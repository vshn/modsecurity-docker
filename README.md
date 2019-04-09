# ModSecurity Docker image

This image is based on the official [`owasp/modsecurity-crs:v3.1`](https://hub.docker.com/r/owasp/modsecurity-crs) image.

It contains the necessary tweaks to run on OpenShift.

## Usage

How to use the image

### Configuration

There are a variety of environment variables available to configure the image.

*Most important are the following three*

* PARANOIA_LEVEL (Default: 1)
  * Ranging from 1-4. Have a look at the section *'What are paranoia levels, and which level should I choose?'* at [coreruleset.org/faq/](https://coreruleset.org/faq/).
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
* MODSEC_MAX_NUM_ARGS
  * `tx.max_num_args`
* MODSEC_ARG_NAME_LENGTH
  * `tx.arg_name_length`

#### Apache

* SERVER_NAME
  * `ServerName`
* PROXY_TIMEOUT
  * `ProxyTimeout`
* HTTPD_SERVER_LIMIT
  * `ServerLimit`
* HTTPD_MAX_REQUEST_WORKERS
  * `MaxRequestWorkers`

For the default values look at the `Dockerfile`.

### Custom rules

Mount your custom rules at `/modsecurity/rules/before-crs/` to load them before the Core Rule Set or at `/modsecurity/rules/after-crs/` to load the CRS is loaded. The custom rule files must end in `.conf` in order to be loaded.

### Data

#### Persistent

Data at `/modsecurity/data/` should be persisted.

It contains:

* SecDataDir
  * `/modsecurity/data`
* ErrorLog
  * `/modsecurity/data/log/error.log`
* CustomLog
  * `/modsecurity/data/log/access.log`
* CustomLog
  * `/modsecurity/data/log/perf.log`
* SecAuditLog
  * `/modsecurity/data/log/audit.log`
* SecAuditLogStorageDir
  * `/modsecurity/data/audit`

#### Other

Other configured directories are:

* SecTmpDir
  * `/modsecurity/tmp`
* SecUploadDir
  * `/modsecurity/upload`
