ARG MODSEC_BASE_IMAGE=ghcr.io/coreruleset/modsecurity-crs:4.27.0-apache-202606290906@sha256:f7c95cb9ef6e7948a20f91e914f9d03d27b5e8fd3a95c585e14c62607ad91cd8

# ---- mod_qos build stage -------------------------------------------------
# mod_qos is not packaged in Debian/Alpine, so compile it from source in a
# separate stage. Only the resulting mod_qos.so is copied into the runtime
# image, keeping the build toolchain out of the final image.
FROM ${MODSEC_BASE_IMAGE} AS qos-builder
USER root
ARG MOD_QOS_VERSION=11.79
ARG MOD_QOS_SHA256=314a60638be42203cd0ed6ed1fe22085c082919545561387db4e7cb35594d755
RUN set -x && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential libpcre2-dev libssl-dev libapr1-dev libaprutil1-dev ca-certificates && \
    rm -rf /var/lib/apt/lists/* && \
    curl --cacert /etc/ssl/certs/ca-certificates.crt -fsSL \
        -o /tmp/mod_qos-${MOD_QOS_VERSION}.tar.gz \
        "https://downloads.sourceforge.net/project/mod-qos/mod_qos-${MOD_QOS_VERSION}.tar.gz" && \
    echo "${MOD_QOS_SHA256}  /tmp/mod_qos-${MOD_QOS_VERSION}.tar.gz" | sha256sum -c - && \
    tar -xzf /tmp/mod_qos-${MOD_QOS_VERSION}.tar.gz -C /tmp && \
    cd /tmp/mod_qos-${MOD_QOS_VERSION}/apache2 && \
    /usr/local/apache2/bin/apxs -i -c mod_qos.c -lcrypto -lpcre2-8 && \
    rm -rf /tmp/mod_qos-*

# ---- runtime image -------------------------------------------------------
FROM ${MODSEC_BASE_IMAGE}

ENV ACCESSLOG=/dev/stdout \
    MOD_QOS_ENABLED=disabled \
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
	apt-get update && \
	apt-get install -y --no-install-recommends \
		clamdscan \
		coreutils \
		gawk && \
    rm -rf /var/lib/apt/lists/* && \
	apt-get clean && \
    # Restore AWK symlink - our transform-alert-message script assumes GNU awk,\
	# while the default awk implementation of the base image is mawk. \
	ln -sfv /etc/alternatives/awk /usr/bin/awk && \
    # We terminate TLS on the proxy; so remove all SSL config from the vhosts \
    sed -i '/<VirtualHost \*:${SSL_PORT}>/,/<\/VirtualHost>/d' /usr/local/apache2/conf/extra/httpd-vhosts.conf && \
    sed -i '/Include .*httpd-ssl.conf/d' /usr/local/apache2/conf/httpd.conf && \
    sed -i '/^\/usr\/local\/bin\/generate-certificate/d' /docker-entrypoint.sh && \
	#Make sure the ProxyPass setting for error-pages is included prior to the ones in vhost settings \
	sed -i '/httpd-modsecurity.conf/d' /usr/local/apache2/conf/httpd.conf && \
	sed -i '/# Virtual hosts/i\Include conf/extra/httpd-modsecurity.conf' /usr/local/apache2/conf/httpd.conf && \
    # Disable CRS plugin system \
    sed -i '/activate-plugins/d' /docker-entrypoint.sh && \
    # Disable customized logging configuration - we'll configure this in \
    # ./conf/vshn-logging.conf \
    sed -i '/CustomLog /d' /usr/local/apache2/conf/httpd.conf

# Fix Permissions
# On OpenShift, the container will be started with a random UID and GID 0, so
# we have to make some directories group-writeable.
RUN chgrp -R 0 /opt/owasp-crs && \
    chmod -R g+rwX /opt/owasp-crs
RUN chgrp -R 0 /usr/local/apache2/logs && \
    chmod -R g+rwX /usr/local/apache2/logs

# Customized configuration files
COPY opt/* /opt/
COPY clamd-config/* /etc/clamav/
COPY apache-config/* /usr/local/apache2/conf/extra/
COPY modsecurity.d/setup.conf /etc/modsecurity.d/setup.conf

# mod_qos module (built in the qos-builder stage). Inert by default; activated
# via MOD_QOS_ENABLED=on + a conf/extra/qos-rules-on.conf (see vshn-qos.conf).
COPY --from=qos-builder /usr/local/apache2/modules/mod_qos.so /usr/local/apache2/modules/mod_qos.so

# Custom ModSecurity rules
COPY ./custom-rules/before-crs.dist /opt/modsecurity/rules/before-crs.dist
COPY ./custom-rules/after-crs.dist /opt/modsecurity/rules/after-crs.dist

USER 56947:0
