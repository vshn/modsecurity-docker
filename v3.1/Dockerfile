# Base image: https://hub.docker.com/r/owasp/modsecurity-crs/dockerfile

FROM owasp/modsecurity-crs:v3.1

ENV PARANOIA_LEVEL=1 \
    PORT=8080 \
    HTTPD_SERVER_LIMIT=16 \
    BACKEND=http://localhost:8080 \
    REQ_BODY_LIMIT=100000000 \
    REQ_BODY_NOFILES_LIMIT=5242880 \
    RULE_ENGINE=On \
    REQ_BODY_ACCESS=On \
    RESP_BODY_ACCESS=On \
    RESP_BODY_LIMIT=500000000 \
    PCRE_MATCH_LIMIT=500000 \
    PCRE_MATCH_LIMIT_RECURSION=500000 \
    MODSEC_TAG=modsecurity \
    MODSEC_MAX_NUM_ARGS=300 \
    MODSEC_ARG_NAME_LENGTH=256 \
    I_ANOMALY_SCORE_TH=1000 \
    O_ANOMALY_SCORE_TH=1000 \
    SERVER_NAME=localhost \
    PROXY_TIMEOUT=120 \
    HTTPD_MAX_REQUEST_WORKERS=250

# COPY conf/httpd.conf /etc/apache2/conf/httpd.conf

COPY modsecurity.d/modsecurity.conf /etc/apache2/modsecurity.d/
COPY sites-available/000-default.conf /etc/apache2/sites-available/

# fix hack of upstream image, enable confs and modules
RUN mv -v /etc/apache2/conf-enabled/security.conf /etc/apache2/conf-available/ \
 && a2enconf security \
 && a2enmod headers

RUN mkdir -p \
 /var/lock/apache2 \
 /modsecurity/tmp \
 /modsecurity/data/upload \
 /modsecurity/data/audit \
 /modsecurity/data/log \
 /modsecurity/rules/before-crs \
 /modsecurity/rules/after-crs \
 && chgrp -R 0 \
 /etc/apache2/ \
 /var/run/ \
 /var/log/ \
 /var/www/html/ \
 /var/lock/apache2 \
 /modsecurity \
 && chmod -R g=u \
 /etc/apache2/ \
 /var/run/ \
 /var/log/ \
 /var/www/html/ \
 /var/lock/apache2 \
 /modsecurity
