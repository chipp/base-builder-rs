FROM --platform=$BUILDPLATFORM base-builder-rs AS builder

RUN apt-get update && apt-get install -y \
    jq \
    --no-install-recommends && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /home/rust/src
COPY ./Cargo.lock ./Cargo.lock
COPY ./Cargo.toml ./Cargo.toml

COPY ./src ./src

RUN cargo clippy --all-targets --all-features -- -D warnings

RUN cargo test --no-run && \
    cp $(cargo test --no-run --message-format=json -q | tail -n 2 | head -n 1 | jq -r .executable) ./validate-test && \
    rm -rf target

FROM emulator AS test-runner
COPY --from=builder /home/rust/src/validate-test ./

ENV OPENSSL_VERSION="OpenSSL 3.5.6 7 Apr 2026"
ENV ZLIB_VERSION="1.3.2"
ENV CURL_VERSION="libcurl/8.20.0 OpenSSL/3.5.6 zlib/1.3.2 libpsl/0.21.5"
ENV SQLITE_VERSION="3.53.1"

RUN ./validate-test
