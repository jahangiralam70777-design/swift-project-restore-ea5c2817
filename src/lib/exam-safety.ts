/**
 * Shared utilities for in-progress exam protection.
 *
 *  - persistAnswers / loadAnswers: localStorage autosave keyed per attempt
 *    so a browser refresh or accidental tab close does not destroy work.
 *  - useBeforeUnloadGuard: shows the native browser "leave site?" prompt
 *    while the predicate is true (e.g. during an active timed attempt).
 */
import { useEffect } from "react";

const KEY = (id: string) => `exam-draft:${id}`;

export type ExamDraft = {
  answers: Record<string, string>;
  bookmarks: number[];
  current?: number;
  savedAt: number;
};

export function persistAnswers(attemptKey: string, draft: ExamDraft) {
  if (typeof window === "undefined") return;
  try {
    window.localStorage.setItem(KEY(attemptKey), JSON.stringify(draft));
  } catch {
    /* quota / private mode — non-fatal */
  }
}

export function loadAnswers(attemptKey: string): ExamDraft | null {
  if (typeof window === "undefined") return null;
  try {
    const raw = window.localStorage.getItem(KEY(attemptKey));
    if (!raw) return null;
    return JSON.parse(raw) as ExamDraft;
  } catch {
    return null;
  }
}

export function clearAnswers(attemptKey: string) {
  if (typeof window === "undefined") return;
  try {
    window.localStorage.removeItem(KEY(attemptKey));
  } catch {
    /* noop */
  }
}

/**
 * Show the native browser "Leave site?" prompt while `active` is true.
 * Use during in-progress exams to protect against accidental refresh /
 * close / back-navigation outside the SPA router.
 */
export function useBeforeUnloadGuard(active: boolean) {
  useEffect(() => {
    if (!active || typeof window === "undefined") return;
    const handler = (e: BeforeUnloadEvent) => {
      e.preventDefault();
      // Required for the prompt to show in Chromium browsers.
      e.returnValue = "";
      return "";
    };
    window.addEventListener("beforeunload", handler);
    return () => window.removeEventListener("beforeunload", handler);
  }, [active]);
}
