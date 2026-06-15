import { createServerFn } from "@tanstack/react-start";
import { z } from "zod";
import { requireSupabaseAuth } from "@/integrations/supabase/auth-middleware";
import { assertPermission } from "@/lib/admin-permissions";

const roleEnum = z.enum(["admin", "moderator", "student"]);
const statusEnum = z.enum(["active", "suspended", "pending"]);
const statusFilterEnum = z.enum(["active", "suspended", "pending", "deleted"]);
const dateRangeEnum = z.enum(["24h", "7d", "30d", "lifetime"]);

const listInput = z.object({
  search: z.string().trim().max(200).optional(),
  role: roleEnum.optional(),
  status: statusFilterEnum.optional(),
  level: z.string().trim().max(40).optional(),
  referralSource: z.string().trim().max(80).optional(),
  dateRange: dateRangeEnum.optional(),
  includeDeleted: z.boolean().optional(),
  verified: z.boolean().optional(),
  page: z.number().int().min(1).max(2000).default(1),
  pageSize: z.number().int().min(1).max(100).default(25),
});

export const adminListUsers = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .inputValidator((i: z.infer<typeof listInput>) => listInput.parse(i))
  .handler(async ({ data, context }) => {
    await assertPermission(context.supabase, context.userId, "manage_users");
    const { supabaseAdmin } = await import("@/integrations/supabase/client.server");
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const sb = context.supabase as any;
    const from = (data.page - 1) * data.pageSize;
    const to = from + data.pageSize - 1;

    // If search looks like an email/uuid, resolve to a profile id via auth.users first.
    let idFilter: string[] | null = null;
    const searchTerm = (data.search ?? "").trim();
    if (searchTerm) {
      const isEmail = /@/.test(searchTerm);
      const isUuidPrefix = /^[0-9a-f-]{6,}$/i.test(searchTerm);
      if (isEmail || isUuidPrefix) {
        try {
          // eslint-disable-next-line @typescript-eslint/no-explicit-any
          const { data: users } = await (supabaseAdmin.auth.admin as any).listUsers({
            page: 1,
            perPage: 200,
          });
          const lower = searchTerm.toLowerCase();
          const matches = (users?.users ?? [])
            .filter(
              (u: { id: string; email?: string | null }) =>
                (u.email ?? "").toLowerCase().includes(lower) ||
                u.id.toLowerCase().startsWith(lower),
            )
            .map((u: { id: string }) => u.id);
          idFilter = matches;
          if (matches.length === 0 && !isUuidPrefix) {
            // No email match; fall through to name search
            idFilter = null;
          }
        } catch {
          idFilter = null;
        }
      }
    }

    let q = sb
      .from("profiles")
      .select(
        "id,display_name,avatar_url,level,bio,status,referral_source,created_at,updated_at,last_login_at,total_login_count,total_usage_seconds,deleted_at",
        { count: "exact" },
      )
      .order("created_at", { ascending: false })
      .range(from, to);
    if (data.status === "deleted") {
      q = q.not("deleted_at", "is", null);
    } else if (data.status) {
      q = q.eq("status", data.status).is("deleted_at", null);
    } else if (!data.includeDeleted) {
      q = q.is("deleted_at", null);
    }
    if (data.level) q = q.eq("level", data.level);
    if (data.referralSource) q = q.eq("referral_source", data.referralSource);
    if (idFilter && idFilter.length > 0) {
      q = q.in("id", idFilter as string[]);
    } else if (searchTerm) {
      q = q.ilike("display_name", `%${searchTerm}%`);
    }
    if (data.dateRange && data.dateRange !== "lifetime") {
      const map: Record<string, number> = { "24h": 1, "7d": 7, "30d": 30 };
      const days = map[data.dateRange];
      if (days) {
        const since = new Date(Date.now() - days * 86400000).toISOString();
        q = q.gte("last_login_at", since);
      }
    }
    const { data: profiles, error, count } = await q;
    if (error) throw error;

    const ids = (profiles ?? []).map((p: { id: string }) => p.id);
    const rolesMap = new Map<string, string[]>();
    const roleDisplayMap = new Map<string, string[]>();
    if (ids.length) {
      const { data: rs } = await sb.from("user_roles").select("user_id,role,display_name").in("user_id", ids);
      for (const r of rs ?? []) {
        const arr = rolesMap.get(r.user_id) ?? [];
        arr.push(r.role);
        rolesMap.set(r.user_id, arr);
        const dArr = roleDisplayMap.get(r.user_id) ?? [];
        dArr.push(r.display_name ?? r.role);
        roleDisplayMap.set(r.user_id, dArr);
      }
    }

    // Look up email + verification status from auth.users in ONE call (avoid N+1 getUserById).
    const emailMap = new Map<string, { email: string | null; verified: boolean }>();
    if (ids.length) {
      try {
        const idSet = new Set(ids);
        // Page through auth.users until we've matched all requested ids (or hit a safety cap).
        const perPage = 1000;
        const maxPages = 10; // up to 10k users covered without per-id round trips
        for (let page = 1; page <= maxPages && idSet.size > emailMap.size; page++) {
          // eslint-disable-next-line @typescript-eslint/no-explicit-any
          const { data: u } = await (supabaseAdmin.auth.admin as any).listUsers({ page, perPage });
          const users: Array<{ id: string; email?: string | null; email_confirmed_at?: string | null }> =
            u?.users ?? [];
          if (!users.length) break;
          for (const usr of users) {
            if (idSet.has(usr.id)) {
              emailMap.set(usr.id, {
                email: usr.email ?? null,
                verified: !!usr.email_confirmed_at,
              });
            }
          }
          if (users.length < perPage) break;
        }
      } catch {
        // best-effort; rows without an email entry default to null/false below
      }
      for (const id of ids) {
        if (!emailMap.has(id)) emailMap.set(id, { email: null, verified: false });
      }
    }


    let rows = (profiles ?? []).map((p: { id: string; display_name: string | null }) => {
      const auth = emailMap.get(p.id);
      // Display priority: profile.display_name → email → short UUID. Never blank.
      const fallback = auth?.email ?? `${p.id.slice(0, 8)}…`;
      return {
        ...p,
        display_name: p.display_name ?? fallback,
        roles: rolesMap.get(p.id) ?? [],
        roleDisplays: roleDisplayMap.get(p.id) ?? [],
        email: auth?.email ?? null,
        email_verified: auth?.verified ?? false,
      };
    });

    if (data.role) rows = rows.filter((r: { roles: string[] }) => r.roles.includes(data.role!));
    if (typeof data.verified === "boolean") {
      rows = rows.filter((r: { email_verified: boolean }) => r.email_verified === data.verified);
    }

    return { rows, count: count ?? 0, page: data.page, pageSize: data.pageSize };
  });

export const adminReferralStats = createServerFn({ method: "GET" })
  .middleware([requireSupabaseAuth])
  .handler(async ({ context }) => {
    await assertPermission(context.supabase, context.userId, "manage_users");
    const { data, error } = await (
      context.supabase as unknown as {
        from: (t: string) => {
          select: (s: string) => {
            limit: (n: number) => Promise<{
              data: Array<{ referral_source: string | null }> | null;
              error: unknown;
            }>;
          };
        };
      }
    )
      .from("profiles")
      .select("referral_source")
      .limit(5000);
    if (error) throw error;
    const counts = new Map<string, number>();
    let unknown = 0;
    for (const row of data ?? []) {
      const k = (row.referral_source ?? "").trim();
      if (!k) {
        unknown += 1;
        continue;
      }
      counts.set(k, (counts.get(k) ?? 0) + 1);
    }
    const sources = [...counts.entries()]
      .map(([source, count]) => ({ source, count }))
      .sort((a, b) => b.count - a.count);
    return { sources, unknown, total: (data ?? []).length };
  });

export const adminUserStats = createServerFn({ method: "GET" })
  .middleware([requireSupabaseAuth])
  .handler(async ({ context }) => {
    await assertPermission(context.supabase, context.userId, "manage_users");
    const sb = context.supabase;
    const { supabaseAdmin } = await import("@/integrations/supabase/client.server");
    const [total, active, suspended, pending, admins] = await Promise.all([
      sb.from("profiles").select("id", { count: "exact", head: true }),
      sb.from("profiles").select("id", { count: "exact", head: true }).eq("status", "active"),
      sb.from("profiles").select("id", { count: "exact", head: true }).eq("status", "suspended"),
      sb.from("profiles").select("id", { count: "exact", head: true }).eq("status", "pending"),
      sb.from("user_roles").select("user_id", { count: "exact", head: true }).eq("role", "admin"),
    ]);
    // Count verified users by paging through auth.users (capped).
    let verified = 0;
    try {
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      const { data: u } = await (supabaseAdmin.auth.admin as any).listUsers({
        page: 1,
        perPage: 1000,
      });
      verified = (u?.users ?? []).filter(
        (x: { email_confirmed_at?: string | null }) => !!x.email_confirmed_at,
      ).length;
    } catch {
      verified = active.count ?? 0;
    }
    return {
      total: total.count ?? 0,
      active: active.count ?? 0,
      suspended: suspended.count ?? 0,
      pending: pending.count ?? 0,
      admins: admins.count ?? 0,
      verified,
    };
  });

const createStudentInput = z.object({
  display_name: z.string().trim().min(1).max(120),
  email: z.string().trim().email().max(255),
  password: z.string().min(8).max(128),
  level: z.string().trim().min(1).max(40),
  phone: z.string().trim().max(40).optional(),
});
export const adminCreateStudent = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .inputValidator((i: z.infer<typeof createStudentInput>) => createStudentInput.parse(i))
  .handler(async ({ data, context }) => {
    await assertPermission(context.supabase, context.userId, "manage_users", "admin.user.create", {
      email: data.email,
      level: data.level,
    });
    const { supabaseAdmin } = await import("@/integrations/supabase/client.server");
    const { data: created, error } = await supabaseAdmin.auth.admin.createUser({
      email: data.email,
      password: data.password,
      email_confirm: true,
      user_metadata: { display_name: data.display_name, phone: data.phone ?? null },
      // Critical: marks this user as service-role created so the
      // hook_before_user_created Auth Hook lets it through even when the
      // student-signup kill-switch is OFF. Only the service role can set
      // app_metadata — public /auth/v1/signup cannot forge this.
      app_metadata: { created_by_admin: true },
    });
    if (error) throw error;
    const newId = created.user?.id;
    if (!newId) throw new Error("Failed to create auth user");
    // Upsert profile row. (No trigger; admin-created student starts active.)
    const { error: pe } = await supabaseAdmin.from("profiles").upsert({
      id: newId,
      display_name: data.display_name,
      level: data.level,
      status: "active",
      bio: data.phone ? `Phone: ${data.phone}` : null,
    });
    if (pe) throw pe;
    return { ok: true, id: newId };
  });

export const adminVerifyUser = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .inputValidator((i: { id: string }) => z.object({ id: z.string().uuid() }).parse(i))
  .handler(async ({ data, context }) => {
    await assertPermission(
      context.supabase,
      context.userId,
      "manage_users",
      "admin.user.verify_email",
      { target_id: data.id },
    );
    const { supabaseAdmin } = await import("@/integrations/supabase/client.server");
    const { error } = await supabaseAdmin.auth.admin.updateUserById(data.id, {
      email_confirm: true,
    });
    if (error) throw error;
    return { ok: true };
  });

export const adminSetUserStatus = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .inputValidator((i: { id: string; status: z.infer<typeof statusEnum> }) =>
    z.object({ id: z.string().uuid(), status: statusEnum }).parse(i),
  )
  .handler(async ({ data, context }) => {
    await assertPermission(
      context.supabase,
      context.userId,
      "manage_users",
      `admin.user.set_status:${data.status}`,
      { target_id: data.id, status: data.status },
    );
    const { error } = await context.supabase
      .from("profiles")
      .update({ status: data.status })
      .eq("id", data.id);
    if (error) throw error;
    return { ok: true };
  });

export const adminSetUserRole = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .inputValidator((i: { id: string; role: z.infer<typeof roleEnum>; grant: boolean }) =>
    z.object({ id: z.string().uuid(), role: roleEnum, grant: z.boolean() }).parse(i),
  )
  .handler(async ({ data, context }) => {
    await assertPermission(
      context.supabase,
      context.userId,
      "manage_users",
      data.grant ? "admin.user.role_grant" : "admin.user.role_revoke",
      { target_id: data.id, role: data.role },
    );
    const sb = context.supabase;
    if (data.grant) {
      const { error } = await sb
        .from("user_roles")
        .upsert({ user_id: data.id, role: data.role }, { onConflict: "user_id,role" });
      if (error) throw error;
    } else {
      const { error } = await sb
        .from("user_roles")
        .delete()
        .eq("user_id", data.id)
        .eq("role", data.role);
      if (error) throw error;
    }
    return { ok: true };
  });

export const adminUpdateUserProfile = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .inputValidator((i: { id: string; display_name?: string; level?: string; bio?: string | null }) =>
    z
      .object({
        id: z.string().uuid(),
        display_name: z.string().trim().min(1).max(120).optional(),
        level: z.string().trim().max(40).optional(),
        bio: z.string().trim().max(1000).nullable().optional(),
      })
      .parse(i),
  )
  .handler(async ({ data, context }) => {
    await assertPermission(
      context.supabase,
      context.userId,
      "manage_users",
      "admin.user.update_profile",
      { target_id: data.id, fields: Object.keys(data).filter((k) => k !== "id") },
    );
    const { id, ...patch } = data;
    const { error } = await context.supabase.from("profiles").update(patch).eq("id", id);
    if (error) throw error;
    return { ok: true };
  });

// ============================================================
// Analytics + lifecycle (control center)
// ============================================================
export const adminUserAnalytics = createServerFn({ method: "GET" })
  .middleware([requireSupabaseAuth])
  .handler(async ({ context }) => {
    await assertPermission(context.supabase, context.userId, "manage_users");
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const { data, error } = await (context.supabase as any).rpc("admin_user_analytics");
    if (error) throw error;
    return data as {
      total_users: number;
      deleted_users: number;
      active_24h: number;
      active_7d: number;
      active_30d: number;
      lifetime_active: number;
      total_logins: number;
      avg_session_seconds: number;
      usage_24h: number;
      usage_7d: number;
      usage_30d: number;
    };
  });

export const adminTopUsers = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .inputValidator((i: { order?: "most" | "least"; limit?: number }) =>
    z
      .object({
        order: z.enum(["most", "least"]).default("most"),
        limit: z.number().int().min(1).max(50).default(10),
      })
      .parse(i ?? {}),
  )
  .handler(async ({ data, context }) => {
    await assertPermission(context.supabase, context.userId, "manage_users");
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const { data: rows, error } = await (context.supabase as any).rpc("admin_top_users", {
      _order: data.order,
      _limit: data.limit,
    });
    if (error) throw error;
    return (rows ?? []) as Array<{
      user_id: string;
      display_name: string;
      total_login_count: number;
      total_usage_seconds: number;
      last_login_at: string | null;
    }>;
  });

export const adminUserSessions = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .inputValidator((i: { userId: string; limit?: number }) =>
    z
      .object({ userId: z.string().uuid(), limit: z.number().int().min(1).max(100).default(20) })
      .parse(i),
  )
  .handler(async ({ data, context }) => {
    await assertPermission(context.supabase, context.userId, "manage_users");
    const { data: rows, error } = await context.supabase
      .from("user_login_events")
      .select("id,login_at,logout_at,duration_seconds,user_agent,device,browser,ip")
      .eq("user_id", data.userId)
      .order("login_at", { ascending: false })
      .limit(data.limit);
    if (error) throw error;
    return rows ?? [];
  });

export const adminSoftDeleteUser = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .inputValidator((i: { id: string }) => z.object({ id: z.string().uuid() }).parse(i))
  .handler(async ({ data, context }) => {
    await assertPermission(
      context.supabase,
      context.userId,
      "manage_users",
      "admin.user.soft_delete",
      { target_id: data.id },
    );
    if (data.id === context.userId) {
      throw new Error("You cannot delete your own account.");
    }
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const { error } = await (context.supabase as any).rpc("admin_soft_delete_user", {
      _id: data.id,
    });
    if (error) throw error;
    // Soft-delete should also kick any active sessions so the UI state and the
    // user's reality match immediately. Non-fatal if it fails.
    try {
      const { supabaseAdmin } = await import("@/integrations/supabase/client.server");
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      await (supabaseAdmin.auth.admin as any).signOut(data.id, "global");
    } catch (e) {
      console.warn("[adminSoftDeleteUser] signOut failed", e);
    }
    return { ok: true };
  });

export const adminRestoreUser = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .inputValidator((i: { id: string }) => z.object({ id: z.string().uuid() }).parse(i))
  .handler(async ({ data, context }) => {
    await assertPermission(context.supabase, context.userId, "manage_users", "admin.user.restore", {
      target_id: data.id,
    });
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const { error } = await (context.supabase as any).rpc("admin_restore_user", { _id: data.id });
    if (error) throw error;
    return { ok: true };
  });

export const adminHardDeleteUser = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .inputValidator((i: { id: string; confirmName: string }) =>
    z.object({ id: z.string().uuid(), confirmName: z.string().min(1) }).parse(i),
  )
  .handler(async ({ data, context }) => {
    await assertPermission(
      context.supabase,
      context.userId,
      "manage_users",
      "admin.user.hard_delete",
      { target_id: data.id },
    );
    if (data.id === context.userId) {
      throw new Error("You cannot delete your own account.");
    }
    const { data: prof } = await context.supabase
      .from("profiles")
      .select("display_name")
      .eq("id", data.id)
      .maybeSingle();
    if (!prof) throw new Error("User not found");
    if ((prof.display_name ?? "").trim() !== data.confirmName.trim()) {
      throw new Error("Confirmation name does not match");
    }

    // Phase 1: in-DB cleanup via SECURITY DEFINER RPC (validates target is
    // not an admin, scrubs public.* rows that don't have ON DELETE CASCADE,
    // and best-effort deletes auth.users). Throws if Forbidden / admin target.
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const { error: rpcErr } = await (context.supabase as any).rpc("admin_hard_delete_user", {
      _id: data.id,
    });
    if (rpcErr) {
      // Surface admin-only / not-found errors verbatim.
      throw rpcErr;
    }

    // Phase 2: canonical removal via Supabase Auth Admin API. This guarantees
    // auth.identities, auth.sessions, auth.refresh_tokens, MFA factors and the
    // auth.users row itself are gone. All public.* tables that reference
    // auth.users(id) ON DELETE CASCADE are cleaned by Postgres at this point.
    try {
      const { supabaseAdmin } = await import("@/integrations/supabase/client.server");
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      const { error: authErr } = await (supabaseAdmin.auth.admin as any).deleteUser(data.id);
      if (authErr && !/User not found/i.test(authErr.message ?? "")) {
        console.warn("[adminHardDeleteUser] auth.admin.deleteUser failed", authErr);
      }
    } catch (e) {
      console.warn("[adminHardDeleteUser] auth admin delete threw", e);
    }
    return { ok: true };
  });
