import { createServerFn } from "@tanstack/react-start";
import { z } from "zod";
import { requireSupabaseAuth } from "@/integrations/supabase/auth-middleware";
import { noInput } from "@/lib/validate";

// eslint-disable-next-line @typescript-eslint/no-explicit-any
const asAny = (x: unknown) => x as any;

export type BroadcastPriority = "normal" | "important" | "urgent";
export type BroadcastStatus = "draft" | "sent" | "hidden" | "archived";
export type BroadcastTargetKind =
  | "all_students"
  | "active_users"
  | "new_users"
  | "class"
  | "batch"
  | "course"
  | "users";

type JsonValue = string | number | boolean | null | JsonValue[] | { [k: string]: JsonValue };
export type TargetFilter = { [k: string]: JsonValue };

export type Broadcast = {
  id: string;
  subject: string;
  body: string;
  priority: BroadcastPriority;
  delivery_methods: string[];
  target_kind: BroadcastTargetKind;
  target_filter: TargetFilter;
  status: BroadcastStatus;
  visible: boolean;
  pinned: boolean;
  recipient_count: number;
  created_by: string | null;
  sent_at: string | null;
  created_at: string;
  updated_at: string;
  // joined
  sender_name?: string | null;
  delivered_count?: number;
  read_count?: number;
};

async function ensureAdmin(supabase: any, userId: string, superOnly = false) {
  if (superOnly) {
    const { data } = await supabase.rpc("has_role", { _user_id: userId, _role: "super_admin" });
    if (!data) throw new Error("Forbidden: super admin only");
    return;
  }
  const { data: a } = await supabase.rpc("has_role", { _user_id: userId, _role: "admin" });
  const { data: s } = await supabase.rpc("has_role", { _user_id: userId, _role: "super_admin" });
  if (!a && !s) throw new Error("Forbidden: admin role required");
}

function dateFromPreset(preset: string, custom_from?: string, custom_to?: string): { from: string; to: string } {
  const now = new Date();
  const to = custom_to ? new Date(custom_to) : now;
  if (preset === "custom" && custom_from) {
    return { from: new Date(custom_from).toISOString(), to: to.toISOString() };
  }
  const offsets: Record<string, number> = {
    today: 0, "24h": 1, "3d": 3, "7d": 7, "15d": 15, "30d": 30,
  };
  const days = offsets[preset] ?? 7;
  const from = new Date(now);
  if (preset === "today") from.setHours(0, 0, 0, 0);
  else from.setTime(now.getTime() - days * 86400_000);
  return { from: from.toISOString(), to: to.toISOString() };
}

async function filterStudentRecipients(supabaseAdmin: any, ids: string[]): Promise<string[]> {
  const unique = Array.from(new Set(ids.filter(Boolean)));
  if (unique.length === 0) return [];
  const { data } = await asAny(supabaseAdmin)
    .from("user_roles")
    .select("user_id, role")
    .in("user_id", unique);
  const rolesByUser = new Map<string, Set<string>>();
  for (const r of (data ?? []) as Array<{ user_id: string; role: string }>) {
    const set = rolesByUser.get(r.user_id) ?? new Set<string>();
    set.add(r.role);
    rolesByUser.set(r.user_id, set);
  }
  return unique.filter((id) => {
    const roles = rolesByUser.get(id);
    return !!roles?.has("student") && !roles.has("admin") && !roles.has("super_admin") && !roles.has("moderator");
  });
}

function notificationPriority(priority: BroadcastPriority) {
  if (priority === "urgent") return "critical";
  if (priority === "important") return "high";
  return "medium";
}

function chunks<T>(rows: T[], size = 500) {
  const out: T[][] = [];
  for (let i = 0; i < rows.length; i += size) out.push(rows.slice(i, i + size));
  return out;
}

async function upsertChunkWithRetry(
  supabaseAdmin: any,
  table: string,
  rows: Array<Record<string, unknown>>,
  onConflict: string,
  label: string,
) {
  if (rows.length === 0) return;
  let lastError: { message: string } | null = null;
  for (let attempt = 1; attempt <= 2; attempt += 1) {
    const { error } = await asAny(supabaseAdmin)
      .from(table)
      .upsert(rows, { onConflict, ignoreDuplicates: true });
    if (!error) return;
    lastError = error;
  }
  throw new Error(`${label} failed after retry: ${lastError?.message ?? "unknown error"}`);
}

async function countBroadcastNotifications(supabaseAdmin: any, broadcastId: string, ids: string[]) {
  let delivered = 0;
  for (const uidChunk of chunks(ids, 500)) {
    const { count, error } = await asAny(supabaseAdmin)
      .from("notifications")
      .select("id", { count: "exact", head: true })
      .eq("source_broadcast_id", broadcastId)
      .in("user_id", uidChunk);
    if (error) throw new Error(`Notification delivery verification failed: ${error.message}`);
    delivered += count ?? 0;
  }
  return delivered;
}

async function resolveRecipients(
  supabaseAdmin: any,
  kind: BroadcastTargetKind,
  filter: TargetFilter,
): Promise<string[]> {
  if (kind === "users") {
    const ids = (filter.user_ids as string[]) ?? [];
    return Array.from(new Set(ids.filter(Boolean)));
  }
  if (kind === "all_students") {
    const { data } = await asAny(supabaseAdmin)
      .from("user_roles").select("user_id").eq("role", "student");
    return Array.from(new Set((data ?? []).map((r: any) => r.user_id as string)));
  }
  if (kind === "active_users") {
    const since = new Date(Date.now() - 30 * 86400_000).toISOString();
    const { data } = await asAny(supabaseAdmin)
      .from("profiles").select("id").gte("last_login_at", since);
    return Array.from(new Set((data ?? []).map((r: any) => r.id as string)));
  }
  if (kind === "new_users") {
    const preset = (filter.preset as string) ?? "7d";
    const { from, to } = dateFromPreset(preset, filter.from as string, filter.to as string);
    const { data } = await asAny(supabaseAdmin)
      .from("profiles").select("id").gte("created_at", from).lte("created_at", to);
    return Array.from(new Set((data ?? []).map((r: any) => r.id as string)));
  }
  if (kind === "class" || kind === "batch" || kind === "course") {
    // Best-effort: profile.level field equals filter.level
    const level = filter.level as string | undefined;
    if (!level) return [];
    const { data } = await asAny(supabaseAdmin)
      .from("profiles").select("id").eq("level", level);
    return Array.from(new Set((data ?? []).map((r: any) => r.id as string)));
  }
  return [];
}

// ---------- CREATE / SEND ----------
const createSchema = z.object({
  subject: z.string().min(1).max(200),
  body: z.string().min(1).max(5000),
  priority: z.enum(["normal", "important", "urgent"]).default("normal"),
  delivery_methods: z.array(z.enum(["inbox", "chat", "popup"])).min(1).default(["inbox"]),
  target_kind: z.enum(["all_students", "active_users", "new_users", "class", "batch", "course", "users"]),
  target_filter: z.record(z.string(), z.any()).default({}) as unknown as z.ZodType<TargetFilter>,
});

export const createBroadcast = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .inputValidator((i: unknown) => createSchema.parse(i))
  .handler(async ({ data, context }) => {
    await ensureAdmin(context.supabase, context.userId);
    const { supabaseAdmin } = await import("@/integrations/supabase/client.server");
    const ids = await filterStudentRecipients(
      supabaseAdmin,
      await resolveRecipients(supabaseAdmin, data.target_kind, data.target_filter),
    );
    const now = new Date().toISOString();
    const { data: row, error } = await asAny(supabaseAdmin)
      .from("broadcasts")
      .insert({
        subject: data.subject.trim(),
        body: data.body.trim(),
        priority: data.priority,
        delivery_methods: data.delivery_methods,
        target_kind: data.target_kind,
        target_filter: data.target_filter,
        status: "sent",
        recipient_count: ids.length,
        created_by: context.userId,
        sent_at: now,
      })
      .select("*")
      .single();
    if (error) throw new Error(error.message);
    if (ids.length > 0) {
      const recipientRows = ids.map((uid) => ({ broadcast_id: row.id, user_id: uid }));
      for (const chunk of chunks(recipientRows)) {
        const { error: e2 } = await asAny(supabaseAdmin)
          .from("broadcast_recipients")
          .upsert(chunk, { onConflict: "broadcast_id,user_id" });
        if (e2) throw new Error(`Broadcast recipient delivery failed: ${e2.message}`);
      }

      const wantsInbox = data.delivery_methods.includes("inbox") || data.delivery_methods.includes("popup");
      if (wantsInbox) {
        const notificationRows = ids.map((uid) => ({
          user_id: uid,
          source_broadcast_id: row.id,
          delivery_group_id: row.id,
          title: `FROM ADMIN: ${data.subject.trim()}`,
          body: data.body.trim(),
          message: data.body.trim(),
          type: "broadcast",
          priority: notificationPriority(data.priority),
          audience: "users",
          status: "unread",
          sent_at: now,
          delivered_at: now,
          recipients_count: 1,
          delivered_count: 1,
          created_by: context.userId,
        }));
        for (const chunk of chunks(notificationRows)) {
          await upsertChunkWithRetry(
            supabaseAdmin,
            "notifications",
            chunk,
            "source_broadcast_id,user_id",
            "Per-user notification fan-out",
          );
        }
        const delivered = await countBroadcastNotifications(supabaseAdmin, row.id, ids);
        if (delivered !== ids.length) {
          throw new Error(`Notification delivery incomplete: ${delivered}/${ids.length} recipients confirmed`);
        }
      }

      if (data.delivery_methods.includes("chat")) {
        const BROADCAST_SUBJECT = "Admin Broadcasts";
        for (const uidChunk of chunks(ids, 200)) {
          // Find existing broadcast conversations for these users
          const { data: existing, error: exErr } = await asAny(supabaseAdmin)
            .from("live_chat_conversations")
            .select("id,user_id")
            .in("user_id", uidChunk)
            .eq("subject", BROADCAST_SUBJECT);
          if (exErr) throw new Error(`Chat lookup failed: ${exErr.message}`);
          const byUser = new Map<string, string>(
            ((existing ?? []) as Array<{ id: string; user_id: string }>).map((c) => [c.user_id, c.id]),
          );
          const missing = uidChunk.filter((u) => !byUser.has(u));
          if (missing.length > 0) {
            const { data: created, error: cErr } = await asAny(supabaseAdmin)
              .from("live_chat_conversations")
              .insert(missing.map((uid) => ({
                user_id: uid,
                subject: BROADCAST_SUBJECT,
                status: "open",
                last_message_preview: data.subject.trim(),
                last_message_at: now,
              })))
              .select("id,user_id");
            if (cErr) throw new Error(`Chat delivery failed: ${cErr.message}`);
            for (const c of (created ?? []) as Array<{ id: string; user_id: string }>) {
              byUser.set(c.user_id, c.id);
            }
          }
          const messages = uidChunk
            .map((uid) => byUser.get(uid))
            .filter((cid): cid is string => !!cid)
            .map((cid) => ({
              conversation_id: cid,
              sender_type: "system",
              sender_user_id: context.userId,
              body: `📢 FROM ADMIN\n${data.subject.trim()}\n\n${data.body.trim()}`,
              delivered_at: now,
            }));
          if (messages.length) {
            const { error: mErr } = await asAny(supabaseAdmin).from("live_chat_messages").insert(messages);
            if (mErr) throw new Error(`Chat message delivery failed: ${mErr.message}`);
            // Bump conversation unread + last message
            for (const cid of new Set(messages.map((m) => m.conversation_id))) {
              await asAny(supabaseAdmin)
                .from("live_chat_conversations")
                .update({
                  last_message_at: now,
                  last_message_preview: data.subject.trim(),
                  unread_for_user: 1,
                })
                .eq("id", cid);
            }
          }
        }
      }
    }

    return { id: row.id, recipient_count: ids.length };
  });

// ---------- LIST / HISTORY ----------
export const listBroadcasts = createServerFn({ method: "GET" })
  .middleware([requireSupabaseAuth])
  .inputValidator(noInput)
  .handler(async ({ context }) => {
    await ensureAdmin(context.supabase, context.userId);
    const { supabaseAdmin } = await import("@/integrations/supabase/client.server");
    const { data: rows, error } = await asAny(supabaseAdmin)
      .from("broadcasts").select("*").order("created_at", { ascending: false }).limit(200);
    if (error) throw new Error(error.message);
    const list = (rows ?? []) as Broadcast[];
    if (list.length === 0) return list;
    const ids = list.map((b) => b.id);
    const { data: recs } = await asAny(supabaseAdmin)
      .from("broadcast_recipients").select("broadcast_id, read_at").in("broadcast_id", ids);
    const delivered = new Map<string, number>();
    const read = new Map<string, number>();
    for (const r of (recs ?? []) as Array<{ broadcast_id: string; read_at: string | null }>) {
      delivered.set(r.broadcast_id, (delivered.get(r.broadcast_id) ?? 0) + 1);
      if (r.read_at) read.set(r.broadcast_id, (read.get(r.broadcast_id) ?? 0) + 1);
    }
    const senderIds = Array.from(new Set(list.map((b) => b.created_by).filter(Boolean) as string[]));
    let senders = new Map<string, string>();
    if (senderIds.length > 0) {
      const { data: profs } = await asAny(supabaseAdmin)
        .from("profiles").select("id, display_name").in("id", senderIds);
      senders = new Map((profs ?? []).map((p: any) => [p.id, p.display_name ?? "Admin"]));
    }
    return list.map((b) => ({
      ...b,
      delivered_count: delivered.get(b.id) ?? 0,
      read_count: read.get(b.id) ?? 0,
      sender_name: b.created_by ? senders.get(b.created_by) ?? "Admin" : "System",
    }));
  });

const idSchema = z.object({ id: z.string().uuid() });

export const setBroadcastVisibility = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .inputValidator((i: unknown) => z.object({ id: z.string().uuid(), visible: z.boolean() }).parse(i))
  .handler(async ({ data, context }) => {
    await ensureAdmin(context.supabase, context.userId, true);
    const { supabaseAdmin } = await import("@/integrations/supabase/client.server");
    const { error } = await asAny(supabaseAdmin).from("broadcasts")
      .update({ visible: data.visible, status: data.visible ? "sent" : "hidden" })
      .eq("id", data.id);
    if (error) throw new Error(error.message);
    return { ok: true };
  });

export const setBroadcastPinned = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .inputValidator((i: unknown) => z.object({ id: z.string().uuid(), pinned: z.boolean() }).parse(i))
  .handler(async ({ data, context }) => {
    await ensureAdmin(context.supabase, context.userId);
    const { supabaseAdmin } = await import("@/integrations/supabase/client.server");
    const { error } = await asAny(supabaseAdmin).from("broadcasts")
      .update({ pinned: data.pinned }).eq("id", data.id);
    if (error) throw new Error(error.message);
    return { ok: true };
  });

export const editBroadcast = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .inputValidator((i: unknown) => z.object({
    id: z.string().uuid(),
    subject: z.string().min(1).max(200).optional(),
    body: z.string().min(1).max(5000).optional(),
    priority: z.enum(["normal", "important", "urgent"]).optional(),
  }).parse(i))
  .handler(async ({ data, context }) => {
    await ensureAdmin(context.supabase, context.userId);
    const { supabaseAdmin } = await import("@/integrations/supabase/client.server");
    const { id, ...patch } = data;
    const { error } = await asAny(supabaseAdmin).from("broadcasts").update(patch).eq("id", id);
    if (error) throw new Error(error.message);
    return { ok: true };
  });

export const deleteBroadcast = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .inputValidator((i: unknown) => idSchema.parse(i))
  .handler(async ({ data, context }) => {
    await ensureAdmin(context.supabase, context.userId, true);
    const { supabaseAdmin } = await import("@/integrations/supabase/client.server");
    const { error } = await asAny(supabaseAdmin).from("broadcasts").delete().eq("id", data.id);
    if (error) throw new Error(error.message);
    return { ok: true };
  });

// ---------- TEMPLATES ----------
export type BroadcastTemplate = {
  id: string;
  name: string;
  subject: string;
  body: string;
  priority: BroadcastPriority;
  delivery_methods: string[];
  target_kind: BroadcastTargetKind | null;
  target_filter: TargetFilter;
  archived: boolean;
  created_at: string;
};

export const listTemplates = createServerFn({ method: "GET" })
  .middleware([requireSupabaseAuth])
  .inputValidator(noInput)
  .handler(async ({ context }) => {
    await ensureAdmin(context.supabase, context.userId);
    const { supabaseAdmin } = await import("@/integrations/supabase/client.server");
    const { data, error } = await asAny(supabaseAdmin).from("broadcast_templates")
      .select("*").order("created_at", { ascending: false });
    if (error) throw new Error(error.message);
    return (data ?? []) as BroadcastTemplate[];
  });

const templateSchema = z.object({
  name: z.string().min(1).max(120),
  subject: z.string().min(1).max(200),
  body: z.string().min(1).max(5000),
  priority: z.enum(["normal", "important", "urgent"]).default("normal"),
  delivery_methods: z.array(z.enum(["inbox", "chat", "popup"])).default(["inbox"]),
  target_kind: z.enum(["all_students", "active_users", "new_users", "class", "batch", "course", "users"]).optional(),
  target_filter: z.record(z.string(), z.any()).default({}) as unknown as z.ZodType<TargetFilter>,
});

export const createTemplate = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .inputValidator((i: unknown) => templateSchema.parse(i))
  .handler(async ({ data, context }) => {
    await ensureAdmin(context.supabase, context.userId, true);
    const { supabaseAdmin } = await import("@/integrations/supabase/client.server");
    const { error } = await asAny(supabaseAdmin).from("broadcast_templates").insert({
      ...data, created_by: context.userId,
    });
    if (error) throw new Error(error.message);
    return { ok: true };
  });

export const updateTemplate = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .inputValidator((i: unknown) => z.object({ id: z.string().uuid() }).merge(templateSchema.partial()).parse(i))
  .handler(async ({ data, context }) => {
    await ensureAdmin(context.supabase, context.userId, true);
    const { supabaseAdmin } = await import("@/integrations/supabase/client.server");
    const { id, ...patch } = data;
    const { error } = await asAny(supabaseAdmin).from("broadcast_templates").update(patch).eq("id", id);
    if (error) throw new Error(error.message);
    return { ok: true };
  });

export const archiveTemplate = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .inputValidator((i: unknown) => z.object({ id: z.string().uuid(), archived: z.boolean() }).parse(i))
  .handler(async ({ data, context }) => {
    await ensureAdmin(context.supabase, context.userId, true);
    const { supabaseAdmin } = await import("@/integrations/supabase/client.server");
    const { error } = await asAny(supabaseAdmin).from("broadcast_templates")
      .update({ archived: data.archived }).eq("id", data.id);
    if (error) throw new Error(error.message);
    return { ok: true };
  });

export const deleteTemplate = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .inputValidator((i: unknown) => idSchema.parse(i))
  .handler(async ({ data, context }) => {
    await ensureAdmin(context.supabase, context.userId, true);
    const { supabaseAdmin } = await import("@/integrations/supabase/client.server");
    const { error } = await asAny(supabaseAdmin).from("broadcast_templates").delete().eq("id", data.id);
    if (error) throw new Error(error.message);
    return { ok: true };
  });

// ---------- STUDENT SIDE ----------
export type MyBroadcast = Broadcast & {
  recipient_id: string;
  read_at: string | null;
  hidden_at: string | null;
};

export const listMyBroadcasts = createServerFn({ method: "GET" })
  .middleware([requireSupabaseAuth])
  .inputValidator(noInput)
  .handler(async ({ context }) => {
    const { data, error } = await asAny(context.supabase)
      .from("broadcast_recipients")
      .select("id, broadcast_id, read_at, hidden_at, broadcasts(*)")
      .eq("user_id", context.userId)
      .is("hidden_at", null)
      .order("delivered_at", { ascending: false })
      .limit(100);
    if (error) throw new Error(error.message);
    return ((data ?? []) as any[])
      .filter((r) => r.broadcasts?.visible)
      .map((r) => ({
        ...(r.broadcasts as Broadcast),
        recipient_id: r.id,
        read_at: r.read_at,
        hidden_at: r.hidden_at,
      })) as MyBroadcast[];
  });

export const markBroadcastRead = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .inputValidator((i: unknown) => idSchema.parse(i))
  .handler(async ({ data, context }) => {
    const { error } = await asAny(context.supabase)
      .from("broadcast_recipients")
      .update({ read_at: new Date().toISOString() })
      .eq("id", data.id)
      .eq("user_id", context.userId);
    if (error) throw new Error(error.message);
    return { ok: true };
  });
