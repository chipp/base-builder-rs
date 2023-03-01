ARG TAG=x86_64_musl

FROM ghcr.io/chipp/build.musl.${TAG}:latest

ARG TARGET=x86_64-unknown-linux-musl
ARG OPENSSL_ARCH=linux-x86_64

ENV PATH=/root/.cargo/bin:$PATH

ENV RUST_VERSION=1.67.1

ENV RUSTUP_VER="1.25.2" RUSTUP_SHA256="bb31eaf643926b2ee9f4d8d6fc0e2835e03c0a60f34d324048aa194f0b29a71c"
RUN curl -O https://static.rust-lang.org/rustup/archive/$RUSTUP_VER/x86_64-unknown-linux-gnu/rustup-init && \
  echo "$RUSTUP_SHA256 *rustup-init" | sha256sum -c - && \
  chmod +x rustup-init && \
  ./rustup-init -y --no-modify-path --profile minimal --default-toolchain $RUST_VERSION --default-host x86_64-unknown-linux-gnu && \
  rm rustup-init && echo "target: $TARGET" && \
  rustup target add $TARGET

RUN echo "[build]\ntarget = \"$TARGET\"\n\n\
  [target.$TARGET]\nlinker = \"$TARGET-gcc\"\n" > /root/.cargo/config

ENV RUSTFLAGS=-L$PREFIX/lib
