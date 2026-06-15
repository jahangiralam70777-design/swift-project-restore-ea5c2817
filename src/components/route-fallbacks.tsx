import { Link, useRouter } from "@tanstack/react-router";
import { AlertTriangle } from "lucide-react";

// Instant navigation: never render a pending fallback between routes.
// Previous page stays on screen until the next route is ready (TanStack
// Router default behavior when no pending component is shown).
export function DefaultPendingFallback() {
  return null;
}

export function DefaultNotFoundFallback() {
  return (
    <div className="flex min-h-[40vh] items-center justify-center px-4">
      <div className="max-w-md text-center">
        <h2 className="text-lg font-semibold text-foreground">Not found</h2>
        <p className="mt-2 text-sm text-muted-foreground">
          The page or resource you're looking for doesn't exist.
        </p>
        <div className="mt-4">
          <Link
            to="/"
            className="inline-flex items-center justify-center rounded-md bg-primary px-4 py-2 text-sm font-medium text-primary-foreground hover:bg-primary/90"
          >
            Go home
          </Link>
        </div>
      </div>
    </div>
  );
}

export function DefaultErrorFallback({ error, reset }: { error: Error; reset: () => void }) {
  const router = useRouter();
  if (typeof console !== "undefined") {
    console.error("[route-error]", error);
  }
  const message =
    error?.message?.includes("Unauthorized") || error?.message?.includes("permission denied")
      ? "You don't have permission to view this. Ask an admin if you think this is a mistake."
      : "Something went wrong loading this page. You can try again or head back home.";

  return (
    <div className="flex min-h-[40vh] items-center justify-center px-4 py-10">
      <div className="max-w-md text-center">
        <div className="mx-auto flex h-12 w-12 items-center justify-center rounded-full bg-destructive/10">
          <AlertTriangle className="h-6 w-6 text-destructive" />
        </div>
        <h2 className="mt-4 text-lg font-semibold text-foreground">This section didn't load</h2>
        <p className="mt-2 text-sm text-muted-foreground">{message}</p>
        <div className="mt-6 flex flex-wrap justify-center gap-2">
          <button
            onClick={() => {
              router.invalidate();
              reset();
            }}
            className="inline-flex items-center justify-center rounded-md bg-primary px-4 py-2 text-sm font-medium text-primary-foreground hover:bg-primary/90"
          >
            Try again
          </button>
          <Link
            to="/"
            className="inline-flex items-center justify-center rounded-md border border-input bg-background px-4 py-2 text-sm font-medium text-foreground hover:bg-accent"
          >
            Go home
          </Link>
        </div>
      </div>
    </div>
  );
}
