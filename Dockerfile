FROM docker.io/owasp/modsecurity-crs:4.3-apache-202406090906@sha256:36fc67d66f7761a6cb532c4855901a41792efa6e58303833c03aeed285c9c961

ENV APACHE_LOGFORMAT='"{\"apache-access\":{\"remoteHost\":\"%a\",\"username\":\"%u\",\"timestamp\":\"%{%Y-%m-%d%H:%M:%S}t.%{usec_frac}t\",\"requestLine\":\"%r\",\"status\":%>s,\"responseBodySize\":%B,\
\"referer\":\"%{Referer}i\",\"userAgent\":\"%{User-Agent}i\",\"serverName\":\"%v\",\"serverIP\":\"%A\",\"serverPort\":%p,\"handler\":\"%R\",\"workerRoute\":\"%{BALANCER_WORKER_ROUTE}e\",\"tcpStatus\":\"%X\",\"cookie\":\"%{cookie}n\",\
\"uniqueID\":\"%{UNIQUE_ID}e\",\"requestBytes\":%I,\"responseBytes\":%O,\"compressionRatio\":\"%{ratio}n%%\",\
\"requestDuration\":%D,\"modsecTimeIn\":%{ModSecTimeIn}e,\"applicationTime\":%{ApplicationTime}e,\"modsecTimeOut\":%{ModSecTimeOut}e,\
\"modsecAnomalyScoreIn\":%{ModSecAnomalyScoreIn}e,\"modsecAnomalyScoreThresholdIn\":%{ModSecAnomalyScoreThresholdIn}e,\"modsecAnomalyScoreOut\":%{ModSecAnomalyScoreOut}e,\"modsecAnomalyScoreThresholdOut\":%{ModSecAnomalyScoreThresholdOut}e,\"modsecParanoiaLevel\":%{ModSecParanoiaLevel}e}}"'

RUN sed -E -i \
    's|^(Include /etc/modsecurity.d/modsecurity.conf)$|Include conf/extra/httpd-logging-before-modsec.conf\n\1\nInclude conf/extra/httpd-logging-after-modsec.conf|' \
    /etc/modsecurity.d/setup.conf
