FROM --platform=$BUILDPLATFORM base-builder-rs AS builder

RUN apt-get update && apt-get install -y \
    jq \
    --no-install-recommends && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /home/rust/src
RUN --mount=type=bind,target=/home/rust/src \
    export CARGO_TARGET_DIR=/tmp/validate-target && \
    cargo clippy --all-targets --all-features -- -D warnings && \
    cargo test --no-run && \
    cp $(cargo test --no-run --message-format=json -q | tail -n 2 | head -n 1 | jq -r .executable) /validate-test && \
    ${TARGET}-readelf -l /validate-test > /tmp/program-headers && \
    ${TARGET}-readelf -d /validate-test > /tmp/dynamic-section && \
    ! grep -q INTERP /tmp/program-headers && \
    ! grep -q NEEDED /tmp/dynamic-section && \
    rm -rf "$CARGO_TARGET_DIR"

FROM emulator AS test-runner
RUN --mount=from=builder,source=/validate-test,target=/validate-test \
    --mount=from=project,source=versions.env,target=/versions.env \
    set -a && . /versions.env && set +a && /validate-test
