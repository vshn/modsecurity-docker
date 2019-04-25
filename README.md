# ModSecurity Docker image

[![dockeri.co](http://dockeri.co/image/vshn/modsecurity)](https://hub.docker.com/r/vshn/modsecurity/)

[![Build Status](https://img.shields.io/docker/cloud/build/vshn/modsecurity.svg)](https://hub.docker.com/r/vshn/modsecurity/builds
) [![GitHub issues](https://img.shields.io/github/issues-raw/vshn/modsecurity-docker.svg)](https://github.com/vshn/modsecurity-docker/issues
) [![GitHub PRs](https://img.shields.io/github/issues-pr-raw/vshn/modsecurity-docker.svg)](https://github.com/vshn/modsecurity-docker/pulls
) [![License](https://img.shields.io/github/license/vshn/modsecurity-docker.svg)](https://github.com/vshn/modsecurity-docker/blob/master/LICENSE)

This image is based on the official [`owasp/modsecurity-crs`](https://hub.docker.com/r/owasp/modsecurity-crs) image.

It contains the necessary tweaks to run on OpenShift.

## Supported Tags

* [![latest](
  https://img.shields.io/badge/latest-blue.svg?colorA=22313f&colorB=4a637b&logo=docker)](
  https://github.com/vshn/modsecurity-docker/blob/master/v3.1/Dockerfile) [![size/layers](
  https://images.microbadger.com/badges/image/vshn/modsecurity:latest.svg)](
  https://microbadger.com/images/vshn/modsecurity:latest) [![based on](
  https://img.shields.io/badge/Git-master-grey.svg?colorA=5a5b5c&colorB=9a9b9c&logo=github)](
  https://github.com/SpiderLabs/owasp-modsecurity-crs/tree/v3.1/dev/util/docker)
* [![3.1](
  https://img.shields.io/badge/3.1-blue.svg?colorA=22313f&colorB=4a637b&logo=docker)](
  https://github.com/vshn/modsecurity-docker/blob/master/v3.1/Dockerfile) [![size/layers](
  https://images.microbadger.com/badges/image/vshn/modsecurity:3.1.svg)](
  https://microbadger.com/images/vshn/modsecurity:3.1) [![based on](
  https://img.shields.io/badge/Git-master-grey.svg?colorA=5a5b5c&colorB=9a9b9c&logo=github)](
  https://github.com/SpiderLabs/owasp-modsecurity-crs/tree/v3.1/dev/util/docker)

## Usage

How to use the image.

### Configuration

There are a variety of environment variables available to configure the image.

*Most important are the following ones:*

* PARANOIA_LEVEL (Default: 1)
  * Ranging from 1-4. Have a look at the section *'What are paranoia levels, and
    which level should I choose?'* at [coreruleset.org/faq/](https://coreruleset.org/faq/).
* I_ANOMALY_SCORE_TH (Default: 1000)
  * inbound anomaly score threshold; start with 1000 and try to bring it down to 5
* O_ANOMALY_SCORE_TH (Default: 1000)
  * outbound anomaly score threshold; start with 1000 and try to bring it down to 4
* PORT (Default: 8080)
  * Port the Apache process should listen on
* BACKEND
  * The IP/URL of the service which should be secured by ModSecurity.

#### ModSecurity

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

For the default values look at the `Dockerfile`.

#### Apache

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
* PROXY_TIMEOUT
  * `ProxyTimeout` (in default site)

For the default values look at the `Dockerfile`.

### Custom rules

Mount your custom rules at `/opt/modsecurity/rules/before-crs/` to load them
before the Core Rule Set and at `/opt/modsecurity/rules/after-crs/` to load
after the CRS has been loaded. All custom rule files must end in `.conf` in
order to be loaded.

### Data

#### Persistent

You should mount `/var/log/modsecurity` onto a persistent volume.
Configured directories and files are:

* MODSEC_AUDIT_LOG (Default: `/var/log/modsecurity/audit.log`)
  * `SecAuditLog`
* MODSEC_AUDIT_STORAGE (Default: `/var/log/modsecurity/audit`)
  * `SecAuditLogStorageDir`

#### Ephemeral

Following the 12-factor app guidelines we're logging error and access
logs to the console, and let the cluster's ELK stack deal with logging:

* ErrorLog (Default: `/dev/stderr`)
  * *see* APACHE_ERRORLOG
* CustomLog (Default: `/dev/stdout`)
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
