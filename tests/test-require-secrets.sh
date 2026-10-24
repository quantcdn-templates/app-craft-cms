#!/bin/bash
# Tests for quant/entrypoints/05-require-secrets.sh.
# Old default values are read from git history through pipes and passed in
# the environment of a subprocess only. They are never printed.
cd "$(dirname "$0")/.." || exit 1

GUARD=quant/entrypoints/05-require-secrets.sh
# Last commit that shipped the old defaults; CI needs full history (fetch-depth: 0).
REF="${OLD_REF:-0aa39db7861ff88aff75a63c8f7ad8d412126cbd}"
FAILS=0
ERR=$(mktemp)
trap 'rm -f "$ERR"' EXIT

pass() { echo "PASS: $1"; }
fail() { echo "FAIL: $1"; FAILS=$((FAILS + 1)); }
skip() { echo "SKIP: $1"; }

# run_guard NAME VALUE... : env assignments, then the variable to check.
run_guard() {
    local name="$1"; shift
    env -i PATH="$PATH" "$@" bash -c ". $GUARD && require_secret $name" 2>"$ERR"
}

expect_refused() {
    local label="$1" name="$2"; shift 2
    run_guard "$name" "$@"
    local rc=$?
    if [ "$rc" -eq 1 ] && grep -q "$name" "$ERR"; then pass "$label"; else fail "$label (rc=$rc)"; fi
}

expect_accepted() {
    local label="$1" name="$2"; shift 2
    run_guard "$name" "$@"
    local rc=$?
    if [ "$rc" -eq 0 ]; then pass "$label"; else fail "$label (rc=$rc)"; fi
}

old_value() { # old_value FILE SED-EXPR : prints nothing on a miss
    git show "$REF:$1" 2>/dev/null | sed -n -E "$2" | tr -d '\n'
}

test_old_default() { # label NAME FILE SED-EXPR
    local value
    value=$(old_value "$3" "$4")
    if [ -z "$value" ]; then fail "$1 (old value is empty at $REF)"; return; fi
    expect_refused "$1" "$2" "$2=$value"
}

test -f "$GUARD" || { fail "guard file missing: $GUARD"; echo "$FAILS failure(s)"; exit 1; }

for NAME in CRAFT_SECURITY_KEY CRAFT_ADMIN_PASSWORD; do
    expect_refused "$NAME empty is refused" "$NAME"
    expect_refused "$NAME blank value is refused" "$NAME" "$NAME="
    expect_refused "$NAME env placeholder is refused" "$NAME" "$NAME=your-security-key-here"
    expect_refused "$NAME override placeholder is refused" "$NAME" "$NAME=change-me-locally"
    expect_accepted "$NAME random value is accepted" "$NAME" "$NAME=$(openssl rand -hex 16)"
    expect_accepted "$NAME special characters are accepted" "$NAME" "$NAME=a\$b&c#d e"
done

test_old_default "security key old compose default is refused" CRAFT_SECURITY_KEY \
    docker-compose.yml 's/^ *- CRAFT_SECURITY_KEY=\$\{CRAFT_SECURITY_KEY:-(.*)\}$/\1/p'
test_old_default "security key old env example value is refused" CRAFT_SECURITY_KEY \
    src/.env.example 's/^CRAFT_SECURITY_KEY=(.*)$/\1/p'
test_old_default "admin password old compose default is refused" CRAFT_ADMIN_PASSWORD \
    docker-compose.yml 's/^ *- CRAFT_ADMIN_PASSWORD=\$\{CRAFT_ADMIN_PASSWORD:-(.*)\}$/\1/p'

# The guard defines the function only: sourcing it must not exit or print.
if env -i PATH="$PATH" bash -c ". $GUARD" 2>/dev/null; then pass "sourcing defines only"; else fail "sourcing defines only"; fi

if grep -E '^CRAFT_SECURITY_KEY=.+' src/.env.example >/dev/null; then fail "env example has no key value"; else pass "env example has no key value"; fi
if grep -F 'CRAFT_ADMIN_PASSWORD:-' quant/entrypoints/10-craft-setup.sh >/dev/null; then fail "install uses no password fallback"; else pass "install uses no password fallback"; fi

# Structural check: the install branch (and its password guard) is reached only after the database gate.
SETUP=quant/entrypoints/10-craft-setup.sh
GATE=$(grep -n 'DB_READY" -ne 1' "$SETUP" | head -1 | cut -d: -f1)
REQ=$(grep -n 'require_secret CRAFT_ADMIN_PASSWORD' "$SETUP" | head -1 | cut -d: -f1)
if [ -n "$GATE" ] && [ -n "$REQ" ] && [ "$GATE" -lt "$REQ" ]; then pass "install is gated on database readiness"; else fail "install is gated on database readiness"; fi

[ "$FAILS" -eq 0 ] && echo "All passed" || { echo "$FAILS failure(s)"; exit 1; }
