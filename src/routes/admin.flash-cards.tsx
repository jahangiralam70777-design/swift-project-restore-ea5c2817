import { createFileRoute } from "@tanstack/react-router";
import { FlashCardManagerFlow } from "@/components/admin/FlashCardManagerFlow";

export const Route = createFileRoute("/admin/flash-cards")({
  component: AdminFlashCardsPage,
  head: () => ({
    meta: [
      { title: "Flash Card Manager · CA Aspire BD Admin" },
      {
        name: "description",
        content:
          "Create, organize and manage smart revision flash cards from the premium CA Aspire BD admin control center.",
      },
      { property: "og:title", content: "Flash Card Manager · CA Aspire BD Admin" },
      {
        property: "og:description",
        content:
          "Flash card builder, bulk import, analytics and publishing controls for administrators.",
      },
    ],
  }),
});

function AdminFlashCardsPage() {
  return <FlashCardManagerFlow />;
}
