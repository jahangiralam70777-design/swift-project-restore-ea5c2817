import { memo, useCallback, useEffect, useMemo, useRef, useState } from "react";
import { useQuery, useQueryClient } from "@tanstack/react-query";
import { useServerFn } from "@tanstack/react-start";
import {
  Sparkles,
  Award,
  Crown,
  Calculator,
  Scale,
  Receipt,
  Briefcase,
  Landmark,
  PiggyBank,
  BookOpen,
  ChevronRight,
  ChevronDown,
  Bookmark,
  Flame,
  ArrowLeft,
  ArrowRight,
  Check,
  X,
  Lightbulb,
  Loader2,
  Trophy,
  RotateCw,
  Eye,
  Clock,
  Target,
  CheckCircle2,
  XCircle,
  MinusCircle,
  Search,
  Play,
  Layers,
  TrendingUp,
  Zap,
  Lock,
  Settings2,
  Timer,
  Shuffle,
} from "lucide-react";

import {
  listSubjects,
  listChapters,
  listMcqs,
  listSubjectProgress,
  listChapterProgress,
} from "@/lib/learning.functions";
import { useLevels } from "@/hooks/use-levels";
import { saveSessionAttempt } from "@/lib/student-performance.functions";
import {
  toggleMcqBookmark,
  listMyBookmarkIds,
  recordMcqOutcomes,
} from "@/lib/mcq-review.functions";

type Step = 0 | 1 | 2 | 3;

const LEVEL_TONES = [
  "var(--neon-purple)",
  "var(--neon-blue)",
  "oklch(0.82 0.16 85)",
  "var(--neon-pink)",
  "oklch(0.75 0.18 150)",
];
const LEVEL_ICONS = [Sparkles, Award, Crown];

const subjectIconMap: Record<string, { i: typeof Calculator; tone: string }> = {
  accounting: { i: Calculator, tone: "var(--neon-purple)" },
  "financial-accounting": { i: Calculator, tone: "var(--neon-purple)" },
  "management-accounting": { i: PiggyBank, tone: "oklch(0.78 0.15 200)" },
  "cost-accounting": { i: PiggyBank, tone: "oklch(0.78 0.15 200)" },
  audit: { i: Briefcase, tone: "var(--neon-blue)" },
  auditing: { i: Briefcase, tone: "var(--neon-blue)" },
  taxation: { i: Receipt, tone: "var(--neon-pink)" },
  tax: { i: Receipt, tone: "var(--neon-pink)" },
  vat: { i: Receipt, tone: "var(--neon-pink)" },
  law: { i: Scale, tone: "oklch(0.75 0.18 150)" },
  "business-law": { i: Scale, tone: "oklch(0.75 0.18 150)" },
  finance: { i: Landmark, tone: "oklch(0.82 0.16 85)" },
  "corporate-finance": { i: Landmark, tone: "oklch(0.82 0.16 85)" },
};
function iconFor(slug: string) {
  return subjectIconMap[slug?.toLowerCase()] ?? { i: BookOpen, tone: "var(--neon-purple)" };
}

const stepLabels = ["Level", "Subject", "Chapter", "Practice"];

type Mcq = {
  id: string;
  question: string;
  option_a: string;
  option_b: string;
  option_c: string;
  option_d: string;
  correct_option: string;
  explanation: string | null;
};

type Choice = "A" | "B" | "C" | "D";
type AnswerRec = { chosen: Choice | null; timeMs: number } | undefined;

import { sanitizeOptionText } from "@/lib/sanitize-option";

function normalizeChoice(value: string | null | undefined): Choice | null {
  const normalized = (value ?? "").trim().toUpperCase();
  return normalized === "A" || normalized === "B" || normalized === "C" || normalized === "D"
    ? normalized
    : null;
}

function debugMcq(label: string, payload?: unknown) {
  console.debug(`[MCQ Practice] ${label}`, payload ?? "");
}

function fmtDuration(sec: number) {
  if (!sec) return "0s";
  const m = Math.floor(sec / 60);
  const s = sec % 60;
  return m ? `${m}m ${s}s` : `${s}s`;
}

type OptionState = "idle" | "correct" | "wrong" | "selected";

type OptionButtonProps = {
  questionId: string;
  optionKey: Choice;
  text: string;
  state: OptionState;
  clickable: boolean;
  onPick: (k: Choice) => void;
};

const OptionButton = memo(function OptionButton({
  optionKey,
  text,
  state,
  clickable,
  onPick,
}: OptionButtonProps) {
  const tone =
    state === "correct"
      ? "border-emerald-400/60 bg-emerald-400/10"
      : state === "wrong"
        ? "border-red-400/60 bg-red-400/10"
        : state === "selected"
          ? "border-primary bg-primary/10"
          : "border-border hover:border-primary/50 hover:bg-muted/40";
  return (
    <button
      type="button"
      onClick={() => clickable && onPick(optionKey)}
      disabled={!clickable}
      className={`group relative flex items-center gap-4 rounded-2xl border p-4 text-left transition-colors duration-150 ${tone} disabled:cursor-default`}
    >
      <span
        className={`flex h-10 w-10 shrink-0 items-center justify-center rounded-xl font-display text-base font-bold transition-colors duration-150 ${
          state === "correct"
            ? "bg-emerald-500 text-white"
            : state === "wrong"
              ? "bg-red-500 text-white"
              : state === "selected"
                ? "bg-cta-gradient text-white shadow-glow"
                : "bg-muted text-foreground group-hover:bg-cta-gradient group-hover:text-white"
        }`}
      >
        {state === "correct" ? (
          <Check className="h-4 w-4" />
        ) : state === "wrong" ? (
          <X className="h-4 w-4" />
        ) : (
          optionKey
        )}
      </span>
      <span className="text-sm font-medium">{text}</span>
    </button>
  );
});

const BATCH_SIZE = 25;

export function McqFlow() {
  const [step, setStep] = useState<Step>(0);
  const [level, setLevel] = useState<string | null>(null);
  const [subjectId, setSubjectId] = useState<string | null>(null);
  const [subjectName, setSubjectName] = useState<string | null>(null);
  const [chapterId, setChapterId] = useState<string | null>(null);
  const [chapterName, setChapterName] = useState<string | null>(null);
  const [openChapter, setOpenChapter] = useState<string | null>(null);

  const [current, setCurrent] = useState(0); // index within the current batch
  const [batchIndex, setBatchIndex] = useState(0);
  const [showExp, setShowExp] = useState(false);
  // Chapter-wide answer array. Index = global MCQ index across the whole chapter.
  const [allAnswers, setAllAnswers] = useState<AnswerRec[]>([]);
  const [selectedOption, setSelectedOption] = useState<Choice | null>(null);
  const [sessionStart, setSessionStart] = useState<number>(0);
  const questionStartRef = useRef<number>(Date.now());
  const [finished, setFinished] = useState(false);
  const [reviewMode, setReviewMode] = useState(false);
  const [saving, setSaving] = useState(false);
  const [savedAttemptId, setSavedAttemptId] = useState<string | null>(null);

  const [levelQuery, setLevelQuery] = useState("");
  const [subjectQuery, setSubjectQuery] = useState("");
  const [chapterQuery, setChapterQuery] = useState("");
  const [pendingChapter, setPendingChapter] = useState<{
    id: string;
    name: string;
    description: string | null;
  } | null>(null);

  // Session config (chosen on the pre-session card)
  const [sessionCount, setSessionCount] = useState<"10" | "25" | "50" | "all">("25");
  const [sessionTimerMin, setSessionTimerMin] = useState<0 | 5 | 10 | 20>(0); // 0 = off
  const [sessionMode, setSessionMode] = useState<"instant" | "submit-end">("instant");
  const [timeLeft, setTimeLeft] = useState<number>(0);
  const autoFinishKeyRef = useRef<string | null>(null);
  const initializedChapterRef = useRef<string | null>(null);

  const listSubjectsFn = useServerFn(listSubjects);
  const listChaptersFn = useServerFn(listChapters);
  const listMcqsFn = useServerFn(listMcqs);
  const listSubjectProgressFn = useServerFn(listSubjectProgress);
  const listChapterProgressFn = useServerFn(listChapterProgress);
  const saveAttemptFn = useServerFn(saveSessionAttempt);
  const toggleBookmarkFn = useServerFn(toggleMcqBookmark);
  const listBookmarkIdsFn = useServerFn(listMyBookmarkIds);
  const recordOutcomesFn = useServerFn(recordMcqOutcomes);
  const qc = useQueryClient();

  const levelsQ = useLevels({ includeLocked: true });
  const levelsList = levelsQ.data ?? [];
  const levelName = useMemo(
    () => levelsList.find((l) => l.code === level)?.name ?? level ?? "",
    [levelsList, level],
  );

  const bookmarksQ = useQuery({
    queryKey: ["my-bookmark-ids"],
    queryFn: () => listBookmarkIdsFn(),
    staleTime: 60_000,
  });
  const bookmarkSet = useMemo(() => new Set<string>(bookmarksQ.data ?? []), [bookmarksQ.data]);

  async function toggleBookmark(mcqId: string) {
    const wasBookmarked = bookmarkSet.has(mcqId);
    try {
      await toggleBookmarkFn({
        data: {
          mcqId,
          bookmarked: !wasBookmarked,
          chapterId: chapterId ?? null,
          subjectId: subjectId ?? null,
          level: level ?? null,
        },
      });
      qc.invalidateQueries({ queryKey: ["my-bookmark-ids"] });
      qc.invalidateQueries({ queryKey: ["mcq-bookmarks"] });
      qc.invalidateQueries({ queryKey: ["mcq-review-counts"] });
    } catch (e) {
      debugMcq("bookmark failed", e);
    }
  }

  const subjectsQ = useQuery({
    queryKey: ["subjects", level],
    queryFn: () => listSubjectsFn({ data: { level: level ?? undefined } }),
    enabled: !!level,
  });
  const subjectProgressQ = useQuery({
    queryKey: ["subject-progress", level],
    queryFn: () => listSubjectProgressFn({ data: { level: level ?? undefined } }),
    enabled: !!level,
    staleTime: 30_000,
  });
  const subjectProgressMap = useMemo(() => {
    const m = new Map<string, { total: number; completed: number; percent: number }>();
    const rows = (subjectProgressQ.data ?? []) as Array<{
      subject_id: string;
      total: number;
      completed: number;
      percent: number;
    }>;
    rows.forEach((r) =>
      m.set(r.subject_id, { total: r.total, completed: r.completed, percent: r.percent }),
    );
    return m;
  }, [subjectProgressQ.data]);

  const chaptersQ = useQuery({
    queryKey: ["chapters", subjectId],
    queryFn: () => listChaptersFn({ data: { subjectId: subjectId! } }),
    enabled: !!subjectId,
  });
  const chapterProgressQ = useQuery({
    queryKey: ["chapter-progress", subjectId],
    queryFn: () => listChapterProgressFn({ data: { subjectId: subjectId! } }),
    enabled: !!subjectId,
    staleTime: 30_000,
  });
  const chapterProgressMap = useMemo(() => {
    const m = new Map<
      string,
      { total: number; completed: number; percent: number; accuracy: number }
    >();
    const rows = (chapterProgressQ.data ?? []) as Array<{
      chapter_id: string;
      total: number;
      completed: number;
      percent: number;
      accuracy: number;
    }>;
    rows.forEach((r) =>
      m.set(r.chapter_id, {
        total: r.total,
        completed: r.completed,
        percent: r.percent,
        accuracy: r.accuracy,
      }),
    );
    return m;
  }, [chapterProgressQ.data]);

  const mcqsQ = useQuery({
    queryKey: ["mcqs", chapterId],
    queryFn: () => listMcqsFn({ data: { chapterId: chapterId!, limit: 2000 } }),
    enabled: !!chapterId && step === 3,
  });

  // Full chapter (all MCQs), optionally truncated by session config.
  const rawMcqs = useMemo(() => (mcqsQ.data ?? []) as Mcq[], [mcqsQ.data]);
  const allMcqs = useMemo(() => {
    if (sessionCount === "all") return rawMcqs;
    const n = Number(sessionCount);
    return rawMcqs.slice(0, n);
  }, [rawMcqs, sessionCount]);
  const totalAll = allMcqs.length;
  const numBatches = Math.max(1, Math.ceil(totalAll / BATCH_SIZE));
  const safeBatchIndex = Math.min(batchIndex, Math.max(0, numBatches - 1));
  const batchStart = safeBatchIndex * BATCH_SIZE;
  const batchEnd = Math.min(batchStart + BATCH_SIZE, totalAll);
  // Current batch view — keeps existing render code thinking in terms of "mcqs".
  const mcqs = useMemo(() => allMcqs.slice(batchStart, batchEnd), [allMcqs, batchStart, batchEnd]);
  const answers = useMemo(
    () => allAnswers.slice(batchStart, batchEnd),
    [allAnswers, batchStart, batchEnd],
  );
  const total = mcqs.length;
  const q = mcqs[current];
  const currentAnswer = answers[current];
  const submittedNow = !!currentAnswer; // true once student clicks Submit (or Skip) for this question
  // Reveal correct/wrong + explanation as soon as this question is submitted, plus in review/finish.
  const revealResults = reviewMode || finished || submittedNow;
  const picked: Choice | null = submittedNow ? (currentAnswer?.chosen ?? null) : selectedOption;

  // Initialize the chapter-wide answer buffer once MCQs load for a chapter.
  // Auto-resume into the next batch when the chapter has prior progress.
  useEffect(() => {
    if (!chapterId || !mcqsQ.isSuccess) return;
    if (initializedChapterRef.current === chapterId && allAnswers.length === totalAll) return;
    initializedChapterRef.current = chapterId;
    setAllAnswers(new Array(totalAll).fill(undefined));
    const prog = chapterProgressMap.get(chapterId);
    const completed = prog?.completed ?? 0;
    const resumeBatch =
      totalAll > 0 && completed > 0 && completed < totalAll
        ? Math.min(Math.floor(completed / BATCH_SIZE), Math.max(0, numBatches - 1))
        : 0;
    setBatchIndex(resumeBatch);
    setCurrent(0);
    setSavedAttemptId(null);
    setSessionStart(Date.now());
    questionStartRef.current = Date.now();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [chapterId, mcqsQ.isSuccess, totalAll]);

  const options = useMemo(
    () =>
      q
        ? (
            [
              { k: "A" as Choice, t: sanitizeOptionText(q.option_a) },
              { k: "B" as Choice, t: sanitizeOptionText(q.option_b) },
              { k: "C" as Choice, t: sanitizeOptionText(q.option_c) },
              { k: "D" as Choice, t: sanitizeOptionText(q.option_d) },
            ] as ReadonlyArray<{ k: Choice; t: string }>
          ).filter((o) => o.t.length > 0)
        : ([] as ReadonlyArray<{ k: Choice; t: string }>),
    [q?.id, q?.option_a, q?.option_b, q?.option_c, q?.option_d],
  );

  const correctChoice = useMemo(
    () => (q ? normalizeChoice(q.correct_option) : null),
    [q?.id, q?.correct_option],
  );

  // Stable click handler — ignores re-selecting the same option (prevents
  // duplicate state writes / re-renders from rapid clicks).
  const pickOption = useCallback((k: Choice) => {
    setSelectedOption((prev) => (prev === k ? prev : k));
  }, []);

  // Derived metrics for the current batch (drives the in-question UI).
  const stats = useMemo(() => {
    let correct = 0,
      wrong = 0,
      skipped = 0,
      attempted = 0;
    answers.forEach((a, i) => {
      if (!a || !mcqs[i]) return;
      if (a.chosen === null) skipped++;
      else {
        attempted++;
        if (a.chosen === normalizeChoice(mcqs[i].correct_option)) correct++;
        else wrong++;
      }
    });
    const submitted = answers.filter(Boolean).length;
    const accuracy = attempted ? Math.round((correct / attempted) * 100) : 0;
    const score = total ? Math.round((correct / total) * 100) : 0;
    return { correct, wrong, skipped, attempted, submitted, accuracy, score };
  }, [answers, mcqs, total]);

  // Chapter-wide rollup — drives the "X / Total Completed" progress chip & sidebar.
  const statsAll = useMemo(() => {
    let correct = 0,
      wrong = 0,
      skipped = 0,
      attempted = 0;
    allAnswers.forEach((a, i) => {
      if (!a || !allMcqs[i]) return;
      if (a.chosen === null) skipped++;
      else {
        attempted++;
        if (a.chosen === normalizeChoice(allMcqs[i].correct_option)) correct++;
        else wrong++;
      }
    });
    const submitted = allAnswers.filter(Boolean).length;
    const accuracy = attempted ? Math.round((correct / attempted) * 100) : 0;
    return { correct, wrong, skipped, attempted, submitted, accuracy };
  }, [allAnswers, allMcqs]);

  const allSubmitted = total > 0 && stats.submitted === total; // batch complete
  const chapterAllSubmitted = totalAll > 0 && statsAll.submitted === totalAll;
  const isLastBatch = safeBatchIndex >= numBatches - 1;

  // reset question timer on navigation; rehydrate selectedOption from prior answer
  useEffect(() => {
    questionStartRef.current = Date.now();
    setShowExp(false);
    setSelectedOption(answers[current]?.chosen ?? null);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [current, batchIndex, chapterId]);

  function gotoChapter(id: string, name: string) {
    setChapterId(id);
    setChapterName(name);
    setStep(3);
    setCurrent(0);
    setBatchIndex(0);
    setShowExp(false);
    setAllAnswers([]);
    initializedChapterRef.current = null;
    setSelectedOption(null);
    setFinished(false);
    setReviewMode(false);
    setSavedAttemptId(null);
    autoFinishKeyRef.current = null;
    setSessionStart(Date.now());
    questionStartRef.current = Date.now();
    debugMcq("chapter start", { chapterId: id, chapterName: name, level, subjectId, subjectName });
  }

  function gotoBatch(nextBatch: number) {
    const clamped = Math.max(0, Math.min(numBatches - 1, nextBatch));
    setBatchIndex(clamped);
    setCurrent(0);
    setShowExp(false);
    setSelectedOption(null);
    setSavedAttemptId(null);
    setSessionStart(Date.now());
    questionStartRef.current = Date.now();
  }

  function recordAnswer(chosen: Choice | null) {
    if (!q) return;
    const elapsed = Math.max(0, Date.now() - questionStartRef.current);
    const globalIndex = batchStart + current;
    setAllAnswers((prev) => {
      const base = prev.length === totalAll ? [...prev] : new Array(totalAll).fill(undefined);
      base[globalIndex] = { chosen, timeMs: Math.min(elapsed, 60 * 60 * 1000) };
      debugMcq("answer recorded", {
        globalIndex,
        batchIndex: safeBatchIndex,
        chosen,
        answeredInChapter: base.filter(Boolean).length,
        totalChapter: totalAll,
      });
      return base;
    });
  }

  function submitAnswer(chosen: Choice | null) {
    if (!q || reviewMode) return;
    // Manual submit only — records answer, reveals correctness + explanation, NO auto-advance.
    debugMcq("submit trigger", {
      currentIndex: current,
      globalIndex: batchStart + current,
      chosen,
      isLastInBatch: current === total - 1,
      isLastBatch,
    });
    recordAnswer(chosen);
    setShowExp(true);

    // Per-question instant outcome sync: as soon as a wrong (or skipped)
    // answer is submitted, push it to the wrong-questions store so the
    // Wrong Questions page reflects it immediately, no batch-end wait,
    // no manual refresh. Correct answers also flow through so that
    // mastering a previously-wrong MCQ clears it in real time.
    const mcqId = q.id;
    void (async () => {
      try {
        await recordOutcomesFn({
          data: {
            level: level ?? null,
            subjectId: subjectId ?? null,
            chapterId: chapterId ?? null,
            outcomes: [{ mcqId, chosen }],
          },
        });
        qc.invalidateQueries({ queryKey: ["mcq-wrong"] });
        qc.invalidateQueries({ queryKey: ["mcq-review-counts"] });
      } catch (e) {
        debugMcq("instant outcome record failed", e);
      }
    })();
  }


  function nextQ() {
    if (current < total - 1) {
      setCurrent((c) => c + 1);
    } else if (!isLastBatch) {
      // Seamlessly cross into the next batch — saves the current batch in the
      // background and lands on the first question of the next batch.
      finishPractice({ finalize: false, auto: true });
    }
  }
  function prevQ() {
    if (current > 0) {
      setCurrent((c) => c - 1);
    } else if (safeBatchIndex > 0) {
      // Cross-batch back: land on the last question of the previous batch.
      const prev = safeBatchIndex - 1;
      const prevStart = prev * BATCH_SIZE;
      const prevEnd = Math.min(prevStart + BATCH_SIZE, totalAll);
      setBatchIndex(prev);
      setCurrent(prevEnd - prevStart - 1);
      setShowExp(false);
      setSelectedOption(null);
      questionStartRef.current = Date.now();
    }
  }
  function jumpTo(i: number) {
    if (i >= 0 && i < total) setCurrent(i);
  }

  // Persist a single batch (or the final chapter completion) as an exam attempt.
  // For non-final batches, this also rolls forward to the next batch.
  const finishPractice = useCallback(
    async (opts?: { auto?: boolean; finalize?: boolean }) => {
      if (saving) return;
      const finalize = opts?.finalize ?? isLastBatch;
      if (finished && savedAttemptId && finalize) return;

      const batchAnswersRaw = allAnswers.slice(batchStart, batchEnd);
      const finalizedAnswers = mcqs.map(
        (_, i) => batchAnswersRaw[i] ?? { chosen: null, timeMs: 0 },
      );
      const totalDurationSec = Math.max(
        1,
        Math.round((Date.now() - (sessionStart || Date.now())) / 1000),
      );
      const localCorrect = finalizedAnswers.reduce(
        (sum, a, i) =>
          sum +
          (a?.chosen !== null && a?.chosen === normalizeChoice(mcqs[i]?.correct_option) ? 1 : 0),
        0,
      );
      const localSkipped = finalizedAnswers.filter((a) => a?.chosen === null).length;
      const localWrong = Math.max(0, total - localCorrect - localSkipped);
      const localAttempted = total - localSkipped;
      const localScore = total ? Math.round((localCorrect / total) * 100) : 0;
      const localAccuracy = localAttempted ? Math.round((localCorrect / localAttempted) * 100) : 0;

      debugMcq("save batch", {
        auto: !!opts?.auto,
        finalize,
        batchIndex: safeBatchIndex,
        numBatches,
        batchSize: total,
        totalChapter: totalAll,
        localCorrect,
        localWrong,
        localSkipped,
        localScore,
        localAccuracy,
      });

      // Mount the final result screen immediately when finalizing. The DB save
      // runs after so a network/RLS failure can never strand the student.
      setAllAnswers((prev) => {
        const base = prev.length === totalAll ? [...prev] : new Array(totalAll).fill(undefined);
        finalizedAnswers.forEach((a, i) => {
          base[batchStart + i] = a;
        });
        return base;
      });
      if (finalize) {
        setFinished(true);
        setReviewMode(false);
      }

      // Advance to the next batch IMMEDIATELY so the UI never gets stuck on a
      // slow/failing save. The DB save below runs in the background and does
      // not block pagination. For the final batch (finalize=true) we keep the
      // user on the results screen.
      if (!finalize && safeBatchIndex < numBatches - 1) {
        gotoBatch(safeBatchIndex + 1);
      }

      setSaving(true);

      // Ensure answer record for every question in this batch (missing = skipped)
      const finalAnswers = mcqs.map((m, i) => {
        const a = finalizedAnswers[i];
        return {
          mcqId: m.id,
          chosen: a?.chosen ?? null,
          timeMs: Math.min(a?.timeMs ?? 0, 60 * 60 * 1000),
        };
      });

      try {
        const res = await saveAttemptFn({
          data: {
            kind: "mcq_practice",
            subjectId: subjectId ?? null,
            chapterId: chapterId ?? null,
            level: level ?? null,
            title: `${chapterName ?? "MCQ Practice"} · Batch ${safeBatchIndex + 1}/${numBatches}`,
            durationSeconds: totalDurationSec,
            answers: finalAnswers,
            meta: {
              auto: !!opts?.auto,
              batchIndex: safeBatchIndex,
              numBatches,
              batchStart,
              batchEnd,
              totalChapter: totalAll,
              score: localScore,
              accuracy: localAccuracy,
              correct: localCorrect,
              wrong: localWrong,
              skipped: localSkipped,
              finalize,
            },
          },
        });
        setSavedAttemptId(res.attemptId);
        debugMcq("DB save success", {
          attemptId: res.attemptId,
          score: res.score,
          correct: res.correct,
          total: res.total,
        });
        // Record wrong/mastered outcomes for the Wrong Questions section
        try {
          const outcomes = mcqs.map((m, i) => {
            const a = finalizedAnswers[i];
            return {
              mcqId: m.id,
              chosen: a?.chosen ?? null,
            };
          });
          await recordOutcomesFn({
            data: {
              level: level ?? null,
              subjectId: subjectId ?? null,
              chapterId: chapterId ?? null,
              outcomes,
            },
          });
        } catch (e) {
          debugMcq("record outcomes failed", e);
        }
        // Refresh dashboard views immediately
        qc.invalidateQueries({ queryKey: ["student-performance-center"] });
        qc.invalidateQueries({ queryKey: ["student-completion-tracker"] });
        qc.invalidateQueries({ queryKey: ["exam-attempts"] });
        qc.invalidateQueries({ queryKey: ["mcq-wrong"] });
        qc.invalidateQueries({ queryKey: ["mcq-review-counts"] });
        qc.invalidateQueries({ queryKey: ["subject-progress"] });
        qc.invalidateQueries({ queryKey: ["chapter-progress"] });
      } catch (e) {
        debugMcq("DB save failed", e);
      } finally {
        setSaving(false);
      }
    },
    [
      allAnswers,
      batchEnd,
      batchStart,
      chapterId,
      chapterName,
      current,
      finished,
      isLastBatch,
      level,
      mcqs,
      numBatches,
      qc,
      recordOutcomesFn,
      safeBatchIndex,
      saveAttemptFn,
      savedAttemptId,
      saving,
      sessionStart,
      subjectId,
      total,
      totalAll,
    ],
  );

  useEffect(() => {
    if (step !== 3 || total === 0) return;
    debugMcq("state", {
      currentIndex: current,
      answeredCount: stats.submitted,
      totalQuestions: total,
      allSubmitted,
      finished,
      saving,
      reviewMode,
    });
  }, [allSubmitted, current, finished, reviewMode, saving, stats.submitted, step, total]);

  function restartSame() {
    if (!chapterId || !chapterName) return;
    gotoChapter(chapterId, chapterName);
    mcqsQ.refetch();
  }

  const inPractice = step === 3;
  return (
    <div className={`grid grid-cols-1 gap-5 ${inPractice ? "xl:grid-cols-[1fr_320px]" : ""}`}>
      <div className="min-w-0 space-y-5">
        {/* Premium connected stepper — only on practice step */}
        {inPractice && (
          <div className="glass shadow-card-soft relative overflow-hidden rounded-2xl p-4 sm:p-5">
            <div className="pointer-events-none absolute -right-16 -top-16 h-40 w-40 rounded-full bg-[var(--neon-purple)]/15 blur-3xl" />
            <div className="pointer-events-none absolute -left-16 -bottom-16 h-40 w-40 rounded-full bg-[var(--neon-blue)]/15 blur-3xl" />
            <div className="relative flex items-center gap-1 overflow-x-auto">
              {stepLabels.map((l, i) => {
                const active = step === i;
                const done = i < step;
                const locked = i > step;
                const ctxName =
                  i === 0 ? null : i === 1 ? levelName : i === 2 ? subjectName : chapterName;
                return (
                  <div key={l} className="flex min-w-fit flex-1 items-center gap-1">
                    <button
                      onClick={() => i <= step && setStep(i as Step)}
                      disabled={locked}
                      className={`group flex w-full items-center gap-3 rounded-xl px-3 py-2 text-left transition-all ${
                        active
                          ? "bg-gradient-to-r from-[var(--neon-purple)]/15 via-[var(--neon-blue)]/10 to-transparent ring-1 ring-inset ring-[var(--neon-purple)]/40 shadow-glow"
                          : done
                            ? "hover:bg-muted/50"
                            : "opacity-60"
                      } ${locked ? "cursor-not-allowed" : "cursor-pointer"}`}
                    >
                      <span
                        className={`relative flex h-8 w-8 shrink-0 items-center justify-center rounded-full text-xs font-bold transition-all ${
                          active
                            ? "bg-cta-gradient text-white shadow-[0_0_18px_var(--neon-purple)]"
                            : done
                              ? "bg-emerald-500/15 text-emerald-500 ring-1 ring-emerald-500/40"
                              : "bg-muted/60 text-muted-foreground ring-1 ring-border"
                        }`}
                      >
                        {done ? <Check className="h-4 w-4" /> : i + 1}
                        {active && (
                          <span className="absolute inset-0 -z-10 animate-ping rounded-full bg-[var(--neon-purple)]/30" />
                        )}
                      </span>
                      <div className="min-w-0">
                        <p
                          className={`text-[10px] uppercase tracking-widest ${active ? "text-[var(--neon-purple)]" : "text-muted-foreground"}`}
                        >
                          Step {i + 1}
                        </p>
                        <p
                          className={`truncate text-sm font-bold ${active || done ? "text-foreground" : "text-muted-foreground"}`}
                        >
                          {l}
                        </p>
                        {ctxName && (done || active) && (
                          <p className="truncate text-[10px] text-muted-foreground">{ctxName}</p>
                        )}
                      </div>
                    </button>
                    {i < stepLabels.length - 1 && (
                      <div className="hidden h-px w-6 shrink-0 sm:block">
                        <div
                          className={`h-full w-full rounded-full ${done ? "bg-gradient-to-r from-emerald-500/60 to-[var(--neon-purple)]/60" : "bg-border"}`}
                        />
                      </div>
                    )}
                  </div>
                );
              })}
            </div>
          </div>
        )}

        {/* STEP 1 — LEVEL */}
        {step === 0 && (
          <section className="animate-fade-up">
            <div className="flex flex-wrap items-end justify-between gap-3">
              <div>
                <h2 className="font-display text-2xl font-bold">Step 1: Select Your Level</h2>
                <p className="text-sm text-muted-foreground">
                  Choose the level of exam you are preparing for.
                </p>
              </div>
              <SearchInput
                value={levelQuery}
                onChange={setLevelQuery}
                placeholder="Search level…"
              />
            </div>

            {levelsQ.isLoading ? (
              <LoadingBlock />
            ) : levelsList.length === 0 ? (
              <EmptyState text="No levels published yet. Ask an admin to add levels." />
            ) : (
              (() => {
                const qq = levelQuery.trim().toLowerCase();
                const filtered = qq
                  ? levelsList.filter(
                      (l) =>
                        l.name.toLowerCase().includes(qq) ||
                        (l.description ?? "").toLowerCase().includes(qq),
                    )
                  : levelsList;
                if (filtered.length === 0)
                  return (
                    <div className="mt-5">
                      <EmptyState text={`No levels match “${levelQuery}”.`} />
                    </div>
                  );
                return (
                  <div className="mt-5 grid grid-cols-1 gap-5 sm:grid-cols-2 lg:grid-cols-3">
                    {filtered.map((l, idx) => {
                      const Icon = LEVEL_ICONS[idx % LEVEL_ICONS.length];
                      const tone = l.color || LEVEL_TONES[idx % LEVEL_TONES.length];
                      const active = level === l.code;
                      const recommended = idx === 0;
                      return (
                        <button
                          key={l.code}
                          onClick={() => {
                            if (l.is_locked) return;
                            setLevel(l.code);
                            setStep(1);
                          }}
                          disabled={!!l.is_locked}
                          className={`group relative rounded-3xl p-px text-left transition-transform ${l.is_locked ? "cursor-not-allowed opacity-60" : "hover:-translate-y-1"} ${active ? "ring-2 ring-primary shadow-glow" : ""}`}
                          style={{
                            background: `linear-gradient(135deg, ${tone}, transparent 65%)`,
                          }}
                        >
                          <div className="glass relative h-full overflow-hidden rounded-[calc(theme(borderRadius.3xl)-1px)] p-6">
                            <div
                              className="pointer-events-none absolute -right-10 -top-10 h-32 w-32 rounded-full opacity-40 blur-3xl transition-opacity group-hover:opacity-80"
                              style={{ background: tone }}
                            />
                            <div className="relative flex items-start justify-between">
                              <div
                                className="flex h-12 w-12 items-center justify-center rounded-2xl text-white shadow-glow"
                                style={{
                                  background: `linear-gradient(135deg, ${tone}, oklch(0.55 0.2 270))`,
                                }}
                              >
                                <Icon className="h-6 w-6" />
                              </div>
                              {l.is_locked ? (
                                <span className="flex h-6 items-center gap-1 rounded-full bg-zinc-900/70 px-2 text-[10px] font-bold uppercase tracking-wide text-zinc-100 ring-1 ring-white/10">
                                  <Lock className="h-3 w-3" /> Locked
                                </span>
                              ) : active ? (
                                <span className="flex h-6 w-6 items-center justify-center rounded-full bg-cta-gradient text-white shadow-glow">
                                  <Check className="h-3.5 w-3.5" />
                                </span>
                              ) : null}
                            </div>
                            {recommended && !l.is_locked && (
                              <span className="relative mt-4 inline-flex items-center gap-1 rounded-full bg-amber-400/15 px-2 py-0.5 text-[10px] font-bold uppercase tracking-wide text-amber-500 ring-1 ring-amber-400/30">
                                <Sparkles className="h-3 w-3" /> Recommended
                              </span>
                            )}
                            <h3 className="font-display relative mt-3 text-xl font-bold">
                              {l.name}
                            </h3>
                            <p className="relative mt-1 text-sm text-muted-foreground line-clamp-2">
                              {l.description ?? "Tap to begin practising at this level."}
                            </p>
                            <div className="relative mt-5 flex items-center justify-between">
                              <span className="text-[11px] uppercase tracking-widest text-muted-foreground">
                                {l.is_locked ? "Unavailable" : "Continue"}
                              </span>
                              <span
                                className={`inline-flex items-center gap-1 text-xs font-bold transition-all ${l.is_locked ? "text-muted-foreground" : "text-gradient group-hover:gap-2"}`}
                              >
                                {l.is_locked ? (
                                  "Ask an admin"
                                ) : (
                                  <>
                                    Select level <ArrowRight className="h-3.5 w-3.5" />
                                  </>
                                )}
                              </span>
                            </div>
                          </div>
                        </button>
                      );
                    })}
                  </div>
                );
              })()
            )}

            {levelsList.length > 0 && (
              <div className="mt-5 glass shadow-card-soft rounded-2xl p-4 flex flex-wrap items-center justify-between gap-3">
                <div className="flex items-center gap-3">
                  <span className="flex h-9 w-9 items-center justify-center rounded-xl bg-cta-gradient text-white shadow-glow">
                    <Zap className="h-4 w-4" />
                  </span>
                  <div>
                    <p className="text-sm font-bold">Smart Recommendation</p>
                    <p className="text-xs text-muted-foreground">
                      Pick a level above to load its subjects and continue practising.
                    </p>
                  </div>
                </div>
              </div>
            )}
          </section>
        )}

        {/* STEP 2 — SUBJECT */}
        {step === 1 && (
          <section className="animate-fade-up">
            <div className="flex flex-wrap items-end justify-between gap-3">
              <div>
                <h2 className="font-display text-2xl font-bold">Step 2: Select Your Subject</h2>
                <p className="text-sm text-muted-foreground">
                  {levelName} Level · choose the subject you want to practise.
                </p>
              </div>
              <SearchInput
                value={subjectQuery}
                onChange={setSubjectQuery}
                placeholder="Search subject…"
              />
            </div>

            {subjectsQ.isLoading ? (
              <LoadingBlock />
            ) : (
              (() => {
                const qq = subjectQuery.trim().toLowerCase();
                const all = subjectsQ.data ?? [];
                const filtered = qq
                  ? all.filter(
                      (s) =>
                        s.name.toLowerCase().includes(qq) ||
                        (s.description ?? "").toLowerCase().includes(qq),
                    )
                  : all;
                if (all.length === 0)
                  return (
                    <div className="mt-5">
                      <EmptyState text="No subjects published for this level yet." />
                    </div>
                  );
                if (filtered.length === 0)
                  return (
                    <div className="mt-5">
                      <EmptyState text={`No subjects match “${subjectQuery}”.`} />
                    </div>
                  );
                return (
                  <div className="mt-5 grid grid-cols-1 gap-4 sm:grid-cols-2">
                    {filtered.map((s) => {
                      const { i: Icon, tone } = iconFor(s.slug);
                      const active = subjectId === s.id;
                      const prog = subjectProgressMap.get(s.id);
                      const pct = prog?.percent ?? 0;
                      const inProgress = (prog?.completed ?? 0) > 0 && pct < 100;
                      return (
                        <button
                          key={s.id}
                          onClick={() => {
                            setSubjectId(s.id);
                            setSubjectName(s.name);
                            setStep(2);
                          }}
                          className={`group relative rounded-3xl p-px text-left transition-transform hover:-translate-y-1 ${active ? "ring-2 ring-primary shadow-glow" : ""}`}
                          style={{
                            background: `linear-gradient(135deg, ${tone}, transparent 65%)`,
                          }}
                        >
                          <div className="glass relative h-full overflow-hidden rounded-[calc(theme(borderRadius.3xl)-1px)] p-5">
                            <div
                              className="pointer-events-none absolute -right-8 -top-8 h-24 w-24 rounded-full opacity-30 blur-2xl transition-opacity group-hover:opacity-70"
                              style={{ background: tone }}
                            />
                            <div className="relative flex items-start justify-between">
                              <div
                                className="flex h-11 w-11 items-center justify-center rounded-2xl text-white"
                                style={{
                                  background: `linear-gradient(135deg, ${tone}, oklch(0.55 0.2 270))`,
                                }}
                              >
                                <Icon className="h-5 w-5" />
                              </div>
                              {inProgress ? (
                                <span className="inline-flex items-center gap-1 rounded-full bg-[var(--neon-blue)]/15 px-2 py-0.5 text-[10px] font-bold text-[var(--neon-blue)] ring-1 ring-[var(--neon-blue)]/30">
                                  <TrendingUp className="h-3 w-3" /> Continue
                                </span>
                              ) : null}
                            </div>
                            <h3 className="font-display relative mt-4 text-lg font-bold">
                              {s.name}
                            </h3>
                            <p className="relative text-xs text-muted-foreground line-clamp-2">
                              {s.description ?? "Tap to explore chapters"}
                            </p>
                            {prog && prog.total > 0 && (
                              <div className="relative mt-3">
                                <div className="flex items-center justify-between text-[11px] font-semibold">
                                  <span className="text-muted-foreground">
                                    {prog.completed} / {prog.total} MCQs
                                  </span>
                                  <span className="text-gradient">{pct}%</span>
                                </div>
                                <div className="mt-1.5 h-1.5 w-full overflow-hidden rounded-full bg-muted/60">
                                  <div
                                    className="h-full rounded-full bg-gradient-to-r from-[var(--neon-purple)] to-[var(--neon-blue)] transition-all duration-500"
                                    style={{ width: `${pct}%` }}
                                  />
                                </div>
                              </div>
                            )}
                          </div>
                        </button>
                      );
                    })}
                  </div>
                );
              })()
            )}

            <StepFooter onBack={() => setStep(0)} backLabel="Back: Select Level" />
          </section>
        )}

        {/* STEP 3 — CHAPTER */}
        {step === 2 && (
          <section className="animate-fade-up">
            <div className="flex flex-wrap items-end justify-between gap-3">
              <div>
                <h2 className="font-display text-2xl font-bold">Step 3: Select Chapter</h2>
                <p className="text-sm text-muted-foreground">
                  {levelName} · {subjectName}
                </p>
              </div>
              <div className="flex items-center gap-2">
                <span className="glass rounded-full px-3 py-1 text-[11px] font-semibold text-muted-foreground">
                  {(chaptersQ.data ?? []).length} chapters
                </span>
                <SearchInput
                  value={chapterQuery}
                  onChange={setChapterQuery}
                  placeholder="Search chapter…"
                />
              </div>
            </div>

            {/* Your Progress in {subject} — premium hero card */}
            {(() => {
              const rows = (chapterProgressQ.data ?? []) as Array<{
                chapter_id: string;
                total: number;
                completed: number;
                percent: number;
                accuracy: number;
              }>;
              const totalCh = (chaptersQ.data ?? []).length;
              const completedCh = rows.filter((r) => r.total > 0 && r.completed >= r.total).length;
              const totalMcqs = rows.reduce((s, r) => s + (r.total || 0), 0);
              const solvedMcqs = rows.reduce((s, r) => s + (r.completed || 0), 0);
              const attempted = rows.filter((r) => r.completed > 0);
              const avgAccuracy = attempted.length
                ? Math.round(
                    attempted.reduce((s, r) => s + (r.accuracy || 0), 0) / attempted.length,
                  )
                : 0;
              const overallPct = totalMcqs ? Math.round((solvedMcqs / totalMcqs) * 100) : 0;
              return (
                <div className="mt-5 glass shadow-card-soft relative overflow-hidden rounded-3xl p-5 sm:p-6">
                  <div className="pointer-events-none absolute -right-16 -top-16 h-44 w-44 rounded-full bg-[var(--neon-purple)]/20 blur-3xl" />
                  <div className="pointer-events-none absolute -left-16 -bottom-16 h-44 w-44 rounded-full bg-[var(--neon-blue)]/15 blur-3xl" />
                  <div className="relative flex items-center justify-between gap-4">
                    <div className="min-w-0">
                      <p className="text-[10px] font-bold uppercase tracking-widest text-[var(--neon-purple)]">
                        Your Progress
                      </p>
                      <h3 className="font-display mt-1 truncate text-lg font-bold sm:text-xl">
                        in {subjectName}
                      </h3>
                    </div>
                    <div className="relative h-20 w-20 shrink-0">
                      <svg viewBox="0 0 100 100" className="h-20 w-20 -rotate-90">
                        <defs>
                          <linearGradient id="subjProg" x1="0" y1="0" x2="1" y2="1">
                            <stop offset="0%" stopColor="var(--neon-purple)" />
                            <stop offset="100%" stopColor="var(--neon-blue)" />
                          </linearGradient>
                        </defs>
                        <circle
                          cx="50"
                          cy="50"
                          r="42"
                          stroke="currentColor"
                          strokeWidth="9"
                          fill="none"
                          className="text-muted/50"
                        />
                        <circle
                          cx="50"
                          cy="50"
                          r="42"
                          strokeWidth="9"
                          fill="none"
                          strokeLinecap="round"
                          stroke="url(#subjProg)"
                          strokeDasharray={`${(overallPct / 100) * 2 * Math.PI * 42} ${2 * Math.PI * 42}`}
                          style={{
                            transition: "stroke-dasharray 600ms cubic-bezier(.2,.8,.2,1)",
                            filter: "drop-shadow(0 0 6px var(--neon-purple))",
                          }}
                        />
                      </svg>
                      <div className="absolute inset-0 flex items-center justify-center">
                        <span className="font-display text-base font-bold tabular-nums text-gradient">
                          {overallPct}%
                        </span>
                      </div>
                    </div>
                  </div>
                  <div className="relative mt-5 grid grid-cols-3 gap-3">
                    <div className="rounded-2xl border border-border/60 bg-background/40 p-3">
                      <p className="text-[10px] uppercase tracking-widest text-muted-foreground">
                        Chapters Completed
                      </p>
                      <p className="font-display mt-1 text-lg font-bold tabular-nums">
                        <span className="text-gradient">{completedCh}</span>
                        <span className="text-muted-foreground"> / {totalCh}</span>
                      </p>
                    </div>
                    <div className="rounded-2xl border border-border/60 bg-background/40 p-3">
                      <p className="text-[10px] uppercase tracking-widest text-muted-foreground">
                        MCQs Solved
                      </p>
                      <p className="font-display mt-1 text-lg font-bold tabular-nums text-gradient">
                        {solvedMcqs}
                      </p>
                    </div>
                    <div className="rounded-2xl border border-border/60 bg-background/40 p-3">
                      <p className="text-[10px] uppercase tracking-widest text-muted-foreground">
                        Accuracy
                      </p>
                      <p className="font-display mt-1 text-lg font-bold tabular-nums text-gradient">
                        {avgAccuracy}%
                      </p>
                    </div>
                  </div>
                </div>
              );
            })()}

            {chaptersQ.isLoading ? (
              <div className="mt-5">
                <LoadingBlock />
              </div>
            ) : (chaptersQ.data ?? []).length === 0 ? (
              <div className="mt-5">
                <EmptyState text="No chapters in this subject yet." />
              </div>
            ) : (
              (() => {
                const qq = chapterQuery.trim().toLowerCase();
                const all = chaptersQ.data ?? [];
                const filtered = qq
                  ? all.filter(
                      (c) =>
                        c.name.toLowerCase().includes(qq) ||
                        (c.description ?? "").toLowerCase().includes(qq),
                    )
                  : all;
                if (filtered.length === 0)
                  return (
                    <div className="mt-5">
                      <EmptyState text={`No chapters match “${chapterQuery}”.`} />
                    </div>
                  );
                return (
                  <div className="mt-5 space-y-3">
                    {filtered.map((c, idx) => {
                      const cprog = chapterProgressMap.get(c.id);
                      const cpct = cprog?.percent ?? 0;
                      const total = cprog?.total ?? 0;
                      const completed = cprog?.completed ?? 0;
                      const accuracy = cprog?.accuracy ?? 0;
                      const isComplete = total > 0 && completed >= total;
                      const isActive = pendingChapter?.id === c.id;
                      const status: "not-started" | "in-progress" | "completed" | "mastered" =
                        isComplete && accuracy >= 90
                          ? "mastered"
                          : isComplete
                            ? "completed"
                            : completed > 0
                              ? "in-progress"
                              : "not-started";
                      const statusTone =
                        status === "mastered"
                          ? "from-amber-400/15 to-amber-400/5 text-amber-500 ring-amber-400/30"
                          : status === "completed"
                            ? "from-emerald-500/15 to-emerald-500/5 text-emerald-500 ring-emerald-500/30"
                            : status === "in-progress"
                              ? "from-[var(--neon-blue)]/15 to-[var(--neon-blue)]/5 text-[var(--neon-blue)] ring-[var(--neon-blue)]/30"
                              : "from-muted/40 to-muted/10 text-muted-foreground ring-border";
                      return (
                        <button
                          key={c.id}
                          onClick={() =>
                            setPendingChapter({
                              id: c.id,
                              name: c.name,
                              description: c.description,
                            })
                          }
                          className={`group glass shadow-card-soft relative flex w-full items-center gap-4 overflow-hidden rounded-2xl p-4 text-left transition-all hover:-translate-y-0.5 hover:shadow-glow ${
                            isActive ? "ring-2 ring-[var(--neon-purple)] shadow-glow" : ""
                          }`}
                        >
                          <div className="flex h-12 w-12 shrink-0 items-center justify-center rounded-2xl bg-cta-gradient font-display text-base font-bold text-white shadow-glow">
                            {String(idx + 1).padStart(2, "0")}
                          </div>
                          <div className="min-w-0 flex-1">
                            <div className="flex flex-wrap items-center gap-2">
                              <h3 className="font-display truncate text-base font-bold leading-snug">
                                {c.name}
                              </h3>
                              <span
                                className={`inline-flex items-center gap-1 rounded-full bg-gradient-to-br px-2 py-0.5 text-[10px] font-bold uppercase tracking-wide ring-1 ring-inset ${statusTone}`}
                              >
                                {status.replace("-", " ")}
                              </span>
                            </div>
                            <p className="mt-1 flex flex-wrap items-center gap-3 text-[11px] font-semibold text-muted-foreground">
                              <span className="inline-flex items-center gap-1">
                                <BookOpen className="h-3 w-3" /> {total || "—"} MCQs
                              </span>
                              <span className="inline-flex items-center gap-1">
                                <Target className="h-3 w-3" /> {accuracy}% accuracy
                              </span>
                              <span className="inline-flex items-center gap-1">
                                <Clock className="h-3 w-3" /> ~
                                {Math.max(1, Math.round((total || 10) * 0.6))} min
                              </span>
                            </p>
                            {total > 0 && (
                              <div className="mt-2 flex items-center gap-2">
                                <div className="h-1.5 flex-1 overflow-hidden rounded-full bg-muted/60">
                                  <div
                                    className="h-full rounded-full bg-gradient-to-r from-[var(--neon-purple)] via-[var(--neon-blue)] to-emerald-400 transition-all duration-700"
                                    style={{ width: `${cpct}%` }}
                                  />
                                </div>
                                <span className="text-[11px] font-bold text-gradient tabular-nums">
                                  {cpct}%
                                </span>
                              </div>
                            )}
                          </div>
                          <ChevronRight className="h-5 w-5 shrink-0 text-muted-foreground transition-transform group-hover:translate-x-1 group-hover:text-foreground" />
                        </button>
                      );
                    })}
                  </div>
                );
              })()
            )}

            {/* Practice Start Panel — shown after a chapter is picked */}
            {pendingChapter &&
              (() => {
                const cprog = chapterProgressMap.get(pendingChapter.id);
                const total = cprog?.total ?? 0;
                const accuracy = cprog?.accuracy ?? 0;
                const completed = cprog?.completed ?? 0;
                const estMin = Math.max(1, Math.round((total || 10) * 0.6));
                return (
                  <div className="mt-6 glass shadow-glow relative overflow-hidden rounded-3xl p-6">
                    <div className="pointer-events-none absolute -right-16 -top-16 h-48 w-48 rounded-full bg-[var(--neon-purple)]/25 blur-3xl" />
                    <div className="pointer-events-none absolute -left-16 -bottom-16 h-48 w-48 rounded-full bg-[var(--neon-blue)]/20 blur-3xl" />
                    <div className="relative flex flex-wrap items-start justify-between gap-4">
                      <div className="min-w-0">
                        <span className="inline-flex items-center gap-1 rounded-full bg-[var(--neon-purple)]/15 px-2.5 py-0.5 text-[10px] font-bold uppercase tracking-widest text-[var(--neon-purple)] ring-1 ring-[var(--neon-purple)]/30">
                          <Play className="h-3 w-3" /> Ready to start
                        </span>
                        <h3 className="font-display mt-3 text-2xl font-bold leading-snug">
                          {pendingChapter.name}
                        </h3>
                        <p className="mt-1 text-xs text-muted-foreground">
                          {levelName} · {subjectName}
                        </p>
                      </div>
                      <button
                        onClick={() => {
                          const pc = pendingChapter;
                          setPendingChapter(null);
                          gotoChapter(pc.id, pc.name);
                        }}
                        className="bg-cta-gradient group inline-flex items-center gap-2 rounded-2xl px-6 py-3 text-sm font-bold text-white shadow-glow transition-transform hover:scale-[1.03]"
                      >
                        <Play className="h-4 w-4" /> Start Practice{" "}
                        <ArrowRight className="h-4 w-4 transition-transform group-hover:translate-x-1" />
                      </button>
                    </div>
                    <div className="relative mt-5 grid grid-cols-2 gap-3 sm:grid-cols-4">
                      <SummaryStat
                        icon={Layers}
                        label="Total Questions"
                        value={String(total || "—")}
                        tone="var(--neon-purple)"
                      />
                      <SummaryStat
                        icon={Clock}
                        label="Estimated Time"
                        value={`${estMin} min`}
                        tone="var(--neon-blue)"
                      />
                      <SummaryStat
                        icon={Target}
                        label="Previous Accuracy"
                        value={completed ? `${accuracy}%` : "—"}
                        tone="oklch(0.75 0.18 150)"
                      />
                      <SummaryStat
                        icon={Trophy}
                        label="Recommended Goal"
                        value="80%+"
                        tone="oklch(0.82 0.16 85)"
                      />
                    </div>

                    {/* Session Config */}
                    <div className="relative mt-5 rounded-2xl border border-border/60 bg-background/40 p-4">
                      <p className="flex items-center gap-1.5 text-[11px] font-bold uppercase tracking-widest text-muted-foreground">
                        <Settings2 className="h-3.5 w-3.5" /> Session settings
                      </p>
                      <div className="mt-3 grid grid-cols-1 gap-3 sm:grid-cols-3">
                        <div>
                          <label className="mb-1 flex items-center gap-1 text-[10px] font-bold uppercase tracking-widest text-muted-foreground">
                            <Shuffle className="h-3 w-3" /> Question count
                          </label>
                          <div className="flex flex-wrap gap-1.5">
                            {(["10", "25", "50", "all"] as const).map((c) => (
                              <button
                                key={c}
                                onClick={() => setSessionCount(c)}
                                className={`rounded-full px-3 py-1 text-[11px] font-semibold capitalize transition-all ${sessionCount === c ? "bg-cta-gradient text-white shadow-glow" : "glass text-foreground/70 hover:text-foreground"}`}
                              >
                                {c === "all" ? "All" : c}
                              </button>
                            ))}
                          </div>
                        </div>
                        <div>
                          <label className="mb-1 flex items-center gap-1 text-[10px] font-bold uppercase tracking-widest text-muted-foreground">
                            <Timer className="h-3 w-3" /> Timer
                          </label>
                          <div className="flex flex-wrap gap-1.5">
                            {([0, 5, 10, 20] as const).map((m) => (
                              <button
                                key={m}
                                onClick={() => {
                                  setSessionTimerMin(m);
                                  setTimeLeft(m * 60);
                                }}
                                className={`rounded-full px-3 py-1 text-[11px] font-semibold transition-all ${sessionTimerMin === m ? "bg-cta-gradient text-white shadow-glow" : "glass text-foreground/70 hover:text-foreground"}`}
                              >
                                {m === 0 ? "Off" : `${m}m`}
                              </button>
                            ))}
                          </div>
                        </div>
                        <div>
                          <label className="mb-1 flex items-center gap-1 text-[10px] font-bold uppercase tracking-widest text-muted-foreground">
                            <Lightbulb className="h-3 w-3" /> Mode
                          </label>
                          <div className="flex flex-wrap gap-1.5">
                            <button
                              onClick={() => setSessionMode("instant")}
                              className={`rounded-full px-3 py-1 text-[11px] font-semibold transition-all ${sessionMode === "instant" ? "bg-cta-gradient text-white shadow-glow" : "glass text-foreground/70 hover:text-foreground"}`}
                            >
                              Instant explanation
                            </button>
                            <button
                              onClick={() => setSessionMode("submit-end")}
                              className={`rounded-full px-3 py-1 text-[11px] font-semibold transition-all ${sessionMode === "submit-end" ? "bg-cta-gradient text-white shadow-glow" : "glass text-foreground/70 hover:text-foreground"}`}
                            >
                              Submit at end
                            </button>
                          </div>
                        </div>
                      </div>
                      <p className="mt-2 text-[10px] text-muted-foreground">
                        {timeLeft > 0
                          ? `Live countdown will auto-submit after ${sessionTimerMin}m.`
                          : "Untimed practice."}{" "}
                        · Active scope:{" "}
                        {sessionCount === "all"
                          ? `${total || 0} MCQs`
                          : `${Math.min(Number(sessionCount), total || 0)} of ${total || 0}`}
                      </p>
                    </div>
                  </div>
                );
              })()}

            <StepFooter onBack={() => setStep(1)} backLabel="Back: Select Subject" />
          </section>
        )}

        {/* STEP 4 — PRACTICE / RESULT */}
        {step === 3 && (
          <section className="animate-fade-up">
            {/* RESULT SCREEN */}
            {finished && !reviewMode ? (
              <ResultScreen
                stats={stats}
                total={total}
                chapterName={chapterName}
                subjectName={subjectName}
                level={levelName}
                durationSec={Math.max(1, Math.round((Date.now() - sessionStart) / 1000))}
                mcqs={mcqs}
                answers={answers}
                onReview={() => {
                  setReviewMode(true);
                  setCurrent(0);
                }}
                onRetry={restartSame}
                onNewChapter={() => setStep(2)}
                savedAttemptId={savedAttemptId}
                saving={saving}
                onSaveRetry={() => finishPractice()}
              />
            ) : (
              <div className="glass shadow-glow relative overflow-hidden rounded-3xl p-6">
                <div className="pointer-events-none absolute -right-20 -top-20 h-60 w-60 rounded-full bg-[var(--neon-purple)]/25 blur-3xl" />
                <div className="pointer-events-none absolute -left-20 -bottom-20 h-60 w-60 rounded-full bg-[var(--neon-blue)]/20 blur-3xl" />

                {mcqsQ.isLoading ? (
                  <LoadingBlock />
                ) : total === 0 ? (
                  <EmptyState text="No questions published in this chapter yet." />
                ) : q ? (
                  <>
                    <div className="relative flex items-center justify-between gap-3">
                      <div className="flex items-center gap-3 flex-wrap">
                        <span className="glass rounded-xl px-3 py-1.5 text-xs font-semibold">
                          Q {String(batchStart + current + 1).padStart(2, "0")} / {totalAll}
                        </span>
                        <span className="rounded-full bg-[var(--neon-purple)]/10 px-2 py-0.5 text-[10px] font-semibold text-[var(--neon-purple)] ring-1 ring-[var(--neon-purple)]/30">
                          Batch {safeBatchIndex + 1} / {numBatches} · {statsAll.submitted} /{" "}
                          {totalAll} completed
                        </span>
                        {reviewMode && (
                          <span className="rounded-full bg-[var(--neon-blue)]/15 px-2 py-0.5 text-[10px] font-semibold text-[var(--neon-blue)]">
                            <Eye className="mr-1 inline h-3 w-3" /> Review mode
                          </span>
                        )}
                      </div>
                      <div className="flex items-center gap-2">
                        <button
                          onClick={() => q && toggleBookmark(q.id)}
                          title={
                            bookmarkSet.has(q.id) ? "Remove bookmark" : "Bookmark this question"
                          }
                          className={`glass flex h-9 w-9 items-center justify-center rounded-xl transition-transform hover:scale-105 ${
                            bookmarkSet.has(q.id) ? "text-[var(--neon-purple)]" : ""
                          }`}
                        >
                          <Bookmark
                            className="h-4 w-4"
                            fill={bookmarkSet.has(q.id) ? "currentColor" : "none"}
                          />
                        </button>
                      </div>
                    </div>

                    <h3 className="font-display relative mt-6 text-xl font-bold leading-snug sm:text-2xl">
                      {sanitizeOptionText(q.question)}
                    </h3>

                    <div className="relative mt-6 grid grid-cols-1 gap-3 sm:grid-cols-2">
                      {options.map((o) => {
                        const isPicked = picked === o.k;
                        const isCorrect = correctChoice === o.k;
                        let state: OptionState = "idle";
                        if (revealResults) {
                          if (isCorrect) state = "correct";
                          else if (isPicked) state = "wrong";
                        } else if (isPicked) state = "selected";
                        const clickable = !reviewMode && !submittedNow;
                        return (
                          <OptionButton
                            key={`${q.id}:${o.k}`}
                            questionId={q.id}
                            optionKey={o.k}
                            text={o.t}
                            state={state}
                            clickable={clickable}
                            onPick={pickOption}
                          />
                        );
                      })}
                    </div>

                    {revealResults && q.explanation && (
                      <div className="relative mt-5">
                        <button
                          onClick={() => setShowExp((s) => !s)}
                          className="glass inline-flex items-center gap-2 rounded-xl px-3 py-2 text-xs font-semibold transition-transform hover:scale-[1.02]"
                        >
                          <Lightbulb className="h-3.5 w-3.5 text-[var(--neon-purple)]" />
                          Explanation
                          <ChevronDown
                            className={`h-3.5 w-3.5 transition-transform ${showExp ? "rotate-180" : ""}`}
                          />
                        </button>
                        {showExp && (
                          <div className="animate-fade-up mt-3 rounded-2xl border border-border bg-background/40 p-4 text-sm text-muted-foreground">
                            {q.explanation}
                          </div>
                        )}
                      </div>
                    )}

                    <div className="relative mt-6 flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
                      <button
                        onClick={prevQ}
                        disabled={current === 0 && safeBatchIndex === 0}
                        className="glass inline-flex items-center justify-center gap-2 rounded-xl px-4 py-2.5 text-sm font-semibold transition-transform hover:scale-[1.02] disabled:opacity-40"
                      >
                        <ArrowLeft className="h-4 w-4" /> Previous
                      </button>
                      <div className="flex flex-wrap gap-3">
                        {!reviewMode && !submittedNow && (
                          <>
                            <button
                              onClick={() => submitAnswer(null)}
                              className="rounded-xl border border-border bg-background/40 px-4 py-2.5 text-sm font-semibold transition-colors hover:bg-muted"
                            >
                              Skip
                            </button>
                            <button
                              onClick={() => selectedOption && submitAnswer(selectedOption)}
                              disabled={!selectedOption}
                              className="bg-cta-gradient inline-flex items-center gap-2 rounded-xl px-5 py-2.5 text-sm font-semibold text-white shadow-glow transition-transform hover:scale-[1.02] disabled:cursor-not-allowed disabled:opacity-40 disabled:shadow-none"
                            >
                              <Check className="h-4 w-4" /> Submit Answer
                            </button>
                          </>
                        )}
                        {!(current === total - 1 && isLastBatch) ? (
                          <button
                            onClick={nextQ}
                            disabled={!reviewMode && !submittedNow}
                            className="bg-cta-gradient inline-flex items-center gap-2 rounded-xl px-5 py-2.5 text-sm font-semibold text-white shadow-glow transition-transform hover:scale-[1.02] disabled:cursor-not-allowed disabled:opacity-40 disabled:shadow-none"
                          >
                            Next <ArrowRight className="h-4 w-4" />
                          </button>
                        ) : reviewMode ? (
                          <button
                            onClick={() => setReviewMode(false)}
                            className="bg-cta-gradient inline-flex items-center gap-2 rounded-xl px-5 py-2.5 text-sm font-semibold text-white shadow-glow transition-transform hover:scale-[1.02]"
                          >
                            Back to Result
                          </button>
                        ) : (
                          <button
                            onClick={() => finishPractice({ finalize: true })}
                            disabled={saving || !chapterAllSubmitted}
                            className="inline-flex items-center gap-2 rounded-xl bg-gradient-to-r from-emerald-500 to-emerald-600 px-5 py-2.5 text-sm font-semibold text-white shadow-glow transition-transform hover:scale-[1.02] disabled:cursor-not-allowed disabled:opacity-50"
                            title={
                              chapterAllSubmitted
                                ? "Complete the chapter"
                                : `Finish all ${totalAll} chapter MCQs first`
                            }
                          >
                            {saving ? (
                              <Loader2 className="h-4 w-4 animate-spin" />
                            ) : (
                              <Trophy className="h-4 w-4" />
                            )}
                            {saving
                              ? "Saving…"
                              : chapterAllSubmitted
                                ? "Finish Chapter"
                                : `Finish (${statsAll.submitted}/${totalAll})`}
                          </button>
                        )}
                      </div>
                    </div>
                  </>
                ) : null}
              </div>
            )}
          </section>
        )}
      </div>

      {/* RIGHT PANEL — only during practice */}
      {inPractice && (
        <aside className="space-y-4">
          <div className="glass shadow-card-soft relative overflow-hidden rounded-3xl p-5 backdrop-blur-xl">
            <div className="pointer-events-none absolute -right-12 -top-12 h-32 w-32 rounded-full bg-[var(--neon-purple)]/20 blur-3xl" />
            <div className="pointer-events-none absolute -left-12 -bottom-12 h-32 w-32 rounded-full bg-[var(--neon-blue)]/15 blur-3xl" />

            <div className="relative flex items-center justify-between">
              <div>
                <h3 className="font-display text-base font-bold">Session</h3>
                <p className="text-[10px] uppercase tracking-widest text-muted-foreground">
                  Live progress
                </p>
              </div>
              <Flame className="h-4 w-4 text-[var(--neon-pink)]" />
            </div>

            {/* Circular progress */}
            <div className="relative mt-5 flex items-center gap-4">
              <div className="relative h-24 w-24 shrink-0">
                <svg viewBox="0 0 100 100" className="h-24 w-24 -rotate-90">
                  <defs>
                    <linearGradient id="sessProg" x1="0" y1="0" x2="1" y2="1">
                      <stop offset="0%" stopColor="var(--neon-purple)" />
                      <stop offset="100%" stopColor="var(--neon-blue)" />
                    </linearGradient>
                  </defs>
                  <circle
                    cx="50"
                    cy="50"
                    r="42"
                    stroke="currentColor"
                    strokeWidth="8"
                    fill="none"
                    className="text-muted/50"
                  />
                  <circle
                    cx="50"
                    cy="50"
                    r="42"
                    strokeWidth="8"
                    fill="none"
                    strokeLinecap="round"
                    stroke="url(#sessProg)"
                    strokeDasharray={`${(totalAll ? statsAll.submitted / totalAll : 0) * 2 * Math.PI * 42} ${2 * Math.PI * 42}`}
                    style={{
                      transition: "stroke-dasharray 600ms cubic-bezier(.2,.8,.2,1)",
                      filter: "drop-shadow(0 0 8px var(--neon-purple))",
                    }}
                  />
                </svg>
                <div className="absolute inset-0 flex flex-col items-center justify-center">
                  <span className="font-display text-xl font-bold tabular-nums">
                    {statsAll.submitted}
                  </span>
                  <span className="text-[9px] uppercase tracking-widest text-muted-foreground">
                    / {totalAll || 0}
                  </span>
                </div>
              </div>
              <div className="min-w-0 flex-1">
                <p className="text-[10px] uppercase tracking-widest text-muted-foreground">
                  Chapter Accuracy
                </p>
                <p className="font-display text-2xl font-bold text-gradient tabular-nums">
                  {statsAll.accuracy}%
                </p>
                <div className="mt-2 h-1.5 w-full overflow-hidden rounded-full bg-muted">
                  <div
                    className="h-full rounded-full bg-gradient-to-r from-emerald-400 via-[var(--neon-blue)] to-[var(--neon-purple)] transition-all duration-700"
                    style={{ width: `${statsAll.accuracy}%` }}
                  />
                </div>
                <p className="mt-1 text-[10px] text-muted-foreground">
                  Batch {safeBatchIndex + 1}/{numBatches} · {stats.submitted}/{total} in batch
                </p>
              </div>
            </div>

            {/* Stat pills (chapter-wide) */}
            <div className="relative mt-5 grid grid-cols-3 gap-2">
              <StatPill label="Correct" value={statsAll.correct} tone="emerald" />
              <StatPill label="Wrong" value={statsAll.wrong} tone="rose" />
              <StatPill label="Skipped" value={statsAll.skipped} tone="amber" />
            </div>
          </div>

          {step === 3 && totalAll > 0 && (
            <div className="glass shadow-card-soft rounded-3xl p-5">
              <div className="flex items-center justify-between gap-2">
                <h3 className="font-display text-base font-bold">Question Map</h3>
                <span className="rounded-full bg-muted/60 px-2 py-0.5 text-[10px] font-bold text-foreground/70">
                  Batch {safeBatchIndex + 1} / {numBatches}
                </span>
              </div>
              <p className="text-xs font-medium text-foreground/70">{chapterName}</p>
              <p className="mt-1 text-[10px] uppercase tracking-widest text-muted-foreground">
                Q {batchStart + 1}–{batchEnd} of {totalAll} · {statsAll.submitted}/{totalAll}{" "}
                completed
              </p>

              <div className="mt-3 flex items-center justify-between gap-2">
                <button
                  onClick={() => gotoBatch(safeBatchIndex - 1)}
                  disabled={safeBatchIndex === 0}
                  className="glass inline-flex items-center gap-1 rounded-lg px-2.5 py-1 text-[11px] font-semibold disabled:opacity-40"
                >
                  <ArrowLeft className="h-3 w-3" /> Prev Batch
                </button>
                <button
                  onClick={() => gotoBatch(safeBatchIndex + 1)}
                  disabled={safeBatchIndex >= numBatches - 1}
                  className="glass inline-flex items-center gap-1 rounded-lg px-2.5 py-1 text-[11px] font-semibold disabled:opacity-40"
                >
                  Next Batch <ArrowRight className="h-3 w-3" />
                </button>
              </div>

              <div className="mt-4 grid grid-cols-5 gap-2">
                {mcqs.map((m, i) => {
                  const a = answers[i];
                  const isCurrent = i === current;
                  const globalNum = batchStart + i + 1;
                  let cls =
                    "border border-border bg-muted/60 text-foreground/80 dark:bg-zinc-800/80 dark:text-zinc-200";
                  if (isCurrent) {
                    cls =
                      "bg-blue-600 text-white border border-blue-700 shadow-[0_0_0_2px_rgba(37,99,235,0.35)] dark:bg-blue-500 dark:border-blue-400";
                  } else if (a) {
                    if (a.chosen === null)
                      cls =
                        "bg-amber-600 text-white border border-amber-700 dark:bg-amber-500 dark:border-amber-400";
                    else if (a.chosen === normalizeChoice(m.correct_option))
                      cls =
                        "bg-emerald-700 text-white border border-emerald-800 dark:bg-emerald-600 dark:border-emerald-500";
                    else
                      cls =
                        "bg-rose-700 text-white border border-rose-800 dark:bg-rose-600 dark:border-rose-500";
                  }
                  return (
                    <button
                      key={m.id}
                      onClick={() => jumpTo(i)}
                      className={`relative flex h-10 items-center justify-center rounded-lg text-[11px] font-bold tracking-tight transition-transform hover:scale-110 ${cls}`}
                      title={`Q${globalNum}${a ? (a.chosen === null ? " · skipped" : a.chosen === normalizeChoice(m.correct_option) ? " · correct" : " · wrong") : " · unattempted"}`}
                    >
                      {globalNum}
                    </button>
                  );
                })}
              </div>
              <div className="mt-4 grid grid-cols-2 gap-x-3 gap-y-1.5 text-[11px] font-medium text-foreground/80">
                <span className="flex items-center gap-1.5">
                  <span className="h-2.5 w-2.5 rounded-sm bg-emerald-700 dark:bg-emerald-600" />{" "}
                  Correct
                </span>
                <span className="flex items-center gap-1.5">
                  <span className="h-2.5 w-2.5 rounded-sm bg-rose-700 dark:bg-rose-600" /> Wrong
                </span>
                <span className="flex items-center gap-1.5">
                  <span className="h-2.5 w-2.5 rounded-sm bg-amber-600 dark:bg-amber-500" /> Skipped
                </span>
                <span className="flex items-center gap-1.5">
                  <span className="h-2.5 w-2.5 rounded-sm bg-blue-600 dark:bg-blue-500" /> Current
                </span>
                <span className="flex items-center gap-1.5">
                  <span className="h-2.5 w-2.5 rounded-sm bg-muted border border-border" />{" "}
                  Unattempted
                </span>
              </div>
              <p className="mt-2 text-[10px] text-muted-foreground">Tip: click a number to jump</p>
            </div>
          )}
        </aside>
      )}
    </div>
  );
}

/* ------------------------------------------------------------------ */
/*  Result screen                                                      */
/* ------------------------------------------------------------------ */

function ResultScreen({
  stats,
  total,
  chapterName,
  subjectName,
  level,
  durationSec,
  mcqs,
  answers,
  onReview,
  onRetry,
  onNewChapter,
  savedAttemptId,
  saving,
  onSaveRetry,
}: {
  stats: {
    correct: number;
    wrong: number;
    skipped: number;
    attempted: number;
    accuracy: number;
    score: number;
    submitted: number;
  };
  total: number;
  chapterName: string | null;
  subjectName: string | null;
  level: string | null;
  durationSec: number;
  mcqs: Mcq[];
  answers: AnswerRec[];
  onReview: () => void;
  onRetry: () => void;
  onNewChapter: () => void;
  savedAttemptId: string | null;
  saving: boolean;
  onSaveRetry: () => void;
}) {
  const passed = stats.score >= 60;

  return (
    <div className="space-y-5">
      {/* Hero */}
      <div className="glass shadow-glow relative overflow-hidden rounded-3xl p-6 sm:p-8">
        <div
          className="pointer-events-none absolute -right-20 -top-20 h-60 w-60 rounded-full blur-3xl"
          style={{ background: passed ? "oklch(0.75 0.18 150 / 0.3)" : "var(--neon-pink) / 0.25" }}
        />
        <div className="pointer-events-none absolute -left-20 -bottom-20 h-60 w-60 rounded-full bg-[var(--neon-blue)]/20 blur-3xl" />

        <div className="relative flex flex-col items-start gap-6 sm:flex-row sm:items-center sm:justify-between">
          <div>
            <span className="inline-flex items-center gap-2 rounded-full bg-emerald-400/15 px-3 py-1 text-[10px] font-bold uppercase tracking-widest text-emerald-400">
              <CheckCircle2 className="h-3 w-3" /> Practice Complete
            </span>
            <h2 className="font-display mt-3 text-3xl font-bold tracking-tight sm:text-4xl">
              {passed ? "Great work!" : "Keep going — you got this."}
            </h2>
            <p className="mt-1 text-sm text-muted-foreground">
              {level} · {subjectName} · {chapterName}
            </p>
            <p className="mt-1 text-[10px] text-muted-foreground">
              {new Date().toLocaleString()} {savedAttemptId ? "· saved" : ""}
            </p>
          </div>

          {/* Circular score */}
          <div className="relative">
            <svg width="140" height="140" className="-rotate-90">
              <circle
                cx="70"
                cy="70"
                r="60"
                stroke="currentColor"
                strokeWidth="10"
                fill="none"
                className="text-muted/40"
              />
              <circle
                cx="70"
                cy="70"
                r="60"
                strokeWidth="10"
                fill="none"
                strokeLinecap="round"
                stroke={passed ? "oklch(0.75 0.18 150)" : "var(--neon-pink)"}
                strokeDasharray={`${(stats.score / 100) * 2 * Math.PI * 60} ${2 * Math.PI * 60}`}
                style={{
                  filter: `drop-shadow(0 0 10px ${passed ? "oklch(0.75 0.18 150)" : "var(--neon-pink)"})`,
                }}
              />
            </svg>
            <div className="absolute inset-0 flex flex-col items-center justify-center">
              <span
                className={`font-display text-4xl font-bold ${passed ? "text-emerald-400" : "text-rose-400"}`}
              >
                {stats.score}%
              </span>
              <span className="text-[10px] uppercase tracking-widest text-muted-foreground">
                Score
              </span>
            </div>
          </div>
        </div>

        {/* KPI strip */}
        <div className="relative mt-6 grid grid-cols-2 gap-3 sm:grid-cols-5">
          <ResultStat
            icon={Target}
            label="Accuracy"
            value={`${stats.accuracy}%`}
            tone="var(--neon-purple)"
          />
          <ResultStat
            icon={CheckCircle2}
            label="Correct"
            value={`${stats.correct}/${total}`}
            tone="oklch(0.75 0.18 150)"
          />
          <ResultStat
            icon={XCircle}
            label="Wrong"
            value={String(stats.wrong)}
            tone="var(--neon-pink)"
          />
          <ResultStat
            icon={MinusCircle}
            label="Skipped"
            value={String(stats.skipped)}
            tone="oklch(0.78 0.15 60)"
          />
          <ResultStat
            icon={Clock}
            label="Time"
            value={fmtDuration(durationSec)}
            tone="var(--neon-blue)"
          />
        </div>

        {/* Actions */}
        <div className="relative mt-6 flex flex-wrap gap-3">
          <button
            onClick={onReview}
            className="bg-cta-gradient inline-flex items-center gap-2 rounded-xl px-5 py-2.5 text-sm font-semibold text-white shadow-glow transition-transform hover:scale-[1.02]"
          >
            <Eye className="h-4 w-4" /> Review Answers
          </button>
          <button
            onClick={onRetry}
            className="glass inline-flex items-center gap-2 rounded-xl px-4 py-2.5 text-sm font-semibold transition-transform hover:scale-[1.02]"
          >
            <RotateCw className="h-4 w-4" /> Retry Chapter
          </button>
          <button
            onClick={onNewChapter}
            className="rounded-xl border border-border bg-background/40 px-4 py-2.5 text-sm font-semibold transition-colors hover:bg-muted"
          >
            Pick Another Chapter
          </button>
          {!savedAttemptId && (
            <button
              onClick={onSaveRetry}
              disabled={saving}
              className="rounded-xl border border-amber-400/30 bg-amber-400/10 px-4 py-2.5 text-sm font-semibold text-amber-400 transition-colors hover:bg-amber-400/15 disabled:opacity-60"
            >
              {saving ? "Saving…" : "Save Attempt"}
            </button>
          )}
        </div>
      </div>

      {/* Weak spots */}
      <div className="grid grid-cols-1 gap-5">
        <div className="glass shadow-card-soft rounded-3xl p-5">
          <div className="flex items-center gap-2">
            <Target className="h-4 w-4 text-[var(--neon-purple)]" />
            <h3 className="font-display text-lg font-bold">Weak Spots</h3>
          </div>
          <p className="text-xs text-muted-foreground">Questions you got wrong — revisit these</p>
          <ul className="mt-4 space-y-2 max-h-64 overflow-y-auto pr-1">
            {mcqs.map((m, i) => {
              const a = answers[i];
              if (!a || a.chosen === null || a.chosen === normalizeChoice(m.correct_option))
                return null;
              return (
                <li key={m.id} className="rounded-xl bg-background/40 p-3 text-xs">
                  <p className="font-medium line-clamp-2">
                    Q{i + 1}. {sanitizeOptionText(m.question)}
                  </p>
                  <p className="mt-1 text-[10px] text-rose-400">
                    Your answer: {a.chosen} · Correct: <b>{m.correct_option}</b>
                  </p>
                </li>
              );
            })}
            {stats.wrong === 0 && stats.skipped === 0 && (
              <li className="text-xs text-emerald-400">🎯 No weak spots — perfect run.</li>
            )}
            {stats.skipped > 0 && (
              <li className="rounded-xl border border-dashed border-amber-400/30 p-2 text-[10px] text-amber-400">
                {stats.skipped} skipped — open Review to attempt them.
              </li>
            )}
          </ul>
        </div>
      </div>
    </div>
  );
}

function ResultStat({
  icon: Icon,
  label,
  value,
  tone,
}: {
  icon: typeof Target;
  label: string;
  value: string;
  tone: string;
}) {
  return (
    <div className="glass relative overflow-hidden rounded-2xl p-3">
      <div
        className="pointer-events-none absolute -right-6 -top-6 h-16 w-16 rounded-full opacity-30 blur-xl"
        style={{ background: tone }}
      />
      <div className="flex items-center gap-2">
        <Icon className="h-3.5 w-3.5" style={{ color: tone }} />
        <p className="text-[10px] uppercase tracking-widest text-muted-foreground">{label}</p>
      </div>
      <p className="font-display mt-1 text-lg font-bold">{value}</p>
    </div>
  );
}

function StatPill({
  label,
  value,
  tone,
}: {
  label: string;
  value: number;
  tone: "emerald" | "rose" | "amber";
}) {
  const toneCls =
    tone === "emerald"
      ? "from-emerald-500/15 to-emerald-500/5 text-emerald-500 ring-emerald-500/20"
      : tone === "rose"
        ? "from-rose-500/15 to-rose-500/5 text-rose-500 ring-rose-500/20"
        : "from-amber-500/15 to-amber-500/5 text-amber-500 ring-amber-500/20";
  return (
    <div
      className={`relative overflow-hidden rounded-xl bg-gradient-to-br ${toneCls} px-2.5 py-2 ring-1 ring-inset transition-transform hover:-translate-y-0.5`}
    >
      <p className="text-[9px] uppercase tracking-widest opacity-80">{label}</p>
      <p className="font-display mt-0.5 text-lg font-bold tabular-nums">{value}</p>
    </div>
  );
}

function Stat({ label, value, gradient }: { label: string; value: string; gradient?: boolean }) {
  return (
    <div className="rounded-2xl border border-border bg-card/40 p-3">
      <p className="text-[10px] uppercase tracking-wider text-muted-foreground">{label}</p>
      <p className={`font-display mt-1 text-xl font-bold ${gradient ? "text-gradient" : ""}`}>
        {value}
      </p>
    </div>
  );
}

function LoadingBlock() {
  return (
    <div className="flex items-center justify-center gap-2 p-10 text-sm text-muted-foreground">
      <Loader2 className="h-4 w-4 animate-spin" /> Loading…
    </div>
  );
}

function EmptyState({ text }: { text: string }) {
  return (
    <div className="rounded-2xl border border-dashed border-border bg-card/30 p-8 text-center text-sm text-muted-foreground">
      {text}
    </div>
  );
}

function SearchInput({
  value,
  onChange,
  placeholder,
}: {
  value: string;
  onChange: (v: string) => void;
  placeholder?: string;
}) {
  return (
    <div className="glass flex items-center gap-2 rounded-2xl px-3 py-2 transition-shadow focus-within:ring-2 focus-within:ring-primary/40 w-full sm:w-72">
      <Search className="h-4 w-4 shrink-0 text-muted-foreground" />
      <input
        value={value}
        onChange={(e) => onChange(e.target.value)}
        placeholder={placeholder}
        className="w-full min-w-0 bg-transparent text-sm outline-none placeholder:text-muted-foreground"
      />
      {value && (
        <button
          onClick={() => onChange("")}
          className="text-[10px] font-semibold text-muted-foreground hover:text-foreground"
        >
          clear
        </button>
      )}
    </div>
  );
}

function StepFooter({ onBack, backLabel }: { onBack: () => void; backLabel: string }) {
  return (
    <div className="mt-6 flex justify-start">
      <button
        onClick={onBack}
        className="glass inline-flex items-center gap-2 rounded-xl px-4 py-2.5 text-sm font-semibold transition-transform hover:scale-[1.02]"
      >
        <ArrowLeft className="h-4 w-4" /> {backLabel}
      </button>
    </div>
  );
}

function SummaryStat({
  icon: Icon,
  label,
  value,
  tone,
}: {
  icon: typeof Target;
  label: string;
  value: string;
  tone: string;
}) {
  return (
    <div className="glass relative overflow-hidden rounded-2xl p-3">
      <div
        className="pointer-events-none absolute -right-6 -top-6 h-16 w-16 rounded-full opacity-30 blur-xl"
        style={{ background: tone }}
      />
      <div className="relative flex items-center gap-2">
        <span
          className="flex h-7 w-7 items-center justify-center rounded-lg text-white"
          style={{ background: `linear-gradient(135deg, ${tone}, oklch(0.55 0.2 270))` }}
        >
          <Icon className="h-3.5 w-3.5" />
        </span>
        <p className="text-[10px] uppercase tracking-widest text-muted-foreground">{label}</p>
      </div>
      <p className="font-display relative mt-1.5 text-xl font-bold tabular-nums">{value}</p>
    </div>
  );
}
