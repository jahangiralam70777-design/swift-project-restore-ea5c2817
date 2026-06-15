import { createFileRoute } from "@tanstack/react-router";
import { LiveChatManager } from "@/components/admin/LiveChatManager";

export const Route = createFileRoute("/admin/live-chat")({
  component: LiveChatPage,
});

function LiveChatPage() {
  return (
    <div className="space-y-4">
      <div>
        <h1 className="text-2xl font-bold tracking-tight">Live Chat Manager</h1>
        <p className="text-sm text-muted-foreground">
          Support Center · Real-time conversations with students
        </p>
      </div>
      <LiveChatManager />
    </div>
  );
}
