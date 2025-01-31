FROM base-builder-rs

WORKDIR /home/rust/src
COPY ./Cargo.lock ./Cargo.lock
COPY ./Cargo.toml ./Cargo.toml

COPY ./src ./src

ENV OPENSSL_VERSION="OpenSSL 3.2.3 3 Sep 2024"
ENV ZLIB_VERSION="1.3.1"
ENV CURL_VERSION="libcurl/8.10.1 OpenSSL/3.2.3 zlib/1.3.1 libpsl/0.21.5"
ENV SQLITE_VERSION="3.47.0"

RUN dpkgArch="$(dpkg --print-architecture)"; \
    case "$dpkgArch" in \
    arm64) export HOST_TARGET='aarch64-linux-musl' ;; \
    amd64) export HOST_TARGET='x86_64-linux-musl' ;; \
    esac; \
    if [ "${HOST_TARGET}" = "${TARGET}" ]; then cargo test; else cargo test --no-run; fi && \
    rm -rf target
