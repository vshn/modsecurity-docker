FROM docker.io/vshn/modsecurity-crs:v3.1

ENV APACHE_RUN_USER=www-data \
    APACHE_RUN_GROUP=root \
    SERVER_ADMIN=root@localhost \
    SERVER_NAME=localhost \
    PORT=8080 \
    BACKEND=http://localhost:8080 \
    BACKEND_WS=ws://localhost:8080 \
    APACHE_TIMEOUT=5 \
    APACHE_LOGLEVEL=notice \
    APACHE_ERRORLOG='"|/usr/bin/stdbuf -i0 -o0 /opt/transform-alert-message.awk"' \
    APACHE_ACCESSLOG='/dev/stdout extendedjson' \
    APACHE_PERFLOG='/dev/stdout perflogjson env=write_perflog' \
    APACHE_METRICSLOG='/dev/null combined' \
    APACHE_METRICS_DENY_FROM='All' \
    APACHE_METRICS_ALLOW_FROM='127.0.0.0/255.0.0.0 ::1/128' \
    MODSEC_AUDIT_LOG=/dev/stdout \
    MODSEC_AUDIT_LOG_TYPE=Serial \
    MODSEC_AUDIT_LOG_FORMAT=JSON \
    MODSEC_AUDIT_STORAGE=/var/log/modsecurity/audit/ \
    MODSEC_DEBUG_LOG=/dev/null \
    MODSEC_DEBUG_LOGLEVEL=0 \
    MODSEC_DATA_DIR=/tmp/modsecurity/data \
    MODSEC_TMP_DIR=/tmp/modsecurity/tmp \
    MODSEC_UPLOAD_DIR=/tmp/modsecurity/upload \
    MODSEC_ALLOWED_METHODS='GET HEAD POST OPTIONS DELETE PUT PROPFIND' \
    MODSEC_ALLOWED_CONTENT='application/x-www-form-urlencoded|multipart/form-data|text/xml|application/xml|application/x-amf|application/json' \
    MODSEC_ARG_NAME_LENGTH=256 \
    MODSEC_MAX_NUM_ARGS=300 \
    MODSEC_MAX_FILE_SIZE=100000000 \
    MODSEC_MAX_COMBINED_SIZE=100000000 \
    MODSEC_TAG=modsecurity \
    RULE_ENGINE=on \
    REMOTEIP_INT_PROXY='10.1.0.0/16' \
    REQ_HEADER_FORWARDED_PROTO='https' \
    REQ_BODY_LIMIT=100000000 \
    REQ_BODY_NOFILES_LIMIT=5242880 \
    REQ_BODY_ACCESS=on \
    RESP_BODY_ACCESS=on \
    RESP_BODY_LIMIT=500000000 \
    PCRE_MATCH_LIMIT=500000 \
    PCRE_MATCH_LIMIT_RECURSION=500000 \
    PROXY_PRESERVE_HOST=on \
    PROXY_SSL=off \
    PROXY_SSL_VERIFY=none \
    PROXY_SSL_CHECK_PEER_NAME=on \
    PROXY_SSL_CA_CERT=/etc/ssl/certs/ca-certificates.crt \
    PROXY_TIMEOUT=42 \
    PARANOIA=1 \
    ANOMALY_INBOUND=1000 \
    ANOMALY_OUTBOUND=1000 \
    HTTPD_MAX_REQUEST_WORKERS=250 \
    CLAMD_SERVER=127.0.0.1 \
    CLAMD_PORT=3310 \
    CLAMD_DEBUG_LOG=off

COPY ports.conf /etc/apache2/
COPY sites-available /etc/apache2/sites-available
COPY conf-available /etc/apache2/conf-available
COPY modsecurity.d /etc/apache2/modsecurity.d
COPY custom-rules/before-crs.dist /opt/modsecurity/rules/before-crs.dist
COPY custom-rules/after-crs.dist /opt/modsecurity/rules/after-crs.dist
COPY transform-alert-message.awk virus-check.pl /opt/

# fix hack of upstream image, enable confs and modules, install clamdscan
RUN mv -v /etc/apache2/conf-enabled/security.conf /etc/apache2/conf-available/ \
 && sed -i /etc/apache2/apache2.conf \
   -e 's/^LogLevel .*$/LogLevel ${APACHE_LOGLEVEL}/' \
   -e 's/^ErrorLog .*$/ErrorLog ${APACHE_ERRORLOG}/' \
   -e 's/^Timeout 300$/Timeout ${APACHE_TIMEOUT}/' \
 && sed -i /etc/apache2/mods-available/mpm_event.conf \
   -e 's/MaxRequestWorkers .*/MaxRequestWorkers ${HTTPD_MAX_REQUEST_WORKERS}/' \
 && ln -sfv /dev/stdout /var/log/apache2/access.log \
 && ln -sfv /dev/stderr /var/log/apache2/error.log \
 && a2enconf logging security \
 && a2enmod \
      headers \
      proxy_wstunnel \
      remoteip \
      rewrite \
      ssl

COPY clamd.conf.template /etc/clamav/

RUN mkdir /tmp/geoip \
 && cd /tmp/geoip \
 && apt-get update \
 && apt-get install -y --no-install-recommends \
      clamdscan \
      curl \
      gawk \
      geoip-bin \
      gettext-base \
      python-pip \
      python-setuptools \
 && python -m pip install --no-cache-dir \
      ipaddr \
      pygeoip \
 && curl -s -o geoip-convert https://raw.githubusercontent.com/emphazer/GeoIP_convert-v2-v1/master/geoip_convert-v2-v1.sh \
 && chmod +x geoip-convert \
 && echo 'Converting GeoLite2 databases to legacy format ...' \
 && ./geoip-convert \
 && mv -v */GeoIP_country.dat /opt/owasp-modsecurity-crs/util/geo-location/ \
 && python -m pip uninstall -y \
     ipaddr \
     pygeoip \
 && apt-get purge -y \
     curl \
     geoip-bin \
     python-pip \
 && apt-get autoremove --purge -y \
 && apt-get clean \
 && rm -rf /tmp/geoip /var/lib/apt/lists/*

RUN mkdir -p \
    /opt/modsecurity/rules/after-crs \
    /opt/modsecurity/rules/before-crs \
    /tmp/modsecurity/data \
    /tmp/modsecurity/tmp \
    /tmp/modsecurity/upload \
    /var/lock/apache2 \
    /var/log/modsecurity/audit \
 && chgrp -R 0 \
    /etc/apache2 \
    /etc/modsecurity.d \
    /opt/modsecurity \
    /tmp/modsecurity \
    /var/lock/apache2 \
    /var/log \
    /var/run \
    /var/www/html \
 && chmod -R g=u \
    /etc/apache2 \
    /etc/clamav \
    /etc/modsecurity.d \
    /opt/modsecurity \
    /tmp/modsecurity \
    /var/lock/apache2 \
    /var/log \
    /var/run \
    /var/www/html

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT [ "/entrypoint.sh" ]
CMD ["apachectl", "-D", "FOREGROUND"]
