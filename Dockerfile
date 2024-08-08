FROM ghcr.io/coreruleset/modsecurity-crs:4.3.0-apache-alpine-202406090906

ENV ACCESSLOG=/dev/stdout \
    ERRORLOG=/dev/stderr \
    PERFLOG=/dev/stdout \
    METRICSLOG=/dev/null

USER root
COPY ./modsecurity.d/setup.conf /etc/modsecurity.d/setup.conf
COPY ./conf/* /usr/local/apache2/conf/extra/
COPY ./custom-rules/before-crs.dist /opt/modsecurity/rules/before-crs.dist
COPY ./custom-rules/after-crs.dist /opt/modsecurity/rules/after-crs.dist
USER httpd
