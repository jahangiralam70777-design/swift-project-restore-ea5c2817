import { createFileRoute } from "@tanstack/react-router";
import { QuizFlow } from "@/components/dashboard/QuizFlow";

export const Route = createFileRoute("/_student/quiz")({
  component: QuizPage,
  head: () => ({
    meta: [
      { title: "Quiz · CA Aspire BD" },
      {
        name: "description",
        content: "Timer-based 10 MCQ quizzes with instant scoring, accuracy and review.",
      },
    ],
  }),
});

function QuizPage() {
  return <QuizFlow />;
}
