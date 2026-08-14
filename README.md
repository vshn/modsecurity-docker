# VSHN ModSecurity Container Image

Based on the official [coreruleset/modsecurity-crs-docker](https://github.com/coreruleset/modsecurity-crs-docker) image.

- Contains the necessary tweaks to run on OpenShift
- Sets opinionated default configurations
- Includeds the [ClamAV anti-virus scanner](https://www.clamav.net/) client

## Usage

The latest image can be pulled from

    ghcr.io/vshn/modsecurity-docker:latest

Our tags track upstream CRS versions.
See [ghcr.io/vshn/modsecurity-docker](https://github.com/vshn/modsecurity-docker/pkgs/container/modsecurity-docker) for a list of historic tags.

## Development

A very basic Docker Compose setup including this container with `httpbun` as the backend. To start it, run:

```sh
docker compose up
```

Once the containers are running, you can make requests to it:

```sh
curl -i http://localhost:8080/anything

curl -i -H 'Host: vshn.ch' http://localhost:8080/anything

curl -i http://localhost:8080/cookies/set/secret/random-value
```

For all supported endpoints, visit [localhost:8080](http://localhost:8080/).

### Release

To publish a new release, simply create & push a new Git Tag.

NOTE: Tags should follow the included CRS version. Use the build number to signify changes to the images with the same CRS number, e.g. `v4.3.0-0` -> `v4.3.0-1`.

One-Liner to create a Tag:

```sh
tag="v$(grep '^FROM ' Containerfile| cut -d':' -f2 | cut -d'-' -f1)-0"; git tag -s "$tag" -m "$tag"
```

Don't forget to `git push --tags` afterwards!

## Configuration

Most aspects can be configured using environment variables.
For a full list of supported environment variables, see the [upstream documentation][upstream].
We use the Apache Debian image.

### Extra configuration variables

- `HEALTHZ_CIDRS` - CIDR from which requests to the `/healthz` endpoint should be whitelisted.
  This should usually be set to your Kubernetes host subnet range.
  Multiple CIDR ranges can be specified.
  Example: `1.2.3.4/24,5.6.7.8/24`

### mod_qos

This image ships the [mod_qos](https://mod-qos.sourceforge.net/) module, compiled from source in a multi-stage build. Only the `mod_qos.so` is copied into the runtime image.

mod_qos is **not loaded by default** (`MOD_QOS_ENABLED=disabled`). Set `MOD_QOS_ENABLED=on` to activate it. All options are configurable via environment variables:

| Variable                         | mod_qos directive                                                                                                   | Default          |
| -------------------------------- | ------------------------------------------------------------------------------------------------------------------- | ---------------- |
| `MOD_QOS_ENABLED`                | loads the module if set to `on`                                                                                     | `disabled`       |
| `QOS_SRV_MAX_CONN`               | [`QS_SrvMaxConn`](https://mod-qos.sourceforge.net/#QS_SrvMaxConn)                                                   | empty (disabled) |
| `QOS_SRV_MAX_CONN_PER_IP`        | [`QS_SrvMaxConnPerIP`](https://mod-qos.sourceforge.net/#QS_SrvMaxConnPerIP)                                         | empty (disabled) |
| `QOS_SRV_MAX_CONN_CLOSE`         | [`QS_SrvMaxConnClose`](https://mod-qos.sourceforge.net/#QS_SrvMaxConnClose)                                         | empty (disabled) |
| `QOS_SRV_MIN_DATA_RATE`          | [`QS_SrvMinDataRate`](https://mod-qos.sourceforge.net/#QS_SrvMinDataRate)                                           | empty (disabled) |
| `QOS_LOC_REQUEST_LIMIT_DEFAULT`  | [`QS_LocRequestLimitDefault`](https://mod-qos.sourceforge.net/#QS_LocRequestLimitDefault)                           | empty (disabled) |
| `QOS_CLIENT_EVENT_PER_SEC_LIMIT` | [`QS_ClientEventPerSecLimit`](https://mod-qos.sourceforge.net/#QS_ClientEventPerSecLimit)                           | empty (disabled) |
| `QOS_CLIENT_EVENT_LIMIT_COUNT`   | [`QS_ClientEventLimitCount`](https://mod-qos.sourceforge.net/#QS_ClientEventLimitCount)                             | `60 60`         |
| `QOS_CLIENT_EVENT_BLOCK_COUNT`   | [`QS_ClientEventBlockCount`](https://mod-qos.sourceforge.net/#QS_ClientEventBlockCount)                             | empty (disabled) |
| `QOS_REQUEST_HEADER_FILTER`      | [`QS_RequestHeaderFilter`](https://mod-qos.sourceforge.net/#QS_RequestHeaderFilter)                                 | empty (disabled) |
| `QOS_LIMIT_REQUEST_BODY`         | [`QS_LimitRequestBody`](https://mod-qos.sourceforge.net/#QS_LimitRequestBody)                                       | empty (disabled) |
| `QOS_CLIENT_IP_FROM_HEADER`      | [`QS_ClientIpFromHeader`](https://mod-qos.sourceforge.net/#QS_ClientIpFromHeader)                                   | empty (disabled) |
| `QOS_EXCLUDE_IP`                 | [`QS_SrvMaxConnExcludeIP`](https://mod-qos.sourceforge.net/#QS_SrvMaxConnExcludeIP) (one per comma-separated entry) | empty (disabled) |
| `QOS_BLOCK_LOCATION`             | sets `QS_Limit` via `SetEnvIf` (see below)                                                                          | `/`              |
| `QOS_ALLOW_LOCATION`             | unsets `QS_Limit` via `SetEnvIf` (see below)                                                                        | `/healthz`       |

Defaults other than `MOD_QOS_ENABLED` only take effect once mod_qos is enabled (`MOD_QOS_ENABLED=on`). `HEALTHZ_CIDRS` IPs are automatically whitelisted (first two octets of each CIDR entry). For per-path rules, use `QOS_BLOCK_LOCATION` (see below).

#### `QOS_BLOCK_LOCATION` — paths to rate-limit

`QOS_BLOCK_LOCATION="/api,/login"` — comma-separated paths. Each matching request increments the shared `QS_Limit` counter (weight `QOS_BLOCK_EVENTS`, default 1). The threshold and window come from `QOS_CLIENT_EVENT_LIMIT_COUNT` (e.g. `200 60` = block after 200 events within 60s per client IP). A single `/` rate-limits every location.

All listed paths share one counter and one threshold: a client that trips the limit on one path is blocked on all of them (mod_qos checks `counter >= threshold` on every request regardless of which path filled the counter). Use `QOS_ALLOW_LOCATION` for paths that must not increment the counter.

The generated `SetEnvIf` setters are written to `qos-active.conf`.

#### `QOS_ALLOW_LOCATION` — never-count paths

`QOS_ALLOW_LOCATION="/health,/ready"` — comma-separated paths that must **not increment** the `QS_Limit` counter, so healthchecks from a separate monitor IP never get throttled and never burn a client's quota. The auto-generated rules emit `SetEnvIf Request_URI ^<path> !QS_Limit` per allow-path, overriding the block-path increment (last-match-wins).

**Note (by-design caveat):** `mod_qos` evaluates `counter >= threshold` on every request regardless of which path filled the counter, so an already-blocked client's request to an allow-path is **also** blocked. This is the chosen trade-off: there is no rate-limit bypass (an attacker cannot un-block themselves by interleaving an allow-path), at the cost that a flood-abusing client's `/health` is also throttled. For unthrottactable healthchecks, run them from a whitelisted source IP (`QOS_EXCLUDE_IP`/`HEALTHZ_CIDRS`) or an address outside any limit's window.

The IP whitelist (`QOS_EXCLUDE_IP` / `HEALTHZ_CIDRS`) exempts source IPs from the `QS_Limit` counter via `SetEnvIf Remote_Addr ^<prefix> !QS_Limit` (one rule per prefix, covers all block paths automatically).

#### `QOS_CLIENT_IP_FROM_HEADER` behind mod_remoteip

The base image loads `mod_remoteip` with `RemoteIPHeader X-Forwarded-For`, so `mod_remoteip` resolves the real client IP from `X-Forwarded-For` into `r->useragent_ip` and **strips `X-Forwarded-For`** from the request headers before `mod_qos` runs. Therefore:

- Do **not** set `QOS_CLIENT_IP_FROM_HEADER=X-Forwarded-For` behind mod_remoteip — `mod_qos` won't find the (stripped) header, logs `mod_qos(069)` and falls back to the proxy/pod IP, collapsing all clients into one rate-limit bucket.
- Set `QOS_CLIENT_IP_FROM_HEADER=#USERAGENT_IP` (recommended) to make `mod_qos` read `mod_remoteip`'s resolved client IP directly. This produces zero `069` errors (even for the container's own healthcheck) and gives per-real-client rate-limit counters.
- `X-Real-IP` works only while an upstream proxy sets it and it survives `mod_remoteip` (mod_remoteip only strips its configured `RemoteIPHeader`); not guaranteed on every platform.

When `QOS_CLIENT_IP_FROM_HEADER` is a `#`-prefixed pseudo-header (such as `#USERAGENT_IP`), the auto-generated whitelist uses `SetEnvIf Remote_Addr ^<prefix> !QS_Limit` (matching `r->useragent_ip`) so `QOS_EXCLUDE_IP` and `HEALTHZ_CIDRS` exempt the real client IPs from `QS_ClientEventLimitCount`.

`QOS_BLOCK_LOCATION` defaults to `/` (rate-limit every location). Set `QOS_ALLOW_LOCATION` to exclude paths such as healthchecks, or run healthchecks from a whitelisted source IP.

### Bot-protection logging

mod_qos logs to the field `botProtection`. \
See <https://mod-qos.sourceforge.net/#accesslog> under `mod_qos_ev`

- `D;` (denied/blocked) when the request was blocked
- `S;` If the request was marked as VIP.
- `-` when no mod_qos event occurred or when mod_qos is not enabled.

The letters can be combined, for example `S;D;` means both denied and skipped.

## License

This project itself is licensed under BSD 3-Clause, see [LICENSE](./LICENSE).

This project includes code from the [OWASP CRS Docker Image project][upstream] (Thank you!). See [Apache-2.0.txt](Apache-2.0.txt).

This project includes code from the [ClamAV project][clamav] (Thank you!). See [GPLv2.txt](GPLv2.txt).

[upstream]: https://github.com/coreruleset/modsecurity-crs-docker
[clamav]: https://www.clamav.net/
