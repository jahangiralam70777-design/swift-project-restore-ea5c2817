-- ============================================================
-- COMPLETE SUPABASE PRODUCTION MIGRATION (strict dependency order)
-- Order: extensions -> enums -> tables -> functions -> triggers ->
--        views -> indexes -> policies -> grants -> publications.
-- All statements are idempotent (IF NOT EXISTS / OR REPLACE /
-- catalog-guarded DO blocks) so this runs cleanly on a fresh OR
-- partially-existing database.
-- ============================================================


-- =================== 1. EXTENSIONS ===================

-- ============================================================
-- SAFE INCREMENTAL SUPABASE PRODUCTION MIGRATION
-- Generated for dirty/partial and fresh databases.
-- No seed/demo data. No ownership changes. No pg_dump output.
-- Safety rules used throughout:
--   * CREATE TABLE IF NOT EXISTS
--   * CREATE INDEX IF NOT EXISTS
--   * CREATE OR REPLACE FUNCTION
--   * enum labels added with ALTER TYPE ... ADD VALUE IF NOT EXISTS
--   * policies/triggers/publication additions guarded by catalog checks
--   * missing columns repaired with ALTER TABLE ... ADD COLUMN IF NOT EXISTS
-- ============================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE EXTENSION IF NOT EXISTS pg_trgm;


-- =================== 2. SESSION SETTINGS ============

-- ============================================================
-- EARLY BOOTSTRAP: enum + user_roles + has_role MUST exist before
-- ANY policy below references public.has_role(uuid, app_role).
-- Idempotent and safe on fresh or partially-existing databases.
-- ============================================================
SET search_path = public, pg_catalog;

-- ------------------------------------------------------------
-- Migration: 20260608040610_0e0e1095-58d6-43f6-83c1-c38dbb706b43.sql
-- ------------------------------------------------------------

SET search_path = public;


-- =================== 3. TYPES / ENUMS ===============

DO $bootstrap_role_enum$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type t JOIN pg_namespace n ON n.oid = t.typnamespace
                 WHERE n.nspname = 'public' AND t.typname = 'app_role') THEN
    CREATE TYPE public.app_role AS ENUM ('admin','moderator','user');
  END IF;
END $bootstrap_role_enum$;

DO $bootstrap_role_labels$
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
END $bootstrap_role_labels$;

-- ============================================================
-- END EARLY BOOTSTRAP
-- ============================================================

-- ------------------------------------------------------------
-- Migration: 20260606134520_c342f042-a41c-465a-9603-3aadc9edf688.sql
-- ------------------------------------------------------------
-- Roles infra
DO $$ BEGIN
  CREATE TYPE public.app_role AS ENUM ('admin','moderator','user');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- ------------------------------------------------------------
-- Migration: 20260606134807_77cbbc3a-1f05-4c46-b7ee-bf91e16badc0.sql
-- ------------------------------------------------------------
do $$ begin
  create type public.content_status as enum ('draft','published','archived');
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.difficulty_level as enum ('easy','medium','hard');
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.mcq_option as enum ('A','B','C','D');
exception when duplicate_object then null; end $$;

-- ------------------------------------------------------------
-- Migration: 20260606134923_3b67396f-abe1-4144-9360-655613ffa29d.sql
-- ------------------------------------------------------------
ALTER TYPE public.app_role ADD VALUE IF NOT EXISTS 'student';

-- ------------------------------------------------------------
-- Migration: 20260606151151_783c1a42-0597-4ef3-949a-25a3bebd6fef.sql
-- ------------------------------------------------------------
-- Roles infra
DO $$ BEGIN
  CREATE TYPE public.app_role AS ENUM ('admin','moderator','user');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- ------------------------------------------------------------
-- Migration: 20260606151335_36b946dc-769c-4dc9-8fcf-357342dac23c.sql
-- ------------------------------------------------------------
do $$ begin
  create type public.content_status as enum ('draft','published','archived');
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.difficulty_level as enum ('easy','medium','hard');
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.mcq_option as enum ('A','B','C','D');
exception when duplicate_object then null; end $$;

-- ------------------------------------------------------------
-- Migration: 20260606151454_a7c5bc5d-db2a-4da7-bb62-64381f558e9b.sql
-- ------------------------------------------------------------
ALTER TYPE public.app_role ADD VALUE IF NOT EXISTS 'student';

-- ------------------------------------------------------------
-- Migration: 20260606180547_52760eac-79c1-4b53-b985-8c0cb3a49e91.sql
-- ------------------------------------------------------------
-- Roles infra
DO $$ BEGIN
  CREATE TYPE public.app_role AS ENUM ('admin','moderator','user');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- ------------------------------------------------------------
-- Migration: 20260606180751_de28e5b1-e55d-433a-8dc6-f27b6e8b2bfd.sql
-- ------------------------------------------------------------
do $$ begin
  create type public.content_status as enum ('draft','published','archived');
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.difficulty_level as enum ('easy','medium','hard');
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.mcq_option as enum ('A','B','C','D');
exception when duplicate_object then null; end $$;

-- ------------------------------------------------------------
-- Migration: 20260606181535_71559e22-40ea-4663-a6ce-5d5bee879c44.sql
-- ------------------------------------------------------------
ALTER TYPE public.app_role ADD VALUE IF NOT EXISTS 'student';

-- ------------------------------------------------------------
-- Migration: 20260607143112_8d5d567b-60bc-45da-9d34-0429d23a9013.sql
-- ------------------------------------------------------------
-- Roles infra
DO $$ BEGIN
  CREATE TYPE public.app_role AS ENUM ('admin','moderator','user');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- ------------------------------------------------------------
-- Migration: 20260607143300_49b7215e-4290-4c18-98cf-a9e3b7a99d51.sql
-- ------------------------------------------------------------
do $$ begin
  create type public.content_status as enum ('draft','published','archived');
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.difficulty_level as enum ('easy','medium','hard');
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.mcq_option as enum ('A','B','C','D');
exception when duplicate_object then null; end $$;

-- ------------------------------------------------------------
-- Migration: 20260607143412_7444ad82-d974-488c-a53e-5fb3b62a7a81.sql
-- ------------------------------------------------------------
ALTER TYPE public.app_role ADD VALUE IF NOT EXISTS 'student';

-- ------------------------------------------------------------
-- Migration: 20260607185209_fc27a0c6-f5eb-4999-8e52-3d1d8a9c4e79.sql
-- ------------------------------------------------------------

-- ============================================================
-- ENUMS
-- ============================================================
DO $$ BEGIN
  CREATE TYPE public.app_role AS ENUM ('admin','moderator','student','teacher','user');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

ALTER TYPE public.app_role ADD VALUE IF NOT EXISTS 'admin';

ALTER TYPE public.app_role ADD VALUE IF NOT EXISTS 'moderator';

ALTER TYPE public.app_role ADD VALUE IF NOT EXISTS 'student';

ALTER TYPE public.app_role ADD VALUE IF NOT EXISTS 'teacher';

ALTER TYPE public.app_role ADD VALUE IF NOT EXISTS 'user';

DO $$ BEGIN
  CREATE TYPE public.content_status AS ENUM ('draft', 'published', 'archived');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

ALTER TYPE public.content_status ADD VALUE IF NOT EXISTS 'draft';

ALTER TYPE public.content_status ADD VALUE IF NOT EXISTS 'published';

ALTER TYPE public.content_status ADD VALUE IF NOT EXISTS 'archived';

DO $$ BEGIN
  CREATE TYPE public.difficulty AS ENUM ('easy', 'medium', 'hard');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

ALTER TYPE public.difficulty ADD VALUE IF NOT EXISTS 'easy';

ALTER TYPE public.difficulty ADD VALUE IF NOT EXISTS 'medium';

ALTER TYPE public.difficulty ADD VALUE IF NOT EXISTS 'hard';

DO $$ BEGIN
  CREATE TYPE public.mcq_option AS ENUM ('A', 'B', 'C', 'D');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

ALTER TYPE public.mcq_option ADD VALUE IF NOT EXISTS 'A';

ALTER TYPE public.mcq_option ADD VALUE IF NOT EXISTS 'B';

ALTER TYPE public.mcq_option ADD VALUE IF NOT EXISTS 'C';

ALTER TYPE public.mcq_option ADD VALUE IF NOT EXISTS 'D';

DO $$ BEGIN
  CREATE TYPE public.question_type AS ENUM ('mcq', 'true_false');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

ALTER TYPE public.question_type ADD VALUE IF NOT EXISTS 'mcq';

ALTER TYPE public.question_type ADD VALUE IF NOT EXISTS 'true_false';

DO $$ BEGIN
  CREATE TYPE public.quiz_kind AS ENUM ('quiz', 'mock');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

ALTER TYPE public.quiz_kind ADD VALUE IF NOT EXISTS 'quiz';

ALTER TYPE public.quiz_kind ADD VALUE IF NOT EXISTS 'mock';

DO $$ BEGIN
  CREATE TYPE public.profile_status AS ENUM ('active', 'suspended', 'pending');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

ALTER TYPE public.profile_status ADD VALUE IF NOT EXISTS 'active';

ALTER TYPE public.profile_status ADD VALUE IF NOT EXISTS 'suspended';

ALTER TYPE public.profile_status ADD VALUE IF NOT EXISTS 'pending';

DO $$ BEGIN
  CREATE TYPE public.notification_type AS ENUM ('announcement', 'push', 'email', 'in_app');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

ALTER TYPE public.notification_type ADD VALUE IF NOT EXISTS 'announcement';

ALTER TYPE public.notification_type ADD VALUE IF NOT EXISTS 'push';

ALTER TYPE public.notification_type ADD VALUE IF NOT EXISTS 'email';

ALTER TYPE public.notification_type ADD VALUE IF NOT EXISTS 'in_app';

DO $$ BEGIN
  CREATE TYPE public.notification_priority AS ENUM ('low', 'medium', 'high', 'critical');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

ALTER TYPE public.notification_priority ADD VALUE IF NOT EXISTS 'low';

ALTER TYPE public.notification_priority ADD VALUE IF NOT EXISTS 'medium';

ALTER TYPE public.notification_priority ADD VALUE IF NOT EXISTS 'high';

ALTER TYPE public.notification_priority ADD VALUE IF NOT EXISTS 'critical';

DO $$ BEGIN
  CREATE TYPE public.notification_status AS ENUM ('draft', 'scheduled', 'sent', 'failed', 'paused');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

ALTER TYPE public.notification_status ADD VALUE IF NOT EXISTS 'draft';

ALTER TYPE public.notification_status ADD VALUE IF NOT EXISTS 'scheduled';

ALTER TYPE public.notification_status ADD VALUE IF NOT EXISTS 'sent';

ALTER TYPE public.notification_status ADD VALUE IF NOT EXISTS 'failed';

ALTER TYPE public.notification_status ADD VALUE IF NOT EXISTS 'paused';

DO $$ BEGIN
  CREATE TYPE public.notification_audience AS ENUM ('all', 'level', 'subject', 'role', 'users');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

ALTER TYPE public.notification_audience ADD VALUE IF NOT EXISTS 'all';

ALTER TYPE public.notification_audience ADD VALUE IF NOT EXISTS 'level';

ALTER TYPE public.notification_audience ADD VALUE IF NOT EXISTS 'subject';

ALTER TYPE public.notification_audience ADD VALUE IF NOT EXISTS 'role';

ALTER TYPE public.notification_audience ADD VALUE IF NOT EXISTS 'users';

DO $$ BEGIN
  CREATE TYPE public.card_type AS ENUM ('concept', 'formula', 'diagram', 'timeline', 'definition', 'other');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

ALTER TYPE public.card_type ADD VALUE IF NOT EXISTS 'concept';

ALTER TYPE public.card_type ADD VALUE IF NOT EXISTS 'formula';

ALTER TYPE public.card_type ADD VALUE IF NOT EXISTS 'diagram';

ALTER TYPE public.card_type ADD VALUE IF NOT EXISTS 'timeline';

ALTER TYPE public.card_type ADD VALUE IF NOT EXISTS 'definition';

ALTER TYPE public.card_type ADD VALUE IF NOT EXISTS 'other';

DO $$ BEGIN
  CREATE TYPE public.note_kind AS ENUM ('text', 'pdf', 'doc');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

ALTER TYPE public.note_kind ADD VALUE IF NOT EXISTS 'text';

ALTER TYPE public.note_kind ADD VALUE IF NOT EXISTS 'pdf';

ALTER TYPE public.note_kind ADD VALUE IF NOT EXISTS 'doc';

DO $$ BEGIN
  CREATE TYPE public.qb_resource_type AS ENUM ('important', 'pyq', 'model', 'notes', 'text');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

ALTER TYPE public.qb_resource_type ADD VALUE IF NOT EXISTS 'important';

ALTER TYPE public.qb_resource_type ADD VALUE IF NOT EXISTS 'pyq';

ALTER TYPE public.qb_resource_type ADD VALUE IF NOT EXISTS 'model';

ALTER TYPE public.qb_resource_type ADD VALUE IF NOT EXISTS 'notes';

ALTER TYPE public.qb_resource_type ADD VALUE IF NOT EXISTS 'text';

DO $$ BEGIN
  CREATE TYPE public.video_kind AS ENUM ('youtube', 'playlist', 'upload');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

ALTER TYPE public.video_kind ADD VALUE IF NOT EXISTS 'youtube';

ALTER TYPE public.video_kind ADD VALUE IF NOT EXISTS 'playlist';

ALTER TYPE public.video_kind ADD VALUE IF NOT EXISTS 'upload';

DO $$ BEGIN
  CREATE TYPE public.attempt_status AS ENUM ('in_progress', 'completed', 'abandoned');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

ALTER TYPE public.attempt_status ADD VALUE IF NOT EXISTS 'in_progress';

ALTER TYPE public.attempt_status ADD VALUE IF NOT EXISTS 'completed';

ALTER TYPE public.attempt_status ADD VALUE IF NOT EXISTS 'abandoned';

DO $$ BEGIN
  CREATE TYPE public.attempt_kind AS ENUM ('practice', 'quiz', 'mock');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

ALTER TYPE public.attempt_kind ADD VALUE IF NOT EXISTS 'practice';

ALTER TYPE public.attempt_kind ADD VALUE IF NOT EXISTS 'quiz';

ALTER TYPE public.attempt_kind ADD VALUE IF NOT EXISTS 'mock';

-- ------------------------------------------------------------
-- Migration: 20260607185312_aa42e662-b3f7-458b-9f82-dcc9bc24a85f.sql
-- ------------------------------------------------------------

-- Enum additions
ALTER TYPE public.attempt_kind ADD VALUE IF NOT EXISTS 'mcq_practice';

ALTER TYPE public.attempt_kind ADD VALUE IF NOT EXISTS 'custom_exam';

ALTER TYPE public.app_role ADD VALUE IF NOT EXISTS 'user';

-- ------------------------------------------------------------
-- Migration: 20260608041742_4f399ef0-b01b-481d-9934-a1124c00d4de.sql
-- ------------------------------------------------------------
-- Roles infra
DO $$ BEGIN
  CREATE TYPE public.app_role AS ENUM ('admin','moderator','user');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- ------------------------------------------------------------
-- Migration: 20260608041915_f7aeafb0-4618-49d2-878c-f6ca63b7c352.sql
-- ------------------------------------------------------------
do $$ begin
  create type public.content_status as enum ('draft','published','archived');
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.difficulty_level as enum ('easy','medium','hard');
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.mcq_option as enum ('A','B','C','D');
exception when duplicate_object then null; end $$;

-- ------------------------------------------------------------
-- Migration: 20260608042024_500f817a-ea21-4642-8b38-8e0016cfe870.sql
-- ------------------------------------------------------------
ALTER TYPE public.app_role ADD VALUE IF NOT EXISTS 'student';

-- ------------------------------------------------------------
-- Migration: 20260608173747_b2f810b5-55fb-48a2-a6d0-72cc6e87d3dd.sql
-- ------------------------------------------------------------
ALTER TYPE public.app_role ADD VALUE IF NOT EXISTS 'super_admin';

-- ------------------------------------------------------------
-- Migration: 20260609034532_b6f71cc1-380d-466b-8eff-33283b5bf4ef.sql
-- ------------------------------------------------------------

-- =====================================================
-- Phase-3 Editor Engine — Production Integration Layer
-- Isolated from Phase-1; uses its own tables.
-- =====================================================

-- Role enum + user_roles guard (idempotent — Phase-1 may already define these)
DO $$ BEGIN
  CREATE TYPE public.app_role AS ENUM ('admin', 'moderator', 'user');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;


-- =================== 4. TABLES ======================

CREATE TABLE IF NOT EXISTS public.user_roles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role public.app_role NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id, role)
);

ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.user_roles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role public.app_role NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id, role)
);

ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.homepage_sections (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  section_key text NOT NULL UNIQUE,
  position int NOT NULL DEFAULT 0,
  visible boolean NOT NULL DEFAULT true,
  draft_content jsonb NOT NULL DEFAULT '{}'::jsonb,
  published_content jsonb NOT NULL DEFAULT '{}'::jsonb,
  published_at timestamptz,
  updated_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.homepage_sections ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.site_settings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  key text NOT NULL UNIQUE,
  draft_value jsonb NOT NULL DEFAULT '{}'::jsonb,
  published_value jsonb NOT NULL DEFAULT '{}'::jsonb,
  published_at timestamptz,
  updated_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.site_settings ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.module_visibility (
  key text PRIMARY KEY,
  label text NOT NULL,
  hidden boolean NOT NULL DEFAULT false,
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.module_visibility ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.content_versions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  target_kind text NOT NULL CHECK (target_kind IN ('section','setting')),
  target_key text NOT NULL,
  snapshot jsonb NOT NULL DEFAULT '{}'::jsonb,
  label text,
  created_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.content_versions ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.media_assets (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  bucket text NOT NULL,
  path text NOT NULL,
  file_name text NOT NULL,
  mime_type text NOT NULL,
  size_bytes bigint NOT NULL DEFAULT 0,
  width int,
  height int,
  alt_text text,
  tags text[] NOT NULL DEFAULT '{}',
  uploaded_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.media_assets ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.user_sessions (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  active_session_id TEXT NOT NULL,
  user_agent TEXT,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.user_sessions ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.user_sessions REPLICA IDENTITY FULL;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text, avatar_url text, bio text, level text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

create table if not exists public.avatars (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  storage_path text not null, public_url text,
  created_at timestamptz not null default now()
);

alter table public.avatars enable row level security;

create table if not exists public.levels (
  code text primary key, name text not null, description text, color text, icon text,
  sort_order integer not null default 0,
  status public.content_status not null default 'published',
  updated_at timestamptz not null default now()
);

alter table public.levels enable row level security;

create table if not exists public.subjects (
  id uuid primary key default gen_random_uuid(),
  name text not null, slug text not null unique,
  level text not null references public.levels(code) on delete restrict,
  description text, color text, icon text,
  sort_order integer not null default 0,
  status public.content_status not null default 'published',
  updated_at timestamptz not null default now()
);

alter table public.subjects enable row level security;

create table if not exists public.chapters (
  id uuid primary key default gen_random_uuid(),
  subject_id uuid not null references public.subjects(id) on delete cascade,
  name text not null, slug text not null, description text,
  sort_order integer not null default 0,
  status public.content_status not null default 'published',
  updated_at timestamptz not null default now(),
  unique (subject_id, slug)
);

alter table public.chapters enable row level security;

create table if not exists public.mcqs (
  id uuid primary key default gen_random_uuid(),
  chapter_id uuid not null references public.chapters(id) on delete cascade,
  question text not null,
  option_a text not null, option_b text not null, option_c text not null, option_d text not null,
  correct_option public.mcq_option not null, explanation text,
  difficulty public.difficulty_level not null default 'medium',
  status public.content_status not null default 'published',
  tags text[] not null default '{}',
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.mcqs enable row level security;

create table if not exists public.mcq_bookmarks (
  user_id uuid not null references auth.users(id) on delete cascade,
  mcq_id uuid not null references public.mcqs(id) on delete cascade,
  chapter_id uuid references public.chapters(id) on delete set null,
  subject_id uuid references public.subjects(id) on delete set null,
  level text, created_at timestamptz not null default now(),
  primary key (user_id, mcq_id)
);

alter table public.mcq_bookmarks enable row level security;

create table if not exists public.mcq_wrong_questions (
  user_id uuid not null references auth.users(id) on delete cascade,
  mcq_id uuid not null references public.mcqs(id) on delete cascade,
  chapter_id uuid references public.chapters(id) on delete set null,
  subject_id uuid references public.subjects(id) on delete set null,
  level text,
  last_chosen_option public.mcq_option, correct_option public.mcq_option,
  retry_count integer not null default 0,
  mastered boolean not null default false,
  last_wrong_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  primary key (user_id, mcq_id)
);

alter table public.mcq_wrong_questions enable row level security;

create table if not exists public.mcq_delete_audit (
  id uuid primary key default gen_random_uuid(),
  admin_id uuid references auth.users(id) on delete set null,
  admin_name text, deleted_count integer not null default 0,
  scope text not null default 'selected',
  level text, subject_id uuid, chapter_id uuid,
  mcq_ids uuid[] not null default '{}',
  created_at timestamptz not null default now()
);

alter table public.mcq_delete_audit enable row level security;

create table if not exists public.quizzes (
  id uuid primary key default gen_random_uuid(),
  title text not null, description text, level text not null,
  subject_id uuid references public.subjects(id) on delete set null,
  chapter_id uuid references public.chapters(id) on delete set null,
  kind text not null default 'quiz' check (kind in ('quiz','mock')),
  status public.content_status not null default 'draft',
  difficulty public.difficulty_level not null default 'medium',
  total_questions integer not null default 10,
  duration_seconds integer not null default 900,
  starts_at timestamptz, ends_at timestamptz,
  is_public boolean not null default true,
  randomize_options boolean not null default false,
  randomize_questions boolean not null default true,
  passing_marks integer not null default 0,
  negative_marking numeric(4,2) not null default 0,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.quizzes enable row level security;

create table if not exists public.quiz_questions (
  id uuid primary key default gen_random_uuid(),
  quiz_id uuid not null references public.quizzes(id) on delete cascade,
  mcq_id uuid not null references public.mcqs(id) on delete cascade,
  position integer not null default 0,
  unique (quiz_id, mcq_id)
);

alter table public.quiz_questions enable row level security;

create table if not exists public.quiz_sessions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  chapter_id uuid references public.chapters(id) on delete set null,
  subject_id uuid references public.subjects(id) on delete set null,
  level text, mcq_ids uuid[] not null default '{}',
  status text not null default 'pending_review' check (status in ('pending_review','ready','in_progress','submitted','expired','rejected')),
  duration_seconds integer not null default 600,
  question_count integer not null default 0,
  started_at timestamptz, submitted_at timestamptz,
  answers jsonb not null default '{}',
  score integer, correct_count integer, wrong_count integer,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.quiz_sessions enable row level security;

create table if not exists public.exam_attempts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  quiz_id uuid references public.quizzes(id) on delete set null,
  subject_id uuid references public.subjects(id) on delete set null,
  chapter_id uuid references public.chapters(id) on delete set null,
  level text,
  kind text not null check (kind in ('mcq_practice','quiz','mock','custom_exam')),
  title text, attempt_number integer not null default 1,
  status text not null default 'completed' check (status in ('in_progress','completed','abandoned')),
  started_at timestamptz not null default now(), completed_at timestamptz,
  duration_seconds integer not null default 0,
  correct_count integer not null default 0,
  total_count integer not null default 0,
  score integer not null default 0,
  meta jsonb not null default '{}',
  created_at timestamptz not null default now()
);

alter table public.exam_attempts enable row level security;

create table if not exists public.attempt_answers (
  id uuid primary key default gen_random_uuid(),
  attempt_id uuid not null references public.exam_attempts(id) on delete cascade,
  mcq_id uuid not null references public.mcqs(id) on delete cascade,
  chosen_option public.mcq_option,
  is_correct boolean not null default false,
  time_spent_ms integer not null default 0
);

alter table public.attempt_answers enable row level security;

create table if not exists public.flash_cards (
  id uuid primary key default gen_random_uuid(),
  subject_id uuid references public.subjects(id) on delete set null,
  chapter_id uuid references public.chapters(id) on delete set null,
  level text not null default 'professional',
  front text not null, back text not null, formula text, image_url text,
  card_type text not null default 'concept' check (card_type in ('concept','formula','diagram','timeline','definition','other')),
  tags text[] not null default '{}',
  status public.content_status not null default 'draft',
  is_hidden boolean not null default false,
  scheduled_at timestamptz, view_count integer not null default 0,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.flash_cards enable row level security;

create table if not exists public.flash_card_visibility (
  id integer primary key default 1,
  section_hidden boolean not null default false,
  hidden_levels text[] not null default '{}',
  hidden_subject_ids uuid[] not null default '{}',
  hidden_chapter_ids uuid[] not null default '{}',
  updated_at timestamptz not null default now(),
  constraint flash_card_visibility_singleton check (id = 1)
);

alter table public.flash_card_visibility enable row level security;

create table if not exists public.short_notes (
  id uuid primary key default gen_random_uuid(),
  title text not null, summary text, level text not null default 'professional',
  subject_id uuid references public.subjects(id) on delete set null,
  chapter_id uuid references public.chapters(id) on delete set null,
  kind text not null default 'text' check (kind in ('text','pdf','doc')),
  body text, file_url text, file_name text, file_size_bytes bigint,
  tags text[] not null default '{}',
  status public.content_status not null default 'draft',
  is_hidden boolean not null default false,
  scheduled_at timestamptz,
  view_count integer not null default 0,
  download_count integer not null default 0,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.short_notes enable row level security;

create table if not exists public.short_notes_visibility (
  id integer primary key default 1,
  section_hidden boolean not null default false,
  hidden_levels text[] not null default '{}',
  hidden_subject_ids uuid[] not null default '{}',
  hidden_chapter_ids uuid[] not null default '{}',
  updated_at timestamptz not null default now(),
  constraint short_notes_visibility_singleton check (id = 1)
);

alter table public.short_notes_visibility enable row level security;

create table if not exists public.question_bank_resources (
  id uuid primary key default gen_random_uuid(),
  title text not null, summary text, level text not null default 'professional',
  subject_id uuid references public.subjects(id) on delete set null,
  chapter_id uuid references public.chapters(id) on delete set null,
  kind text not null default 'text' check (kind in ('text','pdf','doc')),
  resource_type text not null default 'important' check (resource_type in ('important','pyq','model','notes','text')),
  body text, file_url text, file_name text, file_size_bytes bigint,
  question_count integer not null default 0,
  tags text[] not null default '{}',
  status public.content_status not null default 'draft',
  is_hidden boolean not null default false,
  scheduled_at timestamptz,
  view_count integer not null default 0,
  download_count integer not null default 0,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.question_bank_resources enable row level security;

create table if not exists public.question_bank_visibility (
  id integer primary key default 1,
  section_hidden boolean not null default false,
  hidden_levels text[] not null default '{}',
  hidden_subject_ids uuid[] not null default '{}',
  hidden_chapter_ids uuid[] not null default '{}',
  updated_at timestamptz not null default now(),
  constraint question_bank_visibility_singleton check (id = 1)
);

alter table public.question_bank_visibility enable row level security;

create table if not exists public.video_classes (
  id uuid primary key default gen_random_uuid(),
  title text not null, description text, level text not null default 'professional',
  subject_id uuid references public.subjects(id) on delete set null,
  chapter_id uuid references public.chapters(id) on delete set null,
  instructor text,
  kind text not null default 'youtube' check (kind in ('youtube','playlist','upload')),
  youtube_url text, youtube_video_id text, youtube_playlist_id text,
  thumbnail_url text, duration_seconds integer not null default 0,
  playlist_key text, position integer not null default 0,
  tags text[] not null default '{}',
  status public.content_status not null default 'draft',
  is_hidden boolean not null default false,
  is_featured boolean not null default false,
  scheduled_at timestamptz,
  view_count integer not null default 0,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.video_classes enable row level security;

create table if not exists public.video_class_visibility (
  id integer primary key default 1,
  section_hidden boolean not null default false,
  hidden_levels text[] not null default '{}',
  hidden_subject_ids uuid[] not null default '{}',
  hidden_chapter_ids uuid[] not null default '{}',
  updated_at timestamptz not null default now(),
  constraint video_class_visibility_singleton check (id = 1)
);

alter table public.video_class_visibility enable row level security;

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  title text not null, body text not null default '', link text,
  type text not null default 'in_app' check (type in ('announcement','push','email','in_app')),
  priority text not null default 'medium' check (priority in ('low','medium','high','critical')),
  audience text not null default 'all' check (audience in ('all','level','subject','role','users')),
  audience_level text, audience_subject_id uuid,
  audience_role text check (audience_role in ('admin','moderator','student')),
  audience_user_ids uuid[] not null default '{}',
  scheduled_at timestamptz,
  status text not null default 'draft' check (status in ('draft','scheduled','sent','failed','paused')),
  sent_at timestamptz, delivered_count integer not null default 0,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.notifications enable row level security;

create table if not exists public.notification_reads (
  notification_id uuid not null references public.notifications(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (notification_id, user_id)
);

alter table public.notification_reads enable row level security;

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS status text NOT NULL DEFAULT 'active'
    CHECK (status IN ('active','suspended','pending')),
  ADD COLUMN IF NOT EXISTS referral_source text;

ALTER TABLE public.notifications
  ADD COLUMN IF NOT EXISTS open_count integer NOT NULL DEFAULT 0;

ALTER TABLE public.mcq_bookmarks DROP CONSTRAINT IF EXISTS mcq_bookmarks_pkey;

ALTER TABLE public.mcq_bookmarks
  ADD COLUMN IF NOT EXISTS id uuid NOT NULL DEFAULT gen_random_uuid();

ALTER TABLE public.mcq_bookmarks ADD PRIMARY KEY (id);

DO $$ BEGIN
  ALTER TABLE public.mcq_bookmarks ADD CONSTRAINT mcq_bookmarks_user_mcq_key UNIQUE (user_id, mcq_id);
EXCEPTION WHEN duplicate_table THEN NULL; WHEN duplicate_object THEN NULL; END $$;

ALTER TABLE public.mcq_wrong_questions DROP CONSTRAINT IF EXISTS mcq_wrong_questions_pkey;

ALTER TABLE public.mcq_wrong_questions
  ADD COLUMN IF NOT EXISTS id uuid NOT NULL DEFAULT gen_random_uuid();

ALTER TABLE public.mcq_wrong_questions ADD PRIMARY KEY (id);

DO $$ BEGIN
  ALTER TABLE public.mcq_wrong_questions ADD CONSTRAINT mcq_wrong_questions_user_mcq_key UNIQUE (user_id, mcq_id);
EXCEPTION WHEN duplicate_table THEN NULL; WHEN duplicate_object THEN NULL; END $$;

ALTER TABLE public.subjects ALTER COLUMN level DROP NOT NULL;

ALTER TABLE public.quizzes ALTER COLUMN level DROP NOT NULL;

ALTER TABLE public.exam_attempts ALTER COLUMN kind DROP NOT NULL;

ALTER TABLE public.subjects ALTER COLUMN level SET DEFAULT '';

ALTER TABLE public.subjects ALTER COLUMN level SET NOT NULL;

ALTER TABLE public.quizzes ALTER COLUMN level SET DEFAULT '';

ALTER TABLE public.quizzes ALTER COLUMN level SET NOT NULL;

ALTER TABLE public.exam_attempts ALTER COLUMN kind SET DEFAULT 'mcq_practice';

ALTER TABLE public.exam_attempts ALTER COLUMN kind SET NOT NULL;

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS deleted_at timestamptz,
  ADD COLUMN IF NOT EXISTS last_login_at timestamptz,
  ADD COLUMN IF NOT EXISTS total_login_count integer NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS total_usage_seconds bigint NOT NULL DEFAULT 0;

CREATE TABLE IF NOT EXISTS public.user_login_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  login_at timestamptz NOT NULL DEFAULT now(),
  logout_at timestamptz,
  duration_seconds integer,
  user_agent text,
  device text,
  browser text,
  ip text,
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.user_login_events ENABLE ROW LEVEL SECURITY;

-- ------------------------------------------------------------
-- Migration: 20260606135033_df22bf78-4866-4419-aa56-6facbe72df8b.sql
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.activity_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NULL,
  event_type text NOT NULL,
  page_url text NULL,
  page_path text NULL,
  referrer text NULL,
  element_id text NULL,
  element_label text NULL,
  element_role text NULL,
  module text NULL,
  target_kind text NULL,
  target_id text NULL,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  user_agent text NULL,
  device text NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.activity_events ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.activity_events REPLICA IDENTITY FULL;

-- ------------------------------------------------------------
-- Migration: 20260606141018_576c0c75-2a5f-4a25-a56a-10e8cfba4a89.sql
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.study_sessions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  module text NOT NULL DEFAULT 'dashboard',
  subject_id uuid,
  chapter_id uuid,
  started_at timestamptz NOT NULL DEFAULT now(),
  last_heartbeat_at timestamptz NOT NULL DEFAULT now(),
  ended_at timestamptz,
  duration_seconds integer NOT NULL DEFAULT 0,
  meta jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.study_sessions ENABLE ROW LEVEL SECURITY;

-- ------------------------------------------------------------
-- Migration: 20260606143322_6f3b4743-b181-4364-b550-d0aab7222119.sql
-- ------------------------------------------------------------
ALTER TABLE public.quiz_sessions
  ADD COLUMN IF NOT EXISTS approved_by uuid,
  ADD COLUMN IF NOT EXISTS approved_at timestamptz,
  ADD COLUMN IF NOT EXISTS reject_reason text;

CREATE TABLE IF NOT EXISTS public.user_roles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role public.app_role NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id, role)
);

ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.homepage_sections (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  section_key text NOT NULL UNIQUE,
  position int NOT NULL DEFAULT 0,
  visible boolean NOT NULL DEFAULT true,
  draft_content jsonb NOT NULL DEFAULT '{}'::jsonb,
  published_content jsonb NOT NULL DEFAULT '{}'::jsonb,
  published_at timestamptz,
  updated_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.homepage_sections ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.site_settings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  key text NOT NULL UNIQUE,
  draft_value jsonb NOT NULL DEFAULT '{}'::jsonb,
  published_value jsonb NOT NULL DEFAULT '{}'::jsonb,
  published_at timestamptz,
  updated_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.site_settings ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.module_visibility (
  key text PRIMARY KEY,
  label text NOT NULL,
  hidden boolean NOT NULL DEFAULT false,
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.module_visibility ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.content_versions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  target_kind text NOT NULL CHECK (target_kind IN ('section','setting')),
  target_key text NOT NULL,
  snapshot jsonb NOT NULL DEFAULT '{}'::jsonb,
  label text,
  created_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.content_versions ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.media_assets (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  bucket text NOT NULL,
  path text NOT NULL,
  file_name text NOT NULL,
  mime_type text NOT NULL,
  size_bytes bigint NOT NULL DEFAULT 0,
  width int,
  height int,
  alt_text text,
  tags text[] NOT NULL DEFAULT '{}',
  uploaded_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.media_assets ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.user_sessions (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  active_session_id TEXT NOT NULL,
  user_agent TEXT,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.user_sessions ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.user_sessions REPLICA IDENTITY FULL;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text, avatar_url text, bio text, level text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

create table if not exists public.avatars (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  storage_path text not null, public_url text,
  created_at timestamptz not null default now()
);

alter table public.avatars enable row level security;

create table if not exists public.levels (
  code text primary key, name text not null, description text, color text, icon text,
  sort_order integer not null default 0,
  status public.content_status not null default 'published',
  updated_at timestamptz not null default now()
);

alter table public.levels enable row level security;

create table if not exists public.subjects (
  id uuid primary key default gen_random_uuid(),
  name text not null, slug text not null unique,
  level text not null references public.levels(code) on delete restrict,
  description text, color text, icon text,
  sort_order integer not null default 0,
  status public.content_status not null default 'published',
  updated_at timestamptz not null default now()
);

alter table public.subjects enable row level security;

create table if not exists public.chapters (
  id uuid primary key default gen_random_uuid(),
  subject_id uuid not null references public.subjects(id) on delete cascade,
  name text not null, slug text not null, description text,
  sort_order integer not null default 0,
  status public.content_status not null default 'published',
  updated_at timestamptz not null default now(),
  unique (subject_id, slug)
);

alter table public.chapters enable row level security;

create table if not exists public.mcqs (
  id uuid primary key default gen_random_uuid(),
  chapter_id uuid not null references public.chapters(id) on delete cascade,
  question text not null,
  option_a text not null, option_b text not null, option_c text not null, option_d text not null,
  correct_option public.mcq_option not null, explanation text,
  difficulty public.difficulty_level not null default 'medium',
  status public.content_status not null default 'published',
  tags text[] not null default '{}',
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.mcqs enable row level security;

create table if not exists public.mcq_bookmarks (
  user_id uuid not null references auth.users(id) on delete cascade,
  mcq_id uuid not null references public.mcqs(id) on delete cascade,
  chapter_id uuid references public.chapters(id) on delete set null,
  subject_id uuid references public.subjects(id) on delete set null,
  level text, created_at timestamptz not null default now(),
  primary key (user_id, mcq_id)
);

alter table public.mcq_bookmarks enable row level security;

create table if not exists public.mcq_wrong_questions (
  user_id uuid not null references auth.users(id) on delete cascade,
  mcq_id uuid not null references public.mcqs(id) on delete cascade,
  chapter_id uuid references public.chapters(id) on delete set null,
  subject_id uuid references public.subjects(id) on delete set null,
  level text,
  last_chosen_option public.mcq_option, correct_option public.mcq_option,
  retry_count integer not null default 0,
  mastered boolean not null default false,
  last_wrong_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  primary key (user_id, mcq_id)
);

alter table public.mcq_wrong_questions enable row level security;

create table if not exists public.mcq_delete_audit (
  id uuid primary key default gen_random_uuid(),
  admin_id uuid references auth.users(id) on delete set null,
  admin_name text, deleted_count integer not null default 0,
  scope text not null default 'selected',
  level text, subject_id uuid, chapter_id uuid,
  mcq_ids uuid[] not null default '{}',
  created_at timestamptz not null default now()
);

alter table public.mcq_delete_audit enable row level security;

create table if not exists public.quizzes (
  id uuid primary key default gen_random_uuid(),
  title text not null, description text, level text not null,
  subject_id uuid references public.subjects(id) on delete set null,
  chapter_id uuid references public.chapters(id) on delete set null,
  kind text not null default 'quiz' check (kind in ('quiz','mock')),
  status public.content_status not null default 'draft',
  difficulty public.difficulty_level not null default 'medium',
  total_questions integer not null default 10,
  duration_seconds integer not null default 900,
  starts_at timestamptz, ends_at timestamptz,
  is_public boolean not null default true,
  randomize_options boolean not null default false,
  randomize_questions boolean not null default true,
  passing_marks integer not null default 0,
  negative_marking numeric(4,2) not null default 0,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.quizzes enable row level security;

create table if not exists public.quiz_questions (
  id uuid primary key default gen_random_uuid(),
  quiz_id uuid not null references public.quizzes(id) on delete cascade,
  mcq_id uuid not null references public.mcqs(id) on delete cascade,
  position integer not null default 0,
  unique (quiz_id, mcq_id)
);

alter table public.quiz_questions enable row level security;

create table if not exists public.quiz_sessions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  chapter_id uuid references public.chapters(id) on delete set null,
  subject_id uuid references public.subjects(id) on delete set null,
  level text, mcq_ids uuid[] not null default '{}',
  status text not null default 'pending_review' check (status in ('pending_review','ready','in_progress','submitted','expired','rejected')),
  duration_seconds integer not null default 600,
  question_count integer not null default 0,
  started_at timestamptz, submitted_at timestamptz,
  answers jsonb not null default '{}',
  score integer, correct_count integer, wrong_count integer,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.quiz_sessions enable row level security;

create table if not exists public.exam_attempts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  quiz_id uuid references public.quizzes(id) on delete set null,
  subject_id uuid references public.subjects(id) on delete set null,
  chapter_id uuid references public.chapters(id) on delete set null,
  level text,
  kind text not null check (kind in ('mcq_practice','quiz','mock','custom_exam')),
  title text, attempt_number integer not null default 1,
  status text not null default 'completed' check (status in ('in_progress','completed','abandoned')),
  started_at timestamptz not null default now(), completed_at timestamptz,
  duration_seconds integer not null default 0,
  correct_count integer not null default 0,
  total_count integer not null default 0,
  score integer not null default 0,
  meta jsonb not null default '{}',
  created_at timestamptz not null default now()
);

alter table public.exam_attempts enable row level security;

create table if not exists public.attempt_answers (
  id uuid primary key default gen_random_uuid(),
  attempt_id uuid not null references public.exam_attempts(id) on delete cascade,
  mcq_id uuid not null references public.mcqs(id) on delete cascade,
  chosen_option public.mcq_option,
  is_correct boolean not null default false,
  time_spent_ms integer not null default 0
);

alter table public.attempt_answers enable row level security;

create table if not exists public.flash_cards (
  id uuid primary key default gen_random_uuid(),
  subject_id uuid references public.subjects(id) on delete set null,
  chapter_id uuid references public.chapters(id) on delete set null,
  level text not null default 'professional',
  front text not null, back text not null, formula text, image_url text,
  card_type text not null default 'concept' check (card_type in ('concept','formula','diagram','timeline','definition','other')),
  tags text[] not null default '{}',
  status public.content_status not null default 'draft',
  is_hidden boolean not null default false,
  scheduled_at timestamptz, view_count integer not null default 0,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.flash_cards enable row level security;

create table if not exists public.flash_card_visibility (
  id integer primary key default 1,
  section_hidden boolean not null default false,
  hidden_levels text[] not null default '{}',
  hidden_subject_ids uuid[] not null default '{}',
  hidden_chapter_ids uuid[] not null default '{}',
  updated_at timestamptz not null default now(),
  constraint flash_card_visibility_singleton check (id = 1)
);

alter table public.flash_card_visibility enable row level security;

create table if not exists public.short_notes (
  id uuid primary key default gen_random_uuid(),
  title text not null, summary text, level text not null default 'professional',
  subject_id uuid references public.subjects(id) on delete set null,
  chapter_id uuid references public.chapters(id) on delete set null,
  kind text not null default 'text' check (kind in ('text','pdf','doc')),
  body text, file_url text, file_name text, file_size_bytes bigint,
  tags text[] not null default '{}',
  status public.content_status not null default 'draft',
  is_hidden boolean not null default false,
  scheduled_at timestamptz,
  view_count integer not null default 0,
  download_count integer not null default 0,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.short_notes enable row level security;

create table if not exists public.short_notes_visibility (
  id integer primary key default 1,
  section_hidden boolean not null default false,
  hidden_levels text[] not null default '{}',
  hidden_subject_ids uuid[] not null default '{}',
  hidden_chapter_ids uuid[] not null default '{}',
  updated_at timestamptz not null default now(),
  constraint short_notes_visibility_singleton check (id = 1)
);

alter table public.short_notes_visibility enable row level security;

create table if not exists public.question_bank_resources (
  id uuid primary key default gen_random_uuid(),
  title text not null, summary text, level text not null default 'professional',
  subject_id uuid references public.subjects(id) on delete set null,
  chapter_id uuid references public.chapters(id) on delete set null,
  kind text not null default 'text' check (kind in ('text','pdf','doc')),
  resource_type text not null default 'important' check (resource_type in ('important','pyq','model','notes','text')),
  body text, file_url text, file_name text, file_size_bytes bigint,
  question_count integer not null default 0,
  tags text[] not null default '{}',
  status public.content_status not null default 'draft',
  is_hidden boolean not null default false,
  scheduled_at timestamptz,
  view_count integer not null default 0,
  download_count integer not null default 0,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.question_bank_resources enable row level security;

create table if not exists public.question_bank_visibility (
  id integer primary key default 1,
  section_hidden boolean not null default false,
  hidden_levels text[] not null default '{}',
  hidden_subject_ids uuid[] not null default '{}',
  hidden_chapter_ids uuid[] not null default '{}',
  updated_at timestamptz not null default now(),
  constraint question_bank_visibility_singleton check (id = 1)
);

alter table public.question_bank_visibility enable row level security;

create table if not exists public.video_classes (
  id uuid primary key default gen_random_uuid(),
  title text not null, description text, level text not null default 'professional',
  subject_id uuid references public.subjects(id) on delete set null,
  chapter_id uuid references public.chapters(id) on delete set null,
  instructor text,
  kind text not null default 'youtube' check (kind in ('youtube','playlist','upload')),
  youtube_url text, youtube_video_id text, youtube_playlist_id text,
  thumbnail_url text, duration_seconds integer not null default 0,
  playlist_key text, position integer not null default 0,
  tags text[] not null default '{}',
  status public.content_status not null default 'draft',
  is_hidden boolean not null default false,
  is_featured boolean not null default false,
  scheduled_at timestamptz,
  view_count integer not null default 0,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.video_classes enable row level security;

create table if not exists public.video_class_visibility (
  id integer primary key default 1,
  section_hidden boolean not null default false,
  hidden_levels text[] not null default '{}',
  hidden_subject_ids uuid[] not null default '{}',
  hidden_chapter_ids uuid[] not null default '{}',
  updated_at timestamptz not null default now(),
  constraint video_class_visibility_singleton check (id = 1)
);

alter table public.video_class_visibility enable row level security;

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  title text not null, body text not null default '', link text,
  type text not null default 'in_app' check (type in ('announcement','push','email','in_app')),
  priority text not null default 'medium' check (priority in ('low','medium','high','critical')),
  audience text not null default 'all' check (audience in ('all','level','subject','role','users')),
  audience_level text, audience_subject_id uuid,
  audience_role text check (audience_role in ('admin','moderator','student')),
  audience_user_ids uuid[] not null default '{}',
  scheduled_at timestamptz,
  status text not null default 'draft' check (status in ('draft','scheduled','sent','failed','paused')),
  sent_at timestamptz, delivered_count integer not null default 0,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.notifications enable row level security;

create table if not exists public.notification_reads (
  notification_id uuid not null references public.notifications(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (notification_id, user_id)
);

alter table public.notification_reads enable row level security;

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS status text NOT NULL DEFAULT 'active'
    CHECK (status IN ('active','suspended','pending')),
  ADD COLUMN IF NOT EXISTS referral_source text;

ALTER TABLE public.notifications
  ADD COLUMN IF NOT EXISTS open_count integer NOT NULL DEFAULT 0;

ALTER TABLE public.mcq_bookmarks DROP CONSTRAINT IF EXISTS mcq_bookmarks_pkey;

ALTER TABLE public.mcq_bookmarks
  ADD COLUMN IF NOT EXISTS id uuid NOT NULL DEFAULT gen_random_uuid();

ALTER TABLE public.mcq_bookmarks ADD PRIMARY KEY (id);

DO $$ BEGIN
  ALTER TABLE public.mcq_bookmarks ADD CONSTRAINT mcq_bookmarks_user_mcq_key UNIQUE (user_id, mcq_id);
EXCEPTION WHEN duplicate_table THEN NULL; WHEN duplicate_object THEN NULL; END $$;

ALTER TABLE public.mcq_wrong_questions DROP CONSTRAINT IF EXISTS mcq_wrong_questions_pkey;

ALTER TABLE public.mcq_wrong_questions
  ADD COLUMN IF NOT EXISTS id uuid NOT NULL DEFAULT gen_random_uuid();

ALTER TABLE public.mcq_wrong_questions ADD PRIMARY KEY (id);

DO $$ BEGIN
  ALTER TABLE public.mcq_wrong_questions ADD CONSTRAINT mcq_wrong_questions_user_mcq_key UNIQUE (user_id, mcq_id);
EXCEPTION WHEN duplicate_table THEN NULL; WHEN duplicate_object THEN NULL; END $$;

ALTER TABLE public.subjects ALTER COLUMN level DROP NOT NULL;

ALTER TABLE public.quizzes ALTER COLUMN level DROP NOT NULL;

ALTER TABLE public.exam_attempts ALTER COLUMN kind DROP NOT NULL;

ALTER TABLE public.subjects ALTER COLUMN level SET DEFAULT '';

ALTER TABLE public.subjects ALTER COLUMN level SET NOT NULL;

ALTER TABLE public.quizzes ALTER COLUMN level SET DEFAULT '';

ALTER TABLE public.quizzes ALTER COLUMN level SET NOT NULL;

ALTER TABLE public.exam_attempts ALTER COLUMN kind SET DEFAULT 'mcq_practice';

ALTER TABLE public.exam_attempts ALTER COLUMN kind SET NOT NULL;

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS deleted_at timestamptz,
  ADD COLUMN IF NOT EXISTS last_login_at timestamptz,
  ADD COLUMN IF NOT EXISTS total_login_count integer NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS total_usage_seconds bigint NOT NULL DEFAULT 0;

CREATE TABLE IF NOT EXISTS public.user_login_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  login_at timestamptz NOT NULL DEFAULT now(),
  logout_at timestamptz,
  duration_seconds integer,
  user_agent text,
  device text,
  browser text,
  ip text,
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.user_login_events ENABLE ROW LEVEL SECURITY;

-- ------------------------------------------------------------
-- Migration: 20260606151606_ccc194e2-37aa-4f0a-ae18-cf79b7268f0b.sql
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.activity_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NULL,
  event_type text NOT NULL,
  page_url text NULL,
  page_path text NULL,
  referrer text NULL,
  element_id text NULL,
  element_label text NULL,
  element_role text NULL,
  module text NULL,
  target_kind text NULL,
  target_id text NULL,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  user_agent text NULL,
  device text NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.activity_events ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.activity_events REPLICA IDENTITY FULL;

-- ------------------------------------------------------------
-- Migration: 20260606151754_03e2b33c-bfe1-4c52-92d6-a52c6fe5f489.sql
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.study_sessions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  module text NOT NULL,
  started_at timestamptz NOT NULL DEFAULT now(),
  last_heartbeat_at timestamptz NOT NULL DEFAULT now(),
  ended_at timestamptz,
  duration_seconds integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.study_sessions ENABLE ROW LEVEL SECURITY;

-- Also ensure quiz_sessions has any columns referenced by app code (idempotent)
ALTER TABLE public.quiz_sessions
  ADD COLUMN IF NOT EXISTS module text,
  ADD COLUMN IF NOT EXISTS duration_seconds integer NOT NULL DEFAULT 0;

-- ------------------------------------------------------------
-- Migration: 20260606153310_3a615b0f-652f-48be-a304-bfead22b453a.sql
-- ------------------------------------------------------------
-- Add True/False support
ALTER TABLE public.mcqs
  ADD COLUMN IF NOT EXISTS question_type text NOT NULL DEFAULT 'mcq'
    CHECK (question_type IN ('mcq', 'true_false'));

ALTER TABLE public.mcqs ALTER COLUMN option_c DROP NOT NULL;

ALTER TABLE public.mcqs ALTER COLUMN option_d DROP NOT NULL;

CREATE TABLE IF NOT EXISTS public.user_roles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role public.app_role NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id, role)
);

ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.homepage_sections (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  section_key text NOT NULL UNIQUE,
  position int NOT NULL DEFAULT 0,
  visible boolean NOT NULL DEFAULT true,
  draft_content jsonb NOT NULL DEFAULT '{}'::jsonb,
  published_content jsonb NOT NULL DEFAULT '{}'::jsonb,
  published_at timestamptz,
  updated_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.homepage_sections ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.site_settings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  key text NOT NULL UNIQUE,
  draft_value jsonb NOT NULL DEFAULT '{}'::jsonb,
  published_value jsonb NOT NULL DEFAULT '{}'::jsonb,
  published_at timestamptz,
  updated_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.site_settings ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.module_visibility (
  key text PRIMARY KEY,
  label text NOT NULL,
  hidden boolean NOT NULL DEFAULT false,
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.module_visibility ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.content_versions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  target_kind text NOT NULL CHECK (target_kind IN ('section','setting')),
  target_key text NOT NULL,
  snapshot jsonb NOT NULL DEFAULT '{}'::jsonb,
  label text,
  created_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.content_versions ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.media_assets (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  bucket text NOT NULL,
  path text NOT NULL,
  file_name text NOT NULL,
  mime_type text NOT NULL,
  size_bytes bigint NOT NULL DEFAULT 0,
  width int,
  height int,
  alt_text text,
  tags text[] NOT NULL DEFAULT '{}',
  uploaded_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.media_assets ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.user_sessions (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  active_session_id TEXT NOT NULL,
  user_agent TEXT,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.user_sessions ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.user_sessions REPLICA IDENTITY FULL;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text, avatar_url text, bio text, level text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

create table if not exists public.avatars (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  storage_path text not null, public_url text,
  created_at timestamptz not null default now()
);

alter table public.avatars enable row level security;

create table if not exists public.levels (
  code text primary key, name text not null, description text, color text, icon text,
  sort_order integer not null default 0,
  status public.content_status not null default 'published',
  updated_at timestamptz not null default now()
);

alter table public.levels enable row level security;

create table if not exists public.subjects (
  id uuid primary key default gen_random_uuid(),
  name text not null, slug text not null unique,
  level text not null references public.levels(code) on delete restrict,
  description text, color text, icon text,
  sort_order integer not null default 0,
  status public.content_status not null default 'published',
  updated_at timestamptz not null default now()
);

alter table public.subjects enable row level security;

create table if not exists public.chapters (
  id uuid primary key default gen_random_uuid(),
  subject_id uuid not null references public.subjects(id) on delete cascade,
  name text not null, slug text not null, description text,
  sort_order integer not null default 0,
  status public.content_status not null default 'published',
  updated_at timestamptz not null default now(),
  unique (subject_id, slug)
);

alter table public.chapters enable row level security;

create table if not exists public.mcqs (
  id uuid primary key default gen_random_uuid(),
  chapter_id uuid not null references public.chapters(id) on delete cascade,
  question text not null,
  option_a text not null, option_b text not null, option_c text not null, option_d text not null,
  correct_option public.mcq_option not null, explanation text,
  difficulty public.difficulty_level not null default 'medium',
  status public.content_status not null default 'published',
  tags text[] not null default '{}',
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.mcqs enable row level security;

create table if not exists public.mcq_bookmarks (
  user_id uuid not null references auth.users(id) on delete cascade,
  mcq_id uuid not null references public.mcqs(id) on delete cascade,
  chapter_id uuid references public.chapters(id) on delete set null,
  subject_id uuid references public.subjects(id) on delete set null,
  level text, created_at timestamptz not null default now(),
  primary key (user_id, mcq_id)
);

alter table public.mcq_bookmarks enable row level security;

create table if not exists public.mcq_wrong_questions (
  user_id uuid not null references auth.users(id) on delete cascade,
  mcq_id uuid not null references public.mcqs(id) on delete cascade,
  chapter_id uuid references public.chapters(id) on delete set null,
  subject_id uuid references public.subjects(id) on delete set null,
  level text,
  last_chosen_option public.mcq_option, correct_option public.mcq_option,
  retry_count integer not null default 0,
  mastered boolean not null default false,
  last_wrong_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  primary key (user_id, mcq_id)
);

alter table public.mcq_wrong_questions enable row level security;

create table if not exists public.mcq_delete_audit (
  id uuid primary key default gen_random_uuid(),
  admin_id uuid references auth.users(id) on delete set null,
  admin_name text, deleted_count integer not null default 0,
  scope text not null default 'selected',
  level text, subject_id uuid, chapter_id uuid,
  mcq_ids uuid[] not null default '{}',
  created_at timestamptz not null default now()
);

alter table public.mcq_delete_audit enable row level security;

create table if not exists public.quizzes (
  id uuid primary key default gen_random_uuid(),
  title text not null, description text, level text not null,
  subject_id uuid references public.subjects(id) on delete set null,
  chapter_id uuid references public.chapters(id) on delete set null,
  kind text not null default 'quiz' check (kind in ('quiz','mock')),
  status public.content_status not null default 'draft',
  difficulty public.difficulty_level not null default 'medium',
  total_questions integer not null default 10,
  duration_seconds integer not null default 900,
  starts_at timestamptz, ends_at timestamptz,
  is_public boolean not null default true,
  randomize_options boolean not null default false,
  randomize_questions boolean not null default true,
  passing_marks integer not null default 0,
  negative_marking numeric(4,2) not null default 0,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.quizzes enable row level security;

create table if not exists public.quiz_questions (
  id uuid primary key default gen_random_uuid(),
  quiz_id uuid not null references public.quizzes(id) on delete cascade,
  mcq_id uuid not null references public.mcqs(id) on delete cascade,
  position integer not null default 0,
  unique (quiz_id, mcq_id)
);

alter table public.quiz_questions enable row level security;

create table if not exists public.quiz_sessions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  chapter_id uuid references public.chapters(id) on delete set null,
  subject_id uuid references public.subjects(id) on delete set null,
  level text, mcq_ids uuid[] not null default '{}',
  status text not null default 'pending_review' check (status in ('pending_review','ready','in_progress','submitted','expired','rejected')),
  duration_seconds integer not null default 600,
  question_count integer not null default 0,
  started_at timestamptz, submitted_at timestamptz,
  answers jsonb not null default '{}',
  score integer, correct_count integer, wrong_count integer,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.quiz_sessions enable row level security;

create table if not exists public.exam_attempts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  quiz_id uuid references public.quizzes(id) on delete set null,
  subject_id uuid references public.subjects(id) on delete set null,
  chapter_id uuid references public.chapters(id) on delete set null,
  level text,
  kind text not null check (kind in ('mcq_practice','quiz','mock','custom_exam')),
  title text, attempt_number integer not null default 1,
  status text not null default 'completed' check (status in ('in_progress','completed','abandoned')),
  started_at timestamptz not null default now(), completed_at timestamptz,
  duration_seconds integer not null default 0,
  correct_count integer not null default 0,
  total_count integer not null default 0,
  score integer not null default 0,
  meta jsonb not null default '{}',
  created_at timestamptz not null default now()
);

alter table public.exam_attempts enable row level security;

create table if not exists public.attempt_answers (
  id uuid primary key default gen_random_uuid(),
  attempt_id uuid not null references public.exam_attempts(id) on delete cascade,
  mcq_id uuid not null references public.mcqs(id) on delete cascade,
  chosen_option public.mcq_option,
  is_correct boolean not null default false,
  time_spent_ms integer not null default 0
);

alter table public.attempt_answers enable row level security;

create table if not exists public.flash_cards (
  id uuid primary key default gen_random_uuid(),
  subject_id uuid references public.subjects(id) on delete set null,
  chapter_id uuid references public.chapters(id) on delete set null,
  level text not null default 'professional',
  front text not null, back text not null, formula text, image_url text,
  card_type text not null default 'concept' check (card_type in ('concept','formula','diagram','timeline','definition','other')),
  tags text[] not null default '{}',
  status public.content_status not null default 'draft',
  is_hidden boolean not null default false,
  scheduled_at timestamptz, view_count integer not null default 0,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.flash_cards enable row level security;

create table if not exists public.flash_card_visibility (
  id integer primary key default 1,
  section_hidden boolean not null default false,
  hidden_levels text[] not null default '{}',
  hidden_subject_ids uuid[] not null default '{}',
  hidden_chapter_ids uuid[] not null default '{}',
  updated_at timestamptz not null default now(),
  constraint flash_card_visibility_singleton check (id = 1)
);

alter table public.flash_card_visibility enable row level security;

create table if not exists public.short_notes (
  id uuid primary key default gen_random_uuid(),
  title text not null, summary text, level text not null default 'professional',
  subject_id uuid references public.subjects(id) on delete set null,
  chapter_id uuid references public.chapters(id) on delete set null,
  kind text not null default 'text' check (kind in ('text','pdf','doc')),
  body text, file_url text, file_name text, file_size_bytes bigint,
  tags text[] not null default '{}',
  status public.content_status not null default 'draft',
  is_hidden boolean not null default false,
  scheduled_at timestamptz,
  view_count integer not null default 0,
  download_count integer not null default 0,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.short_notes enable row level security;

create table if not exists public.short_notes_visibility (
  id integer primary key default 1,
  section_hidden boolean not null default false,
  hidden_levels text[] not null default '{}',
  hidden_subject_ids uuid[] not null default '{}',
  hidden_chapter_ids uuid[] not null default '{}',
  updated_at timestamptz not null default now(),
  constraint short_notes_visibility_singleton check (id = 1)
);

alter table public.short_notes_visibility enable row level security;

create table if not exists public.question_bank_resources (
  id uuid primary key default gen_random_uuid(),
  title text not null, summary text, level text not null default 'professional',
  subject_id uuid references public.subjects(id) on delete set null,
  chapter_id uuid references public.chapters(id) on delete set null,
  kind text not null default 'text' check (kind in ('text','pdf','doc')),
  resource_type text not null default 'important' check (resource_type in ('important','pyq','model','notes','text')),
  body text, file_url text, file_name text, file_size_bytes bigint,
  question_count integer not null default 0,
  tags text[] not null default '{}',
  status public.content_status not null default 'draft',
  is_hidden boolean not null default false,
  scheduled_at timestamptz,
  view_count integer not null default 0,
  download_count integer not null default 0,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.question_bank_resources enable row level security;

create table if not exists public.question_bank_visibility (
  id integer primary key default 1,
  section_hidden boolean not null default false,
  hidden_levels text[] not null default '{}',
  hidden_subject_ids uuid[] not null default '{}',
  hidden_chapter_ids uuid[] not null default '{}',
  updated_at timestamptz not null default now(),
  constraint question_bank_visibility_singleton check (id = 1)
);

alter table public.question_bank_visibility enable row level security;

create table if not exists public.video_classes (
  id uuid primary key default gen_random_uuid(),
  title text not null, description text, level text not null default 'professional',
  subject_id uuid references public.subjects(id) on delete set null,
  chapter_id uuid references public.chapters(id) on delete set null,
  instructor text,
  kind text not null default 'youtube' check (kind in ('youtube','playlist','upload')),
  youtube_url text, youtube_video_id text, youtube_playlist_id text,
  thumbnail_url text, duration_seconds integer not null default 0,
  playlist_key text, position integer not null default 0,
  tags text[] not null default '{}',
  status public.content_status not null default 'draft',
  is_hidden boolean not null default false,
  is_featured boolean not null default false,
  scheduled_at timestamptz,
  view_count integer not null default 0,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.video_classes enable row level security;

create table if not exists public.video_class_visibility (
  id integer primary key default 1,
  section_hidden boolean not null default false,
  hidden_levels text[] not null default '{}',
  hidden_subject_ids uuid[] not null default '{}',
  hidden_chapter_ids uuid[] not null default '{}',
  updated_at timestamptz not null default now(),
  constraint video_class_visibility_singleton check (id = 1)
);

alter table public.video_class_visibility enable row level security;

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  title text not null, body text not null default '', link text,
  type text not null default 'in_app' check (type in ('announcement','push','email','in_app')),
  priority text not null default 'medium' check (priority in ('low','medium','high','critical')),
  audience text not null default 'all' check (audience in ('all','level','subject','role','users')),
  audience_level text, audience_subject_id uuid,
  audience_role text check (audience_role in ('admin','moderator','student')),
  audience_user_ids uuid[] not null default '{}',
  scheduled_at timestamptz,
  status text not null default 'draft' check (status in ('draft','scheduled','sent','failed','paused')),
  sent_at timestamptz, delivered_count integer not null default 0,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.notifications enable row level security;

create table if not exists public.notification_reads (
  notification_id uuid not null references public.notifications(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (notification_id, user_id)
);

alter table public.notification_reads enable row level security;

-- ------------------------------------------------------------
-- Migration: 20260606181037_64f1ba7b-c1f8-4ec9-abe4-17368a55cb50.sql
-- ------------------------------------------------------------
-- See /tmp/remaining.sql; pasted inline below


-- ------------------------------------------------------------
-- Migration: 20260606181454_664c615b-40ea-4f20-9463-9d47c6befd79.sql
-- ------------------------------------------------------------
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS status text NOT NULL DEFAULT 'active'
    CHECK (status IN ('active','suspended','pending')),
  ADD COLUMN IF NOT EXISTS referral_source text;

ALTER TABLE public.notifications
  ADD COLUMN IF NOT EXISTS open_count integer NOT NULL DEFAULT 0;

ALTER TABLE public.mcq_bookmarks DROP CONSTRAINT IF EXISTS mcq_bookmarks_pkey;

ALTER TABLE public.mcq_bookmarks
  ADD COLUMN IF NOT EXISTS id uuid NOT NULL DEFAULT gen_random_uuid();

ALTER TABLE public.mcq_bookmarks ADD PRIMARY KEY (id);

DO $$ BEGIN
  ALTER TABLE public.mcq_bookmarks ADD CONSTRAINT mcq_bookmarks_user_mcq_key UNIQUE (user_id, mcq_id);
EXCEPTION WHEN duplicate_table THEN NULL; WHEN duplicate_object THEN NULL; END $$;

ALTER TABLE public.mcq_wrong_questions DROP CONSTRAINT IF EXISTS mcq_wrong_questions_pkey;

ALTER TABLE public.mcq_wrong_questions
  ADD COLUMN IF NOT EXISTS id uuid NOT NULL DEFAULT gen_random_uuid();

ALTER TABLE public.mcq_wrong_questions ADD PRIMARY KEY (id);

DO $$ BEGIN
  ALTER TABLE public.mcq_wrong_questions ADD CONSTRAINT mcq_wrong_questions_user_mcq_key UNIQUE (user_id, mcq_id);
EXCEPTION WHEN duplicate_table THEN NULL; WHEN duplicate_object THEN NULL; END $$;

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS deleted_at timestamptz,
  ADD COLUMN IF NOT EXISTS last_login_at timestamptz,
  ADD COLUMN IF NOT EXISTS total_login_count integer NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS total_usage_seconds bigint NOT NULL DEFAULT 0;

CREATE TABLE IF NOT EXISTS public.user_login_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  login_at timestamptz NOT NULL DEFAULT now(),
  logout_at timestamptz,
  duration_seconds integer,
  user_agent text,
  device text,
  browser text,
  ip text,
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.user_login_events ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.activity_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NULL,
  event_type text NOT NULL,
  page_url text NULL,
  page_path text NULL,
  referrer text NULL,
  element_id text NULL,
  element_label text NULL,
  element_role text NULL,
  module text NULL,
  target_kind text NULL,
  target_id text NULL,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  user_agent text NULL,
  device text NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.activity_events ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.activity_events REPLICA IDENTITY FULL;

-- ------------------------------------------------------------
-- Migration: 20260606181615_066ce9eb-094f-4ac7-bda8-e25caab5fe1a.sql
-- ------------------------------------------------------------
ALTER TABLE public.mcqs ALTER COLUMN option_c DROP NOT NULL;

ALTER TABLE public.mcqs ALTER COLUMN option_d DROP NOT NULL;

ALTER TABLE public.mcqs
  ADD COLUMN IF NOT EXISTS question_type text NOT NULL DEFAULT 'mcq'
    CHECK (question_type IN ('mcq','true_false'));

ALTER TABLE public.subjects ALTER COLUMN level DROP NOT NULL;

ALTER TABLE public.quizzes ALTER COLUMN level DROP NOT NULL;

ALTER TABLE public.quiz_sessions
  ADD COLUMN IF NOT EXISTS approved_by uuid,
  ADD COLUMN IF NOT EXISTS approved_at timestamptz,
  ADD COLUMN IF NOT EXISTS reject_reason text;

CREATE TABLE IF NOT EXISTS public.study_sessions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  module text NOT NULL DEFAULT 'dashboard',
  subject_id uuid,
  chapter_id uuid,
  started_at timestamptz NOT NULL DEFAULT now(),
  last_heartbeat_at timestamptz NOT NULL DEFAULT now(),
  ended_at timestamptz,
  duration_seconds integer NOT NULL DEFAULT 0,
  meta jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.study_sessions ENABLE ROW LEVEL SECURITY;

-- ------------------------------------------------------------
-- Migration: 20260606182353_82320132-0bdb-4172-957f-6772557f2ccf.sql
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.site_pages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  slug text NOT NULL UNIQUE,
  title text NOT NULL,
  is_home boolean NOT NULL DEFAULT false,
  seo_title text,
  seo_description text,
  sort_order integer NOT NULL DEFAULT 0,
  status text NOT NULL DEFAULT 'draft' CHECK (status IN ('draft','published','archived')),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.site_pages ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.site_page_sections (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  page_id uuid NOT NULL REFERENCES public.site_pages(id) ON DELETE CASCADE,
  kind text NOT NULL,
  content jsonb NOT NULL DEFAULT '{}'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  visible boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.site_page_sections ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.user_roles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role public.app_role NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id, role)
);

ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.homepage_sections (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  section_key text NOT NULL UNIQUE,
  position int NOT NULL DEFAULT 0,
  visible boolean NOT NULL DEFAULT true,
  draft_content jsonb NOT NULL DEFAULT '{}'::jsonb,
  published_content jsonb NOT NULL DEFAULT '{}'::jsonb,
  published_at timestamptz,
  updated_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.homepage_sections ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.site_settings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  key text NOT NULL UNIQUE,
  draft_value jsonb NOT NULL DEFAULT '{}'::jsonb,
  published_value jsonb NOT NULL DEFAULT '{}'::jsonb,
  published_at timestamptz,
  updated_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.site_settings ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.module_visibility (
  key text PRIMARY KEY,
  label text NOT NULL,
  hidden boolean NOT NULL DEFAULT false,
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.module_visibility ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.content_versions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  target_kind text NOT NULL CHECK (target_kind IN ('section','setting')),
  target_key text NOT NULL,
  snapshot jsonb NOT NULL DEFAULT '{}'::jsonb,
  label text,
  created_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.content_versions ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.media_assets (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  bucket text NOT NULL,
  path text NOT NULL,
  file_name text NOT NULL,
  mime_type text NOT NULL,
  size_bytes bigint NOT NULL DEFAULT 0,
  width int,
  height int,
  alt_text text,
  tags text[] NOT NULL DEFAULT '{}',
  uploaded_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.media_assets ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.user_sessions (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  active_session_id TEXT NOT NULL,
  user_agent TEXT,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.user_sessions ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.user_sessions REPLICA IDENTITY FULL;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text, avatar_url text, bio text, level text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

create table if not exists public.avatars (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  storage_path text not null, public_url text,
  created_at timestamptz not null default now()
);

alter table public.avatars enable row level security;

create table if not exists public.levels (
  code text primary key, name text not null, description text, color text, icon text,
  sort_order integer not null default 0,
  status public.content_status not null default 'published',
  updated_at timestamptz not null default now()
);

alter table public.levels enable row level security;

create table if not exists public.subjects (
  id uuid primary key default gen_random_uuid(),
  name text not null, slug text not null unique,
  level text not null references public.levels(code) on delete restrict,
  description text, color text, icon text,
  sort_order integer not null default 0,
  status public.content_status not null default 'published',
  updated_at timestamptz not null default now()
);

alter table public.subjects enable row level security;

create table if not exists public.chapters (
  id uuid primary key default gen_random_uuid(),
  subject_id uuid not null references public.subjects(id) on delete cascade,
  name text not null, slug text not null, description text,
  sort_order integer not null default 0,
  status public.content_status not null default 'published',
  updated_at timestamptz not null default now(),
  unique (subject_id, slug)
);

alter table public.chapters enable row level security;

create table if not exists public.mcqs (
  id uuid primary key default gen_random_uuid(),
  chapter_id uuid not null references public.chapters(id) on delete cascade,
  question text not null,
  option_a text not null, option_b text not null, option_c text not null, option_d text not null,
  correct_option public.mcq_option not null, explanation text,
  difficulty public.difficulty_level not null default 'medium',
  status public.content_status not null default 'published',
  tags text[] not null default '{}',
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.mcqs enable row level security;

create table if not exists public.mcq_bookmarks (
  user_id uuid not null references auth.users(id) on delete cascade,
  mcq_id uuid not null references public.mcqs(id) on delete cascade,
  chapter_id uuid references public.chapters(id) on delete set null,
  subject_id uuid references public.subjects(id) on delete set null,
  level text, created_at timestamptz not null default now(),
  primary key (user_id, mcq_id)
);

alter table public.mcq_bookmarks enable row level security;

create table if not exists public.mcq_wrong_questions (
  user_id uuid not null references auth.users(id) on delete cascade,
  mcq_id uuid not null references public.mcqs(id) on delete cascade,
  chapter_id uuid references public.chapters(id) on delete set null,
  subject_id uuid references public.subjects(id) on delete set null,
  level text,
  last_chosen_option public.mcq_option, correct_option public.mcq_option,
  retry_count integer not null default 0,
  mastered boolean not null default false,
  last_wrong_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  primary key (user_id, mcq_id)
);

alter table public.mcq_wrong_questions enable row level security;

create table if not exists public.mcq_delete_audit (
  id uuid primary key default gen_random_uuid(),
  admin_id uuid references auth.users(id) on delete set null,
  admin_name text, deleted_count integer not null default 0,
  scope text not null default 'selected',
  level text, subject_id uuid, chapter_id uuid,
  mcq_ids uuid[] not null default '{}',
  created_at timestamptz not null default now()
);

alter table public.mcq_delete_audit enable row level security;

create table if not exists public.quizzes (
  id uuid primary key default gen_random_uuid(),
  title text not null, description text, level text not null,
  subject_id uuid references public.subjects(id) on delete set null,
  chapter_id uuid references public.chapters(id) on delete set null,
  kind text not null default 'quiz' check (kind in ('quiz','mock')),
  status public.content_status not null default 'draft',
  difficulty public.difficulty_level not null default 'medium',
  total_questions integer not null default 10,
  duration_seconds integer not null default 900,
  starts_at timestamptz, ends_at timestamptz,
  is_public boolean not null default true,
  randomize_options boolean not null default false,
  randomize_questions boolean not null default true,
  passing_marks integer not null default 0,
  negative_marking numeric(4,2) not null default 0,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.quizzes enable row level security;

create table if not exists public.quiz_questions (
  id uuid primary key default gen_random_uuid(),
  quiz_id uuid not null references public.quizzes(id) on delete cascade,
  mcq_id uuid not null references public.mcqs(id) on delete cascade,
  position integer not null default 0,
  unique (quiz_id, mcq_id)
);

alter table public.quiz_questions enable row level security;

create table if not exists public.quiz_sessions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  chapter_id uuid references public.chapters(id) on delete set null,
  subject_id uuid references public.subjects(id) on delete set null,
  level text, mcq_ids uuid[] not null default '{}',
  status text not null default 'pending_review' check (status in ('pending_review','ready','in_progress','submitted','expired','rejected')),
  duration_seconds integer not null default 600,
  question_count integer not null default 0,
  started_at timestamptz, submitted_at timestamptz,
  answers jsonb not null default '{}',
  score integer, correct_count integer, wrong_count integer,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.quiz_sessions enable row level security;

create table if not exists public.exam_attempts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  quiz_id uuid references public.quizzes(id) on delete set null,
  subject_id uuid references public.subjects(id) on delete set null,
  chapter_id uuid references public.chapters(id) on delete set null,
  level text,
  kind text not null check (kind in ('mcq_practice','quiz','mock','custom_exam')),
  title text, attempt_number integer not null default 1,
  status text not null default 'completed' check (status in ('in_progress','completed','abandoned')),
  started_at timestamptz not null default now(), completed_at timestamptz,
  duration_seconds integer not null default 0,
  correct_count integer not null default 0,
  total_count integer not null default 0,
  score integer not null default 0,
  meta jsonb not null default '{}',
  created_at timestamptz not null default now()
);

alter table public.exam_attempts enable row level security;

create table if not exists public.attempt_answers (
  id uuid primary key default gen_random_uuid(),
  attempt_id uuid not null references public.exam_attempts(id) on delete cascade,
  mcq_id uuid not null references public.mcqs(id) on delete cascade,
  chosen_option public.mcq_option,
  is_correct boolean not null default false,
  time_spent_ms integer not null default 0
);

alter table public.attempt_answers enable row level security;

create table if not exists public.flash_cards (
  id uuid primary key default gen_random_uuid(),
  subject_id uuid references public.subjects(id) on delete set null,
  chapter_id uuid references public.chapters(id) on delete set null,
  level text not null default 'professional',
  front text not null, back text not null, formula text, image_url text,
  card_type text not null default 'concept' check (card_type in ('concept','formula','diagram','timeline','definition','other')),
  tags text[] not null default '{}',
  status public.content_status not null default 'draft',
  is_hidden boolean not null default false,
  scheduled_at timestamptz, view_count integer not null default 0,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.flash_cards enable row level security;

create table if not exists public.flash_card_visibility (
  id integer primary key default 1,
  section_hidden boolean not null default false,
  hidden_levels text[] not null default '{}',
  hidden_subject_ids uuid[] not null default '{}',
  hidden_chapter_ids uuid[] not null default '{}',
  updated_at timestamptz not null default now(),
  constraint flash_card_visibility_singleton check (id = 1)
);

alter table public.flash_card_visibility enable row level security;

create table if not exists public.short_notes (
  id uuid primary key default gen_random_uuid(),
  title text not null, summary text, level text not null default 'professional',
  subject_id uuid references public.subjects(id) on delete set null,
  chapter_id uuid references public.chapters(id) on delete set null,
  kind text not null default 'text' check (kind in ('text','pdf','doc')),
  body text, file_url text, file_name text, file_size_bytes bigint,
  tags text[] not null default '{}',
  status public.content_status not null default 'draft',
  is_hidden boolean not null default false,
  scheduled_at timestamptz,
  view_count integer not null default 0,
  download_count integer not null default 0,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.short_notes enable row level security;

create table if not exists public.short_notes_visibility (
  id integer primary key default 1,
  section_hidden boolean not null default false,
  hidden_levels text[] not null default '{}',
  hidden_subject_ids uuid[] not null default '{}',
  hidden_chapter_ids uuid[] not null default '{}',
  updated_at timestamptz not null default now(),
  constraint short_notes_visibility_singleton check (id = 1)
);

alter table public.short_notes_visibility enable row level security;

create table if not exists public.question_bank_resources (
  id uuid primary key default gen_random_uuid(),
  title text not null, summary text, level text not null default 'professional',
  subject_id uuid references public.subjects(id) on delete set null,
  chapter_id uuid references public.chapters(id) on delete set null,
  kind text not null default 'text' check (kind in ('text','pdf','doc')),
  resource_type text not null default 'important' check (resource_type in ('important','pyq','model','notes','text')),
  body text, file_url text, file_name text, file_size_bytes bigint,
  question_count integer not null default 0,
  tags text[] not null default '{}',
  status public.content_status not null default 'draft',
  is_hidden boolean not null default false,
  scheduled_at timestamptz,
  view_count integer not null default 0,
  download_count integer not null default 0,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.question_bank_resources enable row level security;

create table if not exists public.question_bank_visibility (
  id integer primary key default 1,
  section_hidden boolean not null default false,
  hidden_levels text[] not null default '{}',
  hidden_subject_ids uuid[] not null default '{}',
  hidden_chapter_ids uuid[] not null default '{}',
  updated_at timestamptz not null default now(),
  constraint question_bank_visibility_singleton check (id = 1)
);

alter table public.question_bank_visibility enable row level security;

create table if not exists public.video_classes (
  id uuid primary key default gen_random_uuid(),
  title text not null, description text, level text not null default 'professional',
  subject_id uuid references public.subjects(id) on delete set null,
  chapter_id uuid references public.chapters(id) on delete set null,
  instructor text,
  kind text not null default 'youtube' check (kind in ('youtube','playlist','upload')),
  youtube_url text, youtube_video_id text, youtube_playlist_id text,
  thumbnail_url text, duration_seconds integer not null default 0,
  playlist_key text, position integer not null default 0,
  tags text[] not null default '{}',
  status public.content_status not null default 'draft',
  is_hidden boolean not null default false,
  is_featured boolean not null default false,
  scheduled_at timestamptz,
  view_count integer not null default 0,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.video_classes enable row level security;

create table if not exists public.video_class_visibility (
  id integer primary key default 1,
  section_hidden boolean not null default false,
  hidden_levels text[] not null default '{}',
  hidden_subject_ids uuid[] not null default '{}',
  hidden_chapter_ids uuid[] not null default '{}',
  updated_at timestamptz not null default now(),
  constraint video_class_visibility_singleton check (id = 1)
);

alter table public.video_class_visibility enable row level security;

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  title text not null, body text not null default '', link text,
  type text not null default 'in_app' check (type in ('announcement','push','email','in_app')),
  priority text not null default 'medium' check (priority in ('low','medium','high','critical')),
  audience text not null default 'all' check (audience in ('all','level','subject','role','users')),
  audience_level text, audience_subject_id uuid,
  audience_role text check (audience_role in ('admin','moderator','student')),
  audience_user_ids uuid[] not null default '{}',
  scheduled_at timestamptz,
  status text not null default 'draft' check (status in ('draft','scheduled','sent','failed','paused')),
  sent_at timestamptz, delivered_count integer not null default 0,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.notifications enable row level security;

create table if not exists public.notification_reads (
  notification_id uuid not null references public.notifications(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (notification_id, user_id)
);

alter table public.notification_reads enable row level security;

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS status text NOT NULL DEFAULT 'active'
    CHECK (status IN ('active','suspended','pending')),
  ADD COLUMN IF NOT EXISTS referral_source text;

ALTER TABLE public.notifications
  ADD COLUMN IF NOT EXISTS open_count integer NOT NULL DEFAULT 0;

ALTER TABLE public.mcq_bookmarks DROP CONSTRAINT IF EXISTS mcq_bookmarks_pkey;

ALTER TABLE public.mcq_bookmarks
  ADD COLUMN IF NOT EXISTS id uuid NOT NULL DEFAULT gen_random_uuid();

ALTER TABLE public.mcq_bookmarks ADD PRIMARY KEY (id);

DO $$ BEGIN
  ALTER TABLE public.mcq_bookmarks ADD CONSTRAINT mcq_bookmarks_user_mcq_key UNIQUE (user_id, mcq_id);
EXCEPTION WHEN duplicate_table THEN NULL; WHEN duplicate_object THEN NULL; END $$;

ALTER TABLE public.mcq_wrong_questions DROP CONSTRAINT IF EXISTS mcq_wrong_questions_pkey;

ALTER TABLE public.mcq_wrong_questions
  ADD COLUMN IF NOT EXISTS id uuid NOT NULL DEFAULT gen_random_uuid();

ALTER TABLE public.mcq_wrong_questions ADD PRIMARY KEY (id);

DO $$ BEGIN
  ALTER TABLE public.mcq_wrong_questions ADD CONSTRAINT mcq_wrong_questions_user_mcq_key UNIQUE (user_id, mcq_id);
EXCEPTION WHEN duplicate_table THEN NULL; WHEN duplicate_object THEN NULL; END $$;

ALTER TABLE public.subjects ALTER COLUMN level DROP NOT NULL;

ALTER TABLE public.quizzes ALTER COLUMN level DROP NOT NULL;

ALTER TABLE public.exam_attempts ALTER COLUMN kind DROP NOT NULL;

ALTER TABLE public.subjects ALTER COLUMN level SET DEFAULT '';

ALTER TABLE public.subjects ALTER COLUMN level SET NOT NULL;

ALTER TABLE public.quizzes ALTER COLUMN level SET DEFAULT '';

ALTER TABLE public.quizzes ALTER COLUMN level SET NOT NULL;

ALTER TABLE public.exam_attempts ALTER COLUMN kind SET DEFAULT 'mcq_practice';

ALTER TABLE public.exam_attempts ALTER COLUMN kind SET NOT NULL;

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS deleted_at timestamptz,
  ADD COLUMN IF NOT EXISTS last_login_at timestamptz,
  ADD COLUMN IF NOT EXISTS total_login_count integer NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS total_usage_seconds bigint NOT NULL DEFAULT 0;

CREATE TABLE IF NOT EXISTS public.user_login_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  login_at timestamptz NOT NULL DEFAULT now(),
  logout_at timestamptz,
  duration_seconds integer,
  user_agent text,
  device text,
  browser text,
  ip text,
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.user_login_events ENABLE ROW LEVEL SECURITY;

-- ------------------------------------------------------------
-- Migration: 20260607143518_1a3450ee-73db-4e60-9446-ba8a0205d908.sql
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.activity_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NULL,
  event_type text NOT NULL,
  page_url text NULL,
  page_path text NULL,
  referrer text NULL,
  element_id text NULL,
  element_label text NULL,
  element_role text NULL,
  module text NULL,
  target_kind text NULL,
  target_id text NULL,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  user_agent text NULL,
  device text NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.activity_events ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.activity_events REPLICA IDENTITY FULL;

-- ------------------------------------------------------------
-- Migration: 20260607143810_cf1591d7-21b0-4010-b4d1-ff2b35fcb649.sql
-- ------------------------------------------------------------

ALTER TABLE public.mcqs ALTER COLUMN option_c DROP NOT NULL;

ALTER TABLE public.mcqs ALTER COLUMN option_d DROP NOT NULL;

ALTER TABLE public.mcqs
  ADD COLUMN IF NOT EXISTS question_type text NOT NULL DEFAULT 'mcq'
    CHECK (question_type IN ('mcq','true_false'));

ALTER TABLE public.subjects ALTER COLUMN level DROP NOT NULL;

ALTER TABLE public.quizzes ALTER COLUMN level DROP NOT NULL;

ALTER TABLE public.quiz_sessions
  ADD COLUMN IF NOT EXISTS approved_by uuid,
  ADD COLUMN IF NOT EXISTS approved_at timestamptz,
  ADD COLUMN IF NOT EXISTS reject_reason text;

CREATE TABLE IF NOT EXISTS public.study_sessions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  module text NOT NULL DEFAULT 'dashboard',
  subject_id uuid,
  chapter_id uuid,
  started_at timestamptz NOT NULL DEFAULT now(),
  last_heartbeat_at timestamptz NOT NULL DEFAULT now(),
  ended_at timestamptz,
  duration_seconds integer NOT NULL DEFAULT 0,
  meta jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.study_sessions ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.site_pages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  slug text NOT NULL UNIQUE,
  title text NOT NULL,
  is_home boolean NOT NULL DEFAULT false,
  seo_title text,
  seo_description text,
  sort_order integer NOT NULL DEFAULT 0,
  status text NOT NULL DEFAULT 'draft' CHECK (status IN ('draft','published','archived')),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.site_pages ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.site_page_sections (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  page_id uuid NOT NULL REFERENCES public.site_pages(id) ON DELETE CASCADE,
  kind text NOT NULL,
  content jsonb NOT NULL DEFAULT '{}'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  visible boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.site_page_sections ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- PROFILES
-- ============================================================
CREATE TABLE IF NOT EXISTS public.profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  display_name text,
  avatar_url text,
  bio text,
  level text NOT NULL DEFAULT 'professional',
  status public.profile_status NOT NULL DEFAULT 'active',
  referral_source text,
  phone text,
  last_login_at timestamptz,
  total_login_count integer NOT NULL DEFAULT 0,
  total_usage_seconds bigint NOT NULL DEFAULT 0,
  deleted_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- USER ROLES + has_role (no recursion)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.user_roles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role public.app_role NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(user_id, role)
);

ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- ACADEMIC: LEVELS, SUBJECTS, CHAPTERS
-- ============================================================
CREATE TABLE IF NOT EXISTS public.levels (
  code text PRIMARY KEY,
  name text NOT NULL,
  description text,
  color text,
  icon text,
  sort_order integer NOT NULL DEFAULT 0,
  status public.content_status NOT NULL DEFAULT 'published',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.levels ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.subjects (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  slug text NOT NULL UNIQUE,
  level text NOT NULL DEFAULT 'professional' REFERENCES public.levels(code) ON UPDATE CASCADE,
  description text,
  color text,
  icon text,
  sort_order integer NOT NULL DEFAULT 0,
  status public.content_status NOT NULL DEFAULT 'published',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.subjects ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.chapters (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  subject_id uuid NOT NULL REFERENCES public.subjects(id) ON DELETE CASCADE,
  name text NOT NULL,
  slug text NOT NULL,
  description text,
  sort_order integer NOT NULL DEFAULT 0,
  status public.content_status NOT NULL DEFAULT 'published',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(subject_id, slug)
);

ALTER TABLE public.chapters ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- MCQs
-- ============================================================
CREATE TABLE IF NOT EXISTS public.mcqs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  chapter_id uuid REFERENCES public.chapters(id) ON DELETE SET NULL,
  question text NOT NULL,
  question_type public.question_type NOT NULL DEFAULT 'mcq',
  option_a text NOT NULL,
  option_b text NOT NULL,
  option_c text,
  option_d text,
  correct_option public.mcq_option NOT NULL,
  explanation text,
  difficulty public.difficulty NOT NULL DEFAULT 'medium',
  status public.content_status NOT NULL DEFAULT 'published',
  tags text[] NOT NULL DEFAULT '{}',
  created_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.mcqs ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.mcq_delete_audit (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  mcq_id uuid NOT NULL,
  snapshot jsonb NOT NULL,
  deleted_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  deleted_by_name text,
  reason text,
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.mcq_delete_audit ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- QUIZZES + QUIZ QUESTIONS (also used for "mock" via kind='mock')
-- ============================================================
CREATE TABLE IF NOT EXISTS public.quizzes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  description text,
  level text NOT NULL DEFAULT 'professional',
  subject_id uuid REFERENCES public.subjects(id) ON DELETE SET NULL,
  chapter_id uuid REFERENCES public.chapters(id) ON DELETE SET NULL,
  kind public.quiz_kind NOT NULL DEFAULT 'quiz',
  status public.content_status NOT NULL DEFAULT 'draft',
  difficulty public.difficulty NOT NULL DEFAULT 'medium',
  total_questions integer NOT NULL DEFAULT 10,
  duration_seconds integer NOT NULL DEFAULT 900,
  starts_at timestamptz,
  ends_at timestamptz,
  is_public boolean NOT NULL DEFAULT true,
  randomize_options boolean NOT NULL DEFAULT false,
  randomize_questions boolean NOT NULL DEFAULT true,
  passing_marks integer NOT NULL DEFAULT 0,
  negative_marking numeric NOT NULL DEFAULT 0,
  created_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.quizzes ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.quiz_questions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  quiz_id uuid NOT NULL REFERENCES public.quizzes(id) ON DELETE CASCADE,
  mcq_id uuid NOT NULL REFERENCES public.mcqs(id) ON DELETE CASCADE,
  position integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(quiz_id, mcq_id)
);

ALTER TABLE public.quiz_questions ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- ATTEMPTS
-- ============================================================
CREATE TABLE IF NOT EXISTS public.exam_attempts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  quiz_id uuid REFERENCES public.quizzes(id) ON DELETE SET NULL,
  kind public.attempt_kind NOT NULL DEFAULT 'practice',
  subject_id uuid REFERENCES public.subjects(id) ON DELETE SET NULL,
  chapter_id uuid REFERENCES public.chapters(id) ON DELETE SET NULL,
  level text,
  title text,
  attempt_number integer NOT NULL DEFAULT 1,
  status public.attempt_status NOT NULL DEFAULT 'completed',
  started_at timestamptz NOT NULL DEFAULT now(),
  completed_at timestamptz,
  duration_seconds integer NOT NULL DEFAULT 0,
  correct_count integer NOT NULL DEFAULT 0,
  total_count integer NOT NULL DEFAULT 0,
  score numeric NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.exam_attempts ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.attempt_answers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  attempt_id uuid NOT NULL REFERENCES public.exam_attempts(id) ON DELETE CASCADE,
  mcq_id uuid NOT NULL REFERENCES public.mcqs(id) ON DELETE CASCADE,
  chosen_option public.mcq_option,
  is_correct boolean NOT NULL DEFAULT false,
  time_spent_seconds integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.attempt_answers ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.mcq_bookmarks (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  mcq_id uuid NOT NULL REFERENCES public.mcqs(id) ON DELETE CASCADE,
  chapter_id uuid REFERENCES public.chapters(id) ON DELETE SET NULL,
  subject_id uuid REFERENCES public.subjects(id) ON DELETE SET NULL,
  level text,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(user_id, mcq_id)
);

ALTER TABLE public.mcq_bookmarks ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.mcq_wrong_questions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  mcq_id uuid NOT NULL REFERENCES public.mcqs(id) ON DELETE CASCADE,
  chapter_id uuid REFERENCES public.chapters(id) ON DELETE SET NULL,
  subject_id uuid REFERENCES public.subjects(id) ON DELETE SET NULL,
  level text,
  last_chosen_option public.mcq_option,
  correct_option public.mcq_option,
  retry_count integer NOT NULL DEFAULT 0,
  mastered boolean NOT NULL DEFAULT false,
  last_wrong_at timestamptz NOT NULL DEFAULT now(),
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(user_id, mcq_id)
);

ALTER TABLE public.mcq_wrong_questions ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- FLASH CARDS / SHORT NOTES / QUESTION BANK / VIDEO CLASSES
-- ============================================================
CREATE TABLE IF NOT EXISTS public.flash_cards (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  subject_id uuid REFERENCES public.subjects(id) ON DELETE SET NULL,
  chapter_id uuid REFERENCES public.chapters(id) ON DELETE SET NULL,
  level text NOT NULL DEFAULT 'professional',
  front text NOT NULL,
  back text NOT NULL,
  formula text,
  image_url text,
  card_type public.card_type NOT NULL DEFAULT 'concept',
  tags text[] NOT NULL DEFAULT '{}',
  status public.content_status NOT NULL DEFAULT 'draft',
  is_hidden boolean NOT NULL DEFAULT false,
  view_count integer NOT NULL DEFAULT 0,
  scheduled_at timestamptz,
  created_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.flash_cards ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.short_notes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  summary text,
  level text NOT NULL DEFAULT 'professional',
  subject_id uuid REFERENCES public.subjects(id) ON DELETE SET NULL,
  chapter_id uuid REFERENCES public.chapters(id) ON DELETE SET NULL,
  kind public.note_kind NOT NULL DEFAULT 'text',
  body text,
  file_url text,
  file_name text,
  file_size_bytes bigint,
  tags text[] NOT NULL DEFAULT '{}',
  status public.content_status NOT NULL DEFAULT 'draft',
  is_hidden boolean NOT NULL DEFAULT false,
  view_count integer NOT NULL DEFAULT 0,
  download_count integer NOT NULL DEFAULT 0,
  scheduled_at timestamptz,
  created_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.short_notes ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.question_bank_resources (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  summary text,
  level text NOT NULL DEFAULT 'professional',
  subject_id uuid REFERENCES public.subjects(id) ON DELETE SET NULL,
  chapter_id uuid REFERENCES public.chapters(id) ON DELETE SET NULL,
  kind public.note_kind NOT NULL DEFAULT 'text',
  resource_type public.qb_resource_type NOT NULL DEFAULT 'important',
  body text,
  file_url text,
  file_name text,
  file_size_bytes bigint,
  question_count integer NOT NULL DEFAULT 0,
  tags text[] NOT NULL DEFAULT '{}',
  status public.content_status NOT NULL DEFAULT 'draft',
  is_hidden boolean NOT NULL DEFAULT false,
  view_count integer NOT NULL DEFAULT 0,
  download_count integer NOT NULL DEFAULT 0,
  scheduled_at timestamptz,
  created_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.question_bank_resources ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.video_classes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  description text,
  level text NOT NULL DEFAULT 'professional',
  subject_id uuid REFERENCES public.subjects(id) ON DELETE SET NULL,
  chapter_id uuid REFERENCES public.chapters(id) ON DELETE SET NULL,
  instructor text,
  kind public.video_kind NOT NULL DEFAULT 'youtube',
  youtube_url text,
  youtube_video_id text,
  youtube_playlist_id text,
  thumbnail_url text,
  duration_seconds integer NOT NULL DEFAULT 0,
  playlist_key text,
  position integer NOT NULL DEFAULT 0,
  tags text[] NOT NULL DEFAULT '{}',
  status public.content_status NOT NULL DEFAULT 'draft',
  is_hidden boolean NOT NULL DEFAULT false,
  is_featured boolean NOT NULL DEFAULT false,
  view_count integer NOT NULL DEFAULT 0,
  scheduled_at timestamptz,
  created_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.video_classes ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- SECTION VISIBILITY (single-row config tables)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.module_visibility (
  key text PRIMARY KEY,
  label text NOT NULL,
  hidden boolean NOT NULL DEFAULT false,
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.module_visibility ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.flash_card_visibility (
  id integer PRIMARY KEY DEFAULT 1,
  section_hidden boolean NOT NULL DEFAULT false,
  hidden_levels text[] NOT NULL DEFAULT '{}',
  hidden_subject_ids uuid[] NOT NULL DEFAULT '{}',
  hidden_chapter_ids uuid[] NOT NULL DEFAULT '{}',
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT single_row CHECK (id = 1)
);

ALTER TABLE public.flash_card_visibility ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.short_notes_visibility (LIKE public.flash_card_visibility INCLUDING ALL);

ALTER TABLE public.short_notes_visibility ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.question_bank_visibility (LIKE public.flash_card_visibility INCLUDING ALL);

ALTER TABLE public.question_bank_visibility ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.video_class_visibility (LIKE public.flash_card_visibility INCLUDING ALL);

ALTER TABLE public.video_class_visibility ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- NOTIFICATIONS
-- ============================================================
CREATE TABLE IF NOT EXISTS public.notifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  body text NOT NULL DEFAULT '',
  link text,
  type public.notification_type NOT NULL DEFAULT 'in_app',
  priority public.notification_priority NOT NULL DEFAULT 'medium',
  status public.notification_status NOT NULL DEFAULT 'draft',
  audience public.notification_audience NOT NULL DEFAULT 'all',
  audience_level text,
  audience_subject_id uuid REFERENCES public.subjects(id) ON DELETE SET NULL,
  audience_role public.app_role,
  audience_user_ids uuid[] NOT NULL DEFAULT '{}',
  scheduled_at timestamptz,
  sent_at timestamptz,
  recipients_count integer NOT NULL DEFAULT 0,
  read_count integer NOT NULL DEFAULT 0,
  click_count integer NOT NULL DEFAULT 0,
  created_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.notification_reads (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  notification_id uuid NOT NULL REFERENCES public.notifications(id) ON DELETE CASCADE,
  read_at timestamptz NOT NULL DEFAULT now(),
  clicked_at timestamptz,
  UNIQUE(user_id, notification_id)
);

ALTER TABLE public.notification_reads ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- ACTIVITY / SESSIONS / LOGINS
-- ============================================================
CREATE TABLE IF NOT EXISTS public.activity_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  event_type text NOT NULL,
  module text,
  page_path text,
  element_label text,
  target_id text,
  device text,
  browser text,
  user_agent text,
  ip text,
  meta jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.activity_events ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.user_login_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  login_at timestamptz NOT NULL DEFAULT now(),
  logout_at timestamptz,
  duration_seconds integer,
  user_agent text,
  browser text,
  device text,
  ip text
);

ALTER TABLE public.user_login_events ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.user_sessions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  session_token text,
  ip text,
  user_agent text,
  is_active boolean NOT NULL DEFAULT true,
  started_at timestamptz NOT NULL DEFAULT now(),
  last_seen_at timestamptz NOT NULL DEFAULT now(),
  ended_at timestamptz
);

ALTER TABLE public.user_sessions ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.study_sessions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  module text NOT NULL,
  duration_seconds integer NOT NULL DEFAULT 0,
  last_heartbeat_at timestamptz NOT NULL DEFAULT now(),
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.study_sessions ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- SITE MANAGEMENT
-- ============================================================
CREATE TABLE IF NOT EXISTS public.site_settings (
  key text PRIMARY KEY,
  value jsonb NOT NULL DEFAULT '{}'::jsonb,
  draft_value jsonb,
  label text,
  updated_at timestamptz NOT NULL DEFAULT now(),
  updated_by uuid REFERENCES auth.users(id) ON DELETE SET NULL
);

ALTER TABLE public.site_settings ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.site_pages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  slug text NOT NULL UNIQUE,
  title text NOT NULL,
  description text,
  status public.content_status NOT NULL DEFAULT 'published',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.site_pages ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.site_page_sections (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  page_id uuid REFERENCES public.site_pages(id) ON DELETE CASCADE,
  section_key text NOT NULL,
  content jsonb NOT NULL DEFAULT '{}'::jsonb,
  draft_content jsonb,
  position integer NOT NULL DEFAULT 0,
  visible boolean NOT NULL DEFAULT true,
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.site_page_sections ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.homepage_sections (
  key text PRIMARY KEY,
  label text NOT NULL,
  content jsonb NOT NULL DEFAULT '{}'::jsonb,
  draft_content jsonb,
  position integer NOT NULL DEFAULT 0,
  visible boolean NOT NULL DEFAULT true,
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.homepage_sections ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.media_assets (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  bucket text NOT NULL,
  path text NOT NULL,
  file_name text,
  mime_type text,
  size_bytes bigint,
  width integer,
  height integer,
  alt_text text,
  tags text[] NOT NULL DEFAULT '{}',
  uploaded_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.media_assets ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.content_versions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  target_kind text NOT NULL,
  target_key text NOT NULL,
  snapshot jsonb NOT NULL,
  label text,
  created_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.content_versions ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.avatars (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  url text NOT NULL,
  label text,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.avatars ENABLE ROW LEVEL SECURITY;

-- Column additions
ALTER TABLE public.activity_events ADD COLUMN IF NOT EXISTS target_kind text;

ALTER TABLE public.attempt_answers ADD COLUMN IF NOT EXISTS time_spent_ms integer NOT NULL DEFAULT 0;

ALTER TABLE public.study_sessions ADD COLUMN IF NOT EXISTS started_at timestamptz NOT NULL DEFAULT now();

ALTER TABLE public.notifications ADD COLUMN IF NOT EXISTS delivered_count integer NOT NULL DEFAULT 0;

ALTER TABLE public.notifications ADD COLUMN IF NOT EXISTS open_count integer NOT NULL DEFAULT 0;

CREATE TABLE IF NOT EXISTS public.user_roles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role public.app_role NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id, role)
);

ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.homepage_sections (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  section_key text NOT NULL UNIQUE,
  position int NOT NULL DEFAULT 0,
  visible boolean NOT NULL DEFAULT true,
  draft_content jsonb NOT NULL DEFAULT '{}'::jsonb,
  published_content jsonb NOT NULL DEFAULT '{}'::jsonb,
  published_at timestamptz,
  updated_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.homepage_sections ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.site_settings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  key text NOT NULL UNIQUE,
  draft_value jsonb NOT NULL DEFAULT '{}'::jsonb,
  published_value jsonb NOT NULL DEFAULT '{}'::jsonb,
  published_at timestamptz,
  updated_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.site_settings ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.module_visibility (
  key text PRIMARY KEY,
  label text NOT NULL,
  hidden boolean NOT NULL DEFAULT false,
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.module_visibility ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.content_versions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  target_kind text NOT NULL CHECK (target_kind IN ('section','setting')),
  target_key text NOT NULL,
  snapshot jsonb NOT NULL DEFAULT '{}'::jsonb,
  label text,
  created_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.content_versions ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.media_assets (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  bucket text NOT NULL,
  path text NOT NULL,
  file_name text NOT NULL,
  mime_type text NOT NULL,
  size_bytes bigint NOT NULL DEFAULT 0,
  width int,
  height int,
  alt_text text,
  tags text[] NOT NULL DEFAULT '{}',
  uploaded_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.media_assets ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.user_sessions (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  active_session_id TEXT NOT NULL,
  user_agent TEXT,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.user_sessions ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.user_sessions REPLICA IDENTITY FULL;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text, avatar_url text, bio text, level text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

create table if not exists public.avatars (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  storage_path text not null, public_url text,
  created_at timestamptz not null default now()
);

alter table public.avatars enable row level security;

create table if not exists public.levels (
  code text primary key, name text not null, description text, color text, icon text,
  sort_order integer not null default 0,
  status public.content_status not null default 'published',
  updated_at timestamptz not null default now()
);

alter table public.levels enable row level security;

create table if not exists public.subjects (
  id uuid primary key default gen_random_uuid(),
  name text not null, slug text not null unique,
  level text not null references public.levels(code) on delete restrict,
  description text, color text, icon text,
  sort_order integer not null default 0,
  status public.content_status not null default 'published',
  updated_at timestamptz not null default now()
);

alter table public.subjects enable row level security;

create table if not exists public.chapters (
  id uuid primary key default gen_random_uuid(),
  subject_id uuid not null references public.subjects(id) on delete cascade,
  name text not null, slug text not null, description text,
  sort_order integer not null default 0,
  status public.content_status not null default 'published',
  updated_at timestamptz not null default now(),
  unique (subject_id, slug)
);

alter table public.chapters enable row level security;

create table if not exists public.mcqs (
  id uuid primary key default gen_random_uuid(),
  chapter_id uuid not null references public.chapters(id) on delete cascade,
  question text not null,
  option_a text not null, option_b text not null, option_c text not null, option_d text not null,
  correct_option public.mcq_option not null, explanation text,
  difficulty public.difficulty_level not null default 'medium',
  status public.content_status not null default 'published',
  tags text[] not null default '{}',
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.mcqs enable row level security;

create table if not exists public.mcq_bookmarks (
  user_id uuid not null references auth.users(id) on delete cascade,
  mcq_id uuid not null references public.mcqs(id) on delete cascade,
  chapter_id uuid references public.chapters(id) on delete set null,
  subject_id uuid references public.subjects(id) on delete set null,
  level text, created_at timestamptz not null default now(),
  primary key (user_id, mcq_id)
);

alter table public.mcq_bookmarks enable row level security;

create table if not exists public.mcq_wrong_questions (
  user_id uuid not null references auth.users(id) on delete cascade,
  mcq_id uuid not null references public.mcqs(id) on delete cascade,
  chapter_id uuid references public.chapters(id) on delete set null,
  subject_id uuid references public.subjects(id) on delete set null,
  level text,
  last_chosen_option public.mcq_option, correct_option public.mcq_option,
  retry_count integer not null default 0,
  mastered boolean not null default false,
  last_wrong_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  primary key (user_id, mcq_id)
);

alter table public.mcq_wrong_questions enable row level security;

create table if not exists public.mcq_delete_audit (
  id uuid primary key default gen_random_uuid(),
  admin_id uuid references auth.users(id) on delete set null,
  admin_name text, deleted_count integer not null default 0,
  scope text not null default 'selected',
  level text, subject_id uuid, chapter_id uuid,
  mcq_ids uuid[] not null default '{}',
  created_at timestamptz not null default now()
);

alter table public.mcq_delete_audit enable row level security;

create table if not exists public.quizzes (
  id uuid primary key default gen_random_uuid(),
  title text not null, description text, level text not null,
  subject_id uuid references public.subjects(id) on delete set null,
  chapter_id uuid references public.chapters(id) on delete set null,
  kind text not null default 'quiz' check (kind in ('quiz','mock')),
  status public.content_status not null default 'draft',
  difficulty public.difficulty_level not null default 'medium',
  total_questions integer not null default 10,
  duration_seconds integer not null default 900,
  starts_at timestamptz, ends_at timestamptz,
  is_public boolean not null default true,
  randomize_options boolean not null default false,
  randomize_questions boolean not null default true,
  passing_marks integer not null default 0,
  negative_marking numeric(4,2) not null default 0,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.quizzes enable row level security;

create table if not exists public.quiz_questions (
  id uuid primary key default gen_random_uuid(),
  quiz_id uuid not null references public.quizzes(id) on delete cascade,
  mcq_id uuid not null references public.mcqs(id) on delete cascade,
  position integer not null default 0,
  unique (quiz_id, mcq_id)
);

alter table public.quiz_questions enable row level security;

create table if not exists public.quiz_sessions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  chapter_id uuid references public.chapters(id) on delete set null,
  subject_id uuid references public.subjects(id) on delete set null,
  level text, mcq_ids uuid[] not null default '{}',
  status text not null default 'pending_review' check (status in ('pending_review','ready','in_progress','submitted','expired','rejected')),
  duration_seconds integer not null default 600,
  question_count integer not null default 0,
  started_at timestamptz, submitted_at timestamptz,
  answers jsonb not null default '{}',
  score integer, correct_count integer, wrong_count integer,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.quiz_sessions enable row level security;

create table if not exists public.exam_attempts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  quiz_id uuid references public.quizzes(id) on delete set null,
  subject_id uuid references public.subjects(id) on delete set null,
  chapter_id uuid references public.chapters(id) on delete set null,
  level text,
  kind text not null check (kind in ('mcq_practice','quiz','mock','custom_exam')),
  title text, attempt_number integer not null default 1,
  status text not null default 'completed' check (status in ('in_progress','completed','abandoned')),
  started_at timestamptz not null default now(), completed_at timestamptz,
  duration_seconds integer not null default 0,
  correct_count integer not null default 0,
  total_count integer not null default 0,
  score integer not null default 0,
  meta jsonb not null default '{}',
  created_at timestamptz not null default now()
);

alter table public.exam_attempts enable row level security;

create table if not exists public.attempt_answers (
  id uuid primary key default gen_random_uuid(),
  attempt_id uuid not null references public.exam_attempts(id) on delete cascade,
  mcq_id uuid not null references public.mcqs(id) on delete cascade,
  chosen_option public.mcq_option,
  is_correct boolean not null default false,
  time_spent_ms integer not null default 0
);

alter table public.attempt_answers enable row level security;

create table if not exists public.flash_cards (
  id uuid primary key default gen_random_uuid(),
  subject_id uuid references public.subjects(id) on delete set null,
  chapter_id uuid references public.chapters(id) on delete set null,
  level text not null default 'professional',
  front text not null, back text not null, formula text, image_url text,
  card_type text not null default 'concept' check (card_type in ('concept','formula','diagram','timeline','definition','other')),
  tags text[] not null default '{}',
  status public.content_status not null default 'draft',
  is_hidden boolean not null default false,
  scheduled_at timestamptz, view_count integer not null default 0,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.flash_cards enable row level security;

create table if not exists public.flash_card_visibility (
  id integer primary key default 1,
  section_hidden boolean not null default false,
  hidden_levels text[] not null default '{}',
  hidden_subject_ids uuid[] not null default '{}',
  hidden_chapter_ids uuid[] not null default '{}',
  updated_at timestamptz not null default now(),
  constraint flash_card_visibility_singleton check (id = 1)
);

alter table public.flash_card_visibility enable row level security;

create table if not exists public.short_notes (
  id uuid primary key default gen_random_uuid(),
  title text not null, summary text, level text not null default 'professional',
  subject_id uuid references public.subjects(id) on delete set null,
  chapter_id uuid references public.chapters(id) on delete set null,
  kind text not null default 'text' check (kind in ('text','pdf','doc')),
  body text, file_url text, file_name text, file_size_bytes bigint,
  tags text[] not null default '{}',
  status public.content_status not null default 'draft',
  is_hidden boolean not null default false,
  scheduled_at timestamptz,
  view_count integer not null default 0,
  download_count integer not null default 0,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.short_notes enable row level security;

create table if not exists public.short_notes_visibility (
  id integer primary key default 1,
  section_hidden boolean not null default false,
  hidden_levels text[] not null default '{}',
  hidden_subject_ids uuid[] not null default '{}',
  hidden_chapter_ids uuid[] not null default '{}',
  updated_at timestamptz not null default now(),
  constraint short_notes_visibility_singleton check (id = 1)
);

alter table public.short_notes_visibility enable row level security;

create table if not exists public.question_bank_resources (
  id uuid primary key default gen_random_uuid(),
  title text not null, summary text, level text not null default 'professional',
  subject_id uuid references public.subjects(id) on delete set null,
  chapter_id uuid references public.chapters(id) on delete set null,
  kind text not null default 'text' check (kind in ('text','pdf','doc')),
  resource_type text not null default 'important' check (resource_type in ('important','pyq','model','notes','text')),
  body text, file_url text, file_name text, file_size_bytes bigint,
  question_count integer not null default 0,
  tags text[] not null default '{}',
  status public.content_status not null default 'draft',
  is_hidden boolean not null default false,
  scheduled_at timestamptz,
  view_count integer not null default 0,
  download_count integer not null default 0,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.question_bank_resources enable row level security;

create table if not exists public.question_bank_visibility (
  id integer primary key default 1,
  section_hidden boolean not null default false,
  hidden_levels text[] not null default '{}',
  hidden_subject_ids uuid[] not null default '{}',
  hidden_chapter_ids uuid[] not null default '{}',
  updated_at timestamptz not null default now(),
  constraint question_bank_visibility_singleton check (id = 1)
);

alter table public.question_bank_visibility enable row level security;

create table if not exists public.video_classes (
  id uuid primary key default gen_random_uuid(),
  title text not null, description text, level text not null default 'professional',
  subject_id uuid references public.subjects(id) on delete set null,
  chapter_id uuid references public.chapters(id) on delete set null,
  instructor text,
  kind text not null default 'youtube' check (kind in ('youtube','playlist','upload')),
  youtube_url text, youtube_video_id text, youtube_playlist_id text,
  thumbnail_url text, duration_seconds integer not null default 0,
  playlist_key text, position integer not null default 0,
  tags text[] not null default '{}',
  status public.content_status not null default 'draft',
  is_hidden boolean not null default false,
  is_featured boolean not null default false,
  scheduled_at timestamptz,
  view_count integer not null default 0,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.video_classes enable row level security;

create table if not exists public.video_class_visibility (
  id integer primary key default 1,
  section_hidden boolean not null default false,
  hidden_levels text[] not null default '{}',
  hidden_subject_ids uuid[] not null default '{}',
  hidden_chapter_ids uuid[] not null default '{}',
  updated_at timestamptz not null default now(),
  constraint video_class_visibility_singleton check (id = 1)
);

alter table public.video_class_visibility enable row level security;

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  title text not null, body text not null default '', link text,
  type text not null default 'in_app' check (type in ('announcement','push','email','in_app')),
  priority text not null default 'medium' check (priority in ('low','medium','high','critical')),
  audience text not null default 'all' check (audience in ('all','level','subject','role','users')),
  audience_level text, audience_subject_id uuid,
  audience_role text check (audience_role in ('admin','moderator','student')),
  audience_user_ids uuid[] not null default '{}',
  scheduled_at timestamptz,
  status text not null default 'draft' check (status in ('draft','scheduled','sent','failed','paused')),
  sent_at timestamptz, delivered_count integer not null default 0,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.notifications enable row level security;

create table if not exists public.notification_reads (
  notification_id uuid not null references public.notifications(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (notification_id, user_id)
);

alter table public.notification_reads enable row level security;

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS status text NOT NULL DEFAULT 'active'
    CHECK (status IN ('active','suspended','pending')),
  ADD COLUMN IF NOT EXISTS referral_source text;

ALTER TABLE public.notifications
  ADD COLUMN IF NOT EXISTS open_count integer NOT NULL DEFAULT 0;

ALTER TABLE public.mcq_bookmarks DROP CONSTRAINT IF EXISTS mcq_bookmarks_pkey;

ALTER TABLE public.mcq_bookmarks
  ADD COLUMN IF NOT EXISTS id uuid NOT NULL DEFAULT gen_random_uuid();

ALTER TABLE public.mcq_bookmarks ADD PRIMARY KEY (id);

DO $$ BEGIN
  ALTER TABLE public.mcq_bookmarks ADD CONSTRAINT mcq_bookmarks_user_mcq_key UNIQUE (user_id, mcq_id);
EXCEPTION WHEN duplicate_table THEN NULL; WHEN duplicate_object THEN NULL; END $$;

ALTER TABLE public.mcq_wrong_questions DROP CONSTRAINT IF EXISTS mcq_wrong_questions_pkey;

ALTER TABLE public.mcq_wrong_questions
  ADD COLUMN IF NOT EXISTS id uuid NOT NULL DEFAULT gen_random_uuid();

ALTER TABLE public.mcq_wrong_questions ADD PRIMARY KEY (id);

DO $$ BEGIN
  ALTER TABLE public.mcq_wrong_questions ADD CONSTRAINT mcq_wrong_questions_user_mcq_key UNIQUE (user_id, mcq_id);
EXCEPTION WHEN duplicate_table THEN NULL; WHEN duplicate_object THEN NULL; END $$;

ALTER TABLE public.subjects ALTER COLUMN level DROP NOT NULL;

ALTER TABLE public.quizzes ALTER COLUMN level DROP NOT NULL;

ALTER TABLE public.exam_attempts ALTER COLUMN kind DROP NOT NULL;

ALTER TABLE public.subjects ALTER COLUMN level SET DEFAULT '';

ALTER TABLE public.subjects ALTER COLUMN level SET NOT NULL;

ALTER TABLE public.quizzes ALTER COLUMN level SET DEFAULT '';

ALTER TABLE public.quizzes ALTER COLUMN level SET NOT NULL;

ALTER TABLE public.exam_attempts ALTER COLUMN kind SET DEFAULT 'mcq_practice';

ALTER TABLE public.exam_attempts ALTER COLUMN kind SET NOT NULL;

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS deleted_at timestamptz,
  ADD COLUMN IF NOT EXISTS last_login_at timestamptz,
  ADD COLUMN IF NOT EXISTS total_login_count integer NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS total_usage_seconds bigint NOT NULL DEFAULT 0;

CREATE TABLE IF NOT EXISTS public.user_login_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  login_at timestamptz NOT NULL DEFAULT now(),
  logout_at timestamptz,
  duration_seconds integer,
  user_agent text,
  device text,
  browser text,
  ip text,
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.user_login_events ENABLE ROW LEVEL SECURITY;

-- ------------------------------------------------------------
-- Migration: 20260608042127_c500d938-30bd-4e49-b3c6-3141f1872a32.sql
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.activity_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NULL,
  event_type text NOT NULL,
  page_url text NULL,
  page_path text NULL,
  referrer text NULL,
  element_id text NULL,
  element_label text NULL,
  element_role text NULL,
  module text NULL,
  target_kind text NULL,
  target_id text NULL,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  user_agent text NULL,
  device text NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.activity_events ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.activity_events REPLICA IDENTITY FULL;

-- ------------------------------------------------------------
-- Migration: 20260608042210_a3a3021e-f18b-45fe-a2ca-556947149d88.sql
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.study_sessions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  module text NOT NULL DEFAULT 'dashboard',
  subject_id uuid,
  chapter_id uuid,
  started_at timestamptz NOT NULL DEFAULT now(),
  last_heartbeat_at timestamptz NOT NULL DEFAULT now(),
  ended_at timestamptz,
  duration_seconds integer NOT NULL DEFAULT 0,
  meta jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.study_sessions ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.quiz_sessions
  ADD COLUMN IF NOT EXISTS approved_by uuid,
  ADD COLUMN IF NOT EXISTS approved_at timestamptz,
  ADD COLUMN IF NOT EXISTS reject_reason text;

-- ------------------------------------------------------------
-- Migration: 20260608042326_2067cac0-1ae9-4fab-8b81-fb92f2a896d9.sql
-- ------------------------------------------------------------
ALTER TABLE public.mcqs
  ADD COLUMN IF NOT EXISTS question_type text NOT NULL DEFAULT 'mcq'
    CHECK (question_type IN ('mcq', 'true_false'));

ALTER TABLE public.mcqs ALTER COLUMN option_c DROP NOT NULL;

ALTER TABLE public.mcqs ALTER COLUMN option_d DROP NOT NULL;

-- ------------------------------------------------------------
-- Migration: 20260608042411_7bdc7639-0ccd-45d9-8efc-5d7eff7f12f5.sql
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.site_pages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  slug text NOT NULL UNIQUE,
  title text NOT NULL,
  is_home boolean NOT NULL DEFAULT false,
  seo_title text,
  seo_description text,
  sort_order integer NOT NULL DEFAULT 0,
  status text NOT NULL DEFAULT 'draft' CHECK (status IN ('draft','published','archived')),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.site_pages ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.site_page_sections (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  page_id uuid NOT NULL REFERENCES public.site_pages(id) ON DELETE CASCADE,
  kind text NOT NULL,
  content jsonb NOT NULL DEFAULT '{}'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  visible boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.site_page_sections ENABLE ROW LEVEL SECURITY;

-- ------------------------------------------------------------
-- Migration: 20260608173829_119a4e53-5144-4c40-bff0-0aba6c9a1adb.sql
-- ------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.role_permissions (
  role public.app_role NOT NULL,
  permission text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (role, permission)
);

ALTER TABLE public.role_permissions ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.role_permissions REPLICA IDENTITY FULL;

-- ------------------------------------------------------------
-- Migration: 20260608174559_1ec164aa-2008-48e4-8bed-33fa84c6967b.sql
-- ------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.admin_action_log (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  permission text NOT NULL,
  action text,
  allowed boolean NOT NULL,
  metadata jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.admin_action_log ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.user_roles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role public.app_role NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id, role)
);

ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;

-- ---------- editor_pages: current working draft per page ----------
CREATE TABLE IF NOT EXISTS public.editor_pages (
  page_id text PRIMARY KEY,
  version_id uuid NOT NULL,
  parent_version_id uuid,
  draft_state jsonb NOT NULL,
  updated_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.editor_pages ENABLE ROW LEVEL SECURITY;

-- ---------- editor_snapshots: immutable version chain ----------
CREATE TABLE IF NOT EXISTS public.editor_snapshots (
  version_id uuid PRIMARY KEY,
  page_id text NOT NULL,
  parent_version_id uuid,
  snapshot jsonb NOT NULL,
  summary text,
  author_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.editor_snapshots ENABLE ROW LEVEL SECURITY;

-- ---------- editor_actions_log: action / audit log ----------
CREATE TABLE IF NOT EXISTS public.editor_actions_log (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  page_id text NOT NULL,
  version_id uuid,
  author_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  action_type text NOT NULL,
  payload jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.editor_actions_log ENABLE ROW LEVEL SECURITY;

-- ---------- editor_published_pages: live target (publish pipeline) ----------
-- Isolated from Phase-1 site_settings/homepage_sections; the public site can
-- read this table to render published content without Phase-1 changes.
CREATE TABLE IF NOT EXISTS public.editor_published_pages (
  page_id text PRIMARY KEY,
  version_id uuid NOT NULL,
  published_state jsonb NOT NULL,
  published_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  published_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.editor_published_pages ENABLE ROW LEVEL SECURITY;

-- ------------------------------------------------------------
-- Migration: 20260609035412_3575f812-0ea5-4fb8-b530-b221785cc5b3.sql
-- ------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.module_visibility (
  key text PRIMARY KEY,
  label text NOT NULL,
  hidden boolean NOT NULL DEFAULT false,
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.module_visibility ENABLE ROW LEVEL SECURITY;

-- ------------------------------------------------------------
-- Migration: 20260609053230_19c507ed-7e50-4b94-a1da-95bd15a49d20.sql
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.system_error_logs (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  source TEXT NOT NULL CHECK (source IN ('frontend','backend','db','network','unknown')),
  severity TEXT NOT NULL DEFAULT 'medium' CHECK (severity IN ('critical','high','medium','low')),
  message TEXT NOT NULL,
  stack TEXT,
  route TEXT,
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  user_agent TEXT,
  payload JSONB,
  fingerprint TEXT NOT NULL,
  occurrence_count INTEGER NOT NULL DEFAULT 1,
  last_seen_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  resolved BOOLEAN NOT NULL DEFAULT FALSE,
  resolved_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.system_error_logs ENABLE ROW LEVEL SECURITY;

-- part 54: system_error_logs
CREATE TABLE IF NOT EXISTS public.system_error_logs (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  source TEXT NOT NULL CHECK (source IN ('frontend','backend','db','network','unknown')),
  severity TEXT NOT NULL DEFAULT 'medium' CHECK (severity IN ('critical','high','medium','low')),
  message TEXT NOT NULL, stack TEXT, route TEXT,
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  user_agent TEXT, payload JSONB, fingerprint TEXT NOT NULL,
  occurrence_count INTEGER NOT NULL DEFAULT 1,
  last_seen_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  resolved BOOLEAN NOT NULL DEFAULT FALSE,
  resolved_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.system_error_logs ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- PHASE 4: BLOG SYSTEM SCHEMA
-- ============================================================

CREATE TABLE IF NOT EXISTS public.blog_categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  slug TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL,
  description TEXT,
  sort_order INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.blog_categories ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.blog_tags (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  slug TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.blog_tags ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.blog_posts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  slug TEXT NOT NULL UNIQUE,
  title TEXT NOT NULL,
  excerpt TEXT,
  content TEXT NOT NULL DEFAULT '',
  cover_image_url TEXT,
  status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft','published','archived')),
  category_id UUID REFERENCES public.blog_categories(id) ON DELETE SET NULL,
  author_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  reading_minutes INTEGER NOT NULL DEFAULT 1,
  view_count INTEGER NOT NULL DEFAULT 0,
  seo_title TEXT,
  seo_description TEXT,
  og_image_url TEXT,
  published_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.blog_posts ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.blog_post_tags (
  post_id UUID NOT NULL REFERENCES public.blog_posts(id) ON DELETE CASCADE,
  tag_id UUID NOT NULL REFERENCES public.blog_tags(id) ON DELETE CASCADE,
  PRIMARY KEY (post_id, tag_id)
);

ALTER TABLE public.blog_post_tags ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.blog_views (
  id BIGSERIAL PRIMARY KEY,
  post_id UUID NOT NULL REFERENCES public.blog_posts(id) ON DELETE CASCADE,
  viewer_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  referrer TEXT,
  user_agent TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.blog_views ENABLE ROW LEVEL SECURITY;

-- ------------------------------------------------------------
-- Migration: 20260611160000_user_management_phase2.sql
-- ------------------------------------------------------------
-- =============================================================
-- Phase 2 — Enterprise User Management (additive, non-destructive)
-- =============================================================
-- HOW TO APPLY:
--   Open Lovable Cloud → SQL Editor and run this file once.
--   Safe to re-run (all statements are idempotent).
-- Adds: admin_notes, user_tags, user_messages, user_bans + helper RPC.
-- Nothing existing is dropped or altered destructively.

-- profiles: additive ban columns ------------------------------
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS ban_until timestamptz;

ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS ban_reason text;

-- admin_notes -------------------------------------------------
CREATE TABLE IF NOT EXISTS public.admin_notes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  admin_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  note_type text NOT NULL DEFAULT 'internal',
  title text,
  content text NOT NULL,
  is_pinned boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.admin_notes ENABLE ROW LEVEL SECURITY;

-- user_tags ---------------------------------------------------
CREATE TABLE IF NOT EXISTS public.user_tags (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  tag text NOT NULL,
  color text,
  assigned_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  assigned_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id, tag)
);

ALTER TABLE public.user_tags ENABLE ROW LEVEL SECURITY;

-- user_messages -----------------------------------------------
CREATE TABLE IF NOT EXISTS public.user_messages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  from_admin_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  to_user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  kind text NOT NULL DEFAULT 'message',
  subject text,
  body text NOT NULL,
  read_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.user_messages ENABLE ROW LEVEL SECURITY;

-- user_bans ---------------------------------------------------
CREATE TABLE IF NOT EXISTS public.user_bans (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  admin_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  kind text NOT NULL DEFAULT 'suspension',
  reason text,
  starts_at timestamptz NOT NULL DEFAULT now(),
  ends_at timestamptz,
  lifted_at timestamptz,
  lifted_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.user_bans ENABLE ROW LEVEL SECURITY;

-- ------------------------------------------------------------
-- Migration: 20260612202013_auth_access_controls.sql
-- ------------------------------------------------------------
-- =====================================================================
-- Admin Authentication Controls
-- Singleton table that gates student login & signup, with admin-editable
-- messages, scheduled auto-reactivation, audit logging, and realtime.
-- =====================================================================

CREATE TABLE IF NOT EXISTS public.auth_access_controls (
  id integer PRIMARY KEY DEFAULT 1,
  login_enabled boolean NOT NULL DEFAULT true,
  signup_enabled boolean NOT NULL DEFAULT true,
  login_message_title text NOT NULL DEFAULT 'System Maintenance',
  login_message_subtitle text NOT NULL DEFAULT 'Login Temporarily Disabled',
  login_message_description text NOT NULL DEFAULT 'Login is temporarily unavailable due to maintenance. Please try again later.',
  login_message_footer text NOT NULL DEFAULT 'Please check back later.',
  signup_message_title text NOT NULL DEFAULT 'System Maintenance',
  signup_message_subtitle text NOT NULL DEFAULT 'Signup Temporarily Disabled',
  signup_message_description text NOT NULL DEFAULT 'New registrations are temporarily unavailable. Please try again later.',
  signup_message_footer text NOT NULL DEFAULT 'Please check back later.',
  login_auto_enable_at timestamptz,
  signup_auto_enable_at timestamptz,
  updated_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  updated_at timestamptz NOT NULL DEFAULT now(),
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT auth_access_controls_singleton CHECK (id = 1)
);

ALTER TABLE public.auth_access_controls ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.auth_access_controls REPLICA IDENTITY FULL;

-- A-5: Prevent blog_views inflation by a single viewer. Bucket views per hour
-- per (post, viewer hash) so a refresh loop cannot pump the counter. The
-- viewer_hash column is populated from the server-side insert path
-- (hash(IP + user-agent)); existing rows are left alone with NULL hash and
-- excluded from the uniqueness check via partial index.
-- Note: date_trunc('hour', timestamptz) is NOT immutable (depends on TimeZone GUC),
-- so it cannot be used in a STORED generated column. We bucket in UTC and store
-- as `timestamp` (without time zone), which IS immutable.
ALTER TABLE public.blog_views
  ADD COLUMN IF NOT EXISTS viewer_hash text,
  ADD COLUMN IF NOT EXISTS time_bucket timestamp
    GENERATED ALWAYS AS (date_trunc('hour', (created_at AT TIME ZONE 'UTC'))) STORED;


-- =================== 5a. DROP STALE FUNCTIONS =====

-- has_role MUST exist before any CREATE POLICY references it.
-- Drop first so signature/return-type changes never fail.
DROP FUNCTION IF EXISTS public.has_role(uuid, public.app_role) CASCADE;

-- ------------------------------------------------------------
-- Migration: 20260608035527_39a98bed-e94e-4598-99b7-92ce58961424.sql
-- ------------------------------------------------------------

DROP FUNCTION IF EXISTS public.admin_activity_overview();

DROP FUNCTION IF EXISTS public.admin_top_modules();

DROP FUNCTION IF EXISTS public.admin_top_users();

DROP FUNCTION IF EXISTS public.admin_top_buttons();

DROP FUNCTION IF EXISTS public.admin_top_pages();

DO $admin_activity_timeseries_drop$
DECLARE
  func_record record;
BEGIN
  FOR func_record IN
    SELECT
      n.nspname AS schema_name,
      p.proname AS function_name,
      pg_get_function_identity_arguments(p.oid) AS identity_args
    FROM pg_proc p
    JOIN pg_namespace n
      ON n.oid = p.pronamespace
    WHERE p.proname = 'admin_activity_timeseries'
  LOOP
    EXECUTE format(
      'DROP FUNCTION IF EXISTS %I.%I(%s) CASCADE',
      func_record.schema_name,
      func_record.function_name,
      func_record.identity_args
    );
  END LOOP;
END
$admin_activity_timeseries_drop$;

DROP FUNCTION IF EXISTS public.admin_user_activity();

DROP FUNCTION IF EXISTS public.admin_user_analytics();

-- ------------------------------------------------------------
-- Migration: 20260608173438_bdbb5383-0cac-40fc-a251-a688772e45a3.sql
-- ------------------------------------------------------------
DROP FUNCTION IF EXISTS public._lovable_import_exec(text);

-- ------------------------------------------------------------
-- Migration: 20260609052652_fb6e3595-fdd2-41d2-8f35-368e854ee601.sql
-- ------------------------------------------------------------

-- 1. Drop the unused bootstrap helper. It runs arbitrary SQL via EXECUTE and
--    has no search_path pinned. It is no longer needed post-bootstrap.
DROP FUNCTION IF EXISTS public._bootstrap_exec(text);


-- =================== 5b. FUNCTIONS =================

CREATE FUNCTION public.has_role(_user_id uuid, _role public.app_role)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $has_role$
  SELECT EXISTS (
    SELECT 1 FROM public.user_roles
    WHERE user_id = _user_id AND role = _role
  )
$has_role$;

CREATE OR REPLACE FUNCTION public.has_role(_user_id uuid, _role public.app_role)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT EXISTS (SELECT 1 FROM public.user_roles WHERE user_id = _user_id AND role = _role)
$$;

CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql SET search_path = public AS $$
BEGIN NEW.updated_at = now(); RETURN NEW; END $$;

CREATE OR REPLACE FUNCTION public.admin_get_table_sizes()
RETURNS TABLE(table_name text, size_bytes bigint, row_estimate bigint)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_catalog
AS $$
BEGIN
  IF NOT public.has_role(auth.uid(), 'admin'::public.app_role) THEN
    RAISE EXCEPTION 'Forbidden: admin role required';
  END IF;
  RETURN QUERY
    SELECT c.relname::text, pg_total_relation_size(c.oid)::bigint, c.reltuples::bigint
    FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public' AND c.relkind = 'r'
    ORDER BY pg_total_relation_size(c.oid) DESC;
END; $$;

CREATE OR REPLACE FUNCTION public.admin_get_db_size()
RETURNS bigint LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_catalog
AS $$
DECLARE s bigint;
BEGIN
  IF NOT public.has_role(auth.uid(), 'admin'::public.app_role) THEN
    RAISE EXCEPTION 'Forbidden: admin role required';
  END IF;
  SELECT pg_database_size(current_database()) INTO s;
  RETURN s;
END; $$;

CREATE OR REPLACE FUNCTION public.claim_user_session(_session_id TEXT, _user_agent TEXT DEFAULT NULL)
RETURNS public.user_sessions LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE uid UUID := auth.uid(); row public.user_sessions;
BEGIN
  IF uid IS NULL THEN RAISE EXCEPTION 'Not authenticated'; END IF;
  IF _session_id IS NULL OR length(_session_id) < 8 OR length(_session_id) > 128 THEN
    RAISE EXCEPTION 'Invalid session id';
  END IF;
  INSERT INTO public.user_sessions(user_id, active_session_id, user_agent, updated_at)
  VALUES (uid, _session_id, _user_agent, now())
  ON CONFLICT (user_id) DO UPDATE
    SET active_session_id = EXCLUDED.active_session_id, user_agent = EXCLUDED.user_agent, updated_at = now()
  RETURNING * INTO row;
  RETURN row;
END; $$;

CREATE OR REPLACE FUNCTION public.admin_user_analytics()
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE result jsonb;
BEGIN
  IF NOT public.has_role(auth.uid(), 'admin'::app_role) THEN
    RAISE EXCEPTION 'Forbidden: admin role required';
  END IF;
  SELECT jsonb_build_object(
    'total_users', (SELECT count(*) FROM public.profiles WHERE deleted_at IS NULL),
    'deleted_users', (SELECT count(*) FROM public.profiles WHERE deleted_at IS NOT NULL),
    'active_24h', (SELECT count(DISTINCT user_id) FROM public.user_login_events WHERE login_at >= now() - interval '24 hours'),
    'active_7d', (SELECT count(DISTINCT user_id) FROM public.user_login_events WHERE login_at >= now() - interval '7 days'),
    'active_30d', (SELECT count(DISTINCT user_id) FROM public.user_login_events WHERE login_at >= now() - interval '30 days'),
    'lifetime_active', (SELECT count(DISTINCT user_id) FROM public.user_login_events),
    'total_logins', (SELECT count(*) FROM public.user_login_events),
    'avg_session_seconds', COALESCE((SELECT avg(duration_seconds)::bigint FROM public.user_login_events WHERE duration_seconds IS NOT NULL AND duration_seconds > 0), 0),
    'usage_24h', COALESCE((SELECT sum(duration_seconds)::bigint FROM public.user_login_events WHERE login_at >= now() - interval '24 hours'), 0),
    'usage_7d', COALESCE((SELECT sum(duration_seconds)::bigint FROM public.user_login_events WHERE login_at >= now() - interval '7 days'), 0),
    'usage_30d', COALESCE((SELECT sum(duration_seconds)::bigint FROM public.user_login_events WHERE login_at >= now() - interval '30 days'), 0)
  ) INTO result;
  RETURN result;
END $$;

CREATE OR REPLACE FUNCTION public.admin_top_users(_order text DEFAULT 'most', _limit integer DEFAULT 10)
RETURNS TABLE (user_id uuid, display_name text, total_login_count integer, total_usage_seconds bigint, last_login_at timestamptz)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NOT public.has_role(auth.uid(), 'admin'::app_role) THEN
    RAISE EXCEPTION 'Forbidden: admin role required';
  END IF;
  IF _order = 'least' THEN
    RETURN QUERY SELECT p.id, p.display_name, p.total_login_count, p.total_usage_seconds, p.last_login_at
      FROM public.profiles p WHERE p.deleted_at IS NULL
      ORDER BY p.total_usage_seconds ASC, p.total_login_count ASC LIMIT _limit;
  ELSE
    RETURN QUERY SELECT p.id, p.display_name, p.total_login_count, p.total_usage_seconds, p.last_login_at
      FROM public.profiles p WHERE p.deleted_at IS NULL AND p.total_login_count > 0
      ORDER BY p.total_usage_seconds DESC, p.total_login_count DESC LIMIT _limit;
  END IF;
END $$;

CREATE OR REPLACE FUNCTION public.admin_soft_delete_user(_id uuid)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NOT public.has_role(auth.uid(), 'admin'::app_role) THEN RAISE EXCEPTION 'Forbidden'; END IF;
  IF public.has_role(_id, 'admin'::app_role) THEN RAISE EXCEPTION 'Cannot remove an admin. Demote first.'; END IF;
  UPDATE public.profiles SET deleted_at = now(), status = 'suspended' WHERE id = _id;
END $$;

CREATE OR REPLACE FUNCTION public.admin_restore_user(_id uuid)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NOT public.has_role(auth.uid(), 'admin'::app_role) THEN RAISE EXCEPTION 'Forbidden'; END IF;
  UPDATE public.profiles SET deleted_at = NULL, status = 'active' WHERE id = _id;
END $$;

CREATE OR REPLACE FUNCTION public.admin_hard_delete_user(_id uuid)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, auth AS $$
BEGIN
  IF NOT public.has_role(auth.uid(), 'admin'::app_role) THEN RAISE EXCEPTION 'Forbidden'; END IF;
  IF public.has_role(_id, 'admin'::app_role) THEN RAISE EXCEPTION 'Cannot permanently delete an admin. Demote first.'; END IF;
  DELETE FROM public.user_login_events WHERE user_id = _id;
  DELETE FROM public.user_roles WHERE user_id = _id;
  DELETE FROM public.profiles WHERE id = _id;
  DELETE FROM auth.users WHERE id = _id;
END $$;

CREATE OR REPLACE FUNCTION public.admin_activity_overview(_range_hours integer DEFAULT 24)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE since timestamptz := now() - make_interval(hours => _range_hours); result jsonb;
BEGIN
  IF NOT public.has_role(auth.uid(), 'admin'::app_role) THEN RAISE EXCEPTION 'Forbidden'; END IF;
  SELECT jsonb_build_object(
    'active_now', (SELECT count(DISTINCT user_id) FROM public.activity_events WHERE created_at >= now() - interval '5 minutes' AND user_id IS NOT NULL),
    'unique_users_24h', (SELECT count(DISTINCT user_id) FROM public.activity_events WHERE created_at >= now() - interval '24 hours' AND user_id IS NOT NULL),
    'unique_users_7d', (SELECT count(DISTINCT user_id) FROM public.activity_events WHERE created_at >= now() - interval '7 days' AND user_id IS NOT NULL),
    'unique_users_30d', (SELECT count(DISTINCT user_id) FROM public.activity_events WHERE created_at >= now() - interval '30 days' AND user_id IS NOT NULL),
    'total_events', (SELECT count(*) FROM public.activity_events WHERE created_at >= since),
    'total_clicks', (SELECT count(*) FROM public.activity_events WHERE created_at >= since AND event_type = 'click'),
    'total_page_views', (SELECT count(*) FROM public.activity_events WHERE created_at >= since AND event_type = 'page_view'),
    'total_logins', (SELECT count(*) FROM public.activity_events WHERE created_at >= since AND event_type = 'login'),
    'total_submits', (SELECT count(*) FROM public.activity_events WHERE created_at >= since AND event_type = 'submit'),
    'total_crud', (SELECT count(*) FROM public.activity_events WHERE created_at >= since AND event_type = 'crud'),
    'total_admin_actions', (SELECT count(*) FROM public.activity_events WHERE created_at >= since AND event_type = 'admin_action'),
    'api_errors', (SELECT count(*) FROM public.activity_events WHERE created_at >= since AND event_type = 'api_call' AND (metadata->>'ok')::boolean IS FALSE),
    'range_hours', _range_hours
  ) INTO result;
  RETURN result;
END $$;

CREATE OR REPLACE FUNCTION public.admin_top_buttons(_range_hours integer DEFAULT 24, _limit integer DEFAULT 10)
RETURNS TABLE(element_id text, element_label text, page_path text, click_count bigint)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NOT public.has_role(auth.uid(), 'admin'::app_role) THEN RAISE EXCEPTION 'Forbidden'; END IF;
  RETURN QUERY SELECT
    COALESCE(e.element_id, e.element_label, '(unknown)'),
    COALESCE(e.element_label, e.element_id, '(unknown)'),
    COALESCE(e.page_path, '/'),
    count(*)::bigint
    FROM public.activity_events e
    WHERE e.event_type = 'click' AND e.created_at >= now() - make_interval(hours => _range_hours)
    GROUP BY 1, 2, 3 ORDER BY 4 DESC LIMIT _limit;
END $$;

CREATE OR REPLACE FUNCTION public.admin_top_pages(_range_hours integer DEFAULT 24, _limit integer DEFAULT 10)
RETURNS TABLE(page_path text, view_count bigint, unique_users bigint)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NOT public.has_role(auth.uid(), 'admin'::app_role) THEN RAISE EXCEPTION 'Forbidden'; END IF;
  RETURN QUERY SELECT COALESCE(e.page_path, '/'), count(*)::bigint, count(DISTINCT e.user_id)::bigint
    FROM public.activity_events e
    WHERE e.event_type = 'page_view' AND e.created_at >= now() - make_interval(hours => _range_hours)
    GROUP BY 1 ORDER BY 2 DESC LIMIT _limit;
END $$;

CREATE OR REPLACE FUNCTION public.admin_top_modules(_range_hours integer DEFAULT 24, _limit integer DEFAULT 10)
RETURNS TABLE(module text, event_count bigint, unique_users bigint)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NOT public.has_role(auth.uid(), 'admin'::app_role) THEN RAISE EXCEPTION 'Forbidden'; END IF;
  RETURN QUERY SELECT COALESCE(e.module, '(none)'), count(*)::bigint, count(DISTINCT e.user_id)::bigint
    FROM public.activity_events e
    WHERE e.created_at >= now() - make_interval(hours => _range_hours) AND e.module IS NOT NULL
    GROUP BY 1 ORDER BY 2 DESC LIMIT _limit;
END $$;

DO $admin_activity_timeseries_drop$
DECLARE
  func_record record;
BEGIN
  FOR func_record IN
    SELECT
      n.nspname AS schema_name,
      p.proname AS function_name,
      pg_get_function_identity_arguments(p.oid) AS identity_args
    FROM pg_proc p
    JOIN pg_namespace n
      ON n.oid = p.pronamespace
    WHERE p.proname = 'admin_activity_timeseries'
  LOOP
    EXECUTE format(
      'DROP FUNCTION IF EXISTS %I.%I(%s) CASCADE',
      func_record.schema_name,
      func_record.function_name,
      func_record.identity_args
    );
  END LOOP;
END
$admin_activity_timeseries_drop$;

CREATE OR REPLACE FUNCTION public.admin_activity_timeseries()
RETURNS TABLE(bucket text, event_type text, event_count bigint)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT to_char(date_trunc('day', created_at), 'YYYY-MM-DD'), event_type, count(*)::bigint
  FROM public.activity_events
  WHERE created_at >= now() - interval '30 days'
  GROUP BY 1,2 ORDER BY 1
$$;

CREATE OR REPLACE FUNCTION public.admin_activity_timeseries(_range_hours integer DEFAULT 24, _bucket_minutes integer DEFAULT 60)
RETURNS TABLE(bucket timestamptz, event_type text, event_count bigint)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NOT public.has_role(auth.uid(), 'admin'::app_role) THEN RAISE EXCEPTION 'Forbidden'; END IF;
  RETURN QUERY SELECT date_bin(make_interval(mins => _bucket_minutes), e.created_at, timestamptz 'epoch'),
    e.event_type, count(*)::bigint
    FROM public.activity_events e
    WHERE e.created_at >= now() - make_interval(hours => _range_hours)
    GROUP BY 1, 2 ORDER BY 1 ASC;
END $$;

CREATE OR REPLACE FUNCTION public.admin_user_activity(_user_id uuid, _limit integer DEFAULT 50)
RETURNS TABLE(id uuid, user_id uuid, event_type text, page_path text, element_label text, module text, metadata jsonb, created_at timestamptz)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NOT public.has_role(auth.uid(), 'admin'::app_role) THEN RAISE EXCEPTION 'Forbidden'; END IF;
  RETURN QUERY SELECT e.id, e.user_id, e.event_type, e.page_path, e.element_label, e.module, e.metadata, e.created_at
    FROM public.activity_events e WHERE e.user_id = _user_id ORDER BY e.created_at DESC LIMIT _limit;
END $$;

CREATE OR REPLACE FUNCTION public.has_role(_user_id uuid, _role public.app_role)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT EXISTS (SELECT 1 FROM public.user_roles WHERE user_id = _user_id AND role = _role)
$$;

CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql SET search_path = public AS $$
BEGIN NEW.updated_at = now(); RETURN NEW; END $$;

CREATE OR REPLACE FUNCTION public.admin_get_table_sizes()
RETURNS TABLE(table_name text, size_bytes bigint, row_estimate bigint)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_catalog
AS $$
BEGIN
  IF NOT public.has_role(auth.uid(), 'admin'::public.app_role) THEN
    RAISE EXCEPTION 'Forbidden: admin role required';
  END IF;
  RETURN QUERY
    SELECT c.relname::text, pg_total_relation_size(c.oid)::bigint, c.reltuples::bigint
    FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public' AND c.relkind = 'r'
    ORDER BY pg_total_relation_size(c.oid) DESC;
END; $$;

CREATE OR REPLACE FUNCTION public.admin_get_db_size()
RETURNS bigint LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_catalog
AS $$
DECLARE s bigint;
BEGIN
  IF NOT public.has_role(auth.uid(), 'admin'::public.app_role) THEN
    RAISE EXCEPTION 'Forbidden: admin role required';
  END IF;
  SELECT pg_database_size(current_database()) INTO s;
  RETURN s;
END; $$;

CREATE OR REPLACE FUNCTION public.claim_user_session(_session_id TEXT, _user_agent TEXT DEFAULT NULL)
RETURNS public.user_sessions LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE uid UUID := auth.uid(); row public.user_sessions;
BEGIN
  IF uid IS NULL THEN RAISE EXCEPTION 'Not authenticated'; END IF;
  IF _session_id IS NULL OR length(_session_id) < 8 OR length(_session_id) > 128 THEN
    RAISE EXCEPTION 'Invalid session id';
  END IF;
  INSERT INTO public.user_sessions(user_id, active_session_id, user_agent, updated_at)
  VALUES (uid, _session_id, _user_agent, now())
  ON CONFLICT (user_id) DO UPDATE
    SET active_session_id = EXCLUDED.active_session_id, user_agent = EXCLUDED.user_agent, updated_at = now()
  RETURNING * INTO row;
  RETURN row;
END; $$;

CREATE OR REPLACE FUNCTION public.admin_user_analytics()
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE result jsonb;
BEGIN
  IF NOT public.has_role(auth.uid(), 'admin'::app_role) THEN
    RAISE EXCEPTION 'Forbidden: admin role required';
  END IF;
  SELECT jsonb_build_object(
    'total_users', (SELECT count(*) FROM public.profiles WHERE deleted_at IS NULL),
    'deleted_users', (SELECT count(*) FROM public.profiles WHERE deleted_at IS NOT NULL),
    'active_24h', (SELECT count(DISTINCT user_id) FROM public.user_login_events WHERE login_at >= now() - interval '24 hours'),
    'active_7d', (SELECT count(DISTINCT user_id) FROM public.user_login_events WHERE login_at >= now() - interval '7 days'),
    'active_30d', (SELECT count(DISTINCT user_id) FROM public.user_login_events WHERE login_at >= now() - interval '30 days'),
    'lifetime_active', (SELECT count(DISTINCT user_id) FROM public.user_login_events),
    'total_logins', (SELECT count(*) FROM public.user_login_events),
    'avg_session_seconds', COALESCE((SELECT avg(duration_seconds)::bigint FROM public.user_login_events WHERE duration_seconds IS NOT NULL AND duration_seconds > 0), 0),
    'usage_24h', COALESCE((SELECT sum(duration_seconds)::bigint FROM public.user_login_events WHERE login_at >= now() - interval '24 hours'), 0),
    'usage_7d', COALESCE((SELECT sum(duration_seconds)::bigint FROM public.user_login_events WHERE login_at >= now() - interval '7 days'), 0),
    'usage_30d', COALESCE((SELECT sum(duration_seconds)::bigint FROM public.user_login_events WHERE login_at >= now() - interval '30 days'), 0)
  ) INTO result;
  RETURN result;
END $$;

CREATE OR REPLACE FUNCTION public.admin_top_users(_order text DEFAULT 'most', _limit integer DEFAULT 10)
RETURNS TABLE (user_id uuid, display_name text, total_login_count integer, total_usage_seconds bigint, last_login_at timestamptz)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NOT public.has_role(auth.uid(), 'admin'::app_role) THEN
    RAISE EXCEPTION 'Forbidden: admin role required';
  END IF;
  IF _order = 'least' THEN
    RETURN QUERY SELECT p.id, p.display_name, p.total_login_count, p.total_usage_seconds, p.last_login_at
      FROM public.profiles p WHERE p.deleted_at IS NULL
      ORDER BY p.total_usage_seconds ASC, p.total_login_count ASC LIMIT _limit;
  ELSE
    RETURN QUERY SELECT p.id, p.display_name, p.total_login_count, p.total_usage_seconds, p.last_login_at
      FROM public.profiles p WHERE p.deleted_at IS NULL AND p.total_login_count > 0
      ORDER BY p.total_usage_seconds DESC, p.total_login_count DESC LIMIT _limit;
  END IF;
END $$;

CREATE OR REPLACE FUNCTION public.admin_soft_delete_user(_id uuid)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NOT public.has_role(auth.uid(), 'admin'::app_role) THEN RAISE EXCEPTION 'Forbidden'; END IF;
  IF public.has_role(_id, 'admin'::app_role) THEN RAISE EXCEPTION 'Cannot remove an admin. Demote first.'; END IF;
  UPDATE public.profiles SET deleted_at = now(), status = 'suspended' WHERE id = _id;
END $$;

CREATE OR REPLACE FUNCTION public.admin_restore_user(_id uuid)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NOT public.has_role(auth.uid(), 'admin'::app_role) THEN RAISE EXCEPTION 'Forbidden'; END IF;
  UPDATE public.profiles SET deleted_at = NULL, status = 'active' WHERE id = _id;
END $$;

CREATE OR REPLACE FUNCTION public.admin_hard_delete_user(_id uuid)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, auth AS $$
BEGIN
  IF NOT public.has_role(auth.uid(), 'admin'::app_role) THEN RAISE EXCEPTION 'Forbidden'; END IF;
  IF public.has_role(_id, 'admin'::app_role) THEN RAISE EXCEPTION 'Cannot permanently delete an admin. Demote first.'; END IF;
  DELETE FROM public.user_login_events WHERE user_id = _id;
  DELETE FROM public.user_roles WHERE user_id = _id;
  DELETE FROM public.profiles WHERE id = _id;
  DELETE FROM auth.users WHERE id = _id;
END $$;

CREATE OR REPLACE FUNCTION public.admin_activity_overview(_range_hours integer DEFAULT 24)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE since timestamptz := now() - make_interval(hours => _range_hours); result jsonb;
BEGIN
  IF NOT public.has_role(auth.uid(), 'admin'::app_role) THEN RAISE EXCEPTION 'Forbidden'; END IF;
  SELECT jsonb_build_object(
    'active_now', (SELECT count(DISTINCT user_id) FROM public.activity_events WHERE created_at >= now() - interval '5 minutes' AND user_id IS NOT NULL),
    'unique_users_24h', (SELECT count(DISTINCT user_id) FROM public.activity_events WHERE created_at >= now() - interval '24 hours' AND user_id IS NOT NULL),
    'unique_users_7d', (SELECT count(DISTINCT user_id) FROM public.activity_events WHERE created_at >= now() - interval '7 days' AND user_id IS NOT NULL),
    'unique_users_30d', (SELECT count(DISTINCT user_id) FROM public.activity_events WHERE created_at >= now() - interval '30 days' AND user_id IS NOT NULL),
    'total_events', (SELECT count(*) FROM public.activity_events WHERE created_at >= since),
    'total_clicks', (SELECT count(*) FROM public.activity_events WHERE created_at >= since AND event_type = 'click'),
    'total_page_views', (SELECT count(*) FROM public.activity_events WHERE created_at >= since AND event_type = 'page_view'),
    'total_logins', (SELECT count(*) FROM public.activity_events WHERE created_at >= since AND event_type = 'login'),
    'total_submits', (SELECT count(*) FROM public.activity_events WHERE created_at >= since AND event_type = 'submit'),
    'total_crud', (SELECT count(*) FROM public.activity_events WHERE created_at >= since AND event_type = 'crud'),
    'total_admin_actions', (SELECT count(*) FROM public.activity_events WHERE created_at >= since AND event_type = 'admin_action'),
    'api_errors', (SELECT count(*) FROM public.activity_events WHERE created_at >= since AND event_type = 'api_call' AND (metadata->>'ok')::boolean IS FALSE),
    'range_hours', _range_hours
  ) INTO result;
  RETURN result;
END $$;

CREATE OR REPLACE FUNCTION public.admin_top_buttons(_range_hours integer DEFAULT 24, _limit integer DEFAULT 10)
RETURNS TABLE(element_id text, element_label text, page_path text, click_count bigint)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NOT public.has_role(auth.uid(), 'admin'::app_role) THEN RAISE EXCEPTION 'Forbidden'; END IF;
  RETURN QUERY SELECT
    COALESCE(e.element_id, e.element_label, '(unknown)'),
    COALESCE(e.element_label, e.element_id, '(unknown)'),
    COALESCE(e.page_path, '/'),
    count(*)::bigint
    FROM public.activity_events e
    WHERE e.event_type = 'click' AND e.created_at >= now() - make_interval(hours => _range_hours)
    GROUP BY 1, 2, 3 ORDER BY 4 DESC LIMIT _limit;
END $$;

CREATE OR REPLACE FUNCTION public.admin_top_pages(_range_hours integer DEFAULT 24, _limit integer DEFAULT 10)
RETURNS TABLE(page_path text, view_count bigint, unique_users bigint)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NOT public.has_role(auth.uid(), 'admin'::app_role) THEN RAISE EXCEPTION 'Forbidden'; END IF;
  RETURN QUERY SELECT COALESCE(e.page_path, '/'), count(*)::bigint, count(DISTINCT e.user_id)::bigint
    FROM public.activity_events e
    WHERE e.event_type = 'page_view' AND e.created_at >= now() - make_interval(hours => _range_hours)
    GROUP BY 1 ORDER BY 2 DESC LIMIT _limit;
END $$;

CREATE OR REPLACE FUNCTION public.admin_top_modules(_range_hours integer DEFAULT 24, _limit integer DEFAULT 10)
RETURNS TABLE(module text, event_count bigint, unique_users bigint)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NOT public.has_role(auth.uid(), 'admin'::app_role) THEN RAISE EXCEPTION 'Forbidden'; END IF;
  RETURN QUERY SELECT COALESCE(e.module, '(none)'), count(*)::bigint, count(DISTINCT e.user_id)::bigint
    FROM public.activity_events e
    WHERE e.created_at >= now() - make_interval(hours => _range_hours) AND e.module IS NOT NULL
    GROUP BY 1 ORDER BY 2 DESC LIMIT _limit;
END $$;

CREATE OR REPLACE FUNCTION public.admin_activity_timeseries(_range_hours integer DEFAULT 24, _bucket_minutes integer DEFAULT 60)
RETURNS TABLE(bucket timestamptz, event_type text, event_count bigint)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NOT public.has_role(auth.uid(), 'admin'::app_role) THEN RAISE EXCEPTION 'Forbidden'; END IF;
  RETURN QUERY SELECT date_bin(make_interval(mins => _bucket_minutes), e.created_at, timestamptz 'epoch'),
    e.event_type, count(*)::bigint
    FROM public.activity_events e
    WHERE e.created_at >= now() - make_interval(hours => _range_hours)
    GROUP BY 1, 2 ORDER BY 1 ASC;
END $$;

CREATE OR REPLACE FUNCTION public.admin_user_activity(_user_id uuid, _limit integer DEFAULT 50)
RETURNS TABLE(id uuid, user_id uuid, event_type text, page_path text, element_label text, module text, metadata jsonb, created_at timestamptz)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NOT public.has_role(auth.uid(), 'admin'::app_role) THEN RAISE EXCEPTION 'Forbidden'; END IF;
  RETURN QUERY SELECT e.id, e.user_id, e.event_type, e.page_path, e.element_label, e.module, e.metadata, e.created_at
    FROM public.activity_events e WHERE e.user_id = _user_id ORDER BY e.created_at DESC LIMIT _limit;
END $$;

-- Validation trigger: enforce shape per question type
CREATE OR REPLACE FUNCTION public.mcqs_validate_question_type()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
  IF NEW.question_type = 'true_false' THEN
    IF NEW.option_a IS NULL OR length(btrim(NEW.option_a)) = 0
       OR NEW.option_b IS NULL OR length(btrim(NEW.option_b)) = 0 THEN
      RAISE EXCEPTION 'True/False questions require option_a and option_b';
    END IF;
    NEW.option_c := NULL;
    NEW.option_d := NULL;
    IF NEW.correct_option NOT IN ('a','b') THEN
      RAISE EXCEPTION 'True/False correct_option must be a or b';
    END IF;
  ELSE
    IF NEW.option_a IS NULL OR NEW.option_b IS NULL OR NEW.option_c IS NULL OR NEW.option_d IS NULL THEN
      RAISE EXCEPTION 'MCQ questions require all four options';
    END IF;
  END IF;
  RETURN NEW;
END $$;

CREATE OR REPLACE FUNCTION public.has_role(_user_id uuid, _role public.app_role)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT EXISTS (SELECT 1 FROM public.user_roles WHERE user_id = _user_id AND role = _role)
$$;

CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql SET search_path = public AS $$
BEGIN NEW.updated_at = now(); RETURN NEW; END $$;

CREATE OR REPLACE FUNCTION public.admin_get_table_sizes()
RETURNS TABLE(table_name text, size_bytes bigint, row_estimate bigint)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_catalog
AS $$
BEGIN
  IF NOT public.has_role(auth.uid(), 'admin'::public.app_role) THEN
    RAISE EXCEPTION 'Forbidden: admin role required';
  END IF;
  RETURN QUERY
    SELECT c.relname::text, pg_total_relation_size(c.oid)::bigint, c.reltuples::bigint
    FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public' AND c.relkind = 'r'
    ORDER BY pg_total_relation_size(c.oid) DESC;
END; $$;

CREATE OR REPLACE FUNCTION public.admin_get_db_size()
RETURNS bigint LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_catalog
AS $$
DECLARE s bigint;
BEGIN
  IF NOT public.has_role(auth.uid(), 'admin'::public.app_role) THEN
    RAISE EXCEPTION 'Forbidden: admin role required';
  END IF;
  SELECT pg_database_size(current_database()) INTO s;
  RETURN s;
END; $$;

CREATE OR REPLACE FUNCTION public.claim_user_session(_session_id TEXT, _user_agent TEXT DEFAULT NULL)
RETURNS public.user_sessions LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE uid UUID := auth.uid(); row public.user_sessions;
BEGIN
  IF uid IS NULL THEN RAISE EXCEPTION 'Not authenticated'; END IF;
  IF _session_id IS NULL OR length(_session_id) < 8 OR length(_session_id) > 128 THEN
    RAISE EXCEPTION 'Invalid session id';
  END IF;
  INSERT INTO public.user_sessions(user_id, active_session_id, user_agent, updated_at)
  VALUES (uid, _session_id, _user_agent, now())
  ON CONFLICT (user_id) DO UPDATE
    SET active_session_id = EXCLUDED.active_session_id, user_agent = EXCLUDED.user_agent, updated_at = now()
  RETURNING * INTO row;
  RETURN row;
END; $$;

CREATE OR REPLACE FUNCTION public.admin_user_analytics()
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE result jsonb;
BEGIN
  IF NOT public.has_role(auth.uid(), 'admin'::app_role) THEN
    RAISE EXCEPTION 'Forbidden: admin role required';
  END IF;
  SELECT jsonb_build_object(
    'total_users', (SELECT count(*) FROM public.profiles WHERE deleted_at IS NULL),
    'deleted_users', (SELECT count(*) FROM public.profiles WHERE deleted_at IS NOT NULL),
    'active_24h', (SELECT count(DISTINCT user_id) FROM public.user_login_events WHERE login_at >= now() - interval '24 hours'),
    'active_7d', (SELECT count(DISTINCT user_id) FROM public.user_login_events WHERE login_at >= now() - interval '7 days'),
    'active_30d', (SELECT count(DISTINCT user_id) FROM public.user_login_events WHERE login_at >= now() - interval '30 days'),
    'lifetime_active', (SELECT count(DISTINCT user_id) FROM public.user_login_events),
    'total_logins', (SELECT count(*) FROM public.user_login_events),
    'avg_session_seconds', COALESCE((SELECT avg(duration_seconds)::bigint FROM public.user_login_events WHERE duration_seconds IS NOT NULL AND duration_seconds > 0), 0),
    'usage_24h', COALESCE((SELECT sum(duration_seconds)::bigint FROM public.user_login_events WHERE login_at >= now() - interval '24 hours'), 0),
    'usage_7d', COALESCE((SELECT sum(duration_seconds)::bigint FROM public.user_login_events WHERE login_at >= now() - interval '7 days'), 0),
    'usage_30d', COALESCE((SELECT sum(duration_seconds)::bigint FROM public.user_login_events WHERE login_at >= now() - interval '30 days'), 0)
  ) INTO result;
  RETURN result;
END $$;

CREATE OR REPLACE FUNCTION public.admin_top_users(_order text DEFAULT 'most', _limit integer DEFAULT 10)
RETURNS TABLE (user_id uuid, display_name text, total_login_count integer, total_usage_seconds bigint, last_login_at timestamptz)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NOT public.has_role(auth.uid(), 'admin'::app_role) THEN
    RAISE EXCEPTION 'Forbidden: admin role required';
  END IF;
  IF _order = 'least' THEN
    RETURN QUERY SELECT p.id, p.display_name, p.total_login_count, p.total_usage_seconds, p.last_login_at
      FROM public.profiles p WHERE p.deleted_at IS NULL
      ORDER BY p.total_usage_seconds ASC, p.total_login_count ASC LIMIT _limit;
  ELSE
    RETURN QUERY SELECT p.id, p.display_name, p.total_login_count, p.total_usage_seconds, p.last_login_at
      FROM public.profiles p WHERE p.deleted_at IS NULL AND p.total_login_count > 0
      ORDER BY p.total_usage_seconds DESC, p.total_login_count DESC LIMIT _limit;
  END IF;
END $$;

CREATE OR REPLACE FUNCTION public.admin_soft_delete_user(_id uuid)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NOT public.has_role(auth.uid(), 'admin'::app_role) THEN RAISE EXCEPTION 'Forbidden'; END IF;
  IF public.has_role(_id, 'admin'::app_role) THEN RAISE EXCEPTION 'Cannot remove an admin. Demote first.'; END IF;
  UPDATE public.profiles SET deleted_at = now(), status = 'suspended' WHERE id = _id;
END $$;

CREATE OR REPLACE FUNCTION public.admin_restore_user(_id uuid)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NOT public.has_role(auth.uid(), 'admin'::app_role) THEN RAISE EXCEPTION 'Forbidden'; END IF;
  UPDATE public.profiles SET deleted_at = NULL, status = 'active' WHERE id = _id;
END $$;

CREATE OR REPLACE FUNCTION public.admin_hard_delete_user(_id uuid)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, auth AS $$
BEGIN
  IF NOT public.has_role(auth.uid(), 'admin'::app_role) THEN RAISE EXCEPTION 'Forbidden'; END IF;
  IF public.has_role(_id, 'admin'::app_role) THEN RAISE EXCEPTION 'Cannot permanently delete an admin. Demote first.'; END IF;
  DELETE FROM public.user_login_events WHERE user_id = _id;
  DELETE FROM public.user_roles WHERE user_id = _id;
  DELETE FROM public.profiles WHERE id = _id;
  DELETE FROM auth.users WHERE id = _id;
END $$;

CREATE OR REPLACE FUNCTION public.admin_activity_overview(_range_hours integer DEFAULT 24)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE since timestamptz := now() - make_interval(hours => _range_hours); result jsonb;
BEGIN
  IF NOT public.has_role(auth.uid(), 'admin'::app_role) THEN RAISE EXCEPTION 'Forbidden'; END IF;
  SELECT jsonb_build_object(
    'active_now', (SELECT count(DISTINCT user_id) FROM public.activity_events WHERE created_at >= now() - interval '5 minutes' AND user_id IS NOT NULL),
    'unique_users_24h', (SELECT count(DISTINCT user_id) FROM public.activity_events WHERE created_at >= now() - interval '24 hours' AND user_id IS NOT NULL),
    'unique_users_7d', (SELECT count(DISTINCT user_id) FROM public.activity_events WHERE created_at >= now() - interval '7 days' AND user_id IS NOT NULL),
    'unique_users_30d', (SELECT count(DISTINCT user_id) FROM public.activity_events WHERE created_at >= now() - interval '30 days' AND user_id IS NOT NULL),
    'total_events', (SELECT count(*) FROM public.activity_events WHERE created_at >= since),
    'total_clicks', (SELECT count(*) FROM public.activity_events WHERE created_at >= since AND event_type = 'click'),
    'total_page_views', (SELECT count(*) FROM public.activity_events WHERE created_at >= since AND event_type = 'page_view'),
    'total_logins', (SELECT count(*) FROM public.activity_events WHERE created_at >= since AND event_type = 'login'),
    'total_submits', (SELECT count(*) FROM public.activity_events WHERE created_at >= since AND event_type = 'submit'),
    'total_crud', (SELECT count(*) FROM public.activity_events WHERE created_at >= since AND event_type = 'crud'),
    'total_admin_actions', (SELECT count(*) FROM public.activity_events WHERE created_at >= since AND event_type = 'admin_action'),
    'api_errors', (SELECT count(*) FROM public.activity_events WHERE created_at >= since AND event_type = 'api_call' AND (metadata->>'ok')::boolean IS FALSE),
    'range_hours', _range_hours
  ) INTO result;
  RETURN result;
END $$;

CREATE OR REPLACE FUNCTION public.admin_top_buttons(_range_hours integer DEFAULT 24, _limit integer DEFAULT 10)
RETURNS TABLE(element_id text, element_label text, page_path text, click_count bigint)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NOT public.has_role(auth.uid(), 'admin'::app_role) THEN RAISE EXCEPTION 'Forbidden'; END IF;
  RETURN QUERY SELECT
    COALESCE(e.element_id, e.element_label, '(unknown)'),
    COALESCE(e.element_label, e.element_id, '(unknown)'),
    COALESCE(e.page_path, '/'),
    count(*)::bigint
    FROM public.activity_events e
    WHERE e.event_type = 'click' AND e.created_at >= now() - make_interval(hours => _range_hours)
    GROUP BY 1, 2, 3 ORDER BY 4 DESC LIMIT _limit;
END $$;

CREATE OR REPLACE FUNCTION public.admin_top_pages(_range_hours integer DEFAULT 24, _limit integer DEFAULT 10)
RETURNS TABLE(page_path text, view_count bigint, unique_users bigint)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NOT public.has_role(auth.uid(), 'admin'::app_role) THEN RAISE EXCEPTION 'Forbidden'; END IF;
  RETURN QUERY SELECT COALESCE(e.page_path, '/'), count(*)::bigint, count(DISTINCT e.user_id)::bigint
    FROM public.activity_events e
    WHERE e.event_type = 'page_view' AND e.created_at >= now() - make_interval(hours => _range_hours)
    GROUP BY 1 ORDER BY 2 DESC LIMIT _limit;
END $$;

CREATE OR REPLACE FUNCTION public.admin_top_modules(_range_hours integer DEFAULT 24, _limit integer DEFAULT 10)
RETURNS TABLE(module text, event_count bigint, unique_users bigint)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NOT public.has_role(auth.uid(), 'admin'::app_role) THEN RAISE EXCEPTION 'Forbidden'; END IF;
  RETURN QUERY SELECT COALESCE(e.module, '(none)'), count(*)::bigint, count(DISTINCT e.user_id)::bigint
    FROM public.activity_events e
    WHERE e.created_at >= now() - make_interval(hours => _range_hours) AND e.module IS NOT NULL
    GROUP BY 1 ORDER BY 2 DESC LIMIT _limit;
END $$;

CREATE OR REPLACE FUNCTION public.admin_activity_timeseries(_range_hours integer DEFAULT 24, _bucket_minutes integer DEFAULT 60)
RETURNS TABLE(bucket timestamptz, event_type text, event_count bigint)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NOT public.has_role(auth.uid(), 'admin'::app_role) THEN RAISE EXCEPTION 'Forbidden'; END IF;
  RETURN QUERY SELECT date_bin(make_interval(mins => _bucket_minutes), e.created_at, timestamptz 'epoch'),
    e.event_type, count(*)::bigint
    FROM public.activity_events e
    WHERE e.created_at >= now() - make_interval(hours => _range_hours)
    GROUP BY 1, 2 ORDER BY 1 ASC;
END $$;

CREATE OR REPLACE FUNCTION public.admin_user_activity(_user_id uuid, _limit integer DEFAULT 50)
RETURNS TABLE(id uuid, user_id uuid, event_type text, page_path text, element_label text, module text, metadata jsonb, created_at timestamptz)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NOT public.has_role(auth.uid(), 'admin'::app_role) THEN RAISE EXCEPTION 'Forbidden'; END IF;
  RETURN QUERY SELECT e.id, e.user_id, e.event_type, e.page_path, e.element_label, e.module, e.metadata, e.created_at
    FROM public.activity_events e WHERE e.user_id = _user_id ORDER BY e.created_at DESC LIMIT _limit;
END $$;

CREATE OR REPLACE FUNCTION public.has_role(_user_id uuid, _role public.app_role)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT EXISTS (SELECT 1 FROM public.user_roles WHERE user_id = _user_id AND role = _role)
$$;

CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql SET search_path = public AS $$
BEGIN NEW.updated_at = now(); RETURN NEW; END $$;

CREATE OR REPLACE FUNCTION public.admin_get_table_sizes()
RETURNS TABLE(table_name text, size_bytes bigint, row_estimate bigint)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_catalog
AS $$
BEGIN
  IF NOT public.has_role(auth.uid(), 'admin'::public.app_role) THEN
    RAISE EXCEPTION 'Forbidden: admin role required';
  END IF;
  RETURN QUERY
    SELECT c.relname::text, pg_total_relation_size(c.oid)::bigint, c.reltuples::bigint
    FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public' AND c.relkind = 'r'
    ORDER BY pg_total_relation_size(c.oid) DESC;
END; $$;

CREATE OR REPLACE FUNCTION public.admin_get_db_size()
RETURNS bigint LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_catalog
AS $$
DECLARE s bigint;
BEGIN
  IF NOT public.has_role(auth.uid(), 'admin'::public.app_role) THEN
    RAISE EXCEPTION 'Forbidden: admin role required';
  END IF;
  SELECT pg_database_size(current_database()) INTO s;
  RETURN s;
END; $$;

CREATE OR REPLACE FUNCTION public.claim_user_session(_session_id TEXT, _user_agent TEXT DEFAULT NULL)
RETURNS public.user_sessions LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE uid UUID := auth.uid(); row public.user_sessions;
BEGIN
  IF uid IS NULL THEN RAISE EXCEPTION 'Not authenticated'; END IF;
  IF _session_id IS NULL OR length(_session_id) < 8 OR length(_session_id) > 128 THEN
    RAISE EXCEPTION 'Invalid session id';
  END IF;
  INSERT INTO public.user_sessions(user_id, active_session_id, user_agent, updated_at)
  VALUES (uid, _session_id, _user_agent, now())
  ON CONFLICT (user_id) DO UPDATE
    SET active_session_id = EXCLUDED.active_session_id, user_agent = EXCLUDED.user_agent, updated_at = now()
  RETURNING * INTO row;
  RETURN row;
END; $$;

CREATE OR REPLACE FUNCTION public.admin_user_analytics()
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE result jsonb;
BEGIN
  IF NOT public.has_role(auth.uid(), 'admin'::app_role) THEN
    RAISE EXCEPTION 'Forbidden: admin role required';
  END IF;
  SELECT jsonb_build_object(
    'total_users', (SELECT count(*) FROM public.profiles WHERE deleted_at IS NULL),
    'deleted_users', (SELECT count(*) FROM public.profiles WHERE deleted_at IS NOT NULL),
    'active_24h', (SELECT count(DISTINCT user_id) FROM public.user_login_events WHERE login_at >= now() - interval '24 hours'),
    'active_7d', (SELECT count(DISTINCT user_id) FROM public.user_login_events WHERE login_at >= now() - interval '7 days'),
    'active_30d', (SELECT count(DISTINCT user_id) FROM public.user_login_events WHERE login_at >= now() - interval '30 days'),
    'lifetime_active', (SELECT count(DISTINCT user_id) FROM public.user_login_events),
    'total_logins', (SELECT count(*) FROM public.user_login_events),
    'avg_session_seconds', COALESCE((SELECT avg(duration_seconds)::bigint FROM public.user_login_events WHERE duration_seconds IS NOT NULL AND duration_seconds > 0), 0),
    'usage_24h', COALESCE((SELECT sum(duration_seconds)::bigint FROM public.user_login_events WHERE login_at >= now() - interval '24 hours'), 0),
    'usage_7d', COALESCE((SELECT sum(duration_seconds)::bigint FROM public.user_login_events WHERE login_at >= now() - interval '7 days'), 0),
    'usage_30d', COALESCE((SELECT sum(duration_seconds)::bigint FROM public.user_login_events WHERE login_at >= now() - interval '30 days'), 0)
  ) INTO result;
  RETURN result;
END $$;

CREATE OR REPLACE FUNCTION public.admin_top_users(_order text DEFAULT 'most', _limit integer DEFAULT 10)
RETURNS TABLE (user_id uuid, display_name text, total_login_count integer, total_usage_seconds bigint, last_login_at timestamptz)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NOT public.has_role(auth.uid(), 'admin'::app_role) THEN
    RAISE EXCEPTION 'Forbidden: admin role required';
  END IF;
  IF _order = 'least' THEN
    RETURN QUERY SELECT p.id, p.display_name, p.total_login_count, p.total_usage_seconds, p.last_login_at
      FROM public.profiles p WHERE p.deleted_at IS NULL
      ORDER BY p.total_usage_seconds ASC, p.total_login_count ASC LIMIT _limit;
  ELSE
    RETURN QUERY SELECT p.id, p.display_name, p.total_login_count, p.total_usage_seconds, p.last_login_at
      FROM public.profiles p WHERE p.deleted_at IS NULL AND p.total_login_count > 0
      ORDER BY p.total_usage_seconds DESC, p.total_login_count DESC LIMIT _limit;
  END IF;
END $$;

CREATE OR REPLACE FUNCTION public.admin_soft_delete_user(_id uuid)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NOT public.has_role(auth.uid(), 'admin'::app_role) THEN RAISE EXCEPTION 'Forbidden'; END IF;
  IF public.has_role(_id, 'admin'::app_role) THEN RAISE EXCEPTION 'Cannot remove an admin. Demote first.'; END IF;
  UPDATE public.profiles SET deleted_at = now(), status = 'suspended' WHERE id = _id;
END $$;

CREATE OR REPLACE FUNCTION public.admin_restore_user(_id uuid)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NOT public.has_role(auth.uid(), 'admin'::app_role) THEN RAISE EXCEPTION 'Forbidden'; END IF;
  UPDATE public.profiles SET deleted_at = NULL, status = 'active' WHERE id = _id;
END $$;

CREATE OR REPLACE FUNCTION public.admin_hard_delete_user(_id uuid)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, auth AS $$
BEGIN
  IF NOT public.has_role(auth.uid(), 'admin'::app_role) THEN RAISE EXCEPTION 'Forbidden'; END IF;
  IF public.has_role(_id, 'admin'::app_role) THEN RAISE EXCEPTION 'Cannot permanently delete an admin. Demote first.'; END IF;
  DELETE FROM public.user_login_events WHERE user_id = _id;
  DELETE FROM public.user_roles WHERE user_id = _id;
  DELETE FROM public.profiles WHERE id = _id;
  DELETE FROM auth.users WHERE id = _id;
END $$;

CREATE OR REPLACE FUNCTION public.admin_activity_overview(_range_hours integer DEFAULT 24)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE since timestamptz := now() - make_interval(hours => _range_hours); result jsonb;
BEGIN
  IF NOT public.has_role(auth.uid(), 'admin'::app_role) THEN RAISE EXCEPTION 'Forbidden'; END IF;
  SELECT jsonb_build_object(
    'active_now', (SELECT count(DISTINCT user_id) FROM public.activity_events WHERE created_at >= now() - interval '5 minutes' AND user_id IS NOT NULL),
    'unique_users_24h', (SELECT count(DISTINCT user_id) FROM public.activity_events WHERE created_at >= now() - interval '24 hours' AND user_id IS NOT NULL),
    'unique_users_7d', (SELECT count(DISTINCT user_id) FROM public.activity_events WHERE created_at >= now() - interval '7 days' AND user_id IS NOT NULL),
    'unique_users_30d', (SELECT count(DISTINCT user_id) FROM public.activity_events WHERE created_at >= now() - interval '30 days' AND user_id IS NOT NULL),
    'total_events', (SELECT count(*) FROM public.activity_events WHERE created_at >= since),
    'total_clicks', (SELECT count(*) FROM public.activity_events WHERE created_at >= since AND event_type = 'click'),
    'total_page_views', (SELECT count(*) FROM public.activity_events WHERE created_at >= since AND event_type = 'page_view'),
    'total_logins', (SELECT count(*) FROM public.activity_events WHERE created_at >= since AND event_type = 'login'),
    'total_submits', (SELECT count(*) FROM public.activity_events WHERE created_at >= since AND event_type = 'submit'),
    'total_crud', (SELECT count(*) FROM public.activity_events WHERE created_at >= since AND event_type = 'crud'),
    'total_admin_actions', (SELECT count(*) FROM public.activity_events WHERE created_at >= since AND event_type = 'admin_action'),
    'api_errors', (SELECT count(*) FROM public.activity_events WHERE created_at >= since AND event_type = 'api_call' AND (metadata->>'ok')::boolean IS FALSE),
    'range_hours', _range_hours
  ) INTO result;
  RETURN result;
END $$;

CREATE OR REPLACE FUNCTION public.admin_top_buttons(_range_hours integer DEFAULT 24, _limit integer DEFAULT 10)
RETURNS TABLE(element_id text, element_label text, page_path text, click_count bigint)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NOT public.has_role(auth.uid(), 'admin'::app_role) THEN RAISE EXCEPTION 'Forbidden'; END IF;
  RETURN QUERY SELECT
    COALESCE(e.element_id, e.element_label, '(unknown)'),
    COALESCE(e.element_label, e.element_id, '(unknown)'),
    COALESCE(e.page_path, '/'),
    count(*)::bigint
    FROM public.activity_events e
    WHERE e.event_type = 'click' AND e.created_at >= now() - make_interval(hours => _range_hours)
    GROUP BY 1, 2, 3 ORDER BY 4 DESC LIMIT _limit;
END $$;

CREATE OR REPLACE FUNCTION public.admin_top_pages(_range_hours integer DEFAULT 24, _limit integer DEFAULT 10)
RETURNS TABLE(page_path text, view_count bigint, unique_users bigint)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NOT public.has_role(auth.uid(), 'admin'::app_role) THEN RAISE EXCEPTION 'Forbidden'; END IF;
  RETURN QUERY SELECT COALESCE(e.page_path, '/'), count(*)::bigint, count(DISTINCT e.user_id)::bigint
    FROM public.activity_events e
    WHERE e.event_type = 'page_view' AND e.created_at >= now() - make_interval(hours => _range_hours)
    GROUP BY 1 ORDER BY 2 DESC LIMIT _limit;
END $$;

CREATE OR REPLACE FUNCTION public.admin_top_modules(_range_hours integer DEFAULT 24, _limit integer DEFAULT 10)
RETURNS TABLE(module text, event_count bigint, unique_users bigint)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NOT public.has_role(auth.uid(), 'admin'::app_role) THEN RAISE EXCEPTION 'Forbidden'; END IF;
  RETURN QUERY SELECT COALESCE(e.module, '(none)'), count(*)::bigint, count(DISTINCT e.user_id)::bigint
    FROM public.activity_events e
    WHERE e.created_at >= now() - make_interval(hours => _range_hours) AND e.module IS NOT NULL
    GROUP BY 1 ORDER BY 2 DESC LIMIT _limit;
END $$;

CREATE OR REPLACE FUNCTION public.admin_activity_timeseries(_range_hours integer DEFAULT 24, _bucket_minutes integer DEFAULT 60)
RETURNS TABLE(bucket timestamptz, event_type text, event_count bigint)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NOT public.has_role(auth.uid(), 'admin'::app_role) THEN RAISE EXCEPTION 'Forbidden'; END IF;
  RETURN QUERY SELECT date_bin(make_interval(mins => _bucket_minutes), e.created_at, timestamptz 'epoch'),
    e.event_type, count(*)::bigint
    FROM public.activity_events e
    WHERE e.created_at >= now() - make_interval(hours => _range_hours)
    GROUP BY 1, 2 ORDER BY 1 ASC;
END $$;

CREATE OR REPLACE FUNCTION public.admin_user_activity(_user_id uuid, _limit integer DEFAULT 50)
RETURNS TABLE(id uuid, user_id uuid, event_type text, page_path text, element_label text, module text, metadata jsonb, created_at timestamptz)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NOT public.has_role(auth.uid(), 'admin'::app_role) THEN RAISE EXCEPTION 'Forbidden'; END IF;
  RETURN QUERY SELECT e.id, e.user_id, e.event_type, e.page_path, e.element_label, e.module, e.metadata, e.created_at
    FROM public.activity_events e WHERE e.user_id = _user_id ORDER BY e.created_at DESC LIMIT _limit;
END $$;

-- ============================================================
-- updated_at helper
-- ============================================================
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN NEW.updated_at = now(); RETURN NEW; END;
$$;

CREATE OR REPLACE FUNCTION public.has_role(_user_id uuid, _role public.app_role)
RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public
AS $$
  SELECT EXISTS(SELECT 1 FROM public.user_roles WHERE user_id = _user_id AND role = _role)
$$;

-- Auto-create profile + assign student role on sign up
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  INSERT INTO public.profiles (id, display_name, level)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'display_name', NEW.raw_user_meta_data->>'full_name', split_part(NEW.email,'@',1)),
    COALESCE(NEW.raw_user_meta_data->>'level','professional')
  )
  ON CONFLICT (id) DO NOTHING;
  INSERT INTO public.user_roles (user_id, role) VALUES (NEW.id,'student')
  ON CONFLICT DO NOTHING;
  RETURN NEW;
END; $$;

-- Stub RPCs (return shapes that match what the app reads; safe to refine later)
CREATE OR REPLACE FUNCTION public.admin_user_analytics()
RETURNS jsonb LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT jsonb_build_object(
    'dau', (SELECT count(DISTINCT user_id) FROM public.activity_events WHERE created_at >= now() - interval '1 day' AND user_id IS NOT NULL),
    'wau', (SELECT count(DISTINCT user_id) FROM public.activity_events WHERE created_at >= now() - interval '7 days' AND user_id IS NOT NULL),
    'mau', (SELECT count(DISTINCT user_id) FROM public.activity_events WHERE created_at >= now() - interval '30 days' AND user_id IS NOT NULL),
    'total_users', (SELECT count(*) FROM public.profiles),
    'new_7d', (SELECT count(*) FROM public.profiles WHERE created_at >= now() - interval '7 days'),
    'new_30d', (SELECT count(*) FROM public.profiles WHERE created_at >= now() - interval '30 days')
  )
$$;

CREATE OR REPLACE FUNCTION public.admin_activity_overview()
RETURNS jsonb LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT jsonb_build_object(
    'events_24h', (SELECT count(*) FROM public.activity_events WHERE created_at >= now() - interval '1 day'),
    'events_7d', (SELECT count(*) FROM public.activity_events WHERE created_at >= now() - interval '7 days'),
    'events_30d', (SELECT count(*) FROM public.activity_events WHERE created_at >= now() - interval '30 days')
  )
$$;

CREATE OR REPLACE FUNCTION public.admin_top_modules()
RETURNS TABLE(module text, event_count bigint, unique_users bigint)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT module, count(*)::bigint, count(DISTINCT user_id)::bigint
  FROM public.activity_events
  WHERE module IS NOT NULL AND created_at >= now() - interval '30 days'
  GROUP BY module ORDER BY count(*) DESC LIMIT 20
$$;

CREATE OR REPLACE FUNCTION public.admin_top_users()
RETURNS TABLE(user_id uuid, event_count bigint)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT user_id, count(*)::bigint
  FROM public.activity_events
  WHERE user_id IS NOT NULL AND created_at >= now() - interval '30 days'
  GROUP BY user_id ORDER BY count(*) DESC LIMIT 20
$$;

CREATE OR REPLACE FUNCTION public.admin_top_buttons()
RETURNS TABLE(element_id text, element_label text, page_path text, click_count bigint)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT target_id, element_label, page_path, count(*)::bigint
  FROM public.activity_events
  WHERE event_type = 'click' AND created_at >= now() - interval '30 days'
  GROUP BY target_id, element_label, page_path
  ORDER BY count(*) DESC LIMIT 50
$$;

CREATE OR REPLACE FUNCTION public.admin_top_pages()
RETURNS TABLE(page_path text, view_count bigint, unique_users bigint)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT page_path, count(*)::bigint, count(DISTINCT user_id)::bigint
  FROM public.activity_events
  WHERE event_type = 'page_view' AND page_path IS NOT NULL AND created_at >= now() - interval '30 days'
  GROUP BY page_path ORDER BY count(*) DESC LIMIT 50
$$;

CREATE OR REPLACE FUNCTION public.admin_activity_timeseries()
RETURNS TABLE(bucket text, event_type text, event_count bigint)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT to_char(date_trunc('day', created_at), 'YYYY-MM-DD'), event_type, count(*)::bigint
  FROM public.activity_events
  WHERE created_at >= now() - interval '30 days'
  GROUP BY 1,2 ORDER BY 1
$$;

CREATE OR REPLACE FUNCTION public.admin_user_activity()
RETURNS jsonb LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT jsonb_build_object(
    'active_now', (SELECT count(DISTINCT user_id) FROM public.activity_events WHERE created_at >= now() - interval '5 minutes' AND user_id IS NOT NULL),
    'active_24h', (SELECT count(DISTINCT user_id) FROM public.activity_events WHERE created_at >= now() - interval '1 day' AND user_id IS NOT NULL)
  )
$$;

CREATE OR REPLACE FUNCTION public.admin_user_analytics()
RETURNS jsonb LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT jsonb_build_object(
    'total_users', (SELECT count(*) FROM public.profiles WHERE deleted_at IS NULL),
    'deleted_users', (SELECT count(*) FROM public.profiles WHERE deleted_at IS NOT NULL),
    'active_24h', (SELECT count(DISTINCT user_id) FROM public.activity_events WHERE created_at >= now() - interval '1 day' AND user_id IS NOT NULL),
    'active_7d', (SELECT count(DISTINCT user_id) FROM public.activity_events WHERE created_at >= now() - interval '7 days' AND user_id IS NOT NULL),
    'active_30d', (SELECT count(DISTINCT user_id) FROM public.activity_events WHERE created_at >= now() - interval '30 days' AND user_id IS NOT NULL),
    'lifetime_active', (SELECT count(DISTINCT user_id) FROM public.activity_events WHERE user_id IS NOT NULL),
    'total_logins', (SELECT coalesce(sum(total_login_count),0) FROM public.profiles),
    'avg_session_seconds', (SELECT coalesce(avg(duration_seconds),0)::int FROM public.user_login_events WHERE duration_seconds IS NOT NULL),
    'usage_24h', (SELECT coalesce(sum(duration_seconds),0)::int FROM public.user_login_events WHERE login_at >= now() - interval '1 day' AND duration_seconds IS NOT NULL),
    'usage_7d', (SELECT coalesce(sum(duration_seconds),0)::int FROM public.user_login_events WHERE login_at >= now() - interval '7 days' AND duration_seconds IS NOT NULL),
    'usage_30d', (SELECT coalesce(sum(duration_seconds),0)::int FROM public.user_login_events WHERE login_at >= now() - interval '30 days' AND duration_seconds IS NOT NULL),
    'dau', (SELECT count(DISTINCT user_id) FROM public.activity_events WHERE created_at >= now() - interval '1 day' AND user_id IS NOT NULL),
    'wau', (SELECT count(DISTINCT user_id) FROM public.activity_events WHERE created_at >= now() - interval '7 days' AND user_id IS NOT NULL),
    'mau', (SELECT count(DISTINCT user_id) FROM public.activity_events WHERE created_at >= now() - interval '30 days' AND user_id IS NOT NULL),
    'new_7d', (SELECT count(*) FROM public.profiles WHERE created_at >= now() - interval '7 days'),
    'new_30d', (SELECT count(*) FROM public.profiles WHERE created_at >= now() - interval '30 days')
  )
$$;

CREATE OR REPLACE FUNCTION public.admin_activity_overview(_range_hours int DEFAULT 24)
RETURNS jsonb LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT jsonb_build_object(
    'events_window', (SELECT count(*) FROM public.activity_events WHERE created_at >= now() - make_interval(hours => _range_hours)),
    'unique_users_window', (SELECT count(DISTINCT user_id) FROM public.activity_events WHERE created_at >= now() - make_interval(hours => _range_hours) AND user_id IS NOT NULL),
    'page_views_window', (SELECT count(*) FROM public.activity_events WHERE event_type='page_view' AND created_at >= now() - make_interval(hours => _range_hours)),
    'clicks_window', (SELECT count(*) FROM public.activity_events WHERE event_type='click' AND created_at >= now() - make_interval(hours => _range_hours)),
    'events_24h', (SELECT count(*) FROM public.activity_events WHERE created_at >= now() - interval '1 day'),
    'events_7d', (SELECT count(*) FROM public.activity_events WHERE created_at >= now() - interval '7 days'),
    'events_30d', (SELECT count(*) FROM public.activity_events WHERE created_at >= now() - interval '30 days')
  )
$$;

CREATE OR REPLACE FUNCTION public.admin_top_modules(_range_hours int DEFAULT 720, _limit int DEFAULT 10)
RETURNS TABLE(module text, event_count bigint, unique_users bigint)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT module, count(*)::bigint, count(DISTINCT user_id)::bigint
  FROM public.activity_events
  WHERE module IS NOT NULL AND created_at >= now() - make_interval(hours => _range_hours)
  GROUP BY module ORDER BY count(*) DESC LIMIT _limit
$$;

CREATE OR REPLACE FUNCTION public.admin_top_buttons(_range_hours int DEFAULT 720, _limit int DEFAULT 50)
RETURNS TABLE(element_id text, element_label text, page_path text, click_count bigint)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT target_id, element_label, page_path, count(*)::bigint
  FROM public.activity_events
  WHERE event_type='click' AND created_at >= now() - make_interval(hours => _range_hours)
  GROUP BY target_id, element_label, page_path
  ORDER BY count(*) DESC LIMIT _limit
$$;

CREATE OR REPLACE FUNCTION public.admin_top_pages(_range_hours int DEFAULT 720, _limit int DEFAULT 50)
RETURNS TABLE(page_path text, view_count bigint, unique_users bigint)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT page_path, count(*)::bigint, count(DISTINCT user_id)::bigint
  FROM public.activity_events
  WHERE event_type='page_view' AND page_path IS NOT NULL AND created_at >= now() - make_interval(hours => _range_hours)
  GROUP BY page_path ORDER BY count(*) DESC LIMIT _limit
$$;

CREATE OR REPLACE FUNCTION public.admin_activity_timeseries(_range_hours int DEFAULT 720, _bucket_minutes int DEFAULT 1440)
RETURNS TABLE(bucket timestamptz, event_type text, event_count bigint)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT date_bin(
           make_interval(mins => _bucket_minutes),
           created_at,
           timestamptz 'epoch'
         ) AS bucket,
         event_type,
         count(*)::bigint
  FROM public.activity_events
  WHERE created_at >= now() - make_interval(hours => _range_hours)
  GROUP BY 1, 2
  ORDER BY 1
$$;

CREATE OR REPLACE FUNCTION public.admin_top_users(_order text DEFAULT 'most', _limit int DEFAULT 10)
RETURNS TABLE(user_id uuid, display_name text, total_login_count int, total_usage_seconds bigint, last_login_at timestamptz)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT p.id, p.display_name, coalesce(p.total_login_count,0),
         coalesce(p.total_usage_seconds,0)::bigint, p.last_login_at
  FROM public.profiles p
  WHERE p.deleted_at IS NULL
  ORDER BY
    CASE WHEN _order='most' THEN coalesce(p.total_usage_seconds,0) END DESC NULLS LAST,
    CASE WHEN _order='least' THEN coalesce(p.total_usage_seconds,0) END ASC NULLS LAST
  LIMIT _limit
$$;

CREATE OR REPLACE FUNCTION public.admin_user_activity(_user_id uuid, _limit int DEFAULT 50)
RETURNS TABLE(id uuid, user_id uuid, event_type text, page_path text, element_label text, module text, metadata jsonb, created_at timestamptz)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT id, user_id, event_type, page_path, element_label, module, metadata, created_at
  FROM public.activity_events
  WHERE user_id = _user_id
  ORDER BY created_at DESC
  LIMIT _limit
$$;

CREATE OR REPLACE FUNCTION public.admin_soft_delete_user(_id uuid)
RETURNS void LANGUAGE sql SECURITY DEFINER SET search_path = public AS $$
  UPDATE public.profiles SET deleted_at = now(), status = 'suspended' WHERE id = _id;
$$;

CREATE OR REPLACE FUNCTION public.admin_restore_user(_id uuid)
RETURNS void LANGUAGE sql SECURITY DEFINER SET search_path = public AS $$
  UPDATE public.profiles SET deleted_at = NULL, status = 'active' WHERE id = _id;
$$;

CREATE OR REPLACE FUNCTION public.admin_hard_delete_user(_id uuid)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  DELETE FROM public.user_roles WHERE user_id = _id;
  DELETE FROM public.profiles WHERE id = _id;
  BEGIN
    DELETE FROM auth.users WHERE id = _id;
  EXCEPTION WHEN OTHERS THEN NULL;
  END;
END $$;

CREATE OR REPLACE FUNCTION public.has_role(_user_id uuid, _role public.app_role)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT EXISTS (SELECT 1 FROM public.user_roles WHERE user_id = _user_id AND role = _role)
$$;

CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql SET search_path = public AS $$
BEGIN NEW.updated_at = now(); RETURN NEW; END $$;

CREATE OR REPLACE FUNCTION public.admin_get_table_sizes()
RETURNS TABLE(table_name text, size_bytes bigint, row_estimate bigint)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_catalog
AS $$
BEGIN
  IF NOT public.has_role(auth.uid(), 'admin'::public.app_role) THEN
    RAISE EXCEPTION 'Forbidden: admin role required';
  END IF;
  RETURN QUERY
    SELECT c.relname::text, pg_total_relation_size(c.oid)::bigint, c.reltuples::bigint
    FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public' AND c.relkind = 'r'
    ORDER BY pg_total_relation_size(c.oid) DESC;
END; $$;

CREATE OR REPLACE FUNCTION public.admin_get_db_size()
RETURNS bigint LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_catalog
AS $$
DECLARE s bigint;
BEGIN
  IF NOT public.has_role(auth.uid(), 'admin'::public.app_role) THEN
    RAISE EXCEPTION 'Forbidden: admin role required';
  END IF;
  SELECT pg_database_size(current_database()) INTO s;
  RETURN s;
END; $$;

CREATE OR REPLACE FUNCTION public.claim_user_session(_session_id TEXT, _user_agent TEXT DEFAULT NULL)
RETURNS public.user_sessions LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE uid UUID := auth.uid(); row public.user_sessions;
BEGIN
  IF uid IS NULL THEN RAISE EXCEPTION 'Not authenticated'; END IF;
  IF _session_id IS NULL OR length(_session_id) < 8 OR length(_session_id) > 128 THEN
    RAISE EXCEPTION 'Invalid session id';
  END IF;
  INSERT INTO public.user_sessions(user_id, active_session_id, user_agent, updated_at)
  VALUES (uid, _session_id, _user_agent, now())
  ON CONFLICT (user_id) DO UPDATE
    SET active_session_id = EXCLUDED.active_session_id, user_agent = EXCLUDED.user_agent, updated_at = now()
  RETURNING * INTO row;
  RETURN row;
END; $$;

CREATE OR REPLACE FUNCTION public.admin_user_analytics()
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE result jsonb;
BEGIN
  IF NOT public.has_role(auth.uid(), 'admin'::app_role) THEN
    RAISE EXCEPTION 'Forbidden: admin role required';
  END IF;
  SELECT jsonb_build_object(
    'total_users', (SELECT count(*) FROM public.profiles WHERE deleted_at IS NULL),
    'deleted_users', (SELECT count(*) FROM public.profiles WHERE deleted_at IS NOT NULL),
    'active_24h', (SELECT count(DISTINCT user_id) FROM public.user_login_events WHERE login_at >= now() - interval '24 hours'),
    'active_7d', (SELECT count(DISTINCT user_id) FROM public.user_login_events WHERE login_at >= now() - interval '7 days'),
    'active_30d', (SELECT count(DISTINCT user_id) FROM public.user_login_events WHERE login_at >= now() - interval '30 days'),
    'lifetime_active', (SELECT count(DISTINCT user_id) FROM public.user_login_events),
    'total_logins', (SELECT count(*) FROM public.user_login_events),
    'avg_session_seconds', COALESCE((SELECT avg(duration_seconds)::bigint FROM public.user_login_events WHERE duration_seconds IS NOT NULL AND duration_seconds > 0), 0),
    'usage_24h', COALESCE((SELECT sum(duration_seconds)::bigint FROM public.user_login_events WHERE login_at >= now() - interval '24 hours'), 0),
    'usage_7d', COALESCE((SELECT sum(duration_seconds)::bigint FROM public.user_login_events WHERE login_at >= now() - interval '7 days'), 0),
    'usage_30d', COALESCE((SELECT sum(duration_seconds)::bigint FROM public.user_login_events WHERE login_at >= now() - interval '30 days'), 0)
  ) INTO result;
  RETURN result;
END $$;

DROP FUNCTION IF EXISTS public.admin_top_users(text, integer);
CREATE OR REPLACE FUNCTION public.admin_top_users(_order text DEFAULT 'most', _limit integer DEFAULT 10)
RETURNS TABLE (user_id uuid, email text, display_name text, full_name text, total_login_count integer, total_usage_seconds bigint, last_login_at timestamptz)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, auth AS $$
BEGIN
  IF NOT public.has_role(auth.uid(), 'admin'::app_role) THEN
    RAISE EXCEPTION 'Forbidden: admin role required';
  END IF;
  IF _order = 'least' THEN
    RETURN QUERY SELECT p.id, u.email::text, p.display_name,
        COALESCE(p.display_name, NULLIF(u.raw_user_meta_data->>'full_name',''), NULLIF(u.raw_user_meta_data->>'name',''), u.email::text) AS full_name,
        p.total_login_count, p.total_usage_seconds, p.last_login_at
      FROM public.profiles p LEFT JOIN auth.users u ON u.id = p.id
      WHERE p.deleted_at IS NULL
      ORDER BY p.total_usage_seconds ASC, p.total_login_count ASC LIMIT _limit;
  ELSE
    RETURN QUERY SELECT p.id, u.email::text, p.display_name,
        COALESCE(p.display_name, NULLIF(u.raw_user_meta_data->>'full_name',''), NULLIF(u.raw_user_meta_data->>'name',''), u.email::text) AS full_name,
        p.total_login_count, p.total_usage_seconds, p.last_login_at
      FROM public.profiles p LEFT JOIN auth.users u ON u.id = p.id
      WHERE p.deleted_at IS NULL AND p.total_login_count > 0
      ORDER BY p.total_usage_seconds DESC, p.total_login_count DESC LIMIT _limit;
  END IF;
END $$;

CREATE OR REPLACE FUNCTION public.admin_soft_delete_user(_id uuid)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NOT public.has_role(auth.uid(), 'admin'::app_role) THEN RAISE EXCEPTION 'Forbidden'; END IF;
  IF public.has_role(_id, 'admin'::app_role) THEN RAISE EXCEPTION 'Cannot remove an admin. Demote first.'; END IF;
  UPDATE public.profiles SET deleted_at = now(), status = 'suspended' WHERE id = _id;
END $$;

CREATE OR REPLACE FUNCTION public.admin_restore_user(_id uuid)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NOT public.has_role(auth.uid(), 'admin'::app_role) THEN RAISE EXCEPTION 'Forbidden'; END IF;
  UPDATE public.profiles SET deleted_at = NULL, status = 'active' WHERE id = _id;
END $$;

CREATE OR REPLACE FUNCTION public.admin_hard_delete_user(_id uuid)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, auth AS $$
BEGIN
  IF NOT public.has_role(auth.uid(), 'admin'::app_role) THEN RAISE EXCEPTION 'Forbidden'; END IF;
  IF public.has_role(_id, 'admin'::app_role) THEN RAISE EXCEPTION 'Cannot permanently delete an admin. Demote first.'; END IF;
  DELETE FROM public.user_login_events WHERE user_id = _id;
  DELETE FROM public.user_roles WHERE user_id = _id;
  DELETE FROM public.profiles WHERE id = _id;
  DELETE FROM auth.users WHERE id = _id;
END $$;

CREATE OR REPLACE FUNCTION public.admin_activity_overview(_range_hours integer DEFAULT 24)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE since timestamptz := now() - make_interval(hours => _range_hours); result jsonb;
BEGIN
  IF NOT public.has_role(auth.uid(), 'admin'::app_role) THEN RAISE EXCEPTION 'Forbidden'; END IF;
  SELECT jsonb_build_object(
    'active_now', (SELECT count(DISTINCT user_id) FROM public.activity_events WHERE created_at >= now() - interval '5 minutes' AND user_id IS NOT NULL),
    'unique_users_24h', (SELECT count(DISTINCT user_id) FROM public.activity_events WHERE created_at >= now() - interval '24 hours' AND user_id IS NOT NULL),
    'unique_users_7d', (SELECT count(DISTINCT user_id) FROM public.activity_events WHERE created_at >= now() - interval '7 days' AND user_id IS NOT NULL),
    'unique_users_30d', (SELECT count(DISTINCT user_id) FROM public.activity_events WHERE created_at >= now() - interval '30 days' AND user_id IS NOT NULL),
    'total_events', (SELECT count(*) FROM public.activity_events WHERE created_at >= since),
    'total_clicks', (SELECT count(*) FROM public.activity_events WHERE created_at >= since AND event_type = 'click'),
    'total_page_views', (SELECT count(*) FROM public.activity_events WHERE created_at >= since AND event_type = 'page_view'),
    'total_logins', (SELECT count(*) FROM public.activity_events WHERE created_at >= since AND event_type = 'login'),
    'total_submits', (SELECT count(*) FROM public.activity_events WHERE created_at >= since AND event_type = 'submit'),
    'total_crud', (SELECT count(*) FROM public.activity_events WHERE created_at >= since AND event_type = 'crud'),
    'total_admin_actions', (SELECT count(*) FROM public.activity_events WHERE created_at >= since AND event_type = 'admin_action'),
    'api_errors', (SELECT count(*) FROM public.activity_events WHERE created_at >= since AND event_type = 'api_call' AND (metadata->>'ok')::boolean IS FALSE),
    'range_hours', _range_hours
  ) INTO result;
  RETURN result;
END $$;

CREATE OR REPLACE FUNCTION public.admin_top_buttons(_range_hours integer DEFAULT 24, _limit integer DEFAULT 10)
RETURNS TABLE(element_id text, element_label text, page_path text, click_count bigint)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NOT public.has_role(auth.uid(), 'admin'::app_role) THEN RAISE EXCEPTION 'Forbidden'; END IF;
  RETURN QUERY SELECT
    COALESCE(e.element_id, e.element_label, '(unknown)'),
    COALESCE(e.element_label, e.element_id, '(unknown)'),
    COALESCE(e.page_path, '/'),
    count(*)::bigint
    FROM public.activity_events e
    WHERE e.event_type = 'click' AND e.created_at >= now() - make_interval(hours => _range_hours)
    GROUP BY 1, 2, 3 ORDER BY 4 DESC LIMIT _limit;
END $$;

CREATE OR REPLACE FUNCTION public.admin_top_pages(_range_hours integer DEFAULT 24, _limit integer DEFAULT 10)
RETURNS TABLE(page_path text, view_count bigint, unique_users bigint)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NOT public.has_role(auth.uid(), 'admin'::app_role) THEN RAISE EXCEPTION 'Forbidden'; END IF;
  RETURN QUERY SELECT COALESCE(e.page_path, '/'), count(*)::bigint, count(DISTINCT e.user_id)::bigint
    FROM public.activity_events e
    WHERE e.event_type = 'page_view' AND e.created_at >= now() - make_interval(hours => _range_hours)
    GROUP BY 1 ORDER BY 2 DESC LIMIT _limit;
END $$;

CREATE OR REPLACE FUNCTION public.admin_top_modules(_range_hours integer DEFAULT 24, _limit integer DEFAULT 10)
RETURNS TABLE(module text, event_count bigint, unique_users bigint)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NOT public.has_role(auth.uid(), 'admin'::app_role) THEN RAISE EXCEPTION 'Forbidden'; END IF;
  RETURN QUERY SELECT COALESCE(e.module, '(none)'), count(*)::bigint, count(DISTINCT e.user_id)::bigint
    FROM public.activity_events e
    WHERE e.created_at >= now() - make_interval(hours => _range_hours) AND e.module IS NOT NULL
    GROUP BY 1 ORDER BY 2 DESC LIMIT _limit;
END $$;

CREATE OR REPLACE FUNCTION public.admin_activity_timeseries(_range_hours integer DEFAULT 24, _bucket_minutes integer DEFAULT 60)
RETURNS TABLE(bucket timestamptz, event_type text, event_count bigint)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NOT public.has_role(auth.uid(), 'admin'::app_role) THEN RAISE EXCEPTION 'Forbidden'; END IF;
  RETURN QUERY SELECT date_bin(make_interval(mins => _bucket_minutes), e.created_at, timestamptz 'epoch'),
    e.event_type, count(*)::bigint
    FROM public.activity_events e
    WHERE e.created_at >= now() - make_interval(hours => _range_hours)
    GROUP BY 1, 2 ORDER BY 1 ASC;
END $$;

DROP FUNCTION IF EXISTS public.admin_user_activity(uuid, integer);
CREATE OR REPLACE FUNCTION public.admin_user_activity(_user_id uuid, _limit integer DEFAULT 50)
RETURNS TABLE(id uuid, user_id uuid, email text, display_name text, full_name text, event_type text, page_path text, element_label text, module text, metadata jsonb, created_at timestamptz)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, auth AS $$
BEGIN
  IF NOT public.has_role(auth.uid(), 'admin'::app_role) THEN RAISE EXCEPTION 'Forbidden'; END IF;
  RETURN QUERY SELECT e.id, e.user_id, u.email::text, p.display_name,
      COALESCE(p.display_name, NULLIF(u.raw_user_meta_data->>'full_name',''), NULLIF(u.raw_user_meta_data->>'name',''), u.email::text) AS full_name,
      e.event_type, e.page_path, e.element_label, e.module, e.metadata, e.created_at
    FROM public.activity_events e
    LEFT JOIN auth.users u ON u.id = e.user_id
    LEFT JOIN public.profiles p ON p.id = e.user_id
    WHERE e.user_id = _user_id ORDER BY e.created_at DESC LIMIT _limit;
END $$;

-- Role listing with user identity (id + email + name + role)
DROP FUNCTION IF EXISTS public.admin_list_user_roles(public.app_role);
CREATE OR REPLACE FUNCTION public.admin_list_user_roles(_role public.app_role DEFAULT NULL)
RETURNS TABLE(user_id uuid, email text, display_name text, full_name text, role public.app_role, assigned_at timestamptz)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, auth AS $$
BEGIN
  IF NOT public.has_role(auth.uid(), 'admin'::app_role) THEN
    RAISE EXCEPTION 'Forbidden: admin role required';
  END IF;
  RETURN QUERY
    SELECT
      ur.user_id,
      u.email::text,
      p.display_name,
      COALESCE(
        NULLIF(p.display_name, ''),
        NULLIF(u.raw_user_meta_data->>'full_name',''),
        NULLIF(u.raw_user_meta_data->>'name',''),
        u.email::text
      ) AS full_name,
      ur.role,
      ur.created_at AS assigned_at
    FROM public.user_roles ur
    LEFT JOIN auth.users u ON u.id = ur.user_id
    LEFT JOIN public.profiles p ON p.id = ur.user_id
    WHERE (_role IS NULL OR ur.role = _role)
    ORDER BY ur.role, full_name NULLS LAST;
END $$;

GRANT EXECUTE ON FUNCTION public.admin_list_user_roles(public.app_role) TO authenticated;



CREATE OR REPLACE FUNCTION public.mcqs_validate_question_type()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
  IF NEW.question_type = 'true_false' THEN
    IF NEW.option_a IS NULL OR length(btrim(NEW.option_a)) = 0
       OR NEW.option_b IS NULL OR length(btrim(NEW.option_b)) = 0 THEN
      RAISE EXCEPTION 'True/False questions require option_a and option_b';
    END IF;
    NEW.option_c := NULL;
    NEW.option_d := NULL;
    IF NEW.correct_option NOT IN ('A','B') THEN
      RAISE EXCEPTION 'True/False correct_option must be A or B';
    END IF;
  ELSE
    IF NEW.option_a IS NULL OR NEW.option_b IS NULL OR NEW.option_c IS NULL OR NEW.option_d IS NULL THEN
      RAISE EXCEPTION 'MCQ questions require all four options';
    END IF;
  END IF;
  RETURN NEW;
END $$;

-- ------------------------------------------------------------
-- Migration: 20260608042905_0591f81b-62ac-48e5-acc6-ebf21543b118.sql
-- ------------------------------------------------------------

-- 1) List all public tables with size + row estimate (admin only)
CREATE OR REPLACE FUNCTION public.admin_list_public_tables()
RETURNS TABLE(table_name text, size_bytes bigint, row_estimate bigint, rls_enabled boolean)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_catalog
AS $$
BEGIN
  IF NOT public.has_role(auth.uid(), 'admin'::public.app_role) THEN
    RAISE EXCEPTION 'Forbidden: admin role required';
  END IF;
  RETURN QUERY
    SELECT c.relname::text,
           pg_total_relation_size(c.oid)::bigint,
           c.reltuples::bigint,
           c.relrowsecurity
    FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public' AND c.relkind = 'r'
    ORDER BY c.relname ASC;
END; $$;

-- 2) Full table metadata as JSON (columns, fks, indexes, policies)
CREATE OR REPLACE FUNCTION public.admin_table_metadata(_table text)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_catalog, information_schema
AS $$
DECLARE
  cols jsonb;
  fks jsonb;
  inbound_fks jsonb;
  idx jsonb;
  pols jsonb;
  pk_cols text[];
  tbl_exists boolean;
BEGIN
  IF NOT public.has_role(auth.uid(), 'admin'::public.app_role) THEN
    RAISE EXCEPTION 'Forbidden: admin role required';
  END IF;

  SELECT EXISTS (
    SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname='public' AND c.relname = _table AND c.relkind='r'
  ) INTO tbl_exists;
  IF NOT tbl_exists THEN
    RAISE EXCEPTION 'Unknown public table: %', _table;
  END IF;

  -- primary key columns
  SELECT COALESCE(array_agg(a.attname ORDER BY array_position(i.indkey::int[], a.attnum)), ARRAY[]::text[])
  INTO pk_cols
  FROM pg_index i
  JOIN pg_class c ON c.oid = i.indrelid
  JOIN pg_namespace n ON n.oid = c.relnamespace
  JOIN pg_attribute a ON a.attrelid = c.oid AND a.attnum = ANY (i.indkey)
  WHERE i.indisprimary AND n.nspname='public' AND c.relname=_table;

  -- columns
  SELECT COALESCE(jsonb_agg(jsonb_build_object(
      'name', column_name,
      'data_type', data_type,
      'is_nullable', is_nullable = 'YES',
      'default', column_default,
      'ordinal_position', ordinal_position,
      'is_pk', column_name = ANY(pk_cols)
  ) ORDER BY ordinal_position), '[]'::jsonb)
  INTO cols
  FROM information_schema.columns
  WHERE table_schema='public' AND table_name=_table;

  -- outbound foreign keys (this table -> other)
  SELECT COALESCE(jsonb_agg(jsonb_build_object(
      'constraint_name', conname,
      'columns', cols_arr,
      'foreign_table', ref_tbl,
      'foreign_columns', ref_cols
  )), '[]'::jsonb)
  INTO fks
  FROM (
    SELECT con.conname,
      (SELECT array_agg(attname ORDER BY a.ord) FROM unnest(con.conkey) WITH ORDINALITY a(attnum, ord)
         JOIN pg_attribute pa ON pa.attrelid = con.conrelid AND pa.attnum = a.attnum) AS cols_arr,
      ref_cls.relname AS ref_tbl,
      (SELECT array_agg(attname ORDER BY a.ord) FROM unnest(con.confkey) WITH ORDINALITY a(attnum, ord)
         JOIN pg_attribute pa ON pa.attrelid = con.confrelid AND pa.attnum = a.attnum) AS ref_cols
    FROM pg_constraint con
    JOIN pg_class cls ON cls.oid = con.conrelid
    JOIN pg_namespace ns ON ns.oid = cls.relnamespace
    JOIN pg_class ref_cls ON ref_cls.oid = con.confrelid
    WHERE con.contype='f' AND ns.nspname='public' AND cls.relname=_table
  ) s;

  -- inbound foreign keys (other -> this table)
  SELECT COALESCE(jsonb_agg(jsonb_build_object(
      'constraint_name', conname,
      'from_table', from_tbl,
      'from_columns', from_cols,
      'columns', to_cols
  )), '[]'::jsonb)
  INTO inbound_fks
  FROM (
    SELECT con.conname,
      cls.relname AS from_tbl,
      (SELECT array_agg(attname ORDER BY a.ord) FROM unnest(con.conkey) WITH ORDINALITY a(attnum, ord)
         JOIN pg_attribute pa ON pa.attrelid = con.conrelid AND pa.attnum = a.attnum) AS from_cols,
      (SELECT array_agg(attname ORDER BY a.ord) FROM unnest(con.confkey) WITH ORDINALITY a(attnum, ord)
         JOIN pg_attribute pa ON pa.attrelid = con.confrelid AND pa.attnum = a.attnum) AS to_cols
    FROM pg_constraint con
    JOIN pg_class cls ON cls.oid = con.conrelid
    JOIN pg_namespace ns ON ns.oid = cls.relnamespace
    JOIN pg_class ref_cls ON ref_cls.oid = con.confrelid
    JOIN pg_namespace rns ON rns.oid = ref_cls.relnamespace
    WHERE con.contype='f' AND rns.nspname='public' AND ref_cls.relname=_table
  ) s;

  -- indexes
  SELECT COALESCE(jsonb_agg(jsonb_build_object(
      'name', indexname, 'definition', indexdef
  )), '[]'::jsonb)
  INTO idx
  FROM pg_indexes WHERE schemaname='public' AND tablename=_table;

  -- RLS policies
  SELECT COALESCE(jsonb_agg(jsonb_build_object(
      'name', policyname,
      'command', cmd,
      'roles', roles,
      'permissive', permissive,
      'using', qual,
      'with_check', with_check
  )), '[]'::jsonb)
  INTO pols
  FROM pg_policies WHERE schemaname='public' AND tablename=_table;

  RETURN jsonb_build_object(
    'table', _table,
    'primary_key', to_jsonb(pk_cols),
    'columns', cols,
    'foreign_keys', fks,
    'referenced_by', inbound_fks,
    'indexes', idx,
    'policies', pols
  );
END; $$;

-- 3) Safe SELECT runner: only single SELECT/WITH, admin only, hard row cap
CREATE OR REPLACE FUNCTION public.admin_run_select_query(_sql text, _max_rows int DEFAULT 200)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE
  trimmed text;
  lowered text;
  forbidden text;
  result jsonb;
  wrapped text;
BEGIN
  IF NOT public.has_role(auth.uid(), 'admin'::public.app_role) THEN
    RAISE EXCEPTION 'Forbidden: admin role required';
  END IF;
  IF _sql IS NULL OR length(btrim(_sql)) = 0 THEN
    RAISE EXCEPTION 'Empty query';
  END IF;
  trimmed := btrim(_sql);
  -- strip trailing semicolons
  WHILE right(trimmed, 1) = ';' LOOP
    trimmed := btrim(left(trimmed, length(trimmed)-1));
  END LOOP;
  IF position(';' in trimmed) > 0 THEN
    RAISE EXCEPTION 'Only a single statement is allowed';
  END IF;
  lowered := lower(trimmed);
  IF NOT (lowered LIKE 'select%' OR lowered LIKE 'with%') THEN
    RAISE EXCEPTION 'Only SELECT / WITH queries are allowed';
  END IF;
  FOREACH forbidden IN ARRAY ARRAY[
    'insert ','update ','delete ','drop ','alter ','create ','grant ','revoke ',
    'truncate ','vacuum ','copy ','do ','call ','comment ','reindex ','listen ',
    'notify ','prepare ','execute ','reset ','set ','lock ','refresh ','cluster ',
    'security definer','pg_sleep'
  ] LOOP
    IF position(forbidden in lowered) > 0 THEN
      RAISE EXCEPTION 'Forbidden token in query: %', trim(forbidden);
    END IF;
  END LOOP;

  _max_rows := GREATEST(1, LEAST(COALESCE(_max_rows, 200), 1000));
  wrapped := format('SELECT COALESCE(jsonb_agg(t), ''[]''::jsonb) FROM (%s LIMIT %s) t', trimmed, _max_rows);
  EXECUTE wrapped INTO result;
  RETURN jsonb_build_object('rows', result, 'limit', _max_rows);
END; $$;

-- 4) Global search across common text columns in public tables (admin only)
CREATE OR REPLACE FUNCTION public.admin_global_search(_term text, _limit int DEFAULT 50)
RETURNS TABLE(table_name text, id text, snippet text)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_catalog, information_schema
AS $$
DECLARE
  rec record;
  pattern text;
  sql text;
  per int := GREATEST(1, LEAST(COALESCE(_limit, 50), 200));
BEGIN
  IF NOT public.has_role(auth.uid(), 'admin'::public.app_role) THEN
    RAISE EXCEPTION 'Forbidden: admin role required';
  END IF;
  IF _term IS NULL OR length(btrim(_term)) < 2 THEN
    RETURN;
  END IF;
  pattern := '%' || btrim(_term) || '%';
  FOR rec IN
    SELECT c.table_name, string_agg(quote_ident(c.column_name), ',' ORDER BY c.ordinal_position) AS cols,
           string_agg(format('%I::text ILIKE %L', c.column_name, pattern), ' OR ' ORDER BY c.ordinal_position) AS where_clause,
           (SELECT a.attname FROM pg_index i
              JOIN pg_class cls ON cls.oid = i.indrelid
              JOIN pg_namespace ns ON ns.oid = cls.relnamespace
              JOIN pg_attribute a ON a.attrelid = cls.oid AND a.attnum = ANY (i.indkey)
              WHERE i.indisprimary AND ns.nspname='public' AND cls.relname = c.table_name
              LIMIT 1) AS pk_col
    FROM information_schema.columns c
    WHERE c.table_schema='public'
      AND c.column_name IN ('name','title','email','label','key','slug','display_name','description','question','body','content')
      AND c.data_type IN ('text','character varying','character','uuid')
    GROUP BY c.table_name
  LOOP
    BEGIN
      sql := format(
        'SELECT %L::text, COALESCE(%s::text, ''(no pk)''), left(concat_ws('' | '', %s)::text, 200) FROM public.%I WHERE %s LIMIT %s',
        rec.table_name,
        COALESCE(quote_ident(rec.pk_col), '''(no pk)'''),
        rec.cols, rec.table_name, rec.where_clause, per
      );
      RETURN QUERY EXECUTE sql;
    EXCEPTION WHEN OTHERS THEN
      -- skip tables that fail (permission, type mismatches, etc.)
      CONTINUE;
    END;
  END LOOP;
END; $$;

-- ------------------------------------------------------------
-- Migration: 20260608173325_2d0249c3-04ec-4e76-abce-88896b70dd29.sql
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION public._lovable_import_exec(q text) RETURNS void LANGUAGE plpgsql SECURITY DEFINER AS $$ BEGIN EXECUTE q; END; $$;

CREATE OR REPLACE FUNCTION public.has_permission(_user_id uuid, _permission text)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.user_roles ur
    WHERE ur.user_id = _user_id
      AND (ur.role = 'super_admin'::public.app_role
        OR EXISTS (
          SELECT 1 FROM public.role_permissions rp
          WHERE rp.role = ur.role AND rp.permission = _permission
        ))
  )
$$;

CREATE OR REPLACE FUNCTION public.role_permissions_guard()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  has_super boolean;
BEGIN
  IF TG_OP = 'INSERT' AND NEW.role = 'super_admin'::public.app_role THEN
    RAISE EXCEPTION 'super_admin permissions are managed automatically and cannot be modified';
  END IF;
  IF TG_OP IN ('UPDATE','DELETE') AND OLD.role = 'super_admin'::public.app_role THEN
    RAISE EXCEPTION 'super_admin permissions are immutable';
  END IF;

  IF TG_OP = 'DELETE' AND OLD.role = 'admin'::public.app_role
     AND OLD.permission IN ('manage_permissions','manage_users') THEN
    SELECT EXISTS(SELECT 1 FROM public.user_roles WHERE role = 'super_admin'::public.app_role)
      INTO has_super;
    IF NOT has_super THEN
      RAISE EXCEPTION 'Cannot remove % from admin role: no super_admin exists as fallback safeguard', OLD.permission;
    END IF;
  END IF;

  RETURN COALESCE(NEW, OLD);
END
$$;

CREATE OR REPLACE FUNCTION public.has_role(_user_id uuid, _role public.app_role)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT EXISTS (SELECT 1 FROM public.user_roles WHERE user_id = _user_id AND role = _role)
$$;

CREATE OR REPLACE FUNCTION public.is_editor_admin()
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT public.has_role(auth.uid(), 'admin'::public.app_role)
$$;

CREATE OR REPLACE FUNCTION public.editor_set_updated_at()
RETURNS trigger LANGUAGE plpgsql SET search_path = public AS $$
BEGIN NEW.updated_at = now(); RETURN NEW; END $$;

-- ---------- Atomic publish RPC ----------
-- Validates expected version, writes snapshot, upserts live row, logs the action — all in one txn.
CREATE OR REPLACE FUNCTION public.editor_publish_page(
  _page_id text,
  _expected_version uuid,
  _new_version uuid,
  _state jsonb,
  _summary text DEFAULT NULL
) RETURNS public.editor_published_pages
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  current_version uuid;
  result public.editor_published_pages;
BEGIN
  IF NOT public.is_editor_admin() THEN
    RAISE EXCEPTION 'forbidden' USING ERRCODE = '42501';
  END IF;

  SELECT version_id INTO current_version FROM public.editor_pages WHERE page_id = _page_id;
  IF current_version IS NOT NULL AND _expected_version IS NOT NULL AND current_version <> _expected_version THEN
    RAISE EXCEPTION 'version_conflict: expected=% actual=%', _expected_version, current_version USING ERRCODE = 'P0001';
  END IF;

  INSERT INTO public.editor_snapshots (version_id, page_id, parent_version_id, snapshot, summary, author_id)
  VALUES (_new_version, _page_id, current_version, _state, COALESCE(_summary, 'publish'), auth.uid())
  ON CONFLICT (version_id) DO NOTHING;

  INSERT INTO public.editor_published_pages (page_id, version_id, published_state, published_by, published_at)
  VALUES (_page_id, _new_version, _state, auth.uid(), now())
  ON CONFLICT (page_id) DO UPDATE
    SET version_id = EXCLUDED.version_id,
        published_state = EXCLUDED.published_state,
        published_by = EXCLUDED.published_by,
        published_at = now()
  RETURNING * INTO result;

  INSERT INTO public.editor_actions_log (page_id, version_id, author_id, action_type, payload)
  VALUES (_page_id, _new_version, auth.uid(), 'publish', jsonb_build_object('summary', _summary));

  RETURN result;
END $$;

-- ------------------------------------------------------------
-- Migration: 20260609044142_e2f19ee4-e032-48e4-a6fe-6ac1d3501e23.sql
-- ------------------------------------------------------------
-- (skipped: orphan fragment of split bootstrap migration)

-- ------------------------------------------------------------
-- Migration: 20260609044218_8d457bec-8295-4a29-b888-f15300bac8c2.sql
-- ------------------------------------------------------------
-- (skipped: orphan EXCEPTION/END fragments of split bootstrap migration)

-- ------------------------------------------------------------
-- Migration: 20260609044511_1977bcd2-a6ec-4023-8ecd-0eca8b61b700.sql
-- ------------------------------------------------------------
-- ownership changes intentionally omitted for Supabase compatibility

-- ------------------------------------------------------------
-- Migration: 20260609052016_c6e0071e-e430-4fb5-a833-be10ade1240a.sql
-- ------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.admin_run_select_query(_sql text, _max_rows integer DEFAULT 200)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  trimmed text;
  lowered text;
  forbidden text;
  result jsonb;
  wrapped text;
BEGIN
  IF NOT public.has_role(auth.uid(), 'admin'::public.app_role) THEN
    RAISE EXCEPTION 'Forbidden: admin role required';
  END IF;
  IF _sql IS NULL OR length(btrim(_sql)) = 0 THEN
    RAISE EXCEPTION 'Empty query';
  END IF;
  trimmed := btrim(_sql);
  WHILE right(trimmed, 1) = ';' LOOP
    trimmed := btrim(left(trimmed, length(trimmed)-1));
  END LOOP;
  IF position(';' in trimmed) > 0 THEN
    RAISE EXCEPTION 'Only a single statement is allowed';
  END IF;
  lowered := lower(trimmed);
  IF NOT (lowered LIKE 'select%' OR lowered LIKE 'with%') THEN
    RAISE EXCEPTION 'Only SELECT / WITH queries are allowed';
  END IF;
  FOREACH forbidden IN ARRAY ARRAY[
    'insert ','update ','delete ','drop ','alter ','create ','grant ','revoke ',
    'truncate ','vacuum ','copy ','do ','call ','comment ','reindex ','listen ',
    'notify ','prepare ','execute ','reset ','set ','lock ','refresh ','cluster ',
    'security definer','pg_sleep','pg_read_server_files','pg_read_binary_file',
    'pg_ls_dir','pg_stat_file','lo_import','lo_export','dblink',
    'pg_catalog.','information_schema.','pg_authid','pg_shadow','pg_user',
    'pg_largeobject','pg_roles'
  ] LOOP
    IF position(forbidden in lowered) > 0 THEN
      RAISE EXCEPTION 'Forbidden token in query: %', trim(forbidden);
    END IF;
  END LOOP;

  _max_rows := GREATEST(1, LEAST(COALESCE(_max_rows, 200), 500));
  -- Defense-in-depth: cap how long this query can run on the server.
  PERFORM set_config('statement_timeout', '5000', true);
  wrapped := format('SELECT COALESCE(jsonb_agg(t), ''[]''::jsonb) FROM (%s LIMIT %s) t', trimmed, _max_rows);
  EXECUTE wrapped INTO result;
  RETURN jsonb_build_object('rows', result, 'limit', _max_rows);
END; $function$;

-- Controlled entry point that dedupes by fingerprint (last hour) and validates input.
CREATE OR REPLACE FUNCTION public.admin_log_system_error(
  _source TEXT,
  _severity TEXT,
  _message TEXT,
  _stack TEXT DEFAULT NULL,
  _route TEXT DEFAULT NULL,
  _user_agent TEXT DEFAULT NULL,
  _payload JSONB DEFAULT NULL,
  _fingerprint TEXT DEFAULT NULL
) RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_id UUID;

v_fp TEXT;

BEGIN
  IF _source IS NULL OR _source NOT IN ('frontend','backend','db','network','unknown') THEN
    _source := 'unknown';

END IF;

IF _severity IS NULL OR _severity NOT IN ('critical','high','medium','low') THEN
    _severity := 'medium';

END IF;

IF _message IS NULL OR length(btrim(_message)) = 0 THEN
    RAISE EXCEPTION 'message required';

END IF;

-- truncate hostile sizes
  _message := left(_message, 2000);

_stack := left(COALESCE(_stack, ''), 8000);

_route := left(COALESCE(_route, ''), 500);

_user_agent := left(COALESCE(_user_agent, ''), 500);

v_fp := COALESCE(NULLIF(_fingerprint, ''), md5(_source || '|' || _message || '|' || COALESCE(_route, '')));

IF v_id IS NULL THEN
    INSERT INTO public.system_error_logs
      (source, severity, message, stack, route, user_id, user_agent, payload, fingerprint)
    VALUES
      (_source, _severity, _message, NULLIF(_stack,''), NULLIF(_route,''),
       auth.uid(), NULLIF(_user_agent,''), _payload, v_fp)
    RETURNING id INTO v_id;

END IF;

RETURN v_id;

END $$;

-- ------------------------------------------------------------
-- Migration: 20260609173140_f42754ce-df87-450d-8c8e-07113aafb478.sql
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION public._tmp_exec_sql(sql text) RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$ BEGIN EXECUTE sql;

END $$;

-- C-2 / H-2: admin_action_log audit-log integrity.
-- Direct INSERT by authenticated allowed any user to forge "allowed: true"
-- entries. Route all writes through a SECURITY DEFINER RPC.
CREATE OR REPLACE FUNCTION public.record_admin_action(
  _permission text,
  _action     text,
  _allowed    boolean,
  _metadata   jsonb DEFAULT NULL
) RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'record_admin_action requires an authenticated caller';

END IF;

END;

$$;

-- ------------------------------------------------------------
-- Migration: 20260611150036_222cfb2f-2515-4939-8198-9afdef928491.sql
-- ------------------------------------------------------------
-- part 50: redefine bootstrap with duplicate-object tolerance
-- (skipped: orphan EXCEPTION/END fragments of split bootstrap migration)

-- part 51: normalize ownership of public objects to postgres
-- ownership changes intentionally omitted for Supabase compatibility

-- part 52: admin_run_select_query
CREATE OR REPLACE FUNCTION public.admin_run_select_query(_sql text, _max_rows integer DEFAULT 200)
 RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public'
AS $function$
DECLARE
  trimmed text; lowered text; forbidden text; result jsonb; wrapped text;
BEGIN
  IF NOT public.has_role(auth.uid(), 'admin'::public.app_role) THEN
    RAISE EXCEPTION 'Forbidden: admin role required';
  END IF;
  IF _sql IS NULL OR length(btrim(_sql)) = 0 THEN RAISE EXCEPTION 'Empty query'; END IF;
  trimmed := btrim(_sql);
  WHILE right(trimmed, 1) = ';' LOOP trimmed := btrim(left(trimmed, length(trimmed)-1)); END LOOP;
  IF position(';' in trimmed) > 0 THEN RAISE EXCEPTION 'Only a single statement is allowed'; END IF;
  lowered := lower(trimmed);
  IF NOT (lowered LIKE 'select%' OR lowered LIKE 'with%') THEN RAISE EXCEPTION 'Only SELECT / WITH queries are allowed'; END IF;
  FOREACH forbidden IN ARRAY ARRAY['insert ','update ','delete ','drop ','alter ','create ','grant ','revoke ','truncate ','vacuum ','copy ','do ','call ','comment ','reindex ','listen ','notify ','prepare ','execute ','reset ','set ','lock ','refresh ','cluster ','security definer','pg_sleep','pg_read_server_files','pg_read_binary_file','pg_ls_dir','pg_stat_file','lo_import','lo_export','dblink','pg_catalog.','information_schema.','pg_authid','pg_shadow','pg_user','pg_largeobject','pg_roles'] LOOP
    IF position(forbidden in lowered) > 0 THEN RAISE EXCEPTION 'Forbidden token in query: %', trim(forbidden); END IF;
  END LOOP;
  _max_rows := GREATEST(1, LEAST(COALESCE(_max_rows, 200), 500));
  PERFORM set_config('statement_timeout', '5000', true);
  wrapped := format('SELECT COALESCE(jsonb_agg(t), ''[]''::jsonb) FROM (%s LIMIT %s) t', trimmed, _max_rows);
  EXECUTE wrapped INTO result;
  RETURN jsonb_build_object('rows', result, 'limit', _max_rows);
END; $function$;

CREATE OR REPLACE FUNCTION public.admin_log_system_error(
  _source TEXT, _severity TEXT, _message TEXT,
  _stack TEXT DEFAULT NULL, _route TEXT DEFAULT NULL, _user_agent TEXT DEFAULT NULL,
  _payload JSONB DEFAULT NULL, _fingerprint TEXT DEFAULT NULL
) RETURNS UUID LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_id UUID;

v_fp TEXT;

BEGIN
  IF _source IS NULL OR _source NOT IN ('frontend','backend','db','network','unknown') THEN _source := 'unknown';

END IF;

IF _severity IS NULL OR _severity NOT IN ('critical','high','medium','low') THEN _severity := 'medium';

END IF;

IF _message IS NULL OR length(btrim(_message)) = 0 THEN RAISE EXCEPTION 'message required';

END IF;

_message := left(_message, 2000);

_stack := left(COALESCE(_stack, ''), 8000);

_route := left(COALESCE(_route, ''), 500);

_user_agent := left(COALESCE(_user_agent, ''), 500);

v_fp := COALESCE(NULLIF(_fingerprint, ''), md5(_source || '|' || _message || '|' || COALESCE(_route, '')));

IF v_id IS NULL THEN
    INSERT INTO public.system_error_logs (source, severity, message, stack, route, user_id, user_agent, payload, fingerprint)
    VALUES (_source, _severity, _message, NULLIF(_stack,''), NULLIF(_route,''), auth.uid(), NULLIF(_user_agent,''), _payload, v_fp)
    RETURNING id INTO v_id;

END IF;

RETURN v_id;

END $$;

-- part 57: _tmp_exec_sql (service-role only)
CREATE OR REPLACE FUNCTION public._tmp_exec_sql(sql text) RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$ BEGIN EXECUTE sql;

END $$;

CREATE OR REPLACE FUNCTION public.blog_increment_view(_post_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE public.blog_posts SET view_count = view_count + 1 WHERE id = _post_id AND status = 'published';

END;

$$;

-- is_user_banned helper ---------------------------------------
CREATE OR REPLACE FUNCTION public.is_user_banned(_user_id uuid)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.user_bans b
    WHERE b.user_id = _user_id
      AND b.lifted_at IS NULL
      AND (b.ends_at IS NULL OR b.ends_at > now())
  );

$$;

CREATE OR REPLACE FUNCTION public.get_auth_access_controls()
RETURNS public.auth_access_controls
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  row_data public.auth_access_controls;

BEGIN
  SELECT * INTO row_data FROM public.auth_access_controls WHERE id = 1;

IF row_data IS NULL THEN
    row_data.id := 1;

row_data.login_enabled := true;

row_data.signup_enabled := true;

RETURN row_data;

END IF;

IF row_data.login_auto_enable_at IS NOT NULL
     AND row_data.login_auto_enable_at <= now()
     AND row_data.login_enabled = false THEN
    UPDATE public.auth_access_controls
      SET login_enabled = true,
          login_auto_enable_at = NULL,
          updated_at = now()
      WHERE id = 1
      RETURNING * INTO row_data;

END IF;

IF row_data.signup_auto_enable_at IS NOT NULL
     AND row_data.signup_auto_enable_at <= now()
     AND row_data.signup_enabled = false THEN
    UPDATE public.auth_access_controls
      SET signup_enabled = true,
          signup_auto_enable_at = NULL,
          updated_at = now()
      WHERE id = 1
      RETURNING * INTO row_data;

END IF;

RETURN row_data;

END;

$$;

CREATE OR REPLACE FUNCTION public.update_auth_access_controls(_payload jsonb)
RETURNS public.auth_access_controls
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  prev_row public.auth_access_controls;

new_row public.auth_access_controls;

caller uuid := auth.uid();

BEGIN
  IF caller IS NULL THEN
    RAISE EXCEPTION 'unauthorized';

END IF;

IF NOT public.has_role(caller, 'admin'::public.app_role) THEN
    RAISE EXCEPTION 'forbidden: admin role required';

END IF;

SELECT * INTO prev_row FROM public.auth_access_controls WHERE id = 1;

RETURN new_row;

END;

$$;


-- =================== 6. TRIGGERS ===================

DO $$
BEGIN
  IF to_regclass('public.homepage_sections') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_trigger
       WHERE tgname = 'trg_homepage_sections_updated_at' AND tgrelid = 'public.homepage_sections'::regclass
     ) THEN
    CREATE TRIGGER trg_homepage_sections_updated_at BEFORE UPDATE ON public.homepage_sections
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.site_settings') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_trigger
       WHERE tgname = 'trg_site_settings_updated_at' AND tgrelid = 'public.site_settings'::regclass
     ) THEN
    CREATE TRIGGER trg_site_settings_updated_at BEFORE UPDATE ON public.site_settings
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.media_assets') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_trigger
       WHERE tgname = 'trg_media_assets_updated_at' AND tgrelid = 'public.media_assets'::regclass
     ) THEN
    CREATE TRIGGER trg_media_assets_updated_at BEFORE UPDATE ON public.media_assets
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.profiles') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_trigger
       WHERE tgname = 'set_updated_at_profiles' AND tgrelid = 'public.profiles'::regclass
     ) THEN
    create trigger set_updated_at_profiles before update on public.profiles for each row execute function public.set_updated_at();
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.levels') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_trigger
       WHERE tgname = 'set_updated_at_levels' AND tgrelid = 'public.levels'::regclass
     ) THEN
    create trigger set_updated_at_levels before update on public.levels for each row execute function public.set_updated_at();
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.subjects') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_trigger
       WHERE tgname = 'set_updated_at_subjects' AND tgrelid = 'public.subjects'::regclass
     ) THEN
    create trigger set_updated_at_subjects before update on public.subjects for each row execute function public.set_updated_at();
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.chapters') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_trigger
       WHERE tgname = 'set_updated_at_chapters' AND tgrelid = 'public.chapters'::regclass
     ) THEN
    create trigger set_updated_at_chapters before update on public.chapters for each row execute function public.set_updated_at();
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.mcqs') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_trigger
       WHERE tgname = 'set_updated_at_mcqs' AND tgrelid = 'public.mcqs'::regclass
     ) THEN
    create trigger set_updated_at_mcqs before update on public.mcqs for each row execute function public.set_updated_at();
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.quizzes') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_trigger
       WHERE tgname = 'set_updated_at_quizzes' AND tgrelid = 'public.quizzes'::regclass
     ) THEN
    create trigger set_updated_at_quizzes before update on public.quizzes for each row execute function public.set_updated_at();
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.quiz_sessions') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_trigger
       WHERE tgname = 'set_updated_at_quiz_sessions' AND tgrelid = 'public.quiz_sessions'::regclass
     ) THEN
    create trigger set_updated_at_quiz_sessions before update on public.quiz_sessions for each row execute function public.set_updated_at();
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.flash_cards') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_trigger
       WHERE tgname = 'set_updated_at_flash_cards' AND tgrelid = 'public.flash_cards'::regclass
     ) THEN
    create trigger set_updated_at_flash_cards before update on public.flash_cards for each row execute function public.set_updated_at();
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.flash_card_visibility') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_trigger
       WHERE tgname = 'set_updated_at_flash_card_visibility' AND tgrelid = 'public.flash_card_visibility'::regclass
     ) THEN
    create trigger set_updated_at_flash_card_visibility before update on public.flash_card_visibility for each row execute function public.set_updated_at();
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.short_notes') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_trigger
       WHERE tgname = 'set_updated_at_short_notes' AND tgrelid = 'public.short_notes'::regclass
     ) THEN
    create trigger set_updated_at_short_notes before update on public.short_notes for each row execute function public.set_updated_at();
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.short_notes_visibility') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_trigger
       WHERE tgname = 'set_updated_at_short_notes_visibility' AND tgrelid = 'public.short_notes_visibility'::regclass
     ) THEN
    create trigger set_updated_at_short_notes_visibility before update on public.short_notes_visibility for each row execute function public.set_updated_at();
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.question_bank_resources') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_trigger
       WHERE tgname = 'set_updated_at_question_bank_resources' AND tgrelid = 'public.question_bank_resources'::regclass
     ) THEN
    create trigger set_updated_at_question_bank_resources before update on public.question_bank_resources for each row execute function public.set_updated_at();
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.question_bank_visibility') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_trigger
       WHERE tgname = 'set_updated_at_question_bank_visibility' AND tgrelid = 'public.question_bank_visibility'::regclass
     ) THEN
    create trigger set_updated_at_question_bank_visibility before update on public.question_bank_visibility for each row execute function public.set_updated_at();
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.video_classes') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_trigger
       WHERE tgname = 'set_updated_at_video_classes' AND tgrelid = 'public.video_classes'::regclass
     ) THEN
    create trigger set_updated_at_video_classes before update on public.video_classes for each row execute function public.set_updated_at();
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.video_class_visibility') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_trigger
       WHERE tgname = 'set_updated_at_video_class_visibility' AND tgrelid = 'public.video_class_visibility'::regclass
     ) THEN
    create trigger set_updated_at_video_class_visibility before update on public.video_class_visibility for each row execute function public.set_updated_at();
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.notifications') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_trigger
       WHERE tgname = 'set_updated_at_notifications' AND tgrelid = 'public.notifications'::regclass
     ) THEN
    create trigger set_updated_at_notifications before update on public.notifications for each row execute function public.set_updated_at();
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.study_sessions') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_trigger
       WHERE tgname = 'study_sessions_set_updated_at' AND tgrelid = 'public.study_sessions'::regclass
     ) THEN
    CREATE TRIGGER study_sessions_set_updated_at
  BEFORE UPDATE ON public.study_sessions
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.homepage_sections') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_trigger
       WHERE tgname = 'trg_homepage_sections_updated_at' AND tgrelid = 'public.homepage_sections'::regclass
     ) THEN
    CREATE TRIGGER trg_homepage_sections_updated_at BEFORE UPDATE ON public.homepage_sections
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.site_settings') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_trigger
       WHERE tgname = 'trg_site_settings_updated_at' AND tgrelid = 'public.site_settings'::regclass
     ) THEN
    CREATE TRIGGER trg_site_settings_updated_at BEFORE UPDATE ON public.site_settings
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.media_assets') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_trigger
       WHERE tgname = 'trg_media_assets_updated_at' AND tgrelid = 'public.media_assets'::regclass
     ) THEN
    CREATE TRIGGER trg_media_assets_updated_at BEFORE UPDATE ON public.media_assets
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.profiles') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_trigger
       WHERE tgname = 'set_updated_at_profiles' AND tgrelid = 'public.profiles'::regclass
     ) THEN
    create trigger set_updated_at_profiles before update on public.profiles for each row execute function public.set_updated_at();
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.levels') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_trigger
       WHERE tgname = 'set_updated_at_levels' AND tgrelid = 'public.levels'::regclass
     ) THEN
    create trigger set_updated_at_levels before update on public.levels for each row execute function public.set_updated_at();
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.subjects') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_trigger
       WHERE tgname = 'set_updated_at_subjects' AND tgrelid = 'public.subjects'::regclass
     ) THEN
    create trigger set_updated_at_subjects before update on public.subjects for each row execute function public.set_updated_at();
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.chapters') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_trigger
       WHERE tgname = 'set_updated_at_chapters' AND tgrelid = 'public.chapters'::regclass
     ) THEN
    create trigger set_updated_at_chapters before update on public.chapters for each row execute function public.set_updated_at();
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.mcqs') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_trigger
       WHERE tgname = 'set_updated_at_mcqs' AND tgrelid = 'public.mcqs'::regclass
     ) THEN
    create trigger set_updated_at_mcqs before update on public.mcqs for each row execute function public.set_updated_at();
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.quizzes') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_trigger
       WHERE tgname = 'set_updated_at_quizzes' AND tgrelid = 'public.quizzes'::regclass
     ) THEN
    create trigger set_updated_at_quizzes before update on public.quizzes for each row execute function public.set_updated_at();
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.quiz_sessions') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_trigger
       WHERE tgname = 'set_updated_at_quiz_sessions' AND tgrelid = 'public.quiz_sessions'::regclass
     ) THEN
    create trigger set_updated_at_quiz_sessions before update on public.quiz_sessions for each row execute function public.set_updated_at();
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.flash_cards') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_trigger
       WHERE tgname = 'set_updated_at_flash_cards' AND tgrelid = 'public.flash_cards'::regclass
     ) THEN
    create trigger set_updated_at_flash_cards before update on public.flash_cards for each row execute function public.set_updated_at();
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.flash_card_visibility') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_trigger
       WHERE tgname = 'set_updated_at_flash_card_visibility' AND tgrelid = 'public.flash_card_visibility'::regclass
     ) THEN
    create trigger set_updated_at_flash_card_visibility before update on public.flash_card_visibility for each row execute function public.set_updated_at();
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.short_notes') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_trigger
       WHERE tgname = 'set_updated_at_short_notes' AND tgrelid = 'public.short_notes'::regclass
     ) THEN
    create trigger set_updated_at_short_notes before update on public.short_notes for each row execute function public.set_updated_at();
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.short_notes_visibility') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_trigger
       WHERE tgname = 'set_updated_at_short_notes_visibility' AND tgrelid = 'public.short_notes_visibility'::regclass
     ) THEN
    create trigger set_updated_at_short_notes_visibility before update on public.short_notes_visibility for each row execute function public.set_updated_at();
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.question_bank_resources') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_trigger
       WHERE tgname = 'set_updated_at_question_bank_resources' AND tgrelid = 'public.question_bank_resources'::regclass
     ) THEN
    create trigger set_updated_at_question_bank_resources before update on public.question_bank_resources for each row execute function public.set_updated_at();
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.question_bank_visibility') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_trigger
       WHERE tgname = 'set_updated_at_question_bank_visibility' AND tgrelid = 'public.question_bank_visibility'::regclass
     ) THEN
    create trigger set_updated_at_question_bank_visibility before update on public.question_bank_visibility for each row execute function public.set_updated_at();
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.video_classes') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_trigger
       WHERE tgname = 'set_updated_at_video_classes' AND tgrelid = 'public.video_classes'::regclass
     ) THEN
    create trigger set_updated_at_video_classes before update on public.video_classes for each row execute function public.set_updated_at();
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.video_class_visibility') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_trigger
       WHERE tgname = 'set_updated_at_video_class_visibility' AND tgrelid = 'public.video_class_visibility'::regclass
     ) THEN
    create trigger set_updated_at_video_class_visibility before update on public.video_class_visibility for each row execute function public.set_updated_at();
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.notifications') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_trigger
       WHERE tgname = 'set_updated_at_notifications' AND tgrelid = 'public.notifications'::regclass
     ) THEN
    create trigger set_updated_at_notifications before update on public.notifications for each row execute function public.set_updated_at();
  END IF;
END $$;

-- DROP TRIGGER IF EXISTS mcqs_validate_question_type_trg ON public.mcqs;

DO $$
BEGIN
  IF to_regclass('public.mcqs') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_trigger
       WHERE tgname = 'mcqs_validate_question_type_trg' AND tgrelid = 'public.mcqs'::regclass
     ) THEN
    CREATE TRIGGER mcqs_validate_question_type_trg
  BEFORE INSERT OR UPDATE ON public.mcqs
  FOR EACH ROW EXECUTE FUNCTION public.mcqs_validate_question_type();
  END IF;
END $$;

-- DROP TRIGGER IF EXISTS trg_homepage_sections_updated_at ON public.homepage_sections;

DO $$
BEGIN
  IF to_regclass('public.homepage_sections') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_trigger
       WHERE tgname = 'trg_homepage_sections_updated_at' AND tgrelid = 'public.homepage_sections'::regclass
     ) THEN
    CREATE TRIGGER trg_homepage_sections_updated_at BEFORE UPDATE ON public.homepage_sections FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
  END IF;
END $$;

-- DROP TRIGGER IF EXISTS trg_site_settings_updated_at ON public.site_settings;

DO $$
BEGIN
  IF to_regclass('public.site_settings') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_trigger
       WHERE tgname = 'trg_site_settings_updated_at' AND tgrelid = 'public.site_settings'::regclass
     ) THEN
    CREATE TRIGGER trg_site_settings_updated_at BEFORE UPDATE ON public.site_settings FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
  END IF;
END $$;

-- DROP TRIGGER IF EXISTS trg_media_assets_updated_at ON public.media_assets;

DO $$
BEGIN
  IF to_regclass('public.media_assets') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_trigger
       WHERE tgname = 'trg_media_assets_updated_at' AND tgrelid = 'public.media_assets'::regclass
     ) THEN
    CREATE TRIGGER trg_media_assets_updated_at BEFORE UPDATE ON public.media_assets FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
  END IF;
END $$;

-- drop trigger if exists set_updated_at_profiles on public.profiles;

DO $$
BEGIN
  IF to_regclass('public.profiles') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_trigger
       WHERE tgname = 'set_updated_at_profiles' AND tgrelid = 'public.profiles'::regclass
     ) THEN
    create trigger set_updated_at_profiles before update on public.profiles for each row execute function public.set_updated_at();
  END IF;
END $$;

-- drop trigger if exists set_updated_at_levels on public.levels;

DO $$
BEGIN
  IF to_regclass('public.levels') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_trigger
       WHERE tgname = 'set_updated_at_levels' AND tgrelid = 'public.levels'::regclass
     ) THEN
    create trigger set_updated_at_levels before update on public.levels for each row execute function public.set_updated_at();
  END IF;
END $$;

-- drop trigger if exists set_updated_at_subjects on public.subjects;

DO $$
BEGIN
  IF to_regclass('public.subjects') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_trigger
       WHERE tgname = 'set_updated_at_subjects' AND tgrelid = 'public.subjects'::regclass
     ) THEN
    create trigger set_updated_at_subjects before update on public.subjects for each row execute function public.set_updated_at();
  END IF;
END $$;

-- drop trigger if exists set_updated_at_chapters on public.chapters;

DO $$
BEGIN
  IF to_regclass('public.chapters') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_trigger
       WHERE tgname = 'set_updated_at_chapters' AND tgrelid = 'public.chapters'::regclass
     ) THEN
    create trigger set_updated_at_chapters before update on public.chapters for each row execute function public.set_updated_at();
  END IF;
END $$;

-- drop trigger if exists set_updated_at_mcqs on public.mcqs;

DO $$
BEGIN
  IF to_regclass('public.mcqs') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_trigger
       WHERE tgname = 'set_updated_at_mcqs' AND tgrelid = 'public.mcqs'::regclass
     ) THEN
    create trigger set_updated_at_mcqs before update on public.mcqs for each row execute function public.set_updated_at();
  END IF;
END $$;

-- drop trigger if exists set_updated_at_quizzes on public.quizzes;

DO $$
BEGIN
  IF to_regclass('public.quizzes') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_trigger
       WHERE tgname = 'set_updated_at_quizzes' AND tgrelid = 'public.quizzes'::regclass
     ) THEN
    create trigger set_updated_at_quizzes before update on public.quizzes for each row execute function public.set_updated_at();
  END IF;
END $$;

-- drop trigger if exists set_updated_at_quiz_sessions on public.quiz_sessions;

DO $$
BEGIN
  IF to_regclass('public.quiz_sessions') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_trigger
       WHERE tgname = 'set_updated_at_quiz_sessions' AND tgrelid = 'public.quiz_sessions'::regclass
     ) THEN
    create trigger set_updated_at_quiz_sessions before update on public.quiz_sessions for each row execute function public.set_updated_at();
  END IF;
END $$;

-- drop trigger if exists set_updated_at_flash_cards on public.flash_cards;

DO $$
BEGIN
  IF to_regclass('public.flash_cards') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_trigger
       WHERE tgname = 'set_updated_at_flash_cards' AND tgrelid = 'public.flash_cards'::regclass
     ) THEN
    create trigger set_updated_at_flash_cards before update on public.flash_cards for each row execute function public.set_updated_at();
  END IF;
END $$;

-- drop trigger if exists set_updated_at_flash_card_visibility on public.flash_card_visibility;

DO $$
BEGIN
  IF to_regclass('public.flash_card_visibility') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_trigger
       WHERE tgname = 'set_updated_at_flash_card_visibility' AND tgrelid = 'public.flash_card_visibility'::regclass
     ) THEN
    create trigger set_updated_at_flash_card_visibility before update on public.flash_card_visibility for each row execute function public.set_updated_at();
  END IF;
END $$;

-- drop trigger if exists set_updated_at_short_notes on public.short_notes;

DO $$
BEGIN
  IF to_regclass('public.short_notes') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_trigger
       WHERE tgname = 'set_updated_at_short_notes' AND tgrelid = 'public.short_notes'::regclass
     ) THEN
    create trigger set_updated_at_short_notes before update on public.short_notes for each row execute function public.set_updated_at();
  END IF;
END $$;

-- drop trigger if exists set_updated_at_short_notes_visibility on public.short_notes_visibility;

DO $$
BEGIN
  IF to_regclass('public.short_notes_visibility') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_trigger
       WHERE tgname = 'set_updated_at_short_notes_visibility' AND tgrelid = 'public.short_notes_visibility'::regclass
     ) THEN
    create trigger set_updated_at_short_notes_visibility before update on public.short_notes_visibility for each row execute function public.set_updated_at();
  END IF;
END $$;

-- drop trigger if exists set_updated_at_question_bank_resources on public.question_bank_resources;

DO $$
BEGIN
  IF to_regclass('public.question_bank_resources') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_trigger
       WHERE tgname = 'set_updated_at_question_bank_resources' AND tgrelid = 'public.question_bank_resources'::regclass
     ) THEN
    create trigger set_updated_at_question_bank_resources before update on public.question_bank_resources for each row execute function public.set_updated_at();
  END IF;
END $$;

-- drop trigger if exists set_updated_at_question_bank_visibility on public.question_bank_visibility;

DO $$
BEGIN
  IF to_regclass('public.question_bank_visibility') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_trigger
       WHERE tgname = 'set_updated_at_question_bank_visibility' AND tgrelid = 'public.question_bank_visibility'::regclass
     ) THEN
    create trigger set_updated_at_question_bank_visibility before update on public.question_bank_visibility for each row execute function public.set_updated_at();
  END IF;
END $$;

-- drop trigger if exists set_updated_at_video_classes on public.video_classes;

DO $$
BEGIN
  IF to_regclass('public.video_classes') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_trigger
       WHERE tgname = 'set_updated_at_video_classes' AND tgrelid = 'public.video_classes'::regclass
     ) THEN
    create trigger set_updated_at_video_classes before update on public.video_classes for each row execute function public.set_updated_at();
  END IF;
END $$;

-- drop trigger if exists set_updated_at_video_class_visibility on public.video_class_visibility;

DO $$
BEGIN
  IF to_regclass('public.video_class_visibility') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_trigger
       WHERE tgname = 'set_updated_at_video_class_visibility' AND tgrelid = 'public.video_class_visibility'::regclass
     ) THEN
    create trigger set_updated_at_video_class_visibility before update on public.video_class_visibility for each row execute function public.set_updated_at();
  END IF;
END $$;

-- drop trigger if exists set_updated_at_notifications on public.notifications;

DO $$
BEGIN
  IF to_regclass('public.notifications') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_trigger
       WHERE tgname = 'set_updated_at_notifications' AND tgrelid = 'public.notifications'::regclass
     ) THEN
    create trigger set_updated_at_notifications before update on public.notifications for each row execute function public.set_updated_at();
  END IF;
END $$;

DO $$ BEGIN
  CREATE TRIGGER study_sessions_set_updated_at
    BEFORE UPDATE ON public.study_sessions
    FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$
BEGIN
  IF to_regclass('public.site_pages') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_trigger
       WHERE tgname = 'site_pages_updated_at' AND tgrelid = 'public.site_pages'::regclass
     ) THEN
    CREATE TRIGGER site_pages_updated_at
  BEFORE UPDATE ON public.site_pages
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.site_page_sections') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_trigger
       WHERE tgname = 'site_page_sections_updated_at' AND tgrelid = 'public.site_page_sections'::regclass
     ) THEN
    CREATE TRIGGER site_page_sections_updated_at
  BEFORE UPDATE ON public.site_page_sections
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.homepage_sections') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_trigger
       WHERE tgname = 'trg_homepage_sections_updated_at' AND tgrelid = 'public.homepage_sections'::regclass
     ) THEN
    CREATE TRIGGER trg_homepage_sections_updated_at BEFORE UPDATE ON public.homepage_sections
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.site_settings') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_trigger
       WHERE tgname = 'trg_site_settings_updated_at' AND tgrelid = 'public.site_settings'::regclass
     ) THEN
    CREATE TRIGGER trg_site_settings_updated_at BEFORE UPDATE ON public.site_settings
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.media_assets') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_trigger
       WHERE tgname = 'trg_media_assets_updated_at' AND tgrelid = 'public.media_assets'::regclass
     ) THEN
    CREATE TRIGGER trg_media_assets_updated_at BEFORE UPDATE ON public.media_assets
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.profiles') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_trigger
       WHERE tgname = 'set_updated_at_profiles' AND tgrelid = 'public.profiles'::regclass
     ) THEN
    create trigger set_updated_at_profiles before update on public.profiles for each row execute function public.set_updated_at();
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.levels') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_trigger
       WHERE tgname = 'set_updated_at_levels' AND tgrelid = 'public.levels'::regclass
     ) THEN
    create trigger set_updated_at_levels before update on public.levels for each row execute function public.set_updated_at();
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.subjects') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_trigger
       WHERE tgname = 'set_updated_at_subjects' AND tgrelid = 'public.subjects'::regclass
     ) THEN
    create trigger set_updated_at_subjects before update on public.subjects for each row execute function public.set_updated_at();
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.chapters') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_trigger
       WHERE tgname = 'set_updated_at_chapters' AND tgrelid = 'public.chapters'::regclass
     ) THEN
    create trigger set_updated_at_chapters before update on public.chapters for each row execute function public.set_updated_at();
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.mcqs') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_trigger
       WHERE tgname = 'set_updated_at_mcqs' AND tgrelid = 'public.mcqs'::regclass
     ) THEN
    create trigger set_updated_at_mcqs before update on public.mcqs for each row execute function public.set_updated_at();
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.quizzes') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_trigger
       WHERE tgname = 'set_updated_at_quizzes' AND tgrelid = 'public.quizzes'::regclass
     ) THEN
    create trigger set_updated_at_quizzes before update on public.quizzes for each row execute function public.set_updated_at();
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.quiz_sessions') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_trigger
       WHERE tgname = 'set_updated_at_quiz_sessions' AND tgrelid = 'public.quiz_sessions'::regclass
     ) THEN
    create trigger set_updated_at_quiz_sessions before update on public.quiz_sessions for each row execute function public.set_updated_at();
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.flash_cards') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_trigger
       WHERE tgname = 'set_updated_at_flash_cards' AND tgrelid = 'public.flash_cards'::regclass
     ) THEN
    create trigger set_updated_at_flash_cards before update on public.flash_cards for each row execute function public.set_updated_at();
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.flash_card_visibility') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_trigger
       WHERE tgname = 'set_updated_at_flash_card_visibility' AND tgrelid = 'public.flash_card_visibility'::regclass
     ) THEN
    create trigger set_updated_at_flash_card_visibility before update on public.flash_card_visibility for each row execute function public.set_updated_at();
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.short_notes') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_trigger
       WHERE tgname = 'set_updated_at_short_notes' AND tgrelid = 'public.short_notes'::regclass
     ) THEN
    create trigger set_updated_at_short_notes before update on public.short_notes for each row execute function public.set_updated_at();
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.short_notes_visibility') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_trigger
       WHERE tgname = 'set_updated_at_short_notes_visibility' AND tgrelid = 'public.short_notes_visibility'::regclass
     ) THEN
    create trigger set_updated_at_short_notes_visibility before update on public.short_notes_visibility for each row execute function public.set_updated_at();
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.question_bank_resources') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_trigger
       WHERE tgname = 'set_updated_at_question_bank_resources' AND tgrelid = 'public.question_bank_resources'::regclass
     ) THEN
    create trigger set_updated_at_question_bank_resources before update on public.question_bank_resources for each row execute function public.set_updated_at();
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.question_bank_visibility') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_trigger
       WHERE tgname = 'set_updated_at_question_bank_visibility' AND tgrelid = 'public.question_bank_visibility'::regclass
     ) THEN
    create trigger set_updated_at_question_bank_visibility before update on public.question_bank_visibility for each row execute function public.set_updated_at();
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.video_classes') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_trigger
       WHERE tgname = 'set_updated_at_video_classes' AND tgrelid = 'public.video_classes'::regclass
     ) THEN
    create trigger set_updated_at_video_classes before update on public.video_classes for each row execute function public.set_updated_at();
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.video_class_visibility') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_trigger
       WHERE tgname = 'set_updated_at_video_class_visibility' AND tgrelid = 'public.video_class_visibility'::regclass
     ) THEN
    create trigger set_updated_at_video_class_visibility before update on public.video_class_visibility for each row execute function public.set_updated_at();
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.notifications') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_trigger
       WHERE tgname = 'set_updated_at_notifications' AND tgrelid = 'public.notifications'::regclass
     ) THEN
    create trigger set_updated_at_notifications before update on public.notifications for each row execute function public.set_updated_at();
  END IF;
END $$;

DO $$ BEGIN
  CREATE TRIGGER study_sessions_set_updated_at
    BEFORE UPDATE ON public.study_sessions
    FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TRIGGER site_pages_updated_at
    BEFORE UPDATE ON public.site_pages
    FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TRIGGER site_page_sections_updated_at
    BEFORE UPDATE ON public.site_page_sections
    FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$
BEGIN
  IF to_regclass('public.profiles') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_trigger
       WHERE tgname = 'trg_profiles_updated' AND tgrelid = 'public.profiles'::regclass
     ) THEN
    CREATE TRIGGER trg_profiles_updated BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
  END IF;
END $$;

-- DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

DO $$
BEGIN
  IF to_regclass('auth.users') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_trigger
       WHERE tgname = 'on_auth_user_created' AND tgrelid = 'auth.users'::regclass
     ) THEN
    CREATE TRIGGER on_auth_user_created AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.levels') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_trigger
       WHERE tgname = 'trg_levels_updated' AND tgrelid = 'public.levels'::regclass
     ) THEN
    CREATE TRIGGER trg_levels_updated BEFORE UPDATE ON public.levels
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.subjects') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_trigger
       WHERE tgname = 'trg_subjects_updated' AND tgrelid = 'public.subjects'::regclass
     ) THEN
    CREATE TRIGGER trg_subjects_updated BEFORE UPDATE ON public.subjects
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.chapters') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_trigger
       WHERE tgname = 'trg_chapters_updated' AND tgrelid = 'public.chapters'::regclass
     ) THEN
    CREATE TRIGGER trg_chapters_updated BEFORE UPDATE ON public.chapters
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.mcqs') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_trigger
       WHERE tgname = 'trg_mcqs_updated' AND tgrelid = 'public.mcqs'::regclass
     ) THEN
    CREATE TRIGGER trg_mcqs_updated BEFORE UPDATE ON public.mcqs
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.quizzes') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_trigger
       WHERE tgname = 'trg_quizzes_updated' AND tgrelid = 'public.quizzes'::regclass
     ) THEN
    CREATE TRIGGER trg_quizzes_updated BEFORE UPDATE ON public.quizzes
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.flash_cards') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_trigger
       WHERE tgname = 'trg_fc_updated' AND tgrelid = 'public.flash_cards'::regclass
     ) THEN
    CREATE TRIGGER trg_fc_updated BEFORE UPDATE ON public.flash_cards
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.short_notes') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_trigger
       WHERE tgname = 'trg_sn_updated' AND tgrelid = 'public.short_notes'::regclass
     ) THEN
    CREATE TRIGGER trg_sn_updated BEFORE UPDATE ON public.short_notes
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.question_bank_resources') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_trigger
       WHERE tgname = 'trg_qb_updated' AND tgrelid = 'public.question_bank_resources'::regclass
     ) THEN
    CREATE TRIGGER trg_qb_updated BEFORE UPDATE ON public.question_bank_resources
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.video_classes') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_trigger
       WHERE tgname = 'trg_vc_updated' AND tgrelid = 'public.video_classes'::regclass
     ) THEN
    CREATE TRIGGER trg_vc_updated BEFORE UPDATE ON public.video_classes
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.notifications') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_trigger
       WHERE tgname = 'trg_notif_updated' AND tgrelid = 'public.notifications'::regclass
     ) THEN
    CREATE TRIGGER trg_notif_updated BEFORE UPDATE ON public.notifications
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.homepage_sections') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_trigger
       WHERE tgname = 'trg_homepage_sections_updated_at' AND tgrelid = 'public.homepage_sections'::regclass
     ) THEN
    CREATE TRIGGER trg_homepage_sections_updated_at BEFORE UPDATE ON public.homepage_sections
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.site_settings') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_trigger
       WHERE tgname = 'trg_site_settings_updated_at' AND tgrelid = 'public.site_settings'::regclass
     ) THEN
    CREATE TRIGGER trg_site_settings_updated_at BEFORE UPDATE ON public.site_settings
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.media_assets') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_trigger
       WHERE tgname = 'trg_media_assets_updated_at' AND tgrelid = 'public.media_assets'::regclass
     ) THEN
    CREATE TRIGGER trg_media_assets_updated_at BEFORE UPDATE ON public.media_assets
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.profiles') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_trigger
       WHERE tgname = 'set_updated_at_profiles' AND tgrelid = 'public.profiles'::regclass
     ) THEN
    create trigger set_updated_at_profiles before update on public.profiles for each row execute function public.set_updated_at();
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.levels') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_trigger
       WHERE tgname = 'set_updated_at_levels' AND tgrelid = 'public.levels'::regclass
     ) THEN
    create trigger set_updated_at_levels before update on public.levels for each row execute function public.set_updated_at();
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.subjects') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_trigger
       WHERE tgname = 'set_updated_at_subjects' AND tgrelid = 'public.subjects'::regclass
     ) THEN
    create trigger set_updated_at_subjects before update on public.subjects for each row execute function public.set_updated_at();
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.chapters') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_trigger
       WHERE tgname = 'set_updated_at_chapters' AND tgrelid = 'public.chapters'::regclass
     ) THEN
    create trigger set_updated_at_chapters before update on public.chapters for each row execute function public.set_updated_at();
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.mcqs') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_trigger
       WHERE tgname = 'set_updated_at_mcqs' AND tgrelid = 'public.mcqs'::regclass
     ) THEN
    create trigger set_updated_at_mcqs before update on public.mcqs for each row execute function public.set_updated_at();
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.quizzes') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_trigger
       WHERE tgname = 'set_updated_at_quizzes' AND tgrelid = 'public.quizzes'::regclass
     ) THEN
    create trigger set_updated_at_quizzes before update on public.quizzes for each row execute function public.set_updated_at();
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.quiz_sessions') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_trigger
       WHERE tgname = 'set_updated_at_quiz_sessions' AND tgrelid = 'public.quiz_sessions'::regclass
     ) THEN
    create trigger set_updated_at_quiz_sessions before update on public.quiz_sessions for each row execute function public.set_updated_at();
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.flash_cards') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_trigger
       WHERE tgname = 'set_updated_at_flash_cards' AND tgrelid = 'public.flash_cards'::regclass
     ) THEN
    create trigger set_updated_at_flash_cards before update on public.flash_cards for each row execute function public.set_updated_at();
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.flash_card_visibility') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_trigger
       WHERE tgname = 'set_updated_at_flash_card_visibility' AND tgrelid = 'public.flash_card_visibility'::regclass
     ) THEN
    create trigger set_updated_at_flash_card_visibility before update on public.flash_card_visibility for each row execute function public.set_updated_at();
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.short_notes') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_trigger
       WHERE tgname = 'set_updated_at_short_notes' AND tgrelid = 'public.short_notes'::regclass
     ) THEN
    create trigger set_updated_at_short_notes before update on public.short_notes for each row execute function public.set_updated_at();
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.short_notes_visibility') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_trigger
       WHERE tgname = 'set_updated_at_short_notes_visibility' AND tgrelid = 'public.short_notes_visibility'::regclass
     ) THEN
    create trigger set_updated_at_short_notes_visibility before update on public.short_notes_visibility for each row execute function public.set_updated_at();
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.question_bank_resources') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_trigger
       WHERE tgname = 'set_updated_at_question_bank_resources' AND tgrelid = 'public.question_bank_resources'::regclass
     ) THEN
    create trigger set_updated_at_question_bank_resources before update on public.question_bank_resources for each row execute function public.set_updated_at();
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.question_bank_visibility') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_trigger
       WHERE tgname = 'set_updated_at_question_bank_visibility' AND tgrelid = 'public.question_bank_visibility'::regclass
     ) THEN
    create trigger set_updated_at_question_bank_visibility before update on public.question_bank_visibility for each row execute function public.set_updated_at();
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.video_classes') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_trigger
       WHERE tgname = 'set_updated_at_video_classes' AND tgrelid = 'public.video_classes'::regclass
     ) THEN
    create trigger set_updated_at_video_classes before update on public.video_classes for each row execute function public.set_updated_at();
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.video_class_visibility') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_trigger
       WHERE tgname = 'set_updated_at_video_class_visibility' AND tgrelid = 'public.video_class_visibility'::regclass
     ) THEN
    create trigger set_updated_at_video_class_visibility before update on public.video_class_visibility for each row execute function public.set_updated_at();
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.notifications') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_trigger
       WHERE tgname = 'set_updated_at_notifications' AND tgrelid = 'public.notifications'::regclass
     ) THEN
    create trigger set_updated_at_notifications before update on public.notifications for each row execute function public.set_updated_at();
  END IF;
END $$;

DO $$ BEGIN
  CREATE TRIGGER study_sessions_set_updated_at
    BEFORE UPDATE ON public.study_sessions
    FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- DROP TRIGGER IF EXISTS mcqs_validate_question_type_trg ON public.mcqs;

DO $$
BEGIN
  IF to_regclass('public.mcqs') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_trigger
       WHERE tgname = 'mcqs_validate_question_type_trg' AND tgrelid = 'public.mcqs'::regclass
     ) THEN
    CREATE TRIGGER mcqs_validate_question_type_trg
  BEFORE INSERT OR UPDATE ON public.mcqs
  FOR EACH ROW EXECUTE FUNCTION public.mcqs_validate_question_type();
  END IF;
END $$;

DO $$ BEGIN
  CREATE TRIGGER site_pages_updated_at
    BEFORE UPDATE ON public.site_pages
    FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TRIGGER site_page_sections_updated_at
    BEFORE UPDATE ON public.site_page_sections
    FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- DROP TRIGGER IF EXISTS trg_role_permissions_updated_at ON public.role_permissions;

DO $$
BEGIN
  IF to_regclass('public.role_permissions') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_trigger
       WHERE tgname = 'trg_role_permissions_updated_at' AND tgrelid = 'public.role_permissions'::regclass
     ) THEN
    CREATE TRIGGER trg_role_permissions_updated_at
  BEFORE UPDATE ON public.role_permissions
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
  END IF;
END $$;

-- DROP TRIGGER IF EXISTS trg_role_permissions_guard ON public.role_permissions;

DO $$
BEGIN
  IF to_regclass('public.role_permissions') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_trigger
       WHERE tgname = 'trg_role_permissions_guard' AND tgrelid = 'public.role_permissions'::regclass
     ) THEN
    CREATE TRIGGER trg_role_permissions_guard
  BEFORE INSERT OR UPDATE OR DELETE ON public.role_permissions
  FOR EACH ROW EXECUTE FUNCTION public.role_permissions_guard();
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.editor_pages') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_trigger
       WHERE tgname = 'editor_pages_touch' AND tgrelid = 'public.editor_pages'::regclass
     ) THEN
    CREATE TRIGGER editor_pages_touch BEFORE UPDATE ON public.editor_pages FOR EACH ROW EXECUTE FUNCTION public.editor_set_updated_at();
  END IF;
END $$;

DROP TRIGGER IF EXISTS trg_blog_categories_updated ON public.blog_categories;

CREATE TRIGGER trg_blog_categories_updated BEFORE UPDATE ON public.blog_categories
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS trg_blog_posts_updated ON public.blog_posts;

CREATE TRIGGER trg_blog_posts_updated BEFORE UPDATE ON public.blog_posts
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


-- =================== 8. INDEXES ====================

CREATE INDEX IF NOT EXISTS idx_content_versions_target ON public.content_versions(target_kind, target_key, created_at DESC);

create index if not exists mcqs_chapter_id_idx on public.mcqs (chapter_id);

create index if not exists mcqs_status_idx on public.mcqs (status);

create index if not exists quiz_questions_quiz_id_idx on public.quiz_questions (quiz_id);

create index if not exists exam_attempts_user_id_idx on public.exam_attempts (user_id);

create index if not exists exam_attempts_created_at_idx on public.exam_attempts (created_at);

create index if not exists attempt_answers_attempt_id_idx on public.attempt_answers (attempt_id);

CREATE INDEX IF NOT EXISTS profiles_last_login_at_idx ON public.profiles(last_login_at DESC);

CREATE INDEX IF NOT EXISTS profiles_deleted_at_idx ON public.profiles(deleted_at);

CREATE INDEX IF NOT EXISTS user_login_events_user_id_idx ON public.user_login_events(user_id);

CREATE INDEX IF NOT EXISTS user_login_events_login_at_idx ON public.user_login_events(login_at DESC);

CREATE INDEX IF NOT EXISTS activity_events_created_at_idx ON public.activity_events (created_at DESC);

CREATE INDEX IF NOT EXISTS activity_events_user_created_idx ON public.activity_events (user_id, created_at DESC);

CREATE INDEX IF NOT EXISTS activity_events_type_created_idx ON public.activity_events (event_type, created_at DESC);

CREATE INDEX IF NOT EXISTS activity_events_path_created_idx ON public.activity_events (page_path, created_at DESC);

CREATE INDEX IF NOT EXISTS activity_events_element_created_idx ON public.activity_events (element_id, created_at DESC);

CREATE INDEX IF NOT EXISTS activity_events_module_created_idx ON public.activity_events (module, created_at DESC);

CREATE INDEX IF NOT EXISTS study_sessions_user_started_idx ON public.study_sessions(user_id, started_at DESC);

CREATE INDEX IF NOT EXISTS study_sessions_user_open_idx ON public.study_sessions(user_id) WHERE ended_at IS NULL;

CREATE INDEX IF NOT EXISTS quiz_sessions_status_created_idx ON public.quiz_sessions (status, created_at DESC);

CREATE INDEX IF NOT EXISTS quiz_sessions_user_status_idx ON public.quiz_sessions (user_id, status);

CREATE INDEX IF NOT EXISTS idx_content_versions_target ON public.content_versions(target_kind, target_key, created_at DESC);

create index if not exists mcqs_chapter_id_idx on public.mcqs (chapter_id);

create index if not exists mcqs_status_idx on public.mcqs (status);

create index if not exists quiz_questions_quiz_id_idx on public.quiz_questions (quiz_id);

create index if not exists exam_attempts_user_id_idx on public.exam_attempts (user_id);

create index if not exists exam_attempts_created_at_idx on public.exam_attempts (created_at);

create index if not exists attempt_answers_attempt_id_idx on public.attempt_answers (attempt_id);

CREATE INDEX IF NOT EXISTS profiles_last_login_at_idx ON public.profiles(last_login_at DESC);

CREATE INDEX IF NOT EXISTS profiles_deleted_at_idx ON public.profiles(deleted_at);

CREATE INDEX IF NOT EXISTS user_login_events_user_id_idx ON public.user_login_events(user_id);

CREATE INDEX IF NOT EXISTS user_login_events_login_at_idx ON public.user_login_events(login_at DESC);

CREATE INDEX IF NOT EXISTS activity_events_created_at_idx ON public.activity_events (created_at DESC);

CREATE INDEX IF NOT EXISTS activity_events_user_created_idx ON public.activity_events (user_id, created_at DESC);

CREATE INDEX IF NOT EXISTS activity_events_type_created_idx ON public.activity_events (event_type, created_at DESC);

CREATE INDEX IF NOT EXISTS activity_events_path_created_idx ON public.activity_events (page_path, created_at DESC);

CREATE INDEX IF NOT EXISTS activity_events_element_created_idx ON public.activity_events (element_id, created_at DESC);

CREATE INDEX IF NOT EXISTS activity_events_module_created_idx ON public.activity_events (module, created_at DESC);

CREATE INDEX IF NOT EXISTS study_sessions_user_id_idx ON public.study_sessions(user_id);

CREATE INDEX IF NOT EXISTS study_sessions_started_at_idx ON public.study_sessions(started_at DESC);

CREATE INDEX IF NOT EXISTS study_sessions_user_module_open_idx ON public.study_sessions(user_id, module, last_heartbeat_at DESC);

CREATE INDEX IF NOT EXISTS mcqs_question_type_idx ON public.mcqs (question_type);

CREATE INDEX IF NOT EXISTS idx_content_versions_target ON public.content_versions(target_kind, target_key, created_at DESC);

create index if not exists mcqs_chapter_id_idx on public.mcqs (chapter_id);

create index if not exists mcqs_status_idx on public.mcqs (status);

create index if not exists quiz_questions_quiz_id_idx on public.quiz_questions (quiz_id);

create index if not exists exam_attempts_user_id_idx on public.exam_attempts (user_id);

create index if not exists exam_attempts_created_at_idx on public.exam_attempts (created_at);

create index if not exists attempt_answers_attempt_id_idx on public.attempt_answers (attempt_id);

CREATE INDEX IF NOT EXISTS profiles_last_login_at_idx ON public.profiles(last_login_at DESC);

CREATE INDEX IF NOT EXISTS profiles_deleted_at_idx ON public.profiles(deleted_at);

CREATE INDEX IF NOT EXISTS user_login_events_user_id_idx ON public.user_login_events(user_id);

CREATE INDEX IF NOT EXISTS user_login_events_login_at_idx ON public.user_login_events(login_at DESC);

CREATE INDEX IF NOT EXISTS activity_events_created_at_idx ON public.activity_events (created_at DESC);

CREATE INDEX IF NOT EXISTS activity_events_user_created_idx ON public.activity_events (user_id, created_at DESC);

CREATE INDEX IF NOT EXISTS activity_events_type_created_idx ON public.activity_events (event_type, created_at DESC);

CREATE INDEX IF NOT EXISTS activity_events_path_created_idx ON public.activity_events (page_path, created_at DESC);

CREATE INDEX IF NOT EXISTS activity_events_element_created_idx ON public.activity_events (element_id, created_at DESC);

CREATE INDEX IF NOT EXISTS activity_events_module_created_idx ON public.activity_events (module, created_at DESC);

CREATE INDEX IF NOT EXISTS quiz_sessions_status_created_idx ON public.quiz_sessions (status, created_at DESC);

CREATE INDEX IF NOT EXISTS quiz_sessions_user_status_idx ON public.quiz_sessions (user_id, status);

CREATE INDEX IF NOT EXISTS study_sessions_user_started_idx ON public.study_sessions(user_id, started_at DESC);

CREATE INDEX IF NOT EXISTS study_sessions_user_open_idx ON public.study_sessions(user_id) WHERE ended_at IS NULL;

CREATE UNIQUE INDEX IF NOT EXISTS site_pages_one_home_idx ON public.site_pages ((is_home)) WHERE is_home = true;

CREATE INDEX IF NOT EXISTS site_page_sections_page_id_idx ON public.site_page_sections(page_id, sort_order);

CREATE INDEX IF NOT EXISTS idx_content_versions_target ON public.content_versions(target_kind, target_key, created_at DESC);

create index if not exists mcqs_chapter_id_idx on public.mcqs (chapter_id);

create index if not exists mcqs_status_idx on public.mcqs (status);

create index if not exists quiz_questions_quiz_id_idx on public.quiz_questions (quiz_id);

create index if not exists exam_attempts_user_id_idx on public.exam_attempts (user_id);

create index if not exists exam_attempts_created_at_idx on public.exam_attempts (created_at);

create index if not exists attempt_answers_attempt_id_idx on public.attempt_answers (attempt_id);

CREATE INDEX IF NOT EXISTS profiles_last_login_at_idx ON public.profiles(last_login_at DESC);

CREATE INDEX IF NOT EXISTS profiles_deleted_at_idx ON public.profiles(deleted_at);

CREATE INDEX IF NOT EXISTS user_login_events_user_id_idx ON public.user_login_events(user_id);

CREATE INDEX IF NOT EXISTS user_login_events_login_at_idx ON public.user_login_events(login_at DESC);

CREATE INDEX IF NOT EXISTS activity_events_created_at_idx ON public.activity_events (created_at DESC);

CREATE INDEX IF NOT EXISTS activity_events_user_created_idx ON public.activity_events (user_id, created_at DESC);

CREATE INDEX IF NOT EXISTS activity_events_type_created_idx ON public.activity_events (event_type, created_at DESC);

CREATE INDEX IF NOT EXISTS activity_events_path_created_idx ON public.activity_events (page_path, created_at DESC);

CREATE INDEX IF NOT EXISTS activity_events_element_created_idx ON public.activity_events (element_id, created_at DESC);

CREATE INDEX IF NOT EXISTS activity_events_module_created_idx ON public.activity_events (module, created_at DESC);

CREATE INDEX IF NOT EXISTS quiz_sessions_status_created_idx ON public.quiz_sessions (status, created_at DESC);

CREATE INDEX IF NOT EXISTS quiz_sessions_user_status_idx ON public.quiz_sessions (user_id, status);

CREATE INDEX IF NOT EXISTS study_sessions_user_started_idx ON public.study_sessions(user_id, started_at DESC);

CREATE INDEX IF NOT EXISTS study_sessions_user_open_idx ON public.study_sessions(user_id) WHERE ended_at IS NULL;

CREATE UNIQUE INDEX IF NOT EXISTS site_pages_one_home_idx ON public.site_pages ((is_home)) WHERE is_home = true;

CREATE INDEX IF NOT EXISTS site_page_sections_page_id_idx ON public.site_page_sections(page_id, sort_order);

CREATE INDEX IF NOT EXISTS idx_profiles_status ON public.profiles(status);

CREATE INDEX IF NOT EXISTS idx_profiles_level ON public.profiles(level);

CREATE INDEX IF NOT EXISTS idx_profiles_created_at ON public.profiles(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_user_roles_user ON public.user_roles(user_id);

CREATE INDEX IF NOT EXISTS idx_subjects_level ON public.subjects(level);

CREATE INDEX IF NOT EXISTS idx_subjects_status ON public.subjects(status);

CREATE INDEX IF NOT EXISTS idx_chapters_subject ON public.chapters(subject_id);

CREATE INDEX IF NOT EXISTS idx_chapters_status ON public.chapters(status);

CREATE INDEX IF NOT EXISTS idx_mcqs_chapter ON public.mcqs(chapter_id);

CREATE INDEX IF NOT EXISTS idx_mcqs_status ON public.mcqs(status);

CREATE INDEX IF NOT EXISTS idx_mcqs_difficulty ON public.mcqs(difficulty);

CREATE INDEX IF NOT EXISTS idx_mcqs_created_at ON public.mcqs(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_quizzes_kind_status ON public.quizzes(kind, status);

CREATE INDEX IF NOT EXISTS idx_quizzes_subject ON public.quizzes(subject_id);

CREATE INDEX IF NOT EXISTS idx_quizzes_chapter ON public.quizzes(chapter_id);

CREATE INDEX IF NOT EXISTS idx_quizzes_starts_at ON public.quizzes(starts_at);

CREATE INDEX IF NOT EXISTS idx_quizzes_created_at ON public.quizzes(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_qq_quiz ON public.quiz_questions(quiz_id);

CREATE INDEX IF NOT EXISTS idx_qq_mcq ON public.quiz_questions(mcq_id);

CREATE INDEX IF NOT EXISTS idx_attempts_user ON public.exam_attempts(user_id);

CREATE INDEX IF NOT EXISTS idx_attempts_quiz ON public.exam_attempts(quiz_id);

CREATE INDEX IF NOT EXISTS idx_attempts_kind ON public.exam_attempts(kind);

CREATE INDEX IF NOT EXISTS idx_attempts_created_at ON public.exam_attempts(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_attempts_status ON public.exam_attempts(status);

CREATE INDEX IF NOT EXISTS idx_aa_attempt ON public.attempt_answers(attempt_id);

CREATE INDEX IF NOT EXISTS idx_aa_mcq ON public.attempt_answers(mcq_id);

CREATE INDEX IF NOT EXISTS idx_bookmarks_user ON public.mcq_bookmarks(user_id);

CREATE INDEX IF NOT EXISTS idx_wrong_user ON public.mcq_wrong_questions(user_id);

CREATE INDEX IF NOT EXISTS idx_fc_chapter ON public.flash_cards(chapter_id);

CREATE INDEX IF NOT EXISTS idx_fc_subject ON public.flash_cards(subject_id);

CREATE INDEX IF NOT EXISTS idx_fc_status ON public.flash_cards(status);

CREATE INDEX IF NOT EXISTS idx_sn_subject ON public.short_notes(subject_id);

CREATE INDEX IF NOT EXISTS idx_sn_chapter ON public.short_notes(chapter_id);

CREATE INDEX IF NOT EXISTS idx_sn_status ON public.short_notes(status);

CREATE INDEX IF NOT EXISTS idx_qb_subject ON public.question_bank_resources(subject_id);

CREATE INDEX IF NOT EXISTS idx_qb_chapter ON public.question_bank_resources(chapter_id);

CREATE INDEX IF NOT EXISTS idx_qb_status ON public.question_bank_resources(status);

CREATE INDEX IF NOT EXISTS idx_vc_subject ON public.video_classes(subject_id);

CREATE INDEX IF NOT EXISTS idx_vc_chapter ON public.video_classes(chapter_id);

CREATE INDEX IF NOT EXISTS idx_vc_status ON public.video_classes(status);

CREATE INDEX IF NOT EXISTS idx_notif_status ON public.notifications(status);

CREATE INDEX IF NOT EXISTS idx_notif_created_at ON public.notifications(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_notif_scheduled_at ON public.notifications(scheduled_at);

CREATE INDEX IF NOT EXISTS idx_nr_user ON public.notification_reads(user_id);

CREATE INDEX IF NOT EXISTS idx_ae_user ON public.activity_events(user_id);

CREATE INDEX IF NOT EXISTS idx_ae_module ON public.activity_events(module);

CREATE INDEX IF NOT EXISTS idx_ae_created_at ON public.activity_events(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_ae_event_type ON public.activity_events(event_type);

CREATE INDEX IF NOT EXISTS idx_ule_user ON public.user_login_events(user_id);

CREATE INDEX IF NOT EXISTS idx_ule_login_at ON public.user_login_events(login_at DESC);

CREATE INDEX IF NOT EXISTS idx_us_user ON public.user_sessions(user_id);

CREATE INDEX IF NOT EXISTS idx_ss_user ON public.study_sessions(user_id);

CREATE INDEX IF NOT EXISTS idx_ss_created_at ON public.study_sessions(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_sps_page ON public.site_page_sections(page_id);

CREATE INDEX IF NOT EXISTS idx_ma_uploaded_by ON public.media_assets(uploaded_by);

CREATE INDEX IF NOT EXISTS idx_cv_target ON public.content_versions(target_kind, target_key, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_ae_target_kind ON public.activity_events(target_kind);

CREATE INDEX IF NOT EXISTS idx_content_versions_target ON public.content_versions(target_kind, target_key, created_at DESC);

create index if not exists mcqs_chapter_id_idx on public.mcqs (chapter_id);

create index if not exists mcqs_status_idx on public.mcqs (status);

create index if not exists quiz_questions_quiz_id_idx on public.quiz_questions (quiz_id);

create index if not exists exam_attempts_user_id_idx on public.exam_attempts (user_id);

create index if not exists exam_attempts_created_at_idx on public.exam_attempts (created_at);

create index if not exists attempt_answers_attempt_id_idx on public.attempt_answers (attempt_id);

CREATE INDEX IF NOT EXISTS profiles_last_login_at_idx ON public.profiles(last_login_at DESC);

CREATE INDEX IF NOT EXISTS profiles_deleted_at_idx ON public.profiles(deleted_at);

CREATE INDEX IF NOT EXISTS user_login_events_user_id_idx ON public.user_login_events(user_id);

CREATE INDEX IF NOT EXISTS user_login_events_login_at_idx ON public.user_login_events(login_at DESC);

CREATE INDEX IF NOT EXISTS activity_events_created_at_idx ON public.activity_events (created_at DESC);

CREATE INDEX IF NOT EXISTS activity_events_user_created_idx ON public.activity_events (user_id, created_at DESC);

CREATE INDEX IF NOT EXISTS activity_events_type_created_idx ON public.activity_events (event_type, created_at DESC);

CREATE INDEX IF NOT EXISTS activity_events_path_created_idx ON public.activity_events (page_path, created_at DESC);

CREATE INDEX IF NOT EXISTS activity_events_element_created_idx ON public.activity_events (element_id, created_at DESC);

CREATE INDEX IF NOT EXISTS activity_events_module_created_idx ON public.activity_events (module, created_at DESC);

CREATE INDEX IF NOT EXISTS study_sessions_user_started_idx ON public.study_sessions(user_id, started_at DESC);

CREATE INDEX IF NOT EXISTS study_sessions_user_open_idx ON public.study_sessions(user_id) WHERE ended_at IS NULL;

CREATE INDEX IF NOT EXISTS quiz_sessions_status_created_idx ON public.quiz_sessions (status, created_at DESC);

CREATE INDEX IF NOT EXISTS quiz_sessions_user_status_idx ON public.quiz_sessions (user_id, status);

CREATE INDEX IF NOT EXISTS mcqs_question_type_idx ON public.mcqs (question_type);

CREATE UNIQUE INDEX IF NOT EXISTS site_pages_one_home_idx ON public.site_pages ((is_home)) WHERE is_home = true;

CREATE INDEX IF NOT EXISTS site_page_sections_page_id_idx ON public.site_page_sections(page_id, sort_order);

CREATE INDEX IF NOT EXISTS idx_admin_action_log_created_at ON public.admin_action_log (created_at DESC);

CREATE INDEX IF NOT EXISTS idx_admin_action_log_user ON public.admin_action_log (user_id, created_at DESC);

CREATE INDEX IF NOT EXISTS editor_snapshots_page_idx ON public.editor_snapshots (page_id, created_at DESC);

CREATE INDEX IF NOT EXISTS editor_actions_log_page_idx ON public.editor_actions_log (page_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_sys_err_created ON public.system_error_logs (created_at DESC);

CREATE INDEX IF NOT EXISTS idx_sys_err_fingerprint ON public.system_error_logs (fingerprint);

CREATE INDEX IF NOT EXISTS idx_sys_err_severity ON public.system_error_logs (severity, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_sys_err_source ON public.system_error_logs (source, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_sys_err_route ON public.system_error_logs (route);

CREATE INDEX IF NOT EXISTS idx_sys_err_unresolved ON public.system_error_logs (resolved, created_at DESC) WHERE resolved = FALSE;

CREATE INDEX IF NOT EXISTS idx_sys_err_created ON public.system_error_logs (created_at DESC);

CREATE INDEX IF NOT EXISTS idx_sys_err_fingerprint ON public.system_error_logs (fingerprint);

CREATE INDEX IF NOT EXISTS idx_sys_err_severity ON public.system_error_logs (severity, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_sys_err_source ON public.system_error_logs (source, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_sys_err_route ON public.system_error_logs (route);

CREATE INDEX IF NOT EXISTS idx_sys_err_unresolved ON public.system_error_logs (resolved, created_at DESC) WHERE resolved = FALSE;

CREATE INDEX IF NOT EXISTS idx_blog_posts_status_published ON public.blog_posts (status, published_at DESC);

CREATE INDEX IF NOT EXISTS idx_blog_posts_category ON public.blog_posts (category_id);

CREATE INDEX IF NOT EXISTS idx_blog_posts_author ON public.blog_posts (author_id);

CREATE INDEX IF NOT EXISTS idx_blog_views_post_time ON public.blog_views (post_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_admin_notes_user ON public.admin_notes (user_id, is_pinned DESC, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_user_tags_user ON public.user_tags (user_id);

CREATE INDEX IF NOT EXISTS idx_user_tags_tag ON public.user_tags (tag);

CREATE INDEX IF NOT EXISTS idx_user_messages_to ON public.user_messages (to_user_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_user_bans_user ON public.user_bans (user_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_user_bans_active ON public.user_bans (user_id) WHERE lifted_at IS NULL;

CREATE UNIQUE INDEX IF NOT EXISTS uq_blog_views_post_viewer_bucket
  ON public.blog_views (post_id, viewer_hash, time_bucket)
  WHERE viewer_hash IS NOT NULL;


-- =================== 9. RLS POLICIES ===============

DO $$ BEGIN
  CREATE POLICY "users read own roles" ON public.user_roles FOR SELECT TO authenticated USING (auth.uid() = user_id);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$
BEGIN
  IF to_regclass('public.homepage_sections') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'homepage_sections' AND policyname = 'public reads visible homepage sections'
     ) THEN
    CREATE POLICY "public reads visible homepage sections" ON public.homepage_sections
  FOR SELECT TO anon, authenticated USING (visible = true);
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.homepage_sections') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'homepage_sections' AND policyname = 'admins manage homepage sections'
     ) THEN
    CREATE POLICY "admins manage homepage sections" ON public.homepage_sections
  FOR ALL TO authenticated USING (public.has_role(auth.uid(),'admin')) WITH CHECK (public.has_role(auth.uid(),'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.site_settings') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'site_settings' AND policyname = 'public reads site settings'
     ) THEN
    CREATE POLICY "public reads site settings" ON public.site_settings
  FOR SELECT TO anon, authenticated USING (true);
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.site_settings') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'site_settings' AND policyname = 'admins manage site settings'
     ) THEN
    CREATE POLICY "admins manage site settings" ON public.site_settings
  FOR ALL TO authenticated USING (public.has_role(auth.uid(),'admin')) WITH CHECK (public.has_role(auth.uid(),'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.module_visibility') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'module_visibility' AND policyname = 'public reads module visibility'
     ) THEN
    CREATE POLICY "public reads module visibility" ON public.module_visibility
  FOR SELECT TO anon, authenticated USING (true);
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.module_visibility') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'module_visibility' AND policyname = 'admins update module visibility'
     ) THEN
    CREATE POLICY "admins update module visibility" ON public.module_visibility
  FOR UPDATE TO authenticated USING (public.has_role(auth.uid(),'admin')) WITH CHECK (public.has_role(auth.uid(),'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.content_versions') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'content_versions' AND policyname = 'admins read content versions'
     ) THEN
    CREATE POLICY "admins read content versions" ON public.content_versions
  FOR SELECT TO authenticated USING (public.has_role(auth.uid(),'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.content_versions') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'content_versions' AND policyname = 'admins insert content versions'
     ) THEN
    CREATE POLICY "admins insert content versions" ON public.content_versions
  FOR INSERT TO authenticated WITH CHECK (public.has_role(auth.uid(),'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.media_assets') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'media_assets' AND policyname = 'public reads media assets'
     ) THEN
    CREATE POLICY "public reads media assets" ON public.media_assets
  FOR SELECT TO anon, authenticated USING (true);
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.media_assets') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'media_assets' AND policyname = 'admins manage media assets'
     ) THEN
    CREATE POLICY "admins manage media assets" ON public.media_assets
  FOR ALL TO authenticated USING (public.has_role(auth.uid(),'admin')) WITH CHECK (public.has_role(auth.uid(),'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.user_sessions') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'user_sessions' AND policyname = 'users read own session'
     ) THEN
    CREATE POLICY "users read own session" ON public.user_sessions FOR SELECT TO authenticated USING (auth.uid() = user_id);
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.profiles') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'profiles' AND policyname = 'profiles_select_all'
     ) THEN
    create policy "profiles_select_all" on public.profiles for select using (true);
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.profiles') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'profiles' AND policyname = 'profiles_insert_own'
     ) THEN
    create policy "profiles_insert_own" on public.profiles for insert with check (id = auth.uid());
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.profiles') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'profiles' AND policyname = 'profiles_update_own'
     ) THEN
    create policy "profiles_update_own" on public.profiles for update using (id = auth.uid());
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.avatars') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'avatars' AND policyname = 'avatars_own'
     ) THEN
    create policy "avatars_own" on public.avatars for all using (user_id = auth.uid());
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.levels') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'levels' AND policyname = 'levels_select'
     ) THEN
    create policy "levels_select" on public.levels for select using (true);
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.levels') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'levels' AND policyname = 'levels_write_admin'
     ) THEN
    create policy "levels_write_admin" on public.levels for all using (public.has_role(auth.uid(), 'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.subjects') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'subjects' AND policyname = 'subjects_select'
     ) THEN
    create policy "subjects_select" on public.subjects for select using (true);
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.subjects') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'subjects' AND policyname = 'subjects_write_admin'
     ) THEN
    create policy "subjects_write_admin" on public.subjects for all using (public.has_role(auth.uid(), 'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.chapters') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'chapters' AND policyname = 'chapters_select'
     ) THEN
    create policy "chapters_select" on public.chapters for select using (true);
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.chapters') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'chapters' AND policyname = 'chapters_write_admin'
     ) THEN
    create policy "chapters_write_admin" on public.chapters for all using (public.has_role(auth.uid(), 'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.mcqs') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'mcqs' AND policyname = 'mcqs_select_published'
     ) THEN
    create policy "mcqs_select_published" on public.mcqs for select using (status = 'published' or public.has_role(auth.uid(), 'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.mcqs') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'mcqs' AND policyname = 'mcqs_write_admin'
     ) THEN
    create policy "mcqs_write_admin" on public.mcqs for all using (public.has_role(auth.uid(), 'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.mcq_bookmarks') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'mcq_bookmarks' AND policyname = 'mcq_bookmarks_own'
     ) THEN
    create policy "mcq_bookmarks_own" on public.mcq_bookmarks for all using (user_id = auth.uid());
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.mcq_wrong_questions') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'mcq_wrong_questions' AND policyname = 'mcq_wrong_questions_own'
     ) THEN
    create policy "mcq_wrong_questions_own" on public.mcq_wrong_questions for all using (user_id = auth.uid());
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.mcq_delete_audit') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'mcq_delete_audit' AND policyname = 'mcq_delete_audit_admin'
     ) THEN
    create policy "mcq_delete_audit_admin" on public.mcq_delete_audit for all using (public.has_role(auth.uid(), 'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.quizzes') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'quizzes' AND policyname = 'quizzes_select'
     ) THEN
    create policy "quizzes_select" on public.quizzes for select using (is_public = true or public.has_role(auth.uid(), 'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.quizzes') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'quizzes' AND policyname = 'quizzes_write_admin'
     ) THEN
    create policy "quizzes_write_admin" on public.quizzes for all using (public.has_role(auth.uid(), 'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.quiz_questions') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'quiz_questions' AND policyname = 'quiz_questions_select'
     ) THEN
    create policy "quiz_questions_select" on public.quiz_questions for select using (true);
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.quiz_questions') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'quiz_questions' AND policyname = 'quiz_questions_write_admin'
     ) THEN
    create policy "quiz_questions_write_admin" on public.quiz_questions for all using (public.has_role(auth.uid(), 'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.quiz_sessions') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'quiz_sessions' AND policyname = 'quiz_sessions_own'
     ) THEN
    create policy "quiz_sessions_own" on public.quiz_sessions for all using (user_id = auth.uid() or public.has_role(auth.uid(), 'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.exam_attempts') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'exam_attempts' AND policyname = 'exam_attempts_own_select'
     ) THEN
    create policy "exam_attempts_own_select" on public.exam_attempts for select using (user_id = auth.uid() or public.has_role(auth.uid(), 'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.exam_attempts') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'exam_attempts' AND policyname = 'exam_attempts_own_insert'
     ) THEN
    create policy "exam_attempts_own_insert" on public.exam_attempts for insert with check (user_id = auth.uid());
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.attempt_answers') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'attempt_answers' AND policyname = 'attempt_answers_own'
     ) THEN
    create policy "attempt_answers_own" on public.attempt_answers for select using (
  exists (select 1 from public.exam_attempts a where a.id = attempt_id and (a.user_id = auth.uid() or public.has_role(auth.uid(), 'admin')))
);
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.attempt_answers') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'attempt_answers' AND policyname = 'attempt_answers_insert_own'
     ) THEN
    create policy "attempt_answers_insert_own" on public.attempt_answers for insert with check (
  exists (select 1 from public.exam_attempts a where a.id = attempt_id and a.user_id = auth.uid())
);
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.flash_cards') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'flash_cards' AND policyname = 'flash_cards_select'
     ) THEN
    create policy "flash_cards_select" on public.flash_cards for select using ((status = 'published' and is_hidden = false) or public.has_role(auth.uid(), 'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.flash_cards') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'flash_cards' AND policyname = 'flash_cards_write_admin'
     ) THEN
    create policy "flash_cards_write_admin" on public.flash_cards for all using (public.has_role(auth.uid(), 'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.flash_card_visibility') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'flash_card_visibility' AND policyname = 'flash_card_visibility_select'
     ) THEN
    create policy "flash_card_visibility_select" on public.flash_card_visibility for select using (true);
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.flash_card_visibility') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'flash_card_visibility' AND policyname = 'flash_card_visibility_write_admin'
     ) THEN
    create policy "flash_card_visibility_write_admin" on public.flash_card_visibility for all using (public.has_role(auth.uid(), 'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.short_notes') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'short_notes' AND policyname = 'short_notes_select'
     ) THEN
    create policy "short_notes_select" on public.short_notes for select using ((status = 'published' and is_hidden = false) or public.has_role(auth.uid(), 'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.short_notes') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'short_notes' AND policyname = 'short_notes_write_admin'
     ) THEN
    create policy "short_notes_write_admin" on public.short_notes for all using (public.has_role(auth.uid(), 'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.short_notes_visibility') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'short_notes_visibility' AND policyname = 'short_notes_visibility_select'
     ) THEN
    create policy "short_notes_visibility_select" on public.short_notes_visibility for select using (true);
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.short_notes_visibility') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'short_notes_visibility' AND policyname = 'short_notes_visibility_write_admin'
     ) THEN
    create policy "short_notes_visibility_write_admin" on public.short_notes_visibility for all using (public.has_role(auth.uid(), 'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.question_bank_resources') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'question_bank_resources' AND policyname = 'question_bank_resources_select'
     ) THEN
    create policy "question_bank_resources_select" on public.question_bank_resources for select using ((status = 'published' and is_hidden = false) or public.has_role(auth.uid(), 'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.question_bank_resources') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'question_bank_resources' AND policyname = 'question_bank_resources_write_admin'
     ) THEN
    create policy "question_bank_resources_write_admin" on public.question_bank_resources for all using (public.has_role(auth.uid(), 'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.question_bank_visibility') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'question_bank_visibility' AND policyname = 'question_bank_visibility_select'
     ) THEN
    create policy "question_bank_visibility_select" on public.question_bank_visibility for select using (true);
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.question_bank_visibility') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'question_bank_visibility' AND policyname = 'question_bank_visibility_write_admin'
     ) THEN
    create policy "question_bank_visibility_write_admin" on public.question_bank_visibility for all using (public.has_role(auth.uid(), 'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.video_classes') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'video_classes' AND policyname = 'video_classes_select'
     ) THEN
    create policy "video_classes_select" on public.video_classes for select using ((status = 'published' and is_hidden = false) or public.has_role(auth.uid(), 'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.video_classes') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'video_classes' AND policyname = 'video_classes_write_admin'
     ) THEN
    create policy "video_classes_write_admin" on public.video_classes for all using (public.has_role(auth.uid(), 'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.video_class_visibility') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'video_class_visibility' AND policyname = 'video_class_visibility_select'
     ) THEN
    create policy "video_class_visibility_select" on public.video_class_visibility for select using (true);
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.video_class_visibility') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'video_class_visibility' AND policyname = 'video_class_visibility_write_admin'
     ) THEN
    create policy "video_class_visibility_write_admin" on public.video_class_visibility for all using (public.has_role(auth.uid(), 'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.notifications') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'notifications' AND policyname = 'notifications_select_sent'
     ) THEN
    create policy "notifications_select_sent" on public.notifications for select using (status = 'sent' or public.has_role(auth.uid(), 'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.notifications') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'notifications' AND policyname = 'notifications_write_admin'
     ) THEN
    create policy "notifications_write_admin" on public.notifications for all using (public.has_role(auth.uid(), 'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.notification_reads') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'notification_reads' AND policyname = 'notification_reads_own'
     ) THEN
    create policy "notification_reads_own" on public.notification_reads for all using (user_id = auth.uid());
  END IF;
END $$;

DO $$ BEGIN
  CREATE POLICY "user_login_events_own_insert"
    ON public.user_login_events FOR INSERT TO authenticated
    WITH CHECK (user_id = auth.uid());
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE POLICY "user_login_events_own_update"
    ON public.user_login_events FOR UPDATE TO authenticated
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE POLICY "user_login_events_select"
    ON public.user_login_events FOR SELECT TO authenticated
    USING (user_id = auth.uid() OR public.has_role(auth.uid(), 'admin'::app_role));
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE POLICY activity_events_insert_own ON public.activity_events
    FOR INSERT TO authenticated WITH CHECK (user_id IS NULL OR user_id = auth.uid());
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE POLICY activity_events_select_admin ON public.activity_events
    FOR SELECT TO authenticated USING (public.has_role(auth.uid(), 'admin'::app_role));
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DROP POLICY IF EXISTS profiles_select_all ON public.profiles;

DO $$ BEGIN
  CREATE POLICY profiles_select_authenticated ON public.profiles FOR SELECT TO authenticated USING (true);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DROP POLICY IF EXISTS user_roles_insert_admin ON public.user_roles;

DO $$
BEGIN
  IF to_regclass('public.user_roles') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'user_roles' AND policyname = 'user_roles_insert_admin'
     ) THEN
    CREATE POLICY user_roles_insert_admin ON public.user_roles FOR INSERT TO authenticated
  WITH CHECK (public.has_role(auth.uid(), 'admin'::public.app_role));
  END IF;
END $$;

DROP POLICY IF EXISTS user_roles_update_admin ON public.user_roles;

DO $$
BEGIN
  IF to_regclass('public.user_roles') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'user_roles' AND policyname = 'user_roles_update_admin'
     ) THEN
    CREATE POLICY user_roles_update_admin ON public.user_roles FOR UPDATE TO authenticated
  USING (public.has_role(auth.uid(), 'admin'::public.app_role)) WITH CHECK (public.has_role(auth.uid(), 'admin'::public.app_role));
  END IF;
END $$;

DROP POLICY IF EXISTS user_roles_delete_admin ON public.user_roles;

DO $$
BEGIN
  IF to_regclass('public.user_roles') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'user_roles' AND policyname = 'user_roles_delete_admin'
     ) THEN
    CREATE POLICY user_roles_delete_admin ON public.user_roles FOR DELETE TO authenticated
  USING (public.has_role(auth.uid(), 'admin'::public.app_role));
  END IF;
END $$;

DROP POLICY IF EXISTS notifications_select_sent ON public.notifications;

DO $$ BEGIN
  CREATE POLICY notifications_select_admin ON public.notifications FOR SELECT TO authenticated
    USING (public.has_role(auth.uid(), 'admin'::public.app_role));
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE POLICY notifications_select_audience ON public.notifications FOR SELECT TO authenticated
    USING (
      status = 'sent' AND (
        audience = 'all'
        OR (audience = 'users' AND auth.uid() = ANY(audience_user_ids))
        OR (audience = 'level' AND audience_level IS NOT NULL AND EXISTS (
          SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.level = audience_level))
      )
    );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$
BEGIN
  IF to_regclass('public.study_sessions') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'study_sessions' AND policyname = 'study_sessions_select_own'
     ) THEN
    CREATE POLICY study_sessions_select_own
  ON public.study_sessions FOR SELECT TO authenticated
  USING (user_id = auth.uid() OR public.has_role(auth.uid(), 'admin'::app_role));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.study_sessions') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'study_sessions' AND policyname = 'study_sessions_insert_own'
     ) THEN
    CREATE POLICY study_sessions_insert_own
  ON public.study_sessions FOR INSERT TO authenticated
  WITH CHECK (user_id = auth.uid());
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.study_sessions') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'study_sessions' AND policyname = 'study_sessions_update_own'
     ) THEN
    CREATE POLICY study_sessions_update_own
  ON public.study_sessions FOR UPDATE TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());
  END IF;
END $$;

DO $$ BEGIN
  CREATE POLICY "users read own roles" ON public.user_roles FOR SELECT TO authenticated USING (auth.uid() = user_id);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$
BEGIN
  IF to_regclass('public.homepage_sections') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'homepage_sections' AND policyname = 'public reads visible homepage sections'
     ) THEN
    CREATE POLICY "public reads visible homepage sections" ON public.homepage_sections
  FOR SELECT TO anon, authenticated USING (visible = true);
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.homepage_sections') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'homepage_sections' AND policyname = 'admins manage homepage sections'
     ) THEN
    CREATE POLICY "admins manage homepage sections" ON public.homepage_sections
  FOR ALL TO authenticated USING (public.has_role(auth.uid(),'admin')) WITH CHECK (public.has_role(auth.uid(),'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.site_settings') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'site_settings' AND policyname = 'public reads site settings'
     ) THEN
    CREATE POLICY "public reads site settings" ON public.site_settings
  FOR SELECT TO anon, authenticated USING (true);
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.site_settings') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'site_settings' AND policyname = 'admins manage site settings'
     ) THEN
    CREATE POLICY "admins manage site settings" ON public.site_settings
  FOR ALL TO authenticated USING (public.has_role(auth.uid(),'admin')) WITH CHECK (public.has_role(auth.uid(),'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.module_visibility') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'module_visibility' AND policyname = 'public reads module visibility'
     ) THEN
    CREATE POLICY "public reads module visibility" ON public.module_visibility
  FOR SELECT TO anon, authenticated USING (true);
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.module_visibility') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'module_visibility' AND policyname = 'admins update module visibility'
     ) THEN
    CREATE POLICY "admins update module visibility" ON public.module_visibility
  FOR UPDATE TO authenticated USING (public.has_role(auth.uid(),'admin')) WITH CHECK (public.has_role(auth.uid(),'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.content_versions') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'content_versions' AND policyname = 'admins read content versions'
     ) THEN
    CREATE POLICY "admins read content versions" ON public.content_versions
  FOR SELECT TO authenticated USING (public.has_role(auth.uid(),'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.content_versions') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'content_versions' AND policyname = 'admins insert content versions'
     ) THEN
    CREATE POLICY "admins insert content versions" ON public.content_versions
  FOR INSERT TO authenticated WITH CHECK (public.has_role(auth.uid(),'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.media_assets') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'media_assets' AND policyname = 'public reads media assets'
     ) THEN
    CREATE POLICY "public reads media assets" ON public.media_assets
  FOR SELECT TO anon, authenticated USING (true);
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.media_assets') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'media_assets' AND policyname = 'admins manage media assets'
     ) THEN
    CREATE POLICY "admins manage media assets" ON public.media_assets
  FOR ALL TO authenticated USING (public.has_role(auth.uid(),'admin')) WITH CHECK (public.has_role(auth.uid(),'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.user_sessions') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'user_sessions' AND policyname = 'users read own session'
     ) THEN
    CREATE POLICY "users read own session" ON public.user_sessions FOR SELECT TO authenticated USING (auth.uid() = user_id);
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.profiles') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'profiles' AND policyname = 'profiles_select_all'
     ) THEN
    create policy "profiles_select_all" on public.profiles for select using (true);
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.profiles') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'profiles' AND policyname = 'profiles_insert_own'
     ) THEN
    create policy "profiles_insert_own" on public.profiles for insert with check (id = auth.uid());
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.profiles') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'profiles' AND policyname = 'profiles_update_own'
     ) THEN
    create policy "profiles_update_own" on public.profiles for update using (id = auth.uid());
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.avatars') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'avatars' AND policyname = 'avatars_own'
     ) THEN
    create policy "avatars_own" on public.avatars for all using (user_id = auth.uid());
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.levels') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'levels' AND policyname = 'levels_select'
     ) THEN
    create policy "levels_select" on public.levels for select using (true);
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.levels') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'levels' AND policyname = 'levels_write_admin'
     ) THEN
    create policy "levels_write_admin" on public.levels for all using (public.has_role(auth.uid(), 'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.subjects') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'subjects' AND policyname = 'subjects_select'
     ) THEN
    create policy "subjects_select" on public.subjects for select using (true);
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.subjects') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'subjects' AND policyname = 'subjects_write_admin'
     ) THEN
    create policy "subjects_write_admin" on public.subjects for all using (public.has_role(auth.uid(), 'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.chapters') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'chapters' AND policyname = 'chapters_select'
     ) THEN
    create policy "chapters_select" on public.chapters for select using (true);
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.chapters') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'chapters' AND policyname = 'chapters_write_admin'
     ) THEN
    create policy "chapters_write_admin" on public.chapters for all using (public.has_role(auth.uid(), 'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.mcqs') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'mcqs' AND policyname = 'mcqs_select_published'
     ) THEN
    create policy "mcqs_select_published" on public.mcqs for select using (status = 'published' or public.has_role(auth.uid(), 'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.mcqs') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'mcqs' AND policyname = 'mcqs_write_admin'
     ) THEN
    create policy "mcqs_write_admin" on public.mcqs for all using (public.has_role(auth.uid(), 'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.mcq_bookmarks') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'mcq_bookmarks' AND policyname = 'mcq_bookmarks_own'
     ) THEN
    create policy "mcq_bookmarks_own" on public.mcq_bookmarks for all using (user_id = auth.uid());
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.mcq_wrong_questions') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'mcq_wrong_questions' AND policyname = 'mcq_wrong_questions_own'
     ) THEN
    create policy "mcq_wrong_questions_own" on public.mcq_wrong_questions for all using (user_id = auth.uid());
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.mcq_delete_audit') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'mcq_delete_audit' AND policyname = 'mcq_delete_audit_admin'
     ) THEN
    create policy "mcq_delete_audit_admin" on public.mcq_delete_audit for all using (public.has_role(auth.uid(), 'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.quizzes') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'quizzes' AND policyname = 'quizzes_select'
     ) THEN
    create policy "quizzes_select" on public.quizzes for select using (is_public = true or public.has_role(auth.uid(), 'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.quizzes') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'quizzes' AND policyname = 'quizzes_write_admin'
     ) THEN
    create policy "quizzes_write_admin" on public.quizzes for all using (public.has_role(auth.uid(), 'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.quiz_questions') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'quiz_questions' AND policyname = 'quiz_questions_select'
     ) THEN
    create policy "quiz_questions_select" on public.quiz_questions for select using (true);
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.quiz_questions') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'quiz_questions' AND policyname = 'quiz_questions_write_admin'
     ) THEN
    create policy "quiz_questions_write_admin" on public.quiz_questions for all using (public.has_role(auth.uid(), 'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.quiz_sessions') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'quiz_sessions' AND policyname = 'quiz_sessions_own'
     ) THEN
    create policy "quiz_sessions_own" on public.quiz_sessions for all using (user_id = auth.uid() or public.has_role(auth.uid(), 'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.exam_attempts') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'exam_attempts' AND policyname = 'exam_attempts_own_select'
     ) THEN
    create policy "exam_attempts_own_select" on public.exam_attempts for select using (user_id = auth.uid() or public.has_role(auth.uid(), 'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.exam_attempts') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'exam_attempts' AND policyname = 'exam_attempts_own_insert'
     ) THEN
    create policy "exam_attempts_own_insert" on public.exam_attempts for insert with check (user_id = auth.uid());
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.attempt_answers') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'attempt_answers' AND policyname = 'attempt_answers_own'
     ) THEN
    create policy "attempt_answers_own" on public.attempt_answers for select using (
  exists (select 1 from public.exam_attempts a where a.id = attempt_id and (a.user_id = auth.uid() or public.has_role(auth.uid(), 'admin')))
);
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.attempt_answers') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'attempt_answers' AND policyname = 'attempt_answers_insert_own'
     ) THEN
    create policy "attempt_answers_insert_own" on public.attempt_answers for insert with check (
  exists (select 1 from public.exam_attempts a where a.id = attempt_id and a.user_id = auth.uid())
);
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.flash_cards') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'flash_cards' AND policyname = 'flash_cards_select'
     ) THEN
    create policy "flash_cards_select" on public.flash_cards for select using ((status = 'published' and is_hidden = false) or public.has_role(auth.uid(), 'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.flash_cards') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'flash_cards' AND policyname = 'flash_cards_write_admin'
     ) THEN
    create policy "flash_cards_write_admin" on public.flash_cards for all using (public.has_role(auth.uid(), 'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.flash_card_visibility') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'flash_card_visibility' AND policyname = 'flash_card_visibility_select'
     ) THEN
    create policy "flash_card_visibility_select" on public.flash_card_visibility for select using (true);
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.flash_card_visibility') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'flash_card_visibility' AND policyname = 'flash_card_visibility_write_admin'
     ) THEN
    create policy "flash_card_visibility_write_admin" on public.flash_card_visibility for all using (public.has_role(auth.uid(), 'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.short_notes') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'short_notes' AND policyname = 'short_notes_select'
     ) THEN
    create policy "short_notes_select" on public.short_notes for select using ((status = 'published' and is_hidden = false) or public.has_role(auth.uid(), 'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.short_notes') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'short_notes' AND policyname = 'short_notes_write_admin'
     ) THEN
    create policy "short_notes_write_admin" on public.short_notes for all using (public.has_role(auth.uid(), 'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.short_notes_visibility') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'short_notes_visibility' AND policyname = 'short_notes_visibility_select'
     ) THEN
    create policy "short_notes_visibility_select" on public.short_notes_visibility for select using (true);
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.short_notes_visibility') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'short_notes_visibility' AND policyname = 'short_notes_visibility_write_admin'
     ) THEN
    create policy "short_notes_visibility_write_admin" on public.short_notes_visibility for all using (public.has_role(auth.uid(), 'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.question_bank_resources') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'question_bank_resources' AND policyname = 'question_bank_resources_select'
     ) THEN
    create policy "question_bank_resources_select" on public.question_bank_resources for select using ((status = 'published' and is_hidden = false) or public.has_role(auth.uid(), 'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.question_bank_resources') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'question_bank_resources' AND policyname = 'question_bank_resources_write_admin'
     ) THEN
    create policy "question_bank_resources_write_admin" on public.question_bank_resources for all using (public.has_role(auth.uid(), 'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.question_bank_visibility') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'question_bank_visibility' AND policyname = 'question_bank_visibility_select'
     ) THEN
    create policy "question_bank_visibility_select" on public.question_bank_visibility for select using (true);
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.question_bank_visibility') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'question_bank_visibility' AND policyname = 'question_bank_visibility_write_admin'
     ) THEN
    create policy "question_bank_visibility_write_admin" on public.question_bank_visibility for all using (public.has_role(auth.uid(), 'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.video_classes') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'video_classes' AND policyname = 'video_classes_select'
     ) THEN
    create policy "video_classes_select" on public.video_classes for select using ((status = 'published' and is_hidden = false) or public.has_role(auth.uid(), 'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.video_classes') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'video_classes' AND policyname = 'video_classes_write_admin'
     ) THEN
    create policy "video_classes_write_admin" on public.video_classes for all using (public.has_role(auth.uid(), 'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.video_class_visibility') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'video_class_visibility' AND policyname = 'video_class_visibility_select'
     ) THEN
    create policy "video_class_visibility_select" on public.video_class_visibility for select using (true);
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.video_class_visibility') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'video_class_visibility' AND policyname = 'video_class_visibility_write_admin'
     ) THEN
    create policy "video_class_visibility_write_admin" on public.video_class_visibility for all using (public.has_role(auth.uid(), 'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.notifications') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'notifications' AND policyname = 'notifications_select_sent'
     ) THEN
    create policy "notifications_select_sent" on public.notifications for select using (status = 'sent' or public.has_role(auth.uid(), 'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.notifications') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'notifications' AND policyname = 'notifications_write_admin'
     ) THEN
    create policy "notifications_write_admin" on public.notifications for all using (public.has_role(auth.uid(), 'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.notification_reads') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'notification_reads' AND policyname = 'notification_reads_own'
     ) THEN
    create policy "notification_reads_own" on public.notification_reads for all using (user_id = auth.uid());
  END IF;
END $$;

DO $$ BEGIN
  CREATE POLICY "user_login_events_own_insert"
    ON public.user_login_events FOR INSERT TO authenticated
    WITH CHECK (user_id = auth.uid());
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE POLICY "user_login_events_own_update"
    ON public.user_login_events FOR UPDATE TO authenticated
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE POLICY "user_login_events_select"
    ON public.user_login_events FOR SELECT TO authenticated
    USING (user_id = auth.uid() OR public.has_role(auth.uid(), 'admin'::app_role));
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE POLICY activity_events_insert_own ON public.activity_events
    FOR INSERT TO authenticated WITH CHECK (user_id IS NULL OR user_id = auth.uid());
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE POLICY activity_events_select_admin ON public.activity_events
    FOR SELECT TO authenticated USING (public.has_role(auth.uid(), 'admin'::app_role));
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DROP POLICY IF EXISTS profiles_select_all ON public.profiles;

DO $$ BEGIN
  CREATE POLICY profiles_select_authenticated ON public.profiles FOR SELECT TO authenticated USING (true);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DROP POLICY IF EXISTS user_roles_insert_admin ON public.user_roles;

DO $$
BEGIN
  IF to_regclass('public.user_roles') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'user_roles' AND policyname = 'user_roles_insert_admin'
     ) THEN
    CREATE POLICY user_roles_insert_admin ON public.user_roles FOR INSERT TO authenticated
  WITH CHECK (public.has_role(auth.uid(), 'admin'::public.app_role));
  END IF;
END $$;

DROP POLICY IF EXISTS user_roles_update_admin ON public.user_roles;

DO $$
BEGIN
  IF to_regclass('public.user_roles') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'user_roles' AND policyname = 'user_roles_update_admin'
     ) THEN
    CREATE POLICY user_roles_update_admin ON public.user_roles FOR UPDATE TO authenticated
  USING (public.has_role(auth.uid(), 'admin'::public.app_role)) WITH CHECK (public.has_role(auth.uid(), 'admin'::public.app_role));
  END IF;
END $$;

DROP POLICY IF EXISTS user_roles_delete_admin ON public.user_roles;

DO $$
BEGIN
  IF to_regclass('public.user_roles') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'user_roles' AND policyname = 'user_roles_delete_admin'
     ) THEN
    CREATE POLICY user_roles_delete_admin ON public.user_roles FOR DELETE TO authenticated
  USING (public.has_role(auth.uid(), 'admin'::public.app_role));
  END IF;
END $$;

DROP POLICY IF EXISTS notifications_select_sent ON public.notifications;

DO $$ BEGIN
  CREATE POLICY notifications_select_admin ON public.notifications FOR SELECT TO authenticated
    USING (public.has_role(auth.uid(), 'admin'::public.app_role));
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE POLICY notifications_select_audience ON public.notifications FOR SELECT TO authenticated
    USING (
      status = 'sent' AND (
        audience = 'all'
        OR (audience = 'users' AND auth.uid() = ANY(audience_user_ids))
        OR (audience = 'level' AND audience_level IS NOT NULL AND EXISTS (
          SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.level = audience_level))
      )
    );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$
BEGIN
  IF to_regclass('public.study_sessions') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'study_sessions' AND policyname = 'study_sessions_own_select'
     ) THEN
    CREATE POLICY "study_sessions_own_select"
  ON public.study_sessions FOR SELECT TO authenticated
  USING (user_id = auth.uid() OR public.has_role(auth.uid(), 'admin'::app_role));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.study_sessions') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'study_sessions' AND policyname = 'study_sessions_own_insert'
     ) THEN
    CREATE POLICY "study_sessions_own_insert"
  ON public.study_sessions FOR INSERT TO authenticated
  WITH CHECK (user_id = auth.uid());
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.study_sessions') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'study_sessions' AND policyname = 'study_sessions_own_update'
     ) THEN
    CREATE POLICY "study_sessions_own_update"
  ON public.study_sessions FOR UPDATE TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());
  END IF;
END $$;

DO $$ BEGIN
  CREATE POLICY "users read own roles" ON public.user_roles FOR SELECT TO authenticated USING (auth.uid() = user_id);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN CREATE POLICY "public reads visible homepage sections" ON public.homepage_sections FOR SELECT TO anon, authenticated USING (visible = true); EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN CREATE POLICY "admins manage homepage sections" ON public.homepage_sections FOR ALL TO authenticated USING (public.has_role(auth.uid(),'admin')) WITH CHECK (public.has_role(auth.uid(),'admin')); EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN CREATE POLICY "public reads site settings" ON public.site_settings FOR SELECT TO anon, authenticated USING (true); EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN CREATE POLICY "admins manage site settings" ON public.site_settings FOR ALL TO authenticated USING (public.has_role(auth.uid(),'admin')) WITH CHECK (public.has_role(auth.uid(),'admin')); EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN CREATE POLICY "public reads module visibility" ON public.module_visibility FOR SELECT TO anon, authenticated USING (true); EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN CREATE POLICY "admins update module visibility" ON public.module_visibility FOR UPDATE TO authenticated USING (public.has_role(auth.uid(),'admin')) WITH CHECK (public.has_role(auth.uid(),'admin')); EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN CREATE POLICY "admins read content versions" ON public.content_versions FOR SELECT TO authenticated USING (public.has_role(auth.uid(),'admin')); EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN CREATE POLICY "admins insert content versions" ON public.content_versions FOR INSERT TO authenticated WITH CHECK (public.has_role(auth.uid(),'admin')); EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN CREATE POLICY "public reads media assets" ON public.media_assets FOR SELECT TO anon, authenticated USING (true); EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN CREATE POLICY "admins manage media assets" ON public.media_assets FOR ALL TO authenticated USING (public.has_role(auth.uid(),'admin')) WITH CHECK (public.has_role(auth.uid(),'admin')); EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN CREATE POLICY "users read own session" ON public.user_sessions FOR SELECT TO authenticated USING (auth.uid() = user_id); EXCEPTION WHEN duplicate_object THEN NULL; END $$;

do $$ begin create policy "profiles_select_all" on public.profiles for select using (true); exception when duplicate_object then null; end $$;

do $$ begin create policy "profiles_insert_own" on public.profiles for insert with check (id = auth.uid()); exception when duplicate_object then null; end $$;

do $$ begin create policy "profiles_update_own" on public.profiles for update using (id = auth.uid()); exception when duplicate_object then null; end $$;

do $$ begin create policy "avatars_own" on public.avatars for all using (user_id = auth.uid()); exception when duplicate_object then null; end $$;

do $$ begin create policy "levels_select" on public.levels for select using (true); exception when duplicate_object then null; end $$;

do $$ begin create policy "levels_write_admin" on public.levels for all using (public.has_role(auth.uid(), 'admin')); exception when duplicate_object then null; end $$;

do $$ begin create policy "subjects_select" on public.subjects for select using (true); exception when duplicate_object then null; end $$;

do $$ begin create policy "subjects_write_admin" on public.subjects for all using (public.has_role(auth.uid(), 'admin')); exception when duplicate_object then null; end $$;

do $$ begin create policy "chapters_select" on public.chapters for select using (true); exception when duplicate_object then null; end $$;

do $$ begin create policy "chapters_write_admin" on public.chapters for all using (public.has_role(auth.uid(), 'admin')); exception when duplicate_object then null; end $$;

do $$ begin create policy "mcqs_select_published" on public.mcqs for select using (status = 'published' or public.has_role(auth.uid(), 'admin')); exception when duplicate_object then null; end $$;

do $$ begin create policy "mcqs_write_admin" on public.mcqs for all using (public.has_role(auth.uid(), 'admin')); exception when duplicate_object then null; end $$;

do $$ begin create policy "mcq_bookmarks_own" on public.mcq_bookmarks for all using (user_id = auth.uid()); exception when duplicate_object then null; end $$;

do $$ begin create policy "mcq_wrong_questions_own" on public.mcq_wrong_questions for all using (user_id = auth.uid()); exception when duplicate_object then null; end $$;

do $$ begin create policy "mcq_delete_audit_admin" on public.mcq_delete_audit for all using (public.has_role(auth.uid(), 'admin')); exception when duplicate_object then null; end $$;

do $$ begin create policy "quizzes_select" on public.quizzes for select using (is_public = true or public.has_role(auth.uid(), 'admin')); exception when duplicate_object then null; end $$;

do $$ begin create policy "quizzes_write_admin" on public.quizzes for all using (public.has_role(auth.uid(), 'admin')); exception when duplicate_object then null; end $$;

do $$ begin create policy "quiz_questions_select" on public.quiz_questions for select using (true); exception when duplicate_object then null; end $$;

do $$ begin create policy "quiz_questions_write_admin" on public.quiz_questions for all using (public.has_role(auth.uid(), 'admin')); exception when duplicate_object then null; end $$;

do $$ begin create policy "quiz_sessions_own" on public.quiz_sessions for all using (user_id = auth.uid() or public.has_role(auth.uid(), 'admin')); exception when duplicate_object then null; end $$;

do $$ begin create policy "exam_attempts_own_select" on public.exam_attempts for select using (user_id = auth.uid() or public.has_role(auth.uid(), 'admin')); exception when duplicate_object then null; end $$;

do $$ begin create policy "exam_attempts_own_insert" on public.exam_attempts for insert with check (user_id = auth.uid()); exception when duplicate_object then null; end $$;

do $$ begin create policy "attempt_answers_own" on public.attempt_answers for select using (exists (select 1 from public.exam_attempts a where a.id = attempt_id and (a.user_id = auth.uid() or public.has_role(auth.uid(), 'admin')))); exception when duplicate_object then null; end $$;

do $$ begin create policy "attempt_answers_insert_own" on public.attempt_answers for insert with check (exists (select 1 from public.exam_attempts a where a.id = attempt_id and a.user_id = auth.uid())); exception when duplicate_object then null; end $$;

do $$ begin create policy "flash_cards_select" on public.flash_cards for select using ((status = 'published' and is_hidden = false) or public.has_role(auth.uid(), 'admin')); exception when duplicate_object then null; end $$;

do $$ begin create policy "flash_cards_write_admin" on public.flash_cards for all using (public.has_role(auth.uid(), 'admin')); exception when duplicate_object then null; end $$;

do $$ begin create policy "flash_card_visibility_select" on public.flash_card_visibility for select using (true); exception when duplicate_object then null; end $$;

do $$ begin create policy "flash_card_visibility_write_admin" on public.flash_card_visibility for all using (public.has_role(auth.uid(), 'admin')); exception when duplicate_object then null; end $$;

do $$ begin create policy "short_notes_select" on public.short_notes for select using ((status = 'published' and is_hidden = false) or public.has_role(auth.uid(), 'admin')); exception when duplicate_object then null; end $$;

do $$ begin create policy "short_notes_write_admin" on public.short_notes for all using (public.has_role(auth.uid(), 'admin')); exception when duplicate_object then null; end $$;

do $$ begin create policy "short_notes_visibility_select" on public.short_notes_visibility for select using (true); exception when duplicate_object then null; end $$;

do $$ begin create policy "short_notes_visibility_write_admin" on public.short_notes_visibility for all using (public.has_role(auth.uid(), 'admin')); exception when duplicate_object then null; end $$;

do $$ begin create policy "question_bank_resources_select" on public.question_bank_resources for select using ((status = 'published' and is_hidden = false) or public.has_role(auth.uid(), 'admin')); exception when duplicate_object then null; end $$;

do $$ begin create policy "question_bank_resources_write_admin" on public.question_bank_resources for all using (public.has_role(auth.uid(), 'admin')); exception when duplicate_object then null; end $$;

do $$ begin create policy "question_bank_visibility_select" on public.question_bank_visibility for select using (true); exception when duplicate_object then null; end $$;

do $$ begin create policy "question_bank_visibility_write_admin" on public.question_bank_visibility for all using (public.has_role(auth.uid(), 'admin')); exception when duplicate_object then null; end $$;

do $$ begin create policy "video_classes_select" on public.video_classes for select using ((status = 'published' and is_hidden = false) or public.has_role(auth.uid(), 'admin')); exception when duplicate_object then null; end $$;

do $$ begin create policy "video_classes_write_admin" on public.video_classes for all using (public.has_role(auth.uid(), 'admin')); exception when duplicate_object then null; end $$;

do $$ begin create policy "video_class_visibility_select" on public.video_class_visibility for select using (true); exception when duplicate_object then null; end $$;

do $$ begin create policy "video_class_visibility_write_admin" on public.video_class_visibility for all using (public.has_role(auth.uid(), 'admin')); exception when duplicate_object then null; end $$;

do $$ begin create policy "notifications_select_sent" on public.notifications for select using (status = 'sent' or public.has_role(auth.uid(), 'admin')); exception when duplicate_object then null; end $$;

do $$ begin create policy "notifications_write_admin" on public.notifications for all using (public.has_role(auth.uid(), 'admin')); exception when duplicate_object then null; end $$;

do $$ begin create policy "notification_reads_own" on public.notification_reads for all using (user_id = auth.uid()); exception when duplicate_object then null; end $$;

DO $$ BEGIN
  CREATE POLICY "user_login_events_own_insert"
    ON public.user_login_events FOR INSERT TO authenticated
    WITH CHECK (user_id = auth.uid());
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE POLICY "user_login_events_own_update"
    ON public.user_login_events FOR UPDATE TO authenticated
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE POLICY "user_login_events_select"
    ON public.user_login_events FOR SELECT TO authenticated
    USING (user_id = auth.uid() OR public.has_role(auth.uid(), 'admin'::app_role));
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE POLICY activity_events_insert_own ON public.activity_events
    FOR INSERT TO authenticated WITH CHECK (user_id IS NULL OR user_id = auth.uid());
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE POLICY activity_events_select_admin ON public.activity_events
    FOR SELECT TO authenticated USING (public.has_role(auth.uid(), 'admin'::app_role));
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE POLICY study_sessions_select_own ON public.study_sessions FOR SELECT TO authenticated
    USING (user_id = auth.uid() OR public.has_role(auth.uid(), 'admin'::app_role));
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE POLICY study_sessions_insert_own ON public.study_sessions FOR INSERT TO authenticated
    WITH CHECK (user_id = auth.uid());
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE POLICY study_sessions_update_own ON public.study_sessions FOR UPDATE TO authenticated
    USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$
BEGIN
  IF to_regclass('public.site_pages') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'site_pages' AND policyname = 'site_pages public read published'
     ) THEN
    CREATE POLICY "site_pages public read published"
  ON public.site_pages FOR SELECT
  USING (status = 'published' OR public.has_role(auth.uid(), 'admin'::public.app_role));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.site_pages') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'site_pages' AND policyname = 'site_pages admin all'
     ) THEN
    CREATE POLICY "site_pages admin all"
  ON public.site_pages FOR ALL
  USING (public.has_role(auth.uid(), 'admin'::public.app_role))
  WITH CHECK (public.has_role(auth.uid(), 'admin'::public.app_role));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.site_page_sections') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'site_page_sections' AND policyname = 'site_page_sections public read'
     ) THEN
    CREATE POLICY "site_page_sections public read"
  ON public.site_page_sections FOR SELECT
  USING (true);
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.site_page_sections') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'site_page_sections' AND policyname = 'site_page_sections admin all'
     ) THEN
    CREATE POLICY "site_page_sections admin all"
  ON public.site_page_sections FOR ALL
  USING (public.has_role(auth.uid(), 'admin'::public.app_role))
  WITH CHECK (public.has_role(auth.uid(), 'admin'::public.app_role));
  END IF;
END $$;

DO $$ BEGIN
  CREATE POLICY "users read own roles" ON public.user_roles FOR SELECT TO authenticated USING (auth.uid() = user_id);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$
BEGIN
  IF to_regclass('public.homepage_sections') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'homepage_sections' AND policyname = 'public reads visible homepage sections'
     ) THEN
    CREATE POLICY "public reads visible homepage sections" ON public.homepage_sections
  FOR SELECT TO anon, authenticated USING (visible = true);
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.homepage_sections') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'homepage_sections' AND policyname = 'admins manage homepage sections'
     ) THEN
    CREATE POLICY "admins manage homepage sections" ON public.homepage_sections
  FOR ALL TO authenticated USING (public.has_role(auth.uid(),'admin')) WITH CHECK (public.has_role(auth.uid(),'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.site_settings') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'site_settings' AND policyname = 'public reads site settings'
     ) THEN
    CREATE POLICY "public reads site settings" ON public.site_settings
  FOR SELECT TO anon, authenticated USING (true);
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.site_settings') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'site_settings' AND policyname = 'admins manage site settings'
     ) THEN
    CREATE POLICY "admins manage site settings" ON public.site_settings
  FOR ALL TO authenticated USING (public.has_role(auth.uid(),'admin')) WITH CHECK (public.has_role(auth.uid(),'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.module_visibility') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'module_visibility' AND policyname = 'public reads module visibility'
     ) THEN
    CREATE POLICY "public reads module visibility" ON public.module_visibility
  FOR SELECT TO anon, authenticated USING (true);
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.module_visibility') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'module_visibility' AND policyname = 'admins update module visibility'
     ) THEN
    CREATE POLICY "admins update module visibility" ON public.module_visibility
  FOR UPDATE TO authenticated USING (public.has_role(auth.uid(),'admin')) WITH CHECK (public.has_role(auth.uid(),'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.content_versions') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'content_versions' AND policyname = 'admins read content versions'
     ) THEN
    CREATE POLICY "admins read content versions" ON public.content_versions
  FOR SELECT TO authenticated USING (public.has_role(auth.uid(),'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.content_versions') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'content_versions' AND policyname = 'admins insert content versions'
     ) THEN
    CREATE POLICY "admins insert content versions" ON public.content_versions
  FOR INSERT TO authenticated WITH CHECK (public.has_role(auth.uid(),'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.media_assets') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'media_assets' AND policyname = 'public reads media assets'
     ) THEN
    CREATE POLICY "public reads media assets" ON public.media_assets
  FOR SELECT TO anon, authenticated USING (true);
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.media_assets') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'media_assets' AND policyname = 'admins manage media assets'
     ) THEN
    CREATE POLICY "admins manage media assets" ON public.media_assets
  FOR ALL TO authenticated USING (public.has_role(auth.uid(),'admin')) WITH CHECK (public.has_role(auth.uid(),'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.user_sessions') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'user_sessions' AND policyname = 'users read own session'
     ) THEN
    CREATE POLICY "users read own session" ON public.user_sessions FOR SELECT TO authenticated USING (auth.uid() = user_id);
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.profiles') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'profiles' AND policyname = 'profiles_select_all'
     ) THEN
    create policy "profiles_select_all" on public.profiles for select using (true);
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.profiles') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'profiles' AND policyname = 'profiles_insert_own'
     ) THEN
    create policy "profiles_insert_own" on public.profiles for insert with check (id = auth.uid());
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.profiles') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'profiles' AND policyname = 'profiles_update_own'
     ) THEN
    create policy "profiles_update_own" on public.profiles for update using (id = auth.uid());
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.avatars') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'avatars' AND policyname = 'avatars_own'
     ) THEN
    create policy "avatars_own" on public.avatars for all using (user_id = auth.uid());
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.levels') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'levels' AND policyname = 'levels_select'
     ) THEN
    create policy "levels_select" on public.levels for select using (true);
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.levels') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'levels' AND policyname = 'levels_write_admin'
     ) THEN
    create policy "levels_write_admin" on public.levels for all using (public.has_role(auth.uid(), 'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.subjects') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'subjects' AND policyname = 'subjects_select'
     ) THEN
    create policy "subjects_select" on public.subjects for select using (true);
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.subjects') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'subjects' AND policyname = 'subjects_write_admin'
     ) THEN
    create policy "subjects_write_admin" on public.subjects for all using (public.has_role(auth.uid(), 'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.chapters') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'chapters' AND policyname = 'chapters_select'
     ) THEN
    create policy "chapters_select" on public.chapters for select using (true);
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.chapters') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'chapters' AND policyname = 'chapters_write_admin'
     ) THEN
    create policy "chapters_write_admin" on public.chapters for all using (public.has_role(auth.uid(), 'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.mcqs') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'mcqs' AND policyname = 'mcqs_select_published'
     ) THEN
    create policy "mcqs_select_published" on public.mcqs for select using (status = 'published' or public.has_role(auth.uid(), 'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.mcqs') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'mcqs' AND policyname = 'mcqs_write_admin'
     ) THEN
    create policy "mcqs_write_admin" on public.mcqs for all using (public.has_role(auth.uid(), 'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.mcq_bookmarks') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'mcq_bookmarks' AND policyname = 'mcq_bookmarks_own'
     ) THEN
    create policy "mcq_bookmarks_own" on public.mcq_bookmarks for all using (user_id = auth.uid());
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.mcq_wrong_questions') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'mcq_wrong_questions' AND policyname = 'mcq_wrong_questions_own'
     ) THEN
    create policy "mcq_wrong_questions_own" on public.mcq_wrong_questions for all using (user_id = auth.uid());
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.mcq_delete_audit') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'mcq_delete_audit' AND policyname = 'mcq_delete_audit_admin'
     ) THEN
    create policy "mcq_delete_audit_admin" on public.mcq_delete_audit for all using (public.has_role(auth.uid(), 'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.quizzes') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'quizzes' AND policyname = 'quizzes_select'
     ) THEN
    create policy "quizzes_select" on public.quizzes for select using (is_public = true or public.has_role(auth.uid(), 'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.quizzes') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'quizzes' AND policyname = 'quizzes_write_admin'
     ) THEN
    create policy "quizzes_write_admin" on public.quizzes for all using (public.has_role(auth.uid(), 'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.quiz_questions') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'quiz_questions' AND policyname = 'quiz_questions_select'
     ) THEN
    create policy "quiz_questions_select" on public.quiz_questions for select using (true);
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.quiz_questions') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'quiz_questions' AND policyname = 'quiz_questions_write_admin'
     ) THEN
    create policy "quiz_questions_write_admin" on public.quiz_questions for all using (public.has_role(auth.uid(), 'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.quiz_sessions') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'quiz_sessions' AND policyname = 'quiz_sessions_own'
     ) THEN
    create policy "quiz_sessions_own" on public.quiz_sessions for all using (user_id = auth.uid() or public.has_role(auth.uid(), 'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.exam_attempts') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'exam_attempts' AND policyname = 'exam_attempts_own_select'
     ) THEN
    create policy "exam_attempts_own_select" on public.exam_attempts for select using (user_id = auth.uid() or public.has_role(auth.uid(), 'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.exam_attempts') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'exam_attempts' AND policyname = 'exam_attempts_own_insert'
     ) THEN
    create policy "exam_attempts_own_insert" on public.exam_attempts for insert with check (user_id = auth.uid());
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.attempt_answers') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'attempt_answers' AND policyname = 'attempt_answers_own'
     ) THEN
    create policy "attempt_answers_own" on public.attempt_answers for select using (
  exists (select 1 from public.exam_attempts a where a.id = attempt_id and (a.user_id = auth.uid() or public.has_role(auth.uid(), 'admin')))
);
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.attempt_answers') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'attempt_answers' AND policyname = 'attempt_answers_insert_own'
     ) THEN
    create policy "attempt_answers_insert_own" on public.attempt_answers for insert with check (
  exists (select 1 from public.exam_attempts a where a.id = attempt_id and a.user_id = auth.uid())
);
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.flash_cards') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'flash_cards' AND policyname = 'flash_cards_select'
     ) THEN
    create policy "flash_cards_select" on public.flash_cards for select using ((status = 'published' and is_hidden = false) or public.has_role(auth.uid(), 'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.flash_cards') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'flash_cards' AND policyname = 'flash_cards_write_admin'
     ) THEN
    create policy "flash_cards_write_admin" on public.flash_cards for all using (public.has_role(auth.uid(), 'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.flash_card_visibility') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'flash_card_visibility' AND policyname = 'flash_card_visibility_select'
     ) THEN
    create policy "flash_card_visibility_select" on public.flash_card_visibility for select using (true);
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.flash_card_visibility') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'flash_card_visibility' AND policyname = 'flash_card_visibility_write_admin'
     ) THEN
    create policy "flash_card_visibility_write_admin" on public.flash_card_visibility for all using (public.has_role(auth.uid(), 'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.short_notes') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'short_notes' AND policyname = 'short_notes_select'
     ) THEN
    create policy "short_notes_select" on public.short_notes for select using ((status = 'published' and is_hidden = false) or public.has_role(auth.uid(), 'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.short_notes') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'short_notes' AND policyname = 'short_notes_write_admin'
     ) THEN
    create policy "short_notes_write_admin" on public.short_notes for all using (public.has_role(auth.uid(), 'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.short_notes_visibility') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'short_notes_visibility' AND policyname = 'short_notes_visibility_select'
     ) THEN
    create policy "short_notes_visibility_select" on public.short_notes_visibility for select using (true);
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.short_notes_visibility') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'short_notes_visibility' AND policyname = 'short_notes_visibility_write_admin'
     ) THEN
    create policy "short_notes_visibility_write_admin" on public.short_notes_visibility for all using (public.has_role(auth.uid(), 'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.question_bank_resources') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'question_bank_resources' AND policyname = 'question_bank_resources_select'
     ) THEN
    create policy "question_bank_resources_select" on public.question_bank_resources for select using ((status = 'published' and is_hidden = false) or public.has_role(auth.uid(), 'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.question_bank_resources') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'question_bank_resources' AND policyname = 'question_bank_resources_write_admin'
     ) THEN
    create policy "question_bank_resources_write_admin" on public.question_bank_resources for all using (public.has_role(auth.uid(), 'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.question_bank_visibility') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'question_bank_visibility' AND policyname = 'question_bank_visibility_select'
     ) THEN
    create policy "question_bank_visibility_select" on public.question_bank_visibility for select using (true);
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.question_bank_visibility') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'question_bank_visibility' AND policyname = 'question_bank_visibility_write_admin'
     ) THEN
    create policy "question_bank_visibility_write_admin" on public.question_bank_visibility for all using (public.has_role(auth.uid(), 'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.video_classes') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'video_classes' AND policyname = 'video_classes_select'
     ) THEN
    create policy "video_classes_select" on public.video_classes for select using ((status = 'published' and is_hidden = false) or public.has_role(auth.uid(), 'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.video_classes') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'video_classes' AND policyname = 'video_classes_write_admin'
     ) THEN
    create policy "video_classes_write_admin" on public.video_classes for all using (public.has_role(auth.uid(), 'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.video_class_visibility') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'video_class_visibility' AND policyname = 'video_class_visibility_select'
     ) THEN
    create policy "video_class_visibility_select" on public.video_class_visibility for select using (true);
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.video_class_visibility') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'video_class_visibility' AND policyname = 'video_class_visibility_write_admin'
     ) THEN
    create policy "video_class_visibility_write_admin" on public.video_class_visibility for all using (public.has_role(auth.uid(), 'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.notifications') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'notifications' AND policyname = 'notifications_select_sent'
     ) THEN
    create policy "notifications_select_sent" on public.notifications for select using (status = 'sent' or public.has_role(auth.uid(), 'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.notifications') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'notifications' AND policyname = 'notifications_write_admin'
     ) THEN
    create policy "notifications_write_admin" on public.notifications for all using (public.has_role(auth.uid(), 'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.notification_reads') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'notification_reads' AND policyname = 'notification_reads_own'
     ) THEN
    create policy "notification_reads_own" on public.notification_reads for all using (user_id = auth.uid());
  END IF;
END $$;

DO $$ BEGIN
  CREATE POLICY "user_login_events_own_insert"
    ON public.user_login_events FOR INSERT TO authenticated
    WITH CHECK (user_id = auth.uid());
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE POLICY "user_login_events_own_update"
    ON public.user_login_events FOR UPDATE TO authenticated
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE POLICY "user_login_events_select"
    ON public.user_login_events FOR SELECT TO authenticated
    USING (user_id = auth.uid() OR public.has_role(auth.uid(), 'admin'::app_role));
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE POLICY activity_events_insert_own ON public.activity_events
    FOR INSERT TO authenticated WITH CHECK (user_id IS NULL OR user_id = auth.uid());
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE POLICY activity_events_select_admin ON public.activity_events
    FOR SELECT TO authenticated USING (public.has_role(auth.uid(), 'admin'::app_role));
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DROP POLICY IF EXISTS profiles_select_all ON public.profiles;

DO $$ BEGIN
  CREATE POLICY profiles_select_authenticated ON public.profiles FOR SELECT TO authenticated USING (true);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DROP POLICY IF EXISTS user_roles_insert_admin ON public.user_roles;

DO $$
BEGIN
  IF to_regclass('public.user_roles') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'user_roles' AND policyname = 'user_roles_insert_admin'
     ) THEN
    CREATE POLICY user_roles_insert_admin ON public.user_roles FOR INSERT TO authenticated
  WITH CHECK (public.has_role(auth.uid(), 'admin'::public.app_role));
  END IF;
END $$;

DROP POLICY IF EXISTS user_roles_update_admin ON public.user_roles;

DO $$
BEGIN
  IF to_regclass('public.user_roles') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'user_roles' AND policyname = 'user_roles_update_admin'
     ) THEN
    CREATE POLICY user_roles_update_admin ON public.user_roles FOR UPDATE TO authenticated
  USING (public.has_role(auth.uid(), 'admin'::public.app_role)) WITH CHECK (public.has_role(auth.uid(), 'admin'::public.app_role));
  END IF;
END $$;

DROP POLICY IF EXISTS user_roles_delete_admin ON public.user_roles;

DO $$
BEGIN
  IF to_regclass('public.user_roles') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'user_roles' AND policyname = 'user_roles_delete_admin'
     ) THEN
    CREATE POLICY user_roles_delete_admin ON public.user_roles FOR DELETE TO authenticated
  USING (public.has_role(auth.uid(), 'admin'::public.app_role));
  END IF;
END $$;

DROP POLICY IF EXISTS notifications_select_sent ON public.notifications;

DO $$ BEGIN
  CREATE POLICY notifications_select_admin ON public.notifications FOR SELECT TO authenticated
    USING (public.has_role(auth.uid(), 'admin'::public.app_role));
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE POLICY notifications_select_audience ON public.notifications FOR SELECT TO authenticated
    USING (
      status = 'sent' AND (
        audience = 'all'
        OR (audience = 'users' AND auth.uid() = ANY(audience_user_ids))
        OR (audience = 'level' AND audience_level IS NOT NULL AND EXISTS (
          SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.level = audience_level))
      )
    );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE POLICY study_sessions_select_own ON public.study_sessions FOR SELECT TO authenticated
    USING (user_id = auth.uid() OR public.has_role(auth.uid(), 'admin'::app_role));
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE POLICY study_sessions_insert_own ON public.study_sessions FOR INSERT TO authenticated
    WITH CHECK (user_id = auth.uid());
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE POLICY study_sessions_update_own ON public.study_sessions FOR UPDATE TO authenticated
    USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE POLICY "site_pages public read published"
    ON public.site_pages FOR SELECT
    USING (status = 'published' OR public.has_role(auth.uid(), 'admin'::public.app_role));
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE POLICY "site_pages admin all"
    ON public.site_pages FOR ALL
    USING (public.has_role(auth.uid(), 'admin'::public.app_role))
    WITH CHECK (public.has_role(auth.uid(), 'admin'::public.app_role));
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE POLICY "site_page_sections public read"
    ON public.site_page_sections FOR SELECT
    USING (true);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE POLICY "site_page_sections admin all"
    ON public.site_page_sections FOR ALL
    USING (public.has_role(auth.uid(), 'admin'::public.app_role))
    WITH CHECK (public.has_role(auth.uid(), 'admin'::public.app_role));
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- Profiles policies (uses has_role; safe — function reads user_roles only)
DO $$
BEGIN
  IF to_regclass('public.profiles') IS NOT NULL
     AND NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='profiles' AND policyname='profiles_self_read') THEN
    CREATE POLICY "profiles_self_read" ON public.profiles FOR SELECT TO authenticated
      USING (id = auth.uid() OR public.has_role(auth.uid(),'admin') OR public.has_role(auth.uid(),'moderator'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.profiles') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'profiles' AND policyname = 'profiles_self_update'
     ) THEN
    CREATE POLICY "profiles_self_update" ON public.profiles FOR UPDATE TO authenticated
  USING (id = auth.uid() OR public.has_role(auth.uid(),'admin'))
  WITH CHECK (id = auth.uid() OR public.has_role(auth.uid(),'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.profiles') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'profiles' AND policyname = 'profiles_admin_insert'
     ) THEN
    CREATE POLICY "profiles_admin_insert" ON public.profiles FOR INSERT TO authenticated
  WITH CHECK (id = auth.uid() OR public.has_role(auth.uid(),'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.profiles') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'profiles' AND policyname = 'profiles_admin_delete'
     ) THEN
    CREATE POLICY "profiles_admin_delete" ON public.profiles FOR DELETE TO authenticated
  USING (public.has_role(auth.uid(),'admin'));
  END IF;
END $$;

-- User roles policies
DO $$
BEGIN
  IF to_regclass('public.user_roles') IS NOT NULL
     AND NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='user_roles' AND policyname='user_roles_self_read') THEN
    CREATE POLICY "user_roles_self_read" ON public.user_roles FOR SELECT TO authenticated
      USING (user_id = auth.uid() OR public.has_role(auth.uid(),'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.user_roles') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'user_roles' AND policyname = 'user_roles_admin_write'
     ) THEN
    CREATE POLICY "user_roles_admin_write" ON public.user_roles FOR ALL TO authenticated
  USING (public.has_role(auth.uid(),'admin'))
  WITH CHECK (public.has_role(auth.uid(),'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.levels') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'levels' AND policyname = 'levels_public_read'
     ) THEN
    CREATE POLICY "levels_public_read" ON public.levels FOR SELECT USING (true);
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.levels') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'levels' AND policyname = 'levels_admin_write'
     ) THEN
    CREATE POLICY "levels_admin_write" ON public.levels FOR ALL TO authenticated
  USING (public.has_role(auth.uid(),'admin')) WITH CHECK (public.has_role(auth.uid(),'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.subjects') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'subjects' AND policyname = 'subjects_public_read'
     ) THEN
    CREATE POLICY "subjects_public_read" ON public.subjects FOR SELECT USING (true);
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.subjects') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'subjects' AND policyname = 'subjects_admin_write'
     ) THEN
    CREATE POLICY "subjects_admin_write" ON public.subjects FOR ALL TO authenticated
  USING (public.has_role(auth.uid(),'admin')) WITH CHECK (public.has_role(auth.uid(),'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.chapters') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'chapters' AND policyname = 'chapters_public_read'
     ) THEN
    CREATE POLICY "chapters_public_read" ON public.chapters FOR SELECT USING (true);
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.chapters') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'chapters' AND policyname = 'chapters_admin_write'
     ) THEN
    CREATE POLICY "chapters_admin_write" ON public.chapters FOR ALL TO authenticated
  USING (public.has_role(auth.uid(),'admin')) WITH CHECK (public.has_role(auth.uid(),'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.mcqs') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'mcqs' AND policyname = 'mcqs_published_read'
     ) THEN
    CREATE POLICY "mcqs_published_read" ON public.mcqs FOR SELECT USING (status = 'published' OR public.has_role(auth.uid(),'admin') OR public.has_role(auth.uid(),'moderator'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.mcqs') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'mcqs' AND policyname = 'mcqs_admin_write'
     ) THEN
    CREATE POLICY "mcqs_admin_write" ON public.mcqs FOR ALL TO authenticated
  USING (public.has_role(auth.uid(),'admin')) WITH CHECK (public.has_role(auth.uid(),'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.mcq_delete_audit') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'mcq_delete_audit' AND policyname = 'audit_admin_only'
     ) THEN
    CREATE POLICY "audit_admin_only" ON public.mcq_delete_audit FOR ALL TO authenticated
  USING (public.has_role(auth.uid(),'admin')) WITH CHECK (public.has_role(auth.uid(),'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.quizzes') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'quizzes' AND policyname = 'quizzes_published_read'
     ) THEN
    CREATE POLICY "quizzes_published_read" ON public.quizzes FOR SELECT
  USING (status = 'published' OR public.has_role(auth.uid(),'admin') OR public.has_role(auth.uid(),'moderator'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.quizzes') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'quizzes' AND policyname = 'quizzes_admin_write'
     ) THEN
    CREATE POLICY "quizzes_admin_write" ON public.quizzes FOR ALL TO authenticated
  USING (public.has_role(auth.uid(),'admin')) WITH CHECK (public.has_role(auth.uid(),'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.quiz_questions') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'quiz_questions' AND policyname = 'qq_public_read'
     ) THEN
    CREATE POLICY "qq_public_read" ON public.quiz_questions FOR SELECT USING (true);
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.quiz_questions') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'quiz_questions' AND policyname = 'qq_admin_write'
     ) THEN
    CREATE POLICY "qq_admin_write" ON public.quiz_questions FOR ALL TO authenticated
  USING (public.has_role(auth.uid(),'admin')) WITH CHECK (public.has_role(auth.uid(),'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.exam_attempts') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'exam_attempts' AND policyname = 'attempts_self_read'
     ) THEN
    CREATE POLICY "attempts_self_read" ON public.exam_attempts FOR SELECT TO authenticated
  USING (user_id = auth.uid() OR public.has_role(auth.uid(),'admin') OR public.has_role(auth.uid(),'moderator'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.exam_attempts') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'exam_attempts' AND policyname = 'attempts_self_insert'
     ) THEN
    CREATE POLICY "attempts_self_insert" ON public.exam_attempts FOR INSERT TO authenticated
  WITH CHECK (user_id = auth.uid());
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.exam_attempts') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'exam_attempts' AND policyname = 'attempts_self_update'
     ) THEN
    CREATE POLICY "attempts_self_update" ON public.exam_attempts FOR UPDATE TO authenticated
  USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.exam_attempts') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'exam_attempts' AND policyname = 'attempts_self_delete'
     ) THEN
    CREATE POLICY "attempts_self_delete" ON public.exam_attempts FOR DELETE TO authenticated
  USING (user_id = auth.uid() OR public.has_role(auth.uid(),'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.attempt_answers') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'attempt_answers' AND policyname = 'aa_own_read'
     ) THEN
    CREATE POLICY "aa_own_read" ON public.attempt_answers FOR SELECT TO authenticated
  USING (EXISTS (SELECT 1 FROM public.exam_attempts e WHERE e.id = attempt_id AND (e.user_id = auth.uid() OR public.has_role(auth.uid(),'admin') OR public.has_role(auth.uid(),'moderator'))));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.attempt_answers') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'attempt_answers' AND policyname = 'aa_own_write'
     ) THEN
    CREATE POLICY "aa_own_write" ON public.attempt_answers FOR INSERT TO authenticated
  WITH CHECK (EXISTS (SELECT 1 FROM public.exam_attempts e WHERE e.id = attempt_id AND e.user_id = auth.uid()));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.mcq_bookmarks') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'mcq_bookmarks' AND policyname = 'bm_self'
     ) THEN
    CREATE POLICY "bm_self" ON public.mcq_bookmarks FOR ALL TO authenticated
  USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.mcq_wrong_questions') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'mcq_wrong_questions' AND policyname = 'wq_self'
     ) THEN
    CREATE POLICY "wq_self" ON public.mcq_wrong_questions FOR ALL TO authenticated
  USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.flash_cards') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'flash_cards' AND policyname = 'fc_published_read'
     ) THEN
    CREATE POLICY "fc_published_read" ON public.flash_cards FOR SELECT
  USING ((status = 'published' AND NOT is_hidden) OR public.has_role(auth.uid(),'admin') OR public.has_role(auth.uid(),'moderator'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.flash_cards') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'flash_cards' AND policyname = 'fc_admin_write'
     ) THEN
    CREATE POLICY "fc_admin_write" ON public.flash_cards FOR ALL TO authenticated
  USING (public.has_role(auth.uid(),'admin')) WITH CHECK (public.has_role(auth.uid(),'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.short_notes') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'short_notes' AND policyname = 'sn_published_read'
     ) THEN
    CREATE POLICY "sn_published_read" ON public.short_notes FOR SELECT
  USING ((status = 'published' AND NOT is_hidden) OR public.has_role(auth.uid(),'admin') OR public.has_role(auth.uid(),'moderator'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.short_notes') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'short_notes' AND policyname = 'sn_admin_write'
     ) THEN
    CREATE POLICY "sn_admin_write" ON public.short_notes FOR ALL TO authenticated
  USING (public.has_role(auth.uid(),'admin')) WITH CHECK (public.has_role(auth.uid(),'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.question_bank_resources') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'question_bank_resources' AND policyname = 'qb_published_read'
     ) THEN
    CREATE POLICY "qb_published_read" ON public.question_bank_resources FOR SELECT
  USING ((status = 'published' AND NOT is_hidden) OR public.has_role(auth.uid(),'admin') OR public.has_role(auth.uid(),'moderator'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.question_bank_resources') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'question_bank_resources' AND policyname = 'qb_admin_write'
     ) THEN
    CREATE POLICY "qb_admin_write" ON public.question_bank_resources FOR ALL TO authenticated
  USING (public.has_role(auth.uid(),'admin')) WITH CHECK (public.has_role(auth.uid(),'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.video_classes') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'video_classes' AND policyname = 'vc_published_read'
     ) THEN
    CREATE POLICY "vc_published_read" ON public.video_classes FOR SELECT
  USING ((status = 'published' AND NOT is_hidden) OR public.has_role(auth.uid(),'admin') OR public.has_role(auth.uid(),'moderator'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.video_classes') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'video_classes' AND policyname = 'vc_admin_write'
     ) THEN
    CREATE POLICY "vc_admin_write" ON public.video_classes FOR ALL TO authenticated
  USING (public.has_role(auth.uid(),'admin')) WITH CHECK (public.has_role(auth.uid(),'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.module_visibility') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'module_visibility' AND policyname = 'mv_public_read'
     ) THEN
    CREATE POLICY "mv_public_read" ON public.module_visibility FOR SELECT USING (true);
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.module_visibility') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'module_visibility' AND policyname = 'mv_admin_write'
     ) THEN
    CREATE POLICY "mv_admin_write" ON public.module_visibility FOR ALL TO authenticated
  USING (public.has_role(auth.uid(),'admin')) WITH CHECK (public.has_role(auth.uid(),'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.flash_card_visibility') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'flash_card_visibility' AND policyname = 'fcv_public_read'
     ) THEN
    CREATE POLICY "fcv_public_read" ON public.flash_card_visibility FOR SELECT USING (true);
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.flash_card_visibility') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'flash_card_visibility' AND policyname = 'fcv_admin_write'
     ) THEN
    CREATE POLICY "fcv_admin_write" ON public.flash_card_visibility FOR ALL TO authenticated
  USING (public.has_role(auth.uid(),'admin')) WITH CHECK (public.has_role(auth.uid(),'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.short_notes_visibility') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'short_notes_visibility' AND policyname = 'snv_public_read'
     ) THEN
    CREATE POLICY "snv_public_read" ON public.short_notes_visibility FOR SELECT USING (true);
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.short_notes_visibility') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'short_notes_visibility' AND policyname = 'snv_admin_write'
     ) THEN
    CREATE POLICY "snv_admin_write" ON public.short_notes_visibility FOR ALL TO authenticated
  USING (public.has_role(auth.uid(),'admin')) WITH CHECK (public.has_role(auth.uid(),'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.question_bank_visibility') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'question_bank_visibility' AND policyname = 'qbv_public_read'
     ) THEN
    CREATE POLICY "qbv_public_read" ON public.question_bank_visibility FOR SELECT USING (true);
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.question_bank_visibility') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'question_bank_visibility' AND policyname = 'qbv_admin_write'
     ) THEN
    CREATE POLICY "qbv_admin_write" ON public.question_bank_visibility FOR ALL TO authenticated
  USING (public.has_role(auth.uid(),'admin')) WITH CHECK (public.has_role(auth.uid(),'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.video_class_visibility') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'video_class_visibility' AND policyname = 'vcv_public_read'
     ) THEN
    CREATE POLICY "vcv_public_read" ON public.video_class_visibility FOR SELECT USING (true);
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.video_class_visibility') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'video_class_visibility' AND policyname = 'vcv_admin_write'
     ) THEN
    CREATE POLICY "vcv_admin_write" ON public.video_class_visibility FOR ALL TO authenticated
  USING (public.has_role(auth.uid(),'admin')) WITH CHECK (public.has_role(auth.uid(),'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.notifications') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'notifications' AND policyname = 'notif_sent_read'
     ) THEN
    CREATE POLICY "notif_sent_read" ON public.notifications FOR SELECT
  USING (status = 'sent' OR public.has_role(auth.uid(),'admin') OR public.has_role(auth.uid(),'moderator'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.notifications') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'notifications' AND policyname = 'notif_admin_write'
     ) THEN
    CREATE POLICY "notif_admin_write" ON public.notifications FOR ALL TO authenticated
  USING (public.has_role(auth.uid(),'admin')) WITH CHECK (public.has_role(auth.uid(),'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.notification_reads') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'notification_reads' AND policyname = 'nr_self'
     ) THEN
    CREATE POLICY "nr_self" ON public.notification_reads FOR ALL TO authenticated
  USING (user_id = auth.uid() OR public.has_role(auth.uid(),'admin'))
  WITH CHECK (user_id = auth.uid());
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.activity_events') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'activity_events' AND policyname = 'ae_self_insert'
     ) THEN
    CREATE POLICY "ae_self_insert" ON public.activity_events FOR INSERT TO authenticated
  WITH CHECK (user_id = auth.uid() OR user_id IS NULL);
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.activity_events') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'activity_events' AND policyname = 'ae_admin_read'
     ) THEN
    CREATE POLICY "ae_admin_read" ON public.activity_events FOR SELECT TO authenticated
  USING (public.has_role(auth.uid(),'admin') OR public.has_role(auth.uid(),'moderator') OR user_id = auth.uid());
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.user_login_events') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'user_login_events' AND policyname = 'ule_self_rw'
     ) THEN
    CREATE POLICY "ule_self_rw" ON public.user_login_events FOR ALL TO authenticated
  USING (user_id = auth.uid() OR public.has_role(auth.uid(),'admin') OR public.has_role(auth.uid(),'moderator'))
  WITH CHECK (user_id = auth.uid());
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.user_sessions') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'user_sessions' AND policyname = 'us_self'
     ) THEN
    CREATE POLICY "us_self" ON public.user_sessions FOR ALL TO authenticated
  USING (user_id = auth.uid() OR public.has_role(auth.uid(),'admin'))
  WITH CHECK (user_id = auth.uid());
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.study_sessions') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'study_sessions' AND policyname = 'ss_self'
     ) THEN
    CREATE POLICY "ss_self" ON public.study_sessions FOR ALL TO authenticated
  USING (user_id = auth.uid() OR public.has_role(auth.uid(),'admin'))
  WITH CHECK (user_id = auth.uid());
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.site_settings') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'site_settings' AND policyname = 'ssettings_public_read'
     ) THEN
    CREATE POLICY "ssettings_public_read" ON public.site_settings FOR SELECT USING (true);
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.site_settings') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'site_settings' AND policyname = 'ssettings_admin_write'
     ) THEN
    CREATE POLICY "ssettings_admin_write" ON public.site_settings FOR ALL TO authenticated
  USING (public.has_role(auth.uid(),'admin')) WITH CHECK (public.has_role(auth.uid(),'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.site_pages') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'site_pages' AND policyname = 'spages_public_read'
     ) THEN
    CREATE POLICY "spages_public_read" ON public.site_pages FOR SELECT USING (true);
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.site_pages') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'site_pages' AND policyname = 'spages_admin_write'
     ) THEN
    CREATE POLICY "spages_admin_write" ON public.site_pages FOR ALL TO authenticated
  USING (public.has_role(auth.uid(),'admin')) WITH CHECK (public.has_role(auth.uid(),'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.site_page_sections') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'site_page_sections' AND policyname = 'sps_public_read'
     ) THEN
    CREATE POLICY "sps_public_read" ON public.site_page_sections FOR SELECT USING (true);
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.site_page_sections') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'site_page_sections' AND policyname = 'sps_admin_write'
     ) THEN
    CREATE POLICY "sps_admin_write" ON public.site_page_sections FOR ALL TO authenticated
  USING (public.has_role(auth.uid(),'admin')) WITH CHECK (public.has_role(auth.uid(),'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.homepage_sections') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'homepage_sections' AND policyname = 'hs_public_read'
     ) THEN
    CREATE POLICY "hs_public_read" ON public.homepage_sections FOR SELECT USING (true);
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.homepage_sections') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'homepage_sections' AND policyname = 'hs_admin_write'
     ) THEN
    CREATE POLICY "hs_admin_write" ON public.homepage_sections FOR ALL TO authenticated
  USING (public.has_role(auth.uid(),'admin')) WITH CHECK (public.has_role(auth.uid(),'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.media_assets') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'media_assets' AND policyname = 'ma_public_read'
     ) THEN
    CREATE POLICY "ma_public_read" ON public.media_assets FOR SELECT USING (true);
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.media_assets') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'media_assets' AND policyname = 'ma_admin_write'
     ) THEN
    CREATE POLICY "ma_admin_write" ON public.media_assets FOR ALL TO authenticated
  USING (public.has_role(auth.uid(),'admin')) WITH CHECK (public.has_role(auth.uid(),'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.content_versions') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'content_versions' AND policyname = 'cv_admin'
     ) THEN
    CREATE POLICY "cv_admin" ON public.content_versions FOR ALL TO authenticated
  USING (public.has_role(auth.uid(),'admin')) WITH CHECK (public.has_role(auth.uid(),'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.avatars') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'avatars' AND policyname = 'av_public_read'
     ) THEN
    CREATE POLICY "av_public_read" ON public.avatars FOR SELECT USING (true);
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.avatars') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'avatars' AND policyname = 'av_admin_write'
     ) THEN
    CREATE POLICY "av_admin_write" ON public.avatars FOR ALL TO authenticated
  USING (public.has_role(auth.uid(),'admin')) WITH CHECK (public.has_role(auth.uid(),'admin'));
  END IF;
END $$;

DO $$ BEGIN
  CREATE POLICY "users read own roles" ON public.user_roles FOR SELECT TO authenticated USING (auth.uid() = user_id);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$
BEGIN
  IF to_regclass('public.homepage_sections') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'homepage_sections' AND policyname = 'public reads visible homepage sections'
     ) THEN
    CREATE POLICY "public reads visible homepage sections" ON public.homepage_sections
  FOR SELECT TO anon, authenticated USING (visible = true);
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.homepage_sections') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'homepage_sections' AND policyname = 'admins manage homepage sections'
     ) THEN
    CREATE POLICY "admins manage homepage sections" ON public.homepage_sections
  FOR ALL TO authenticated USING (public.has_role(auth.uid(),'admin')) WITH CHECK (public.has_role(auth.uid(),'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.site_settings') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'site_settings' AND policyname = 'public reads site settings'
     ) THEN
    CREATE POLICY "public reads site settings" ON public.site_settings
  FOR SELECT TO anon, authenticated USING (true);
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.site_settings') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'site_settings' AND policyname = 'admins manage site settings'
     ) THEN
    CREATE POLICY "admins manage site settings" ON public.site_settings
  FOR ALL TO authenticated USING (public.has_role(auth.uid(),'admin')) WITH CHECK (public.has_role(auth.uid(),'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.module_visibility') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'module_visibility' AND policyname = 'public reads module visibility'
     ) THEN
    CREATE POLICY "public reads module visibility" ON public.module_visibility
  FOR SELECT TO anon, authenticated USING (true);
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.module_visibility') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'module_visibility' AND policyname = 'admins update module visibility'
     ) THEN
    CREATE POLICY "admins update module visibility" ON public.module_visibility
  FOR UPDATE TO authenticated USING (public.has_role(auth.uid(),'admin')) WITH CHECK (public.has_role(auth.uid(),'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.content_versions') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'content_versions' AND policyname = 'admins read content versions'
     ) THEN
    CREATE POLICY "admins read content versions" ON public.content_versions
  FOR SELECT TO authenticated USING (public.has_role(auth.uid(),'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.content_versions') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'content_versions' AND policyname = 'admins insert content versions'
     ) THEN
    CREATE POLICY "admins insert content versions" ON public.content_versions
  FOR INSERT TO authenticated WITH CHECK (public.has_role(auth.uid(),'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.media_assets') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'media_assets' AND policyname = 'public reads media assets'
     ) THEN
    CREATE POLICY "public reads media assets" ON public.media_assets
  FOR SELECT TO anon, authenticated USING (true);
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.media_assets') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'media_assets' AND policyname = 'admins manage media assets'
     ) THEN
    CREATE POLICY "admins manage media assets" ON public.media_assets
  FOR ALL TO authenticated USING (public.has_role(auth.uid(),'admin')) WITH CHECK (public.has_role(auth.uid(),'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.user_sessions') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'user_sessions' AND policyname = 'users read own session'
     ) THEN
    CREATE POLICY "users read own session" ON public.user_sessions FOR SELECT TO authenticated USING (auth.uid() = user_id);
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.profiles') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'profiles' AND policyname = 'profiles_select_all'
     ) THEN
    create policy "profiles_select_all" on public.profiles for select using (true);
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.profiles') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'profiles' AND policyname = 'profiles_insert_own'
     ) THEN
    create policy "profiles_insert_own" on public.profiles for insert with check (id = auth.uid());
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.profiles') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'profiles' AND policyname = 'profiles_update_own'
     ) THEN
    create policy "profiles_update_own" on public.profiles for update using (id = auth.uid());
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.avatars') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'avatars' AND policyname = 'avatars_own'
     ) THEN
    create policy "avatars_own" on public.avatars for all using (user_id = auth.uid());
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.levels') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'levels' AND policyname = 'levels_select'
     ) THEN
    create policy "levels_select" on public.levels for select using (true);
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.levels') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'levels' AND policyname = 'levels_write_admin'
     ) THEN
    create policy "levels_write_admin" on public.levels for all using (public.has_role(auth.uid(), 'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.subjects') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'subjects' AND policyname = 'subjects_select'
     ) THEN
    create policy "subjects_select" on public.subjects for select using (true);
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.subjects') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'subjects' AND policyname = 'subjects_write_admin'
     ) THEN
    create policy "subjects_write_admin" on public.subjects for all using (public.has_role(auth.uid(), 'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.chapters') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'chapters' AND policyname = 'chapters_select'
     ) THEN
    create policy "chapters_select" on public.chapters for select using (true);
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.chapters') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'chapters' AND policyname = 'chapters_write_admin'
     ) THEN
    create policy "chapters_write_admin" on public.chapters for all using (public.has_role(auth.uid(), 'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.mcqs') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'mcqs' AND policyname = 'mcqs_select_published'
     ) THEN
    create policy "mcqs_select_published" on public.mcqs for select using (status = 'published' or public.has_role(auth.uid(), 'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.mcqs') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'mcqs' AND policyname = 'mcqs_write_admin'
     ) THEN
    create policy "mcqs_write_admin" on public.mcqs for all using (public.has_role(auth.uid(), 'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.mcq_bookmarks') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'mcq_bookmarks' AND policyname = 'mcq_bookmarks_own'
     ) THEN
    create policy "mcq_bookmarks_own" on public.mcq_bookmarks for all using (user_id = auth.uid());
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.mcq_wrong_questions') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'mcq_wrong_questions' AND policyname = 'mcq_wrong_questions_own'
     ) THEN
    create policy "mcq_wrong_questions_own" on public.mcq_wrong_questions for all using (user_id = auth.uid());
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.mcq_delete_audit') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'mcq_delete_audit' AND policyname = 'mcq_delete_audit_admin'
     ) THEN
    create policy "mcq_delete_audit_admin" on public.mcq_delete_audit for all using (public.has_role(auth.uid(), 'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.quizzes') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'quizzes' AND policyname = 'quizzes_select'
     ) THEN
    create policy "quizzes_select" on public.quizzes for select using (is_public = true or public.has_role(auth.uid(), 'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.quizzes') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'quizzes' AND policyname = 'quizzes_write_admin'
     ) THEN
    create policy "quizzes_write_admin" on public.quizzes for all using (public.has_role(auth.uid(), 'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.quiz_questions') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'quiz_questions' AND policyname = 'quiz_questions_select'
     ) THEN
    create policy "quiz_questions_select" on public.quiz_questions for select using (true);
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.quiz_questions') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'quiz_questions' AND policyname = 'quiz_questions_write_admin'
     ) THEN
    create policy "quiz_questions_write_admin" on public.quiz_questions for all using (public.has_role(auth.uid(), 'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.quiz_sessions') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'quiz_sessions' AND policyname = 'quiz_sessions_own'
     ) THEN
    create policy "quiz_sessions_own" on public.quiz_sessions for all using (user_id = auth.uid() or public.has_role(auth.uid(), 'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.exam_attempts') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'exam_attempts' AND policyname = 'exam_attempts_own_select'
     ) THEN
    create policy "exam_attempts_own_select" on public.exam_attempts for select using (user_id = auth.uid() or public.has_role(auth.uid(), 'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.exam_attempts') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'exam_attempts' AND policyname = 'exam_attempts_own_insert'
     ) THEN
    create policy "exam_attempts_own_insert" on public.exam_attempts for insert with check (user_id = auth.uid());
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.attempt_answers') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'attempt_answers' AND policyname = 'attempt_answers_own'
     ) THEN
    create policy "attempt_answers_own" on public.attempt_answers for select using (
  exists (select 1 from public.exam_attempts a where a.id = attempt_id and (a.user_id = auth.uid() or public.has_role(auth.uid(), 'admin')))
);
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.attempt_answers') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'attempt_answers' AND policyname = 'attempt_answers_insert_own'
     ) THEN
    create policy "attempt_answers_insert_own" on public.attempt_answers for insert with check (
  exists (select 1 from public.exam_attempts a where a.id = attempt_id and a.user_id = auth.uid())
);
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.flash_cards') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'flash_cards' AND policyname = 'flash_cards_select'
     ) THEN
    create policy "flash_cards_select" on public.flash_cards for select using ((status = 'published' and is_hidden = false) or public.has_role(auth.uid(), 'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.flash_cards') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'flash_cards' AND policyname = 'flash_cards_write_admin'
     ) THEN
    create policy "flash_cards_write_admin" on public.flash_cards for all using (public.has_role(auth.uid(), 'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.flash_card_visibility') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'flash_card_visibility' AND policyname = 'flash_card_visibility_select'
     ) THEN
    create policy "flash_card_visibility_select" on public.flash_card_visibility for select using (true);
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.flash_card_visibility') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'flash_card_visibility' AND policyname = 'flash_card_visibility_write_admin'
     ) THEN
    create policy "flash_card_visibility_write_admin" on public.flash_card_visibility for all using (public.has_role(auth.uid(), 'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.short_notes') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'short_notes' AND policyname = 'short_notes_select'
     ) THEN
    create policy "short_notes_select" on public.short_notes for select using ((status = 'published' and is_hidden = false) or public.has_role(auth.uid(), 'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.short_notes') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'short_notes' AND policyname = 'short_notes_write_admin'
     ) THEN
    create policy "short_notes_write_admin" on public.short_notes for all using (public.has_role(auth.uid(), 'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.short_notes_visibility') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'short_notes_visibility' AND policyname = 'short_notes_visibility_select'
     ) THEN
    create policy "short_notes_visibility_select" on public.short_notes_visibility for select using (true);
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.short_notes_visibility') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'short_notes_visibility' AND policyname = 'short_notes_visibility_write_admin'
     ) THEN
    create policy "short_notes_visibility_write_admin" on public.short_notes_visibility for all using (public.has_role(auth.uid(), 'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.question_bank_resources') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'question_bank_resources' AND policyname = 'question_bank_resources_select'
     ) THEN
    create policy "question_bank_resources_select" on public.question_bank_resources for select using ((status = 'published' and is_hidden = false) or public.has_role(auth.uid(), 'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.question_bank_resources') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'question_bank_resources' AND policyname = 'question_bank_resources_write_admin'
     ) THEN
    create policy "question_bank_resources_write_admin" on public.question_bank_resources for all using (public.has_role(auth.uid(), 'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.question_bank_visibility') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'question_bank_visibility' AND policyname = 'question_bank_visibility_select'
     ) THEN
    create policy "question_bank_visibility_select" on public.question_bank_visibility for select using (true);
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.question_bank_visibility') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'question_bank_visibility' AND policyname = 'question_bank_visibility_write_admin'
     ) THEN
    create policy "question_bank_visibility_write_admin" on public.question_bank_visibility for all using (public.has_role(auth.uid(), 'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.video_classes') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'video_classes' AND policyname = 'video_classes_select'
     ) THEN
    create policy "video_classes_select" on public.video_classes for select using ((status = 'published' and is_hidden = false) or public.has_role(auth.uid(), 'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.video_classes') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'video_classes' AND policyname = 'video_classes_write_admin'
     ) THEN
    create policy "video_classes_write_admin" on public.video_classes for all using (public.has_role(auth.uid(), 'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.video_class_visibility') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'video_class_visibility' AND policyname = 'video_class_visibility_select'
     ) THEN
    create policy "video_class_visibility_select" on public.video_class_visibility for select using (true);
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.video_class_visibility') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'video_class_visibility' AND policyname = 'video_class_visibility_write_admin'
     ) THEN
    create policy "video_class_visibility_write_admin" on public.video_class_visibility for all using (public.has_role(auth.uid(), 'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.notifications') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'notifications' AND policyname = 'notifications_select_sent'
     ) THEN
    create policy "notifications_select_sent" on public.notifications for select using (status = 'sent' or public.has_role(auth.uid(), 'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.notifications') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'notifications' AND policyname = 'notifications_write_admin'
     ) THEN
    create policy "notifications_write_admin" on public.notifications for all using (public.has_role(auth.uid(), 'admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.notification_reads') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'notification_reads' AND policyname = 'notification_reads_own'
     ) THEN
    create policy "notification_reads_own" on public.notification_reads for all using (user_id = auth.uid());
  END IF;
END $$;

DO $$ BEGIN
  CREATE POLICY "user_login_events_own_insert"
    ON public.user_login_events FOR INSERT TO authenticated
    WITH CHECK (user_id = auth.uid());
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE POLICY "user_login_events_own_update"
    ON public.user_login_events FOR UPDATE TO authenticated
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE POLICY "user_login_events_select"
    ON public.user_login_events FOR SELECT TO authenticated
    USING (user_id = auth.uid() OR public.has_role(auth.uid(), 'admin'::app_role));
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE POLICY activity_events_insert_own ON public.activity_events
    FOR INSERT TO authenticated WITH CHECK (user_id IS NULL OR user_id = auth.uid());
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE POLICY activity_events_select_admin ON public.activity_events
    FOR SELECT TO authenticated USING (public.has_role(auth.uid(), 'admin'::app_role));
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DROP POLICY IF EXISTS profiles_select_all ON public.profiles;

DO $$ BEGIN
  CREATE POLICY profiles_select_authenticated ON public.profiles FOR SELECT TO authenticated USING (true);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DROP POLICY IF EXISTS user_roles_insert_admin ON public.user_roles;

DO $$
BEGIN
  IF to_regclass('public.user_roles') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'user_roles' AND policyname = 'user_roles_insert_admin'
     ) THEN
    CREATE POLICY user_roles_insert_admin ON public.user_roles FOR INSERT TO authenticated
  WITH CHECK (public.has_role(auth.uid(), 'admin'::public.app_role));
  END IF;
END $$;

DROP POLICY IF EXISTS user_roles_update_admin ON public.user_roles;

DO $$
BEGIN
  IF to_regclass('public.user_roles') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'user_roles' AND policyname = 'user_roles_update_admin'
     ) THEN
    CREATE POLICY user_roles_update_admin ON public.user_roles FOR UPDATE TO authenticated
  USING (public.has_role(auth.uid(), 'admin'::public.app_role)) WITH CHECK (public.has_role(auth.uid(), 'admin'::public.app_role));
  END IF;
END $$;

DROP POLICY IF EXISTS user_roles_delete_admin ON public.user_roles;

DO $$
BEGIN
  IF to_regclass('public.user_roles') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'user_roles' AND policyname = 'user_roles_delete_admin'
     ) THEN
    CREATE POLICY user_roles_delete_admin ON public.user_roles FOR DELETE TO authenticated
  USING (public.has_role(auth.uid(), 'admin'::public.app_role));
  END IF;
END $$;

DROP POLICY IF EXISTS notifications_select_sent ON public.notifications;

DO $$ BEGIN
  CREATE POLICY notifications_select_admin ON public.notifications FOR SELECT TO authenticated
    USING (public.has_role(auth.uid(), 'admin'::public.app_role));
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE POLICY notifications_select_audience ON public.notifications FOR SELECT TO authenticated
    USING (
      status = 'sent' AND (
        audience = 'all'
        OR (audience = 'users' AND auth.uid() = ANY(audience_user_ids))
        OR (audience = 'level' AND audience_level IS NOT NULL AND EXISTS (
          SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.level = audience_level))
      )
    );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE POLICY study_sessions_select_own
    ON public.study_sessions FOR SELECT TO authenticated
    USING (user_id = auth.uid() OR public.has_role(auth.uid(), 'admin'::app_role));
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE POLICY study_sessions_insert_own
    ON public.study_sessions FOR INSERT TO authenticated
    WITH CHECK (user_id = auth.uid());
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE POLICY study_sessions_update_own
    ON public.study_sessions FOR UPDATE TO authenticated
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE POLICY "site_pages public read published"
    ON public.site_pages FOR SELECT
    USING (status = 'published' OR public.has_role(auth.uid(), 'admin'::public.app_role));
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE POLICY "site_pages admin all"
    ON public.site_pages FOR ALL
    USING (public.has_role(auth.uid(), 'admin'::public.app_role))
    WITH CHECK (public.has_role(auth.uid(), 'admin'::public.app_role));
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE POLICY "site_page_sections public read"
    ON public.site_page_sections FOR SELECT
    USING (true);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE POLICY "site_page_sections admin all"
    ON public.site_page_sections FOR ALL
    USING (public.has_role(auth.uid(), 'admin'::public.app_role))
    WITH CHECK (public.has_role(auth.uid(), 'admin'::public.app_role));
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DROP POLICY IF EXISTS "Admins read role_permissions" ON public.role_permissions;

DO $$
BEGIN
  IF to_regclass('public.role_permissions') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'role_permissions' AND policyname = 'Admins read role_permissions'
     ) THEN
    CREATE POLICY "Admins read role_permissions" ON public.role_permissions
  FOR SELECT TO authenticated
  USING (public.has_role(auth.uid(), 'admin'::public.app_role)
      OR public.has_role(auth.uid(), 'super_admin'::public.app_role));
  END IF;
END $$;

DROP POLICY IF EXISTS "Admins write role_permissions" ON public.role_permissions;

DO $$
BEGIN
  IF to_regclass('public.role_permissions') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'role_permissions' AND policyname = 'Admins write role_permissions'
     ) THEN
    CREATE POLICY "Admins write role_permissions" ON public.role_permissions
  FOR ALL TO authenticated
  USING (public.has_role(auth.uid(), 'admin'::public.app_role)
      OR public.has_role(auth.uid(), 'super_admin'::public.app_role))
  WITH CHECK (public.has_role(auth.uid(), 'admin'::public.app_role)
           OR public.has_role(auth.uid(), 'super_admin'::public.app_role));
  END IF;
END $$;

DROP POLICY IF EXISTS "Admins read admin_action_log" ON public.admin_action_log;

DO $$
BEGIN
  IF to_regclass('public.admin_action_log') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'admin_action_log' AND policyname = 'Admins read admin_action_log'
     ) THEN
    CREATE POLICY "Admins read admin_action_log" ON public.admin_action_log
  FOR SELECT TO authenticated
  USING (public.has_role(auth.uid(), 'admin'::public.app_role)
      OR public.has_role(auth.uid(), 'super_admin'::public.app_role));
  END IF;
END $$;

DROP POLICY IF EXISTS "Users insert own admin_action_log" ON public.admin_action_log;

DO $$
BEGIN
  IF to_regclass('public.admin_action_log') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'admin_action_log' AND policyname = 'Users insert own admin_action_log'
     ) THEN
    CREATE POLICY "Users insert own admin_action_log" ON public.admin_action_log
  FOR INSERT TO authenticated
  WITH CHECK (user_id = auth.uid());
  END IF;
END $$;

DO $$ BEGIN
  CREATE POLICY "user_roles self read" ON public.user_roles FOR SELECT TO authenticated USING (user_id = auth.uid());
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$
BEGIN
  IF to_regclass('public.editor_pages') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'editor_pages' AND policyname = 'editor_pages admin read'
     ) THEN
    CREATE POLICY "editor_pages admin read"  ON public.editor_pages FOR SELECT TO authenticated USING (public.is_editor_admin());
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.editor_pages') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'editor_pages' AND policyname = 'editor_pages admin write'
     ) THEN
    CREATE POLICY "editor_pages admin write" ON public.editor_pages FOR ALL    TO authenticated USING (public.is_editor_admin()) WITH CHECK (public.is_editor_admin());
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.editor_snapshots') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'editor_snapshots' AND policyname = 'editor_snapshots admin read'
     ) THEN
    CREATE POLICY "editor_snapshots admin read"   ON public.editor_snapshots FOR SELECT TO authenticated USING (public.is_editor_admin());
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.editor_snapshots') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'editor_snapshots' AND policyname = 'editor_snapshots admin insert'
     ) THEN
    CREATE POLICY "editor_snapshots admin insert" ON public.editor_snapshots FOR INSERT TO authenticated WITH CHECK (public.is_editor_admin());
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.editor_actions_log') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'editor_actions_log' AND policyname = 'editor_actions admin read'
     ) THEN
    CREATE POLICY "editor_actions admin read"   ON public.editor_actions_log FOR SELECT TO authenticated USING (public.is_editor_admin());
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.editor_actions_log') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'editor_actions_log' AND policyname = 'editor_actions admin insert'
     ) THEN
    CREATE POLICY "editor_actions admin insert" ON public.editor_actions_log FOR INSERT TO authenticated WITH CHECK (public.is_editor_admin());
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.editor_published_pages') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'editor_published_pages' AND policyname = 'published pages public read'
     ) THEN
    CREATE POLICY "published pages public read" ON public.editor_published_pages FOR SELECT USING (true);
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.editor_published_pages') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'editor_published_pages' AND policyname = 'published pages admin write'
     ) THEN
    CREATE POLICY "published pages admin write" ON public.editor_published_pages FOR ALL TO authenticated USING (public.is_editor_admin()) WITH CHECK (public.is_editor_admin());
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.module_visibility') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'module_visibility' AND policyname = 'module_visibility public read'
     ) THEN
    CREATE POLICY "module_visibility public read"
  ON public.module_visibility FOR SELECT USING (true);
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('public.module_visibility') IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE schemaname = 'public' AND tablename = 'module_visibility' AND policyname = 'module_visibility admin write'
     ) THEN
    CREATE POLICY "module_visibility admin write"
  ON public.module_visibility FOR UPDATE TO authenticated
  USING (public.is_editor_admin()) WITH CHECK (public.is_editor_admin());
  END IF;
END $$;

-- Admins can read everything; non-admins cannot read this table at all.
CREATE POLICY "Admins read all system errors"
  ON public.system_error_logs FOR SELECT TO authenticated
  USING (public.has_role(auth.uid(), 'admin'::public.app_role));

-- Authenticated users can insert errors only scoped to themselves OR with a NULL user_id
-- (for very early bootstrap errors before session is hydrated).
CREATE POLICY "Authenticated insert own errors"
  ON public.system_error_logs FOR INSERT TO authenticated
  WITH CHECK (user_id IS NULL OR user_id = auth.uid());

-- Anon visitors can insert with NULL user_id only.
CREATE POLICY "Anon insert anonymous errors"
  ON public.system_error_logs FOR INSERT TO anon
  WITH CHECK (user_id IS NULL);

-- Admins can update (mark resolved, etc).
CREATE POLICY "Admins update system errors"
  ON public.system_error_logs FOR UPDATE TO authenticated
  USING (public.has_role(auth.uid(), 'admin'::public.app_role))
  WITH CHECK (public.has_role(auth.uid(), 'admin'::public.app_role));

DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'admin_action_log'
      AND policyname = 'Users insert own admin_action_log'
  ) THEN
    EXECUTE 'DROP POLICY "Users insert own admin_action_log" ON public.admin_action_log';

END IF;

END $$;

-- H-3: activity_events — NULL user_id bypass.
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'activity_events'
      AND policyname = 'activity_events_insert_own'
  ) THEN
    EXECUTE 'DROP POLICY activity_events_insert_own ON public.activity_events';

END IF;

END $$;

CREATE POLICY activity_events_insert_authenticated
  ON public.activity_events
  FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

-- L-1: module_visibility — admins had UPDATE but no INSERT/DELETE.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'module_visibility'
      AND policyname = 'admins insert module visibility'
  ) THEN
    EXECUTE $p$
      CREATE POLICY "admins insert module visibility"
        ON public.module_visibility
        FOR INSERT TO authenticated
        WITH CHECK (public.has_role(auth.uid(), 'admin'::public.app_role))
    $p$;

END IF;

IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'module_visibility'
      AND policyname = 'admins delete module visibility'
  ) THEN
    EXECUTE $p$
      CREATE POLICY "admins delete module visibility"
        ON public.module_visibility
        FOR DELETE TO authenticated
        USING (public.has_role(auth.uid(), 'admin'::public.app_role))
    $p$;

END IF;

END $$;

DO $idem$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname='Admins read all system errors' AND tablename='system_error_logs') THEN
    CREATE POLICY "Admins read all system errors" ON public.system_error_logs FOR SELECT TO authenticated USING (public.has_role(auth.uid(), 'admin'::public.app_role));
  END IF;
END $idem$;

DO $idem$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname='Authenticated insert own errors' AND tablename='system_error_logs') THEN
    CREATE POLICY "Authenticated insert own errors" ON public.system_error_logs FOR INSERT TO authenticated WITH CHECK (user_id IS NULL OR user_id = auth.uid());
  END IF;
END $idem$;

DO $idem$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname='Anon insert anonymous errors' AND tablename='system_error_logs') THEN
    CREATE POLICY "Anon insert anonymous errors" ON public.system_error_logs FOR INSERT TO anon WITH CHECK (user_id IS NULL);
  END IF;
END $idem$;

DO $idem$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname='Admins update system errors' AND tablename='system_error_logs') THEN
    CREATE POLICY "Admins update system errors" ON public.system_error_logs FOR UPDATE TO authenticated USING (public.has_role(auth.uid(), 'admin'::public.app_role)) WITH CHECK (public.has_role(auth.uid(), 'admin'::public.app_role));
  END IF;
END $idem$;

-- ------------------------------------------------------------
-- Migration: 20260611152022_f1a8dfa1-3ba2-44ef-8993-07f8110b0094.sql
-- ------------------------------------------------------------

-- ============================================================
-- PHASE 3: CRITICAL SECURITY HARDENING
-- ============================================================
DROP POLICY IF EXISTS profiles_select_authenticated ON public.profiles;

DROP POLICY IF EXISTS spages_public_read ON public.site_pages;

DROP POLICY IF EXISTS "public reads site settings" ON public.site_settings;

DROP POLICY IF EXISTS ssettings_public_read ON public.site_settings;

CREATE POLICY ssettings_public_read ON public.site_settings
  FOR SELECT TO anon, authenticated USING (true);

DROP POLICY IF EXISTS notif_sent_read ON public.notifications;

CREATE POLICY blog_categories_public_read ON public.blog_categories FOR SELECT TO anon, authenticated USING (true);

CREATE POLICY blog_categories_admin_write ON public.blog_categories FOR ALL TO authenticated
  USING (public.has_role(auth.uid(), 'admin'::public.app_role))
  WITH CHECK (public.has_role(auth.uid(), 'admin'::public.app_role));

CREATE POLICY blog_tags_public_read ON public.blog_tags FOR SELECT TO anon, authenticated USING (true);

CREATE POLICY blog_tags_admin_write ON public.blog_tags FOR ALL TO authenticated
  USING (public.has_role(auth.uid(), 'admin'::public.app_role))
  WITH CHECK (public.has_role(auth.uid(), 'admin'::public.app_role));

CREATE POLICY blog_posts_public_read_published ON public.blog_posts
  FOR SELECT TO anon, authenticated
  USING (status = 'published' OR public.has_role(auth.uid(), 'admin'::public.app_role));

CREATE POLICY blog_posts_admin_write ON public.blog_posts FOR ALL TO authenticated
  USING (public.has_role(auth.uid(), 'admin'::public.app_role))
  WITH CHECK (public.has_role(auth.uid(), 'admin'::public.app_role));

CREATE POLICY blog_post_tags_public_read ON public.blog_post_tags FOR SELECT TO anon, authenticated USING (true);

CREATE POLICY blog_post_tags_admin_write ON public.blog_post_tags FOR ALL TO authenticated
  USING (public.has_role(auth.uid(), 'admin'::public.app_role))
  WITH CHECK (public.has_role(auth.uid(), 'admin'::public.app_role));

CREATE POLICY blog_views_anyone_insert ON public.blog_views FOR INSERT TO anon, authenticated WITH CHECK (true);

CREATE POLICY blog_views_admin_read ON public.blog_views FOR SELECT TO authenticated
  USING (public.has_role(auth.uid(), 'admin'::public.app_role));

DROP POLICY IF EXISTS "Admins manage admin_notes" ON public.admin_notes;

CREATE POLICY "Admins manage admin_notes" ON public.admin_notes
  FOR ALL TO authenticated
  USING (public.has_permission(auth.uid(), 'manage_users'))
  WITH CHECK (public.has_permission(auth.uid(), 'manage_users'));

DROP POLICY IF EXISTS "Admins manage user_tags" ON public.user_tags;

CREATE POLICY "Admins manage user_tags" ON public.user_tags
  FOR ALL TO authenticated
  USING (public.has_permission(auth.uid(), 'manage_users'))
  WITH CHECK (public.has_permission(auth.uid(), 'manage_users'));

DROP POLICY IF EXISTS "Users read own tags" ON public.user_tags;

CREATE POLICY "Users read own tags" ON public.user_tags
  FOR SELECT TO authenticated USING (user_id = auth.uid());

DROP POLICY IF EXISTS "Admins manage user_messages" ON public.user_messages;

CREATE POLICY "Admins manage user_messages" ON public.user_messages
  FOR ALL TO authenticated
  USING (public.has_permission(auth.uid(), 'manage_users'))
  WITH CHECK (public.has_permission(auth.uid(), 'manage_users'));

DROP POLICY IF EXISTS "Recipients read own messages" ON public.user_messages;

CREATE POLICY "Recipients read own messages" ON public.user_messages
  FOR SELECT TO authenticated USING (to_user_id = auth.uid());

DROP POLICY IF EXISTS "Recipients mark own read" ON public.user_messages;

CREATE POLICY "Recipients mark own read" ON public.user_messages
  FOR UPDATE TO authenticated USING (to_user_id = auth.uid()) WITH CHECK (to_user_id = auth.uid());

DROP POLICY IF EXISTS "Admins manage user_bans" ON public.user_bans;

CREATE POLICY "Admins manage user_bans" ON public.user_bans
  FOR ALL TO authenticated
  USING (public.has_permission(auth.uid(), 'manage_users'))
  WITH CHECK (public.has_permission(auth.uid(), 'manage_users'));

DROP POLICY IF EXISTS "Users read own bans" ON public.user_bans;

CREATE POLICY "Users read own bans" ON public.user_bans
  FOR SELECT TO authenticated USING (user_id = auth.uid());

DROP POLICY IF EXISTS "Auth controls are world readable" ON public.auth_access_controls;

CREATE POLICY "Auth controls are world readable" ON public.auth_access_controls
  FOR SELECT TO anon, authenticated
  USING (true);

DROP POLICY IF EXISTS "Anon insert anonymous errors" ON public.system_error_logs;

-- Tighten the permissive WITH CHECK so anon inserts must carry a viewer_hash
-- and may not impersonate another user. Authenticated inserts may set their
-- own viewer_id (or leave it null).
DROP POLICY IF EXISTS blog_views_anyone_insert ON public.blog_views;

CREATE POLICY blog_views_anon_insert ON public.blog_views
  FOR INSERT TO anon
  WITH CHECK (viewer_id IS NULL AND viewer_hash IS NOT NULL);

CREATE POLICY blog_views_auth_insert ON public.blog_views
  FOR INSERT TO authenticated
  WITH CHECK ((viewer_id IS NULL OR viewer_id = auth.uid()) AND viewer_hash IS NOT NULL);


-- =================== 10. GRANTS / REVOKES ==========

GRANT SELECT ON public.user_roles TO authenticated;

GRANT ALL    ON public.user_roles TO service_role;

GRANT EXECUTE ON FUNCTION public.has_role(uuid, public.app_role) TO authenticated, service_role;

REVOKE EXECUTE ON FUNCTION public.has_role(uuid, public.app_role) FROM anon, PUBLIC;

GRANT SELECT ON public.user_roles TO authenticated;

GRANT ALL ON public.user_roles TO service_role;

GRANT SELECT ON public.homepage_sections TO anon, authenticated;

GRANT ALL ON public.homepage_sections TO service_role;

GRANT SELECT ON public.site_settings TO anon, authenticated;

GRANT ALL ON public.site_settings TO service_role;

GRANT SELECT ON public.module_visibility TO anon, authenticated;

GRANT ALL ON public.module_visibility TO service_role;

GRANT SELECT, INSERT ON public.content_versions TO authenticated;

GRANT ALL ON public.content_versions TO service_role;

GRANT SELECT ON public.media_assets TO anon, authenticated;

GRANT INSERT, UPDATE, DELETE ON public.media_assets TO authenticated;

GRANT ALL ON public.media_assets TO service_role;

REVOKE EXECUTE ON FUNCTION public.has_role(uuid, public.app_role) FROM PUBLIC, anon, authenticated;

GRANT EXECUTE ON FUNCTION public.has_role(uuid, public.app_role) TO service_role;

REVOKE ALL ON FUNCTION public.admin_get_table_sizes() FROM PUBLIC;

REVOKE ALL ON FUNCTION public.admin_get_db_size() FROM PUBLIC;

GRANT EXECUTE ON FUNCTION public.admin_get_table_sizes() TO authenticated;

GRANT EXECUTE ON FUNCTION public.admin_get_db_size() TO authenticated;

GRANT SELECT ON public.user_sessions TO authenticated;

GRANT ALL ON public.user_sessions TO service_role;

GRANT EXECUTE ON FUNCTION public.claim_user_session(TEXT, TEXT) TO authenticated;

grant select on public.profiles to anon;

grant select, insert, update on public.profiles to authenticated;

grant all on public.profiles to service_role;

grant select, insert, delete on public.avatars to authenticated;

grant all on public.avatars to service_role;

grant select on public.levels to anon, authenticated;

grant all on public.levels to service_role;

grant select on public.subjects to anon, authenticated;

grant all on public.subjects to service_role;

grant select on public.chapters to anon, authenticated;

grant all on public.chapters to service_role;

grant select on public.mcqs to authenticated;

grant all on public.mcqs to service_role;

grant select, insert, delete on public.mcq_bookmarks to authenticated;

grant all on public.mcq_bookmarks to service_role;

grant select, insert, update, delete on public.mcq_wrong_questions to authenticated;

grant all on public.mcq_wrong_questions to service_role;

grant select, insert on public.mcq_delete_audit to authenticated;

grant all on public.mcq_delete_audit to service_role;

grant select on public.quizzes to authenticated;

grant all on public.quizzes to service_role;

grant select on public.quiz_questions to authenticated;

grant all on public.quiz_questions to service_role;

grant select, insert, update on public.quiz_sessions to authenticated;

grant all on public.quiz_sessions to service_role;

grant select, insert on public.exam_attempts to authenticated;

grant all on public.exam_attempts to service_role;

grant select, insert on public.attempt_answers to authenticated;

grant all on public.attempt_answers to service_role;

grant select on public.flash_cards to authenticated;

grant all on public.flash_cards to service_role;

grant select on public.flash_card_visibility to anon, authenticated;

grant all on public.flash_card_visibility to service_role;

grant select on public.short_notes to authenticated;

grant all on public.short_notes to service_role;

grant select on public.short_notes_visibility to anon, authenticated;

grant all on public.short_notes_visibility to service_role;

grant select on public.question_bank_resources to authenticated;

grant all on public.question_bank_resources to service_role;

grant select on public.question_bank_visibility to anon, authenticated;

grant all on public.question_bank_visibility to service_role;

grant select on public.video_classes to authenticated;

grant all on public.video_classes to service_role;

grant select on public.video_class_visibility to anon, authenticated;

grant all on public.video_class_visibility to service_role;

grant select on public.notifications to authenticated;

grant all on public.notifications to service_role;

grant select, insert on public.notification_reads to authenticated;

grant all on public.notification_reads to service_role;

GRANT SELECT, INSERT, UPDATE ON public.user_login_events TO authenticated;

GRANT ALL ON public.user_login_events TO service_role;

REVOKE EXECUTE ON FUNCTION public.admin_user_analytics() FROM PUBLIC, anon;

REVOKE EXECUTE ON FUNCTION public.admin_top_users(text, integer) FROM PUBLIC, anon;

REVOKE EXECUTE ON FUNCTION public.admin_soft_delete_user(uuid) FROM PUBLIC, anon;

REVOKE EXECUTE ON FUNCTION public.admin_restore_user(uuid) FROM PUBLIC, anon;

REVOKE EXECUTE ON FUNCTION public.admin_hard_delete_user(uuid) FROM PUBLIC, anon;

GRANT EXECUTE ON FUNCTION public.admin_user_analytics() TO authenticated;

GRANT EXECUTE ON FUNCTION public.admin_top_users(text, integer) TO authenticated;

GRANT EXECUTE ON FUNCTION public.admin_soft_delete_user(uuid) TO authenticated;

GRANT EXECUTE ON FUNCTION public.admin_restore_user(uuid) TO authenticated;

GRANT EXECUTE ON FUNCTION public.admin_hard_delete_user(uuid) TO authenticated;

GRANT SELECT, INSERT ON public.activity_events TO authenticated;

GRANT ALL ON public.activity_events TO service_role;

REVOKE EXECUTE ON FUNCTION public.admin_get_db_size() FROM anon, public;

REVOKE EXECUTE ON FUNCTION public.admin_get_table_sizes() FROM anon, public;

REVOKE EXECUTE ON FUNCTION public.admin_hard_delete_user(uuid) FROM anon, public;

REVOKE EXECUTE ON FUNCTION public.admin_restore_user(uuid) FROM anon, public;

REVOKE EXECUTE ON FUNCTION public.admin_soft_delete_user(uuid) FROM anon, public;

REVOKE EXECUTE ON FUNCTION public.admin_user_analytics() FROM anon, public;

REVOKE EXECUTE ON FUNCTION public.admin_activity_overview(integer) FROM anon, public;

REVOKE EXECUTE ON FUNCTION public.admin_top_buttons(integer, integer) FROM anon, public;

REVOKE EXECUTE ON FUNCTION public.admin_user_activity(uuid, integer) FROM anon, public;

REVOKE EXECUTE ON FUNCTION public.admin_top_users(text, integer) FROM anon, public;

REVOKE EXECUTE ON FUNCTION public.admin_top_pages(integer, integer) FROM anon, public;

REVOKE EXECUTE ON FUNCTION public.admin_top_modules(integer, integer) FROM anon, public;

REVOKE EXECUTE ON FUNCTION public.admin_activity_timeseries(integer, integer) FROM anon, public;

GRANT EXECUTE ON FUNCTION public.admin_activity_overview(integer) TO authenticated;

GRANT EXECUTE ON FUNCTION public.admin_top_buttons(integer, integer) TO authenticated;

GRANT EXECUTE ON FUNCTION public.admin_top_pages(integer, integer) TO authenticated;

GRANT EXECUTE ON FUNCTION public.admin_top_modules(integer, integer) TO authenticated;

GRANT EXECUTE ON FUNCTION public.admin_activity_timeseries(integer, integer) TO authenticated;

GRANT EXECUTE ON FUNCTION public.admin_user_activity(uuid, integer) TO authenticated;

GRANT SELECT, INSERT, UPDATE ON public.study_sessions TO authenticated;

GRANT ALL ON public.study_sessions TO service_role;

GRANT SELECT ON public.user_roles TO authenticated;

GRANT ALL ON public.user_roles TO service_role;

GRANT SELECT ON public.homepage_sections TO anon, authenticated;

GRANT ALL ON public.homepage_sections TO service_role;

GRANT SELECT ON public.site_settings TO anon, authenticated;

GRANT ALL ON public.site_settings TO service_role;

GRANT SELECT ON public.module_visibility TO anon, authenticated;

GRANT ALL ON public.module_visibility TO service_role;

GRANT SELECT, INSERT ON public.content_versions TO authenticated;

GRANT ALL ON public.content_versions TO service_role;

GRANT SELECT ON public.media_assets TO anon, authenticated;

GRANT INSERT, UPDATE, DELETE ON public.media_assets TO authenticated;

GRANT ALL ON public.media_assets TO service_role;

REVOKE EXECUTE ON FUNCTION public.has_role(uuid, public.app_role) FROM PUBLIC, anon, authenticated;

GRANT EXECUTE ON FUNCTION public.has_role(uuid, public.app_role) TO service_role;

REVOKE ALL ON FUNCTION public.admin_get_table_sizes() FROM PUBLIC;

REVOKE ALL ON FUNCTION public.admin_get_db_size() FROM PUBLIC;

GRANT EXECUTE ON FUNCTION public.admin_get_table_sizes() TO authenticated;

GRANT EXECUTE ON FUNCTION public.admin_get_db_size() TO authenticated;

GRANT SELECT ON public.user_sessions TO authenticated;

GRANT ALL ON public.user_sessions TO service_role;

GRANT EXECUTE ON FUNCTION public.claim_user_session(TEXT, TEXT) TO authenticated;

grant select on public.profiles to anon;

grant select, insert, update on public.profiles to authenticated;

grant all on public.profiles to service_role;

grant select, insert, delete on public.avatars to authenticated;

grant all on public.avatars to service_role;

grant select on public.levels to anon, authenticated;

grant all on public.levels to service_role;

grant select on public.subjects to anon, authenticated;

grant all on public.subjects to service_role;

grant select on public.chapters to anon, authenticated;

grant all on public.chapters to service_role;

grant select on public.mcqs to authenticated;

grant all on public.mcqs to service_role;

grant select, insert, delete on public.mcq_bookmarks to authenticated;

grant all on public.mcq_bookmarks to service_role;

grant select, insert, update, delete on public.mcq_wrong_questions to authenticated;

grant all on public.mcq_wrong_questions to service_role;

grant select, insert on public.mcq_delete_audit to authenticated;

grant all on public.mcq_delete_audit to service_role;

grant select on public.quizzes to authenticated;

grant all on public.quizzes to service_role;

grant select on public.quiz_questions to authenticated;

grant all on public.quiz_questions to service_role;

grant select, insert, update on public.quiz_sessions to authenticated;

grant all on public.quiz_sessions to service_role;

grant select, insert on public.exam_attempts to authenticated;

grant all on public.exam_attempts to service_role;

grant select, insert on public.attempt_answers to authenticated;

grant all on public.attempt_answers to service_role;

grant select on public.flash_cards to authenticated;

grant all on public.flash_cards to service_role;

grant select on public.flash_card_visibility to anon, authenticated;

grant all on public.flash_card_visibility to service_role;

grant select on public.short_notes to authenticated;

grant all on public.short_notes to service_role;

grant select on public.short_notes_visibility to anon, authenticated;

grant all on public.short_notes_visibility to service_role;

grant select on public.question_bank_resources to authenticated;

grant all on public.question_bank_resources to service_role;

grant select on public.question_bank_visibility to anon, authenticated;

grant all on public.question_bank_visibility to service_role;

grant select on public.video_classes to authenticated;

grant all on public.video_classes to service_role;

grant select on public.video_class_visibility to anon, authenticated;

grant all on public.video_class_visibility to service_role;

grant select on public.notifications to authenticated;

grant all on public.notifications to service_role;

grant select, insert on public.notification_reads to authenticated;

grant all on public.notification_reads to service_role;

GRANT SELECT, INSERT, UPDATE ON public.user_login_events TO authenticated;

GRANT ALL ON public.user_login_events TO service_role;

REVOKE EXECUTE ON FUNCTION public.admin_user_analytics() FROM PUBLIC, anon;

REVOKE EXECUTE ON FUNCTION public.admin_top_users(text, integer) FROM PUBLIC, anon;

REVOKE EXECUTE ON FUNCTION public.admin_soft_delete_user(uuid) FROM PUBLIC, anon;

REVOKE EXECUTE ON FUNCTION public.admin_restore_user(uuid) FROM PUBLIC, anon;

REVOKE EXECUTE ON FUNCTION public.admin_hard_delete_user(uuid) FROM PUBLIC, anon;

GRANT EXECUTE ON FUNCTION public.admin_user_analytics() TO authenticated;

GRANT EXECUTE ON FUNCTION public.admin_top_users(text, integer) TO authenticated;

GRANT EXECUTE ON FUNCTION public.admin_soft_delete_user(uuid) TO authenticated;

GRANT EXECUTE ON FUNCTION public.admin_restore_user(uuid) TO authenticated;

GRANT EXECUTE ON FUNCTION public.admin_hard_delete_user(uuid) TO authenticated;

GRANT SELECT, INSERT ON public.activity_events TO authenticated;

GRANT ALL ON public.activity_events TO service_role;

REVOKE EXECUTE ON FUNCTION public.admin_get_db_size() FROM anon, public;

REVOKE EXECUTE ON FUNCTION public.admin_get_table_sizes() FROM anon, public;

REVOKE EXECUTE ON FUNCTION public.admin_hard_delete_user(uuid) FROM anon, public;

REVOKE EXECUTE ON FUNCTION public.admin_restore_user(uuid) FROM anon, public;

REVOKE EXECUTE ON FUNCTION public.admin_soft_delete_user(uuid) FROM anon, public;

REVOKE EXECUTE ON FUNCTION public.admin_user_analytics() FROM anon, public;

REVOKE EXECUTE ON FUNCTION public.admin_activity_overview(integer) FROM anon, public;

REVOKE EXECUTE ON FUNCTION public.admin_top_buttons(integer, integer) FROM anon, public;

REVOKE EXECUTE ON FUNCTION public.admin_user_activity(uuid, integer) FROM anon, public;

REVOKE EXECUTE ON FUNCTION public.admin_top_users(text, integer) FROM anon, public;

REVOKE EXECUTE ON FUNCTION public.admin_top_pages(integer, integer) FROM anon, public;

REVOKE EXECUTE ON FUNCTION public.admin_top_modules(integer, integer) FROM anon, public;

REVOKE EXECUTE ON FUNCTION public.admin_activity_timeseries(integer, integer) FROM anon, public;

GRANT EXECUTE ON FUNCTION public.admin_activity_overview(integer) TO authenticated;

GRANT EXECUTE ON FUNCTION public.admin_top_buttons(integer, integer) TO authenticated;

GRANT EXECUTE ON FUNCTION public.admin_top_pages(integer, integer) TO authenticated;

GRANT EXECUTE ON FUNCTION public.admin_top_modules(integer, integer) TO authenticated;

GRANT EXECUTE ON FUNCTION public.admin_activity_timeseries(integer, integer) TO authenticated;

GRANT EXECUTE ON FUNCTION public.admin_user_activity(uuid, integer) TO authenticated;

GRANT SELECT, INSERT, UPDATE ON public.study_sessions TO authenticated;

GRANT ALL ON public.study_sessions TO service_role;

GRANT SELECT ON public.user_roles TO authenticated;

GRANT ALL ON public.user_roles TO service_role;

GRANT SELECT ON public.homepage_sections TO anon, authenticated;

GRANT ALL ON public.homepage_sections TO service_role;

GRANT SELECT ON public.site_settings TO anon, authenticated;

GRANT ALL ON public.site_settings TO service_role;

GRANT SELECT ON public.module_visibility TO anon, authenticated;

GRANT ALL ON public.module_visibility TO service_role;

GRANT SELECT, INSERT ON public.content_versions TO authenticated;

GRANT ALL ON public.content_versions TO service_role;

GRANT SELECT ON public.media_assets TO anon, authenticated;

GRANT INSERT, UPDATE, DELETE ON public.media_assets TO authenticated;

GRANT ALL ON public.media_assets TO service_role;

REVOKE EXECUTE ON FUNCTION public.has_role(uuid, public.app_role) FROM PUBLIC, anon, authenticated;

GRANT EXECUTE ON FUNCTION public.has_role(uuid, public.app_role) TO service_role;

REVOKE ALL ON FUNCTION public.admin_get_table_sizes() FROM PUBLIC;

REVOKE ALL ON FUNCTION public.admin_get_db_size() FROM PUBLIC;

GRANT EXECUTE ON FUNCTION public.admin_get_table_sizes() TO authenticated;

GRANT EXECUTE ON FUNCTION public.admin_get_db_size() TO authenticated;

GRANT SELECT ON public.user_sessions TO authenticated;

GRANT ALL ON public.user_sessions TO service_role;

GRANT EXECUTE ON FUNCTION public.claim_user_session(TEXT, TEXT) TO authenticated;

grant select on public.profiles to anon;

grant select, insert, update on public.profiles to authenticated;

grant all on public.profiles to service_role;

grant select, insert, delete on public.avatars to authenticated;

grant all on public.avatars to service_role;

grant select on public.levels to anon, authenticated;

grant all on public.levels to service_role;

grant select on public.subjects to anon, authenticated;

grant all on public.subjects to service_role;

grant select on public.chapters to anon, authenticated;

grant all on public.chapters to service_role;

grant select on public.mcqs to authenticated;

grant all on public.mcqs to service_role;

grant select, insert, delete on public.mcq_bookmarks to authenticated;

grant all on public.mcq_bookmarks to service_role;

grant select, insert, update, delete on public.mcq_wrong_questions to authenticated;

grant all on public.mcq_wrong_questions to service_role;

grant select, insert on public.mcq_delete_audit to authenticated;

grant all on public.mcq_delete_audit to service_role;

grant select on public.quizzes to authenticated;

grant all on public.quizzes to service_role;

grant select on public.quiz_questions to authenticated;

grant all on public.quiz_questions to service_role;

grant select, insert, update on public.quiz_sessions to authenticated;

grant all on public.quiz_sessions to service_role;

grant select, insert on public.exam_attempts to authenticated;

grant all on public.exam_attempts to service_role;

grant select, insert on public.attempt_answers to authenticated;

grant all on public.attempt_answers to service_role;

grant select on public.flash_cards to authenticated;

grant all on public.flash_cards to service_role;

grant select on public.flash_card_visibility to anon, authenticated;

grant all on public.flash_card_visibility to service_role;

grant select on public.short_notes to authenticated;

grant all on public.short_notes to service_role;

grant select on public.short_notes_visibility to anon, authenticated;

grant all on public.short_notes_visibility to service_role;

grant select on public.question_bank_resources to authenticated;

grant all on public.question_bank_resources to service_role;

grant select on public.question_bank_visibility to anon, authenticated;

grant all on public.question_bank_visibility to service_role;

grant select on public.video_classes to authenticated;

grant all on public.video_classes to service_role;

grant select on public.video_class_visibility to anon, authenticated;

grant all on public.video_class_visibility to service_role;

grant select on public.notifications to authenticated;

grant all on public.notifications to service_role;

grant select, insert on public.notification_reads to authenticated;

grant all on public.notification_reads to service_role;

GRANT SELECT, INSERT, UPDATE ON public.user_login_events TO authenticated;

GRANT ALL ON public.user_login_events TO service_role;

REVOKE EXECUTE ON FUNCTION public.admin_user_analytics() FROM PUBLIC, anon;

REVOKE EXECUTE ON FUNCTION public.admin_top_users(text, integer) FROM PUBLIC, anon;

REVOKE EXECUTE ON FUNCTION public.admin_soft_delete_user(uuid) FROM PUBLIC, anon;

REVOKE EXECUTE ON FUNCTION public.admin_restore_user(uuid) FROM PUBLIC, anon;

REVOKE EXECUTE ON FUNCTION public.admin_hard_delete_user(uuid) FROM PUBLIC, anon;

GRANT EXECUTE ON FUNCTION public.admin_user_analytics() TO authenticated;

GRANT EXECUTE ON FUNCTION public.admin_top_users(text, integer) TO authenticated;

GRANT EXECUTE ON FUNCTION public.admin_soft_delete_user(uuid) TO authenticated;

GRANT EXECUTE ON FUNCTION public.admin_restore_user(uuid) TO authenticated;

GRANT EXECUTE ON FUNCTION public.admin_hard_delete_user(uuid) TO authenticated;

GRANT SELECT, INSERT ON public.activity_events TO authenticated;

GRANT ALL ON public.activity_events TO service_role;

REVOKE EXECUTE ON FUNCTION public.admin_activity_overview(integer) FROM PUBLIC, anon;

REVOKE EXECUTE ON FUNCTION public.admin_top_buttons(integer, integer) FROM PUBLIC, anon;

REVOKE EXECUTE ON FUNCTION public.admin_top_pages(integer, integer) FROM PUBLIC, anon;

REVOKE EXECUTE ON FUNCTION public.admin_top_modules(integer, integer) FROM PUBLIC, anon;

REVOKE EXECUTE ON FUNCTION public.admin_activity_timeseries(integer, integer) FROM PUBLIC, anon;

REVOKE EXECUTE ON FUNCTION public.admin_user_activity(uuid, integer) FROM PUBLIC, anon;

GRANT EXECUTE ON FUNCTION public.admin_activity_overview(integer) TO authenticated;

GRANT EXECUTE ON FUNCTION public.admin_top_buttons(integer, integer) TO authenticated;

GRANT EXECUTE ON FUNCTION public.admin_top_pages(integer, integer) TO authenticated;

GRANT EXECUTE ON FUNCTION public.admin_top_modules(integer, integer) TO authenticated;

GRANT EXECUTE ON FUNCTION public.admin_activity_timeseries(integer, integer) TO authenticated;

GRANT EXECUTE ON FUNCTION public.admin_user_activity(uuid, integer) TO authenticated;

GRANT SELECT, INSERT, UPDATE ON public.study_sessions TO authenticated;

GRANT ALL ON public.study_sessions TO service_role;

GRANT SELECT ON public.site_pages TO anon;

GRANT SELECT, INSERT, UPDATE, DELETE ON public.site_pages TO authenticated;

GRANT ALL ON public.site_pages TO service_role;

GRANT SELECT ON public.site_page_sections TO anon;

GRANT SELECT, INSERT, UPDATE, DELETE ON public.site_page_sections TO authenticated;

GRANT ALL ON public.site_page_sections TO service_role;

GRANT SELECT ON public.user_roles TO authenticated;

GRANT ALL ON public.user_roles TO service_role;

GRANT SELECT ON public.homepage_sections TO anon, authenticated;

GRANT ALL ON public.homepage_sections TO service_role;

GRANT SELECT ON public.site_settings TO anon, authenticated;

GRANT ALL ON public.site_settings TO service_role;

GRANT SELECT ON public.module_visibility TO anon, authenticated;

GRANT ALL ON public.module_visibility TO service_role;

GRANT SELECT, INSERT ON public.content_versions TO authenticated;

GRANT ALL ON public.content_versions TO service_role;

GRANT SELECT ON public.media_assets TO anon, authenticated;

GRANT INSERT, UPDATE, DELETE ON public.media_assets TO authenticated;

GRANT ALL ON public.media_assets TO service_role;

REVOKE EXECUTE ON FUNCTION public.has_role(uuid, public.app_role) FROM PUBLIC, anon, authenticated;

GRANT EXECUTE ON FUNCTION public.has_role(uuid, public.app_role) TO service_role;

REVOKE ALL ON FUNCTION public.admin_get_table_sizes() FROM PUBLIC;

REVOKE ALL ON FUNCTION public.admin_get_db_size() FROM PUBLIC;

GRANT EXECUTE ON FUNCTION public.admin_get_table_sizes() TO authenticated;

GRANT EXECUTE ON FUNCTION public.admin_get_db_size() TO authenticated;

GRANT SELECT ON public.user_sessions TO authenticated;

GRANT ALL ON public.user_sessions TO service_role;

GRANT EXECUTE ON FUNCTION public.claim_user_session(TEXT, TEXT) TO authenticated;

grant select on public.profiles to anon;

grant select, insert, update on public.profiles to authenticated;

grant all on public.profiles to service_role;

grant select, insert, delete on public.avatars to authenticated;

grant all on public.avatars to service_role;

grant select on public.levels to anon, authenticated;

grant all on public.levels to service_role;

grant select on public.subjects to anon, authenticated;

grant all on public.subjects to service_role;

grant select on public.chapters to anon, authenticated;

grant all on public.chapters to service_role;

grant select on public.mcqs to authenticated;

grant all on public.mcqs to service_role;

grant select, insert, delete on public.mcq_bookmarks to authenticated;

grant all on public.mcq_bookmarks to service_role;

grant select, insert, update, delete on public.mcq_wrong_questions to authenticated;

grant all on public.mcq_wrong_questions to service_role;

grant select, insert on public.mcq_delete_audit to authenticated;

grant all on public.mcq_delete_audit to service_role;

grant select on public.quizzes to authenticated;

grant all on public.quizzes to service_role;

grant select on public.quiz_questions to authenticated;

grant all on public.quiz_questions to service_role;

grant select, insert, update on public.quiz_sessions to authenticated;

grant all on public.quiz_sessions to service_role;

grant select, insert on public.exam_attempts to authenticated;

grant all on public.exam_attempts to service_role;

grant select, insert on public.attempt_answers to authenticated;

grant all on public.attempt_answers to service_role;

grant select on public.flash_cards to authenticated;

grant all on public.flash_cards to service_role;

grant select on public.flash_card_visibility to anon, authenticated;

grant all on public.flash_card_visibility to service_role;

grant select on public.short_notes to authenticated;

grant all on public.short_notes to service_role;

grant select on public.short_notes_visibility to anon, authenticated;

grant all on public.short_notes_visibility to service_role;

grant select on public.question_bank_resources to authenticated;

grant all on public.question_bank_resources to service_role;

grant select on public.question_bank_visibility to anon, authenticated;

grant all on public.question_bank_visibility to service_role;

grant select on public.video_classes to authenticated;

grant all on public.video_classes to service_role;

grant select on public.video_class_visibility to anon, authenticated;

grant all on public.video_class_visibility to service_role;

grant select on public.notifications to authenticated;

grant all on public.notifications to service_role;

grant select, insert on public.notification_reads to authenticated;

grant all on public.notification_reads to service_role;

GRANT SELECT, INSERT, UPDATE ON public.user_login_events TO authenticated;

GRANT ALL ON public.user_login_events TO service_role;

REVOKE EXECUTE ON FUNCTION public.admin_user_analytics() FROM PUBLIC, anon;

REVOKE EXECUTE ON FUNCTION public.admin_top_users(text, integer) FROM PUBLIC, anon;

REVOKE EXECUTE ON FUNCTION public.admin_soft_delete_user(uuid) FROM PUBLIC, anon;

REVOKE EXECUTE ON FUNCTION public.admin_restore_user(uuid) FROM PUBLIC, anon;

REVOKE EXECUTE ON FUNCTION public.admin_hard_delete_user(uuid) FROM PUBLIC, anon;

GRANT EXECUTE ON FUNCTION public.admin_user_analytics() TO authenticated;

GRANT EXECUTE ON FUNCTION public.admin_top_users(text, integer) TO authenticated;

GRANT EXECUTE ON FUNCTION public.admin_soft_delete_user(uuid) TO authenticated;

GRANT EXECUTE ON FUNCTION public.admin_restore_user(uuid) TO authenticated;

GRANT EXECUTE ON FUNCTION public.admin_hard_delete_user(uuid) TO authenticated;

GRANT SELECT, INSERT ON public.activity_events TO authenticated;

GRANT ALL ON public.activity_events TO service_role;

REVOKE EXECUTE ON FUNCTION public.admin_get_db_size() FROM anon, public;

REVOKE EXECUTE ON FUNCTION public.admin_get_table_sizes() FROM anon, public;

REVOKE EXECUTE ON FUNCTION public.admin_hard_delete_user(uuid) FROM anon, public;

REVOKE EXECUTE ON FUNCTION public.admin_restore_user(uuid) FROM anon, public;

REVOKE EXECUTE ON FUNCTION public.admin_soft_delete_user(uuid) FROM anon, public;

REVOKE EXECUTE ON FUNCTION public.admin_user_analytics() FROM anon, public;

REVOKE EXECUTE ON FUNCTION public.admin_activity_overview(integer) FROM anon, public;

REVOKE EXECUTE ON FUNCTION public.admin_top_buttons(integer, integer) FROM anon, public;

REVOKE EXECUTE ON FUNCTION public.admin_user_activity(uuid, integer) FROM anon, public;

REVOKE EXECUTE ON FUNCTION public.admin_top_users(text, integer) FROM anon, public;

REVOKE EXECUTE ON FUNCTION public.admin_top_pages(integer, integer) FROM anon, public;

REVOKE EXECUTE ON FUNCTION public.admin_top_modules(integer, integer) FROM anon, public;

REVOKE EXECUTE ON FUNCTION public.admin_activity_timeseries(integer, integer) FROM anon, public;

GRANT EXECUTE ON FUNCTION public.admin_activity_overview(integer) TO authenticated;

GRANT EXECUTE ON FUNCTION public.admin_top_buttons(integer, integer) TO authenticated;

GRANT EXECUTE ON FUNCTION public.admin_top_pages(integer, integer) TO authenticated;

GRANT EXECUTE ON FUNCTION public.admin_top_modules(integer, integer) TO authenticated;

GRANT EXECUTE ON FUNCTION public.admin_activity_timeseries(integer, integer) TO authenticated;

GRANT EXECUTE ON FUNCTION public.admin_user_activity(uuid, integer) TO authenticated;

GRANT SELECT, INSERT, UPDATE ON public.study_sessions TO authenticated;

GRANT ALL ON public.study_sessions TO service_role;

GRANT SELECT ON public.site_pages TO anon;

GRANT SELECT, INSERT, UPDATE, DELETE ON public.site_pages TO authenticated;

GRANT ALL ON public.site_pages TO service_role;

GRANT SELECT ON public.site_page_sections TO anon;

GRANT SELECT, INSERT, UPDATE, DELETE ON public.site_page_sections TO authenticated;

GRANT ALL ON public.site_page_sections TO service_role;

GRANT SELECT, INSERT, UPDATE, DELETE ON public.profiles TO authenticated;

GRANT ALL ON public.profiles TO service_role;

GRANT SELECT ON public.user_roles TO authenticated;

GRANT ALL ON public.user_roles TO service_role;

GRANT EXECUTE ON FUNCTION public.has_role(uuid, public.app_role) TO authenticated, anon, service_role;

GRANT SELECT ON public.levels TO anon, authenticated;

GRANT ALL ON public.levels TO authenticated;

GRANT ALL ON public.levels TO service_role;

GRANT SELECT ON public.subjects TO anon, authenticated;

GRANT ALL ON public.subjects TO authenticated;

GRANT ALL ON public.subjects TO service_role;

GRANT SELECT ON public.chapters TO anon, authenticated;

GRANT ALL ON public.chapters TO authenticated;

GRANT ALL ON public.chapters TO service_role;

GRANT SELECT ON public.mcqs TO anon, authenticated;

GRANT ALL ON public.mcqs TO authenticated;

GRANT ALL ON public.mcqs TO service_role;

GRANT SELECT, INSERT ON public.mcq_delete_audit TO authenticated;

GRANT ALL ON public.mcq_delete_audit TO service_role;

GRANT SELECT ON public.quizzes TO anon, authenticated;

GRANT ALL ON public.quizzes TO authenticated;

GRANT ALL ON public.quizzes TO service_role;

GRANT SELECT ON public.quiz_questions TO anon, authenticated;

GRANT ALL ON public.quiz_questions TO authenticated;

GRANT ALL ON public.quiz_questions TO service_role;

GRANT SELECT, INSERT, UPDATE, DELETE ON public.exam_attempts TO authenticated;

GRANT ALL ON public.exam_attempts TO service_role;

GRANT SELECT, INSERT, UPDATE, DELETE ON public.attempt_answers TO authenticated;

GRANT ALL ON public.attempt_answers TO service_role;

GRANT SELECT, INSERT, UPDATE, DELETE ON public.mcq_bookmarks TO authenticated;

GRANT ALL ON public.mcq_bookmarks TO service_role;

GRANT SELECT, INSERT, UPDATE, DELETE ON public.mcq_wrong_questions TO authenticated;

GRANT ALL ON public.mcq_wrong_questions TO service_role;

GRANT SELECT ON public.flash_cards TO anon, authenticated;

GRANT ALL ON public.flash_cards TO authenticated;

GRANT ALL ON public.flash_cards TO service_role;

GRANT SELECT ON public.short_notes TO anon, authenticated;

GRANT ALL ON public.short_notes TO authenticated;

GRANT ALL ON public.short_notes TO service_role;

GRANT SELECT ON public.question_bank_resources TO anon, authenticated;

GRANT ALL ON public.question_bank_resources TO authenticated;

GRANT ALL ON public.question_bank_resources TO service_role;

GRANT SELECT ON public.video_classes TO anon, authenticated;

GRANT ALL ON public.video_classes TO authenticated;

GRANT ALL ON public.video_classes TO service_role;

GRANT SELECT ON public.module_visibility TO anon, authenticated;

GRANT ALL ON public.module_visibility TO authenticated;

GRANT ALL ON public.module_visibility TO service_role;

GRANT SELECT ON public.flash_card_visibility TO anon, authenticated;

GRANT ALL ON public.flash_card_visibility TO authenticated;

GRANT ALL ON public.flash_card_visibility TO service_role;

GRANT SELECT ON public.short_notes_visibility TO anon, authenticated;

GRANT ALL ON public.short_notes_visibility TO authenticated;

GRANT ALL ON public.short_notes_visibility TO service_role;

GRANT SELECT ON public.question_bank_visibility TO anon, authenticated;

GRANT ALL ON public.question_bank_visibility TO authenticated;

GRANT ALL ON public.question_bank_visibility TO service_role;

GRANT SELECT ON public.video_class_visibility TO anon, authenticated;

GRANT ALL ON public.video_class_visibility TO authenticated;

GRANT ALL ON public.video_class_visibility TO service_role;

GRANT SELECT ON public.notifications TO anon, authenticated;

GRANT ALL ON public.notifications TO authenticated;

GRANT ALL ON public.notifications TO service_role;

GRANT SELECT, INSERT, UPDATE, DELETE ON public.notification_reads TO authenticated;

GRANT ALL ON public.notification_reads TO service_role;

GRANT SELECT, INSERT ON public.activity_events TO authenticated;

GRANT ALL ON public.activity_events TO service_role;

GRANT SELECT, INSERT, UPDATE ON public.user_login_events TO authenticated;

GRANT ALL ON public.user_login_events TO service_role;

GRANT SELECT, INSERT, UPDATE, DELETE ON public.user_sessions TO authenticated;

GRANT ALL ON public.user_sessions TO service_role;

GRANT SELECT, INSERT, UPDATE ON public.study_sessions TO authenticated;

GRANT ALL ON public.study_sessions TO service_role;

GRANT SELECT ON public.site_settings TO anon, authenticated;

GRANT ALL ON public.site_settings TO authenticated;

GRANT ALL ON public.site_settings TO service_role;

GRANT SELECT ON public.site_pages TO anon, authenticated;

GRANT ALL ON public.site_pages TO authenticated;

GRANT ALL ON public.site_pages TO service_role;

GRANT SELECT ON public.site_page_sections TO anon, authenticated;

GRANT ALL ON public.site_page_sections TO authenticated;

GRANT ALL ON public.site_page_sections TO service_role;

GRANT SELECT ON public.homepage_sections TO anon, authenticated;

GRANT ALL ON public.homepage_sections TO authenticated;

GRANT ALL ON public.homepage_sections TO service_role;

GRANT SELECT ON public.media_assets TO anon, authenticated;

GRANT ALL ON public.media_assets TO authenticated;

GRANT ALL ON public.media_assets TO service_role;

GRANT SELECT, INSERT ON public.content_versions TO authenticated;

GRANT ALL ON public.content_versions TO service_role;

GRANT SELECT ON public.avatars TO anon, authenticated;

GRANT ALL ON public.avatars TO authenticated;

GRANT ALL ON public.avatars TO service_role;

-- Grant execute to authenticated only (admins enforce via assertAdmin in server fns)
REVOKE EXECUTE ON FUNCTION public.admin_user_analytics() FROM PUBLIC, anon;

REVOKE EXECUTE ON FUNCTION public.admin_activity_overview() FROM PUBLIC, anon;

REVOKE EXECUTE ON FUNCTION public.admin_top_modules() FROM PUBLIC, anon;

REVOKE EXECUTE ON FUNCTION public.admin_top_users() FROM PUBLIC, anon;

REVOKE EXECUTE ON FUNCTION public.admin_top_buttons() FROM PUBLIC, anon;

REVOKE EXECUTE ON FUNCTION public.admin_top_pages() FROM PUBLIC, anon;

REVOKE EXECUTE ON FUNCTION public.admin_activity_timeseries() FROM PUBLIC, anon;

REVOKE EXECUTE ON FUNCTION public.admin_user_activity() FROM PUBLIC, anon;

GRANT EXECUTE ON FUNCTION public.admin_user_analytics() TO authenticated, service_role;

GRANT EXECUTE ON FUNCTION public.admin_activity_overview() TO authenticated, service_role;

GRANT EXECUTE ON FUNCTION public.admin_top_modules() TO authenticated, service_role;

GRANT EXECUTE ON FUNCTION public.admin_top_users() TO authenticated, service_role;

GRANT EXECUTE ON FUNCTION public.admin_top_buttons() TO authenticated, service_role;

GRANT EXECUTE ON FUNCTION public.admin_top_pages() TO authenticated, service_role;

GRANT EXECUTE ON FUNCTION public.admin_activity_timeseries() TO authenticated, service_role;

GRANT EXECUTE ON FUNCTION public.admin_user_activity() TO authenticated, service_role;

-- Tighten security: scope has_role to authenticated only (linter WARN 28/29)
REVOKE EXECUTE ON FUNCTION public.has_role(uuid, public.app_role) FROM PUBLIC, anon;

GRANT EXECUTE ON FUNCTION public.has_role(uuid, public.app_role) TO authenticated, service_role;

GRANT SELECT ON public.user_roles TO authenticated;

GRANT ALL ON public.user_roles TO service_role;

GRANT SELECT ON public.homepage_sections TO anon, authenticated;

GRANT ALL ON public.homepage_sections TO service_role;

GRANT SELECT ON public.site_settings TO anon, authenticated;

GRANT ALL ON public.site_settings TO service_role;

GRANT SELECT ON public.module_visibility TO anon, authenticated;

GRANT ALL ON public.module_visibility TO service_role;

GRANT SELECT, INSERT ON public.content_versions TO authenticated;

GRANT ALL ON public.content_versions TO service_role;

GRANT SELECT ON public.media_assets TO anon, authenticated;

GRANT INSERT, UPDATE, DELETE ON public.media_assets TO authenticated;

GRANT ALL ON public.media_assets TO service_role;

REVOKE EXECUTE ON FUNCTION public.has_role(uuid, public.app_role) FROM PUBLIC, anon, authenticated;

GRANT EXECUTE ON FUNCTION public.has_role(uuid, public.app_role) TO service_role;

REVOKE ALL ON FUNCTION public.admin_get_table_sizes() FROM PUBLIC;

REVOKE ALL ON FUNCTION public.admin_get_db_size() FROM PUBLIC;

GRANT EXECUTE ON FUNCTION public.admin_get_table_sizes() TO authenticated;

GRANT EXECUTE ON FUNCTION public.admin_get_db_size() TO authenticated;

GRANT SELECT ON public.user_sessions TO authenticated;

GRANT ALL ON public.user_sessions TO service_role;

GRANT EXECUTE ON FUNCTION public.claim_user_session(TEXT, TEXT) TO authenticated;

grant select on public.profiles to anon;

grant select, insert, update on public.profiles to authenticated;

grant all on public.profiles to service_role;

grant select, insert, delete on public.avatars to authenticated;

grant all on public.avatars to service_role;

grant select on public.levels to anon, authenticated;

grant all on public.levels to service_role;

grant select on public.subjects to anon, authenticated;

grant all on public.subjects to service_role;

grant select on public.chapters to anon, authenticated;

grant all on public.chapters to service_role;

grant select on public.mcqs to authenticated;

grant all on public.mcqs to service_role;

grant select, insert, delete on public.mcq_bookmarks to authenticated;

grant all on public.mcq_bookmarks to service_role;

grant select, insert, update, delete on public.mcq_wrong_questions to authenticated;

grant all on public.mcq_wrong_questions to service_role;

grant select, insert on public.mcq_delete_audit to authenticated;

grant all on public.mcq_delete_audit to service_role;

grant select on public.quizzes to authenticated;

grant all on public.quizzes to service_role;

grant select on public.quiz_questions to authenticated;

grant all on public.quiz_questions to service_role;

grant select, insert, update on public.quiz_sessions to authenticated;

grant all on public.quiz_sessions to service_role;

grant select, insert on public.exam_attempts to authenticated;

grant all on public.exam_attempts to service_role;

grant select, insert on public.attempt_answers to authenticated;

grant all on public.attempt_answers to service_role;

grant select on public.flash_cards to authenticated;

grant all on public.flash_cards to service_role;

grant select on public.flash_card_visibility to anon, authenticated;

grant all on public.flash_card_visibility to service_role;

grant select on public.short_notes to authenticated;

grant all on public.short_notes to service_role;

grant select on public.short_notes_visibility to anon, authenticated;

grant all on public.short_notes_visibility to service_role;

grant select on public.question_bank_resources to authenticated;

grant all on public.question_bank_resources to service_role;

grant select on public.question_bank_visibility to anon, authenticated;

grant all on public.question_bank_visibility to service_role;

grant select on public.video_classes to authenticated;

grant all on public.video_classes to service_role;

grant select on public.video_class_visibility to anon, authenticated;

grant all on public.video_class_visibility to service_role;

grant select on public.notifications to authenticated;

grant all on public.notifications to service_role;

grant select, insert on public.notification_reads to authenticated;

grant all on public.notification_reads to service_role;

GRANT SELECT, INSERT, UPDATE ON public.user_login_events TO authenticated;

GRANT ALL ON public.user_login_events TO service_role;

REVOKE EXECUTE ON FUNCTION public.admin_user_analytics() FROM PUBLIC, anon;

REVOKE EXECUTE ON FUNCTION public.admin_top_users(text, integer) FROM PUBLIC, anon;

REVOKE EXECUTE ON FUNCTION public.admin_soft_delete_user(uuid) FROM PUBLIC, anon;

REVOKE EXECUTE ON FUNCTION public.admin_restore_user(uuid) FROM PUBLIC, anon;

REVOKE EXECUTE ON FUNCTION public.admin_hard_delete_user(uuid) FROM PUBLIC, anon;

GRANT EXECUTE ON FUNCTION public.admin_user_analytics() TO authenticated;

GRANT EXECUTE ON FUNCTION public.admin_top_users(text, integer) TO authenticated;

GRANT EXECUTE ON FUNCTION public.admin_soft_delete_user(uuid) TO authenticated;

GRANT EXECUTE ON FUNCTION public.admin_restore_user(uuid) TO authenticated;

GRANT EXECUTE ON FUNCTION public.admin_hard_delete_user(uuid) TO authenticated;

GRANT SELECT, INSERT ON public.activity_events TO authenticated;

GRANT ALL ON public.activity_events TO service_role;

REVOKE EXECUTE ON FUNCTION public.admin_get_db_size() FROM anon, public;

REVOKE EXECUTE ON FUNCTION public.admin_get_table_sizes() FROM anon, public;

REVOKE EXECUTE ON FUNCTION public.admin_hard_delete_user(uuid) FROM anon, public;

REVOKE EXECUTE ON FUNCTION public.admin_restore_user(uuid) FROM anon, public;

REVOKE EXECUTE ON FUNCTION public.admin_soft_delete_user(uuid) FROM anon, public;

REVOKE EXECUTE ON FUNCTION public.admin_user_analytics() FROM anon, public;

REVOKE EXECUTE ON FUNCTION public.admin_activity_overview(integer) FROM anon, public;

REVOKE EXECUTE ON FUNCTION public.admin_top_buttons(integer, integer) FROM anon, public;

REVOKE EXECUTE ON FUNCTION public.admin_user_activity(uuid, integer) FROM anon, public;

REVOKE EXECUTE ON FUNCTION public.admin_top_users(text, integer) FROM anon, public;

REVOKE EXECUTE ON FUNCTION public.admin_top_pages(integer, integer) FROM anon, public;

REVOKE EXECUTE ON FUNCTION public.admin_top_modules(integer, integer) FROM anon, public;

REVOKE EXECUTE ON FUNCTION public.admin_activity_timeseries(integer, integer) FROM anon, public;

GRANT EXECUTE ON FUNCTION public.admin_activity_overview(integer) TO authenticated;

GRANT EXECUTE ON FUNCTION public.admin_top_buttons(integer, integer) TO authenticated;

GRANT EXECUTE ON FUNCTION public.admin_top_pages(integer, integer) TO authenticated;

GRANT EXECUTE ON FUNCTION public.admin_top_modules(integer, integer) TO authenticated;

GRANT EXECUTE ON FUNCTION public.admin_activity_timeseries(integer, integer) TO authenticated;

GRANT EXECUTE ON FUNCTION public.admin_user_activity(uuid, integer) TO authenticated;

GRANT SELECT, INSERT, UPDATE ON public.study_sessions TO authenticated;

GRANT ALL ON public.study_sessions TO service_role;

GRANT SELECT ON public.site_pages TO anon;

GRANT SELECT, INSERT, UPDATE, DELETE ON public.site_pages TO authenticated;

GRANT ALL ON public.site_pages TO service_role;

GRANT SELECT ON public.site_page_sections TO anon;

GRANT SELECT, INSERT, UPDATE, DELETE ON public.site_page_sections TO authenticated;

GRANT ALL ON public.site_page_sections TO service_role;

-- Permissions: only authenticated callers (admin gate is inside the functions)
REVOKE ALL ON FUNCTION public.admin_list_public_tables() FROM public;

REVOKE ALL ON FUNCTION public.admin_table_metadata(text) FROM public;

REVOKE ALL ON FUNCTION public.admin_run_select_query(text, int) FROM public;

REVOKE ALL ON FUNCTION public.admin_global_search(text, int) FROM public;

GRANT EXECUTE ON FUNCTION public.admin_list_public_tables() TO authenticated, service_role;

GRANT EXECUTE ON FUNCTION public.admin_table_metadata(text) TO authenticated, service_role;

GRANT EXECUTE ON FUNCTION public.admin_run_select_query(text, int) TO authenticated, service_role;

GRANT EXECUTE ON FUNCTION public.admin_global_search(text, int) TO authenticated, service_role;

REVOKE ALL ON FUNCTION public._lovable_import_exec(text) FROM PUBLIC, anon, authenticated;

GRANT EXECUTE ON FUNCTION public._lovable_import_exec(text) TO service_role;

GRANT SELECT, INSERT, UPDATE, DELETE ON public.role_permissions TO authenticated;

GRANT ALL ON public.role_permissions TO service_role;

REVOKE EXECUTE ON FUNCTION public.has_permission(uuid, text) FROM PUBLIC, anon;

GRANT EXECUTE ON FUNCTION public.has_permission(uuid, text) TO authenticated, service_role;

GRANT SELECT, INSERT ON public.admin_action_log TO authenticated;

GRANT ALL ON public.admin_action_log TO service_role;

-- ------------------------------------------------------------
-- Migration: 20260608175734_89957c0f-4927-497b-bc6f-678c54762f52.sql
-- ------------------------------------------------------------
GRANT EXECUTE ON FUNCTION public.has_role(uuid, public.app_role) TO authenticated, anon;

GRANT SELECT ON public.user_roles TO authenticated;

GRANT ALL ON public.user_roles TO service_role;

GRANT SELECT, INSERT, UPDATE, DELETE ON public.editor_pages TO authenticated;

GRANT ALL ON public.editor_pages TO service_role;

GRANT SELECT, INSERT ON public.editor_snapshots TO authenticated;

GRANT ALL ON public.editor_snapshots TO service_role;

GRANT SELECT, INSERT ON public.editor_actions_log TO authenticated;

GRANT ALL ON public.editor_actions_log TO service_role;

GRANT SELECT ON public.editor_published_pages TO anon, authenticated;

GRANT ALL ON public.editor_published_pages TO service_role;

REVOKE ALL ON FUNCTION public.editor_publish_page(text, uuid, uuid, jsonb, text) FROM public;

GRANT EXECUTE ON FUNCTION public.editor_publish_page(text, uuid, uuid, jsonb, text) TO authenticated;

GRANT SELECT ON public.module_visibility TO anon, authenticated;

GRANT SELECT, UPDATE ON public.module_visibility TO authenticated;

GRANT ALL ON public.module_visibility TO service_role;

-- ------------------------------------------------------------
-- Migration: 20260609044045_6521e6bd-5d4b-4b36-b8d9-dfbdf52fe05b.sql
-- ------------------------------------------------------------
-- (skipped: orphan fragment of split bootstrap migration)

-- ------------------------------------------------------------
-- Migration: 20260609044117_61e51541-75c3-4d81-b4cf-389d9705e35d.sql
-- ------------------------------------------------------------
GRANT USAGE, CREATE ON SCHEMA public TO service_role;

GRANT ALL ON ALL TABLES IN SCHEMA public TO service_role;

GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO service_role;

-- 2. Revoke EXECUTE from anon on every admin-only function. The in-function
--    has_role(auth.uid(),'admin') check already blocks non-admins, but
--    revoking at the grant layer means anonymous (signed-out) requests are
--    rejected before the function body ever runs.
DO $$
DECLARE
  fn record;

BEGIN
  FOR fn IN
    SELECT n.nspname AS schema_name, p.proname AS func_name,
           pg_get_function_identity_arguments(p.oid) AS args
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public'
      AND (p.proname LIKE 'admin\_%' ESCAPE '\'
           OR p.proname IN ('editor_publish_page','claim_user_session'))
  LOOP
    EXECUTE format('REVOKE EXECUTE ON FUNCTION %I.%I(%s) FROM PUBLIC, anon;',
                   fn.schema_name, fn.func_name, fn.args);

EXECUTE format('GRANT  EXECUTE ON FUNCTION %I.%I(%s) TO authenticated;',
                   fn.schema_name, fn.func_name, fn.args);

END LOOP;

END $$;

GRANT SELECT, INSERT, UPDATE ON public.system_error_logs TO authenticated;

GRANT INSERT ON public.system_error_logs TO anon;

GRANT ALL ON public.system_error_logs TO service_role;

REVOKE EXECUTE ON FUNCTION public.admin_log_system_error(TEXT,TEXT,TEXT,TEXT,TEXT,TEXT,JSONB,TEXT) FROM PUBLIC;

GRANT EXECUTE ON FUNCTION public.admin_log_system_error(TEXT,TEXT,TEXT,TEXT,TEXT,TEXT,JSONB,TEXT) TO anon, authenticated;

-- ------------------------------------------------------------
-- Migration: 20260609154435_c29fd268-9556-48c5-b1ff-448a15a43a10.sql
-- ------------------------------------------------------------
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'sandbox_exec') THEN
    CREATE ROLE sandbox_exec NOLOGIN;
  END IF;
END $$;

GRANT USAGE, CREATE ON SCHEMA public TO sandbox_exec;

GRANT ALL ON ALL TABLES IN SCHEMA public TO sandbox_exec;

GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO sandbox_exec;

GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO sandbox_exec;

-- ------------------------------------------------------------
-- Migration: 20260609154505_5baaeb0a-71c3-4640-b550-e68e24e6923e.sql
-- ------------------------------------------------------------
GRANT USAGE ON SCHEMA auth TO sandbox_exec;

GRANT SELECT ON ALL TABLES IN SCHEMA auth TO sandbox_exec;

GRANT REFERENCES ON ALL TABLES IN SCHEMA auth TO sandbox_exec;

REVOKE ALL ON FUNCTION public._tmp_exec_sql(text) FROM PUBLIC, anon, authenticated;

GRANT EXECUTE ON FUNCTION public._tmp_exec_sql(text) TO service_role;

-- ------------------------------------------------------------
-- Migration: 20260609175152_ccb4c308-28fb-42d0-9008-7ac1b85bae10.sql
-- ------------------------------------------------------------
GRANT SELECT ON public.user_roles TO authenticated;

GRANT ALL ON public.user_roles TO service_role;

GRANT SELECT ON public.profiles TO authenticated;

GRANT INSERT, UPDATE ON public.profiles TO authenticated;

GRANT ALL ON public.profiles TO service_role;

GRANT SELECT ON public.user_sessions TO authenticated;

GRANT ALL ON public.user_sessions TO service_role;

GRANT SELECT ON public.homepage_sections TO anon;

GRANT SELECT, INSERT, UPDATE, DELETE ON public.homepage_sections TO authenticated;

GRANT ALL ON public.homepage_sections TO service_role;

GRANT SELECT ON public.site_settings TO anon;

GRANT SELECT, INSERT, UPDATE, DELETE ON public.site_settings TO authenticated;

GRANT ALL ON public.site_settings TO service_role;

GRANT SELECT ON public.media_assets TO anon;

GRANT SELECT, INSERT, UPDATE, DELETE ON public.media_assets TO authenticated;

GRANT ALL ON public.media_assets TO service_role;

GRANT SELECT ON public.site_pages TO anon;

GRANT SELECT, INSERT, UPDATE, DELETE ON public.site_pages TO authenticated;

GRANT ALL ON public.site_pages TO service_role;

GRANT SELECT, INSERT, UPDATE, DELETE ON public.content_versions TO authenticated;

GRANT ALL ON public.content_versions TO service_role;

-- ------------------------------------------------------------
-- Migration: 20260610120000_security_hardening.sql
-- ------------------------------------------------------------
-- ===================================================================
-- SECURITY-AUDIT HARDENING MIGRATION
-- ===================================================================
-- This project uses an externally-managed Supabase project (not Lovable
-- Cloud), so this SQL is NOT auto-applied. Run it manually in the
-- Supabase SQL editor for project `rspkzydnpxyrucdvgbte`.
--
-- Findings consolidated from parallel auth / RLS / data-leak audits.
-- Each block is idempotent and safe to re-run.
-- ===================================================================

-- C-1 / H-4: Revoke privileged role-lookup RPCs from anon.
-- has_role / has_permission are SECURITY DEFINER, so granting EXECUTE to
-- anon made them enumeration oracles for unauthenticated callers.
REVOKE EXECUTE ON FUNCTION public.has_role(uuid, public.app_role) FROM anon, PUBLIC;

GRANT  EXECUTE ON FUNCTION public.has_role(uuid, public.app_role) TO authenticated, service_role;

REVOKE EXECUTE ON FUNCTION public.has_permission(uuid, text) FROM anon, PUBLIC;

GRANT  EXECUTE ON FUNCTION public.has_permission(uuid, text) TO authenticated, service_role;

REVOKE EXECUTE ON FUNCTION public.record_admin_action(text, text, boolean, jsonb) FROM PUBLIC, anon;

GRANT  EXECUTE ON FUNCTION public.record_admin_action(text, text, boolean, jsonb) TO authenticated, service_role;

REVOKE INSERT ON public.admin_action_log FROM authenticated, anon;

GRANT  INSERT ON public.admin_action_log TO service_role;

-- ------------------------------------------------------------
-- Migration: 20260611145417_366ec833-847a-420e-98f8-7302d64c5386.sql
-- ------------------------------------------------------------
-- (skipped: orphan END;/$$; for already-dropped _bootstrap_exec)

-- (skipped: GRANT/REVOKE on already-dropped _bootstrap_exec)

GRANT SELECT, INSERT, UPDATE ON public.system_error_logs TO authenticated;

GRANT INSERT ON public.system_error_logs TO anon;

GRANT ALL ON public.system_error_logs TO service_role;

REVOKE EXECUTE ON FUNCTION public.admin_log_system_error(TEXT,TEXT,TEXT,TEXT,TEXT,TEXT,JSONB,TEXT) FROM PUBLIC;

GRANT EXECUTE ON FUNCTION public.admin_log_system_error(TEXT,TEXT,TEXT,TEXT,TEXT,TEXT,JSONB,TEXT) TO anon, authenticated;

-- part 55: sandbox grants
GRANT USAGE, CREATE ON SCHEMA public TO sandbox_exec;

GRANT ALL ON ALL TABLES IN SCHEMA public TO sandbox_exec;

GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO sandbox_exec;

GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO sandbox_exec;

REVOKE ALL ON FUNCTION public._tmp_exec_sql(text) FROM PUBLIC, anon, authenticated;

GRANT EXECUTE ON FUNCTION public._tmp_exec_sql(text) TO service_role;

-- part 58: explicit grants
GRANT SELECT ON public.user_roles TO authenticated;

GRANT ALL ON public.user_roles TO service_role;

GRANT SELECT ON public.profiles TO authenticated;

GRANT INSERT, UPDATE ON public.profiles TO authenticated;

GRANT ALL ON public.profiles TO service_role;

GRANT SELECT ON public.user_sessions TO authenticated;

GRANT ALL ON public.user_sessions TO service_role;

GRANT SELECT ON public.homepage_sections TO anon;

GRANT SELECT, INSERT, UPDATE, DELETE ON public.homepage_sections TO authenticated;

GRANT ALL ON public.homepage_sections TO service_role;

GRANT SELECT ON public.site_settings TO anon;

GRANT SELECT, INSERT, UPDATE, DELETE ON public.site_settings TO authenticated;

GRANT ALL ON public.site_settings TO service_role;

GRANT SELECT ON public.media_assets TO anon;

GRANT SELECT, INSERT, UPDATE, DELETE ON public.media_assets TO authenticated;

GRANT ALL ON public.media_assets TO service_role;

GRANT SELECT ON public.site_pages TO anon;

GRANT SELECT, INSERT, UPDATE, DELETE ON public.site_pages TO authenticated;

GRANT ALL ON public.site_pages TO service_role;

GRANT SELECT, INSERT, UPDATE, DELETE ON public.content_versions TO authenticated;

GRANT ALL ON public.content_versions TO service_role;

REVOKE ALL ON public.site_settings FROM anon;

GRANT SELECT (id, key, published_value, published_at, updated_at, created_at) ON public.site_settings TO anon;

GRANT SELECT ON public.site_settings TO authenticated;

GRANT ALL ON public.site_settings TO service_role;

REVOKE SELECT ON public.mcqs FROM anon;

GRANT SELECT ON public.blog_categories TO anon;

GRANT SELECT, INSERT, UPDATE, DELETE ON public.blog_categories TO authenticated;

GRANT ALL ON public.blog_categories TO service_role;

GRANT SELECT ON public.blog_tags TO anon;

GRANT SELECT, INSERT, UPDATE, DELETE ON public.blog_tags TO authenticated;

GRANT ALL ON public.blog_tags TO service_role;

GRANT SELECT ON public.blog_posts TO anon;

GRANT SELECT, INSERT, UPDATE, DELETE ON public.blog_posts TO authenticated;

GRANT ALL ON public.blog_posts TO service_role;

GRANT SELECT ON public.blog_post_tags TO anon;

GRANT SELECT, INSERT, UPDATE, DELETE ON public.blog_post_tags TO authenticated;

GRANT ALL ON public.blog_post_tags TO service_role;

GRANT INSERT ON public.blog_views TO anon, authenticated;

GRANT SELECT ON public.blog_views TO authenticated;

GRANT ALL ON public.blog_views TO service_role;

GRANT USAGE, SELECT ON SEQUENCE public.blog_views_id_seq TO anon, authenticated;

REVOKE ALL ON FUNCTION public.blog_increment_view(UUID) FROM PUBLIC;

GRANT EXECUTE ON FUNCTION public.blog_increment_view(UUID) TO anon, authenticated;

GRANT SELECT, INSERT, UPDATE, DELETE ON public.admin_notes TO authenticated;

GRANT ALL ON public.admin_notes TO service_role;

GRANT SELECT, INSERT, UPDATE, DELETE ON public.user_tags TO authenticated;

GRANT ALL ON public.user_tags TO service_role;

GRANT SELECT, INSERT, UPDATE, DELETE ON public.user_messages TO authenticated;

GRANT ALL ON public.user_messages TO service_role;

GRANT SELECT, INSERT, UPDATE, DELETE ON public.user_bans TO authenticated;

GRANT ALL ON public.user_bans TO service_role;

REVOKE EXECUTE ON FUNCTION public.is_user_banned(uuid) FROM PUBLIC, anon;

GRANT  EXECUTE ON FUNCTION public.is_user_banned(uuid) TO authenticated, service_role;

GRANT SELECT ON public.auth_access_controls TO anon, authenticated;

GRANT ALL ON public.auth_access_controls TO service_role;

REVOKE ALL ON FUNCTION public.get_auth_access_controls() FROM PUBLIC;

GRANT EXECUTE ON FUNCTION public.get_auth_access_controls() TO anon, authenticated, service_role;

REVOKE ALL ON FUNCTION public.update_auth_access_controls(jsonb) FROM PUBLIC;

GRANT EXECUTE ON FUNCTION public.update_auth_access_controls(jsonb) TO authenticated, service_role;

-- ------------------------------------------------------------
-- Migration: 20260613090000_security_hardening_audit_fixes.sql
-- ------------------------------------------------------------
-- =====================================================================
-- Security hardening — audit fixes A-1, A-4, A-5
-- =====================================================================

-- A-1: Lock down get_auth_access_controls EXECUTE.
-- The RPC is invoked from a public server fn using the anon client, so anon
-- still needs EXECUTE, but PUBLIC must be revoked to prevent unintended grants.
REVOKE ALL ON FUNCTION public.get_auth_access_controls() FROM PUBLIC;

GRANT EXECUTE ON FUNCTION public.get_auth_access_controls() TO anon, authenticated, service_role;

-- A-4: Stop anonymous clients from writing arbitrary rows into
-- system_error_logs. Authenticated inserts (scoped to auth.uid()) and the
-- SECURITY DEFINER admin_log_system_error() helper remain available.
REVOKE INSERT ON public.system_error_logs FROM anon;


-- =================== 11. REALTIME PUBLICATIONS ====

DO $$
BEGIN
  IF to_regclass('public.user_sessions') IS NOT NULL
     AND EXISTS (SELECT 1 FROM pg_publication WHERE pubname = 'supabase_realtime')
     AND NOT EXISTS (
       SELECT 1 FROM pg_publication_tables
       WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'user_sessions'
     ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.user_sessions;
  END IF;
EXCEPTION WHEN duplicate_object OR undefined_object THEN NULL;
END $$;

DO $$ BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE public.activity_events;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$
BEGIN
  IF to_regclass('public.user_sessions') IS NOT NULL
     AND EXISTS (SELECT 1 FROM pg_publication WHERE pubname = 'supabase_realtime')
     AND NOT EXISTS (
       SELECT 1 FROM pg_publication_tables
       WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'user_sessions'
     ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.user_sessions;
  END IF;
EXCEPTION WHEN duplicate_object OR undefined_object THEN NULL;
END $$;

DO $$ BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE public.activity_events;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE public.user_sessions;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$
BEGIN
  IF to_regclass('public.user_sessions') IS NOT NULL
     AND EXISTS (SELECT 1 FROM pg_publication WHERE pubname = 'supabase_realtime')
     AND NOT EXISTS (
       SELECT 1 FROM pg_publication_tables
       WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'user_sessions'
     ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.user_sessions;
  END IF;
EXCEPTION WHEN duplicate_object OR undefined_object THEN NULL;
END $$;

DO $$ BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE public.activity_events;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- ============================================================
-- REALTIME
-- ============================================================
DO $$
BEGIN
  IF to_regclass('public.notifications') IS NOT NULL
     AND EXISTS (SELECT 1 FROM pg_publication WHERE pubname = 'supabase_realtime')
     AND NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname='supabase_realtime' AND schemaname='public' AND tablename='notifications') THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;
  END IF;
EXCEPTION WHEN duplicate_object OR undefined_object THEN NULL;
END $$;

DO $$
BEGIN
  IF to_regclass('public.notification_reads') IS NOT NULL
     AND EXISTS (SELECT 1 FROM pg_publication WHERE pubname = 'supabase_realtime')
     AND NOT EXISTS (
       SELECT 1 FROM pg_publication_tables
       WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'notification_reads'
     ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.notification_reads;
  END IF;
EXCEPTION WHEN duplicate_object OR undefined_object THEN NULL;
END $$;

DO $$
BEGIN
  IF to_regclass('public.exam_attempts') IS NOT NULL
     AND EXISTS (SELECT 1 FROM pg_publication WHERE pubname = 'supabase_realtime')
     AND NOT EXISTS (
       SELECT 1 FROM pg_publication_tables
       WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'exam_attempts'
     ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.exam_attempts;
  END IF;
EXCEPTION WHEN duplicate_object OR undefined_object THEN NULL;
END $$;

DO $$
BEGIN
  IF to_regclass('public.activity_events') IS NOT NULL
     AND EXISTS (SELECT 1 FROM pg_publication WHERE pubname = 'supabase_realtime')
     AND NOT EXISTS (
       SELECT 1 FROM pg_publication_tables
       WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'activity_events'
     ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.activity_events;
  END IF;
EXCEPTION WHEN duplicate_object OR undefined_object THEN NULL;
END $$;

DO $$
BEGIN
  IF to_regclass('public.user_login_events') IS NOT NULL
     AND EXISTS (SELECT 1 FROM pg_publication WHERE pubname = 'supabase_realtime')
     AND NOT EXISTS (
       SELECT 1 FROM pg_publication_tables
       WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'user_login_events'
     ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.user_login_events;
  END IF;
EXCEPTION WHEN duplicate_object OR undefined_object THEN NULL;
END $$;

DO $$
BEGIN
  IF to_regclass('public.user_sessions') IS NOT NULL
     AND EXISTS (SELECT 1 FROM pg_publication WHERE pubname = 'supabase_realtime')
     AND NOT EXISTS (
       SELECT 1 FROM pg_publication_tables
       WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'user_sessions'
     ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.user_sessions;
  END IF;
EXCEPTION WHEN duplicate_object OR undefined_object THEN NULL;
END $$;

DO $$
BEGIN
  IF to_regclass('public.module_visibility') IS NOT NULL
     AND EXISTS (SELECT 1 FROM pg_publication WHERE pubname = 'supabase_realtime')
     AND NOT EXISTS (
       SELECT 1 FROM pg_publication_tables
       WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'module_visibility'
     ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.module_visibility;
  END IF;
EXCEPTION WHEN duplicate_object OR undefined_object THEN NULL;
END $$;

DO $$
BEGIN
  IF to_regclass('public.user_sessions') IS NOT NULL
     AND EXISTS (SELECT 1 FROM pg_publication WHERE pubname = 'supabase_realtime')
     AND NOT EXISTS (
       SELECT 1 FROM pg_publication_tables
       WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'user_sessions'
     ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.user_sessions;
  END IF;
EXCEPTION WHEN duplicate_object OR undefined_object THEN NULL;
END $$;

DO $$ BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE public.activity_events;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'role_permissions'
  ) THEN
    EXECUTE 'ALTER PUBLICATION supabase_realtime ADD TABLE public.role_permissions';
  END IF;
END $$;

-- ---------- Realtime ----------
DO $$ BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE public.editor_pages;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE public.editor_snapshots;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE public.editor_published_pages;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- M-5: role_permissions must NOT be in the realtime publication.
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
      AND schemaname = 'public' AND tablename = 'role_permissions'
  ) THEN
    EXECUTE 'ALTER PUBLICATION supabase_realtime DROP TABLE public.role_permissions';

END IF;

END $$;

DO $$ BEGIN
  BEGIN ALTER PUBLICATION supabase_realtime DROP TABLE public.role_permissions;

EXCEPTION WHEN OTHERS THEN NULL;

END;

BEGIN ALTER PUBLICATION supabase_realtime DROP TABLE public.user_sessions;

EXCEPTION WHEN OTHERS THEN NULL;

END;

BEGIN ALTER PUBLICATION supabase_realtime DROP TABLE public.user_login_events;

EXCEPTION WHEN OTHERS THEN NULL;

END;

BEGIN ALTER PUBLICATION supabase_realtime DROP TABLE public.activity_events;

EXCEPTION WHEN OTHERS THEN NULL;

END;

END $$;

DO $$
BEGIN
  BEGIN
    EXECUTE 'ALTER PUBLICATION supabase_realtime ADD TABLE public.auth_access_controls';

EXCEPTION
    WHEN duplicate_object THEN NULL;

WHEN undefined_object THEN NULL;

END;

END $$;


-- =================== 12. MISC DO BLOCKS ===========

-- ============================================================
-- Signature-change guard: drop ALL overloads of analytics
-- functions whose return types/parameters changed across
-- migrations. Required because CREATE OR REPLACE FUNCTION
-- cannot change return type or OUT parameters.
-- ============================================================
DO $signature_guard$
DECLARE r record;
BEGIN
  FOR r IN
    SELECT n.nspname AS schema_name, p.proname AS func_name,
           pg_get_function_identity_arguments(p.oid) AS args
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public'
      AND p.proname IN (
        'admin_activity_timeseries',
        'admin_activity_overview',
        'admin_user_activity',
        'admin_top_users',
        'admin_top_pages',
        'admin_top_modules',
        'admin_top_buttons',
        'admin_run_select_query'
      )
  LOOP
    EXECUTE format('DROP FUNCTION IF EXISTS %I.%I(%s) CASCADE;',
                   r.schema_name, r.func_name, r.args);
  END LOOP;
END
$signature_guard$;


-- =================== 13. OTHER ====================

-- ------------------------------------------------------------
-- Migration: 20260608041553_919fdd72-1d39-4205-8781-ab37188b12f3.sql
-- ------------------------------------------------------------
SELECT 1;

-- ------------------------------------------------------------
-- Migration: 20260609032640_e69d4a08-4eee-4858-a898-6e38077ca437.sql
-- ------------------------------------------------------------
-- See /tmp/all_migrations.sql; passing inline below

-- ------------------------------------------------------------
-- Migration: 20260609032722_975a1b34-c0c9-4722-951e-5338a713f1d5.sql
-- ------------------------------------------------------------
SELECT 1;

ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO service_role;

ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO service_role;

ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO sandbox_exec;

ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO sandbox_exec;

ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON FUNCTIONS TO sandbox_exec;

ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TYPES TO sandbox_exec;

ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO sandbox_exec;

ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO sandbox_exec;

ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON FUNCTIONS TO sandbox_exec;

ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TYPES TO sandbox_exec;


-- =================== 15. DML (idempotent upserts) =

INSERT INTO public.blog_categories (slug, name, description, sort_order)
VALUES ('general', 'General', 'General articles and announcements', 0)
ON CONFLICT (slug) DO NOTHING;

INSERT INTO public.auth_access_controls (id) VALUES (1)
ON CONFLICT (id) DO NOTHING;
