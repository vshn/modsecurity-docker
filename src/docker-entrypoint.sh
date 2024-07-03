#!/bin/env bash
set -e -o pipefail -x

. /opt/modsecurity/activate-plugins.sh
. /opt/modsecurity/activate-rules.sh

exec "$@"
