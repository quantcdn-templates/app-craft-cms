#!/bin/bash

# Usage: lint-compose-secrets.sh <compose-file>...
#
# Fails (exit 1) when an environment entry whose name matches
# (KEY|SECRET|PASSWORD|PASS|TOKEN|SALT), case-insensitive, has a literal value
# or a ${VAR:-non-empty} default. Empty values, ${VAR} and ${VAR:-} pass.
# Services with a quant.type label are platform-managed and are skipped.
# The report names the file, line and variable. It never prints the value.

lint_file() {
    awk -v file="$1" '
    function flush(   i) {
        if (!managed) for (i = 1; i <= n; i++) print file ":" ln[i] ": " nm[i] " has a literal value"
        n = 0; managed = 0
    }
    function is_literal(v) {
        sub(/^[ \t]+/, "", v); sub(/[ \t\r]+$/, "", v)
        gsub(/^["\x27]|["\x27]$/, "", v)
        if (v == "") return 0
        if (v ~ /^\$\{[A-Za-z_0-9]+\}$/) return 0
        if (v ~ /^\$\{[A-Za-z_0-9]+:-\}$/) return 0
        return 1
    }
    function check(name, val) {
        if (toupper(name) ~ /(KEY|SECRET|PASSWORD|PASS|TOKEN|SALT)/ && is_literal(val)) {
            n++; nm[n] = name; ln[n] = NR
        }
    }
    /^[^ #]/ { flush(); in_services = ($0 ~ /^services:/); next }
    in_services && /^  [A-Za-z0-9_.-]+:[ \t]*$/ { flush(); next }
    /quant\.type[ \t]*[:=]/ { managed = 1 }
    /^[ \t]*-[ \t]*[A-Za-z_][A-Za-z_0-9]*=/ {
        line = $0; sub(/^[ \t]*-[ \t]*/, "", line)
        eq = index(line, "="); check(substr(line, 1, eq - 1), substr(line, eq + 1)); next
    }
    /^[ \t]+[A-Za-z_][A-Za-z_0-9]*:[ \t]+[^ \t]/ {
        line = $0; sub(/^[ \t]+/, "", line)
        c = index(line, ":"); check(substr(line, 1, c - 1), substr(line, c + 1))
    }
    END { flush() }
    ' "$1"
}

main() {
    local out rc=0 f
    for f in "$@"; do
        out=$(lint_file "$f")
        if [ -n "$out" ]; then printf '%s\n' "$out"; rc=1; fi
    done
    return "$rc"
}

main "$@"
