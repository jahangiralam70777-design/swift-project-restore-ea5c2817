
SET search_path = public;

DELETE FROM auth.users WHERE email LIKE 'seed+%@caaspirebd.test';
DELETE FROM public.notifications WHERE title LIKE '[seed]%';
DELETE FROM public.question_bank_resources WHERE title LIKE '[seed]%';
DELETE FROM public.short_notes WHERE title LIKE '[seed]%';
DELETE FROM public.flash_cards WHERE front LIKE '[seed]%';
DELETE FROM public.quizzes WHERE title LIKE '[seed]%';
DELETE FROM public.mcqs WHERE question LIKE '[seed]%';
DELETE FROM public.chapters WHERE slug LIKE 'seed-%';
DELETE FROM public.subjects WHERE slug LIKE 'seed-%';

INSERT INTO public.subjects (id, name, slug, level, description, color, sort_order, status) VALUES
  ('11111111-0000-0000-0000-000000000001','Principles & Practice of Accounting','seed-foundation-accounting','foundation','Foundation of double-entry accounting','#6366f1',1,'published'),
  ('11111111-0000-0000-0000-000000000002','Business Laws','seed-foundation-laws','foundation','Indian Contract Act, Sale of Goods Act','#10b981',2,'published'),
  ('11111111-0000-0000-0000-000000000003','Business Mathematics & Statistics','seed-foundation-maths','foundation','Quant aptitude for CA aspirants','#f59e0b',3,'published'),
  ('11111111-0000-0000-0000-000000000004','Business Economics','seed-foundation-economics','foundation','Micro & macro economics','#ef4444',4,'published'),
  ('22222222-0000-0000-0000-000000000001','Advanced Accounting','seed-inter-advanced-accounting','intermediate','Partnership, branch & departmental accounts','#8b5cf6',5,'published'),
  ('22222222-0000-0000-0000-000000000002','Corporate & Other Laws','seed-inter-corporate-laws','intermediate','Companies Act 2013','#06b6d4',6,'published');

INSERT INTO public.chapters (id, subject_id, name, slug, sort_order, status)
SELECT
  ('00000000-0000-0000-' || lpad(s.idx::text, 4, '0') || '-' || lpad(c::text, 12, '0'))::uuid,
  s.id, s.name || ' — Chapter ' || c,
  'seed-' || s.slug_short || '-ch-' || c, c, 'published'
FROM (VALUES
    ('11111111-0000-0000-0000-000000000001'::uuid, 1, 'Accounting Basics', 'acct'),
    ('11111111-0000-0000-0000-000000000002'::uuid, 2, 'Business Laws', 'laws'),
    ('11111111-0000-0000-0000-000000000003'::uuid, 3, 'Maths & Stats', 'maths'),
    ('11111111-0000-0000-0000-000000000004'::uuid, 4, 'Economics', 'econ'),
    ('22222222-0000-0000-0000-000000000001'::uuid, 5, 'Advanced Accounting', 'advacct'),
    ('22222222-0000-0000-0000-000000000002'::uuid, 6, 'Corporate Laws', 'corp')
) AS s(id, idx, name, slug_short)
CROSS JOIN generate_series(1, 6) AS c;

INSERT INTO public.mcqs (chapter_id, question, option_a, option_b, option_c, option_d, correct_option, explanation, difficulty, tags, status)
SELECT
  c.id,
  '[seed] Q' || n || ' — Which best describes concept #' || n || ' in ' || c.name || '?',
  'Option A for concept ' || n,'Option B for concept ' || n,'Option C for concept ' || n,'Option D for concept ' || n,
  (ARRAY['A','B','C','D']::mcq_option[])[1 + (n % 4)],
  'Explanation for principle ' || n || '.',
  (ARRAY['easy','medium','medium','hard']::difficulty[])[1 + (n % 4)],
  ARRAY['seed'], 'published'
FROM public.chapters c CROSS JOIN generate_series(1, 34) AS n
WHERE c.slug LIKE 'seed-%';

-- 120 students. encrypted_password is a static bcrypt hash for "SeedPass123!"
INSERT INTO auth.users (id, instance_id, email, encrypted_password, email_confirmed_at,
                        raw_user_meta_data, raw_app_meta_data, aud, role,
                        created_at, updated_at, last_sign_in_at)
SELECT
  ('aaaaaaaa-0000-0000-0000-' || lpad(n::text, 12, '0'))::uuid,
  '00000000-0000-0000-0000-000000000000'::uuid,
  'seed+student' || n || '@caaspirebd.test',
  '$2a$10$abcdefghijklmnopqrstuuJ.UnTBg5fwfH4kPGqgZAhO5DKL8Z6Iu',
  CASE WHEN n % 7 = 0 THEN NULL ELSE now() - ((n*3) % 60) * interval '1 day' END,
  jsonb_build_object(
    'display_name',
      (ARRAY['Aarav','Vivaan','Aditya','Vihaan','Arjun','Sai','Reyansh','Krishna','Ishaan','Rohan',
             'Ananya','Diya','Saanvi','Pari','Aadhya','Anaya','Avani','Myra','Sara','Ira'])[1+((n-1)%20)]
      || ' ' ||
      (ARRAY['Sharma','Verma','Iyer','Patel','Kumar','Singh','Das','Roy','Bose','Khan'])[1+((n-1)%10)],
    'level', (ARRAY['foundation','foundation','foundation','intermediate','intermediate','professional'])[1+(n%6)]
  ),
  '{"provider":"email","providers":["email"]}'::jsonb,
  'authenticated','authenticated',
  now() - (30 + (n*2) % 120) * interval '1 day',
  now() - ((n*5) % 30) * interval '1 day',
  now() - ((n*2) % 7) * interval '1 day'
FROM generate_series(1, 120) AS n;

UPDATE public.profiles p
SET
  status = CASE WHEN (t.h % 13) = 0 THEN 'suspended'::profile_status
                WHEN (t.h % 11) = 0 THEN 'pending'::profile_status
                ELSE 'active'::profile_status END,
  referral_source = (ARRAY['google','facebook','friend','youtube','instagram','organic','linkedin'])[1 + (abs(t.h) % 7)],
  phone = '+8801' || lpad((100000000 + abs(t.h) % 800000000)::text, 9, '0'),
  total_login_count = 5 + abs(t.h) % 80,
  total_usage_seconds = 600 + (abs(t.h) % 50) * 1800,
  last_login_at = now() - (abs(t.h) % 14) * interval '1 day',
  created_at = now() - (30 + abs(t.h) % 120) * interval '1 day'
FROM (
  SELECT id, ('x' || substr(md5(id::text), 1, 7))::bit(28)::int AS h
  FROM public.profiles WHERE id::text LIKE 'aaaaaaaa-%'
) t
WHERE p.id = t.id;

INSERT INTO public.user_login_events (user_id, login_at, logout_at, duration_seconds, user_agent, browser, device, ip)
SELECT
  u.id,
  now() - d * interval '1 day' - (d % 8) * interval '1 hour',
  now() - d * interval '1 day' - (d % 8) * interval '1 hour' + (300 + ((d*97) % 5400)) * interval '1 second',
  300 + ((d*97) % 5400),
  'Mozilla/5.0',
  (ARRAY['Chrome','Safari','Firefox','Edge'])[1 + (d % 4)],
  (ARRAY['desktop','mobile','tablet'])[1 + (d % 3)],
  '203.0.113.' || (d % 250 + 1)
FROM auth.users u
CROSS JOIN generate_series(0, 59) AS d
WHERE u.email LIKE 'seed+%@caaspirebd.test'
  AND (('x' || substr(md5(u.id::text || d::text),1,4))::bit(16)::int % 5) = 0;

INSERT INTO public.activity_events (user_id, event_type, module, page_path, element_label, target_id, target_kind, browser, device, created_at, meta)
SELECT
  u.id,
  (ARRAY['page_view','page_view','page_view','click','click','mcq_attempt','quiz_attempt','mock_attempt','download','login'])[1 + (n % 10)],
  (ARRAY['mcq','quiz','mock_test','flash_cards','short_notes','question_bank','dashboard','profile'])[1 + (n % 8)],
  (ARRAY['/dashboard','/mcq-practice','/quiz','/mock-test','/flash-cards','/short-notes','/qns-bank','/notifications'])[1 + (n % 8)],
  (ARRAY['Start','Submit','Next','Bookmark','Download','Open','Filter','Sort'])[1 + (n % 8)],
  'el-' || (n % 50), 'button',
  (ARRAY['Chrome','Safari','Firefox','Edge'])[1 + (n % 4)],
  (ARRAY['desktop','mobile','tablet'])[1 + (n % 3)],
  now() - ((n*13) % 45) * interval '1 day' - ((n*97) % 86400) * interval '1 second',
  jsonb_build_object('seed', true, 'n', n)
FROM auth.users u CROSS JOIN generate_series(1, 100) AS n
WHERE u.email LIKE 'seed+%@caaspirebd.test';

INSERT INTO public.activity_events (user_id, event_type, module, page_path, created_at)
SELECT u.id,'page_view','dashboard','/dashboard',
       now() - ((('x' || substr(md5(u.id::text),1,3))::bit(12)::int) % 60) * interval '1 minute'
FROM auth.users u
WHERE u.email LIKE 'seed+%@caaspirebd.test'
  AND (('x' || substr(md5(u.id::text),1,4))::bit(16)::int % 3) = 0;

INSERT INTO public.quizzes (id, title, description, level, subject_id, chapter_id, kind, status, difficulty, total_questions, duration_seconds)
SELECT
  ('cccccccc-0000-0000-' || lpad(c.rn::text, 4, '0') || '-' || lpad(k::text, 12, '0'))::uuid,
  '[seed] ' || c.name || ' — ' || (CASE WHEN k=1 THEN 'Quick Quiz' ELSE 'Mock Test' END),
  'Auto-generated practice for ' || c.name,
  s.level, c.subject_id, c.id,
  (CASE WHEN k=1 THEN 'quiz' ELSE 'mock' END)::quiz_kind,
  'published',
  (ARRAY['easy','medium','hard']::difficulty[])[1 + (c.rn % 3)],
  CASE WHEN k=1 THEN 10 ELSE 30 END,
  CASE WHEN k=1 THEN 900 ELSE 3600 END
FROM (SELECT id, subject_id, name, row_number() OVER (ORDER BY subject_id, sort_order) AS rn FROM public.chapters WHERE slug LIKE 'seed-%') c
JOIN public.subjects s ON s.id = c.subject_id
CROSS JOIN generate_series(1, 2) AS k;

INSERT INTO public.quiz_questions (quiz_id, mcq_id, position)
SELECT q.id, m.id, m.rn
FROM public.quizzes q
JOIN LATERAL (
  SELECT id, row_number() OVER (ORDER BY created_at) AS rn
  FROM public.mcqs WHERE chapter_id = q.chapter_id LIMIT (CASE WHEN q.kind='quiz' THEN 10 ELSE 30 END)
) m ON true
WHERE q.title LIKE '[seed]%';

INSERT INTO public.exam_attempts
  (user_id, quiz_id, kind, subject_id, chapter_id, level, title, attempt_number, status,
   started_at, completed_at, duration_seconds, correct_count, total_count, score, created_at)
SELECT
  u.id, q.id, q.kind::text::attempt_kind, q.subject_id, q.chapter_id, q.level, q.title,
  1 + (n % 3),
  (CASE WHEN n % 9 = 0 THEN 'in_progress' WHEN n % 11 = 0 THEN 'abandoned' ELSE 'completed' END)::attempt_status,
  now() - ((n*7) % 60) * interval '1 day',
  now() - ((n*7) % 60) * interval '1 day' + (q.duration_seconds/2) * interval '1 second',
  q.duration_seconds/2,
  greatest(0, least(q.total_questions, (q.total_questions * (30 + n%60) / 100))),
  q.total_questions,
  ((30 + (n*17) % 65))::numeric,
  now() - ((n*7) % 60) * interval '1 day'
FROM auth.users u
CROSS JOIN LATERAL (
  SELECT * FROM public.quizzes WHERE title LIKE '[seed]%' ORDER BY md5(id::text || u.id::text) LIMIT 5
) q
CROSS JOIN generate_series(1, 1) g(n)
WHERE u.email LIKE 'seed+%@caaspirebd.test';

INSERT INTO public.exam_attempts (user_id, kind, subject_id, chapter_id, level, title, status,
                                   started_at, completed_at, duration_seconds, correct_count, total_count, score)
SELECT
  u.id, 'mcq_practice'::attempt_kind, c.subject_id, c.id, s.level,
  '[seed] Practice — ' || c.name, 'completed'::attempt_status,
  now() - ((('x'||substr(md5(u.id::text||c.id::text),1,4))::bit(16)::int) % 45) * interval '1 day',
  now() - ((('x'||substr(md5(u.id::text||c.id::text),1,4))::bit(16)::int) % 45) * interval '1 day' + 900 * interval '1 second',
  900,
  greatest(0, ((('x'||substr(md5(u.id::text||c.id::text),5,4))::bit(16)::int) % 10)),
  10,
  ((40 + (('x'||substr(md5(u.id::text||c.id::text),5,4))::bit(16)::int) % 55))::numeric
FROM auth.users u
JOIN public.chapters c ON c.slug LIKE 'seed-%'
JOIN public.subjects s ON s.id = c.subject_id
WHERE u.email LIKE 'seed+%@caaspirebd.test'
  AND (('x' || substr(md5(u.id::text || c.id::text),1,4))::bit(16)::int % 6) = 0;

INSERT INTO public.flash_cards (subject_id, chapter_id, level, front, back, card_type, tags, status, view_count)
SELECT c.subject_id, c.id, s.level,
  '[seed] Concept #' || n || ' for ' || c.name,
  'Definition / explanation for concept ' || n || ' in ' || c.name,
  (ARRAY['concept','formula','definition','timeline','diagram'])[1 + (n % 5)]::card_type,
  ARRAY['seed','flash'], 'published', (n * 7) % 200
FROM public.chapters c JOIN public.subjects s ON s.id = c.subject_id
CROSS JOIN generate_series(1,5) AS n WHERE c.slug LIKE 'seed-%';

INSERT INTO public.short_notes (title, summary, level, subject_id, chapter_id, kind, body, tags, status, view_count, download_count)
SELECT '[seed] Notes: ' || c.name || ' (Part ' || n || ')',
       'Concise summary for ' || c.name, s.level, c.subject_id, c.id, 'text'::note_kind,
       'Chapter notes part ' || n || ' for ' || c.name || '.',
       ARRAY['seed','notes'], 'published', (n * 17) % 500, (n * 11) % 120
FROM public.chapters c JOIN public.subjects s ON s.id = c.subject_id
CROSS JOIN generate_series(1,3) AS n WHERE c.slug LIKE 'seed-%';

INSERT INTO public.question_bank_resources (title, summary, level, subject_id, chapter_id, kind, resource_type, body, question_count, tags, status, view_count, download_count)
SELECT '[seed] ' || (ARRAY['PYQ','Model','Important'])[n] || ': ' || c.name,
       'Question bank for ' || c.name, s.level, c.subject_id, c.id, 'text'::note_kind,
       (ARRAY['pyq','model','important'])[n]::qb_resource_type,
       'Curated questions for ' || c.name,
       20 + (n * 5), ARRAY['seed','qb'], 'published', (n * 23) % 400, (n * 9) % 90
FROM public.chapters c JOIN public.subjects s ON s.id = c.subject_id
CROSS JOIN generate_series(1,3) AS n WHERE c.slug LIKE 'seed-%';

INSERT INTO public.notifications (title, body, type, priority, status, audience, recipients_count, read_count, click_count, delivered_count, open_count, sent_at, created_at)
SELECT
  '[seed] ' || (ARRAY['New mock test live','Result announced','Live class today','Holiday notice','Syllabus update',
                       'Scholarship opens','Webinar invite','Practice marathon','Doubt clearing session','Feature update'])[1 + (n % 10)],
  'Important update for all students. Reference #' || n,
  'in_app'::notification_type,
  (ARRAY['low','medium','high','critical'])[1 + (n % 4)]::notification_priority,
  'sent'::notification_status, 'all'::notification_audience,
  120, 20 + (n * 3) % 80, 5 + (n * 2) % 40, 120, 20 + (n * 3) % 80,
  now() - n * interval '2 day', now() - n * interval '2 day'
FROM generate_series(1, 25) AS n;
