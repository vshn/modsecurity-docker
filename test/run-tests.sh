#!/usr/bin/env sh
set -eu

cleanup() {
    docker compose -f compose.yml -f compose.test.yml down -v 2>/dev/null || true
    docker compose -f compose.yml -f compose.test.whitelist-ip.yml down -v 2>/dev/null || true
}
trap cleanup EXIT

# Phase A: blocking + whitelisted-route behaviour
docker compose -f compose.yml -f compose.test.yml up -d --build
sh ./test/test_mod_evasive.sh
docker compose -f compose.yml -f compose.test.yml down -v

# Phase B: whitelisted-IP behaviour (separate stack -> its own DOSWhitelist)
docker compose -f compose.yml -f compose.test.whitelist-ip.yml up -d --build
sh ./test/test_mod_evasive_whitelist_ip.sh
docker compose -f compose.yml -f compose.test.whitelist-ip.yml down -v

# Phase C: HTTP/2 (h2c) behaviour — fresh stack so no carry-over blacklist
docker compose -f compose.yml -f compose.test.yml up -d --build
sh ./test/test_mod_evasive_http2.sh
docker compose -f compose.yml -f compose.test.yml down -v