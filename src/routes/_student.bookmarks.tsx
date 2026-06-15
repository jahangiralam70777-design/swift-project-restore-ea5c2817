import { createFileRoute } from "@tanstack/react-router";
import { BookmarksFlow } from "@/components/dashboard/BookmarksFlow";

export const Route = createFileRoute("/_student/bookmarks")({
  component: () => <BookmarksFlow />,
  head: () => ({
    meta: [{ title: "Bookmarks · CA Aspire BD" }],
  }),
});
