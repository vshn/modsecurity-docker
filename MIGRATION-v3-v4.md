# Migration from v3 to v4

## Environment variables

```sh
# Upstream; set to upstream default
APACHE_METRICSLOG='/dev/null combined' # TODO: move to `METRICSLOG=/dev/null`
APACHE_METRICS_ALLOW_FROM='127.0.0.0/255.0.0.0 ::1/128' # TODO: move to `METRICS_ALLOW_FROM`
APACHE_METRICS_DENY_FROM='All' # TODO: move to `METRICS_DENY_FROM`
CRS_DISABLE_PLUGINS=0
MODSEC_AUDIT_ENGINE=RelevantOnly
MODSEC_AUDIT_LOG=/dev/stdout
MODSEC_AUDIT_LOG_FORMAT=JSON
MODSEC_AUDIT_LOG_RELEVANT_STATUS='^(?:5|4(?!04))'
MODSEC_AUDIT_LOG_TYPE=Serial
MODSEC_AUDIT_STORAGE=/var/log/modsecurity/audit/ # was renamed(?) to MODSEC_AUDIT_STORAGE_DIR
MODSEC_DATA_DIR=/tmp/modsecurity/data
MODSEC_DEBUG_LOG=/dev/null
MODSEC_DEBUG_LOGLEVEL=0
MODSEC_TAG=modsecurity
MODSEC_TMP_DIR=/tmp/modsecurity/tmp
MODSEC_UPLOAD_DIR=/tmp/modsecurity/upload
PARANOIA=1 # TODO: new: BLOCKING_PARANOIA
PORT=8080
PROXY_PRESERVE_HOST=on
PROXY_SSL=off
PROXY_SSL_CA_CERT=/etc/ssl/certs/ca-certificates.crt
PROXY_SSL_CHECK_PEER_NAME=on
PROXY_SSL_VERIFY=none
PROXY_TIMEOUT=60
REMOTEIP_INT_PROXY='10.1.0.0/16'
REQ_BODY_ACCESS=on # TODO: move to `MODSEC_REQ_BODY_ACCESS=On`
REQ_HEADER_FORWARDED_PROTO='https'
RESP_BODY_ACCESS=on #TODO: move to `MODSEC_RESP_BODY_ACCESS=On`
RULE_ENGINE=on # TODO: move to `MODSEC_RULE_ENGINE=On`
SERVER_ADMIN=root@localhost
SERVER_NAME=localhost

# Upstream; customized
ANOMALY_INBOUND=1000
ANOMALY_OUTBOUND=1000
APACHE_LOGLEVEL=notice # TODO: new: `LOGLEVEL`
APACHE_TIMEOUT=5 # TODO: new: `TIMEOUT`
HTTPD_MAX_REQUEST_WORKERS=250 # TODO: new: `WORKER_CONNECTIONS`
MODSEC_AUDIT_LOG_PARTS=ABEFHIJZ
MODSEC_MAX_COMBINED_SIZE=100000000 # TODO: new: COMBINED_FILE_SIZES

# Upstream; customized stuff that needs its `MODSEC_` prefix REMOVED
MODSEC_ALLOWED_CONTENT='|application/x-www-form-urlencoded| |multipart/form-data| |text/xml| |application/xml| |application/x-amf| |application/json|' # TODO: new: `ALLOWED_REQUEST_CONTENT_TYPE`
MODSEC_ALLOWED_METHODS='GET HEAD POST OPTIONS DELETE PUT PROPFIND' # TODO: new `ALLOWED_METHODS`
MODSEC_ARG_NAME_LENGTH=256 #TODO: new: ARG_NAME_LENGTH
MODSEC_MAX_FILE_SIZE=100000000 # TODO: new: `MAX_FILE_SIZE`
MODSEC_MAX_NUM_ARGS=300 # TODO: new: `MAX_NUM_ARGS`

# Upstream; customized stuff that needs its `MODSEC_` prefix ADDED
PCRE_MATCH_LIMIT=500000
PCRE_MATCH_LIMIT_RECURSION=500000
REQ_BODY_LIMIT=100000000 # TODO: new: `MODSEC_REQ_BODY_LIMIT`
REQ_BODY_NOFILES_LIMIT=5242880 # TODO: new: `MODSEC_REQ_BODY_NOFILES_LIMIT`
RESP_BODY_LIMIT=500000000 # TODO: new: `MODSEC_RESP_BODY_LIMIT`

# Custom
APACHE_PERFLOG='/dev/stdout perflogjson env=write_perflog'
CLAMD_DEBUG_LOG=off
CLAMD_PORT=3310
CLAMD_SERVER=127.0.0.1
MODSEC_ARGS_COMBINED_SIZE=100000 # TODO: does not exist in upstream?

# obsolete
# APACHE_RUN_USER=www-data
# APACHE_RUN_GROUP=root

# TODO: should be changed to
# ERRORLOG=/proc/self/fd/2
#
# APACHE_ERRORLOG='"|/usr/bin/stdbuf -i0 -o0 /opt/transform-alert-message.awk"'

# TODO: should be changed to:
# ACCESSLOG=/proc/self/fd/1
# APACHE_LOGFORMAT=extendedjson
#
# APACHE_ACCESSLOG='/dev/stdout extendedjson'

# those do not really make sense? loopback anyone?
# BACKEND=http://localhost:8080
# BACKEND_WS=ws://localhost:8080
```
