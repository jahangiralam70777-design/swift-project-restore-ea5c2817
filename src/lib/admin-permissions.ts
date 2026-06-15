/* eslint-disable @typescript-eslint/no-explicit-any */
// Server-only RBAC enforcement helper. Single source of truth for "can the
// current user perform <permission>?" — backed by public.has_permission().
// Every check is recorded in public.admin_action_log via a SECURITY DEFINER
// RPC (record_admin_action) so audit entries cannot be forged client-side.
//
// SECURITY: This helper also applies a per-user admin-write rate limit
// (RATE_LIMITS.ADMIN_WRITE) so a compromised admin account or buggy UI
// cannot hammer privileged endpoints. Read-only flows that wrap reads in
// has_permission() will still incur the rate-limit check — that is
// intentional and the budget (30/min) is comfortably above any real UI.

import {
  enforceRateLimit,
  RATE_LIMITS,
  rateLimitKey,
} from "@/integrations/security/rate-limit";

export async function assertPermission(
  supabase: any,
  userId: string,
  permission: string,
  action?: string,
  metadata?: Record<string, unknown>,
): Promise<void> {
  const { data, error } = await supabase.rpc("has_permission", {
    _user_id: userId,
    _permission: permission,
  });

  const allowed = !error && data === true;

  // Best-effort audit log — never block the user-facing operation on a logging
  // failure, but surface the failure in server logs so silent breakage is
  // detectable (L-3).
  try {
    const { error: auditErr } = await supabase.rpc("record_admin_action", {
      _permission: permission,
      _action: action ?? null,
      _allowed: allowed,
      _metadata: metadata ?? null,
    });
    if (auditErr) {
      console.error("[audit-log-fail]", { permission, action, message: auditErr.message });
    }
  } catch (auditErr) {
    console.error("[audit-log-fail]", { permission, action, error: auditErr });
  }

  // FAIL CLOSED: any error from has_permission denies the operation. Never
  // silently downgrade to "allowed" on RPC failure.
  if (error) {
    console.error("[authz-rpc-fail]", { userId, permission, action, message: error.message });
    throw new Error(`Permission check failed: ${error.message}`);
  }
  if (!allowed) {
    // Server-side diagnostic so support can answer "why did this user see
    // Forbidden?" without exposing role internals to the end user.
    try {
      const { data: diag } = await supabase.rpc("debug_permission_check", {
        _user_id: userId,
        _permission: permission,
      });
      console.warn("[authz-denied]", {
        userId,
        permission,
        action,
        diagnostic: Array.isArray(diag) ? diag[0] : diag,
      });
    } catch {
      console.warn("[authz-denied]", { userId, permission, action });
    }
    throw new Error(`Forbidden: missing permission "${permission}"`);
  }

  // Per-user admin-write rate limit. Applied AFTER the permission check so
  // an unauthorized caller is rejected with a 403-like message rather than
  // a 429 (which would otherwise leak the existence of the endpoint).
  await enforceRateLimit(
    supabase,
    rateLimitKey(`admin:${permission}`, "user", userId),
    RATE_LIMITS.ADMIN_WRITE,
  );
}
