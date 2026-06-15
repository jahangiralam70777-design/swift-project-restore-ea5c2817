/* eslint-disable @typescript-eslint/no-explicit-any */
/**
 * Postgres-backed sliding-window rate limiter.
 *
 * Calls the `public.check_rate_limit(key, max, window_seconds)` RPC
 * (SECURITY DEFINER) defined in db_audit/SECURITY_PHASE3_HARDENING.sql.
 * Returns TRUE when the caller is under the limit (and a hit was
 * recorded); FALSE when the limit has been reached.
 *
 * Use {@link enforceRateLimit} from inside a server-fn `.handler()` to
 * throw a structured 429-like error when the limit is exceeded.
 *
 * Keys MUST be scoped — combine the protected action with the caller's
 * identity (user id when authenticated, otherwise the request IP). Example:
 *   `auth:login:ip:203.0.113.5`
 *   `mcq:submit:user:7d3...`
 */
import type { SupabaseClient } from "@supabase/supabase-js";

export type RateLimitConfig = { max: number; windowSeconds: number };

// Suggested defaults — single source of truth referenced by callers.
export const RATE_LIMITS = {
  AUTH:        { max: 5,  windowSeconds: 60 }, //   5 / min
  BLOG_VIEW:   { max: 30, windowSeconds: 60 }, //  30 / min
  MCQ_SUBMIT:  { max: 60, windowSeconds: 60 }, //  60 / min
  QUIZ_SUBMIT: { max: 60, windowSeconds: 60 }, //  60 / min
  MOCK_SUBMIT: { max: 30, windowSeconds: 60 }, //  30 / min
  BULK_UPLOAD: { max: 5,  windowSeconds: 60 }, //   5 / min
  ADMIN_WRITE: { max: 30, windowSeconds: 60 }, //  30 / min
} as const satisfies Record<string, RateLimitConfig>;

export class RateLimitError extends Error {
  readonly status = 429 as const;
  readonly code = "RATE_LIMITED" as const;
  readonly retryAfterSeconds: number;
  constructor(retryAfterSeconds: number, key: string) {
    super(`Rate limit exceeded for "${key}". Retry in ${retryAfterSeconds}s.`);
    this.name = "RateLimitError";
    this.retryAfterSeconds = retryAfterSeconds;
  }
  /** Structured payload safe to return to clients. */
  toJSON() {
    return {
      error: "rate_limited",
      message: "Too many requests. Please slow down.",
      retry_after_seconds: this.retryAfterSeconds,
      status: this.status,
    };
  }
}

/**
 * Check the rate limit and throw {@link RateLimitError} if exceeded.
 * Pass either the authenticated `supabase` from `requireSupabaseAuth`
 * context, or the admin client for anon flows.
 */
export async function enforceRateLimit(
  supabase: SupabaseClient<any>,
  key: string,
  cfg: RateLimitConfig,
): Promise<void> {
  const { data, error } = await supabase.rpc("check_rate_limit", {
    _key: key,
    _max_hits: cfg.max,
    _window_seconds: cfg.windowSeconds,
  });
  // FAIL OPEN on RPC errors — a broken limiter must not lock users out.
  // Logged so a sustained outage is visible.
  if (error) {
    console.error("[rate-limit] check_rate_limit RPC error — failing open", {
      key,
      message: error.message,
    });
    return;
  }
  if (data === false) {
    throw new RateLimitError(cfg.windowSeconds, key);
  }
}

/** Build a stable rate-limit key. */
export function rateLimitKey(action: string, scope: string, id: string): string {
  return `${action}:${scope}:${id}`;
}
