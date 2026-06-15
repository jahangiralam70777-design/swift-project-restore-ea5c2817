import { createServerFn } from "@tanstack/react-start";
import { requireSupabaseAuth } from "@/integrations/supabase/auth-middleware";

/**
 * Advanced analytics for the redesigned student dashboard:
 * - daily/weekly/monthly study time (from study_sessions)
 * - per-subject and per-chapter accuracy (from attempt_answers join mcqs)
 * - weak/strong topics, performance by quiz kind
 * - smart insights (data-derived sentences)
 * - 30-day heatmap of activity
 */
export const studentAdvancedAnalytics = createServerFn({ method: "GET" })
  .middleware([requireSupabaseAuth])
  .handler(async ({ context }) => {
    const { supabase, userId, claims } = context;
    const meta = (claims as { user_metadata?: Record<string, unknown> })?.user_metadata ?? {};
    const dailyGoal = Math.max(1, Math.min(5000, Number(meta.daily_mcq_goal) || 50));
    const weeklyGoal = Math.max(1, Math.min(50000, Number(meta.weekly_mcq_goal) || 350));

    const now = new Date();
    const dayStart = new Date(now);
    dayStart.setUTCHours(0, 0, 0, 0);
    const since7 = new Date(now.getTime() - 7 * 86400_000);
    const since30 = new Date(now.getTime() - 30 * 86400_000);
    const since90 = new Date(now.getTime() - 90 * 86400_000);

    const [sessionsR, attemptsR, subjectsR, chaptersR, weeklyPrevR] = await Promise.all([
      supabase
        .from("study_sessions")
        .select("module,duration_seconds,started_at,last_heartbeat_at")
        .eq("user_id", userId)
        .gte("started_at", since30.toISOString()),
      supabase
        .from("exam_attempts")
        .select(
          "id,quiz_id,subject_id,chapter_id,kind,score,correct_count,total_count,duration_seconds,started_at,completed_at,status",
        )
        .eq("user_id", userId)
        .gte("started_at", since90.toISOString())
        .order("started_at", { ascending: false })
        .limit(500),
      supabase.from("subjects").select("id,name,color"),
      supabase.from("chapters").select("id,name,subject_id"),
      supabase
        .from("exam_attempts")
        .select("correct_count,total_count,started_at")
        .eq("user_id", userId)
        .eq("status", "completed")
        .gte("started_at", new Date(now.getTime() - 14 * 86400_000).toISOString())
        .lt("started_at", since7.toISOString()),
    ]);

    const sessions = sessionsR.data ?? [];
    const attempts = (attemptsR.data ?? []).filter((a) => a.status === "completed");
    const subjects = subjectsR.data ?? [];
    const chapters = chaptersR.data ?? [];

    // Pull answers for the recent attempts (no FK declared, so do it in two steps)
    const recentIds = attempts.filter((a) => new Date(a.started_at) >= since30).map((a) => a.id);
    let answers: Array<{ attempt_id: string; is_correct: boolean }> = [];
    if (recentIds.length) {
      const { data: ans } = await supabase
        .from("attempt_answers")
        .select("attempt_id,is_correct")
        .in("attempt_id", recentIds.slice(0, 200));
      answers = ans ?? [];
    }
    const attemptById = new Map(attempts.map((a) => [a.id, a]));

    // ---- Study time ----
    const sumWhere = (pred: (d: string) => boolean) =>
      sessions.reduce((s, x) => (pred(x.started_at) ? s + (x.duration_seconds ?? 0) : s), 0);
    const studyTime = {
      today: sumWhere((d) => new Date(d) >= dayStart),
      week: sumWhere((d) => new Date(d) >= since7),
      month: sumWhere((d) => new Date(d) >= since30),
    };

    // 7-day study minutes series
    const studyDaily: Array<{ date: string; minutes: number }> = [];
    for (let i = 6; i >= 0; i--) {
      const d = new Date(now);
      d.setUTCHours(0, 0, 0, 0);
      d.setUTCDate(d.getUTCDate() - i);
      const next = new Date(d);
      next.setUTCDate(next.getUTCDate() + 1);
      const secs = sessions.reduce((s, x) => {
        const t = new Date(x.started_at);
        return t >= d && t < next ? s + (x.duration_seconds ?? 0) : s;
      }, 0);
      studyDaily.push({ date: d.toISOString().slice(0, 10), minutes: Math.round(secs / 60) });
    }

    // ---- Totals ----
    const totals = attempts.reduce(
      (a, x) => {
        a.total += x.total_count ?? 0;
        a.correct += x.correct_count ?? 0;
        return a;
      },
      { total: 0, correct: 0 },
    );
    const wrong = Math.max(0, totals.total - totals.correct);
    const accuracy = totals.total > 0 ? Math.round((totals.correct / totals.total) * 1000) / 10 : 0;

    // Weekly prev vs this week (for improvement %)
    const thisWeekAttempts = attempts.filter((a) => new Date(a.started_at) >= since7);
    const sumAcc = (xs: typeof attempts) => {
      const t = xs.reduce((s, x) => s + (x.total_count ?? 0), 0);
      const c = xs.reduce((s, x) => s + (x.correct_count ?? 0), 0);
      return t > 0 ? (c / t) * 100 : 0;
    };
    const thisWeekAcc = sumAcc(thisWeekAttempts);
    const prevWeekRaw = weeklyPrevR.data ?? [];
    const prevWeekT = prevWeekRaw.reduce((s, x) => s + (x.total_count ?? 0), 0);
    const prevWeekC = prevWeekRaw.reduce((s, x) => s + (x.correct_count ?? 0), 0);
    const prevWeekAcc = prevWeekT > 0 ? (prevWeekC / prevWeekT) * 100 : 0;
    const weeklyChange = Math.round((thisWeekAcc - prevWeekAcc) * 10) / 10;

    // ---- Per kind performance ----
    const byKind: Record<string, { attempts: number; accuracy: number }> = {};
    for (const k of ["mock", "quiz", "mcq_practice"] as const) {
      const subset = attempts.filter((a) => (a.kind ?? "mcq_practice") === k);
      byKind[k] = {
        attempts: subset.length,
        accuracy: Math.round(sumAcc(subset) * 10) / 10,
      };
    }

    // ---- Subject / Chapter accuracy from answers ----
    const subjectMap = new Map(subjects.map((s) => [s.id, s]));
    const chapterMap = new Map(chapters.map((c) => [c.id, c]));

    type Agg = { correct: number; total: number };
    const subjAgg = new Map<string, Agg>();
    const chapAgg = new Map<string, Agg>();
    for (const ans of answers) {
      const ea = attemptById.get(ans.attempt_id);
      const sid = ea?.subject_id ?? null;
      const cid = ea?.chapter_id ?? null;
      if (sid) {
        const cur = subjAgg.get(sid) ?? { correct: 0, total: 0 };
        cur.total += 1;
        if (ans.is_correct) cur.correct += 1;
        subjAgg.set(sid, cur);
      }
      if (cid) {
        const cur = chapAgg.get(cid) ?? { correct: 0, total: 0 };
        cur.total += 1;
        if (ans.is_correct) cur.correct += 1;
        chapAgg.set(cid, cur);
      }
    }

    const subjectAccuracy = Array.from(subjAgg.entries())
      .map(([id, v]) => ({
        id,
        name: subjectMap.get(id)?.name ?? "Subject",
        color: subjectMap.get(id)?.color ?? null,
        accuracy: v.total ? Math.round((v.correct / v.total) * 1000) / 10 : 0,
        attempts: v.total,
      }))
      .sort((a, b) => b.accuracy - a.accuracy);

    const chapterAccuracy = Array.from(chapAgg.entries())
      .map(([id, v]) => ({
        id,
        name: chapterMap.get(id)?.name ?? "Chapter",
        subject: subjectMap.get(chapterMap.get(id)?.subject_id ?? "")?.name ?? null,
        accuracy: v.total ? Math.round((v.correct / v.total) * 1000) / 10 : 0,
        attempts: v.total,
      }))
      .filter((c) => c.attempts >= 3)
      .sort((a, b) => b.accuracy - a.accuracy);

    const strongTopics = chapterAccuracy.slice(0, 5);
    const weakTopics = [...chapterAccuracy].reverse().slice(0, 5);

    // ---- 30-day heatmap ----
    const heatmap: Array<{ date: string; count: number }> = [];
    for (let i = 29; i >= 0; i--) {
      const d = new Date(now);
      d.setUTCHours(0, 0, 0, 0);
      d.setUTCDate(d.getUTCDate() - i);
      const key = d.toISOString().slice(0, 10);
      const c = attempts.filter(
        (a) => (a.completed_at ?? a.started_at ?? "").slice(0, 10) === key,
      ).length;
      heatmap.push({ date: key, count: c });
    }

    // ---- Streak ----
    const days = new Set(attempts.map((a) => (a.completed_at ?? a.started_at).slice(0, 10)));
    let streak = 0;
    const cursor = new Date(now);
    cursor.setUTCHours(0, 0, 0, 0);
    if (!days.has(cursor.toISOString().slice(0, 10))) cursor.setUTCDate(cursor.getUTCDate() - 1);
    while (days.has(cursor.toISOString().slice(0, 10))) {
      streak++;
      cursor.setUTCDate(cursor.getUTCDate() - 1);
    }
    // Longest streak in last 90 days
    const sortedDays = Array.from(days).sort();
    let longest = 0,
      run = 0;
    let prev: Date | null = null;
    for (const d of sortedDays) {
      const cur = new Date(d);
      if (prev && cur.getTime() - prev.getTime() === 86400_000) run++;
      else run = 1;
      if (run > longest) longest = run;
      prev = cur;
    }

    // ---- Insights ----
    const insights: Array<{ kind: "up" | "down" | "info" | "goal"; text: string }> = [];
    if (weeklyChange > 2)
      insights.push({
        kind: "up",
        text: `Accuracy is up ${weeklyChange}% vs last week — keep going!`,
      });
    if (weeklyChange < -2)
      insights.push({
        kind: "down",
        text: `Accuracy dropped ${Math.abs(weeklyChange)}% vs last week. Review your wrong questions.`,
      });
    if (subjectAccuracy[0])
      insights.push({
        kind: "info",
        text: `You are strongest in ${subjectAccuracy[0].name} (${subjectAccuracy[0].accuracy}%).`,
      });
    const worstSubj = [...subjectAccuracy].reverse()[0];
    if (worstSubj && worstSubj.id !== subjectAccuracy[0]?.id) {
      insights.push({
        kind: "down",
        text: `${worstSubj.name} needs work — only ${worstSubj.accuracy}% accuracy.`,
      });
    }
    if (weakTopics[0])
      insights.push({
        kind: "down",
        text: `${weakTopics[0].name} completion is below average (${weakTopics[0].accuracy}%).`,
      });
    const answeredThisWeek = thisWeekAttempts.reduce((s, a) => s + (a.total_count ?? 0), 0);
    if (answeredThisWeek < weeklyGoal) {
      insights.push({
        kind: "goal",
        text: `Answer ${weeklyGoal - answeredThisWeek} more MCQs to hit your weekly goal.`,
      });
    } else {
      insights.push({ kind: "up", text: `Weekly goal hit — ${answeredThisWeek} MCQs answered!` });
    }
    if (streak >= 3)
      insights.push({ kind: "up", text: `You're on a ${streak}-day learning streak.` });

    // ---- MCQ counts (real, derived from completed attempts) ----
    const inRange = (iso: string, from: Date, to?: Date) => {
      const t = new Date(iso).getTime();
      return t >= from.getTime() && (!to || t < to.getTime());
    };
    const sumMcqs = (xs: typeof attempts) => xs.reduce((s, a) => s + (a.total_count ?? 0), 0);
    const mcqsToday = sumMcqs(
      attempts.filter((a) => inRange(a.completed_at ?? a.started_at, dayStart)),
    );
    const mcqsWeek = sumMcqs(thisWeekAttempts);
    const mcqsMonth = sumMcqs(attempts.filter((a) => new Date(a.started_at) >= since30));

    // Daily MCQ series (last 7 days, count of questions answered per day)
    const mcqDaily: Array<{ date: string; count: number }> = [];
    for (let i = 6; i >= 0; i--) {
      const d = new Date(now);
      d.setUTCHours(0, 0, 0, 0);
      d.setUTCDate(d.getUTCDate() - i);
      const next = new Date(d);
      next.setUTCDate(next.getUTCDate() + 1);
      const c = attempts.reduce((s, a) => {
        const t = new Date(a.completed_at ?? a.started_at);
        return t >= d && t < next ? s + (a.total_count ?? 0) : s;
      }, 0);
      mcqDaily.push({ date: d.toISOString().slice(0, 10), count: c });
    }

    const goals = {
      daily: {
        solved: mcqsToday,
        target: dailyGoal,
        percent: Math.min(100, Math.round((mcqsToday / dailyGoal) * 100)),
      },
      weekly: {
        solved: mcqsWeek,
        target: weeklyGoal,
        percent: Math.min(100, Math.round((mcqsWeek / weeklyGoal) * 100)),
      },
    };

    return {
      mcqCounts: { today: mcqsToday, week: mcqsWeek, month: mcqsMonth, daily: mcqDaily },
      totals: {
        answered: totals.total,
        correct: totals.correct,
        wrong,
        accuracy,
        attempts: attempts.length,
        weeklyChange,
      },
      byKind,
      subjectAccuracy: subjectAccuracy.slice(0, 8),
      chapterAccuracy: chapterAccuracy.slice(0, 10),
      strongTopics,
      weakTopics,
      heatmap,
      streak: { current: streak, longest },
      insights: insights.slice(0, 6),
      goals,
    };
  });

export const updateStudentMcqGoals = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .inputValidator((d: { dailyMcqGoal: number; weeklyMcqGoal: number }) => ({
    dailyMcqGoal: Math.max(1, Math.min(5000, Math.round(Number(d.dailyMcqGoal) || 0))),
    weeklyMcqGoal: Math.max(1, Math.min(50000, Math.round(Number(d.weeklyMcqGoal) || 0))),
  }))
  .handler(async ({ context, data }) => {
    const { supabase } = context;
    const { error } = await supabase.auth.updateUser({
      data: {
        daily_mcq_goal: data.dailyMcqGoal,
        weekly_mcq_goal: data.weeklyMcqGoal,
      },
    });
    if (error) throw new Error(error.message);
    return { ok: true, dailyMcqGoal: data.dailyMcqGoal, weeklyMcqGoal: data.weeklyMcqGoal };
  });
