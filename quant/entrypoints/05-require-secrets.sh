#!/bin/bash

# Defines require_secret. Sourced by quant/entrypoints.sh before the setup
# scripts run (entrypoints load in name order). This file only defines
# functions: it makes no calls.
#
# require_secret NAME stops the container (exit 1) when the variable is empty
# or holds a value that ships in an earlier template version or example file.
# Only SHA-256 hashes of those values are stored here.

KNOWN_DEFAULT_SHA256="
afa6c2acabd63ec89d36282e771ba54440a63b36fc90fc1329b00123bbfbecb1
5e884898da28047151d0e56f8dc6292773603d0d6aabbdd62a11ef721d1542d8
368e12878b66b88a3edcad5b9ddedf8e95e24b1ef8a14cbad862a03d397fa06f
ec00bebe906b2a58c6b5b1e3cf2176f2f035b240d186ffe7009bf8ae033396a2
1210bb365f950c71128f492608a520986d43a83bd7735aacf7f26a827e500d35
"

# Print the SHA-256 of stdin (Debian: sha256sum, macOS: shasum).
secret_sha256() {
    if command -v sha256sum >/dev/null 2>&1; then
        sha256sum | cut -d' ' -f1
    else
        shasum -a 256 | cut -d' ' -f1
    fi
}

# True when the value hash is on the known list.
is_known_default() {
    local digest
    digest=$(printf '%s' "$1" | secret_sha256)
    printf '%s\n' "$KNOWN_DEFAULT_SHA256" | grep -qx "$digest"
}

require_secret() {
    local name="$1"
    local value="${!name}"
    if [ -z "$value" ] || is_known_default "$value"; then
        echo "ERROR: ${name} is not set to a unique value. Set it as an application secret and redeploy." >&2
        exit 1
    fi
}
