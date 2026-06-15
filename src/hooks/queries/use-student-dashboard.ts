/**
 * Student dashboard hooks.
 */
import { queryOptions, useQuery } from "@tanstack/react-query";
import * as StudentDashboardService from "@/lib/services/student-dashboard.service";

export const studentDashboardQueries = {
  snapshot: () =>
    queryOptions({
      queryKey: ["student", "dashboard", "snapshot"] as const,
      queryFn: () => StudentDashboardService.getDashboardSnapshot(),
    }),
};

export const useStudentDashboardSnapshot = () => useQuery(studentDashboardQueries.snapshot());
