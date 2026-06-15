# Database Audit & Migration Drift Report

_Generated as part of the post-import audit._

## Archived ad-hoc SQL (formerly at repo root)

These eight `.sql` files predate the Supabase migration system being adopted
in this repo. They were written for **manual application via the Supabase SQL
editor** (each file says so in its header) and were never registered as
timestamped migrations. They have been moved here so the repo no longer
implies they are part of the canonical migration history.

| File | Phase | Action taken | Recommended next step |
|---|---|---|---|
| `PHASE1_RLS_HARDENING.sql` | RLS hardening (phase 1) | archived | Compare with `supabase/migrations/2026060613*.sql`; the RLS policies it adds appear duplicated by the timestamped migrations from 2026-06-06. **Verify in DB**, then keep only as historical record. |
| `PRODUCTION_SECURITY_HARDENING.sql` | RLS + roles | archived | Superseded by `..._LOCK_FINAL.sql`. |
| `PRODUCTION_SECURITY_LOCK.sql` | RLS lockdown | archived | Superseded by `..._LOCK_FINAL.sql`. |
| `PRODUCTION_SECURITY_LOCK_FINAL.sql` | RLS lockdown (final) | archived | If not yet applied to production, run it through the migration tool as a new timestamped migration; do **not** re-run silently — it is idempotent but listed as "manual". |
| `PRODUCTION_SECURITY_ADMIN_FULL_ACCESS.sql` | Admin override policies | archived | Compare with `has_role`/`is_admin` policies already in migrations; keep only if it adds something new. |
| `SECURITY_AUDIT_MIGRATION.sql` | Audit-log scaffolding | archived | The `audit_log` table & triggers it defines already exist in `supabase/migrations/20260607*`. **Drift risk = low**. |
| `SITE_MGMT_PHASE0_SECURITY.sql` | Site management RLS | archived | Compare with `supabase/migrations/20260608*` site-management migrations. |
| `USER_MANAGEMENT_PHASE2_MIGRATION.sql` | User management phase 2 | archived | If `user_bans`, `user_audit`, `user_sessions` tables already exist in the live DB, this file is fully applied. Confirm and delete. |

**Bottom line:** no destructive action taken; only the *location* changed.
Run `\dt` against the live Supabase project and diff against
`supabase/migrations/` to confirm full coverage before deleting these files.

## Migration system inventory

```
supabase/migrations/  → 64 timestamped files
                       110 CREATE TABLE statements
                       110 ENABLE ROW LEVEL SECURITY statements (100% coverage)
                       247 CREATE POLICY statements
                       423 GRANT statements
                       388 has_role(...) invocations in policies (no recursive RLS)
```

No `service_role_key` references in client code. No `storage.buckets` mutations
in migrations — if buckets exist in production, their policies are managed
out-of-band; audit `storage.objects` policies directly in the dashboard.

## Recommended next migration

See `db_audit/RECOMMENDED_INDEXES.sql` — a non-destructive `CREATE INDEX
CONCURRENTLY` script aimed at safe operation up to ~50 000 users. Review
`EXPLAIN ANALYZE` output for each query first; do not blindly apply.
