ARG VARIANT=x86_64_musl

FROM ghcr.io/chipp/build.musl.${VARIANT}:latest

# used in install.sh, provided by docker builder
ARG TARGETARCH

ARG RUST_TARGET=x86_64-unknown-linux-musl
ARG OPENSSL_ARCH=linux-x86_64
ARG ADDITIONAL_CFLAGS
ARG ADDITIONAL_LIBS

RUN apt-get update && apt-get install -y \
    tcl-dev \
    --no-install-recommends && \
    rm -rf /var/lib/apt/lists/*

SHELL ["/bin/bash", "-c"]

RUN --mount=type=bind,source=versions.env,target=/versions.env --mount=type=bind,source=scripts/install_zlib.sh,target=/tmp/install.sh BASH_ENV=/versions.env bash /tmp/install.sh
RUN --mount=type=bind,source=versions.env,target=/versions.env --mount=type=bind,source=scripts/install_openssl.sh,target=/tmp/install.sh BASH_ENV=/versions.env bash /tmp/install.sh
RUN --mount=type=bind,source=versions.env,target=/versions.env --mount=type=bind,source=scripts/install_libpsl.sh,target=/tmp/install.sh BASH_ENV=/versions.env bash /tmp/install.sh
RUN --mount=type=bind,source=versions.env,target=/versions.env --mount=type=bind,source=scripts/install_curl.sh,target=/tmp/install.sh BASH_ENV=/versions.env bash /tmp/install.sh
RUN --mount=type=bind,source=versions.env,target=/versions.env --mount=type=bind,source=scripts/install_sqlite.sh,target=/tmp/install.sh BASH_ENV=/versions.env bash /tmp/install.sh

ENV OPENSSL_STATIC=1 \
    OPENSSL_DIR=$PREFIX \
    OPENSSL_INCLUDE_DIR=$PREFIX/include/ \
    DEP_OPENSSL_INCLUDE=$PREFIX/include/ \
    LIBZ_SYS_STATIC=1 \
    SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt \
    SSL_CERT_DIR=/etc/ssl/certs \
    SQLITE3_STATIC=1 \
    LIBSQLITE3_SYS_USE_PKG_CONFIG=1

ENV PATH=/root/.cargo/bin:$PATH

RUN --mount=type=bind,source=install.sh,target=/tmp/install.sh \
    --mount=type=bind,source=rust-version,target=/rust-version \
    --mount=type=bind,source=versions.env,target=/versions.env \
    BASH_ENV=/versions.env RUST_VERSION="$(cat /rust-version)" bash /tmp/install.sh

RUN --mount=type=bind,source=conf.sh,target=/tmp/conf.sh bash /tmp/conf.sh
