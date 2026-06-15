-- =====================================================================
-- PHASE 1 — RLS HARDENING (NO SCHEMA CHANGES, REVERSIBLE)
-- Manual application: paste into the Supabase SQL editor and run.
--
-- Scope:
--   * profiles            -> self + admin only (no public exposure)
--   * quiz_questions      -> published-only public read, admin full
--   * notifications       -> recipient (user_id = auth.uid()) + admin
--   * site_page_sections  -> published-only public read, admin full
--   * media_assets        -> remove anonymous full-read, admin/auth read
--   * blog_posts          -> public sees only status='published', admin full
--   * mcqs / quizzes      -> public sees only published, admin full
--
-- Rules:
--   * Does NOT drop tables, columns, types, or indexes.
--   * Only DROP POLICY ... IF EXISTS + CREATE POLICY.
--   * Admin/super_admin keep full access through public.is_admin().
--   * RLS stays enabled on every touched table.
-- =====================================================================

BEGIN;

-- ---------------------------------------------------------------------
-- 0. Admin helper (idempotent; safe if already defined).
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

-- ---------------------------------------------------------------------
-- 1. profiles  — self + admin only. NO public/anon read.
-- ---------------------------------------------------------------------
ALTER TABLE IF EXISTS public.profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public profiles are viewable by everyone" ON public.profiles;
DROP POLICY IF EXISTS "Profiles are viewable by everyone"        ON public.profiles;
DROP POLICY IF EXISTS "Anyone can view profiles"                 ON public.profiles;
DROP POLICY IF EXISTS "profiles_public_read"                     ON public.profiles;
DROP POLICY IF EXISTS "profiles_select_all"                      ON public.profiles;
DROP POLICY IF EXISTS "profiles_self_select"                     ON public.profiles;
DROP POLICY IF EXISTS "profiles_self_update"                     ON public.profiles;
DROP POLICY IF EXISTS "profiles_admin_all"                       ON public.profiles;

CREATE POLICY "profiles_self_select"
  ON public.profiles FOR SELECT
  TO authenticated
  USING (id = auth.uid());

CREATE POLICY "profiles_self_update"
  ON public.profiles FOR UPDATE
  TO authenticated
  USING (id = auth.uid())
  WITH CHECK (id = auth.uid());

CREATE POLICY "profiles_admin_all"
  ON public.profiles FOR ALL
  TO authenticated
  USING (public.is_admin(auth.uid()))
  WITH CHECK (public.is_admin(auth.uid()));

-- ---------------------------------------------------------------------
-- 2. quiz_questions — public can only read published; admin full.
-- ---------------------------------------------------------------------
ALTER TABLE IF EXISTS public.quiz_questions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "quiz_questions_public_read"    ON public.quiz_questions;
DROP POLICY IF EXISTS "Anyone can view quiz questions" ON public.quiz_questions;
DROP POLICY IF EXISTS "quiz_questions_select_all"     ON public.quiz_questions;
DROP POLICY IF EXISTS "quiz_questions_published_read" ON public.quiz_questions;
DROP POLICY IF EXISTS "quiz_questions_admin_all"      ON public.quiz_questions;

CREATE POLICY "quiz_questions_published_read"
  ON public.quiz_questions FOR SELECT
  TO anon, authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.quizzes q
      WHERE q.id = quiz_questions.quiz_id
        AND q.status = 'published'
    )
  );

CREATE POLICY "quiz_questions_admin_all"
  ON public.quiz_questions FOR ALL
  TO authenticated
  USING (public.is_admin(auth.uid()))
  WITH CHECK (public.is_admin(auth.uid()));

-- ---------------------------------------------------------------------
-- 3. notifications — recipient only + admin full.
-- ---------------------------------------------------------------------
ALTER TABLE IF EXISTS public.notifications ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "notifications_public_read"  ON public.notifications;
DROP POLICY IF EXISTS "notifications_select_all"   ON public.notifications;
DROP POLICY IF EXISTS "Anyone can view notifications" ON public.notifications;
DROP POLICY IF EXISTS "notifications_owner_select" ON public.notifications;
DROP POLICY IF EXISTS "notifications_owner_update" ON public.notifications;
DROP POLICY IF EXISTS "notifications_admin_all"    ON public.notifications;

CREATE POLICY "notifications_owner_select"
  ON public.notifications FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "notifications_owner_update"
  ON public.notifications FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "notifications_admin_all"
  ON public.notifications FOR ALL
  TO authenticated
  USING (public.is_admin(auth.uid()))
  WITH CHECK (public.is_admin(auth.uid()));

-- ---------------------------------------------------------------------
-- 4. site_page_sections — published-only public read; admin full.
-- ---------------------------------------------------------------------
ALTER TABLE IF EXISTS public.site_page_sections ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "site_page_sections_public_read"     ON public.site_page_sections;
DROP POLICY IF EXISTS "site_page_sections_select_all"      ON public.site_page_sections;
DROP POLICY IF EXISTS "Anyone can view site page sections" ON public.site_page_sections;
DROP POLICY IF EXISTS "site_page_sections_published_read"  ON public.site_page_sections;
DROP POLICY IF EXISTS "site_page_sections_admin_all"       ON public.site_page_sections;

CREATE POLICY "site_page_sections_published_read"
  ON public.site_page_sections FOR SELECT
  TO anon, authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.site_pages sp
      WHERE sp.id = site_page_sections.page_id
        AND sp.status = 'published'
    )
  );

CREATE POLICY "site_page_sections_admin_all"
  ON public.site_page_sections FOR ALL
  TO authenticated
  USING (public.is_admin(auth.uid()))
  WITH CHECK (public.is_admin(auth.uid()));

-- ---------------------------------------------------------------------
-- 5. media_assets — remove anonymous full read; auth can read, admin full.
-- ---------------------------------------------------------------------
ALTER TABLE IF EXISTS public.media_assets ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "media_assets_public_read" ON public.media_assets;
DROP POLICY IF EXISTS "media_assets_select_all"  ON public.media_assets;
DROP POLICY IF EXISTS "Anyone can view media"    ON public.media_assets;
DROP POLICY IF EXISTS "media_assets_auth_read"   ON public.media_assets;
DROP POLICY IF EXISTS "media_assets_admin_all"   ON public.media_assets;

CREATE POLICY "media_assets_auth_read"
  ON public.media_assets FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "media_assets_admin_all"
  ON public.media_assets FOR ALL
  TO authenticated
  USING (public.is_admin(auth.uid()))
  WITH CHECK (public.is_admin(auth.uid()));

-- ---------------------------------------------------------------------
-- 6. blog_posts — public sees only status='published'; admin full.
-- ---------------------------------------------------------------------
ALTER TABLE IF EXISTS public.blog_posts ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "blog_posts_public_read"     ON public.blog_posts;
DROP POLICY IF EXISTS "blog_posts_select_all"      ON public.blog_posts;
DROP POLICY IF EXISTS "Anyone can view blog posts" ON public.blog_posts;
DROP POLICY IF EXISTS "blog_posts_published_read"  ON public.blog_posts;
DROP POLICY IF EXISTS "blog_posts_admin_all"       ON public.blog_posts;

CREATE POLICY "blog_posts_published_read"
  ON public.blog_posts FOR SELECT
  TO anon, authenticated
  USING (status = 'published');

CREATE POLICY "blog_posts_admin_all"
  ON public.blog_posts FOR ALL
  TO authenticated
  USING (public.is_admin(auth.uid()))
  WITH CHECK (public.is_admin(auth.uid()));

-- ---------------------------------------------------------------------
-- 7. mcqs — public sees only published; admin full.
-- ---------------------------------------------------------------------
ALTER TABLE IF EXISTS public.mcqs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "mcqs_public_read"     ON public.mcqs;
DROP POLICY IF EXISTS "mcqs_select_all"      ON public.mcqs;
DROP POLICY IF EXISTS "Anyone can view mcqs" ON public.mcqs;
DROP POLICY IF EXISTS "mcqs_published_read"  ON public.mcqs;
DROP POLICY IF EXISTS "mcqs_admin_all"       ON public.mcqs;

CREATE POLICY "mcqs_published_read"
  ON public.mcqs FOR SELECT
  TO anon, authenticated
  USING (status = 'published');

CREATE POLICY "mcqs_admin_all"
  ON public.mcqs FOR ALL
  TO authenticated
  USING (public.is_admin(auth.uid()))
  WITH CHECK (public.is_admin(auth.uid()));

-- ---------------------------------------------------------------------
-- 8. quizzes — public sees only published; admin full.
-- ---------------------------------------------------------------------
ALTER TABLE IF EXISTS public.quizzes ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "quizzes_public_read"     ON public.quizzes;
DROP POLICY IF EXISTS "quizzes_select_all"      ON public.quizzes;
DROP POLICY IF EXISTS "Anyone can view quizzes" ON public.quizzes;
DROP POLICY IF EXISTS "quizzes_published_read"  ON public.quizzes;
DROP POLICY IF EXISTS "quizzes_admin_all"       ON public.quizzes;

CREATE POLICY "quizzes_published_read"
  ON public.quizzes FOR SELECT
  TO anon, authenticated
  USING (status = 'published');

CREATE POLICY "quizzes_admin_all"
  ON public.quizzes FOR ALL
  TO authenticated
  USING (public.is_admin(auth.uid()))
  WITH CHECK (public.is_admin(auth.uid()));

COMMIT;

-- =====================================================================
-- REVERSAL HINT (manual): each block above can be undone by dropping
-- the new *_admin_all / *_published_read / *_self_* / *_owner_* policies
-- and recreating the previous permissive policy. No schema was altered.
-- =====================================================================
