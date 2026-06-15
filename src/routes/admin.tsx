import {
  createFileRoute,
  Outlet,
  redirect,
  useNavigate,
  useLocation,
} from "@tanstack/react-router";
import { useEffect, useState } from "react";
import { AdminSidebar } from "@/components/admin/AdminSidebar";
import { useAppStore, hasLocalAuthSession } from "@/stores/app-store";
import { supabase } from "@/integrations/supabase/client";
import { verifyAdminAccess, type VerifyAdminAccessResult } from "@/lib/admin-verify.functions";
import { useServerFn } from "@tanstack/react-start";

export const Route = createFileRoute("/admin")({
  // Admin session lives in localStorage (Supabase). SSR-skip + a
  // synchronous beforeLoad gate prevents admin chrome from being
  // streamed to anonymous visitors. Server-verified role check still
  // runs inside <AdminGate /> against `user_roles`.
  ssr: false,
  beforeLoad: ({ location }) => {
    if (typeof window === "undefined") return;
    if (location.pathname === "/admin/login") return; // public sub-route
    if (!hasLocalAuthSession()) {
      throw redirect({ to: "/admin/login" });
    }
  },
  component: AdminLayout,
  head: () => ({
    meta: [
      { title: "Admin Control Center · CA Aspire BD" },
      { name: "robots", content: "noindex, nofollow" },
      {
        name: "description",
        content:
          "Manage students, exams, resources and platform analytics from the premium glassmorphism CA Aspire BD admin dashboard.",
      },
    ],
  }),
});

function AdminGate({ children }: { children: React.ReactNode }) {
  const user = useAppStore((s) => s.user);
  const sessionReady = useAppStore((s) => s.sessionReady);
  const authLoading = useAppStore((s) => s.authLoading);
  const refreshAuth = useAppStore((s) => s.refreshAuth);
  const navigate = useNavigate();
  const verifyAdmin = useServerFn(verifyAdminAccess);
  const [verified, setVerified] = useState(false);

  // Instant navigation: never block rendering on auth/role checks.
  // The synchronous beforeLoad gate already redirects unauthenticated
  // visitors via localStorage. Server-side admin role verification runs
  // silently in the background; if it fails we redirect without ever
  // rendering a loading or denied screen.
  useEffect(() => {
    if (!user && hasLocalAuthSession()) void refreshAuth({ force: true });
  }, [refreshAuth, user]);

  useEffect(() => {
    let cancelled = false;
    setVerified(false);
    if (!sessionReady || authLoading) return;
    (async () => {
      const { data: userData, error: userErr } = await supabase.auth.getUser();
      if (cancelled) return;
      if (userErr || !userData.user) {
        navigate({ to: "/admin/login", replace: true });
        return;
      }
      const { data: sess } = await supabase.auth.getSession();
      if (cancelled) return;
      const hasToken = !!sess.session?.access_token;
      if (!hasToken) {
        navigate({ to: "/admin/login", replace: true });
        return;
      }
      try {
        console.info("[admin-route] session user", {
          id: userData.user.id,
          email: userData.user.email,
          appMetadata: userData.user.app_metadata,
          userMetadata: userData.user.user_metadata,
        });
        const result = (await verifyAdmin()) as VerifyAdminAccessResult;
        if (cancelled) return;
        if (result?.degraded) {
          console.warn("[admin-route] admin verification degraded", {
            userId: userData.user.id,
            reason: result.reason,
          });
          return;
        }
        if (!result?.isAdmin) {
          console.warn("[admin-route] verifyAdmin returned non-admin", {
            userId: userData.user.id,
            sources: result?.sources,
          });
          navigate({ to: "/admin/login", replace: true });
          return;
        }
        console.info("[admin-route] admin verified", { userId: userData.user.id, role: result.role });
        setVerified(true);
      } catch (error) {
        if (cancelled) return;
        console.warn("[admin-route] admin verification request failed", {
          userId: userData.user.id,
          error: error instanceof Error ? error.message : String(error),
        });
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [authLoading, sessionReady, user?.id, navigate, verifyAdmin]);

  if (!verified) {
    return <div className="min-h-[60dvh] flex-1 animate-pulse rounded-lg border border-border bg-muted/20" />;
  }

  return <>{children}</>;
}

function AdminLayout() {
  const path = useLocation({ select: (l) => l.pathname });

  // The admin login page lives at /admin/login but must be publicly reachable
  // (no sidebar, no gate) so unauthenticated admins can sign in.
  if (path === "/admin/login") {
    return (
      <div className="relative min-h-dvh overflow-x-hidden bg-background text-foreground">
        <div className="pointer-events-none fixed inset-0 -z-10 bg-hero-glow opacity-60" />
        <Outlet />
      </div>
    );
  }

  // H-4: AdminSidebar must NOT render until `verifyAdminAccess` confirms.
  // Previously it was a sibling of <AdminGate/> and therefore visible to
  // anyone hitting /admin (revealing the admin nav structure). It now
  // lives inside the gate, so non-admins see only the gate's loading /
  // forbidden / demo card.
  return (
    <div className="relative min-h-dvh overflow-x-hidden bg-background text-foreground">
      <div className="pointer-events-none fixed inset-0 -z-10 bg-hero-glow opacity-60" />
      <div className="pointer-events-none fixed left-10 top-20 -z-10 h-72 w-72 rounded-full bg-[var(--neon-purple)]/20 blur-3xl animate-pulse-glow" />
      <div className="pointer-events-none fixed right-10 bottom-10 -z-10 h-80 w-80 rounded-full bg-[var(--neon-blue)]/20 blur-3xl animate-pulse-glow" />
      <div className="pointer-events-none fixed left-1/2 top-1/3 -z-10 h-64 w-64 rounded-full bg-fuchsia-500/10 blur-3xl animate-pulse-glow" />

      <div className="mx-auto flex max-w-[1600px] gap-4 px-4 py-4 sm:px-6">
        <AdminGate>
          <AdminSidebar />
          <div className="pointer-events-auto min-w-0 flex-1 space-y-4">
            <Outlet />
          </div>
        </AdminGate>
      </div>
    </div>
  );
}
