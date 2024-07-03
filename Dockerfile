FROM docker.io/owasp/modsecurity-crs:4.1.0-apache-202405050505

# Default values from upstream at the time of writing; redefined here to
# prevent issues when upstream defaults change.
ENV \
    BLOCKING_PARANOIA=1 \
    CRS_DISABLE_PLUGINS=0 \
    METRICSLOG=/dev/null \
    METRICS_ALLOW_FROM='127.0.0.0/255.0.0.0 ::1/128' \
    METRICS_DENY_FROM='All' \
    MODSEC_AUDIT_ENGINE=RelevantOnly \
    MODSEC_AUDIT_LOG=/dev/stdout \
    MODSEC_AUDIT_LOG_FORMAT=JSON \
    MODSEC_AUDIT_LOG_RELEVANT_STATUS='^(?:5|4(?!04))' \
    MODSEC_AUDIT_LOG_TYPE=Serial \
    MODSEC_AUDIT_STORAGE_DIR=/var/log/modsecurity/audit/ \
    MODSEC_DATA_DIR=/tmp/modsecurity/data \
    MODSEC_DEBUG_LOG=/dev/null \
    MODSEC_DEBUG_LOGLEVEL=0 \
    MODSEC_REQ_BODY_ACCESS=On \
    MODSEC_RESP_BODY_ACCESS=On \
    MODSEC_RULE_ENGINE=On \
    MODSEC_TAG=modsecurity \
    MODSEC_TMP_DIR=/tmp/modsecurity/tmp \
    MODSEC_UPLOAD_DIR=/tmp/modsecurity/upload \
    PORT=8080 \
    PROXY_PRESERVE_HOST=on \
    PROXY_SSL=off \
    PROXY_SSL_CA_CERT=/etc/ssl/certs/ca-certificates.crt \
    PROXY_SSL_CHECK_PEER_NAME=on \
    PROXY_SSL_VERIFY=none \
    PROXY_TIMEOUT=60 \
    REMOTEIP_INT_PROXY='10.1.0.0/16' \
    REQ_HEADER_FORWARDED_PROTO='https' \
    SERVER_ADMIN=root@localhost \
    SERVER_NAME=localhost
 
# Upstream; customized
ENV \
    ACCESSLOG=/proc/self/fd/1 \
    ALLOWED_METHODS='GET HEAD POST OPTIONS DELETE PUT PROPFIND' \
    ALLOWED_REQUEST_CONTENT_TYPE='|application/x-www-form-urlencoded| |multipart/form-data| |text/xml| |application/xml| |application/x-amf| |application/json|' \
    ANOMALY_INBOUND=1000 \
    ANOMALY_OUTBOUND=1000 \
    ARG_NAME_LENGTH=256 \
    COMBINED_FILE_SIZES=100000000 \
    ERRORLOG=/proc/self/fd/2 \
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
    TOTAL_ARG_LENGTH=100000

# Custom
ENV \
    APACHE_PERFLOG='/dev/stdout perflogjson env=write_perflog' \
    CLAMD_DEBUG_LOG=off \
    CLAMD_PORT=3310 \
    CLAMD_SERVER=127.0.0.1

USER root
COPY ./src/usr/local/apache2/conf/extra/httpd-vhosts.conf /usr/local/apache2/conf/extra/
COPY ./src/usr/local/apache2/conf/extra/httpd-logging.conf /usr/local/apache2/conf/extra/
COPY ./src/usr/local/apache2/conf/extra/deflate.conf /usr/local/apache2/conf/extra/
COPY ./src/docker-entrypoint.sh /docker-entrypoint.sh

RUN echo 'Include conf/extra/httpd-logging.conf' >> /usr/local/apache2/conf/httpd.conf \
 && echo 'Include conf/extra/deflate.conf' >> /usr/local/apache2/conf/httpd.conf \
 && echo 'TraceEnable Off' >> /usr/local/apache2/conf/extra/httpd-default.conf \
 && sed -i '/conf\/extra\/httpd-mpm\.conf/s/^#//' conf/httpd.conf \
 && sed -i '/proxy_wstunnel_module/s/^#//' conf/httpd.conf \
 && sed -i '/logio_module/s/^#//' conf/httpd.conf \
 && sed -i '/deflate_module/s/^#//' conf/httpd.conf \
 && sed -i '/Include conf\/extra\/httpd-ssl.conf/ s/^#*/#/' conf/httpd.conf \
 && sed -i '/CustomLog/s/modsec/extendedjson/' conf/httpd.conf

# Ensure config files cannot be overwritten at runtime ...
RUN chown -R 0:0 \
        /var/log/ \
        /usr/local/apache2/ \
        /etc/modsecurity.d \
        /opt/owasp-crs

# ... but deal with upstream's entrypoint writing to random locations in the FS
RUN chmod g+w \
    /opt/owasp-crs \
    /usr/local/apache2/logs

# Run under a "random" user ID
USER 1001330001
