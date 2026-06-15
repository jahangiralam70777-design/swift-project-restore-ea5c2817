-- =====================================================================
-- PRODUCTION_SECURITY_LOCK_FINAL.sql
-- Phase 1 — RLS hardening only. Idempotent, reversible, no schema changes.
-- Apply manually in the Supabase SQL editor.
--
-- Policy model:
--   ADMIN  : public.is_admin(auth.uid()) -> full ALL access.
--   PUBLIC : anon/auth read only published rows.
--   USER   : authenticated users see/modify only their own rows.
--
-- Covered tables:
--   profiles, blog_posts, quiz_questions, quizzes, mcqs, notifications,
--   site_pages, site_page_sections, media_assets, flash_cards,
--   short_notes, video_classes, question_bank_resources
--
-- Safe-execution rules:
--   * ALTER TABLE ... ENABLE RLS is no-op if already enabled.
--   * DROP POLICY IF EXISTS before every CREATE POLICY (idempotent).
--   * No DROP TABLE / DROP COLUMN / ALTER TYPE / RENAME.
--   * Uses ALTER TABLE IF EXISTS so missing optional tables don't abort.
--   * Helper functions use CREATE OR REPLACE.
-- =====================================================================

BEGIN;

-- ---------------------------------------------------------------------
-- 0. Admin helper. SECURITY DEFINER -> bypasses RLS on user_roles when
--    evaluating policies, so no recursive policy issues.
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.is_admin(_uid uuid DEFAULT auth.uid())
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.user_roles
    WHERE user_id = _uid
      AND role IN ('admin', 'super_admin')
  );
$$;

GRANT EXECUTE ON FUNCTION public.is_admin(uuid) TO anon, authenticated, service_role;

-- =====================================================================
-- USER DATA TABLES (self + admin only)
-- =====================================================================

-- 1. profiles -----------------------------------------------------------
ALTER TABLE IF EXISTS public.profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public profiles are viewable by everyone" ON public.profiles;
DROP POLICY IF EXISTS "Profiles are viewable by everyone"        ON public.profiles;
DROP POLICY IF EXISTS "Anyone can view profiles"                 ON public.profiles;
DROP POLICY IF EXISTS "profiles_public_read"                     ON public.profiles;
DROP POLICY IF EXISTS "profiles_select_all"                      ON public.profiles;
DROP POLICY IF EXISTS "profiles_self_select"                     ON public.profiles;
DROP POLICY IF EXISTS "profiles_self_update"                     ON public.profiles;
DROP POLICY IF EXISTS "profiles_admin_all"                       ON public.profiles;

CREATE POLICY "profiles_self_select" ON public.profiles
  FOR SELECT TO authenticated USING (id = auth.uid());

CREATE POLICY "profiles_self_update" ON public.profiles
  FOR UPDATE TO authenticated
  USING (id = auth.uid()) WITH CHECK (id = auth.uid());

CREATE POLICY "profiles_admin_all" ON public.profiles
  FOR ALL TO authenticated
  USING (public.is_admin(auth.uid())) WITH CHECK (public.is_admin(auth.uid()));

-- 2. notifications ------------------------------------------------------
ALTER TABLE IF EXISTS public.notifications ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "notifications_public_read"      ON public.notifications;
DROP POLICY IF EXISTS "notifications_select_all"       ON public.notifications;
DROP POLICY IF EXISTS "Anyone can view notifications"  ON public.notifications;
DROP POLICY IF EXISTS "notifications_owner_select"     ON public.notifications;
DROP POLICY IF EXISTS "notifications_owner_update"     ON public.notifications;
DROP POLICY IF EXISTS "notifications_admin_all"        ON public.notifications;

CREATE POLICY "notifications_owner_select" ON public.notifications
  FOR SELECT TO authenticated USING (user_id = auth.uid());

CREATE POLICY "notifications_owner_update" ON public.notifications
  FOR UPDATE TO authenticated
  USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

CREATE POLICY "notifications_admin_all" ON public.notifications
  FOR ALL TO authenticated
  USING (public.is_admin(auth.uid())) WITH CHECK (public.is_admin(auth.uid()));

-- =====================================================================
-- CONTENT TABLES (published-only public read + admin full)
-- =====================================================================

-- 3. blog_posts ---------------------------------------------------------
ALTER TABLE IF EXISTS public.blog_posts ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "blog_posts_public_read"     ON public.blog_posts;
DROP POLICY IF EXISTS "blog_posts_select_all"      ON public.blog_posts;
DROP POLICY IF EXISTS "Anyone can view blog posts" ON public.blog_posts;
DROP POLICY IF EXISTS "blog_posts_published_read"  ON public.blog_posts;
DROP POLICY IF EXISTS "blog_posts_admin_all"       ON public.blog_posts;

CREATE POLICY "blog_posts_published_read" ON public.blog_posts
  FOR SELECT TO anon, authenticated USING (status = 'published');

CREATE POLICY "blog_posts_admin_all" ON public.blog_posts
  FOR ALL TO authenticated
  USING (public.is_admin(auth.uid())) WITH CHECK (public.is_admin(auth.uid()));

-- 4. quizzes ------------------------------------------------------------
ALTER TABLE IF EXISTS public.quizzes ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "quizzes_public_read"     ON public.quizzes;
DROP POLICY IF EXISTS "quizzes_select_all"      ON public.quizzes;
DROP POLICY IF EXISTS "Anyone can view quizzes" ON public.quizzes;
DROP POLICY IF EXISTS "quizzes_published_read"  ON public.quizzes;
DROP POLICY IF EXISTS "quizzes_admin_all"       ON public.quizzes;

CREATE POLICY "quizzes_published_read" ON public.quizzes
  FOR SELECT TO anon, authenticated USING (status = 'published');

CREATE POLICY "quizzes_admin_all" ON public.quizzes
  FOR ALL TO authenticated
  USING (public.is_admin(auth.uid())) WITH CHECK (public.is_admin(auth.uid()));

-- 5. quiz_questions (gated by parent quiz status) -----------------------
ALTER TABLE IF EXISTS public.quiz_questions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "quiz_questions_public_read"     ON public.quiz_questions;
DROP POLICY IF EXISTS "Anyone can view quiz questions" ON public.quiz_questions;
DROP POLICY IF EXISTS "quiz_questions_select_all"      ON public.quiz_questions;
DROP POLICY IF EXISTS "quiz_questions_published_read"  ON public.quiz_questions;
DROP POLICY IF EXISTS "quiz_questions_admin_all"       ON public.quiz_questions;

CREATE POLICY "quiz_questions_published_read" ON public.quiz_questions
  FOR SELECT TO anon, authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.quizzes q
      WHERE q.id = quiz_questions.quiz_id
        AND q.status = 'published'
    )
  );

CREATE POLICY "quiz_questions_admin_all" ON public.quiz_questions
  FOR ALL TO authenticated
  USING (public.is_admin(auth.uid())) WITH CHECK (public.is_admin(auth.uid()));

-- 6. mcqs ---------------------------------------------------------------
ALTER TABLE IF EXISTS public.mcqs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "mcqs_public_read"     ON public.mcqs;
DROP POLICY IF EXISTS "mcqs_select_all"      ON public.mcqs;
DROP POLICY IF EXISTS "Anyone can view mcqs" ON public.mcqs;
DROP POLICY IF EXISTS "mcqs_published_read"  ON public.mcqs;
DROP POLICY IF EXISTS "mcqs_admin_all"       ON public.mcqs;

CREATE POLICY "mcqs_published_read" ON public.mcqs
  FOR SELECT TO anon, authenticated USING (status = 'published');

CREATE POLICY "mcqs_admin_all" ON public.mcqs
  FOR ALL TO authenticated
  USING (public.is_admin(auth.uid())) WITH CHECK (public.is_admin(auth.uid()));

-- 7. site_pages ---------------------------------------------------------
ALTER TABLE IF EXISTS public.site_pages ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "site_pages_public_read"     ON public.site_pages;
DROP POLICY IF EXISTS "site_pages_select_all"      ON public.site_pages;
DROP POLICY IF EXISTS "Anyone can view site pages" ON public.site_pages;
DROP POLICY IF EXISTS "site_pages_published_read"  ON public.site_pages;
DROP POLICY IF EXISTS "site_pages_admin_all"       ON public.site_pages;

CREATE POLICY "site_pages_published_read" ON public.site_pages
  FOR SELECT TO anon, authenticated USING (status = 'published');

CREATE POLICY "site_pages_admin_all" ON public.site_pages
  FOR ALL TO authenticated
  USING (public.is_admin(auth.uid())) WITH CHECK (public.is_admin(auth.uid()));

-- 8. site_page_sections (gated by parent site_pages.status) -------------
ALTER TABLE IF EXISTS public.site_page_sections ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "site_page_sections_public_read"     ON public.site_page_sections;
DROP POLICY IF EXISTS "site_page_sections_select_all"      ON public.site_page_sections;
DROP POLICY IF EXISTS "Anyone can view site page sections" ON public.site_page_sections;
DROP POLICY IF EXISTS "site_page_sections_published_read"  ON public.site_page_sections;
DROP POLICY IF EXISTS "site_page_sections_admin_all"       ON public.site_page_sections;

CREATE POLICY "site_page_sections_published_read" ON public.site_page_sections
  FOR SELECT TO anon, authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.site_pages sp
      WHERE sp.id = site_page_sections.page_id
        AND sp.status = 'published'
    )
  );

CREATE POLICY "site_page_sections_admin_all" ON public.site_page_sections
  FOR ALL TO authenticated
  USING (public.is_admin(auth.uid())) WITH CHECK (public.is_admin(auth.uid()));

-- 9. media_assets -------------------------------------------------------
--    Authenticated users may read references; anonymous read removed.
ALTER TABLE IF EXISTS public.media_assets ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "media_assets_public_read" ON public.media_assets;
DROP POLICY IF EXISTS "media_assets_select_all"  ON public.media_assets;
DROP POLICY IF EXISTS "Anyone can view media"    ON public.media_assets;
DROP POLICY IF EXISTS "media_assets_auth_read"   ON public.media_assets;
DROP POLICY IF EXISTS "media_assets_admin_all"   ON public.media_assets;

CREATE POLICY "media_assets_auth_read" ON public.media_assets
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "media_assets_admin_all" ON public.media_assets
  FOR ALL TO authenticated
  USING (public.is_admin(auth.uid())) WITH CHECK (public.is_admin(auth.uid()));

-- 10. flash_cards -------------------------------------------------------
ALTER TABLE IF EXISTS public.flash_cards ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "flash_cards_public_read"     ON public.flash_cards;
DROP POLICY IF EXISTS "flash_cards_select_all"      ON public.flash_cards;
DROP POLICY IF EXISTS "Anyone can view flash cards" ON public.flash_cards;
DROP POLICY IF EXISTS "flash_cards_published_read"  ON public.flash_cards;
DROP POLICY IF EXISTS "flash_cards_admin_all"       ON public.flash_cards;

CREATE POLICY "flash_cards_published_read" ON public.flash_cards
  FOR SELECT TO anon, authenticated USING (status = 'published');

CREATE POLICY "flash_cards_admin_all" ON public.flash_cards
  FOR ALL TO authenticated
  USING (public.is_admin(auth.uid())) WITH CHECK (public.is_admin(auth.uid()));

-- 11. short_notes -------------------------------------------------------
ALTER TABLE IF EXISTS public.short_notes ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "short_notes_public_read"     ON public.short_notes;
DROP POLICY IF EXISTS "short_notes_select_all"      ON public.short_notes;
DROP POLICY IF EXISTS "Anyone can view short notes" ON public.short_notes;
DROP POLICY IF EXISTS "short_notes_published_read"  ON public.short_notes;
DROP POLICY IF EXISTS "short_notes_admin_all"       ON public.short_notes;

CREATE POLICY "short_notes_published_read" ON public.short_notes
  FOR SELECT TO anon, authenticated USING (status = 'published');

CREATE POLICY "short_notes_admin_all" ON public.short_notes
  FOR ALL TO authenticated
  USING (public.is_admin(auth.uid())) WITH CHECK (public.is_admin(auth.uid()));

-- 12. video_classes -----------------------------------------------------
ALTER TABLE IF EXISTS public.video_classes ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "video_classes_public_read"       ON public.video_classes;
DROP POLICY IF EXISTS "video_classes_select_all"        ON public.video_classes;
DROP POLICY IF EXISTS "Anyone can view video classes"   ON public.video_classes;
DROP POLICY IF EXISTS "video_classes_published_read"    ON public.video_classes;
DROP POLICY IF EXISTS "video_classes_admin_all"         ON public.video_classes;

CREATE POLICY "video_classes_published_read" ON public.video_classes
  FOR SELECT TO anon, authenticated USING (status = 'published');

CREATE POLICY "video_classes_admin_all" ON public.video_classes
  FOR ALL TO authenticated
  USING (public.is_admin(auth.uid())) WITH CHECK (public.is_admin(auth.uid()));

-- 13. question_bank_resources ------------------------------------------
ALTER TABLE IF EXISTS public.question_bank_resources ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "qbr_public_read"     ON public.question_bank_resources;
DROP POLICY IF EXISTS "qbr_select_all"      ON public.question_bank_resources;
DROP POLICY IF EXISTS "Anyone can view qbr" ON public.question_bank_resources;
DROP POLICY IF EXISTS "qbr_published_read"  ON public.question_bank_resources;
DROP POLICY IF EXISTS "qbr_admin_all"       ON public.question_bank_resources;

CREATE POLICY "qbr_published_read" ON public.question_bank_resources
  FOR SELECT TO anon, authenticated USING (status = 'published');

CREATE POLICY "qbr_admin_all" ON public.question_bank_resources
  FOR ALL TO authenticated
  USING (public.is_admin(auth.uid())) WITH CHECK (public.is_admin(auth.uid()));

COMMIT;

-- =====================================================================
-- REVERSAL: every block can be undone by dropping the *_admin_all,
-- *_published_read, *_self_*, *_owner_* policies and (optionally)
-- re-creating the previous permissive policies. No schema was altered.
-- =====================================================================
