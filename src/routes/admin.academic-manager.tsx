import { createFileRoute } from "@tanstack/react-router";
import { AcademicStructureManager } from "@/components/admin/AcademicStructureManager";

export const Route = createFileRoute("/admin/academic-manager")({
  component: AcademicManagerPage,
  head: () => ({
    meta: [
      { title: "Academic Manager · CA Aspire BD Admin" },
      {
        name: "description",
        content:
          "Centralized Level, Subject and Chapter management — the single source of truth for the CA Aspire BD academic hierarchy.",
      },
      { property: "og:title", content: "Academic Manager · CA Aspire BD Admin" },
      {
        property: "og:description",
        content:
          "Manage levels, subjects, chapters and connected content from one enterprise-grade hierarchy console.",
      },
    ],
  }),
});

function AcademicManagerPage() {
  return <AcademicStructureManager />;
}
