import { createFileRoute } from "@tanstack/react-router";
import { DashContent } from "@/components/dashboard/DashContent";

export const Route = createFileRoute("/_student/dashboard")({
  component: DashboardPage,
  head: () => ({
    meta: [
      { title: "Dashboard · CA Aspire BD" },
      {
        name: "description",
        content:
          "Your personalized learning dashboard — MCQs, quizzes, mock tests, analytics and more.",
      },
    ],
  }),
});

function DashboardPage() {
  return <DashContent />;
}
