#!/usr/bin/env sh
set -eu

WAF_URL="http://127.0.0.1:8080"

# Wait for the WAF to be reachable
i=0
while [ "$i" -lt 60 ]; do
    if curl -sf -o /dev/null "$WAF_URL/anything"; then
        break
    fi
    i=$((i + 1))
    sleep 1
done

if [ "$i" -ge 60 ]; then
    echo "ERROR: WAF not reachable at $WAF_URL within 60s" >&2
    exit 1
fi

echo "WAF reachable, running mod_evasive tests..."

# Phase 1 — Unprotected path: /anything is NOT in the DOSTargetlist, so DoS
# detection is skipped and the gateway IP is clean here -> all 200.
# (Must run before any blocking phase, since a blacklist caused elsewhere
# would also block /anything from the same IP.)
unprotected_codes=""
n=0
while [ "$n" -lt 10 ]; do
    code=$(curl -s -o /dev/null -w "%{http_code}\n" "$WAF_URL/anything")
    unprotected_codes="$unprotected_codes $code"
    n=$((n + 1))
done
echo "Unprotected /anything codes:$unprotected_codes"

case "$unprotected_codes" in
    *403*)
        echo "ERROR: got a 403 on unprotected path, codes:$unprotected_codes" >&2
        exit 1
        ;;
esac

# Phase 2 — Whitelisted route: /evasive-whitelist IS in the DOSTargetlist
# (would trigger counting) but ALSO matches DOSWhitelistUri -> must NEVER be
# blocked. httpbun returns 404 for unknown paths (no vshn route); assert no 403.
whitelisted_codes=""
n=0
while [ "$n" -lt 25 ]; do
    code=$(curl -s -o /dev/null -w "%{http_code}\n" "$WAF_URL/evasive-whitelist")
    whitelisted_codes="$whitelisted_codes $code"
    n=$((n + 1))
done
echo "Whitelisted /evasive-whitelist codes:$whitelisted_codes"

case "$whitelisted_codes" in
    *403*)
        echo "ERROR: whitelisted route got a 403, codes:$whitelisted_codes" >&2
        exit 1
        ;;
esac

# Phase 3 — Protected path (runs LAST so its blacklist can't contaminate
# the non-blocking phases above): repeated rapid requests to /evasive-test
# exceed DOSPageCount=2 within DOSPageInterval=10s per worker -> 403s appear.
protected_codes=""
n=0
while [ "$n" -lt 25 ]; do
    code=$(curl -s -o /dev/null -w "%{http_code}\n" "$WAF_URL/evasive-test")
    protected_codes="$protected_codes $code"
    n=$((n + 1))
done
echo "Protected /evasive-test codes:$protected_codes"

case "$protected_codes" in
    *403*) ;;
    *)
        echo "ERROR: expected at least one 403 on protected path, got:$protected_codes" >&2
        exit 1
        ;;
esac

echo "PASS: mod_evasive integration test succeeded"
exit 0