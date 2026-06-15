import { createFileRoute } from "@tanstack/react-router";
import { NotificationManagerFlow } from "@/components/admin/NotificationManagerFlow";

export const Route = createFileRoute("/admin/notifications")({
  component: AdminNotificationsPage,
  head: () => ({
    meta: [
      { title: "Notification Manager · CA Aspire BD Admin" },
      {
        name: "description",
        content:
          "Create, schedule and manage announcements, alerts and system notifications across push, email and in-app channels.",
      },
      { property: "og:title", content: "Notification Manager · CA Aspire BD Admin" },
      {
        property: "og:description",
        content:
          "Premium glass admin UI for crafting notifications, scheduling broadcasts and tracking delivery analytics.",
      },
    ],
  }),
});

function AdminNotificationsPage() {
  return <NotificationManagerFlow />;
}
