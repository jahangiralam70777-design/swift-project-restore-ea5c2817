import { createFileRoute, Outlet, redirect, useNavigate } from "@tanstack/react-router";
import { useEffect } from "react";

import { DashSidebar } from "@/components/dashboard/DashSidebar";
import { DashTopbar } from "@/components/dashboard/DashTopbar";
import { StudyHeartbeat } from "@/components/tracking/StudyHeartbeat";
import { NoticeBanner } from "@/components/site/NoticeBanner";
import { useAppStore, hasLocalAuthSession } from "@/stores/app-store";

export const Route = createFileRoute("/_student")({
  // Supabase session lives in localStorage; SSR cannot read it, so render
  // the protected subtree client-only. The synchronous beforeLoad gate
  // gives SSR-safe, no-flash protection before any child renders.
  ssr: false,
  beforeLoad: ({ location }) => {
    if (typeof window === "undefined") return;
    if (!hasLocalAuthSession()) {
      throw redirect({ to: "/login", search: { redirect: location.href } });
    }
  },
  component: StudentLayout,
});

function StudentGate({ children }: { children: React.ReactNode }) {
  const user = useAppStore((s) => s.user);
  const sessionReady = useAppStore((s) => s.sessionReady);
  const authLoading = useAppStore((s) => s.authLoading);
  const navigate = useNavigate();

  // Instant navigation: never block rendering on auth/profile fetches.
  // The synchronous beforeLoad gate above already short-circuits
  // unauthenticated visits via localStorage. Role checks run silently
  // in the background; if the user turns out to not be a student we
  // redirect without ever showing a loading or denied screen.
  useEffect(() => {
    if (!sessionReady || authLoading) return;
    if (!user) {
      navigate({ to: "/login", replace: true });
      return;
    }
    if (user.role !== "student") {
      navigate({ to: "/login", replace: true });
    }
  }, [sessionReady, authLoading, user, navigate]);

  return <>{children}</>;
}

function StudentLayout() {
  return (
    <div className="relative min-h-dvh overflow-x-hidden bg-background text-foreground">
      <div className="pointer-events-none fixed inset-0 -z-10 bg-hero-glow opacity-60" />
      <div className="pointer-events-none fixed left-10 top-20 -z-10 h-72 w-72 rounded-full bg-[var(--neon-purple)]/20 blur-3xl animate-pulse-glow" />
      <div className="pointer-events-none fixed right-10 bottom-10 -z-10 h-80 w-80 rounded-full bg-[var(--neon-blue)]/20 blur-3xl animate-pulse-glow" />
      <div className="pointer-events-none fixed left-1/2 top-1/3 -z-10 h-64 w-64 rounded-full bg-fuchsia-500/10 blur-3xl animate-pulse-glow" />

      {/* H-2 fix: sidebar + topbar moved INSIDE StudentGate so an
          unauthenticated visitor hitting a /dashboard URL doesn't see the
          authenticated chrome (nav items, branded topbar) before the
          redirect fires. */}
      <div className="mx-auto flex max-w-[1500px] gap-4 px-4 py-4 sm:px-6">
        <StudentGate>
          <DashSidebar />
          <div className="pointer-events-auto min-w-0 flex-1 space-y-4">
            <DashTopbar />
            <NoticeBanner />
            <StudyHeartbeat />
            <Outlet />
          </div>
        </StudentGate>
      </div>
    </div>
  );
}

