#!/usr/bin/env bash
# =====================================================================
# Direct-GoTrue bypass probe for Student Login/Signup controls.
#
# Usage:
#   STUDENT_EMAIL=student@example.com STUDENT_PASSWORD=... \
#   ADMIN_EMAIL=admin@example.com    ADMIN_PASSWORD=...   \
#   bash scripts/probe-auth-hooks.sh
#
# This script bypasses the entire React app and hits the Supabase
# GoTrue REST API directly — exactly what a malicious client would do.
# Expected results AFTER applying the Auth Hooks:
#   1. Student login with controls OFF  -> 403 + maintenance message
#   2. Admin login with controls OFF    -> 200 + session
#   3. Public signup with controls OFF  -> 403 + maintenance message
# =====================================================================
set -u
URL="${SUPABASE_URL:-$(grep -E '^SUPABASE_URL=' .env | cut -d= -f2- | tr -d '\"')}"
KEY="${SUPABASE_PUBLISHABLE_KEY:-$(grep -E '^SUPABASE_PUBLISHABLE_KEY=' .env | cut -d= -f2- | tr -d '\"')}"
echo "Target: $URL"
hr() { printf '\n----- %s -----\n' "$1"; }

hr "1. STUDENT login attempt via /auth/v1/token (should FAIL when student login is OFF)"
curl -sS -i -X POST "$URL/auth/v1/token?grant_type=password" \
  -H "apikey: $KEY" -H "Content-Type: application/json" \
  -d "{\"email\":\"${STUDENT_EMAIL:?set STUDENT_EMAIL}\",\"password\":\"${STUDENT_PASSWORD:?set STUDENT_PASSWORD}\"}" \
  | sed -n '1,15p'

hr "2. ADMIN login attempt via /auth/v1/token (should SUCCEED even when student login is OFF)"
curl -sS -i -X POST "$URL/auth/v1/token?grant_type=password" \
  -H "apikey: $KEY" -H "Content-Type: application/json" \
  -d "{\"email\":\"${ADMIN_EMAIL:?set ADMIN_EMAIL}\",\"password\":\"${ADMIN_PASSWORD:?set ADMIN_PASSWORD}\"}" \
  | sed -n '1,15p'

hr "3. Public SIGNUP attempt via /auth/v1/signup (should FAIL when student signup is OFF)"
RAND=$RANDOM
curl -sS -i -X POST "$URL/auth/v1/signup" \
  -H "apikey: $KEY" -H "Content-Type: application/json" \
  -d "{\"email\":\"probe+$RAND@example.com\",\"password\":\"ProbePass!$RAND\"}" \
  | sed -n '1,15p'

echo
echo "Done. Look for HTTP/2 403 + your configured maintenance message on (1) and (3),"
echo "and HTTP/2 200 with an access_token on (2)."
