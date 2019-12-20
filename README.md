# ModSecurity Docker image

[![dockeri.co](http://dockeri.co/image/vshn/modsecurity)](https://hub.docker.com/r/vshn/modsecurity/)

[![Build Status](https://img.shields.io/docker/cloud/build/vshn/modsecurity.svg)](https://hub.docker.com/r/vshn/modsecurity/builds
) [![GitHub issues](https://img.shields.io/github/issues-raw/vshn/modsecurity-docker.svg)](https://github.com/vshn/modsecurity-docker/issues
) [![GitHub PRs](https://img.shields.io/github/issues-pr-raw/vshn/modsecurity-docker.svg)](https://github.com/vshn/modsecurity-docker/pulls
) [![License](https://img.shields.io/github/license/vshn/modsecurity-docker.svg)](https://github.com/vshn/modsecurity-docker/blob/master/LICENSE)

Based on the official [`owasp/modsecurity-crs`](https://hub.docker.com/r/owasp/modsecurity-crs) image.

* Contains the necessary tweaks to run on [OpenShift](https://www.openshift.com/).
* Uses the [GeoLite2 Country Database](https://dev.maxmind.com/geoip/geoip2/geolite2/) provided
  by MaxMind under the [CC BY-SA 4.0 license](https://creativecommons.org/licenses/by-sa/4.0/).
* Includes [ClamAV anti-virus scanner](https://www.clamav.net/) provided by Cisco-TALOS under the
  [GPL v2 (or later) license](https://github.com/Cisco-Talos/clamav-devel/blob/master/COPYING).

## Supported Tags

* [![latest](
  https://img.shields.io/badge/latest-blue.svg?colorA=22313f&colorB=4a637b&logo=docker)](
  https://github.com/vshn/modsecurity-docker/blob/master/v3.1/Dockerfile) [![size/layers](
  https://images.microbadger.com/badges/image/vshn/modsecurity:latest.svg)](
  https://microbadger.com/images/vshn/modsecurity:latest) [![based on](
  https://img.shields.io/badge/Git-master-grey.svg?colorA=5a5b5c&colorB=9a9b9c&logo=github)](
  https://github.com/SpiderLabs/owasp-modsecurity-crs/tree/v3.1/dev/util/docker) (v3.1)
* [![3.1](
  https://img.shields.io/badge/3.1-blue.svg?colorA=22313f&colorB=4a637b&logo=docker)](
  https://github.com/vshn/modsecurity-docker/blob/master/v3.1/Dockerfile) [![size/layers](
  https://images.microbadger.com/badges/image/vshn/modsecurity:3.1.svg)](
  https://microbadger.com/images/vshn/modsecurity:3.1) [![based on](
  https://img.shields.io/badge/Git-master-grey.svg?colorA=5a5b5c&colorB=9a9b9c&logo=github)](
  https://github.com/SpiderLabs/owasp-modsecurity-crs/tree/v3.1/dev/util/docker) (ModSecurity 2, CRS v3.1)

## Usage

Ad-hoc usage and debugging:

```console
$ docker run -p 80:80 -it -e PARANOIA=4 --rm vshn/modsecurity bash
```

With a Dockerfile:

```Dockerfile
FROM vshn/modsecurity:3.1

ENV PARANOIA=1 \
    ANOMALY_INBOUND=500 \
    ANOMALY_OUTBOUND=400 \
    PORT=8000 \
    BACKEND=http://facade-svc:9000

VOLUME /opt/modsecurity/rules/before-crs
VOLUME /opt/modsecurity/rules/after-crs
VOLUME /var/log/modsecurity
VOLUME /tmp/modsecurity
```

With Docker Compose to start a ModSecurity and a httpbin container:

```console
cd v3.1
docker-compose up
```

When the containers are running, you can make requests like:
```console
curl -i http://localhost:8080/anything

curl -i -H 'Host: vshn.ch' http://localhost:8080/anything

curl -i http://localhost:8080/cookies/set/secret/random-value
```

For all supported endpoints have a look at [httpbin.org](https://httpbin.org).

## Configuration

There are a variety of environment variables available to configure the image.

*Most important are the following ones:*

* PARANOIA (Default: `1`)
  * Ranging from 1-4. Have a look at the section *'What are paranoia levels, and
    which level should I choose?'* at [coreruleset.org/faq/](https://coreruleset.org/faq/).
* ANOMALY_INBOUND (Default: `1000`)
  * inbound anomaly score threshold; start with 1000 and try to bring it down to 5
* ANOMALY_OUTBOUND (Default: `1000`)
  * outbound anomaly score threshold; start with 1000 and try to bring it down to 4
* PORT (Default: `8080`)
  * Port the Apache process should listen on
* BACKEND
  * The IP/URL of the service which should be secured by ModSecurity.
* BACKEND_WS
  * The IP/URL of the WebSocket service (if used)

### ModSecurity

* RULE_ENGINE
  * `SecRuleEngine`
* REQ_BODY_ACCESS
  * `SecRequestBodyAccess`
* RESP_BODY_ACCESS
  * `SecResponseBodyAccess`
* REQ_BODY_LIMIT
  * `SecResponseBodyLimit`
* RESP_BODY_LIMIT
  * `SecRequestBodyLimit`
* REQ_BODY_NOFILES_LIMIT
  * `SecRequestBodyNoFilesLimit`
* PCRE_MATCH_LIMIT
  * `SecPcreMatchLimit`
* PCRE_MATCH_LIMIT_RECURSION
  * `SecPcreMatchLimitRecursion`
* MODSEC_TAG
  * `SecDefaultAction` tag
* MODSEC_ALLOWED_METHODS
  * `tx.allowed_methods`
* MODSEC_ALLOWED_CONTENT
  * `tx.allowed_request_content_type`
* MODSEC_ARG_NAME_LENGTH
  * `tx.arg_name_length`
* MODSEC_MAX_NUM_ARGS
  * `tx.max_num_args`
* MODSEC_MAX_FILE_SIZE
  * `tx.max_file_size`
* MODSEC_MAX_COMBINED_SIZE
  * `tx.combined_file_sizes`
* MODSEC_DEBUG_LOG
  * `SecDebugLog`
* MODSEC_DEBUG_LOGLEVEL
  * `SecDebugLogLevel`
* MODSEC_AUDIT_LOG_TYPE
  * `SecAuditLogType`
* MODSEC_AUDIT_LOG_FORMAT
  * `SecAuditLogFormat`
* MODSEC_AUDIT_LOG
  * `SecAuditLog`
* MODSEC_AUDIT_STORAGE
  * `SecAuditLogStorageDir`

For the default values look at the `Dockerfile`.

### Apache

* APACHE_RUN_USER
  * system user the Apache process should use
* APACHE_RUN_GROUP
  * system group the Apache process should use
* HTTPD_MAX_REQUEST_WORKERS
  * `MaxRequestWorkers` (in mpm_event module configuration)
* SERVER_NAME
  * `ServerName` (in default site)
* SERVER_ADMIN
  * `ServerAdmin` (in default site)
* APACHE_LOGLEVEL
  * `LogLevel` (in default site)
* APACHE_ERRORLOG
  * `ErrorLog` (in default site)
* APACHE_ACCESSLOG
  * `CustomLog` (in default site)
* APACHE_PERFLOG
  * `CustomLog` (in default site)
* REMOTEIP_INT_PROXY
  * `RemoteIPInternalProxy` (in default site)
* REQ_HEADER_FORWARDED_PROTO
  * `X-Forwarded-Proto` RequestHeader (in default site)
* APACHE_TIMEOUT
  * `Timeout` (in Apache configuration)
* PROXY_PRESERVE_HOST (Default: `on`)
  * `ProxyPreserveHost` (in default site)
* PROXY_SSL (Default: `off`)
  * `SSLProxyEngine`, can be `on` or `off` (in default site). `PROXY_PRESERVE_HOST` should be turned `off` to fully validate backend certificates (including host name).
* PROXY_SSL_VERIFY (Default: `none`)
  * `SSLProxyVerify`, specifies the level of certificate verification (`none`, `optional`, `require`, `optional_no_ca`).
* PROXY_SSL_CHECK_PEER_NAME (Default: `on`)
  * `SSLProxyCheckPeerName`, can be `on` or `off`. Wether the host name of the backend certificate should be checked or not. If `PROXY_PRESERVE_HOST` is `on`, this should be `off`.
* PROXY_SSL_CA_CERT (Default: `/etc/ssl/certs/ca-certificates.crt`)
  * `SSLProxyCACertificateFile` (in default site)
* PROXY_TIMEOUT
  * `ProxyTimeout` (in default site)

For the default values look at the `Dockerfile`.

### ClamAV Anti Virus

* CLAMD_SERVER (Default: `127.0.0.1`)
  * host/ip of server running clamd
* CLAMD_PORT (Default: `3310`)
  * port on which clamd is listening
* CLAMD_DEBUG_LOG (Default: `off`)
  * whether ClamAV scanning should log debug messages

## Custom rules

Mount your custom rules at `/opt/modsecurity/rules/before-crs/` to load them
before the Core Rule Set and at `/opt/modsecurity/rules/after-crs/` to load
after the CRS has been loaded. All custom rule files must end in `.conf` in
order to be loaded.

## Logging

Following the 12-factor app guidelines we're logging audit, error and access
logs to the console, and let the cluster's logging stack deal with logging:

* Audit Log (Default: JSON to stdout)
  * *see* MODSEC_AUDIT_LOG
* ErrorLog (Default: JSON to stdout)
  * *see* APACHE_ERRORLOG
* CustomLog (Default: JSON to stdout)
  * *see* APACHE_ACCESSLOG
  * *see* APACHE_PERFLOG

You should mount `/tmp/modsecurity` onto a scratch space, such as an
`emptyDir` volume. Configured settings are:

* MODSEC_DATA_DIR (Default: `/tmp/modsecurity/data`)
  * `SecDataDir`
* MODSEC_TMP_DIR (Default: `/tmp/modsecurity/tmp`)
  * `SecTmpDir`
* MODSEC_UPLOAD_DIR (Default: `/tmp/modsecurity/upload`)
  * `SecUploadDir`

## Credits

This product includes GeoLite2 data created by MaxMind, available from
[https://www.maxmind.com](https://www.maxmind.com).
