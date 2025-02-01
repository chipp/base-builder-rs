#! /bin/bash

case $TARGETARCH in
  "amd64")
    HOST_ARCH="x86_64-unknown-linux-gnu"
    RUSTUP_SHA256=$RUSTUP_AMD64_SHA256
    ;;
  "arm64")
    HOST_ARCH="aarch64-unknown-linux-gnu"
    RUSTUP_SHA256=$RUSTUP_ARM64_SHA256
    ;;
esac

curl -O https://static.rust-lang.org/rustup/archive/$RUSTUP_VER/$HOST_ARCH/rustup-init

echo "$RUSTUP_SHA256 *rustup-init" | sha256sum -c -
chmod +x rustup-init

./rustup-init -y --no-modify-path --profile minimal \
  --default-toolchain $RUST_VERSION \
  --default-host $HOST_ARCH

rm rustup-init && echo "target: $RUST_TARGET"

rustup target add $RUST_TARGET
