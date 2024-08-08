FROM ghcr.io/coreruleset/modsecurity-crs:4.3.0-apache-alpine-202406090906

ENV ACCESSLOG=/dev/stdout \
    ERRORLOG=/dev/stderr \
    PERFLOG=/dev/stdout \
    METRICSLOG=/dev/stdout \
    MANUAL_MODE=true

USER root

# Disable all TLS related stuff (we'll have a reverse-proxy in front of us
# doing TLS termination)
# Also see the amended ./conf/httpd-vhosts.conf file.
RUN sed -i '/generate-certificate/d' /docker-entrypoint.sh

# Fix Permissions
# On OpenShift, the container will be started with a random UID and GID 0, so
# we have to make some directories group-writeable.
RUN chown -R 0:0 /usr/local/apache2/logs && \
    chmod g+w /usr/local/apache2/logs

# Customized configuration files
COPY ./conf/* /usr/local/apache2/conf/extra/

# TODO Add our own stuff here

USER 956947:0
