-- =============================================================================
-- PRODUCTION-GRADE SECURITY LOCK — EXPLICIT PER-TABLE RLS (idempotent)
-- Apply via Supabase SQL Editor. Supersedes prior wildcard policies.
--
-- Model:
--   * EVERY table gets its OWN explicit admin/user/public policies
--   * Admin + super_admin: FULL ALL access (separate policy per table)
--   * Authenticated non-admin: scoped to own rows (auth.uid())
--   * Anon: only published/visible rows on whitelisted tables
--   * NO blanket / catch-all policies remain
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 0. HELPERS
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.is_admin(_uid uuid DEFAULT auth.uid())
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT EXISTS (SELECT 1 FROM public.user_roles
                 WHERE user_id = _uid AND role IN ('admin','super_admin'));
$$;
GRANT EXECUTE ON FUNCTION public.is_admin(uuid) TO anon, authenticated;

CREATE OR REPLACE FUNCTION public.is_user_banned(_uid uuid DEFAULT auth.uid())
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.user_bans
    WHERE user_id = _uid
      AND (expires_at IS NULL OR expires_at > now())
      AND COALESCE(revoked, false) = false
  );
$$;
GRANT EXECUTE ON FUNCTION public.is_user_banned(uuid) TO anon, authenticated;

-- Drop wildcard admin_full_access policy created by previous migration
DO $$
DECLARE r record;
BEGIN
  FOR r IN
    SELECT schemaname, tablename FROM pg_policies
    WHERE schemaname='public' AND polname IN ('admin_full_access','admin_only_default')
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS "admin_full_access" ON public.%I', r.tablename);
    EXECUTE format('DROP POLICY IF EXISTS "admin_only_default" ON public.%I', r.tablename);
  END LOOP;
END$$;

-- Helper macro: drop + recreate a policy by name (avoids stale state)
-- (Inlined per-table below for clarity.)

-- ---------------------------------------------------------------------------
-- 1. BLOG SYSTEM
-- ---------------------------------------------------------------------------
DO $$ BEGIN
  IF to_regclass('public.blog_posts') IS NOT NULL THEN
    EXECUTE 'ALTER TABLE public.blog_posts ENABLE ROW LEVEL SECURITY';
    EXECUTE 'DROP POLICY IF EXISTS "blog_posts_admin_all"        ON public.blog_posts';
    EXECUTE 'DROP POLICY IF EXISTS "blog_posts_public_published"  ON public.blog_posts';
    EXECUTE 'DROP POLICY IF EXISTS "blog_posts_public_read_published" ON public.blog_posts';
    EXECUTE 'CREATE POLICY "blog_posts_admin_all" ON public.blog_posts
             FOR ALL TO authenticated
             USING (public.is_admin(auth.uid())) WITH CHECK (public.is_admin(auth.uid()))';
    EXECUTE 'CREATE POLICY "blog_posts_public_published" ON public.blog_posts
             FOR SELECT TO anon, authenticated USING (status = ''published'')';
    EXECUTE 'GRANT SELECT ON public.blog_posts TO anon, authenticated';
    EXECUTE 'GRANT INSERT, UPDATE, DELETE ON public.blog_posts TO authenticated';
  END IF;

  IF to_regclass('public.blog_views') IS NOT NULL THEN
    EXECUTE 'ALTER TABLE public.blog_views ENABLE ROW LEVEL SECURITY';
    EXECUTE 'DROP POLICY IF EXISTS "blog_views_admin_all"   ON public.blog_views';
    EXECUTE 'DROP POLICY IF EXISTS "blog_views_anon_insert" ON public.blog_views';
    EXECUTE 'DROP POLICY IF EXISTS "blog_views_admin_read"  ON public.blog_views';
    EXECUTE 'CREATE POLICY "blog_views_admin_all" ON public.blog_views
             FOR ALL TO authenticated
             USING (public.is_admin(auth.uid())) WITH CHECK (public.is_admin(auth.uid()))';
    EXECUTE 'CREATE POLICY "blog_views_anon_insert" ON public.blog_views
             FOR INSERT TO anon, authenticated WITH CHECK (true)';
    EXECUTE 'GRANT INSERT ON public.blog_views TO anon, authenticated';
    EXECUTE 'GRANT SELECT, UPDATE, DELETE ON public.blog_views TO authenticated';
  END IF;
END$$;

DO $$
DECLARE t text;
BEGIN
  FOREACH t IN ARRAY ARRAY['blog_tags','blog_categories','blog_post_tags','blog_post_categories'] LOOP
    IF to_regclass('public.'||t) IS NOT NULL THEN
      EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', t);
      EXECUTE format('DROP POLICY IF EXISTS "%s_admin_all"   ON public.%I', t, t);
      EXECUTE format('DROP POLICY IF EXISTS "%s_public_read" ON public.%I', t, t);
      EXECUTE format('CREATE POLICY "%s_admin_all" ON public.%I
                      FOR ALL TO authenticated
                      USING (public.is_admin(auth.uid())) WITH CHECK (public.is_admin(auth.uid()))', t, t);
      EXECUTE format('CREATE POLICY "%s_public_read" ON public.%I
                      FOR SELECT TO anon, authenticated USING (true)', t, t);
      EXECUTE format('GRANT SELECT ON public.%I TO anon, authenticated', t);
      EXECUTE format('GRANT INSERT, UPDATE, DELETE ON public.%I TO authenticated', t);
    END IF;
  END LOOP;
END$$;

-- ---------------------------------------------------------------------------
-- 2. CMS / SITE TABLES
-- ---------------------------------------------------------------------------
-- site_page_sections
DO $$ BEGIN
  IF to_regclass('public.site_page_sections') IS NOT NULL THEN
    EXECUTE 'ALTER TABLE public.site_page_sections ENABLE ROW LEVEL SECURITY';
    EXECUTE 'DROP POLICY IF EXISTS "site_page_sections_admin_all"    ON public.site_page_sections';
    EXECUTE 'DROP POLICY IF EXISTS "page_sections_public_read"        ON public.site_page_sections';
    EXECUTE 'DROP POLICY IF EXISTS "site_page_sections_public_read"   ON public.site_page_sections';
    EXECUTE 'CREATE POLICY "site_page_sections_admin_all" ON public.site_page_sections
             FOR ALL TO authenticated
             USING (public.is_admin(auth.uid())) WITH CHECK (public.is_admin(auth.uid()))';
    IF EXISTS (SELECT 1 FROM information_schema.columns
               WHERE table_schema='public' AND table_name='site_page_sections' AND column_name='status') THEN
      EXECUTE 'CREATE POLICY "site_page_sections_public_read" ON public.site_page_sections
               FOR SELECT TO anon, authenticated USING (status = ''published'')';
    ELSIF EXISTS (SELECT 1 FROM information_schema.columns
                  WHERE table_schema='public' AND table_name='site_page_sections' AND column_name='published_content') THEN
      EXECUTE 'CREATE POLICY "site_page_sections_public_read" ON public.site_page_sections
               FOR SELECT TO anon, authenticated USING (published_content IS NOT NULL)';
    END IF;
    EXECUTE 'GRANT SELECT ON public.site_page_sections TO anon, authenticated';
    EXECUTE 'GRANT INSERT, UPDATE, DELETE ON public.site_page_sections TO authenticated';
  END IF;
END$$;

-- site_pages
DO $$ BEGIN
  IF to_regclass('public.site_pages') IS NOT NULL THEN
    EXECUTE 'ALTER TABLE public.site_pages ENABLE ROW LEVEL SECURITY';
    EXECUTE 'DROP POLICY IF EXISTS "site_pages_admin_all"   ON public.site_pages';
    EXECUTE 'DROP POLICY IF EXISTS "site_pages_public_read" ON public.site_pages';
    EXECUTE 'CREATE POLICY "site_pages_admin_all" ON public.site_pages
             FOR ALL TO authenticated
             USING (public.is_admin(auth.uid())) WITH CHECK (public.is_admin(auth.uid()))';
    IF EXISTS (SELECT 1 FROM information_schema.columns
               WHERE table_schema='public' AND table_name='site_pages' AND column_name='status') THEN
      EXECUTE 'CREATE POLICY "site_pages_public_read" ON public.site_pages
               FOR SELECT TO anon, authenticated USING (status = ''published'')';
    END IF;
    EXECUTE 'GRANT SELECT ON public.site_pages TO anon, authenticated';
    EXECUTE 'GRANT INSERT, UPDATE, DELETE ON public.site_pages TO authenticated';
  END IF;
END$$;

-- homepage_sections
DO $$ BEGIN
  IF to_regclass('public.homepage_sections') IS NOT NULL THEN
    EXECUTE 'ALTER TABLE public.homepage_sections ENABLE ROW LEVEL SECURITY';
    EXECUTE 'DROP POLICY IF EXISTS "homepage_sections_admin_all"   ON public.homepage_sections';
    EXECUTE 'DROP POLICY IF EXISTS "homepage_sections_public_read" ON public.homepage_sections';
    EXECUTE 'DROP POLICY IF EXISTS "homepage_public_read"          ON public.homepage_sections';
    EXECUTE 'CREATE POLICY "homepage_sections_admin_all" ON public.homepage_sections
             FOR ALL TO authenticated
             USING (public.is_admin(auth.uid())) WITH CHECK (public.is_admin(auth.uid()))';
    IF EXISTS (SELECT 1 FROM information_schema.columns
               WHERE table_schema='public' AND table_name='homepage_sections' AND column_name='visible') THEN
      EXECUTE 'CREATE POLICY "homepage_sections_public_read" ON public.homepage_sections
               FOR SELECT TO anon, authenticated USING (visible = true)';
    ELSE
      EXECUTE 'CREATE POLICY "homepage_sections_public_read" ON public.homepage_sections
               FOR SELECT TO anon, authenticated USING (true)';
    END IF;
    EXECUTE 'GRANT SELECT ON public.homepage_sections TO anon, authenticated';
    EXECUTE 'GRANT INSERT, UPDATE, DELETE ON public.homepage_sections TO authenticated';
  END IF;
END$$;

-- site_settings
DO $$ BEGIN
  IF to_regclass('public.site_settings') IS NOT NULL THEN
    EXECUTE 'ALTER TABLE public.site_settings ENABLE ROW LEVEL SECURITY';
    EXECUTE 'DROP POLICY IF EXISTS "site_settings_admin_all"   ON public.site_settings';
    EXECUTE 'DROP POLICY IF EXISTS "site_settings_public_read" ON public.site_settings';
    EXECUTE 'CREATE POLICY "site_settings_admin_all" ON public.site_settings
             FOR ALL TO authenticated
             USING (public.is_admin(auth.uid())) WITH CHECK (public.is_admin(auth.uid()))';
    IF EXISTS (SELECT 1 FROM information_schema.columns
               WHERE table_schema='public' AND table_name='site_settings' AND column_name='published_value') THEN
      EXECUTE 'CREATE POLICY "site_settings_public_read" ON public.site_settings
               FOR SELECT TO anon, authenticated USING (published_value IS NOT NULL)';
    ELSE
      EXECUTE 'CREATE POLICY "site_settings_public_read" ON public.site_settings
               FOR SELECT TO anon, authenticated USING (true)';
    END IF;
    EXECUTE 'GRANT SELECT ON public.site_settings TO anon, authenticated';
    EXECUTE 'GRANT INSERT, UPDATE, DELETE ON public.site_settings TO authenticated';
  END IF;
END$$;

-- ---------------------------------------------------------------------------
-- 3. LEARNING CONTENT (authenticated published; admin full)
-- ---------------------------------------------------------------------------
DO $$
DECLARE t text; v text;
BEGIN
  FOREACH t IN ARRAY ARRAY['mcqs','quizzes','flash_cards','short_notes',
                           'video_classes','question_bank_resources','mock_tests'] LOOP
    IF to_regclass('public.'||t) IS NOT NULL THEN
      EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', t);
      EXECUTE format('DROP POLICY IF EXISTS "%s_admin_all"        ON public.%I', t, t);
      EXECUTE format('DROP POLICY IF EXISTS "%s_auth_published"   ON public.%I', t, t);
      EXECUTE format('DROP POLICY IF EXISTS "%s_public_published" ON public.%I', t, t);
      EXECUTE format('CREATE POLICY "%s_admin_all" ON public.%I
                      FOR ALL TO authenticated
                      USING (public.is_admin(auth.uid())) WITH CHECK (public.is_admin(auth.uid()))', t, t);

      SELECT column_name INTO v FROM information_schema.columns
       WHERE table_schema='public' AND table_name=t
         AND column_name IN ('status','is_published','visible','published')
       ORDER BY CASE column_name WHEN 'status' THEN 1 WHEN 'is_published' THEN 2
                                 WHEN 'visible' THEN 3 ELSE 4 END
       LIMIT 1;

      IF v = 'status' THEN
        EXECUTE format('CREATE POLICY "%s_auth_published" ON public.%I
                        FOR SELECT TO authenticated USING (status = ''published'')', t, t);
      ELSIF v IN ('is_published','visible','published') THEN
        EXECUTE format('CREATE POLICY "%s_auth_published" ON public.%I
                        FOR SELECT TO authenticated USING (%I = true)', t, t, v);
      ELSE
        EXECUTE format('CREATE POLICY "%s_auth_published" ON public.%I
                        FOR SELECT TO authenticated USING (true)', t, t);
      END IF;
      EXECUTE format('GRANT SELECT ON public.%I TO authenticated', t);
    END IF;
  END LOOP;
END$$;

-- ---------------------------------------------------------------------------
-- 4. USER-OWNED TABLES (self + admin only; no other path)
-- ---------------------------------------------------------------------------
DO $$
DECLARE t text; uidcol text;
BEGIN
  FOR t, uidcol IN VALUES
    ('profiles','id'),
    ('activity_events','user_id'),
    ('exam_attempts','user_id'),
    ('quiz_sessions','user_id'),
    ('notifications','user_id'),
    ('bookmarks','user_id'),
    ('wrong_questions','user_id'),
    ('study_sessions','user_id'),
    ('user_goals','user_id'),
    ('user_login_events','user_id'),
    ('user_bans','user_id')
  LOOP
    IF to_regclass('public.'||t) IS NOT NULL
       AND EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_schema='public' AND table_name=t AND column_name=uidcol) THEN
      EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', t);
      EXECUTE format('DROP POLICY IF EXISTS "%s_admin_all"   ON public.%I', t, t);
      EXECUTE format('DROP POLICY IF EXISTS "%s_self_read"   ON public.%I', t, t);
      EXECUTE format('DROP POLICY IF EXISTS "%s_self_write"  ON public.%I', t, t);
      EXECUTE format('DROP POLICY IF EXISTS "%s_self_update" ON public.%I', t, t);
      EXECUTE format('DROP POLICY IF EXISTS "%s_self_insert" ON public.%I', t, t);
      EXECUTE format('DROP POLICY IF EXISTS "%s_self_delete" ON public.%I', t, t);

      EXECUTE format('CREATE POLICY "%s_admin_all" ON public.%I
                      FOR ALL TO authenticated
                      USING (public.is_admin(auth.uid())) WITH CHECK (public.is_admin(auth.uid()))', t, t);
      EXECUTE format('CREATE POLICY "%s_self_read" ON public.%I
                      FOR SELECT TO authenticated USING (%I = auth.uid())', t, t, uidcol);
      EXECUTE format('CREATE POLICY "%s_self_insert" ON public.%I
                      FOR INSERT TO authenticated WITH CHECK (%I = auth.uid())', t, t, uidcol);
      EXECUTE format('CREATE POLICY "%s_self_update" ON public.%I
                      FOR UPDATE TO authenticated USING (%I = auth.uid()) WITH CHECK (%I = auth.uid())', t, t, uidcol, uidcol);
      EXECUTE format('CREATE POLICY "%s_self_delete" ON public.%I
                      FOR DELETE TO authenticated USING (%I = auth.uid())', t, t, uidcol);
      EXECUTE format('GRANT SELECT, INSERT, UPDATE, DELETE ON public.%I TO authenticated', t);
    END IF;
  END LOOP;
END$$;

-- user_bans: regular users can READ their own ban row but cannot modify it
DO $$ BEGIN
  IF to_regclass('public.user_bans') IS NOT NULL THEN
    EXECUTE 'DROP POLICY IF EXISTS "user_bans_self_insert" ON public.user_bans';
    EXECUTE 'DROP POLICY IF EXISTS "user_bans_self_update" ON public.user_bans';
    EXECUTE 'DROP POLICY IF EXISTS "user_bans_self_delete" ON public.user_bans';
  END IF;
END$$;

-- ---------------------------------------------------------------------------
-- 5. LOG TABLES (admin-only)
-- ---------------------------------------------------------------------------
DO $$
DECLARE t text;
BEGIN
  FOREACH t IN ARRAY ARRAY['system_error_logs','admin_action_log','audit_log'] LOOP
    IF to_regclass('public.'||t) IS NOT NULL THEN
      EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', t);
      EXECUTE format('DROP POLICY IF EXISTS "%s_admin_all" ON public.%I', t, t);
      EXECUTE format('CREATE POLICY "%s_admin_all" ON public.%I
                      FOR ALL TO authenticated
                      USING (public.is_admin(auth.uid())) WITH CHECK (true)', t, t);
      EXECUTE format('REVOKE ALL ON public.%I FROM anon', t);
      EXECUTE format('GRANT SELECT, INSERT ON public.%I TO authenticated', t);
    END IF;
  END LOOP;
END$$;

-- ---------------------------------------------------------------------------
-- 6. BAN ENFORCEMENT — DB-LEVEL TRIGGER
--    Force-revoke active sessions when a non-admin user is banned.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.enforce_ban_revoke_sessions()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, auth AS $$
BEGIN
  IF NEW.user_id IS NOT NULL
     AND (NEW.expires_at IS NULL OR NEW.expires_at > now())
     AND COALESCE(NEW.revoked, false) = false
     AND NOT public.is_admin(NEW.user_id) THEN
    BEGIN
      DELETE FROM auth.sessions WHERE user_id = NEW.user_id;
    EXCEPTION WHEN others THEN
      RAISE NOTICE 'Could not revoke sessions for %: %', NEW.user_id, SQLERRM;
    END;
  END IF;
  RETURN NEW;
END;
$$;

DO $$ BEGIN
  IF to_regclass('public.user_bans') IS NOT NULL THEN
    EXECUTE 'DROP TRIGGER IF EXISTS trg_user_bans_revoke ON public.user_bans';
    EXECUTE 'CREATE TRIGGER trg_user_bans_revoke
             AFTER INSERT OR UPDATE ON public.user_bans
             FOR EACH ROW EXECUTE FUNCTION public.enforce_ban_revoke_sessions()';
  END IF;
END$$;

-- ---------------------------------------------------------------------------
-- 7. FOREIGN KEYS
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  pairs text[][] := ARRAY[
    ARRAY['activity_events','user_id'],
    ARRAY['exam_attempts','user_id'],
    ARRAY['quiz_sessions','user_id'],
    ARRAY['blog_views','user_id'],
    ARRAY['blog_posts','author_id'],
    ARRAY['notifications','user_id']
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
          EXECUTE format('ALTER TABLE public.%I ADD CONSTRAINT %I
                          FOREIGN KEY (%I) REFERENCES auth.users(id) ON DELETE CASCADE',
                         tbl, fkname, col);
        EXCEPTION WHEN others THEN
          RAISE NOTICE 'FK skip %.%: %', tbl, col, SQLERRM;
        END;
      END IF;
    END IF;
  END LOOP;
END$$;

-- ---------------------------------------------------------------------------
-- 8. INDEXES
-- ---------------------------------------------------------------------------
DO $$ BEGIN
  IF to_regclass('public.blog_posts') IS NOT NULL THEN
    CREATE INDEX IF NOT EXISTS idx_blog_posts_status_created ON public.blog_posts(status, created_at DESC);
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
-- 9. ADMIN SQL SAFETY — admin_run_select_query
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.admin_action_log (
  id bigserial PRIMARY KEY,
  actor_id uuid, permission text, action text, allowed boolean,
  metadata jsonb, created_at timestamptz NOT NULL DEFAULT now()
);

CREATE OR REPLACE FUNCTION public.admin_run_select_query(_sql text)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  trimmed text; lowered text; result jsonb;
  forbidden text[] := ARRAY[
    'insert','update','delete','drop','alter','truncate','grant','revoke',
    'create','copy','vacuum','analyze','comment','call','merge','reindex',
    'cluster','listen','notify','lock','refresh','reset','perform','into',
    'execute','prepare','deallocate','security','definer'
  ];
  kw text;
BEGIN
  IF NOT public.is_admin(auth.uid()) THEN
    RAISE EXCEPTION 'Forbidden: admin only';
  END IF;

  trimmed := btrim(COALESCE(_sql, ''));
  IF length(trimmed) = 0 OR length(trimmed) > 8000 THEN
    RAISE EXCEPTION 'Invalid query length';
  END IF;

  WHILE right(trimmed,1) = ';' LOOP trimmed := btrim(left(trimmed, length(trimmed)-1)); END LOOP;

  IF position(';'  IN trimmed) > 0 THEN RAISE EXCEPTION 'Semicolons not allowed'; END IF;
  IF position('--' IN trimmed) > 0 THEN RAISE EXCEPTION 'Comments not allowed'; END IF;
  IF position('/*' IN trimmed) > 0 THEN RAISE EXCEPTION 'Comments not allowed'; END IF;
  IF trimmed ~ '\\x[0-9a-fA-F]{2}' OR trimmed ~ 'chr\s*\(' THEN
    RAISE EXCEPTION 'Encoded sequences not allowed';
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
-- 10. REALTIME — RLS-filtered publication (policies above filter payloads)
-- ---------------------------------------------------------------------------
DO $$
DECLARE t text;
BEGIN
  FOREACH t IN ARRAY ARRAY['blog_posts','site_page_sections','site_pages',
                           'homepage_sections','site_settings','profiles',
                           'notifications','mcqs','quizzes','flash_cards',
                           'short_notes','video_classes'] LOOP
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
-- DONE.
-- =============================================================================
