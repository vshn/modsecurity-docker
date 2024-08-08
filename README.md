# VSHN ModSecurity Container Image

Based on the official [coreruleset/modsecurity-crs-docker](https://github.com/coreruleset/modsecurity-crs-docker) image.

- Contains the necessary tweaks to run on OpenShift
- Sets opinionated default configurations
- Includeds the [ClamAV anti-virus scanner](https://www.clamav.net/) client

## Status

This image is currently being reworked.

### Backlog

- [x] rudimentary development environment
- [x] use the `alpine` upstream image
- [x] build & push to GHCR
- [x] automated updates via Renovate
- [x] can run on OpenShift
- [ ] ModSecurity configuration defaults (& documented)
- [x] JSON AccessLog
- [x] JSON ModSecurity log
- [x] custom rules support (`init`, `before`, `after`)
- [ ] contains ClamAV
- [ ] automated release (tagging) process

## Usage

The latest image can be pulled from

    ghcr.io/vshn/modsecurity-docker:latest

Our tags track upstream CRS versions.
See [ghcr.io/vshn/modsecurity-docker](https://github.com/vshn/modsecurity-docker/pkgs/container/modsecurity-docker) for a list of historic tags.

## Development

A very basic Docker Compose setup including this container with `httpbin` as the backend. To start it, run:

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

## Configuration

Most aspects can be configured using environment variables.
For a full list of supported environment variables, see the [upstream documentation][upstream].
We use the Apache Alpine image.

## License

This project itself is licensed under BSD 3-Clause, see [LICENSE](./LICENSE).

This project includes code from the [OWASP CRS Docker Image project][upstream] (Thank you!). See [Apache-2.0.txt](Apache-2.0.txt).

This project includes code from the [ClamAV project][clamav] (Thank you!). See [GPLv2.txt](GPLv2.txt).

[upstream]: https://github.com/coreruleset/modsecurity-crs-docker
[clamav]: https://www.clamav.net/
