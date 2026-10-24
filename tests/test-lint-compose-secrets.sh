#!/bin/bash
# Tests for scripts/lint-compose-secrets.sh.
cd "$(dirname "$0")/.." || exit 1

LINT=scripts/lint-compose-secrets.sh
# Last commit that shipped the old defaults; CI needs full history (fetch-depth: 0).
REF="${OLD_REF:-0aa39db7861ff88aff75a63c8f7ad8d412126cbd}"
FAILS=0
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

pass() { echo "PASS: $1"; }
fail() { echo "FAIL: $1"; FAILS=$((FAILS + 1)); }
skip() { echo "SKIP: $1"; }

expect_rc() { # label expected-rc file
    bash "$LINT" "$3" >"$TMP/out" 2>&1
    local rc=$?
    if [ "$rc" -eq "$2" ]; then pass "$1"; else fail "$1 (rc=$rc, want $2)"; fi
}

sample() { # sample NAME : body from stdin
    cat > "$TMP/$1"
    echo "$TMP/$1"
}

test -f "$LINT" || { fail "lint missing: $LINT"; echo "$FAILS failure(s)"; exit 1; }

if git show "$REF:docker-compose.yml" > "$TMP/old.yml" 2>/dev/null; then
    expect_rc "old compose is flagged" 1 "$TMP/old.yml"
    # The report names the variable and never the value.
    if grep -q 'CRAFT_SECURITY_KEY has a literal value' "$TMP/out"; then pass "report names variable"; else fail "report names variable"; fi
else
    fail "old compose readable at $REF (fetch full history)"
fi

expect_rc "new compose passes" 0 docker-compose.yml
expect_rc "empty default passes" 0 "$(sample a.yml <<'Y'
services:
  web:
    environment:
      - API_TOKEN=${API_TOKEN:-}
      - OTHER_SECRET=${OTHER_SECRET}
      - EMPTY_KEY=
Y
)"
expect_rc "literal value is flagged" 1 "$(sample b.yml <<'Y'
services:
  web:
    environment:
      - SESSION_SALT=abc
Y
)"
expect_rc "map form literal is flagged" 1 "$(sample c.yml <<'Y'
services:
  web:
    environment:
      DB_PASSWORD: hunter2
Y
)"
expect_rc "platform-managed service is skipped" 0 "$(sample d.yml <<'Y'
services:
  db:
    labels:
      quant.type: mysql
    environment:
      - MYSQL_PASSWORD=${X:-y}
Y
)"
expect_rc "non-secret names pass" 0 "$(sample e.yml <<'Y'
services:
  web:
    environment:
      - APP_ENV=production
Y
)"

[ "$FAILS" -eq 0 ] && echo "All passed" || { echo "$FAILS failure(s)"; exit 1; }
