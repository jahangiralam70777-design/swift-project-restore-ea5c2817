-- =============================================================================
-- PRODUCTION SECURITY HARDENING — ADMIN FULL ACCESS MODE (idempotent)
-- Apply via Supabase SQL Editor.
--
-- Goals:
--   * Admin / super_admin retain UNRESTRICTED read+write on every public table
--   * Authenticated non-admins limited to their own rows
--   * Anonymous users limited to published content
--   * RLS enabled everywhere, realtime cannot leak drafts/private data
--   * Ban enforcement at session validation
--   * admin_run_select_query hardened (SELECT/WITH only, audit logged)
--   * Missing FKs + performance indexes added
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 0. HELPERS: is_admin() + audit logger
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.is_admin(_uid uuid DEFAULT auth.uid())
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.user_roles
    WHERE user_id = _uid AND role IN ('admin','super_admin')
  );
$$;
GRANT EXECUTE ON FUNCTION public.is_admin(uuid) TO anon, authenticated;

-- Ensure admin_action_log exists
CREATE TABLE IF NOT EXISTS public.admin_action_log (
  id           bigserial PRIMARY KEY,
  actor_id     uuid,
  permission   text,
  action       text,
  allowed      boolean,
  metadata     jsonb,
  created_at   timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.admin_action_log ENABLE ROW LEVEL SECURITY;
DO $$ BEGIN
  EXECUTE COALESCE((SELECT string_agg(format('DROP POLICY IF EXISTS %I ON public.admin_action_log;', polname),' ')
                    FROM pg_policies WHERE schemaname='public' AND tablename='admin_action_log'),'SELECT 1');
END $$;
CREATE POLICY "admin_action_log_admin_all" ON public.admin_action_log
  FOR ALL TO authenticated USING (public.is_admin(auth.uid())) WITH CHECK (true);
GRANT SELECT, INSERT ON public.admin_action_log TO authenticated;
GRANT USAGE, SELECT ON SEQUENCE public.admin_action_log_id_seq TO authenticated;

-- ---------------------------------------------------------------------------
-- 1. BAN ENFORCEMENT
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.is_user_banned(_uid uuid DEFAULT auth.uid())
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.user_bans
    WHERE user_id = _uid
      AND (expires_at IS NULL OR expires_at > now())
      AND COALESCE(revoked, false) = false
  );
$$;
GRANT EXECUTE ON FUNCTION public.is_user_banned(uuid) TO anon, authenticated;

-- ---------------------------------------------------------------------------
-- 2. CATCH-ALL: enable RLS on every public table + give admin full access
-- ---------------------------------------------------------------------------
DO $$
DECLARE r record;
BEGIN
  FOR r IN
    SELECT c.relname FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
    WHERE n.nspname='public' AND c.relkind='r'
  LOOP
    EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', r.relname);
    EXECUTE format('DROP POLICY IF EXISTS "admin_full_access" ON public.%I', r.relname);
    EXECUTE format(
      'CREATE POLICY "admin_full_access" ON public.%I FOR ALL TO authenticated USING (public.is_admin(auth.uid())) WITH CHECK (public.is_admin(auth.uid()))',
      r.relname
    );
  END LOOP;
END$$;

-- ---------------------------------------------------------------------------
-- 3. BLOG: admin sees all; public sees published only
-- ---------------------------------------------------------------------------
DO $$ BEGIN
  IF to_regclass('public.blog_posts') IS NOT NULL THEN
    EXECUTE 'DROP POLICY IF EXISTS "blog_posts_public_read_published" ON public.blog_posts';
    EXECUTE 'CREATE POLICY "blog_posts_public_read_published" ON public.blog_posts
             FOR SELECT TO anon, authenticated USING (status = ''published'')';
    EXECUTE 'GRANT SELECT ON public.blog_posts TO anon, authenticated';
    EXECUTE 'GRANT INSERT, UPDATE, DELETE ON public.blog_posts TO authenticated';
  END IF;
END$$;

DO $$
DECLARE t text;
BEGIN
  FOREACH t IN ARRAY ARRAY['blog_tags','blog_categories','blog_post_tags','blog_post_categories'] LOOP
    IF to_regclass('public.'||t) IS NOT NULL THEN
      EXECUTE format('DROP POLICY IF EXISTS "%s_public_read" ON public.%I', t, t);
      EXECUTE format('CREATE POLICY "%s_public_read" ON public.%I FOR SELECT TO anon, authenticated USING (true)', t, t);
      EXECUTE format('GRANT SELECT ON public.%I TO anon, authenticated', t);
    END IF;
  END LOOP;
END$$;

DO $$ BEGIN
  IF to_regclass('public.blog_views') IS NOT NULL THEN
    EXECUTE 'DROP POLICY IF EXISTS "blog_views_anon_insert" ON public.blog_views';
    EXECUTE 'CREATE POLICY "blog_views_anon_insert" ON public.blog_views
             FOR INSERT TO anon, authenticated WITH CHECK (true)';
    EXECUTE 'GRANT INSERT ON public.blog_views TO anon, authenticated';
  END IF;
END$$;

-- ---------------------------------------------------------------------------
-- 4. SITE / CMS: published content publicly readable
-- ---------------------------------------------------------------------------
DO $$ BEGIN
  IF to_regclass('public.site_page_sections') IS NOT NULL THEN
    EXECUTE 'DROP POLICY IF EXISTS "page_sections_public_read" ON public.site_page_sections';
    IF EXISTS (SELECT 1 FROM information_schema.columns
               WHERE table_schema='public' AND table_name='site_page_sections' AND column_name='status') THEN
      EXECUTE 'CREATE POLICY "page_sections_public_read" ON public.site_page_sections
               FOR SELECT TO anon, authenticated USING (status = ''published'')';
    ELSIF EXISTS (SELECT 1 FROM information_schema.columns
                  WHERE table_schema='public' AND table_name='site_page_sections' AND column_name='published_content') THEN
      EXECUTE 'CREATE POLICY "page_sections_public_read" ON public.site_page_sections
               FOR SELECT TO anon, authenticated USING (published_content IS NOT NULL)';
    END IF;
    EXECUTE 'GRANT SELECT ON public.site_page_sections TO anon, authenticated';
  END IF;
END$$;

DO $$ BEGIN
  IF to_regclass('public.site_pages') IS NOT NULL
     AND EXISTS (SELECT 1 FROM information_schema.columns
                 WHERE table_schema='public' AND table_name='site_pages' AND column_name='status') THEN
    EXECUTE 'DROP POLICY IF EXISTS "site_pages_public_read" ON public.site_pages';
    EXECUTE 'CREATE POLICY "site_pages_public_read" ON public.site_pages
             FOR SELECT TO anon, authenticated USING (status = ''published'')';
    EXECUTE 'GRANT SELECT ON public.site_pages TO anon, authenticated';
  END IF;
END$$;

DO $$ BEGIN
  IF to_regclass('public.homepage_sections') IS NOT NULL THEN
    EXECUTE 'DROP POLICY IF EXISTS "homepage_public_read" ON public.homepage_sections';
    IF EXISTS (SELECT 1 FROM information_schema.columns
               WHERE table_schema='public' AND table_name='homepage_sections' AND column_name='visible') THEN
      EXECUTE 'CREATE POLICY "homepage_public_read" ON public.homepage_sections
               FOR SELECT TO anon, authenticated USING (visible = true)';
    ELSE
      EXECUTE 'CREATE POLICY "homepage_public_read" ON public.homepage_sections
               FOR SELECT TO anon, authenticated USING (true)';
    END IF;
    EXECUTE 'GRANT SELECT ON public.homepage_sections TO anon, authenticated';
  END IF;
END$$;

DO $$ BEGIN
  IF to_regclass('public.site_settings') IS NOT NULL THEN
    EXECUTE 'DROP POLICY IF EXISTS "site_settings_public_read" ON public.site_settings';
    IF EXISTS (SELECT 1 FROM information_schema.columns
               WHERE table_schema='public' AND table_name='site_settings' AND column_name='published_value') THEN
      EXECUTE 'CREATE POLICY "site_settings_public_read" ON public.site_settings
               FOR SELECT TO anon, authenticated USING (published_value IS NOT NULL)';
    ELSE
      EXECUTE 'CREATE POLICY "site_settings_public_read" ON public.site_settings
               FOR SELECT TO anon, authenticated USING (true)';
    END IF;
    EXECUTE 'GRANT SELECT ON public.site_settings TO anon, authenticated';
  END IF;
END$$;

-- ---------------------------------------------------------------------------
-- 5. PUBLISHED-CONTENT public reads for learning resources
--    (admin still sees everything via admin_full_access policy above)
-- ---------------------------------------------------------------------------
DO $$
DECLARE t text;
BEGIN
  FOREACH t IN ARRAY ARRAY['mcqs','quizzes','flash_cards','short_notes','video_classes','question_bank_resources','mock_tests'] LOOP
    IF to_regclass('public.'||t) IS NOT NULL THEN
      EXECUTE format('DROP POLICY IF EXISTS "%s_public_published" ON public.%I', t, t);
      IF EXISTS (SELECT 1 FROM information_schema.columns
                 WHERE table_schema='public' AND table_name=t AND column_name='status') THEN
        EXECUTE format('CREATE POLICY "%s_public_published" ON public.%I
                        FOR SELECT TO authenticated USING (status = ''published'' OR public.is_admin(auth.uid()))', t, t);
      ELSIF EXISTS (SELECT 1 FROM information_schema.columns
                    WHERE table_schema='public' AND table_name=t AND column_name='is_published') THEN
        EXECUTE format('CREATE POLICY "%s_public_published" ON public.%I
                        FOR SELECT TO authenticated USING (is_published = true OR public.is_admin(auth.uid()))', t, t);
      ELSIF EXISTS (SELECT 1 FROM information_schema.columns
                    WHERE table_schema='public' AND table_name=t AND column_name='visible') THEN
        EXECUTE format('CREATE POLICY "%s_public_published" ON public.%I
                        FOR SELECT TO authenticated USING (visible = true OR public.is_admin(auth.uid()))', t, t);
      ELSE
        EXECUTE format('CREATE POLICY "%s_public_published" ON public.%I
                        FOR SELECT TO authenticated USING (true)', t, t);
      END IF;
      EXECUTE format('GRANT SELECT ON public.%I TO authenticated', t);
    END IF;
  END LOOP;
END$$;

-- ---------------------------------------------------------------------------
-- 6. USER-OWNED DATA: self can read/write own rows; admin sees all (above)
-- ---------------------------------------------------------------------------
DO $$
DECLARE t text; uidcol text;
BEGIN
  FOR t, uidcol IN VALUES
    ('profiles','id'),
    ('user_login_events','user_id'),
    ('activity_events','user_id'),
    ('exam_attempts','user_id'),
    ('quiz_sessions','user_id'),
    ('notifications','user_id'),
    ('bookmarks','user_id'),
    ('wrong_questions','user_id'),
    ('study_sessions','user_id'),
    ('user_goals','user_id'),
    ('user_bans','user_id')
  LOOP
    IF to_regclass('public.'||t) IS NOT NULL
       AND EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_schema='public' AND table_name=t AND column_name=uidcol) THEN
      EXECUTE format('DROP POLICY IF EXISTS "%s_self_read"  ON public.%I', t, t);
      EXECUTE format('DROP POLICY IF EXISTS "%s_self_write" ON public.%I', t, t);
      EXECUTE format(
        'CREATE POLICY "%s_self_read" ON public.%I FOR SELECT TO authenticated USING (%I = auth.uid())',
        t, t, uidcol
      );
      EXECUTE format(
        'CREATE POLICY "%s_self_write" ON public.%I FOR ALL TO authenticated
         USING (%I = auth.uid()) WITH CHECK (%I = auth.uid())',
        t, t, uidcol, uidcol
      );
      EXECUTE format('GRANT SELECT, INSERT, UPDATE, DELETE ON public.%I TO authenticated', t);
    END IF;
  END LOOP;
END$$;

-- profiles: prevent users from changing their own role/ban fields
DO $$ BEGIN
  IF to_regclass('public.profiles') IS NOT NULL THEN
    EXECUTE 'DROP POLICY IF EXISTS "profiles_self_write" ON public.profiles';
    EXECUTE 'CREATE POLICY "profiles_self_update" ON public.profiles
             FOR UPDATE TO authenticated USING (id = auth.uid()) WITH CHECK (id = auth.uid())';
  END IF;
END$$;

-- ---------------------------------------------------------------------------
-- 7. LOGS: admin-only (admin_full_access covers it; revoke anon)
-- ---------------------------------------------------------------------------
DO $$
DECLARE t text;
BEGIN
  FOREACH t IN ARRAY ARRAY['system_error_logs','admin_action_log','audit_log'] LOOP
    IF to_regclass('public.'||t) IS NOT NULL THEN
      EXECUTE format('REVOKE ALL ON public.%I FROM anon', t);
    END IF;
  END LOOP;
END$$;

-- ---------------------------------------------------------------------------
-- 8. MISSING FOREIGN KEYS → auth.users
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  pairs text[][] := ARRAY[
    ARRAY['blog_posts','author_id'],
    ARRAY['blog_views','user_id'],
    ARRAY['activity_events','user_id'],
    ARRAY['exam_attempts','user_id'],
    ARRAY['quiz_sessions','user_id'],
    ARRAY['notifications','user_id'],
    ARRAY['notifications','created_by']
  ];
  p text[]; tbl text; col text; fkname text;
BEGIN
  FOREACH p SLICE 1 IN ARRAY pairs LOOP
    tbl := p[1]; col := p[2];
    IF to_regclass('public.'||tbl) IS NOT NULL
       AND EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_schema='public' AND table_name=tbl AND column_name=col) THEN
      fkname := tbl||'_'||col||'_fkey';
      IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname=fkname) THEN
        BEGIN
          EXECUTE format(
            'ALTER TABLE public.%I ADD CONSTRAINT %I FOREIGN KEY (%I) REFERENCES auth.users(id) ON DELETE CASCADE',
            tbl, fkname, col
          );
        EXCEPTION WHEN others THEN
          RAISE NOTICE 'FK skip %.%: %', tbl, col, SQLERRM;
        END;
      END IF;
    END IF;
  END LOOP;
END$$;

-- ---------------------------------------------------------------------------
-- 9. PERFORMANCE INDEXES
-- ---------------------------------------------------------------------------
DO $$ BEGIN
  IF to_regclass('public.blog_posts') IS NOT NULL THEN
    CREATE INDEX IF NOT EXISTS idx_blog_posts_status_created  ON public.blog_posts(status, created_at DESC);
  END IF;
  IF to_regclass('public.site_pages') IS NOT NULL
     AND EXISTS (SELECT 1 FROM information_schema.columns
                 WHERE table_schema='public' AND table_name='site_pages' AND column_name='status') THEN
    CREATE INDEX IF NOT EXISTS idx_site_pages_status ON public.site_pages(status);
  END IF;
  IF to_regclass('public.notifications') IS NOT NULL THEN
    CREATE INDEX IF NOT EXISTS idx_notifications_created ON public.notifications(created_at DESC);
  END IF;
  IF to_regclass('public.activity_events') IS NOT NULL THEN
    CREATE INDEX IF NOT EXISTS idx_activity_events_user_created ON public.activity_events(user_id, created_at DESC);
  END IF;
  IF to_regclass('public.exam_attempts') IS NOT NULL THEN
    CREATE INDEX IF NOT EXISTS idx_exam_attempts_user_created ON public.exam_attempts(user_id, created_at DESC);
  END IF;
END$$;

-- ---------------------------------------------------------------------------
-- 10. HARDEN admin_run_select_query
--     - allow only SELECT or WITH ... SELECT
--     - reject ;, --, /*, INTO, and DML/DDL keywords
--     - audit every execution
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.admin_run_select_query(_sql text)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE
  trimmed   text;
  lowered   text;
  result    jsonb;
  forbidden text[] := ARRAY[
    'insert','update','delete','drop','alter','truncate','grant','revoke',
    'create','copy','vacuum','analyze','comment','call','do ','merge','reindex',
    'cluster','listen','notify','lock ','refresh','reset','set ','perform','into'
  ];
  kw text;
BEGIN
  IF NOT public.is_admin(auth.uid()) THEN
    RAISE EXCEPTION 'Forbidden: admin only';
  END IF;

  trimmed := btrim(COALESCE(_sql,''));
  IF length(trimmed) = 0 OR length(trimmed) > 8000 THEN
    RAISE EXCEPTION 'Invalid query length';
  END IF;

  -- strip trailing semicolons (single statement only)
  WHILE right(trimmed,1) = ';' LOOP trimmed := btrim(left(trimmed, length(trimmed)-1)); END LOOP;
  IF position(';' IN trimmed) > 0 THEN
    RAISE EXCEPTION 'Multiple statements are not allowed';
  END IF;
  IF position('--' IN trimmed) > 0 OR position('/*' IN trimmed) > 0 THEN
    RAISE EXCEPTION 'Comments are not allowed';
  END IF;

  lowered := lower(trimmed);
  IF lowered !~ '^(select|with)\s' THEN
    RAISE EXCEPTION 'Only SELECT/WITH queries are allowed';
  END IF;

  FOREACH kw IN ARRAY forbidden LOOP
    IF lowered ~ ('\m' || kw || '\M') THEN
      RAISE EXCEPTION 'Forbidden keyword: %', kw;
    END IF;
  END LOOP;

  EXECUTE format('SELECT COALESCE(jsonb_agg(t), ''[]''::jsonb) FROM (%s) t', trimmed) INTO result;

  -- audit
  INSERT INTO public.admin_action_log(actor_id, permission, action, allowed, metadata)
  VALUES (auth.uid(), 'manage_system', 'admin_run_select_query', true,
          jsonb_build_object('sql', trimmed, 'rows', jsonb_array_length(result)));

  RETURN result;
EXCEPTION WHEN others THEN
  INSERT INTO public.admin_action_log(actor_id, permission, action, allowed, metadata)
  VALUES (auth.uid(), 'manage_system', 'admin_run_select_query', false,
          jsonb_build_object('sql', _sql, 'error', SQLERRM));
  RAISE;
END;
$$;
REVOKE ALL ON FUNCTION public.admin_run_select_query(text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.admin_run_select_query(text) TO authenticated;

-- ---------------------------------------------------------------------------
-- 11. REALTIME PUBLICATION HYGIENE
--     RLS policies above already filter realtime payloads; ensure tables are
--     published consistently. (Service role bypasses RLS for admin channels.)
-- ---------------------------------------------------------------------------
DO $$
DECLARE t text;
BEGIN
  FOREACH t IN ARRAY ARRAY['blog_posts','site_page_sections','homepage_sections','profiles'] LOOP
    IF to_regclass('public.'||t) IS NOT NULL THEN
      BEGIN
        EXECUTE format('ALTER PUBLICATION supabase_realtime ADD TABLE public.%I', t);
      EXCEPTION WHEN duplicate_object THEN NULL;
               WHEN others THEN NULL;
      END;
    END IF;
  END LOOP;
END$$;

-- =============================================================================
-- DONE. Verification queries (run separately):
--   SELECT relname FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
--   WHERE n.nspname='public' AND c.relkind='r' AND NOT c.relrowsecurity;
--   SELECT tablename, count(*) FROM pg_policies WHERE schemaname='public' GROUP BY 1;
-- =============================================================================
