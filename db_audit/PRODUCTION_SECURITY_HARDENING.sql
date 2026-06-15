-- =============================================================================
-- PRODUCTION SECURITY HARDENING (idempotent, safe to re-run)
-- Apply via Supabase SQL Editor against project xgnlydivsecwodwhdvky.
--
-- Covers:
--   1. Blog public-read-published-only + drafts admin-only
--   2. Homepage / CMS published-only public reads
--   3. User data: self + admin
--   4. Logs: admin-only
--   5. Catch-all: enable RLS on every public table, default admin-only
--   6. Missing FKs to auth.users
--   7. Performance indexes
--   8. Harden admin_run_select_query grants
--
-- All statements guarded with IF EXISTS / to_regclass / information_schema
-- checks so missing tables/columns are skipped, not errors.
-- =============================================================================

-- 0. Helper: is_admin() wrapper (uses existing public.has_role infrastructure)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public' AND p.proname = 'is_admin'
  ) THEN
    EXECUTE $f$
      CREATE OR REPLACE FUNCTION public.is_admin(_uid uuid DEFAULT auth.uid())
      RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public
      AS $body$
        SELECT EXISTS (
          SELECT 1 FROM public.user_roles
          WHERE user_id = _uid AND role IN ('admin','super_admin')
        );
      $body$;
    $f$;
  END IF;
END$$;

GRANT EXECUTE ON FUNCTION public.is_admin(uuid) TO anon, authenticated;

-- 1. BLOG ---------------------------------------------------------------------
DO $$
BEGIN
  IF to_regclass('public.blog_posts') IS NOT NULL THEN
    EXECUTE 'ALTER TABLE public.blog_posts ENABLE ROW LEVEL SECURITY';
    EXECUTE 'ALTER TABLE public.blog_posts FORCE ROW LEVEL SECURITY';
    EXECUTE COALESCE((
      SELECT string_agg(format('DROP POLICY IF EXISTS %I ON public.blog_posts;', polname), ' ')
      FROM pg_policies WHERE schemaname='public' AND tablename='blog_posts'
    ), 'SELECT 1');
    EXECUTE 'CREATE POLICY "blog_posts_public_read_published" ON public.blog_posts FOR SELECT TO anon, authenticated USING (status = ''published'')';
    EXECUTE 'CREATE POLICY "blog_posts_admin_all" ON public.blog_posts FOR ALL TO authenticated USING (public.is_admin(auth.uid())) WITH CHECK (public.is_admin(auth.uid()))';
    EXECUTE 'GRANT SELECT ON public.blog_posts TO anon, authenticated';
    EXECUTE 'GRANT INSERT, UPDATE, DELETE ON public.blog_posts TO authenticated';
  END IF;
END$$;

DO $$
BEGIN
  IF to_regclass('public.blog_views') IS NOT NULL THEN
    EXECUTE 'ALTER TABLE public.blog_views ENABLE ROW LEVEL SECURITY';
    EXECUTE COALESCE((
      SELECT string_agg(format('DROP POLICY IF EXISTS %I ON public.blog_views;', polname), ' ')
      FROM pg_policies WHERE schemaname='public' AND tablename='blog_views'
    ), 'SELECT 1');
    EXECUTE 'CREATE POLICY "blog_views_anon_insert" ON public.blog_views FOR INSERT TO anon, authenticated WITH CHECK (true)';
    EXECUTE 'CREATE POLICY "blog_views_admin_read"  ON public.blog_views FOR SELECT TO authenticated USING (public.is_admin(auth.uid()))';
    EXECUTE 'GRANT INSERT ON public.blog_views TO anon, authenticated';
    EXECUTE 'GRANT SELECT ON public.blog_views TO authenticated';
  END IF;
END$$;

DO $$
DECLARE t text;
BEGIN
  FOREACH t IN ARRAY ARRAY['blog_tags','blog_categories','blog_post_tags','blog_post_categories'] LOOP
    IF to_regclass('public.'||t) IS NOT NULL THEN
      EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', t);
      EXECUTE format('DROP POLICY IF EXISTS "%s_public_read" ON public.%I', t, t);
      EXECUTE format('CREATE POLICY "%s_public_read" ON public.%I FOR SELECT TO anon, authenticated USING (true)', t, t);
      EXECUTE format('DROP POLICY IF EXISTS "%s_admin_write" ON public.%I', t, t);
      EXECUTE format('CREATE POLICY "%s_admin_write" ON public.%I FOR ALL TO authenticated USING (public.is_admin(auth.uid())) WITH CHECK (public.is_admin(auth.uid()))', t, t);
      EXECUTE format('GRANT SELECT ON public.%I TO anon, authenticated', t);
      EXECUTE format('GRANT INSERT, UPDATE, DELETE ON public.%I TO authenticated', t);
    END IF;
  END LOOP;
END$$;

-- 2. HOMEPAGE / CMS ----------------------------------------------------------
DO $$
BEGIN
  IF to_regclass('public.homepage_sections') IS NOT NULL THEN
    EXECUTE 'ALTER TABLE public.homepage_sections ENABLE ROW LEVEL SECURITY';
    EXECUTE COALESCE((
      SELECT string_agg(format('DROP POLICY IF EXISTS %I ON public.homepage_sections;', polname), ' ')
      FROM pg_policies WHERE schemaname='public' AND tablename='homepage_sections'
    ), 'SELECT 1');
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='homepage_sections' AND column_name='published_content')
       AND EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='homepage_sections' AND column_name='visible') THEN
      EXECUTE 'CREATE POLICY "homepage_public_read" ON public.homepage_sections FOR SELECT TO anon, authenticated USING (visible = true AND published_content IS NOT NULL)';
    ELSE
      EXECUTE 'CREATE POLICY "homepage_public_read" ON public.homepage_sections FOR SELECT TO anon, authenticated USING (true)';
    END IF;
    EXECUTE 'CREATE POLICY "homepage_admin_all" ON public.homepage_sections FOR ALL TO authenticated USING (public.is_admin(auth.uid())) WITH CHECK (public.is_admin(auth.uid()))';
    EXECUTE 'GRANT SELECT ON public.homepage_sections TO anon, authenticated';
    EXECUTE 'GRANT INSERT, UPDATE, DELETE ON public.homepage_sections TO authenticated';
  END IF;
END$$;

DO $$
BEGIN
  IF to_regclass('public.site_settings') IS NOT NULL THEN
    EXECUTE 'ALTER TABLE public.site_settings ENABLE ROW LEVEL SECURITY';
    EXECUTE COALESCE((
      SELECT string_agg(format('DROP POLICY IF EXISTS %I ON public.site_settings;', polname), ' ')
      FROM pg_policies WHERE schemaname='public' AND tablename='site_settings'
    ), 'SELECT 1');
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='site_settings' AND column_name='published_value') THEN
      EXECUTE 'CREATE POLICY "site_settings_public_read" ON public.site_settings FOR SELECT TO anon, authenticated USING (published_value IS NOT NULL)';
    ELSE
      EXECUTE 'CREATE POLICY "site_settings_public_read" ON public.site_settings FOR SELECT TO anon, authenticated USING (true)';
    END IF;
    EXECUTE 'CREATE POLICY "site_settings_admin_all" ON public.site_settings FOR ALL TO authenticated USING (public.is_admin(auth.uid())) WITH CHECK (public.is_admin(auth.uid()))';
    EXECUTE 'GRANT SELECT ON public.site_settings TO anon, authenticated';
    EXECUTE 'GRANT INSERT, UPDATE, DELETE ON public.site_settings TO authenticated';
  END IF;
END$$;

DO $$
BEGIN
  IF to_regclass('public.site_page_sections') IS NOT NULL THEN
    EXECUTE 'ALTER TABLE public.site_page_sections ENABLE ROW LEVEL SECURITY';
    EXECUTE COALESCE((
      SELECT string_agg(format('DROP POLICY IF EXISTS %I ON public.site_page_sections;', polname), ' ')
      FROM pg_policies WHERE schemaname='public' AND tablename='site_page_sections'
    ), 'SELECT 1');
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='site_page_sections' AND column_name='status') THEN
      EXECUTE 'CREATE POLICY "page_sections_public_read" ON public.site_page_sections FOR SELECT TO anon, authenticated USING (status = ''published'')';
    ELSIF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='site_page_sections' AND column_name='published_content') THEN
      EXECUTE 'CREATE POLICY "page_sections_public_read" ON public.site_page_sections FOR SELECT TO anon, authenticated USING (published_content IS NOT NULL)';
    ELSE
      EXECUTE 'CREATE POLICY "page_sections_public_read" ON public.site_page_sections FOR SELECT TO anon, authenticated USING (true)';
    END IF;
    EXECUTE 'CREATE POLICY "page_sections_admin_all" ON public.site_page_sections FOR ALL TO authenticated USING (public.is_admin(auth.uid())) WITH CHECK (public.is_admin(auth.uid()))';
    EXECUTE 'GRANT SELECT ON public.site_page_sections TO anon, authenticated';
    EXECUTE 'GRANT INSERT, UPDATE, DELETE ON public.site_page_sections TO authenticated';
  END IF;
END$$;

-- 3. USER DATA: self + admin -------------------------------------------------
DO $$
DECLARE t text; uidcol text;
BEGIN
  FOR t, uidcol IN VALUES
    ('profiles','id'),
    ('user_login_events','user_id'),
    ('activity_events','user_id'),
    ('user_bans','user_id')
  LOOP
    IF to_regclass('public.'||t) IS NOT NULL
       AND EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name=t AND column_name=uidcol) THEN
      EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', t);
      EXECUTE COALESCE((
        SELECT string_agg(format('DROP POLICY IF EXISTS %I ON public.%I;', polname, t), ' ')
        FROM pg_policies WHERE schemaname='public' AND tablename=t
      ), 'SELECT 1');
      EXECUTE format(
        'CREATE POLICY "%s_self_read" ON public.%I FOR SELECT TO authenticated USING (%I = auth.uid() OR public.is_admin(auth.uid()))',
        t, t, uidcol
      );
      EXECUTE format(
        'CREATE POLICY "%s_admin_write" ON public.%I FOR ALL TO authenticated USING (public.is_admin(auth.uid())) WITH CHECK (public.is_admin(auth.uid()))',
        t, t
      );
      EXECUTE format('GRANT SELECT ON public.%I TO authenticated', t);
      EXECUTE format('GRANT INSERT, UPDATE, DELETE ON public.%I TO authenticated', t);
    END IF;
  END LOOP;
END$$;

DO $$
BEGIN
  IF to_regclass('public.profiles') IS NOT NULL THEN
    EXECUTE 'DROP POLICY IF EXISTS "profiles_self_update" ON public.profiles';
    EXECUTE 'CREATE POLICY "profiles_self_update" ON public.profiles FOR UPDATE TO authenticated USING (id = auth.uid()) WITH CHECK (id = auth.uid())';
  END IF;
END$$;

-- 4. LOGS: admin-only --------------------------------------------------------
DO $$
DECLARE t text;
BEGIN
  FOREACH t IN ARRAY ARRAY['system_error_logs','admin_action_log','audit_log'] LOOP
    IF to_regclass('public.'||t) IS NOT NULL THEN
      EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', t);
      EXECUTE COALESCE((
        SELECT string_agg(format('DROP POLICY IF EXISTS %I ON public.%I;', polname, t), ' ')
        FROM pg_policies WHERE schemaname='public' AND tablename=t
      ), 'SELECT 1');
      EXECUTE format('CREATE POLICY "%s_admin_only" ON public.%I FOR ALL TO authenticated USING (public.is_admin(auth.uid())) WITH CHECK (public.is_admin(auth.uid()))', t, t);
      EXECUTE format('REVOKE ALL ON public.%I FROM anon', t);
      EXECUTE format('GRANT SELECT, INSERT ON public.%I TO authenticated', t);
    END IF;
  END LOOP;
END$$;

-- 5. CATCH-ALL: any public table without RLS → enable + admin-only default ---
DO $$
DECLARE r record;
BEGIN
  FOR r IN
    SELECT c.relname
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname='public' AND c.relkind='r' AND c.relrowsecurity = false
  LOOP
    EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', r.relname);
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename=r.relname) THEN
      EXECUTE format('CREATE POLICY "%s_admin_only_default" ON public.%I FOR ALL TO authenticated USING (public.is_admin(auth.uid())) WITH CHECK (public.is_admin(auth.uid()))', r.relname, r.relname);
    END IF;
  END LOOP;
END$$;

-- 6. MISSING FOREIGN KEYS → auth.users ---------------------------------------
DO $$
DECLARE
  pairs text[][] := ARRAY[
    ARRAY['blog_posts','author_id'],
    ARRAY['activity_events','user_id'],
    ARRAY['exam_attempts','user_id'],
    ARRAY['quiz_sessions','user_id'],
    ARRAY['notifications','created_by']
  ];
  p text[]; tbl text; col text; fkname text;
BEGIN
  FOREACH p SLICE 1 IN ARRAY pairs LOOP
    tbl := p[1]; col := p[2];
    IF to_regclass('public.'||tbl) IS NOT NULL
       AND EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name=tbl AND column_name=col) THEN
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

-- 7. PERFORMANCE INDEXES -----------------------------------------------------
DO $$
BEGIN
  IF to_regclass('public.blog_posts') IS NOT NULL THEN
    CREATE INDEX IF NOT EXISTS idx_blog_posts_status_published_at ON public.blog_posts(status, published_at DESC);
  END IF;
  IF to_regclass('public.exam_attempts') IS NOT NULL THEN
    CREATE INDEX IF NOT EXISTS idx_exam_attempts_user_created ON public.exam_attempts(user_id, created_at DESC);
  END IF;
  IF to_regclass('public.activity_events') IS NOT NULL THEN
    CREATE INDEX IF NOT EXISTS idx_activity_events_user_created ON public.activity_events(user_id, created_at DESC);
  END IF;
  IF to_regclass('public.notifications') IS NOT NULL
     AND EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='notifications' AND column_name='status') THEN
    CREATE INDEX IF NOT EXISTS idx_notifications_user_status ON public.notifications(user_id, status);
  END IF;
END$$;

-- 8. ADMIN RPC SAFETY --------------------------------------------------------
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
    WHERE n.nspname='public' AND p.proname='admin_run_select_query'
  ) THEN
    EXECUTE 'REVOKE ALL ON FUNCTION public.admin_run_select_query(text) FROM PUBLIC, anon';
    EXECUTE 'GRANT EXECUTE ON FUNCTION public.admin_run_select_query(text) TO authenticated';
  END IF;
END$$;

-- =============================================================================
-- POST-RUN VERIFICATION QUERIES (run separately, read-only):
--
-- -- Tables still missing RLS:
-- SELECT c.relname FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
-- WHERE n.nspname='public' AND c.relkind='r' AND NOT c.relrowsecurity;
--
-- -- Anon-readable tables (verify only intended ones appear):
-- SELECT tablename FROM pg_policies
-- WHERE schemaname='public' AND 'anon'=ANY(roles) AND cmd='SELECT';
--
-- -- Per-table policy count:
-- SELECT tablename, count(*) FROM pg_policies WHERE schemaname='public'
-- GROUP BY tablename ORDER BY tablename;
-- =============================================================================
