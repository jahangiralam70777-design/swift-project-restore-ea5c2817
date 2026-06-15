import { createServerFn } from "@tanstack/react-start";
import { requireSupabaseAuth } from "@/integrations/supabase/auth-middleware";
import { assertPermission } from "@/lib/admin-permissions";
import { z } from "zod";

type JsonValue = string | number | boolean | null | JsonValue[] | { [k: string]: JsonValue };
export type SystemErrorRow = {
  id: string;
  source: "frontend" | "backend" | "db" | "network" | "unknown";
  severity: "critical" | "high" | "medium" | "low";
  message: string;
  stack: string | null;
  route: string | null;
  user_id: string | null;
  user_agent: string | null;
  payload: JsonValue | null;
  fingerprint: string;
  occurrence_count: number;
  last_seen_at: string;
  resolved: boolean;
  resolved_at: string | null;
  created_at: string;
};

const listInput = z.object({
  page: z.number().int().min(0).max(2000).default(0),
  pageSize: z.number().int().min(1).max(100).default(50),
  source: z.enum(["frontend", "backend", "db", "network", "unknown"]).optional(),
  severity: z.enum(["critical", "high", "medium", "low"]).optional(),
  route: z.string().max(500).optional(),
  resolved: z.boolean().optional(),
  q: z.string().max(200).optional(),
});

export const adminListSystemErrors = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .inputValidator((input) => listInput.parse(input))
  .handler(async ({ data, context }) => {
    await assertPermission(context.supabase, context.userId, "manage_system");
    const from = data.page * data.pageSize;
    const to = from + data.pageSize - 1;
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    let q = (context.supabase as any)
      .from("system_error_logs")
      .select("*", { count: "exact" })
      .order("last_seen_at", { ascending: false });
    if (data.source) q = q.eq("source", data.source);
    if (data.severity) q = q.eq("severity", data.severity);
    if (data.route) q = q.eq("route", data.route);
    if (typeof data.resolved === "boolean") q = q.eq("resolved", data.resolved);
    if (data.q && data.q.trim()) q = q.ilike("message", `%${data.q.trim()}%`);
    const res = await q.range(from, to);
    if (res.error) throw new Error(res.error.message);
    return {
      rows: (res.data ?? []) as SystemErrorRow[],
      total: res.count ?? 0,
      page: data.page,
      pageSize: data.pageSize,
    };
  });

export const adminSystemHealthSummary = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .handler(async ({ context }) => {
    await assertPermission(context.supabase, context.userId, "manage_system");
    const since24 = new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString();
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const sb: any = context.supabase;
    const [allOpen, crit24, top] = await Promise.all([
      sb
        .from("system_error_logs")
        .select("id", { count: "exact", head: true })
        .eq("resolved", false),
      sb
        .from("system_error_logs")
        .select("id", { count: "exact", head: true })
        .eq("severity", "critical")
        .gte("last_seen_at", since24),
      sb
        .from("system_error_logs")
        .select("route, occurrence_count")
        .eq("resolved", false)
        .order("occurrence_count", { ascending: false })
        .limit(50),
    ]);
    const byRoute = new Map<string, number>();
    for (const r of (top.data ?? []) as Array<{ route: string | null; occurrence_count: number }>) {
      const k = r.route ?? "(unknown)";
      byRoute.set(k, (byRoute.get(k) ?? 0) + Number(r.occurrence_count ?? 1));
    }
    const topRoutes = Array.from(byRoute.entries())
      .map(([route, count]) => ({ route, count }))
      .sort((a, b) => b.count - a.count)
      .slice(0, 8);
    return {
      openErrors: allOpen.count ?? 0,
      critical24h: crit24.count ?? 0,
      status:
        (crit24.count ?? 0) > 5 ? "degraded" : (allOpen.count ?? 0) > 0 ? "warning" : "healthy",
      topRoutes,
    } as {
      openErrors: number;
      critical24h: number;
      status: "healthy" | "warning" | "degraded";
      topRoutes: { route: string; count: number }[];
    };
  });

export const adminResolveSystemError = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .inputValidator((input) =>
    z.object({ id: z.string().uuid(), resolved: z.boolean() }).parse(input),
  )
  .handler(async ({ data, context }) => {
    await assertPermission(
      context.supabase,
      context.userId,
      "manage_system",
      "system_health.resolve",
      { id: data.id, resolved: data.resolved },
    );
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const { error } = await (context.supabase as any)
      .from("system_error_logs")
      .update({
        resolved: data.resolved,
        resolved_at: data.resolved ? new Date().toISOString() : null,
      })
      .eq("id", data.id);
    if (error) throw new Error(error.message);
    return { ok: true };
  });
