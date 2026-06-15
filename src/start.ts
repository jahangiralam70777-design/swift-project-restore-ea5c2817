import { createStart, createMiddleware } from "@tanstack/react-start";
import { setResponseHeader } from "@tanstack/react-start/server";
import { attachSupabaseAuth } from "@/integrations/supabase/auth-attacher";

import { renderErrorPage } from "./lib/error-page";

/**
 * Security headers applied to every server response.
 *
 * Set headers BEFORE awaiting `next()` so they land on the outgoing response
 * regardless of what downstream handlers return (HTML, JSON, XML, binary).
 * Per-route handlers may still override these with their own headers.
 *
 * CSP is intentionally permissive for non-admin routes (blog images, OAuth
 * popups) and strict on /admin. `unsafe-inline` is required for the
 * theme-init script in __root.tsx and shadcn chart styles.
 */
const securityHeadersMiddleware = createMiddleware().server(async ({ next, request }) => {
  try {
    const url = new URL(request.url);
    const isAdmin = url.pathname === "/admin" || url.pathname.startsWith("/admin/");

    setResponseHeader("X-Content-Type-Options", "nosniff");
    setResponseHeader("Referrer-Policy", "strict-origin-when-cross-origin");
    setResponseHeader(
      "Permissions-Policy",
      "camera=(), microphone=(), geolocation=(), payment=()",
    );
    setResponseHeader("X-Frame-Options", isAdmin ? "DENY" : "SAMEORIGIN");

    const csp = [
      "default-src 'self'",
      "img-src 'self' data: blob: https:",
      "font-src 'self' data:",
      "style-src 'self' 'unsafe-inline'",
      // 'unsafe-eval' kept for non-production so Vite/HMR keeps working.
      "script-src 'self' 'unsafe-inline'" +
        (process.env.NODE_ENV === "production" ? "" : " 'unsafe-eval'"),
      "connect-src 'self' https: wss:",
      "frame-ancestors " + (isAdmin ? "'none'" : "'self'"),
      "base-uri 'self'",
      "form-action 'self'",
      "object-src 'none'",
    ].join("; ");
    // Report-only outside production to avoid breaking dev tooling unexpectedly.
    const cspHeader =
      process.env.NODE_ENV === "production"
        ? "Content-Security-Policy"
        : "Content-Security-Policy-Report-Only";
    setResponseHeader(cspHeader, csp);
  } catch {
    // Never let header logic break the request pipeline.
  }
  return next();
});

const errorMiddleware = createMiddleware().server(async ({ next }) => {
  try {
    return await next();
  } catch (error) {
    if (error != null && typeof error === "object" && "statusCode" in error) {
      throw error;
    }
    console.error(error);
    return new Response(renderErrorPage(), {
      status: 500,
      headers: { "content-type": "text/html; charset=utf-8" },
    });
  }
});

export const startInstance = createStart(() => ({
  // Order matters: errorMiddleware wraps everything so header logic failures
  // still surface as a clean 500.
  requestMiddleware: [errorMiddleware, securityHeadersMiddleware],
  functionMiddleware: [attachSupabaseAuth],
}));
