import { createServerFn } from "@tanstack/react-start";
import { z } from "zod";
import { requireSupabaseAuth } from "@/integrations/supabase/auth-middleware";
import { assertPermission } from "@/lib/admin-permissions";

function parseUA(ua: string | null | undefined) {
  const s = ua ?? "";
  let browser = "Unknown";
  if (/Edg\//.test(s)) browser = "Edge";
  else if (/Chrome\//.test(s)) browser = "Chrome";
  else if (/Safari\//.test(s)) browser = "Safari";
  else if (/Firefox\//.test(s)) browser = "Firefox";
  const device = /Mobile|Android|iPhone/.test(s)
    ? "Mobile"
    : /iPad|Tablet/.test(s)
      ? "Tablet"
      : "Desktop";
  return { browser, device };
}

const historyInput = z.object({
  limit: z.number().int().min(1).max(200).default(50),
  search: z.string().trim().max(120).optional(),
  rangeHours: z
    .number()
    .int()
    .min(1)
    .max(24 * 90)
    .default(24 * 7),
});

export const adminLoginHistory = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .inputValidator((i: z.infer<typeof historyInput>) => historyInput.parse(i ?? {}))
  .handler(async ({ data, context }) => {
    await assertPermission(context.supabase, context.userId, "manage_users");
    const sb = context.supabase;
    const since = new Date(Date.now() - data.rangeHours * 3600_000).toISOString();
    const { data: rows, error } = await sb
      .from("user_login_events")
      .select("id,user_id,login_at,logout_at,duration_seconds,user_agent,device,browser,ip")
      .gte("login_at", since)
      .order("login_at", { ascending: false })
      .limit(data.limit);
    if (error) throw error;
    const ids = Array.from(new Set((rows ?? []).map((r: { user_id: string }) => r.user_id)));
    const pmap = new Map<string, { display_name: string | null }>();
    if (ids.length) {
      const { data: profs } = await sb.from("profiles").select("id,display_name").in("id", ids);
      for (const p of profs ?? []) pmap.set(p.id, { display_name: p.display_name });
    }
    type Row = {
      id: string;
      user_id: string;
      login_at: string;
      logout_at: string | null;
      duration_seconds: number | null;
      user_agent: string | null;
      device: string | null;
      browser: string | null;
      ip: string | null;
    };
    let out = ((rows ?? []) as Row[]).map((r) => {
      const parsed = parseUA(r.user_agent);
      return {
        id: r.id,
        user_id: r.user_id,
        login_at: r.login_at,
        logout_at: r.logout_at,
        duration_seconds: r.duration_seconds,
        ip: r.ip,
        display_name: pmap.get(r.user_id)?.display_name ?? "Unknown",
        device: r.device ?? parsed.device,
        browser: r.browser ?? parsed.browser,
      };
    });
    if (data.search) {
      const s = data.search.toLowerCase();
      out = out.filter(
        (r: { display_name: string; ip: string | null }) =>
          (r.display_name ?? "").toLowerCase().includes(s) || (r.ip ?? "").includes(s),
      );
    }
    return out;
  });

export const adminDeviceBreakdown = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .inputValidator((i: { rangeHours?: number }) =>
    z
      .object({
        rangeHours: z
          .number()
          .int()
          .min(1)
          .max(24 * 90)
          .default(24 * 7),
      })
      .parse(i ?? {}),
  )
  .handler(async ({ data, context }) => {
    await assertPermission(context.supabase, context.userId, "manage_users");
    const since = new Date(Date.now() - data.rangeHours * 3600_000).toISOString();
    const { data: rows, error } = await context.supabase
      .from("user_login_events")
      .select("user_agent,device,browser")
      .gte("login_at", since)
      .limit(5000);
    if (error) throw error;
    const devCounts = new Map<string, number>();
    const browCounts = new Map<string, number>();
    for (const r of (rows ?? []) as Array<{
      user_agent: string | null;
      device: string | null;
      browser: string | null;
    }>) {
      const p = parseUA(r.user_agent);
      const d = r.device ?? p.device;
      const b = r.browser ?? p.browser;
      devCounts.set(d, (devCounts.get(d) ?? 0) + 1);
      browCounts.set(b, (browCounts.get(b) ?? 0) + 1);
    }
    const total = rows?.length ?? 0;
    const toArr = (m: Map<string, number>) =>
      [...m.entries()]
        .map(([k, v]) => ({
          label: k,
          count: v,
          percent: total ? Math.round((v / total) * 100) : 0,
        }))
        .sort((a, b) => b.count - a.count);
    return { devices: toArr(devCounts), browsers: toArr(browCounts), total };
  });

export const adminLoginHeatmap = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .inputValidator((i: { days?: number }) =>
    z.object({ days: z.number().int().min(1).max(30).default(7) }).parse(i ?? {}),
  )
  .handler(async ({ data, context }) => {
    await assertPermission(context.supabase, context.userId, "manage_users");
    const since = new Date(Date.now() - data.days * 86_400_000).toISOString();
    const { data: rows, error } = await context.supabase
      .from("user_login_events")
      .select("login_at")
      .gte("login_at", since)
      .limit(20_000);
    if (error) throw error;
    // 7 days x 12 buckets of 2h
    const grid: number[] = Array(data.days * 12).fill(0);
    const startMs = Date.now() - data.days * 86_400_000;
    for (const r of (rows ?? []) as Array<{ login_at: string }>) {
      const t = new Date(r.login_at).getTime();
      const day = Math.floor((t - startMs) / 86_400_000);
      if (day < 0 || day >= data.days) continue;
      const hour = new Date(r.login_at).getHours();
      const bucket = Math.floor(hour / 2);
      const idx = day * 12 + bucket;
      grid[idx] = (grid[idx] ?? 0) + 1;
    }
    const max = Math.max(1, ...grid);
    return { grid, max, days: data.days };
  });

export const adminRoleBreakdown = createServerFn({ method: "GET" })
  .middleware([requireSupabaseAuth])
  .handler(async ({ context }) => {
    await assertPermission(context.supabase, context.userId, "manage_users");
    const { data, error } = await context.supabase
      .from("user_roles")
      .select("user_id,role,display_name")
      .limit(10_000);
    if (error) throw error;
    const counts = new Map<string, Set<string>>();
    const displayNames = new Map<string, string>();
    for (const r of (data ?? []) as Array<{ user_id: string; role: string; display_name: string | null }>) {
      const s = counts.get(r.role) ?? new Set<string>();
      s.add(r.user_id);
      counts.set(r.role, s);
      if (r.display_name && !displayNames.has(r.role)) {
        displayNames.set(r.role, r.display_name);
      }
    }
    const out = [...counts.entries()].map(([role, s]) => ({
      role,
      display_name: displayNames.get(role) ?? role,
      count: s.size,
    }));
    out.sort((a, b) => b.count - a.count);
    return out;
  });

export const adminSecuritySummary = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .inputValidator((i: { rangeHours?: number }) =>
    z
      .object({
        rangeHours: z
          .number()
          .int()
          .min(1)
          .max(24 * 30)
          .default(24 * 7),
      })
      .parse(i ?? {}),
  )
  .handler(async ({ data, context }) => {
    await assertPermission(context.supabase, context.userId, "manage_users");
    const sb = context.supabase;
    const since = new Date(Date.now() - data.rangeHours * 3600_000).toISOString();
    const [suspended, unverified, logins, adminActions] = await Promise.all([
      sb.from("profiles").select("id", { count: "exact", head: true }).eq("status", "suspended"),
      sb.from("profiles").select("id", { count: "exact", head: true }).eq("status", "pending"),
      sb.from("user_login_events").select("user_id,ip,login_at").gte("login_at", since).limit(5000),
      sb
        .from("activity_events")
        .select("id", { count: "exact", head: true })
        .gte("created_at", since)
        .eq("event_type", "admin_action"),
    ]);
    // Suspicious = users with >1 distinct IP in the window
    const ipsByUser = new Map<string, Set<string>>();
    for (const r of (logins.data ?? []) as Array<{ user_id: string; ip: string | null }>) {
      if (!r.ip) continue;
      const set = ipsByUser.get(r.user_id) ?? new Set<string>();
      set.add(r.ip);
      ipsByUser.set(r.user_id, set);
    }
    let suspicious = 0;
    for (const s of ipsByUser.values()) if (s.size > 1) suspicious += 1;
    return {
      suspended: suspended.count ?? 0,
      unverified: unverified.count ?? 0,
      logins_in_window: logins.data?.length ?? 0,
      admin_actions: adminActions.count ?? 0,
      suspicious_multi_ip: suspicious,
      range_hours: data.rangeHours,
    };
  });

export const adminSendPasswordReset = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .inputValidator((i: { id: string }) =>
    z.object({ id: z.string().uuid() }).parse(i),
  )
  .handler(async ({ data, context }) => {
    await assertPermission(context.supabase, context.userId, "manage_users");
    const { supabaseAdmin } = await import("@/integrations/supabase/client.server");
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const { data: u } = await (supabaseAdmin.auth.admin as any).getUserById(data.id);
    const email = u?.user?.email;
    if (!email) throw new Error("User has no email on file");
    // SECURITY: do NOT accept redirectTo from clients (open-redirect / phishing
    // surface). Rely on the redirect configured in Supabase project settings.
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const { error } = await (supabaseAdmin.auth as any).resetPasswordForEmail(email);
    if (error) throw error;
    return { ok: true, email };
  });
// Period-over-period KPI trends (real timestamped deltas)
export const adminUserTrends = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .inputValidator((i: { days?: number }) =>
    z.object({ days: z.number().int().min(1).max(90).default(7) }).parse(i ?? {}),
  )
  .handler(async ({ data, context }) => {
    await assertPermission(context.supabase, context.userId, "manage_users");
    const now = Date.now();
    const ms = data.days * 24 * 60 * 60 * 1000;
    const curStart = new Date(now - ms).toISOString();
    const prevStart = new Date(now - 2 * ms).toISOString();
    const prevEnd = curStart;
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const sb = context.supabase as any;

    const trend = (cur: number, prev: number) =>
      prev === 0 ? (cur > 0 ? 100 : 0) : Math.round(((cur - prev) / prev) * 100);

    const [
      newCur,
      newPrev,
      activeCur,
      activePrev,
      suspendedCur,
      suspendedPrev,
      verifiedCur,
      verifiedPrev,
    ] = await Promise.all([
      sb.from("profiles").select("id", { count: "exact", head: true }).gte("created_at", curStart),
      sb
        .from("profiles")
        .select("id", { count: "exact", head: true })
        .gte("created_at", prevStart)
        .lt("created_at", prevEnd),
      sb
        .from("profiles")
        .select("id", { count: "exact", head: true })
        .gte("last_login_at", curStart),
      sb
        .from("profiles")
        .select("id", { count: "exact", head: true })
        .gte("last_login_at", prevStart)
        .lt("last_login_at", prevEnd),
      sb
        .from("admin_action_log")
        .select("id", { count: "exact", head: true })
        .eq("action", "user_status_change")
        .gte("created_at", curStart),
      sb
        .from("admin_action_log")
        .select("id", { count: "exact", head: true })
        .eq("action", "user_status_change")
        .gte("created_at", prevStart)
        .lt("created_at", prevEnd),
      sb
        .from("admin_action_log")
        .select("id", { count: "exact", head: true })
        .eq("action", "user_verify")
        .gte("created_at", curStart),
      sb
        .from("admin_action_log")
        .select("id", { count: "exact", head: true })
        .eq("action", "user_verify")
        .gte("created_at", prevStart)
        .lt("created_at", prevEnd),
    ]);

    return {
      days: data.days,
      new_users: {
        current: newCur.count ?? 0,
        previous: newPrev.count ?? 0,
        pct: trend(newCur.count ?? 0, newPrev.count ?? 0),
      },
      active: {
        current: activeCur.count ?? 0,
        previous: activePrev.count ?? 0,
        pct: trend(activeCur.count ?? 0, activePrev.count ?? 0),
      },
      suspended_actions: {
        current: suspendedCur.count ?? 0,
        previous: suspendedPrev.count ?? 0,
        pct: trend(suspendedCur.count ?? 0, suspendedPrev.count ?? 0),
      },
      verifications: {
        current: verifiedCur.count ?? 0,
        previous: verifiedPrev.count ?? 0,
        pct: trend(verifiedCur.count ?? 0, verifiedPrev.count ?? 0),
      },
    };
  });
