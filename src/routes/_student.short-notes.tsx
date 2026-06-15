import { createFileRoute } from "@tanstack/react-router";
import { ShortNotesFlow } from "@/components/dashboard/ShortNotesFlow";
import { HiddenModuleGuard } from "@/components/dashboard/HiddenModuleGuard";

export const Route = createFileRoute("/_student/short-notes")({
  component: ShortNotesPage,
  head: () => ({
    meta: [
      { title: "Smart Short Notes · CA Aspire BD" },
      {
        name: "description",
        content:
          "Quick chapter-wise short notes for fast revision. Search, bookmark, zoom and download as PDF.",
      },
      { property: "og:title", content: "Smart Short Notes · CA Aspire BD" },
      {
        property: "og:description",
        content:
          "Premium glassmorphism reading experience with text/PDF modes, highlights and AI-recommended notes.",
      },
    ],
  }),
});

function ShortNotesPage() {
  return (
    <HiddenModuleGuard moduleKey="short_notes">
      <ShortNotesFlow />
    </HiddenModuleGuard>
  );
}
