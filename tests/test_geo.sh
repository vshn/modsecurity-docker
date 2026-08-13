#!/usr/bin/env bash
# tests/test_geo.sh — mod_qos GeoIP country-block + IPv6-block end-to-end test.
#
# Brings up the waf + httpbun via tests/compose.geo.test.yml. The production
# image is NOT modified: geo CSV + qos rules are injected via read-only
# bind-mounts, and MOD_QOS_ENABLED=on. mod_remoteip (already loaded in the base
# image) is configured via the bind-mounted rules to let X-Forwarded-For
# override Remote_Addr, so the IPv6-block rule can be exercised over the IPv4
# docker network (real IPv6 needs daemon-level enablement).
#
# Assertions:
#   1. allow: FR-simulated country -> 2xx/3xx (NOT blocked)
#   2. block by country: PV (simulated header) -> 403
#   3. block by country: real docker client IP (no header) -> 403
#   4. block IPv6: X-Forwarded-For: 2001:db8::1 (country=FR) -> 403 (ipv6 rule, not country)
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE=(docker compose -f "${HERE}/compose.geo.test.yml" -p modsec-qos-geo-test)
WAF="http://127.0.0.1:8082"
FR_IP="62.184.102.0"   # -> FR (allowed)
PV_IP="172.16.0.5"     # -> PV (blocked)

code_of() { curl -s -o /dev/null -w '%{http_code}' "$@" 2>/dev/null || true; }

cleanup() { "${COMPOSE[@]}" down -v >/dev/null 2>&1 || true; }
trap cleanup EXIT

echo "==> building and starting stack"
"${COMPOSE[@]}" up -d --build

echo "==> waiting for waf to become ready (using allow header)"
ready=""
code="000"
for _ in $(seq 1 60); do
  code="$(code_of -H "X-Geo-Test-IP: ${FR_IP}" "${WAF}/anything")"
  if [ "${code:-000}" -ge 200 ] 2>/dev/null && [ "${code:-999}" -lt 400 ] 2>/dev/null; then
    ready=1; break
  fi
  sleep 1
done
if [ -z "${ready}" ]; then
  echo "FAIL: waf did not become ready (last code: ${code})" >&2
  "${COMPOSE[@]}" logs --tail=60 >&2 || true
  exit 1
fi
echo "    ready (last code: ${code})"

echo "==> 1) allow: country FR (simulated) must NOT be blocked"
c="$(code_of -H "X-Geo-Test-IP: ${FR_IP}" "${WAF}/anything")"
echo "    FR -> ${c}"
if [ "${c:-000}" -lt 200 ] 2>/dev/null || [ "${c:-999}" -ge 400 ] 2>/dev/null; then
  echo "FAIL: expected 2xx/3xx for FR, got ${c}" >&2; exit 1
fi

echo "==> 2) block by country: PV (simulated) -> 403"
c="$(code_of -H "X-Geo-Test-IP: ${PV_IP}" "${WAF}/anything")"
echo "    PV -> ${c}"
if [ "${c:-000}" -ne 403 ] 2>/dev/null; then
  echo "FAIL: expected 403 for PV, got ${c}" >&2; exit 1
fi

echo "==> 3) block by country: real docker client IP (no header) -> 403"
c="$(code_of "${WAF}/anything")"
echo "    real IP -> ${c}"
if [ "${c:-000}" -ne 403 ] 2>/dev/null; then
  echo "FAIL: expected 403 for real (PV) IP, got ${c}" >&2; exit 1
fi

echo "==> 4) block IPv6: X-Forwarded-For: 2001:db8::1 (country=FR) -> 403"
c="$(code_of -H "X-Geo-Test-IP: ${FR_IP}" -H "X-Forwarded-For: 2001:db8::1" "${WAF}/anything")"
echo "    IPv6-simulated -> ${c}"
if [ "${c:-000}" -ne 403 ] 2>/dev/null; then
  echo "FAIL: expected 403 for IPv6 (simulated), got ${c}" >&2; exit 1
fi

echo "PASS: geo country-block + IPv6-block both work"