#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR=$(realpath "$(dirname "$0")")
COMPOSE=(docker compose -f "${SCRIPT_DIR}/compose.proxy.test.yml" -p modsec-qos-proxy-test)
WAF="http://reverse-proxy:8080"

code_of() { local c="$1"; shift; "${COMPOSE[@]}" exec -T "$c" curl -s -o /dev/null -w '%{http_code}' "$@" 2>/dev/null || true; }
ver_of() { local c="$1"; shift; "${COMPOSE[@]}" exec -T "$c" curl -s -o /dev/null -w '%{http_version}' "$@" 2>/dev/null || true; }

assert_burst() {
  local client="$1" expect="$2" flags="$3" label="$4" path="$5" count="${6:-6}"
  local codes="" blocked=0 code
  for i in $(seq 1 "$count"); do
    code="$(code_of "$client" $flags "${WAF}/${path}")"
    codes="${codes} ${code}"
    if [ "${code}" -ge 500 ] 2>/dev/null && [ "${code}" -lt 600 ] 2>/dev/null; then
      blocked=$((blocked + 1))
    fi
  done
  echo "    ${label} ${client} /${path}:${codes} blocked=${blocked}"
  if [ "${expect}" = "none" ] && [ "${blocked}" -ne 0 ]; then
    echo "FAIL: ${client} blocked ${blocked} on /${path} (expected 0, whitelist not working)" >&2; exit 1
  fi
  if [ "${expect}" = "some" ] && [ "${blocked}" -le 0 ]; then
    echo "FAIL: ${client} not blocked on /${path} (expected >=1)" >&2; exit 1
  fi
}

assert_allow_no_burn() {
  local client="$1" allow="$2" blockpath="$3" thr="$4" label="$5" flags="${6:-}"
  local codes="" code i ablocked=0 bad=0
  for i in $(seq 1 10); do
    code="$(code_of "$client" $flags "${WAF}/${allow}")"; codes="${codes} ${code}"
    [ -z "${code}" -o "${code}" = "000" ] && bad=$((bad + 1))
    if [ "${code}" -ge 500 ] 2>/dev/null && [ "${code}" -lt 600 ] 2>/dev/null; then ablocked=$((ablocked + 1)); fi
  done
  local bpass=0 bcode
  for i in $(seq 1 "$((thr + 1))"); do
    bcode="$(code_of "$client" $flags "${WAF}/${blockpath}")"; codes="${codes} ${bcode}"
    [ -z "${bcode}" -o "${bcode}" = "000" ] && bad=$((bad + 1))
    if [ "${bcode}" -ge 500 ] 2>/dev/null && [ "${bcode}" -lt 600 ] 2>/dev/null; then break; fi
    bpass=$((bpass + 1))
  done
  echo "    ${label} ${client} /${allow}(10)+/${blockpath}:${codes} blockpass_before=${bpass}"
  # empty/000 responses mean curl never reached the waf (e.g. a stray "" arg as URL) -> fail loudly
  [ "$bad" -eq 0 ] || { echo "FAIL: ${client} got ${bad} empty/000 responses on /${allow}+/${blockpath} (test infra broken)" >&2; exit 1; }
  [ "$ablocked" -eq 0 ] || { echo "FAIL: ${client} allow-path /${allow} blocked ${ablocked} (expected 0)" >&2; exit 1; }
  if [ "${bpass}" -lt "$((thr - 1))" ]; then
    echo "FAIL: ${client} only ${bpass} passes on /${blockpath} after /${allow} (allow burned quota, expected >=$((thr-1)))" >&2; exit 1
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
"${COMPOSE[@]}" up --force-recreate -d --wait --build

# controls MUST run before any burst: mod_qos evaluates `counter >= threshold` every request
# regardless of which path filled the counter, so an already-blocked client's /anything is also blocked.
echo "==> HTTP/1.1: controls"
assert_control client-a "" "1.1" "HTTP/1.1"
assert_control client-b "" "1.1" "HTTP/1.1"
assert_control client-c "" "1.1" "HTTP/1.1"
assert_control client-d "" "1.1" "HTTP/1.1"

echo "==> HTTP/1.1: per-location thresholds (blockslow=3, blockfast=6) + allow-location (don't-burn-quota)"
assert_allow_no_burn client-d allowalways blockslow 3 "HTTP/1.1 allow"
assert_burst client-d some "" "HTTP/1.1" blockfast 8
assert_burst client-d some "" "HTTP/1.1" blockme 6

echo "==> HTTP/1.1: IP whitelist (client-a/b/c) for each active limit var"
assert_burst client-a none "" "HTTP/1.1" blockslow 6
assert_burst client-b none "" "HTTP/1.1" blockslow 6
assert_burst client-c none "" "HTTP/1.1" blockslow 6
assert_burst client-a none "" "HTTP/1.1" blockfast 8
assert_burst client-a none "" "HTTP/1.1" blockme 6

echo "==> HTTP/1.1: per-IP status-throttle (threshold 2 on 409; NOT IP-whitelistable)"
# /status/409 (httpbun echoes 409) is the ONLY path that produces 409 -> stat409 counter is independent
# of the blockslow/blockfast/blockme QS_Limit vars. client-d is NOT whitelisted; client-a IS whitelisted
# via QOS_EXCLUDE_IP -> asserting client-a ALSO blocked proves status-throttle is NOT IP-whitelistable.
assert_burst client-d some "" "HTTP/1.1 status-409" status/409 5
assert_burst client-a some "" "HTTP/1.1 status-409 (IP-wl)" status/409 5

echo "==> restarting waf for HTTP/2 tests (also resets mod_qos in-memory counters)"
"${COMPOSE[@]}" restart waf
"${COMPOSE[@]}" up -d --wait

echo "==> HTTP/2: controls"
assert_control client-a "--http2-prior-knowledge" "2" "HTTP/2"
assert_control client-d "--http2-prior-knowledge" "2" "HTTP/2"

echo "==> HTTP/2: per-location thresholds + allow"
assert_allow_no_burn client-d allowalways blockslow 3 "HTTP/2 allow" "--http2-prior-knowledge"
assert_burst client-a none "--http2-prior-knowledge" "HTTP/2" blockslow 6
assert_burst client-d some "--http2-prior-knowledge" "HTTP/2" blockslow 6
assert_burst client-d some "--http2-prior-knowledge" "HTTP/2" blockfast 8

echo "PASS: mod_qos per-location thresholds, allow-location (don't-count), IP whitelist over HTTP/1.1 and HTTP/2"