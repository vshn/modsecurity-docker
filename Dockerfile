FROM ghcr.io/coreruleset/modsecurity-crs:4.3.0-apache-alpine-202406090906

ENV ACCESSLOG=/dev/stdout \
    ERRORLOG=/dev/stderr \
    PERFLOG=/dev/stdout \
    METRICSLOG=/dev/null

USER root
# TODO: Add our own stuff here
USER httpd
