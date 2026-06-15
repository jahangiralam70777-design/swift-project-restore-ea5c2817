-- =============================================================
-- Site Management Phase 0 — Security Hardening (additive, idempotent)
-- =============================================================
-- HOW TO APPLY: Open Lovable Cloud → SQL Editor and run this file once.
-- Safe to re-run.
--
-- Closes draft-leak risks surfaced by the discovery scan:
--   1. site_settings  — anon could SELECT draft_value
--   2. site_page_sections — anon could SELECT all rows (incl. drafts)
--   3. content_versions — authenticated could UPDATE/DELETE via GRANT
--   4. module_visibility — duplicate UPDATE policy
--   5. media_assets — least-privilege GRANT tightening
--   6. app_role enum drift — ensure all expected members exist
--
-- All public read paths already go through server fns using the
-- service-role client, so tightening RLS does NOT break public rendering.

-- ---------- 1. site_settings: only published rows readable to anon ----
DROP POLICY IF EXISTS "public reads site settings" ON public.site_settings;
DROP POLICY IF EXISTS "public reads published site settings" ON public.site_settings;
CREATE POLICY "public reads published site settings"
  ON public.site_settings
  FOR SELECT
  TO anon, authenticated
  USING (published_at IS NOT NULL);
-- admins keep full access via existing "admins manage site settings" policy.

-- ---------- 2. site_page_sections: only sections of published pages ----
DO $$
DECLARE pol record;
BEGIN
  FOR pol IN
    SELECT polname FROM pg_policy
    WHERE polrelid = 'public.site_page_sections'::regclass
      AND polcmd = 'r'  -- SELECT
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.site_page_sections', pol.polname);
  END LOOP;
END $$;
CREATE POLICY "public reads sections of published pages"
  ON public.site_page_sections
  FOR SELECT
  TO anon, authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.site_pages p
      WHERE p.id = site_page_sections.page_id
        AND p.status = 'published'
    )
    OR public.has_role(auth.uid(), 'admin')
  );

-- ---------- 3. content_versions: forbid UPDATE/DELETE via RLS ----------
DROP POLICY IF EXISTS "content_versions deny update" ON public.content_versions;
DROP POLICY IF EXISTS "content_versions deny delete" ON public.content_versions;
CREATE POLICY "content_versions deny update"
  ON public.content_versions FOR UPDATE TO authenticated
  USING (false) WITH CHECK (false);
CREATE POLICY "content_versions deny delete"
  ON public.content_versions FOR DELETE TO authenticated
  USING (false);
REVOKE UPDATE, DELETE ON public.content_versions FROM authenticated;

-- ---------- 4. module_visibility: drop duplicate admin write policy ----
DROP POLICY IF EXISTS "module_visibility admin write" ON public.module_visibility;

-- ---------- 5. media_assets: least-privilege GRANT ---------------------
REVOKE INSERT, UPDATE, DELETE ON public.media_assets FROM authenticated;
-- service_role (used by adminFinalizeMedia / adminDeleteMedia) is unaffected.

-- ---------- 6. app_role enum drift -------------------------------------
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_enum e JOIN pg_type t ON t.oid = e.enumtypid
                 WHERE t.typname = 'app_role' AND e.enumlabel = 'admin') THEN
    ALTER TYPE public.app_role ADD VALUE IF NOT EXISTS 'admin';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_enum e JOIN pg_type t ON t.oid = e.enumtypid
                 WHERE t.typname = 'app_role' AND e.enumlabel = 'moderator') THEN
    ALTER TYPE public.app_role ADD VALUE IF NOT EXISTS 'moderator';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_enum e JOIN pg_type t ON t.oid = e.enumtypid
                 WHERE t.typname = 'app_role' AND e.enumlabel = 'user') THEN
    ALTER TYPE public.app_role ADD VALUE IF NOT EXISTS 'user';
  END IF;
  -- 'student' is preserved if it exists; not added otherwise.
END $$;
