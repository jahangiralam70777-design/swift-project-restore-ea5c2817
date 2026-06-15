import { createFileRoute } from "@tanstack/react-router";
import { VideoClassesFlow } from "@/components/dashboard/VideoClassesFlow";
import { HiddenModuleGuard } from "@/components/dashboard/HiddenModuleGuard";

export const Route = createFileRoute("/_student/classes")({
  component: ClassesPage,
  head: () => ({
    meta: [
      { title: "Smart Video Classes · CA Aspire BD" },
      {
        name: "description",
        content:
          "Learn chapter-wise through premium interactive video lessons with playlist, instructor cards and progress tracking.",
      },
      { property: "og:title", content: "Smart Video Classes · CA Aspire BD" },
      {
        property: "og:description",
        content:
          "Cinematic glass player, chapter playlist and AI-recommended classes for fast, focused learning.",
      },
    ],
  }),
});

function ClassesPage() {
  return (
    <HiddenModuleGuard moduleKey="classes">
      <VideoClassesFlow />
    </HiddenModuleGuard>
  );
}
