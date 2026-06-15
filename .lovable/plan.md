# Live Chat & Broadcast — Implementation Plan

A focused upgrade across the floating launcher, admin chat panel, student composer, and a brand-new Broadcast Messaging system.

## 1. Floating Live Chat launcher (premium, always-readable)

File: `src/components/site/LiveChatWidget.tsx` (+ new settings schema).

- Replace bare circular FAB with a **pill launcher**: icon + label (e.g. `💬 Live Chat`), Intercom/Crisp-style.
- Tokens: `bg-primary text-primary-foreground` with hover glow + ring; explicit `dark:` pair verified.
- Tooltip on hover (`Tooltip` from shadcn) sourced from settings.
- Mobile: collapse to icon only below `sm`, keep tooltip; never blank.
- Pull config from `site_settings.live_chat_widget` (extend existing settings table):
  - `button_text` (default "Live Chat")
  - `tooltip_text`
  - `welcome_text`
  - `icon` enum (`message-circle` | `headphones` | `bot` | `life-buoy` | `sparkles`)
  - `show_label` boolean
  - `position` (`right` | `left`)
- Admin editor in `src/components/admin/LiveChatWidgetSettings.tsx` — wire all fields above, with live preview tile.
- Acceptance: launcher visible in light/dark/mobile/desktop with contrast ≥ AA; admin toggles label off → icon-only chip.

## 2. User name everywhere in Admin Live Chat

Files: `src/lib/live-chat.functions.ts`, `src/components/admin/LiveChatManager.tsx`.

- All admin queries join `profiles` (already present) and select `full_name, display_name, email, role, created_at, last_seen_at`.
- Add `pickDisplayName(profile)` helper with fallback order: `display_name → full_name → profile_name → email`.
- Conversation list row: avatar · **Name (bold)** · email muted · role chip · status · last message preview · assignee chip · unread badge.
- Thread header + details panel use same name resolver. Never render bare email when a name exists.
- Backend: extend `adminListConversations` and `adminGetConversationDetails` returns with `user_display_name`.

## 3. Student composer — optional subject

Files: `src/components/site/LiveChatWidget.tsx`, `src/lib/live-chat.functions.ts`.

- When starting a new conversation, show two fields: **Subject (optional)** + **Message (required)**.
- `startNewConversation({ subject?, firstMessage })` — server creates conversation (title = subject || first 60 chars of message) and inserts the first message atomically.
- Within an existing thread, composer is message-only.
- Validation: message 1–4000 chars; subject 0–120 chars.

## 4. Admin Broadcast Messaging (new feature)

### 4.1 Schema — `supabase/manual_apply/20260615_broadcast_system.sql`
- `broadcasts` (id, sender_id, subject, body, priority enum `normal|important|urgent`, delivery_methods text[] `inbox|chat|popup`, target_kind enum `all_students|active_users|new_users|class|batch|course|users`, target_filter jsonb, status `draft|sent|hidden|archived`, pinned bool, visible bool default true, sent_at, created_at, updated_at, created_by).
- `broadcast_recipients` (id, broadcast_id, user_id, delivered_at, read_at, hidden bool default false). Unique (broadcast_id,user_id).
- `broadcast_templates` (id, name, subject, body, priority, delivery_methods, target_kind, target_filter, created_by, archived bool, created_at, updated_at).
- Indexes on `(user_id, read_at)`, `(broadcast_id)`, `(created_at desc)`.
- RLS:
  - `broadcasts`: SELECT for admins+super_admin (all), authenticated users (only via recipients view).
  - `broadcast_recipients`: SELECT where `user_id = auth.uid()` OR `has_role(admin/super_admin)`. UPDATE (mark read / hide) where `user_id = auth.uid()`.
  - INSERT/UPDATE/DELETE on broadcasts: `has_role(admin)` or `super_admin`; DELETE super_admin only.
  - Templates: admin+ for all ops.
- GRANTs for `authenticated` + `service_role`.
- Realtime publication adds `broadcasts`, `broadcast_recipients`.

### 4.2 Server functions — `src/lib/broadcasts.functions.ts`
- `createBroadcast({ subject, body, priority, delivery_methods[], target_kind, target_filter, send_now })` — resolves recipient set server-side (one of):
  - `all_students` — users with role `student`.
  - `active_users` — `last_seen_at > now() - 30d`.
  - `new_users` — date range / preset (`today|24h|3d|7d|15d|30d|custom{from,to}`).
  - `class|batch|course` — filter by `target_filter.id`.
  - `users` — explicit `target_filter.user_ids[]`.
  - Inserts `broadcast_recipients` rows in a single statement.
- `listBroadcasts(filters)` — admin history with delivered/read counts (aggregates from recipients).
- `getBroadcastAnalytics(id)` — totals + percentages.
- `updateBroadcast` / `hideBroadcast` / `unhideBroadcast` / `pinBroadcast` / `archiveBroadcast` / `deleteBroadcast` (super_admin) / `editBroadcast`.
- Templates: `listTemplates`, `createTemplate`, `updateTemplate`, `duplicateTemplate`, `archiveTemplate`, `deleteTemplate`.
- Student-facing: `listMyBroadcasts`, `markBroadcastRead({id})`, `hideMyBroadcast({id})`, `unreadBroadcastCount`.
- All privileged fns: `requireSupabaseAuth` + explicit `has_role` check (admin or super_admin per matrix in §6).

### 4.3 Admin UI — `src/components/admin/BroadcastManager.tsx` + sub-components
- Tabs: **Compose** · **History** · **Templates** · **Analytics**.
- Compose form:
  - From: `FROM ADMIN` chip (read-only).
  - Subject input, Message textarea (rich plain), Priority radio.
  - Delivery methods checkboxes (inbox / chat notification / popup).
  - Target picker (segmented): All Students · Active · New Users · Class · Batch · Course · Specific users (multi-select combobox).
  - New Users panel: preset chips + custom range (`react-day-picker`).
  - Save as Template / Send buttons.
- History table: Sent By · Date · Subject · Recipients · Delivered · Read · % · Status · actions (Hide/Unhide/Pin/Archive/Edit/Delete-super).
- Templates manager: list with create/edit/duplicate/archive/delete + "Use template" → prefills Compose.
- Analytics view per broadcast: cards + bar.
- Add route file `src/routes/admin.broadcasts.tsx` and link in `AdminSidebar` under Live Chat group.

### 4.4 Student delivery
- New hook `src/hooks/use-my-broadcasts.ts` — query + realtime subscription on `broadcast_recipients` for `user_id = me`.
- Inbox: extend `NotificationsFlow.tsx` to merge broadcasts (badge "FROM ADMIN"), or add dedicated `BroadcastsFlow` tab; pin pinned items.
- Live chat notification: a system message in widget header pulse + count.
- Popup: lightweight toast (`sonner`) for `popup` delivery method with subject/body + priority color.
- Mark read on open; unread badge real-time.

## 5. Permissions matrix (enforced server + UI)

`src/hooks/use-chat-permissions.ts` extended with: `canBroadcastCreate`, `canBroadcastSend`, `canBroadcastEdit`, `canBroadcastDelete`, `canBroadcastManageTemplates`, `canBroadcastHide`.

| Action | Super | Admin | Mod |
|---|---|---|---|
| Create / Send | ✓ | ✓ | ✗ |
| Send to New Users | ✓ | ✓ | ✗ |
| Edit own | ✓ | ✓ | ✗ |
| Edit any / Delete / Hide / Templates | ✓ | ✗ | ✗ |

## 6. Realtime

- Subscribe `broadcasts` + `broadcast_recipients` for student.
- Subscribe `broadcasts` for admin history.
- Subscribe `live_chat_conversations`/`live_chat_messages` (already done) — extend invalidations to refresh name fields.

## 7. Files touched / created

New:
- `supabase/manual_apply/20260615_broadcast_system.sql`
- `src/lib/broadcasts.functions.ts`
- `src/components/admin/BroadcastManager.tsx`
- `src/components/admin/broadcasts/{ComposeTab,HistoryTab,TemplatesTab,AnalyticsTab,TargetPicker,NewUsersPicker}.tsx`
- `src/components/site/BroadcastPopup.tsx`
- `src/routes/admin.broadcasts.tsx`
- `src/hooks/use-my-broadcasts.ts`
- `src/lib/display-name.ts`

Edit:
- `src/components/site/LiveChatWidget.tsx` (launcher rewrite + subject field)
- `src/components/admin/LiveChatWidgetSettings.tsx` (new fields)
- `src/components/admin/LiveChatManager.tsx` (name everywhere)
- `src/lib/live-chat.functions.ts` (name joins + subject)
- `src/hooks/use-chat-permissions.ts` (broadcast perms)
- `src/components/admin/AdminSidebar.tsx` (Broadcasts entry)
- `src/components/dashboard/NotificationsFlow.tsx` (merge broadcasts)
- `src/routes/__root.tsx` (mount BroadcastPopup for authenticated users)

## 8. Acceptance checks

- Launcher visible w/ label "Live Chat" in light+dark+mobile; admin toggle hides label.
- Admin Live Chat shows user **Name + Email + Role** in list, header, and details.
- Student can send (subject+message) and (message only); both create conversations.
- Admin can broadcast to all/active/new-users (with date preset) and specific users; recipients receive in inbox + realtime popup; unread badge updates without refresh.
- Permission matrix enforced — moderator sees no Broadcast menu and server rejects direct calls.
- Templates: create/edit/duplicate/archive/delete + "Use template" prefill works.
- Hide/Unhide/Pin/Edit-after-send/Delete-super all functional.

## Open question

For "Class / Batch / Course" targets — should I reuse the existing `classes`/`batches` tables already present in the schema, or are these new groupings? I'll default to the existing tables (whatever `src/lib/admin-academic.functions.ts` exposes) unless you say otherwise.
