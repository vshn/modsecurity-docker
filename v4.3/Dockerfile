FROM docker.io/owasp/modsecurity-crs:4.3-apache-202406090906@sha256:36fc67d66f7761a6cb532c4855901a41792efa6e58303833c03aeed285c9c961 

# Default values from upstream at the time of writing; redefined here to
# prevent issues when upstream defaults change.
ENV \
    ACCESSLOG=/var/log/apache2/access.log \
    APACHE_ALWAYS_TLS_REDIRECT=off \
    APACHE_ERRORLOG_FORMAT='"[%{u}t] [%-m:%l] [pid %P:tid %T] %7F: %E: [client\ %a] %M% ,\ referer\ %{Referer}i"' \
    APACHE_LOGFORMAT='"%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-agent}i\""' \
    APACHE_METRICS_LOGFORMAT='"%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-agent}i\""' \
    BACKEND=http://localhost:8080 \
    BACKEND_WS=ws://localhost:8081 \
    ERRORLOG='/proc/self/fd/2' \
    H2_PROTOCOLS='h2 http/1.1' \
    LOGLEVEL=warn \
    METRICS_ALLOW_FROM='127.0.0.0/255.0.0.0 ::1/128' \
    METRICS_DENY_FROM='All' \
    METRICSLOG='/dev/null' \
    MODSEC_ARGUMENT_SEPARATOR="&" \
    MODSEC_ARGUMENTS_LIMIT=1000 \
    MODSEC_AUDIT_ENGINE="RelevantOnly" \
    MODSEC_AUDIT_LOG=/dev/stdout \
    MODSEC_AUDIT_LOG_FORMAT=JSON \
    MODSEC_AUDIT_LOG_PARTS='ABIJDEFHZ' \
    MODSEC_AUDIT_LOG_RELEVANT_STATUS="^(?:5|4(?!04))" \
    MODSEC_AUDIT_LOG_TYPE=Serial \
    MODSEC_COOKIE_FORMAT=0 \
    MODSEC_AUDIT_STORAGE_DIR=/var/log/modsecurity/audit/ \
    MODSEC_DATA_DIR=/tmp/modsecurity/data \
    MODSEC_DEBUG_LOG=/dev/null \
    MODSEC_DEBUG_LOGLEVEL=0 \
    MODSEC_DEFAULT_PHASE1_ACTION="phase:1,pass,log,tag:'\${MODSEC_TAG}'" \
    MODSEC_DEFAULT_PHASE2_ACTION="phase:2,pass,log,tag:'\${MODSEC_TAG}'" \
    MODSEC_DISABLE_BACKEND_COMPRESSION="On" \
    MODSEC_PCRE_MATCH_LIMIT=100000 \
    MODSEC_PCRE_MATCH_LIMIT_RECURSION=100000 \
    MODSEC_REQ_BODY_ACCESS=on \
    MODSEC_REQ_BODY_JSON_DEPTH_LIMIT=512 \
    MODSEC_REQ_BODY_LIMIT=13107200 \
    MODSEC_REQ_BODY_LIMIT_ACTION="Reject" \
    MODSEC_REQ_BODY_NOFILES_LIMIT=131072 \
    MODSEC_RESP_BODY_ACCESS=on \
    MODSEC_RESP_BODY_LIMIT=1048576 \
    MODSEC_RESP_BODY_LIMIT_ACTION="ProcessPartial" \
    MODSEC_RESP_BODY_MIMETYPE="text/plain text/html text/xml" \
    MODSEC_RULE_ENGINE=on \
    MODSEC_SERVER_SIGNATURE="Apache" \
    MODSEC_STATUS_ENGINE="Off" \
    MODSEC_TAG=modsecurity \
    MODSEC_TMP_DIR=/tmp/modsecurity/tmp \
    MODSEC_TMP_SAVE_UPLOADED_FILES="on" \
    MODSEC_UNICODE_MAPPING=20127 \
    MODSEC_UPLOAD_DIR=/tmp/modsecurity/upload \
    MODSEC_UPLOAD_FILE_MODE=0600 \
    MODSEC_UPLOAD_KEEP_FILES=RelevantOnly \
    MUTEX='default' \
    PORT=8080 \
    PROXY_ERROR_OVERRIDE=on \
    PROXY_PRESERVE_HOST=on \
    PROXY_SSL_CA_CERT=/etc/ssl/certs/ca-certificates.crt \
    PROXY_SSL_CERT_KEY=/usr/local/apache2/conf/proxy.key \
    PROXY_SSL_CERT=/usr/local/apache2/conf/proxy.crt \
    PROXY_SSL_CHECK_PEER_NAME=off \
    PROXY_SSL_CIPHERS="ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384" \
    PROXY_SSL=off \
    PROXY_SSL_PROTOCOLS="all -SSLv3 -TLSv1 -TLSv1.1" \
    PROXY_SSL_VERIFY=none \
    PROXY_TIMEOUT=60 \
    REMOTEIP_INT_PROXY='10.1.0.0/16' \
    REQ_HEADER_FORWARDED_PROTO='https' \
    SERVER_ADMIN=root@localhost \
    SERVER_NAME=localhost \
    SERVER_SIGNATURE=Off \
    SERVER_TOKENS=Full \
    SSL_CERT_KEY=/usr/local/apache2/conf/server.key \
    SSL_CERT=/usr/local/apache2/conf/server.crt \
    SSL_CIPHERS="ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384" \
    SSL_ENGINE=on \
    SSL_HONOR_CIPHER_ORDER=off \
    SSL_OCSP_STAPLING=On \
    SSL_PORT=8443 \
    SSL_PROTOCOLS="all -SSLv3 -TLSv1 -TLSv1.1" \
    SSL_SESSION_TICKETS=off \
    TIMEOUT=60 \
    WORKER_CONNECTIONS=400 \
    # CRS specific variables
    PARANOIA=1 \
    ANOMALY_INBOUND=5 \
    ANOMALY_OUTBOUND=4 \
    BLOCKING_PARANOIA=1
# Upstream; customized
ENV \
    ACCESSLOG=/proc/self/fd/1 \
    ALLOWED_METHODS='GET HEAD POST OPTIONS DELETE PUT PROPFIND' \
    ALLOWED_REQUEST_CONTENT_TYPE='|application/x-www-form-urlencoded| |multipart/form-data| |text/xml| |application/xml| |application/x-amf| |application/json|' \
    ANOMALY_INBOUND=1000 \
    ANOMALY_OUTBOUND=1000 \
    ARG_NAME_LENGTH=256 \
    COMBINED_FILE_SIZES=100000000 \
    ERRORLOG='"|/usr/bin/stdbuf -i0 -o0 /opt/transform-alert-message.awk"' \
    HTTPD_MAX_REQUEST_WORKERS=250 \
    LOGLEVEL=notice \
    MAX_FILE_SIZE=100000000 \
    MAX_NUM_ARGS=300 \
    MODSEC_AUDIT_LOG_PARTS=ABEFHIJZ \
    MODSEC_PCRE_MATCH_LIMIT=500000 \
    MODSEC_PCRE_MATCH_LIMIT_RECURSION=500000 \
    MODSEC_REQ_BODY_LIMIT=100000000 \
    MODSEC_REQ_BODY_NOFILES_LIMIT=5242880 \
    MODSEC_RESP_BODY_LIMIT=500000000 \
    SSL_ENGINE=off \
    TIMEOUT=5 \
    TOTAL_ARG_LENGTH=100000 \
	WORKER_CONNECTIONS=250 

# Custom
ENV \
    APACHE_PERFLOG='/dev/stdout perflogjson env=write_perflog'
    
USER root
COPY ./config/apache/httpd-vhosts.conf /usr/local/apache2/conf/extra/
COPY ./config/apache/httpd-logging.conf /usr/local/apache2/conf/extra/
COPY ./config/apache/deflate.conf /usr/local/apache2/conf/extra/
COPY ./scripts/docker-entrypoint.sh /docker-entrypoint.sh
COPY ./scripts/transform-alert-message.awk ./scripts/virus-check.pl /opt/
COPY ./config/modsecurity.d/include.conf /etc/modsecurity.d/setup.conf

RUN echo 'Include conf/extra/httpd-logging.conf' >> /usr/local/apache2/conf/httpd.conf \
	&& echo 'Include conf/extra/deflate.conf' >> /usr/local/apache2/conf/httpd.conf \
	&& echo 'TraceEnable Off' >> /usr/local/apache2/conf/extra/httpd-default.conf \
	&& sed -i '/conf\/extra\/httpd-mpm\.conf/s/^#//' conf/httpd.conf \
	&& sed -i '/proxy_wstunnel_module/s/^#//' conf/httpd.conf \
	&& sed -i '/logio_module/s/^#//' conf/httpd.conf \
	&& sed -i '/deflate_module/s/^#//' conf/httpd.conf \
	&& sed -i '/Include conf\/extra\/httpd-ssl.conf/ s/^#*/#/' conf/httpd.conf \
	&& sed -i '/CustomLog/s/modsec/extendedjson/' conf/httpd.conf 

RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
	  vim \
      clamdscan \
      gawk \
      gettext-base \
 	&& apt-get autoremove --purge -y \
 	&& apt-get clean \
 	&& rm -rf /var/lib/apt/lists/*

COPY ./config/clamd.conf /etc/clamav/clamd.conf

# Ensure config files cannot be overwritten at runtime ...
RUN chown -R 0:0 \
    /var/log/ \
    /usr/local/apache2/ \
    /etc/modsecurity.d \
    /opt/owasp-crs

# ... but deal with upstream's entrypoint writing to random locations in the FS
RUN chmod g+w \
    /opt/owasp-crs \
    /usr/local/apache2/logs \
	/etc/modsecurity.d

# Run under a "random" user ID
USER 1001330001
