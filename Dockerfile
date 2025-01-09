FROM ghcr.io/coreruleset/modsecurity-crs:4.10.0-apache-alpine-202501050801

ENV ACCESSLOG=/dev/stdout \
    ERRORLOG='"|/usr/bin/stdbuf -i0 -oL /opt/transform-alert-message.awk"' \
    PERFLOG=/dev/stdout \
    LOGLEVEL=notice \
    TIMEOUT=5 \
    WORKER_CONNECTIONS=250 \
    MODSEC_AUDIT_LOG_PARTS=ABEFHIJZ \
    ANOMALY_INBOUND=1000 \
    ANOMALY_OUTBOUND=1000 \
    ALLOWED_METHODS='GET HEAD POST OPTIONS DELETE PUT PROPFIND' \
    ALLOWED_CONTENT='|application/x-www-form-urlencoded| |multipart/form-data| |text/xml| |application/xml| |application/x-amf| |application/json|' \
    ARG_NAME_LENGTH=256 \
    COMBINED_FILE_SIZES=100000000 \
    MAX_FILE_SIZE=100000000 \
    MAX_NUM_ARGS=300 \
    TOTAL_ARG_LENGTH=100000 \
    MODSEC_PCRE_MATCH_LIMIT=500000 \
    MODSEC_PCRE_MATCH_LIMIT_RECURSION=500000 \
    MODSEC_REQ_BODY_LIMIT=100000000 \
    MODSEC_REQ_BODY_NOFILES_LIMIT=5242880 \
    MODSEC_RESP_BODY_LIMIT=500000000 \
    CLAMD_DEBUG_LOG=off \
    # Use the default docker subnet as the default \
    HEALTHZ_CIDRS=172.18.0.0/24

USER root

RUN set -x && \
    # Install additional required tools \
    apk add --no-cache clamav-clamdscan coreutils gawk && \
    # We terminate TLS on the proxy; so remove all SSL config from the vhosts \
    sed -i '/<VirtualHost \*:${SSL_PORT}>/,/<\/VirtualHost>/d' /usr/local/apache2/conf/extra/httpd-vhosts.conf && \
    sed -i '/Include .*httpd-ssl.conf/d' /usr/local/apache2/conf/httpd.conf && \
    sed -i '/^\/usr\/local\/bin\/generate-certificate/d' /docker-entrypoint.sh && \
    # Disable CRS plugin system \
    sed -i '/activate-plugins/d' /docker-entrypoint.sh && \
    # Disable customized logging configuration - we'll configure this in \
    # ./conf/vshn-logging.conf \
    sed -i '/CustomLog /d' /usr/local/apache2/conf/httpd.conf

# Fix Permissions
# On OpenShift, the container will be started with a random UID and GID 0, so
# we have to make some directories group-writeable.
RUN chown -R 0:0 \
        /usr/local/apache2/logs \
        /opt/owasp-crs \
        && \
    chmod g+w \
        /usr/local/apache2/logs \
        /opt/owasp-crs

# Customized configuration files
COPY transform-alert-message.awk virus-check.pl /opt/
COPY clamd.conf /etc/clamav/clamd.conf
COPY conf/* /usr/local/apache2/conf/extra/
COPY modsecurity.d/setup.conf /etc/modsecurity.d/setup.conf

# Custom ModSecurity rules
COPY ./custom-rules/before-crs.dist /opt/modsecurity/rules/before-crs.dist
COPY ./custom-rules/after-crs.dist /opt/modsecurity/rules/after-crs.dist


USER 956947:0
