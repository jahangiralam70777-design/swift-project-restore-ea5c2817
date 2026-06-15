import { createFileRoute } from "@tanstack/react-router";
import { DatabaseManagerFlow } from "@/components/admin/DatabaseManagerFlow";

export const Route = createFileRoute("/admin/database")({
  component: DatabaseManagerPage,
  head: () => ({
    meta: [
      { title: "Database Manager · CA Aspire BD Admin" },
      {
        name: "description",
        content:
          "Real-time database analytics, storage breakdown by table, daily growth trends and system health for CA Aspire BD admins.",
      },
    ],
  }),
});

function DatabaseManagerPage() {
  return <DatabaseManagerFlow />;
}
