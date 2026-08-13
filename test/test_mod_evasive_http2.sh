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

echo "WAF reachable, running mod_evasive HTTP/2 test..."

# Sanity: confirm the WAF actually negotiates h2c (cleartext HTTP/2).
# --http2-prior-knowledge forces h2c (no Upgrade), so http_version must be 2.
ver=$(curl -s --http2-prior-knowledge -o /dev/null -w "%{http_version}" "$WAF_URL/anything")
if [ "$ver" != "2" ]; then
    echo "ERROR: HTTP/2 not negotiated (http_version='$ver', expected '2')" >&2
    echo "  curl needs nghttp2 support; check: curl --version | grep nghttp2" >&2
    exit 1
fi
echo "HTTP/2 (h2c) negotiated."

# Phase 1 — Unprotected path over H2: /anything is NOT in the DOSTargetlist,
# so DoS detection is skipped -> all 200. Run first while the IP is clean.
unprotected_codes=""
n=0
while [ "$n" -lt 10 ]; do
    code=$(curl -s --http2-prior-knowledge -o /dev/null -w "%{http_code}\n" "$WAF_URL/anything")
    unprotected_codes="$unprotected_codes $code"
    n=$((n + 1))
done
echo "Unprotected /anything (h2) codes:$unprotected_codes"

case "$unprotected_codes" in
    *403*)
        echo "ERROR: got a 403 on unprotected path over h2, codes:$unprotected_codes" >&2
        exit 1
        ;;
esac

# Phase 2 — Protected path over H2: rapid repeated /evasive-test exceeds
# DOSPageCount=2 within DOSPageInterval=10s per worker -> 403s appear.
protected_codes=""
n=0
while [ "$n" -lt 25 ]; do
    code=$(curl -s --http2-prior-knowledge -o /dev/null -w "%{http_code}\n" "$WAF_URL/evasive-test")
    protected_codes="$protected_codes $code"
    n=$((n + 1))
done
echo "Protected /evasive-test (h2) codes:$protected_codes"

case "$protected_codes" in
    *403*) ;;
    *)
        echo "ERROR: expected at least one 403 on protected path over h2, got:$protected_codes" >&2
        exit 1
        ;;
esac

echo "PASS: mod_evasive HTTP/2 test succeeded"
exit 0