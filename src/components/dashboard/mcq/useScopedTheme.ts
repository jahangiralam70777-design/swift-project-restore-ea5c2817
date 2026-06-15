import { useCallback, useEffect, useState } from "react";

export type ScopedTheme = "light" | "dark";
const STORAGE_KEY = "mcq.practice.theme";

/**
 * Page-scoped light/dark theme for the MCQ Practice experience.
 * Does NOT touch the global app theme — the returned `themeClass` is applied
 * to a wrapper element and the `.mcq-theme-light` token overrides in styles.css
 * make light mode render correctly even when the global shell is dark.
 */
export function useScopedTheme() {
  const [theme, setTheme] = useState<ScopedTheme>("dark");

  useEffect(() => {
    try {
      const stored = localStorage.getItem(STORAGE_KEY) as ScopedTheme | null;
      if (stored === "light" || stored === "dark") {
        setTheme(stored);
        return;
      }
      // Fall back to the global app preference on first visit.
      const global = document.documentElement.classList.contains("dark");
      setTheme(global ? "dark" : "light");
    } catch {
      /* ignore */
    }
  }, []);

  const toggle = useCallback(() => {
    setTheme((prev) => {
      const next = prev === "dark" ? "light" : "dark";
      try {
        localStorage.setItem(STORAGE_KEY, next);
      } catch {
        /* ignore */
      }
      return next;
    });
  }, []);

  const themeClass = theme === "dark" ? "mcq-scope dark" : "mcq-scope mcq-theme-light";
  return { theme, toggle, themeClass };
}
