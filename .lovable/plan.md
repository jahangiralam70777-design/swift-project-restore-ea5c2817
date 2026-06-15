# Live Chat System v2 — Full Upgrade Plan

A focused, end-to-end upgrade of the existing Live Chat system covering schema changes, RLS, server functions, admin UI, student widget, and contrast/readability.

## 1. Database migration (`supabase/manual_apply/20260615_live_chat_v2.sql`)

Schema additions on `live_chat_conversations`:
- `title text` (auto-derived from first message)
- `expires_at timestamptz default now() + interval '30 days'`
- `archived_at timestamptz`
- `deleted_at timestamptz`, `deleted_by uuid`
- Index on `(user_id, last_message_at desc)` and `(expires_at)`

`live_chat_messages`:
- `deleted_at`, `deleted_by`
- `expires_at timestamptz default now() + interval '30 days'`

New table `live_chat_assignment_history` (assigned_by, assigned_to, role, conversation_id, created_at, note).

Trigger: on every new message → bump `conversation.expires_at = now() + 30d` so active chats don't die mid-conversation.

RLS updates:
- DELETE policies on conversations/messages **only** for `has_role(auth.uid(),'super_admin')`.
- Staff SELECT scoped via `is_chat_staff` + assignment check for moderators (admins/super see all).
- Add `user_profile_view` join helper or use existing `profiles` table for name/email lookup.

GRANTs for `authenticated` and `service_role` on new objects.

Cron cleanup (`pg_cron`):
- Hourly job: delete messages, conversations, assignments, notes where `expires_at < now()` AND no recent activity.
- Storage cleanup via SQL: list `chat-attachments` paths from deleted messages and delete via `storage.objects` table.

## 2. Server functions (`src/lib/live-chat.functions.ts`)

Add / update:
- `listMyConversations()` — student: returns all their conversations w/ status, last message, last_message_at.
- `startNewConversation({ subject? })` — explicit create (no auto-create on widget open).
- `adminListConversations(filters)` — joins `profiles` to return `user_full_name`, `user_email`, `user_role`, `last_seen_at`, `assigned_to_name`.
- `adminGetConversationDetails(id)` — returns user profile (name, email, role, created_at, last_sign_in_at), assigned staff, prior conversation count, prior conversations list.
- `assignConversation({ conversationId, assigneeId })` — super_admin only; writes to `assignment_history`, updates `assigned_to`, triggers notification.
- `reassignConversation` — same, history-tracked.
- `deleteMessage({ id })` — **super_admin only** (server-side role check + RLS).
- `deleteConversation({ id })` — **super_admin only**; cascade messages + storage attachments.
- `listAssignableStaff()` — admins + moderators with chat permission.

All privileged fns: `requireSupabaseAuth` + explicit `has_role` check before action.

## 3. Student widget (`src/components/site/LiveChatWidget.tsx`)

Behavior change:
- On open → fetch `listMyConversations()`.
- If none → show "Start a new conversation" CTA.
- If some → show conversation picker modal: list (subject, last message preview, last activity, status badge) + "Start new conversation" button.
- Selecting one opens its thread; "New" calls `startNewConversation`.
- Back button on thread → returns to picker.
- Realtime subscription scoped to currently-open conversation + a list-level subscription to refresh picker.

Contrast fixes:
- Replace any `text-muted-foreground` on colored bubble backgrounds with paired foreground tokens.
- User bubble: `bg-primary text-primary-foreground`.
- Agent bubble: `bg-card text-card-foreground border`.
- System: `bg-muted text-foreground`.
- Inputs: `bg-background text-foreground placeholder:text-muted-foreground/80`.
- Timestamps: `text-foreground/70` (not `/40`).
- Audit every element in widget + header + picker for WCAG AA.

## 4. Admin Live Chat Manager (`src/components/admin/LiveChatManager.tsx`)

Three-pane upgrades:

**Conversation list (left):**
- Avatar + Full Name (bold) + Email (muted)
- Role badge, Online dot (from `last_seen_at` within 5m)
- Last message preview, time ago, unread badge, status badge
- Assigned-to chip

**Thread (center):**
- Header: user name + email + role + online status
- Messages with proper light/dark contrast, sender labels
- Composer (admin/mod): reply + internal notes tab
- Delete buttons (message-level + conversation-level) **only rendered if `isSuperAdmin`**

**Details panel (right):**
- User card: full name, email, role, registered date, last login, total previous chats, active chat count
- Previous Conversations list (clickable to jump)
- Assignment section: current assignee, "Assign / Reassign" dropdown (super_admin only) listing staff
- Assignment history timeline
- Status / Priority controls
- Danger zone (super_admin only): Delete conversation

Permissions sourced via `useIsSuperAdmin()` hook + server-side enforcement.

## 5. Permissions helper

`src/hooks/use-chat-permissions.ts`:
- Returns `{ isSuperAdmin, isAdmin, isModerator, canDelete, canAssign, canReply }`.
- Wraps existing role queries.

## 6. Realtime

- Subscribe to `live_chat_conversations` and `live_chat_messages` changes; invalidate React Query keys.
- Subscribe to `live_chat_assignment_history` for assignment toasts.

## 7. Notifications

On assign → insert into existing `live_chat_notifications` for `assigned_to` user; existing notification hook surfaces it.

## 8. Acceptance checks

- WCAG AA on all chat text in both themes (manual audit via Playwright screenshots in light + dark).
- Student can have 5 concurrent threads; switching works; realtime per-thread.
- Admin sees user name + email everywhere.
- Super admin: delete works and removes from DB + storage. Admin/Mod: no delete buttons; backend rejects direct calls.
- Cron deletes >30d old messages/conversations/files automatically; active threads refresh `expires_at`.
- RLS: user A cannot read user B's conversation via direct supabase call (test with two sessions).

## Files touched

- new: `supabase/manual_apply/20260615_live_chat_v2.sql`
- new: `src/hooks/use-chat-permissions.ts`
- edit: `src/lib/live-chat.functions.ts`
- edit: `src/components/site/LiveChatWidget.tsx` (significant rewrite for multi-conversation)
- edit: `src/components/admin/LiveChatManager.tsx` (significant rewrite for user info + assignment + RBAC delete)
- edit: `.lovable/plan.md`

## Open questions before I start

1. **Super Admin role name** — is it stored as `'super_admin'` in your `app_role` enum, or as `'admin'` with a separate flag? I need to know which `has_role()` value gates delete.
2. **Assignable staff** — should moderators be auto-assigned (round-robin) or always manual by super admin?
3. **Cron** — is `pg_cron` already enabled on your Supabase project? If not I'll provide a fallback: a `/api/public/cron/chat-cleanup` route you can hit from an external scheduler.
4. **Attachments** — current widget doesn't send attachments yet; OK to defer attachment cleanup wiring until attachments ship, or include the storage-delete code now (safe no-op if no files)?
