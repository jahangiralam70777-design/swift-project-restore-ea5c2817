import { createFileRoute } from "@tanstack/react-router";
import { BroadcastManager } from "@/components/admin/BroadcastManager";

export const Route = createFileRoute("/admin/broadcasts")({
  component: BroadcastsPage,
});

function BroadcastsPage() {
  return <BroadcastManager />;
}
