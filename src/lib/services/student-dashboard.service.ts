/**
 * Student dashboard service — composes student-facing dashboard repository calls.
 */
import { StudentDashboard } from "@/lib/repositories";

export type StudentDashboardData = Awaited<ReturnType<typeof StudentDashboard.studentDashboardSnapshot>>;

export async function getDashboardSnapshot(): Promise<StudentDashboardData> {
  return StudentDashboard.studentDashboardSnapshot();
}
