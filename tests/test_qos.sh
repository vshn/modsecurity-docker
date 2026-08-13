#!/usr/bin/env bash
# tests/test_qos.sh — end-to-end check of the mod_qos activation mechanism.
#
# Brings up the waf + httpbun backend via tests/compose.test.yml and asserts:
#   1. a request to a NON-limited path is NOT blocked (2xx/3xx), and
#   2. a rapid burst to the mod_qos-limited path (/blockme) is HARD-BLOCKED
#      (HTTP 5xx; mod_qos denies with 500 by default).
#
# The production image is built unmodified; qos rules are supplied via a
# read-only bind-mount and MOD_QOS_ENABLED=on (image default is 'disabled').
# Run:  bash tests/test_qos.sh
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE=(docker compose -f "${HERE}/compose.test.yml" -p modsec-qos-test)
WAF="http://127.0.0.1:8081"
CTRL_PATH="/anything"
BLOCK_PATH="/blockme"

cleanup() { "${COMPOSE[@]}" down -v >/dev/null 2>&1 || true; }
trap cleanup EXIT

echo "==> building and starting stack"
"${COMPOSE[@]}" up -d --build

echo "==> waiting for waf to become ready"
ready=""
code="000"
for _ in $(seq 1 60); do
  code="$(curl -s -o /dev/null -w '%{http_code}' "${WAF}${CTRL_PATH}" 2>/dev/null || true)"
  if [ "${code:-000}" -ge 200 ] 2>/dev/null && [ "${code:-999}" -lt 400 ] 2>/dev/null; then
    ready=1; break
  fi
  sleep 1
done
if [ -z "${ready}" ]; then
  echo "FAIL: waf did not become ready (last code: ${code})" >&2
  "${COMPOSE[@]}" logs --tail=40 >&2 || true
  exit 1
fi

echo "==> control request (non-limited path must NOT be blocked)"
ctrl="$(curl -s -o /dev/null -w '%{http_code}' "${WAF}${CTRL_PATH}")"
if [ "${ctrl:-000}" -lt 200 ] 2>/dev/null || [ "${ctrl:-999}" -ge 400 ] 2>/dev/null; then
  echo "FAIL: control ${CTRL_PATH} returned ${ctrl} (expected 2xx/3xx)" >&2
  exit 1
fi
echo "    control ${CTRL_PATH} -> ${ctrl} (ok)"

# NOTE: must assert control BEFORE the burst. Once the per-client-IP limit is
# hit, mod_qos denies ALL requests from that IP for the configured period, so a
# control request issued AFTER the burst would also return 5xx.
echo "==> ${BLOCK_PATH} burst (mod_qos limit = 3 events / 60s per client IP)"
blocked=0
for _ in $(seq 1 10); do
  code="$(curl -s -o /dev/null -w '%{http_code}' "${WAF}${BLOCK_PATH}" 2>/dev/null || true)"
  if [ "${code:-000}" -ge 500 ] 2>/dev/null && [ "${code:-999}" -lt 600 ] 2>/dev/null; then
    blocked=$((blocked + 1))
  fi
done
echo "    /blockme burst: ${blocked}/10 returned HTTP 5xx"
if [ "${blocked}" -le 0 ]; then
  echo "FAIL: no requests to ${BLOCK_PATH} were blocked (expected >=1 HTTP 5xx)" >&2
  exit 1
fi

echo "PASS: mod_qos blocked ${blocked} of 10 ${BLOCK_PATH} requests"