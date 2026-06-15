-- =====================================================================
-- RECOMMENDED_INDEXES.sql
-- Non-destructive index additions to keep dashboard/leaderboard/heartbeat
-- queries flat up to ~50 000 users.
--
-- REVIEW BEFORE APPLYING:
--   1. EXPLAIN ANALYZE the exact queries from src/lib/*.functions.ts to
--      confirm each index actually wins.
--   2. Apply via `CREATE INDEX CONCURRENTLY` (already used below) so no
--      table is locked during creation.
--   3. Roll out one index at a time on production; monitor pg_stat_user_indexes
--      for idx_scan vs seq_scan deltas afterwards.
--
-- All `IF NOT EXISTS` so the script is idempotent.
-- =====================================================================

-- --- Heartbeats / activity tracking ----------------------------------
-- DashboardPreview / DailyProgressCenter / ActivityTracker filter by
-- user_id then sort by created_at DESC.
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_study_heartbeats_user_created
  ON public.study_heartbeats (user_id, created_at DESC);

-- --- Wrong questions revisit list ------------------------------------
-- WrongQuestionsFlow paginates per user, newest first, and frequently
-- filters by mcq_id for "is this still wrong?" lookups.
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_wrong_questions_user_created
  ON public.wrong_questions (user_id, created_at DESC);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_wrong_questions_user_mcq
  ON public.wrong_questions (user_id, mcq_id);

-- --- MCQ attempts (leaderboard + per-user stats) ---------------------
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_mcq_attempts_user_created
  ON public.mcq_attempts (user_id, created_at DESC);
-- For "global accuracy in last 7 days" leaderboard reads.
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_mcq_attempts_created
  ON public.mcq_attempts (created_at DESC)
  WHERE is_correct IS NOT NULL;

-- --- Mock test attempts / leaderboard --------------------------------
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_mock_attempts_user_started
  ON public.mock_attempts (user_id, started_at DESC);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_mock_attempts_test_score
  ON public.mock_attempts (mock_test_id, score DESC NULLS LAST);

-- --- Quiz attempts ---------------------------------------------------
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_quiz_attempts_user_started
  ON public.quiz_attempts (user_id, started_at DESC);

-- --- Notifications inbox --------------------------------------------
-- Topbar bell badge: unread count per user.
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_notifications_user_unread
  ON public.notifications (user_id, created_at DESC)
  WHERE read_at IS NULL;

-- --- Blog ------------------------------------------------------------
-- Public listing + sitemap query: WHERE status='published' ORDER BY published_at DESC.
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_blog_posts_published
  ON public.blog_posts (published_at DESC)
  WHERE status = 'published';
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_blog_posts_slug
  ON public.blog_posts (slug)
  WHERE status = 'published';

-- --- Audit log -------------------------------------------------------
-- Admin search by actor / target / created_at.
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_audit_log_actor_created
  ON public.audit_log (actor_id, created_at DESC);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_audit_log_target_created
  ON public.audit_log (target_id, created_at DESC);

-- --- user_roles lookups (hot path in has_role) ----------------------
-- Likely already a UNIQUE (user_id, role) index from the table definition;
-- this is a fallback if the constraint was created without an index.
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_user_roles_user
  ON public.user_roles (user_id);
