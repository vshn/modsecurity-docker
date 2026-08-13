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

### mod_qos (Quality of Service)

This image additionally ships the [mod_qos](https://mod-qos.sourceforge.net/) Apache module — a quality-of-service / DoS-mitigation module that can enforce request-rate, concurrency and per-client-IP limits (among others).

mod_qos is **not** packaged in Debian (or Alpine), so it is **compiled from source** in a separate build stage of the `Containerfile`; only the resulting `mod_qos.so` is copied into the runtime image (no build toolchain leaks into the final image). The pinned upstream version is `11.79` (released 2026-06-06) and the downloaded tarball is verified against a pinned SHA-256 (`MOD_QOS_SHA256`).

**Security note:** as of the research date there are **no known CVEs** for mod_qos in the NVD or the Debian Security Tracker, and the project is actively maintained (latest release 2026-06-06). This is an observation, not a guarantee.

#### Activation

mod_qos is loaded but **inert by default** (`MOD_QOS_ENABLED=disabled`). It enforces no rules until you:

1. set `MOD_QOS_ENABLED=on`, **and**
2. supply a rules file at `/usr/local/apache2/conf/extra/qos-rules-on.conf` (e.g. via a bind-mount, a Kubernetes `Secret` or `ConfigMap`).

The toggle lives in `conf/extra/vshn-qos.conf` (auto-included at server scope):

```apache
<IfModule !qos_module>
  LoadModule qos_module modules/mod_qos.so
</IfModule>
IncludeOptional conf/extra/qos-rules-${MOD_QOS_ENABLED}.conf
```

When disabled (or when no matching `qos-rules-on.conf` exists) the module loads but no rules apply. With `MOD_QOS_ENABLED=on` and a `qos-rules-on.conf` present, the rules take effect at server scope. See the [mod_qos documentation](https://mod-qos.sourceforge.net/) for the available directives.

#### Test fixtures

`tests/test_qos.sh` exercises the activation mechanism (rate-limit). `tests/test_geo.sh` adds a further end-to-end example operators can adapt: a **GeoIP country-block** (`QS_Country` + `SetEnvIf QS_Country ^(PV|LO)$` + `QS_DenyEvent +cblock`) driven by a 3-field `QS_ClientGeoCountryDB` CSV, and an **IPv6-block** (`SetEnvIf Remote_Addr :`) exercised by `mod_remoteip` + `X-Forwarded-For` over the IPv4 docker network. Both inject rules via read-only bind-mounts; the production image is unmodified.

## License

This project itself is licensed under BSD 3-Clause, see [LICENSE](./LICENSE).

This project includes code from the [OWASP CRS Docker Image project][upstream] (Thank you!). See [Apache-2.0.txt](Apache-2.0.txt).

This project includes code from the [ClamAV project][clamav] (Thank you!). See [GPLv2.txt](GPLv2.txt).

[upstream]: https://github.com/coreruleset/modsecurity-crs-docker
[clamav]: https://www.clamav.net/
