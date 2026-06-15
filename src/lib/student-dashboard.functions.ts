import { createServerFn } from "@tanstack/react-start";
import { requireSupabaseAuth } from "@/integrations/supabase/auth-middleware";

/**
 * Aggregates everything the student dashboard renders so the UI can stay
 * one query + one realtime invalidator. RLS is respected via the
 * `requireSupabaseAuth` middleware so each call is scoped to the caller.
 */
export const studentDashboardSnapshot = createServerFn({ method: "GET" })
  .middleware([requireSupabaseAuth])
  .handler(async ({ context }) => {
    const { supabase, userId } = context;

    const since30 = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString();
    const since7 = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString();

    const [
      mcqCountR,
      mcqWeekR,
      quizCountR,
      quizWeekR,
      mockCountR,
      mockWeekR,
      notesCountR,
      classesCountR,
      attemptsR,
      notificationsR,
      upcomingMockR,
      recommendedQuizR,
      subjectsR,
    ] = await Promise.all([
      supabase.from("mcqs").select("id", { count: "exact", head: true }).eq("status", "published"),
      supabase
        .from("mcqs")
        .select("id", { count: "exact", head: true })
        .eq("status", "published")
        .gte("created_at", since7),
      supabase
        .from("quizzes")
        .select("id", { count: "exact", head: true })
        .eq("status", "published")
        .eq("kind", "quiz"),
      supabase
        .from("quizzes")
        .select("id", { count: "exact", head: true })
        .eq("status", "published")
        .eq("kind", "quiz")
        .gte("created_at", since7),
      supabase
        .from("quizzes")
        .select("id", { count: "exact", head: true })
        .eq("status", "published")
        .eq("kind", "mock"),
      supabase
        .from("quizzes")
        .select("id", { count: "exact", head: true })
        .eq("status", "published")
        .eq("kind", "mock")
        .gte("created_at", since7),
      supabase
        .from("short_notes")
        .select("id", { count: "exact", head: true })
        .eq("status", "published")
        .eq("is_hidden", false),
      supabase
        .from("video_classes")
        .select("id", { count: "exact", head: true })
        .eq("status", "published")
        .eq("is_hidden", false),
      supabase
        .from("exam_attempts")
        .select("id,quiz_id,score,correct_count,total_count,completed_at,started_at,status")
        .eq("user_id", userId)
        .gte("started_at", since30)
        .order("started_at", { ascending: false })
        .limit(50),
      supabase
        .from("notifications")
        .select("id,title,body,priority,sent_at,created_at,type")
        .eq("status", "sent")
        .order("sent_at", { ascending: false, nullsFirst: false })
        .limit(6),
      supabase
        .from("quizzes")
        .select("id,title,total_questions,duration_seconds,starts_at,kind,created_at")
        .eq("status", "published")
        .eq("kind", "mock")
        .order("starts_at", { ascending: true, nullsFirst: false })
        .limit(1),
      supabase
        .from("quizzes")
        .select(
          "id,title,description,total_questions,duration_seconds,subject_id,created_at,kind,level",
        )
        .eq("status", "published")
        .eq("kind", "quiz")
        .order("created_at", { ascending: false })
        .limit(8),
      supabase.from("subjects").select("id,name,color").eq("status", "published"),
    ]);

    const attempts = attemptsR.data ?? [];
    const completed = attempts.filter((a) => a.status === "completed");

    // Accuracy
    const totals = completed.reduce(
      (acc, a) => {
        acc.correct += a.correct_count ?? 0;
        acc.total += a.total_count ?? 0;
        return acc;
      },
      { correct: 0, total: 0 },
    );
    const accuracy = totals.total > 0 ? Math.round((totals.correct / totals.total) * 1000) / 10 : 0;

    // Streak: consecutive days (in user TZ approximated as UTC) ending today/yesterday with ≥1 completion
    const dayKeys = new Set(
      completed
        .map((a) => a.completed_at ?? a.started_at)
        .filter(Boolean)
        .map((d) => new Date(d as string).toISOString().slice(0, 10)),
    );
    let streak = 0;
    const cursor = new Date();
    // Allow today to be empty without breaking the streak
    if (!dayKeys.has(cursor.toISOString().slice(0, 10))) {
      cursor.setUTCDate(cursor.getUTCDate() - 1);
    }
    while (dayKeys.has(cursor.toISOString().slice(0, 10))) {
      streak += 1;
      cursor.setUTCDate(cursor.getUTCDate() - 1);
    }

    // Weekly bars (Mon..Sun accuracy of attempts that day, 0 if none)
    const today = new Date();
    const bars: number[] = [];
    for (let i = 6; i >= 0; i--) {
      const d = new Date(today);
      d.setUTCDate(today.getUTCDate() - i);
      const key = d.toISOString().slice(0, 10);
      const day = completed.filter(
        (a) => (a.completed_at ?? a.started_at ?? "").slice(0, 10) === key,
      );
      const t = day.reduce((s, a) => s + (a.total_count ?? 0), 0);
      const c = day.reduce((s, a) => s + (a.correct_count ?? 0), 0);
      bars.push(t ? Math.round((c / t) * 100) : 0);
    }

    // Continue learning: latest unique quizzes the user attempted but didn't finish 100%
    const seen = new Set<string>();
    const continueLearning = completed
      .filter((a) => {
        if (!a.quiz_id || seen.has(a.quiz_id)) return false;
        seen.add(a.quiz_id);
        return (a.score ?? 0) < 100;
      })
      .slice(0, 3);

    // Hydrate continueLearning titles
    let learning: Array<{ id: string; title: string; progress: number }> = [];
    if (continueLearning.length) {
      const ids = continueLearning.map((a) => a.quiz_id!) as string[];
      const { data: quizzesData } = await supabase
        .from("quizzes")
        .select("id,title,subject_id")
        .in("id", ids);
      const map = new Map((quizzesData ?? []).map((q) => [q.id, q]));
      learning = continueLearning.map((a) => ({
        id: a.quiz_id!,
        title: map.get(a.quiz_id!)?.title ?? "Resume session",
        progress: a.score ?? 0,
      }));
    }

    // Recommendations: most recent quizzes user has not attempted
    const attemptedIds = new Set(completed.map((a) => a.quiz_id).filter(Boolean));
    const recommendations = (recommendedQuizR.data ?? [])
      .filter((q) => !attemptedIds.has(q.id))
      .slice(0, 4);

    // Subject performance: group attempts by subject (via quiz lookup)
    const quizSubjectMap = new Map<string, string | null>();
    const allQuizIds = [
      ...new Set([
        ...completed.map((a) => a.quiz_id).filter(Boolean),
        ...(recommendedQuizR.data ?? []).map((q) => q.id),
      ]),
    ] as string[];
    if (allQuizIds.length) {
      const { data: qSubs } = await supabase
        .from("quizzes")
        .select("id,subject_id")
        .in("id", allQuizIds);
      (qSubs ?? []).forEach((q) => quizSubjectMap.set(q.id, q.subject_id ?? null));
    }

    const subjectAgg = new Map<string, { correct: number; total: number }>();
    for (const a of completed) {
      const sid = a.quiz_id ? (quizSubjectMap.get(a.quiz_id) ?? null) : null;
      if (!sid) continue;
      const cur = subjectAgg.get(sid) ?? { correct: 0, total: 0 };
      cur.correct += a.correct_count ?? 0;
      cur.total += a.total_count ?? 0;
      subjectAgg.set(sid, cur);
    }
    const subjectsList = (subjectsR.data ?? []).map((s) => {
      const agg = subjectAgg.get(s.id);
      const pct = agg && agg.total ? Math.round((agg.correct / agg.total) * 100) : 0;
      return { id: s.id, name: s.name, color: s.color, progress: pct };
    });

    // Recent activity feed (last 6 completed attempts)
    const recentActivity = completed.slice(0, 6).map((a) => ({
      id: a.id,
      quiz_id: a.quiz_id,
      score: a.score ?? 0,
      total: a.total_count ?? 0,
      correct: a.correct_count ?? 0,
      completed_at: a.completed_at ?? a.started_at,
    }));

    return {
      counts: {
        mcqs: mcqCountR.count ?? 0,
        mcqsThisWeek: mcqWeekR.count ?? 0,
        quizzes: quizCountR.count ?? 0,
        quizzesThisWeek: quizWeekR.count ?? 0,
        mocks: mockCountR.count ?? 0,
        mocksThisWeek: mockWeekR.count ?? 0,
        notes: notesCountR.count ?? 0,
        classes: classesCountR.count ?? 0,
        attempts: completed.length,
      },
      accuracy,
      streak,
      bars,
      subjects: subjectsList,
      learning,
      recommendations,
      notifications: notificationsR.data ?? [],
      upcomingMock: upcomingMockR.data?.[0] ?? null,
      recentActivity,
    };
  });
