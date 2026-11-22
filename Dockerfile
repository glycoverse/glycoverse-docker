# syntax=docker/dockerfile:1

ARG BASE_IMAGE=rocker/r-ver:4.6.2@sha256:4383092318935c298533466f753354a7dfdc75a6e12edfb93a0f13c8a97135f9
FROM ${BASE_IMAGE}

LABEL org.opencontainers.image.title="Glycoverse" \
      org.opencontainers.image.description="Glycomics and glycoproteomics analysis with Glycoverse and R 4.6" \
      org.opencontainers.image.source="https://github.com/glycoverse/glycoverse-docker" \
      org.opencontainers.image.licenses="MIT"

ARG NCPUS=2
ENV MAKEFLAGS="-j${NCPUS}" \
    R_BUILD_NCPUS=${NCPUS}

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates curl git \
        libcurl4-openssl-dev libssl-dev libxml2-dev \
        fonts-dejavu-core \
    && rm -rf /var/lib/apt/lists/*

COPY packages.txt scripts/install.R /opt/glycoverse/
RUN --mount=type=cache,target=/root/.cache \
    Rscript /opt/glycoverse/install.R \
    && rm -rf /tmp/downloaded_packages /tmp/Rtmp* /var/lib/apt/lists/*

RUN useradd --create-home --uid 1000 --shell /bin/bash glycoverse \
    && mkdir -p /workspace /home/glycoverse/R/library \
    && chown -R glycoverse:glycoverse /workspace /home/glycoverse/R

COPY scripts/smoke-test.R /opt/glycoverse/smoke-test.R
ENV R_LIBS_USER=/home/glycoverse/R/library
USER glycoverse
WORKDIR /workspace

# Test the installed image as its runtime user, including native code and graphics.
RUN Rscript /opt/glycoverse/smoke-test.R

CMD ["R", "--no-save", "--no-restore"]
