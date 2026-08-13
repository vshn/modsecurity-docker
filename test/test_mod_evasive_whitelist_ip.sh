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

echo "WAF reachable, running mod_evasive whitelisted-IP test..."

# The docker bridge gateway IP (172.18.0.1) is in DOSWhitelist 172.*.*.*.
# /evasive-test is in DOSTargetlistUri and would normally block on rapid
# repeats, but the whitelisted client must NEVER receive a 403.
codes=""
n=0
while [ "$n" -lt 25 ]; do
    code=$(curl -s -o /dev/null -w "%{http_code}\n" "$WAF_URL/evasive-test")
    codes="$codes $code"
    n=$((n + 1))
done
echo "Whitelisted-IP /evasive-test codes:$codes"

case "$codes" in
    *403*)
        echo "ERROR: whitelisted IP got a 403, codes:$codes" >&2
        exit 1
        ;;
esac

echo "PASS: mod_evasive whitelisted-IP test succeeded"
exit 0