import { createFileRoute } from "@tanstack/react-router";
import { SiteEditorV2Flow } from "@/components/admin/site-editor-v2/SiteEditorV2Flow";

export const Route = createFileRoute("/admin/site-editor")({
  component: SiteEditorV2Page,
  head: () => ({
    meta: [
      { title: "Advanced Editor (Phase 2) · CA Aspire BD Admin" },
      {
        name: "description",
        content:
          "Webflow-style draft editor with undo/redo, snapshot version history and diff viewer. Isolated from production Site Management.",
      },
    ],
  }),
});

function SiteEditorV2Page() {
  return <SiteEditorV2Flow />;
}
