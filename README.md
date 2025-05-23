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
tag="v$(grep '^FROM ' Dockerfile| cut -d':' -f2 | cut -d'-' -f1)-0"; git tag -s "$tag" -m "$tag"
```

Don't forget to `git push --tags` afterwards!

## Configuration

Most aspects can be configured using environment variables.
For a full list of supported environment variables, see the [upstream documentation][upstream].
We use the Apache Alpine image.

### Extra configuration variables

- `HEALTHZ_CIDRS` - CIDR from which requests to the `/healthz` endpoint should be whitelisted.
  This should usually be set to your Kubernetes host subnet range.
  Multiple CIDR ranges can be specified.
  Example: `1.2.3.4/24,5.6.7.8/24`

## License

This project itself is licensed under BSD 3-Clause, see [LICENSE](./LICENSE).

This project includes code from the [OWASP CRS Docker Image project][upstream] (Thank you!). See [Apache-2.0.txt](Apache-2.0.txt).

This project includes code from the [ClamAV project][clamav] (Thank you!). See [GPLv2.txt](GPLv2.txt).

[upstream]: https://github.com/coreruleset/modsecurity-crs-docker
[clamav]: https://www.clamav.net/
