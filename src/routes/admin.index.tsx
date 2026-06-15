import { createFileRoute } from "@tanstack/react-router";
import { AdminFlow } from "@/components/admin/AdminFlow";

export const Route = createFileRoute("/admin/")({
  component: AdminDashboardPage,
  head: () => ({
    meta: [
      { title: "Admin Dashboard · CA Aspire BD" },
      {
        name: "description",
        content:
          "Open the CA Aspire BD admin dashboard for live metrics, activity, quick actions and platform status.",
      },
      { property: "og:title", content: "Admin Dashboard · CA Aspire BD" },
      {
        property: "og:description",
        content:
          "Live metrics, content operations and platform controls for CA Aspire BD administrators.",
      },
    ],
  }),
});

function AdminDashboardPage() {
  return <AdminFlow />;
}
