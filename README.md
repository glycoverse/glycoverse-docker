# Glycoverse Docker

[![Docker](https://github.com/glycoverse/glycoverse-docker/actions/workflows/docker.yml/badge.svg)](https://github.com/glycoverse/glycoverse-docker/actions/workflows/docker.yml)
[![Docker Hub](https://img.shields.io/docker/v/fubin1999/glycoverse?label=Docker%20Hub)](https://hub.docker.com/r/fubin1999/glycoverse)

A ready-to-use R environment for glycomics and glycoproteomics analysis.

- Base: [`rocker/r-ver:4.6.2`](https://rocker-project.org/images/versioned/r-ver.html), pinned by image digest.
- Platforms: Linux `amd64` (Intel/AMD) and `arm64` (including Apple Silicon).
- Packages: `glyexp`, `glyread`, `glyclean`, `glystats`, `glyvis`, `glyrepr`,
  `glyparse`, `glymotif`, `glydet`, `glydraw`, `glydb`, `glyanno`, and `glycoverse`.
- Source: tagged releases from the [Glycoverse r-universe](https://glycoverse.r-universe.dev),
  with required CRAN and Bioconductor dependencies resolved by [`pak`](https://pak.r-lib.org/).
- Interface: R and Rscript in the terminal. This image does not include RStudio Server.

## Run

Start an interactive R session:

```sh
docker pull fubin1999/glycoverse:4.6.2
docker run --rm -it fubin1999/glycoverse:4.6.2
```

Then attach the core packages:

```r
library(glycoverse)
library(glydb)
library(glyanno)
```

Run a local script and write results into the current directory:

```sh
docker run --rm \
  --mount "type=bind,source=$(pwd),target=/workspace" \
  fubin1999/glycoverse:4.6.2 Rscript analysis.R
```

The default working directory is `/workspace`. The default user is `glycoverse`
(UID/GID 1000). On Linux, match the host user when writing to a bind mount:

```sh
docker run --rm --user "$(id -u):$(id -g)" \
  --mount "type=bind,source=$(pwd),target=/workspace" \
  fubin1999/glycoverse:4.6.2 Rscript analysis.R
```

## Verify and inspect

The build fails if any requested package cannot load. Its smoke test also checks
glycan parsing, compiled motif matching, a `GlycomicSE` object, and PNG rendering
without a display. Run the same test offline:

```sh
docker run --rm --network none fubin1999/glycoverse:4.6.2 \
  Rscript /opt/glycoverse/smoke-test.R
```

List every installed R package and version:

```sh
docker run --rm fubin1999/glycoverse:4.6.2 \
  cat /opt/glycoverse/package-versions.tsv
```

`/opt/glycoverse/build-session.txt` records the R build environment. Optional
`Suggests` dependencies are not installed automatically; functions needing an
optional package may require adding it with `pak::pkg_install()`.

## Tags and reproducibility

`latest`, `4.6`, and `4.6.2` identify the current R 4.6.2 build. Dated or CI build
tags identify individual publications. These tags may contain newer Glycoverse
package releases after a rebuild.

For a fixed analysis environment, record and use the published image digest:

```sh
docker buildx imagetools inspect fubin1999/glycoverse:4.6.2
# Use the reported digest, for example:
# docker pull fubin1999/glycoverse@sha256:<digest>
```

The base image is pinned, but package repositories track current releases.
Rebuilding the Dockerfile later can therefore produce a different dependency
set. The installed-package manifest records what each image actually contains.

## Build locally

```sh
docker build --tag glycoverse:local .
docker run --rm --network none glycoverse:local \
  Rscript /opt/glycoverse/smoke-test.R
```

`NCPUS` controls compilation parallelism (default: 2):

```sh
docker build --build-arg NCPUS=4 --tag glycoverse:local .
```

To publish both platforms using a Buildx builder with multi-platform support:

```sh
docker login
docker buildx create --name glycoverse-builder --driver docker-container
docker buildx build --builder glycoverse-builder \
  --platform linux/amd64,linux/arm64 \
  --tag fubin1999/glycoverse:latest \
  --tag fubin1999/glycoverse:4.6 \
  --tag fubin1999/glycoverse:4.6.2 \
  --push .
```

## GitHub Actions

Pushes and pull requests build and test both platforms on native runners.
Package manifests are uploaded as workflow artifacts.

To enable publishing from Actions, set the repository variable
`DOCKERHUB_USERNAME` and repository secret `DOCKERHUB_TOKEN` (a Docker Hub token
with write access to `fubin1999/glycoverse`). Run the **Docker** workflow on `main`
with **publish** enabled. Both architecture tests must pass before the workflow
updates the shared Docker Hub tags. Ordinary pushes only build and test.

## License

The Docker build files and scripts are MIT licensed. Bundled R packages and
system software retain their respective licenses.
