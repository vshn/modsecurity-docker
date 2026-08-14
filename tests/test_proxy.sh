#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR=$(realpath "$(dirname "$0")")
COMPOSE=(docker compose -f "${SCRIPT_DIR}/compose.proxy.test.yml" -p modsec-qos-proxy-test)
WAF="http://reverse-proxy:8080"

cleanup() { "${COMPOSE[@]}" down -v >/dev/null 2>&1 || true; }
trap cleanup EXIT

code_of() { local c="$1"; shift; "${COMPOSE[@]}" exec -T "$c" curl -s -o /dev/null -w '%{http_code}' "$@" 2>/dev/null || true; }
ver_of() { local c="$1"; shift; "${COMPOSE[@]}" exec -T "$c" curl -s -o /dev/null -w '%{http_version}' "$@" 2>/dev/null || true; }

assert_burst() {
  local client="$1" expect="$2" flags="$3" label="$4"
  local codes="" blocked=0 code
  for i in 1 2 3 4 5 6; do
    code="$(code_of "$client" $flags "${WAF}/blockme")"
    codes="${codes} ${code}"
    if [ "${code}" -ge 500 ] 2>/dev/null && [ "${code}" -lt 600 ] 2>/dev/null; then
      blocked=$((blocked + 1))
    fi
  done
  echo "    ${label} ${client} /blockme:${codes} blocked=${blocked}"
  if [ "${expect}" = "none" ] && [ "${blocked}" -ne 0 ]; then
    echo "FAIL: ${client} blocked ${blocked} (expected 0, whitelist not working)" >&2; exit 1
  fi
  if [ "${expect}" = "some" ] && [ "${blocked}" -le 0 ]; then
    echo "FAIL: ${client} not blocked (expected >=1)" >&2; exit 1
  fi
}

assert_control() {
  local client="$1" flags="$2" expect_ver="$3" label="$4"
  local code ver
  ver="$(ver_of "$client" $flags "${WAF}/anything")"
  code="$(code_of "$client" $flags "${WAF}/anything")"
  echo "    ${label} ${client} /anything -> ${code} ver ${ver}"
  if [ "${expect_ver}" != "any" ] && [ "${ver}" != "${expect_ver}" ]; then
    echo "FAIL: ${client} protocol ${ver}, expected ${expect_ver}" >&2; exit 1
  fi
  if [ "${code:-000}" -lt 200 ] 2>/dev/null || [ "${code:-999}" -ge 400 ] 2>/dev/null; then
    echo "FAIL: ${client} control ${code} (expected 2xx/3xx)" >&2; exit 1
  fi
}

echo "==> starting stack"
"${COMPOSE[@]}" up -d --wait --build

echo "==> HTTP/1.1: controls"
assert_control client-a "" "1.1" "HTTP/1.1"
assert_control client-b "" "1.1" "HTTP/1.1"
assert_control client-c "" "1.1" "HTTP/1.1"
assert_control client-d "" "1.1" "HTTP/1.1"

echo "==> HTTP/1.1: whitelist (client-a, client-b, client-c) + block (client-d)"
assert_burst client-a none "" "HTTP/1.1"
assert_burst client-b none "" "HTTP/1.1"
assert_burst client-c none "" "HTTP/1.1"
assert_burst client-d some "" "HTTP/1.1"

echo "==> restarting waf for HTTP/2 tests"
"${COMPOSE[@]}" restart waf
"${COMPOSE[@]}" up -d --wait

echo "==> HTTP/2: controls"
assert_control client-a "--http2-prior-knowledge" "2" "HTTP/2"
assert_control client-d "--http2-prior-knowledge" "2" "HTTP/2"

echo "==> HTTP/2: whitelist (client-a) + block (client-d)"
assert_burst client-a none "--http2-prior-knowledge" "HTTP/2"
assert_burst client-d some "--http2-prior-knowledge" "HTTP/2"

echo "PASS: mod_qos whitelist+block over HTTP/1.1 and HTTP/2 behind reverse proxy"
