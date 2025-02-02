FROM --platform=$BUILDPLATFORM base-builder-rs AS builder

RUN apt-get update && apt-get install -y \
    jq \
    --no-install-recommends && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /home/rust/src
COPY ./Cargo.lock ./Cargo.lock
COPY ./Cargo.toml ./Cargo.toml

COPY ./src ./src

RUN cargo test --no-run && \
    cp $(cargo test --no-run --message-format=json -q | tail -n 2 | head -n 1 | jq -r .executable) ./validate-test && \
    rm -rf target

FROM emulator AS test-runner
COPY --from=builder /home/rust/src/validate-test ./

ENV OPENSSL_VERSION="OpenSSL 3.2.3 3 Sep 2024"
ENV ZLIB_VERSION="1.3.1"
ENV CURL_VERSION="libcurl/8.11.1 OpenSSL/3.2.3 zlib/1.3.1 libpsl/0.21.5"
ENV SQLITE_VERSION="3.48.0"

RUN ./validate-test
