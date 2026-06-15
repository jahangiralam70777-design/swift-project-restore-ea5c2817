import { QueryClient, QueryClientProvider, useQueryClient } from "@tanstack/react-query";
import {
  Outlet,
  Link,
  Navigate,
  createRootRouteWithContext,
  useRouter,
  useLocation,
  HeadContent,
  Scripts,
} from "@tanstack/react-router";
import { Suspense, useEffect, useMemo, useRef } from "react";
import { Toaster } from "@/components/ui/sonner";
import { hasLocalAuthSession, useAppStore } from "@/stores/app-store";
import { useRealtimeInvalidator } from "@/hooks/use-realtime-invalidator";
import { usePrefs } from "@/lib/profile-prefs";
import { ThemeInjector } from "@/components/site/ThemeInjector";
import { SingleSessionGuard } from "@/components/auth/SingleSessionGuard";
import { SessionTimeoutGuard } from "@/components/auth/SessionTimeoutGuard";
import { ActivityTracker } from "@/components/tracking/ActivityTracker";
import { RootErrorBoundary } from "@/components/RootErrorBoundary";
import { installGlobalErrorReporter, reportError } from "@/lib/error-reporter";
import { useNavTiming } from "@/lib/nav-timing";
import { SkipToContent } from "@/components/a11y/SkipToContent";
import { LiveRegionProvider } from "@/components/a11y/LiveRegion";
import { ConfirmDialogHost } from "@/components/ui/confirm-imperative";
import { WhatsAppFloatingButton } from "@/components/site/WhatsAppFloatingButton";
import { LiveChatWidget } from "@/components/site/LiveChatWidget";

import appCss from "../styles.css?url";

// A-9: silence non-essential console output in production builds. Errors and
// warnings are preserved so reportError + browser DevTools still surface real
// problems; only `console.log/debug/info` are stripped to avoid leaking
// internal state to end users.
if (typeof window !== "undefined" && import.meta.env.PROD) {
  const noop = () => undefined;
  // eslint-disable-next-line no-console
  console.log = noop;
  // eslint-disable-next-line no-console
  console.debug = noop;
  // eslint-disable-next-line no-console
  console.info = noop;
}

function NotFoundComponent() {
  return (
    <main id="main-content" className="flex min-h-dvh items-center justify-center bg-background px-4">
      <div className="max-w-md text-center">
        <p aria-hidden="true" className="text-7xl font-bold text-muted-foreground/40">
          404
        </p>
        <h1 className="mt-4 text-2xl font-semibold text-foreground">Page not found</h1>
        <p className="mt-2 text-sm text-muted-foreground">
          The page you're looking for doesn't exist or has been moved.
        </p>
        <div className="mt-6">
          <Link
            to="/"
            className="inline-flex min-h-11 items-center justify-center rounded-md bg-primary px-4 py-2 text-sm font-medium text-primary-foreground transition-colors hover:bg-primary/90 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2"
          >
            Go home
          </Link>
        </div>
      </div>
    </main>
  );
}

function ErrorComponent({ error, reset }: { error: Error; reset: () => void }) {
  console.error(error);
  const router = useRouter();
  // Capture route-level render failures into the system error log.
  useEffect(() => {
    reportError({
      source: "frontend",
      severity: "critical",
      message: error.message || "Route render failure",
      stack: error.stack,
    });
  }, [error]);

  return (
    <div className="flex min-h-dvh items-center justify-center bg-background px-4">
      <div className="max-w-md text-center">
        <h1 className="text-xl font-semibold tracking-tight text-foreground">
          This page didn't load
        </h1>
        <p className="mt-2 text-sm text-muted-foreground">
          Something went wrong on our end. You can try refreshing or head back home.
        </p>
        <div className="mt-6 flex flex-wrap justify-center gap-2">
          <button
            onClick={() => {
              router.invalidate();
              reset();
            }}
            className="inline-flex items-center justify-center rounded-md bg-primary px-4 py-2 text-sm font-medium text-primary-foreground transition-colors hover:bg-primary/90"
          >
            Try again
          </button>
          <a
            href="/"
            className="inline-flex items-center justify-center rounded-md border border-input bg-background px-4 py-2 text-sm font-medium text-foreground transition-colors hover:bg-accent"
          >
            Go home
          </a>
        </div>
      </div>
    </div>
  );
}

export const Route = createRootRouteWithContext<{ queryClient: QueryClient }>()({
  head: () => ({
    meta: [
      { charSet: "utf-8" },
      { name: "viewport", content: "width=device-width, initial-scale=1" },
      { title: "CA Aspire BD — Professional ICAB & Chartered Accountancy Learning Platform" },
      {
        name: "description",
        content:
          "CA Aspire BD — Professional CA learning platform for ICAB students with MCQ practice, mock tests, quizzes, flash cards, notes, analytics and performance tracking across Financial Accounting, Audit, Taxation and Business Law.",
      },
      {
        name: "keywords",
        content:
          "CA Aspire BD, ICAB, Chartered Accountancy, CA exam preparation, CA MCQ practice, CA mock test, Financial Accounting, Audit, Taxation, Business Law, Financial Reporting, Management Accounting, CA Bangladesh",
      },
      { name: "author", content: "CA Aspire BD" },
      {
        property: "og:title",
        content: "CA Aspire BD — ICAB & Chartered Accountancy Learning Platform",
      },
      {
        property: "og:description",
        content:
          "Professional CA learning platform for ICAB students — MCQ practice, mock tests, flash cards, notes & analytics.",
      },
      { property: "og:type", content: "website" },
      { name: "twitter:card", content: "summary" },
    ],
    links: [
      {
        rel: "stylesheet",
        href: appCss,
      },
    ],
  }),
  shellComponent: RootShell,
  component: RootComponent,
  notFoundComponent: NotFoundComponent,
  errorComponent: ErrorComponent,
});

const THEME_INIT_SCRIPT = `(function(){try{document.documentElement.classList.toggle('dark',localStorage.getItem('edumaster.theme')==='dark');}catch(e){document.documentElement.classList.remove('dark');}})();`;

function RootShell({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" suppressHydrationWarning>
      <head>
        <HeadContent />
        <script dangerouslySetInnerHTML={{ __html: THEME_INIT_SCRIPT }} />
      </head>
      <body suppressHydrationWarning>
        {children}
        <Scripts />
      </body>
    </html>
  );
}

function RootComponent() {
  const { queryClient } = Route.useRouteContext();

  return (
    <RootErrorBoundary>
      <QueryClientProvider client={queryClient}>
        <ThemeInjector />
        <LiveRegionProvider>
          <SkipToContent />
          <RootInner />
        </LiveRegionProvider>
        <Toaster position="top-right" richColors closeButton />
      </QueryClientProvider>
    </RootErrorBoundary>
  );
}

const AUTH_ROUTES = [
  "/login",
  "/signup",
  "/register",
  "/admin/login",
  "/forgot-password",
  "/reset-password",
  "/email-verified",
];
const STUDENT_ROUTES = [
  "/dashboard",
  "/mcq-practice",
  "/quiz",
  "/custom-exam",
  "/mock-test",
  "/flash-cards",
  "/short-notes",
  "/qns-bank",
  "/classes",
  "/notifications",
  "/profile",
  "/bookmarks",
  "/wrong-questions",
];

function RootInner() {
  const location = useLocation();
  const router = useRouter();
  const queryClient = useQueryClient();
  const { hydrate, user, authVersion } = useAppStore();
  useNavTiming();
  const lastAuthVersion = useRef(authVersion);
  const isSitePreviewFrame =
    typeof window !== "undefined" &&
    new URLSearchParams(window.location.search).get("site-preview") === "1";

  // Apply user prefs (accent color, font size) to <html> on every mount.
  usePrefs();

  // Must be inside QueryClientProvider — uses useQueryClient internally.
  useRealtimeInvalidator(Boolean(user));

  useEffect(() => {
    if (isSitePreviewFrame) return;
    hydrate();
  }, [hydrate, isSitePreviewFrame]);

  useEffect(() => {
    if (typeof window === "undefined") return;
    try {
      const url = import.meta.env.VITE_SUPABASE_URL || "";
      const key = import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY || "";
      const host = url ? new URL(url).host : null;
      console.log("[app] backend config", {
        supabaseConfigured: Boolean(url && key),
        projectHost: host,
        publishableKeyPrefix: key ? `${key.slice(0, 12)}…` : null,
        path: window.location.pathname,
      });
    } catch (error) {
      console.warn("[app] backend config check failed", error);
    }
  }, []);

  // Install window-level error + unhandled-rejection reporters once.
  useEffect(() => {
    installGlobalErrorReporter();
  }, []);

  useEffect(() => {
    if (authVersion === lastAuthVersion.current) return;
    lastAuthVersion.current = authVersion;
    console.debug("[auth] global refresh", { authVersion, hasUser: !!user });
    queryClient.invalidateQueries();
    void router.invalidate();
    (router as unknown as { refresh?: () => void }).refresh?.();
  }, [authVersion, queryClient, router, user]);

  const path = location.pathname;
  // /admin/login is a PUBLIC admin sign-in page — it must not be treated as a
  // protected admin route (otherwise unauthenticated visitors get bounced).
  const isAdminLogin = path === "/admin/login";
  const isAdminRoute = !isAdminLogin && (path === "/admin" || path.startsWith("/admin/"));
  const isStudentRoute = STUDENT_ROUTES.includes(path);

  const hasPersistedSession = useMemo(() => {
    return hasLocalAuthSession();
  }, [path, user]);

  const redirectTo = useMemo(() => {
    if (typeof window === "undefined") return null;
    if (user && AUTH_ROUTES.includes(path)) {
      // Never bounce a signed-in user off /admin/login to /dashboard —
      // that's the source of the "admin menu → /dashboard" loop when the
      // store still holds a stale default role of "student" while the
      // real role is being resolved. Only auto-forward confirmed admins;
      // everyone else stays put on the admin sign-in page.
      if (path === "/admin/login") {
        return user.role === "admin" || user.role === "super_admin" ? "/admin" : null;
      }
      return user.role === "admin" || user.role === "super_admin" ? "/admin" : "/dashboard";
    }
    if (!hasPersistedSession && (isAdminRoute || isStudentRoute)) return "/login";
    return null;
  }, [path, user, isAdminRoute, isStudentRoute, hasPersistedSession]);

  if (redirectTo) return <Navigate to={redirectTo as never} replace />;
  return (
    // Empty fallback: route chunks preload on link hover (defaultPreload: "intent"),
    // so navigation almost never suspends. Avoiding a full-screen spinner here
    // prevents the "black screen during route change" flicker.
    <Suspense fallback={null}>
      <SingleSessionGuard />
      <SessionTimeoutGuard />
      <ActivityTracker />
      <Outlet />
      <ConfirmDialogHost />
      <WhatsAppFloatingButton />
      <LiveChatWidget />
    </Suspense>
  );
}
