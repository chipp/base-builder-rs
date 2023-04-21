ARG TAG=x86_64_musl

FROM ghcr.io/chipp/build.musl.${TAG}:latest

ARG TARGETARCH
ARG RUST_TARGET=x86_64-unknown-linux-musl
ARG OPENSSL_ARCH=linux-x86_64

ENV PATH=/root/.cargo/bin:$PATH

ENV RUST_VERSION=1.69.0

ENV RUSTUP_VER=1.25.2

ENV RUSTUP_AMD64_SHA256="bb31eaf643926b2ee9f4d8d6fc0e2835e03c0a60f34d324048aa194f0b29a71c"
ENV RUSTUP_ARM64_SHA256="6a2691ced61ef616ca196bab4b6ba7b0fc5a092923955106a0c8e0afa31dbce4"

COPY install.sh .
RUN ./install.sh

RUN echo "[build]\ntarget = \"$RUST_TARGET\"\n\n\
  [target.$RUST_TARGET]\nlinker = \"$RUST_TARGET-gcc\"\n" > /root/.cargo/config

ENV RUSTFLAGS=-L$PREFIX/lib
