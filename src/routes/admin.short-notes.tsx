import { createFileRoute } from "@tanstack/react-router";
import { ShortNotesManagerFlow } from "@/components/admin/ShortNotesManagerFlow";

export const Route = createFileRoute("/admin/short-notes")({
  component: AdminShortNotesPage,
  head: () => ({
    meta: [
      { title: "Short Notes Manager · CA Aspire BD Admin" },
      {
        name: "description",
        content:
          "Upload, organize and manage chapter-wise smart revision notes from the premium CA Aspire BD admin control center.",
      },
      { property: "og:title", content: "Short Notes Manager · CA Aspire BD Admin" },
      {
        property: "og:description",
        content:
          "Short notes creator, bulk import, reader preview, analytics and publishing controls for administrators.",
      },
    ],
  }),
});

function AdminShortNotesPage() {
  return <ShortNotesManagerFlow />;
}
