import { QueryClient } from "@tanstack/react-query";
import { createRouter } from "@tanstack/react-router";
import { routeTree } from "./routeTree.gen";
import {
  DefaultErrorFallback,
  DefaultNotFoundFallback,
  DefaultPendingFallback,
} from "./components/route-fallbacks";

export const getRouter = () => {
  const queryClient = new QueryClient({
    defaultOptions: {
      queries: {
        // Reuse cached data across navigations — keeps page switches instant.
        staleTime: 60_000,
        gcTime: 5 * 60_000,
        refetchOnWindowFocus: false,
        refetchOnReconnect: false,
        retry: 1,
      },
    },
  });

  const router = createRouter({
    routeTree,
    context: { queryClient },
    scrollRestoration: true,
    defaultPreload: "intent",
    defaultPreloadDelay: 30,
    defaultPreloadStaleTime: 0,
    defaultErrorComponent: DefaultErrorFallback,
    defaultNotFoundComponent: DefaultNotFoundFallback,
    defaultPendingComponent: DefaultPendingFallback,
    // Never flash a pending UI during navigation — keep the previous page
    // visible until the next route is ready.
    defaultPendingMs: 10_000,
    defaultPendingMinMs: 0,
  });

  return router;
};
