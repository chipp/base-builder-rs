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
    ${TARGET}-readelf -l ./validate-test > /tmp/program-headers && \
    ${TARGET}-readelf -d ./validate-test > /tmp/dynamic-section && \
    ! grep -q INTERP /tmp/program-headers && \
    ! grep -q NEEDED /tmp/dynamic-section && \
    rm -rf target

FROM emulator AS test-runner
COPY --from=builder /home/rust/src/validate-test ./
COPY --from=project versions.env /versions.env

RUN set -a && . /versions.env && set +a && ./validate-test
