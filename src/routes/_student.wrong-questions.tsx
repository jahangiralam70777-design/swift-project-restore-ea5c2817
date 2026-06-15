import { createFileRoute } from "@tanstack/react-router";
import { WrongQuestionsFlow } from "@/components/dashboard/WrongQuestionsFlow";

export const Route = createFileRoute("/_student/wrong-questions")({
  component: () => <WrongQuestionsFlow />,
  head: () => ({
    meta: [{ title: "Wrong Questions · CA Aspire BD" }],
  }),
});
