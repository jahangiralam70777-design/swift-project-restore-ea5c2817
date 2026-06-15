import { createFileRoute } from "@tanstack/react-router";
import { CustomExamFlow } from "@/components/dashboard/CustomExamFlow";

export const Route = createFileRoute("/_student/custom-exam")({
  component: CustomExamPage,
  head: () => ({
    meta: [
      { title: "Custom Exam · CA Aspire BD" },
      {
        name: "description",
        content: "Build a custom exam: choose level, subject, chapters, MCQ count and duration.",
      },
    ],
  }),
});

function CustomExamPage() {
  return <CustomExamFlow />;
}
