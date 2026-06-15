-- =====================================================================
-- SECURITY_PHASE3_HARDENING.sql
-- Rate limiting + storage bucket policies + profiles RLS hardening
-- + recommended indexes. All idempotent. Apply via the Supabase SQL
-- console (or psql) — this project's prior security migrations
-- (PHASE1_RLS_HARDENING.sql, SITE_MGMT_PHASE0_SECURITY.sql, ...) live
-- here under db_audit/ and are applied the same way.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1) Rate limiting (sliding-window in Postgres)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.rate_limit_hits (
  id          bigserial PRIMARY KEY,
  key         text        NOT NULL,
  occurred_at timestamptz NOT NULL DEFAULT now()
);

GRANT SELECT, INSERT, DELETE ON public.rate_limit_hits TO authenticated;
GRANT ALL ON public.rate_limit_hits TO service_role;
GRANT USAGE, SELECT ON SEQUENCE public.rate_limit_hits_id_seq TO authenticated, service_role;

ALTER TABLE public.rate_limit_hits ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "rate_limit_hits_no_direct_access" ON public.rate_limit_hits;
CREATE POLICY "rate_limit_hits_no_direct_access" ON public.rate_limit_hits
  FOR ALL TO authenticated USING (false) WITH CHECK (false);

CREATE INDEX IF NOT EXISTS idx_rate_limit_hits_key_time
  ON public.rate_limit_hits (key, occurred_at DESC);

-- check_rate_limit(_key, _max_hits, _window_seconds)
-- TRUE  = caller is under the limit; hit recorded.
-- FALSE = limit reached; hit NOT recorded.
CREATE OR REPLACE FUNCTION public.check_rate_limit(
  _key text,
  _max_hits int,
  _window_seconds int
) RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  cutoff timestamptz := now() - make_interval(secs => _window_seconds);
  hit_count int;
BEGIN
  DELETE FROM public.rate_limit_hits
   WHERE key = _key AND occurred_at < cutoff;

  SELECT count(*) INTO hit_count
    FROM public.rate_limit_hits
   WHERE key = _key AND occurred_at >= cutoff;

  IF hit_count >= _max_hits THEN
    RETURN false;
  END IF;

  INSERT INTO public.rate_limit_hits(key) VALUES (_key);
  RETURN true;
END;
$$;

REVOKE ALL ON FUNCTION public.check_rate_limit(text, int, int) FROM public;
GRANT EXECUTE ON FUNCTION public.check_rate_limit(text, int, int)
  TO authenticated, anon, service_role;

-- ---------------------------------------------------------------------
-- 2) Profiles RLS hardening — self-or-admin SELECT
-- ---------------------------------------------------------------------
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_policy
     WHERE polrelid='public.profiles'::regclass
       AND polname='profiles_select_authenticated'
  ) THEN
    DROP POLICY "profiles_select_authenticated" ON public.profiles;
  END IF;
END $$;

DROP POLICY IF EXISTS "profiles_select_self_or_admin" ON public.profiles;
CREATE POLICY "profiles_select_self_or_admin" ON public.profiles
  FOR SELECT TO authenticated
  USING (
    id = auth.uid()
    OR public.has_role(auth.uid(), 'admin'::public.app_role)
  );

-- ---------------------------------------------------------------------
-- 3) Storage bucket allow-list + upload restrictions
-- ---------------------------------------------------------------------
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES
  ('site-media','site-media', true,  20971520,
     ARRAY['image/png','image/jpeg','image/webp','image/gif','image/svg+xml',
           'video/mp4','video/webm','audio/mpeg','application/pdf']),
  ('blog',      'blog',       true,  10485760,
     ARRAY['image/png','image/jpeg','image/webp','image/gif']),
  ('avatars',   'avatars',    true,   2097152,
     ARRAY['image/png','image/jpeg','image/webp']),
  ('documents', 'documents',  false, 20971520,
     ARRAY['application/pdf','application/zip','image/png','image/jpeg','image/webp'])
ON CONFLICT (id) DO UPDATE
SET public             = EXCLUDED.public,
    file_size_limit    = EXCLUDED.file_size_limit,
    allowed_mime_types = EXCLUDED.allowed_mime_types;

DROP POLICY IF EXISTS "approved_buckets_public_read"   ON storage.objects;
DROP POLICY IF EXISTS "approved_buckets_authed_upload" ON storage.objects;
DROP POLICY IF EXISTS "documents_owner_read"           ON storage.objects;
DROP POLICY IF EXISTS "documents_owner_delete"         ON storage.objects;
DROP POLICY IF EXISTS "admin_full_access_storage"      ON storage.objects;

CREATE POLICY "approved_buckets_public_read" ON storage.objects
  FOR SELECT TO anon, authenticated
  USING (bucket_id IN ('blog','avatars','site-media'));

CREATE POLICY "approved_buckets_authed_upload" ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id IN ('site-media','blog','avatars','documents')
    AND owner = auth.uid()
  );

CREATE POLICY "documents_owner_read" ON storage.objects
  FOR SELECT TO authenticated
  USING (bucket_id = 'documents' AND owner = auth.uid());

CREATE POLICY "documents_owner_delete" ON storage.objects
  FOR DELETE TO authenticated
  USING (
    bucket_id IN ('site-media','blog','avatars','documents')
    AND owner = auth.uid()
  );

CREATE POLICY "admin_full_access_storage" ON storage.objects
  FOR ALL TO authenticated
  USING (
    bucket_id IN ('site-media','blog','avatars','documents')
    AND public.has_role(auth.uid(), 'admin'::public.app_role)
  )
  WITH CHECK (
    bucket_id IN ('site-media','blog','avatars','documents')
    AND public.has_role(auth.uid(), 'admin'::public.app_role)
  );

-- ---------------------------------------------------------------------
-- 4) Recommended indexes (non-CONCURRENT — safe inside a migration txn)
-- ---------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_study_heartbeats_user_created
  ON public.study_heartbeats (user_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_wrong_questions_user_created
  ON public.wrong_questions (user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_wrong_questions_user_mcq
  ON public.wrong_questions (user_id, mcq_id);

CREATE INDEX IF NOT EXISTS idx_mcq_attempts_user_created
  ON public.mcq_attempts (user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_mcq_attempts_created
  ON public.mcq_attempts (created_at DESC)
  WHERE is_correct IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_mock_attempts_user_started
  ON public.mock_attempts (user_id, started_at DESC);
CREATE INDEX IF NOT EXISTS idx_mock_attempts_test_score
  ON public.mock_attempts (mock_test_id, score DESC NULLS LAST);

CREATE INDEX IF NOT EXISTS idx_quiz_attempts_user_started
  ON public.quiz_attempts (user_id, started_at DESC);

CREATE INDEX IF NOT EXISTS idx_notifications_user_unread
  ON public.notifications (user_id, created_at DESC)
  WHERE read_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_blog_posts_published
  ON public.blog_posts (published_at DESC)
  WHERE status = 'published';
CREATE INDEX IF NOT EXISTS idx_blog_posts_slug
  ON public.blog_posts (slug)
  WHERE status = 'published';

CREATE INDEX IF NOT EXISTS idx_audit_log_actor_created
  ON public.audit_log (actor_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_log_target_created
  ON public.audit_log (target_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_user_roles_user
  ON public.user_roles (user_id);
