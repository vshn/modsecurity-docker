#!/bin/sh

mkdir -p "${MODSEC_AUDIT_STORAGE}" \
         "${MODSEC_DATA_DIR}" \
         "${MODSEC_TMP_DIR}" \
         "${MODSEC_UPLOAD_DIR}"

exec /docker-entrypoint.sh "$@"
