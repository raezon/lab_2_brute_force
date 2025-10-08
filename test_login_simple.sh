#!/usr/bin/env bash
# test_login_fixed.sh
# Usage:
#   ./test_login_fixed.sh [base-url] username password
# Examples:
#   ./test_login_fixed.sh admin password
#   ./test_login_fixed.sh http://127.0.0.1:8000 admin password
set -eu

DEFAULT="http://127.0.0.1:8000"
if [ $# -eq 2 ]; then
  BASE="$DEFAULT"; USER="$1"; PASS="$2"
elif [ $# -ge 3 ]; then
  BASE="$1"; USER="$2"; PASS="$3"
else
  echo "Usage: $0 [base-url] username password" >&2
  exit 2
fi
BASE="${BASE%/}"


command -v curl >/dev/null 2>&1 || { echo "curl requis"; exit 3; }

echo "Base: $BASE — user: $USER"
TMP="$(mktemp)"; trap 'rm -f "$TMP"' EXIT

# 1) PRIORITE : POST JSON /api/login
API="$BASE/api/login"
echo "-> POST JSON $API"
resp="$(curl -s -w "\n%{http_code}" -X POST "$API" \
  -H "Content-Type: application/json" \
  -d "{\"username\":\"$USER\",\"password\":\"$PASS\"}" --max-time 10) || true"
code="$(printf "%s" "$resp" | tail -n1)"
body="$(printf "%s" "$resp" | sed '$d')"
echo "HTTP $code"
[ -n "$body" ] && echo "$body"
if [ "$code" = "200" ] || [ "$code" = "302" ]; then
  echo "✅ Auth OK via $API"
  exit 0
fi

# 2) ESSAI GET users.json (fallback)
USERS_URL="$BASE/users.json"
echo
echo "-> GET $USERS_URL (fallback)"
if curl -sS -o "$TMP" "$USERS_URL"; then
  if sed -n '1p' "$TMP" | grep -qE '^\s*[\[\{]'; then
    # recherche simple : user et password dans le même objet (approx)
    if grep -F "\"username\"" -n "$TMP" | cut -d: -f1 | while read -r ln; do
         sed -n "${ln},$((ln+6))p" "$TMP" | grep -q "\"username\"[[:space:]]*:[[:space:]]*\"$USER\"" \
         && sed -n "${ln},$((ln+6))p" "$TMP" | grep -q "\"password\"[[:space:]]*:[[:space:]]*\"$PASS\"" && echo ok && break
       done | grep -q ok; then
      echo "✅ Matching trouvé dans users.json pour $USER"
      exit 0
    else
      echo "→ Pas de matching dans users.json"
    fi
  else
    echo "→ users.json non valide"
  fi
else
  echo "→ users.json inaccessible"
fi

# 3) ESSAI POST form /login (dernière tentative)
FORM="$BASE/login"
echo
echo "-> POST form $FORM"
resp="$(curl -s -w "\n%{http_code}" -X POST "$FORM" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  --data-urlencode "username=$USER" --data-urlencode "password=$PASS" --max-time 10) || true"
code="$(printf "%s" "$resp" | tail -n1)"
body="$(printf "%s" "$resp" | sed '$d')"
echo "HTTP $code"
[ -n "$body" ] && echo "$body"
if [ "$code" = "200" ] || [ "$code" = "302" ]; then
  echo "✅ Auth OK via $FORM"
  exit 0
fi

echo "❌ Aucun test n'a confirmé l'authentification."
exit 1
