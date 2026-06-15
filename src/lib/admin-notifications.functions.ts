import { createServerFn } from "@tanstack/react-start";
import { z } from "zod";
import { requireSupabaseAuth } from "@/integrations/supabase/auth-middleware";
import { assertPermission } from "@/lib/admin-permissions";

import { noInput } from "@/lib/validate";
const typeEnum = z.enum(["announcement", "push", "email", "in_app"]);
const priorityEnum = z.enum(["low", "medium", "high", "critical"]);
const statusEnum = z.enum(["draft", "scheduled", "sent", "failed", "paused"]);
const audienceEnum = z.enum(["all", "level", "subject", "role", "users"]);
const roleEnum = z.enum(["admin", "moderator", "student"]);

// ---------- Admin: list ----------
const listInput = z.object({
  search: z.string().trim().max(200).optional(),
  status: statusEnum.optional(),
  type: typeEnum.optional(),
  page: z.number().int().min(1).max(2000).default(1),
  pageSize: z.number().int().min(1).max(100).default(25),
});

export const adminListNotifications = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .inputValidator((i: z.infer<typeof listInput>) => listInput.parse(i))
  .handler(async ({ data, context }) => {
    await assertPermission(context.supabase, context.userId, "manage_content");
    const from = (data.page - 1) * data.pageSize;
    const to = from + data.pageSize - 1;
    let q = context.supabase
      .from("notifications")
      .select("*", { count: "exact" })
      .order("created_at", { ascending: false })
      .range(from, to);
    if (data.status) q = q.eq("status", data.status);
    if (data.type) q = q.eq("type", data.type);
    if (data.search) q = q.ilike("title", `%${data.search}%`);
    const { data: rows, error, count } = await q;
    if (error) throw error;
    return { rows: rows ?? [], count: count ?? 0, page: data.page, pageSize: data.pageSize };
  });

export const adminNotificationStats = createServerFn({ method: "GET" })
  .middleware([requireSupabaseAuth])
  .inputValidator(noInput)
  .handler(async ({ context }) => {
    await assertPermission(context.supabase, context.userId, "manage_content");
    const sb = context.supabase;
    const [total, sent, scheduled, draft, failed] = await Promise.all([
      sb.from("notifications").select("id", { count: "exact", head: true }),
      sb.from("notifications").select("id", { count: "exact", head: true }).eq("status", "sent"),
      sb
        .from("notifications")
        .select("id", { count: "exact", head: true })
        .eq("status", "scheduled"),
      sb.from("notifications").select("id", { count: "exact", head: true }).eq("status", "draft"),
      sb.from("notifications").select("id", { count: "exact", head: true }).eq("status", "failed"),
    ]);
    return {
      total: total.count ?? 0,
      sent: sent.count ?? 0,
      scheduled: scheduled.count ?? 0,
      draft: draft.count ?? 0,
      failed: failed.count ?? 0,
    };
  });

// ---------- Create / Update ----------
const notifInput = z.object({
  title: z.string().trim().min(1).max(180),
  body: z.string().trim().max(4000).default(""),
  link: z.string().trim().max(500).nullable().optional(),
  type: typeEnum.default("in_app"),
  priority: priorityEnum.default("medium"),
  audience: audienceEnum.default("all"),
  audience_level: z.string().trim().max(40).nullable().optional(),
  audience_subject_id: z.string().uuid().nullable().optional(),
  audience_role: roleEnum.nullable().optional(),
  audience_user_ids: z.array(z.string().uuid()).max(2000).default([]),
  scheduled_at: z.string().datetime().nullable().optional(),
});

export const adminCreateNotification = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .inputValidator((i: z.infer<typeof notifInput>) => notifInput.parse(i))
  .handler(async ({ data, context }) => {
    await assertPermission(context.supabase, context.userId, "manage_content");
    const initialStatus = data.scheduled_at ? "scheduled" : "draft";
    const { data: row, error } = await context.supabase
      .from("notifications")
      .insert({ ...data, status: initialStatus, created_by: context.userId })
      .select("id")
      .single();
    if (error) throw error;
    return row;
  });

const updateInput = notifInput.partial().extend({ id: z.string().uuid() });
export const adminUpdateNotification = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .inputValidator((i: z.infer<typeof updateInput>) => updateInput.parse(i))
  .handler(async ({ data, context }) => {
    await assertPermission(context.supabase, context.userId, "manage_content");
    const { id, ...patch } = data;
    const { error } = await context.supabase.from("notifications").update(patch).eq("id", id);
    if (error) throw error;
    return { ok: true };
  });

export const adminDeleteNotification = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .inputValidator((i: { id: string }) => z.object({ id: z.string().uuid() }).parse(i))
  .handler(async ({ data, context }) => {
    await assertPermission(context.supabase, context.userId, "manage_content");
    const { error } = await context.supabase.from("notifications").delete().eq("id", data.id);
    if (error) throw error;
    return { ok: true };
  });

// ---------- Send / Schedule / Pause ----------
export const adminSendNotification = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .inputValidator((i: { id: string }) => z.object({ id: z.string().uuid() }).parse(i))
  .handler(async ({ data, context }) => {
    await assertPermission(context.supabase, context.userId, "manage_content");
    const sb = context.supabase;
    // Estimate delivered_count from audience
    const { data: n, error } = await sb
      .from("notifications")
      .select("*")
      .eq("id", data.id)
      .single();
    if (error) throw error;
    let delivered = 0;
    if (n.audience === "all") {
      const { count } = await sb.from("profiles").select("id", { count: "exact", head: true });
      delivered = count ?? 0;
    } else if (n.audience === "level" && n.audience_level) {
      const { count } = await sb
        .from("profiles")
        .select("id", { count: "exact", head: true })
        .eq("level", n.audience_level);
      delivered = count ?? 0;
    } else if (n.audience === "role" && n.audience_role) {
      const { count } = await sb
        .from("user_roles")
        .select("user_id", { count: "exact", head: true })
        .eq("role", n.audience_role as "admin" | "moderator" | "student" | "user");
      delivered = count ?? 0;
    } else if (n.audience === "users") {
      delivered = (n.audience_user_ids ?? []).length;
    }
    const { error: ue } = await sb
      .from("notifications")
      .update({ status: "sent", sent_at: new Date().toISOString(), delivered_count: delivered })
      .eq("id", data.id);
    if (ue) throw ue;
    return { ok: true, delivered };
  });

export const adminSetNotificationStatus = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .inputValidator((i: { id: string; status: z.infer<typeof statusEnum> }) =>
    z.object({ id: z.string().uuid(), status: statusEnum }).parse(i),
  )
  .handler(async ({ data, context }) => {
    await assertPermission(context.supabase, context.userId, "manage_content");
    const { error } = await context.supabase
      .from("notifications")
      .update({ status: data.status })
      .eq("id", data.id);
    if (error) throw error;
    return { ok: true };
  });

// ---------- Student: own inbox ----------
export const listMyNotifications = createServerFn({ method: "GET" })
  .middleware([requireSupabaseAuth])
  .inputValidator(noInput)
  .handler(async ({ context }) => {
    const sb = context.supabase;
    const { data, error } = await sb
      .from("notifications")
      .select("id,title,body,link,type,priority,sent_at,created_at")
      .eq("status", "sent")
      .order("sent_at", { ascending: false })
      .limit(100);
    if (error) throw error;
    const { data: reads } = await sb
      .from("notification_reads")
      .select("notification_id")
      .eq("user_id", context.userId);
    const readSet = new Set(
      (reads ?? []).map((r: { notification_id: string }) => r.notification_id),
    );
    return (data ?? []).map((n: { id: string }) => ({ ...n, read: readSet.has(n.id) }));
  });

export const markNotificationRead = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .inputValidator((i: { id: string }) => z.object({ id: z.string().uuid() }).parse(i))
  .handler(async ({ data, context }) => {
    const { error } = await context.supabase
      .from("notification_reads")
      .upsert(
        { notification_id: data.id, user_id: context.userId },
        { onConflict: "notification_id,user_id" },
      );
    if (error) throw error;
    return { ok: true };
  });

export const markAllNotificationsRead = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .inputValidator(noInput)
  .handler(async ({ context }) => {
    const sb = context.supabase;
    const { data: notifs, error: ne } = await sb
      .from("notifications")
      .select("id")
      .eq("status", "sent")
      .limit(500);
    if (ne) throw ne;
    if (!notifs?.length) return { ok: true, count: 0 };
    const rows = notifs.map((n: { id: string }) => ({
      notification_id: n.id,
      user_id: context.userId,
    }));
    const { error } = await sb
      .from("notification_reads")
      .upsert(rows, { onConflict: "notification_id,user_id" });
    if (error) throw error;
    return { ok: true, count: rows.length };
  });
