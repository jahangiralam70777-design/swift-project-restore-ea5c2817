import { createServerFn } from "@tanstack/react-start";
import { z } from "zod";
import { requireSupabaseAuth } from "@/integrations/supabase/auth-middleware";
import {
  enforceRateLimit,
  RATE_LIMITS,
  rateLimitKey,
} from "@/integrations/security/rate-limit";

// ---- Levels (dynamic, admin-managed) ----
export const listLevels = createServerFn({ method: "GET" })
  .middleware([requireSupabaseAuth])
  .handler(async ({ context }) => {
    const { data, error } = await context.supabase
      .from("levels")
      .select("code,name,description,color,icon,sort_order,status")
      .in("status", ["published", "archived"])
      .order("sort_order", { ascending: true });
    if (error) throw error;
    return (data ?? []).map((l) => ({
      code: l.code,
      name: l.name,
      description: l.description,
      color: l.color,
      icon: l.icon,
      sort_order: l.sort_order,
      is_locked: l.status === "archived",
    }));
  });

// ---- Subjects ----
const subjectsSchema = z.object({ level: z.string().trim().min(1).max(40).optional() }).partial();

export const listSubjects = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .inputValidator((i: z.infer<typeof subjectsSchema> | undefined) => subjectsSchema.parse(i ?? {}))
  .handler(async ({ data, context }) => {
    let q = context.supabase
      .from("subjects")
      .select("id,name,slug,description,icon,color,sort_order,level")
      .eq("status", "published")
      .order("sort_order", { ascending: true });
    if (data?.level) q = q.ilike("level", data.level);
    const { data: rows, error } = await q;
    if (error) throw error;
    return rows ?? [];
  });

// ---- Progress: subjects in a level ----
const subjectProgressSchema = z
  .object({ level: z.string().trim().min(1).max(40).optional() })
  .partial();

export const listSubjectProgress = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .inputValidator((i: z.infer<typeof subjectProgressSchema> | undefined) =>
    subjectProgressSchema.parse(i ?? {}),
  )
  .handler(async ({ data, context }) => {
    const supabase = context.supabase;
    const userId = context.userId;
    // 1. Subjects in scope
    let sq = supabase.from("subjects").select("id").eq("status", "published");
    if (data?.level) sq = sq.ilike("level", data.level);
    const { data: subjects, error: se } = await sq;
    if (se) throw se;
    const subjectIds = (subjects ?? []).map((s) => s.id);
    if (!subjectIds.length)
      return [] as Array<{ subject_id: string; total: number; completed: number; percent: number }>;
    // 2. Chapters under those subjects
    const { data: chapters, error: ce } = await supabase
      .from("chapters")
      .select("id,subject_id")
      .in("subject_id", subjectIds)
      .eq("status", "published");
    if (ce) throw ce;
    const chapterToSubject = new Map<string, string>();
    (chapters ?? []).forEach((c) => chapterToSubject.set(c.id, c.subject_id));
    const chapterIds = Array.from(chapterToSubject.keys());
    if (!chapterIds.length) {
      return subjectIds.map((id) => ({ subject_id: id, total: 0, completed: 0, percent: 0 }));
    }
    // 3. Total published MCQs per subject (via chapter)
    const { data: mcqs, error: me } = await supabase
      .from("mcqs")
      .select("id,chapter_id")
      .in("chapter_id", chapterIds)
      .eq("status", "published");
    if (me) throw me;
    const totalsBySubject = new Map<string, number>();
    const mcqToSubject = new Map<string, string>();
    for (const m of mcqs ?? []) {
      if (!m.chapter_id) continue;
      const sId = chapterToSubject.get(m.chapter_id);
      if (!sId) continue;
      mcqToSubject.set(m.id, sId);
      totalsBySubject.set(sId, (totalsBySubject.get(sId) ?? 0) + 1);
    }
    // 4. Distinct MCQs the user has answered (chosen non-null)
    const { data: attempts, error: ae } = await supabase
      .from("exam_attempts")
      .select("id")
      .eq("user_id", userId)
      .in("subject_id", subjectIds);
    if (ae) throw ae;
    const attemptIds = (attempts ?? []).map((a) => a.id);
    const completedBySubject = new Map<string, Set<string>>();
    if (attemptIds.length) {
      const { data: ans, error: aae } = await supabase
        .from("attempt_answers")
        .select("mcq_id,chosen_option,attempt_id")
        .in("attempt_id", attemptIds)
        .not("chosen_option", "is", null);
      if (aae) throw aae;
      for (const r of ans ?? []) {
        const sId = mcqToSubject.get(r.mcq_id);
        if (!sId) continue;
        if (!completedBySubject.has(sId)) completedBySubject.set(sId, new Set());
        completedBySubject.get(sId)!.add(r.mcq_id);
      }
    }
    return subjectIds.map((id) => {
      const total = totalsBySubject.get(id) ?? 0;
      const completed = completedBySubject.get(id)?.size ?? 0;
      const percent = total ? Math.round((completed / total) * 100) : 0;
      return { subject_id: id, total, completed, percent };
    });
  });

// ---- Progress: chapters in a subject ----
const chapterProgressSchema = z.object({ subjectId: z.string().uuid() });

export const listChapterProgress = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .inputValidator((i: z.infer<typeof chapterProgressSchema>) => chapterProgressSchema.parse(i))
  .handler(async ({ data, context }) => {
    const supabase = context.supabase;
    const userId = context.userId;
    const { data: chapters, error: ce } = await supabase
      .from("chapters")
      .select("id")
      .eq("subject_id", data.subjectId)
      .eq("status", "published");
    if (ce) throw ce;
    const chapterIds = (chapters ?? []).map((c) => c.id);
    if (!chapterIds.length)
      return [] as Array<{
        chapter_id: string;
        total: number;
        completed: number;
        percent: number;
        correct: number;
        accuracy: number;
      }>;
    const { data: mcqs, error: me } = await supabase
      .from("mcqs")
      .select("id,chapter_id")
      .in("chapter_id", chapterIds)
      .eq("status", "published");
    if (me) throw me;
    const totalsByChapter = new Map<string, number>();
    const mcqToChapter = new Map<string, string>();
    for (const m of mcqs ?? []) {
      if (!m.chapter_id) continue;
      mcqToChapter.set(m.id, m.chapter_id);
      totalsByChapter.set(m.chapter_id, (totalsByChapter.get(m.chapter_id) ?? 0) + 1);
    }
    const { data: attempts, error: ae } = await supabase
      .from("exam_attempts")
      .select("id")
      .eq("user_id", userId)
      .in("chapter_id", chapterIds);
    if (ae) throw ae;
    const attemptIds = (attempts ?? []).map((a) => a.id);
    const completedByChapter = new Map<string, Set<string>>();
    const correctByChapter = new Map<string, Set<string>>();
    if (attemptIds.length) {
      const { data: ans, error: aae } = await supabase
        .from("attempt_answers")
        .select("mcq_id,chosen_option,is_correct,attempt_id")
        .in("attempt_id", attemptIds)
        .not("chosen_option", "is", null);
      if (aae) throw aae;
      for (const r of ans ?? []) {
        const cId = mcqToChapter.get(r.mcq_id);
        if (!cId) continue;
        if (!completedByChapter.has(cId)) completedByChapter.set(cId, new Set());
        completedByChapter.get(cId)!.add(r.mcq_id);
        if (r.is_correct) {
          if (!correctByChapter.has(cId)) correctByChapter.set(cId, new Set());
          correctByChapter.get(cId)!.add(r.mcq_id);
        }
      }
    }
    return chapterIds.map((id) => {
      const total = totalsByChapter.get(id) ?? 0;
      const completed = completedByChapter.get(id)?.size ?? 0;
      const correct = correctByChapter.get(id)?.size ?? 0;
      const percent = total ? Math.round((completed / total) * 100) : 0;
      const accuracy = completed ? Math.round((correct / completed) * 100) : 0;
      return { chapter_id: id, total, completed, percent, correct, accuracy };
    });
  });

// ---- Chapters ----
const chaptersSchema = z.object({ subjectId: z.string().uuid() });

export const listChapters = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .inputValidator((i: z.infer<typeof chaptersSchema>) => chaptersSchema.parse(i))
  .handler(async ({ data, context }) => {
    const { data: rows, error } = await context.supabase
      .from("chapters")
      .select("id,name,slug,description,sort_order,subject_id")
      .eq("subject_id", data.subjectId)
      .eq("status", "published")
      .order("sort_order", { ascending: true });
    if (error) throw error;
    return rows ?? [];
  });

// ---- MCQs by chapter ----
const mcqsSchema = z
  .object({
    chapterId: z.string().uuid().nullable().optional(),
    subjectId: z.string().uuid().nullable().optional(),
    level: z.string().trim().max(40).nullable().optional(),
    limit: z.number().int().min(1).max(2000).optional(),
  })
  .refine((v) => v.chapterId || v.subjectId || v.level, {
    message: "Provide chapterId, subjectId or level",
  });

export const listMcqs = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .inputValidator((i: z.infer<typeof mcqsSchema>) => mcqsSchema.parse(i))
  .handler(async ({ data, context }) => {
    const sb = context.supabase;
    let chapterIds: string[] | null = null;
    if (!data.chapterId) {
      // "All Chapters" mode — gather chapter ids for the subject/level.
      let cq = sb
        .from("chapters")
        .select("id,subject_id,subjects!inner(level)")
        .eq("status", "published");
      if (data.subjectId) cq = cq.eq("subject_id", data.subjectId);
      if (data.level) cq = cq.ilike("subjects.level", data.level);
      const { data: cRows, error: cErr } = await cq;
      if (cErr) throw cErr;
      chapterIds = (cRows ?? []).map((c) => c.id);
      if (!chapterIds.length) return [];
    }
    let q = sb
      .from("mcqs")
      .select(
        "id,question,option_a,option_b,option_c,option_d,correct_option,explanation,tags",
      )
      .eq("status", "published")
      .order("created_at", { ascending: true })
      .limit(data.limit ?? 2000);
    if (data.chapterId) q = q.eq("chapter_id", data.chapterId);
    else if (chapterIds) q = q.in("chapter_id", chapterIds);
    const { data: rows, error } = await q;
    if (error) throw error;
    return rows ?? [];
  });

// ---- Quizzes ----
const listQuizzesSchema = z
  .object({
    level: z.string().trim().max(40).optional(),
    subjectId: z.string().uuid().nullable().optional(),
    chapterId: z.string().uuid().nullable().optional(),
    kind: z.enum(["quiz", "mock"]).default("quiz"),
  })
  .partial();

export const listQuizzes = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .inputValidator((i: z.infer<typeof listQuizzesSchema> | undefined) =>
    listQuizzesSchema.parse(i ?? {}),
  )
  .handler(async ({ data, context }) => {
    const kind = data.kind ?? "quiz";
    let q = context.supabase
      .from("quizzes")
      .select(
        "id,title,description,total_questions,duration_seconds,passing_marks,negative_marking,subject_id,chapter_id,level,kind,starts_at,ends_at,created_at,subjects(name),chapters(name)",
      )
      .eq("status", "published")
      .eq("kind", kind)
      .order("created_at", { ascending: false });
    if (data.level) q = q.eq("level", data.level);
    if (data.subjectId) q = q.eq("subject_id", data.subjectId);
    if (data.chapterId) q = q.eq("chapter_id", data.chapterId);
    const { data: rows, error } = await q;
    if (error) throw error;
    const quizIds = (rows ?? []).map((r) => r.id);
    if (!quizIds.length) return [];
    // Only surface quizzes that have at least one assigned question
    const { data: qq, error: qqErr } = await context.supabase
      .from("quiz_questions")
      .select("quiz_id")
      .in("quiz_id", quizIds);
    if (qqErr) throw qqErr;
    const counts = new Map<string, number>();
    for (const r of qq ?? []) {
      counts.set(r.quiz_id, (counts.get(r.quiz_id) ?? 0) + 1);
    }
    return (rows ?? [])
      .filter((r) => (counts.get(r.id) ?? 0) > 0)
      .map((r) => ({ ...r, mcq_count: counts.get(r.id) ?? 0 }));
  });

const quizSchema = z.object({ quizId: z.string().uuid() });

export const getQuiz = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .inputValidator((i: z.infer<typeof quizSchema>) => quizSchema.parse(i))
  .handler(async ({ data, context }) => {
    const supabase = context.supabase;
    const [quizRes, qqRes] = await Promise.all([
      supabase
        .from("quizzes")
        .select(
          "id,title,description,total_questions,duration_seconds,subject_id,chapter_id",
        )
        .eq("id", data.quizId)
        .single(),
      supabase
        .from("quiz_questions")
        // SECURITY: do NOT expose correct_option or explanation here.
        // They are revealed post-submission via revealAnswers(attemptId).
        .select(
          "position,mcq:mcqs(id,question,option_a,option_b,option_c,option_d)",
        )
        .eq("quiz_id", data.quizId)
        .order("position", { ascending: true }),
    ]);
    if (quizRes.error) throw quizRes.error;
    if (qqRes.error) throw qqRes.error;

    const questions = (qqRes.data ?? [])
      .map((r) => {
        const mcq = (r as unknown as { mcq: Record<string, unknown> | null }).mcq;
        return mcq ? { position: r.position, ...mcq } : null;
      })
      .filter(Boolean);
    return { quiz: quizRes.data, questions };
  });

// ---- Attempts ----
const submitSchema = z.object({
  quizId: z.string().uuid(),
  durationSeconds: z
    .number()
    .int()
    .min(0)
    .max(60 * 60 * 4),
  answers: z
    .array(
      z.object({
        mcqId: z.string().uuid(),
        chosen: z.enum(["A", "B", "C", "D"]).nullable(),
        timeMs: z
          .number()
          .int()
          .min(0)
          .max(60 * 60 * 1000),
      }),
    )
    .max(200),
});

export const submitAttempt = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .inputValidator((i: z.infer<typeof submitSchema>) => submitSchema.parse(i))
  .handler(async ({ data, context }) => {
    const supabase = context.supabase;
    const userId = context.userId;

    // Per-user rate limit on quiz/mcq/mock submissions (anti-spam).
    await enforceRateLimit(
      supabase,
      rateLimitKey("quiz:submit", "user", userId),
      RATE_LIMITS.QUIZ_SUBMIT,
    );



    // Resolve correct answers + quiz meta server-side; never trust client.
    const ids = data.answers.map((a) => a.mcqId);
    let correctMap = new Map<string, string>();
    if (ids.length) {
      const { data: mcqs, error: me } = await supabase
        .from("mcqs")
        .select("id,correct_option")
        .in("id", ids);
      if (me) throw me;
      correctMap = new Map((mcqs ?? []).map((m) => [m.id, m.correct_option]));
    }

    // Load quiz so the attempt row is fully categorized (analytics + per-kind
    // performance need kind/subject/chapter/level/title). negative_marking is
    // applied below so mock-test scores reflect the penalty configured by
    // the admin (H-1 fix).
    const { data: quizMeta } = await supabase
      .from("quizzes")
      .select("id,title,subject_id,chapter_id,level,kind,negative_marking")
      .eq("id", data.quizId)
      .maybeSingle();

    let correct = 0;
    let wrong = 0;
    const rows = data.answers.map((a) => {
      const isCorrect = a.chosen !== null && correctMap.get(a.mcqId) === a.chosen;
      if (isCorrect) correct++;
      else if (a.chosen !== null) wrong++;
      return {
        mcq_id: a.mcqId,
        chosen_option: a.chosen,
        is_correct: isCorrect,
        time_spent_ms: a.timeMs,
      };
    });

    const total = data.answers.length;
    // H-1: apply per-quiz negative marking. `negative_marking` is the fractional
    // penalty per wrong answer (e.g. 0.25 = -25% of one mark). Clamp at 0 so
    // a heavily-penalised attempt never reports a negative percentage.
    const negFactor = Number(quizMeta?.negative_marking ?? 0) || 0;
    const rawCorrect = Math.max(0, correct - wrong * negFactor);
    const score = total === 0 ? 0 : Math.max(0, Math.round((rawCorrect / total) * 100));
    const attemptKind = (quizMeta?.kind === "mock" ? "mock" : "quiz") as "quiz" | "mock";


    // attempt_number per quiz for this user
    let attemptNumber = 1;
    {
      const { count } = await supabase
        .from("exam_attempts")
        .select("id", { count: "exact", head: true })
        .eq("user_id", userId)
        .eq("quiz_id", data.quizId)
        .eq("status", "completed");
      attemptNumber = (count ?? 0) + 1;
    }

    const { data: attempt, error: ae } = await supabase
      .from("exam_attempts")
      .insert({
        user_id: userId,
        quiz_id: data.quizId,
        kind: attemptKind,
        subject_id: quizMeta?.subject_id ?? null,
        chapter_id: quizMeta?.chapter_id ?? null,
        level: quizMeta?.level ?? null,
        title: quizMeta?.title ?? null,
        attempt_number: attemptNumber,
        status: "completed",
        completed_at: new Date().toISOString(),
        duration_seconds: data.durationSeconds,
        correct_count: correct,
        total_count: total,
        score,
      })
      .select("id")
      .single();
    if (ae) throw ae;

    if (rows.length) {
      const { error: ie } = await supabase
        .from("attempt_answers")
        .insert(rows.map((r) => ({ ...r, attempt_id: attempt.id })));
      if (ie) throw ie;
    }

    // Mirror outcomes into mcq_wrong_questions so Wrong Questions / Mastery
    // track quiz attempts too (not only MCQ Practice).
    try {
      const correctById = new Map(
        data.answers.map((a) => [a.mcqId, correctMap.get(a.mcqId) ?? null]),
      );
      const affected = data.answers.filter((a) => a.chosen !== null);
      if (affected.length) {
        const wrongIds = affected
          .filter((a) => correctById.get(a.mcqId) !== a.chosen)
          .map((a) => a.mcqId);
        const correctIds = affected
          .filter((a) => correctById.get(a.mcqId) === a.chosen)
          .map((a) => a.mcqId);
        const allIds = [...wrongIds, ...correctIds];
        const { data: existing } = await supabase
          .from("mcq_wrong_questions")
          .select("mcq_id,retry_count,mastered")
          .eq("user_id", userId)
          .in("mcq_id", allIds);
        const existMap = new Map(
          (existing ?? []).map((r: { mcq_id: string; retry_count: number; mastered: boolean }) => [
            r.mcq_id,
            r,
          ]),
        );
        const nowIso = new Date().toISOString();
        for (const a of affected) {
          const isWrong = correctById.get(a.mcqId) !== a.chosen;
          if (!isWrong) continue;
          const prev = existMap.get(a.mcqId);
          const nextRetry = prev ? (prev.retry_count ?? 0) + 1 : 0;
          await supabase.from("mcq_wrong_questions").upsert(
            {
              user_id: userId,
              mcq_id: a.mcqId,
              chapter_id: quizMeta?.chapter_id ?? null,
              subject_id: quizMeta?.subject_id ?? null,
              level: quizMeta?.level ?? null,
              last_chosen_option: a.chosen,
              correct_option: (correctById.get(a.mcqId) as "A" | "B" | "C" | "D" | null) ?? null,
              retry_count: nextRetry,
              mastered: false,
              last_wrong_at: nowIso,
            },
            { onConflict: "user_id,mcq_id" },
          );
        }
        const masterIds = correctIds.filter(
          (id) => existMap.has(id) && !existMap.get(id)!.mastered,
        );
        if (masterIds.length) {
          await supabase
            .from("mcq_wrong_questions")
            .update({ mastered: true })
            .eq("user_id", userId)
            .in("mcq_id", masterIds);
        }
      }
    } catch {
      /* non-fatal — analytics shouldn't block the attempt */
    }

    return { attemptId: attempt.id, correct, wrong, total, score };
  });

export const listMyAttempts = createServerFn({ method: "GET" })
  .middleware([requireSupabaseAuth])
  .handler(async ({ context }) => {
    const { data, error } = await context.supabase
      .from("exam_attempts")
      .select(
        "id,quiz_id,status,score,correct_count,total_count,duration_seconds,started_at,completed_at",
      )
      .eq("user_id", context.userId)
      .order("started_at", { ascending: false })
      .limit(20);
    if (error) throw error;
    return data ?? [];
  });

// Post-submission answer reveal. Returns correct_option + explanation ONLY
// for MCQs that belong to a completed attempt owned by the caller. This is
// the secure replacement for embedding correct_option in pre-submission
// reads such as getQuiz/listMcqs — future UI refactors should swap to this.
const revealSchema = z.object({ attemptId: z.string().uuid() });

export const revealAnswers = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .inputValidator((i: z.infer<typeof revealSchema>) => revealSchema.parse(i))
  .handler(async ({ data, context }) => {
    const { supabase, userId } = context;
    // Ownership + completion check — RLS already scopes to auth.uid(),
    // but we double-check status here so an in-progress attempt cannot leak
    // answers via this endpoint.
    const { data: attempt, error: ae } = await supabase
      .from("exam_attempts")
      .select("id,user_id,status")
      .eq("id", data.attemptId)
      .maybeSingle();
    if (ae) throw ae;
    if (!attempt || attempt.user_id !== userId) {
      throw new Error("Attempt not found");
    }
    if (attempt.status !== "completed") {
      throw new Error("Attempt not yet submitted");
    }
    const { data: rows, error: re } = await supabase
      .from("attempt_answers")
      .select("mcq_id,chosen_option,is_correct,mcq:mcqs(correct_option,explanation)")
      .eq("attempt_id", data.attemptId);
    if (re) throw re;
    return (rows ?? []).map((r) => {
      const m = (r as unknown as { mcq: { correct_option: string; explanation: string | null } | null }).mcq;
      return {
        mcq_id: r.mcq_id,
        chosen_option: r.chosen_option,
        is_correct: r.is_correct,
        correct_option: m?.correct_option ?? null,
        explanation: m?.explanation ?? null,
      };
    });
  });

// ===== Custom Exam (server-authoritative) =====
//
// generateCustomExam returns randomized MCQs WITHOUT correct_option /
// explanation so the client cannot inspect answers before submission.
// submitCustomExamAttempt scores server-side and persists an exam_attempts
// row with kind='custom'. revealAnswers(attemptId) is then used for review.

const customGenSchema = z.object({
  chapterIds: z.array(z.string().uuid()).min(1).max(50),
  count: z.number().int().min(1).max(200),
  randomize: z.boolean().default(true),
  level: z.string().trim().max(40).optional(),
  subjectId: z.string().uuid().optional(),
});

export const generateCustomExam = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .inputValidator((i: z.infer<typeof customGenSchema>) => customGenSchema.parse(i))
  .handler(async ({ data, context }) => {
    const { data: rows, error } = await context.supabase
      .from("mcqs")
      // SECURITY: no correct_option, no explanation
      .select("id,chapter_id,question,option_a,option_b,option_c,option_d")
      .eq("status", "published")
      .in("chapter_id", data.chapterIds);
    if (error) throw error;
    let pool = (rows ?? []) as Array<{
      id: string;
      chapter_id: string;
      question: string;
      option_a: string;
      option_b: string;
      option_c: string;
      option_d: string;
    }>;
    if (data.randomize) {
      // Fisher-Yates server-side
      for (let i = pool.length - 1; i > 0; i--) {
        const j = Math.floor(Math.random() * (i + 1));
        [pool[i], pool[j]] = [pool[j], pool[i]];
      }
    }
    return pool.slice(0, Math.min(data.count, pool.length));
  });

const customSubmitSchema = z.object({
  durationSeconds: z.number().int().min(0).max(60 * 60 * 4),
  level: z.string().trim().max(40).nullable().optional(),
  subjectId: z.string().uuid().nullable().optional(),
  // The list of chapter ids the exam was scoped to (for analytics rollup).
  chapterIds: z.array(z.string().uuid()).max(50).optional(),
  // negative_marking factor (0..1). Default 0 — Custom Exam has no penalty
  // unless an admin extends this contract later.
  negativeMarking: z.number().min(0).max(1).optional(),
  answers: z
    .array(
      z.object({
        mcqId: z.string().uuid(),
        chosen: z.enum(["A", "B", "C", "D"]).nullable(),
        timeMs: z.number().int().min(0).max(60 * 60 * 1000).default(0),
      }),
    )
    .min(1)
    .max(200),
});

export const submitCustomExamAttempt = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .inputValidator((i: z.infer<typeof customSubmitSchema>) => customSubmitSchema.parse(i))
  .handler(async ({ data, context }) => {
    const { supabase, userId } = context;
    const ids = data.answers.map((a) => a.mcqId);
    const { data: mcqs, error: me } = await supabase
      .from("mcqs")
      .select("id,correct_option,chapter_id")
      .in("id", ids);
    if (me) throw me;
    const correctMap = new Map<string, string>(
      (mcqs ?? []).map((m) => [m.id, m.correct_option as string]),
    );

    let correct = 0;
    let wrong = 0;
    const rows = data.answers.map((a) => {
      const isCorrect = a.chosen !== null && correctMap.get(a.mcqId) === a.chosen;
      if (isCorrect) correct++;
      else if (a.chosen !== null) wrong++;
      return {
        mcq_id: a.mcqId,
        chosen_option: a.chosen,
        is_correct: isCorrect,
        time_spent_ms: a.timeMs ?? 0,
      };
    });

    const total = data.answers.length;
    const negFactor = data.negativeMarking ?? 0;
    const rawCorrect = Math.max(0, correct - wrong * negFactor);
    const score = total === 0 ? 0 : Math.max(0, Math.round((rawCorrect / total) * 100));

    // Attempt number among custom exams
    let attemptNumber = 1;
    {
      const { count } = await supabase
        .from("exam_attempts")
        .select("id", { count: "exact", head: true })
        .eq("user_id", userId)
        .eq("kind", "custom")
        .eq("status", "completed");
      attemptNumber = (count ?? 0) + 1;
    }

    const { data: attempt, error: ae } = await supabase
      .from("exam_attempts")
      .insert({
        user_id: userId,
        quiz_id: null,
        kind: "custom",
        subject_id: data.subjectId ?? null,
        chapter_id:
          data.chapterIds && data.chapterIds.length === 1 ? data.chapterIds[0] : null,
        level: data.level ?? null,
        title: "Custom Exam",
        attempt_number: attemptNumber,
        status: "completed",
        completed_at: new Date().toISOString(),
        duration_seconds: data.durationSeconds,
        correct_count: correct,
        total_count: total,
        score,
        meta: { chapter_ids: data.chapterIds ?? [], wrong },
      })
      .select("id")
      .single();
    if (ae) throw ae;

    if (rows.length) {
      const { error: ie } = await supabase
        .from("attempt_answers")
        .insert(rows.map((r) => ({ ...r, attempt_id: attempt.id })));
      if (ie) throw ie;
    }

    // Mirror wrong answers into mcq_wrong_questions for the Review/Mastery
    // flows (non-fatal — never blocks the submit).
    try {
      const affected = data.answers.filter((a) => a.chosen !== null);
      const wrongIds = affected
        .filter((a) => correctMap.get(a.mcqId) !== a.chosen)
        .map((a) => a.mcqId);
      const correctIds = affected
        .filter((a) => correctMap.get(a.mcqId) === a.chosen)
        .map((a) => a.mcqId);
      const allIds = [...wrongIds, ...correctIds];
      if (allIds.length) {
        const { data: existing } = await supabase
          .from("mcq_wrong_questions")
          .select("mcq_id,retry_count,mastered")
          .eq("user_id", userId)
          .in("mcq_id", allIds);
        const existMap = new Map(
          (existing ?? []).map(
            (r: { mcq_id: string; retry_count: number; mastered: boolean }) => [r.mcq_id, r],
          ),
        );
        const nowIso = new Date().toISOString();
        const mcqMeta = new Map(
          (mcqs ?? []).map((m) => [m.id as string, m as { id: string; chapter_id: string | null }]),
        );
        for (const a of affected) {
          const isWrong = correctMap.get(a.mcqId) !== a.chosen;
          if (!isWrong) continue;
          const prev = existMap.get(a.mcqId);
          const meta = mcqMeta.get(a.mcqId);
          await supabase.from("mcq_wrong_questions").upsert(
            {
              user_id: userId,
              mcq_id: a.mcqId,
              chapter_id: meta?.chapter_id ?? null,
              subject_id: data.subjectId ?? null,
              level: data.level ?? null,
              last_chosen_option: a.chosen,
              correct_option: (correctMap.get(a.mcqId) as "A" | "B" | "C" | "D" | null) ?? null,
              retry_count: prev ? (prev.retry_count ?? 0) + 1 : 0,
              mastered: false,
              last_wrong_at: nowIso,
            },
            { onConflict: "user_id,mcq_id" },
          );
        }
        const masterIds = correctIds.filter(
          (id) => existMap.has(id) && !existMap.get(id)!.mastered,
        );
        if (masterIds.length) {
          await supabase
            .from("mcq_wrong_questions")
            .update({ mastered: true })
            .eq("user_id", userId)
            .in("mcq_id", masterIds);
        }
      }
    } catch {
      /* non-fatal */
    }

    return {
      attemptId: attempt.id as string,
      correct,
      wrong,
      total,
      score,
      skipped: total - (correct + wrong),
    };
  });
