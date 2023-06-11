ARG TAG=x86_64_musl

FROM ghcr.io/chipp/build.musl.${TAG}:latest

ARG TARGETARCH
ARG RUST_TARGET=x86_64-unknown-linux-musl
ARG OPENSSL_ARCH=linux-x86_64

ENV PATH=/root/.cargo/bin:$PATH

ENV RUST_VERSION=1.70.0

ENV RUSTUP_VER=1.26.0

ENV RUSTUP_AMD64_SHA256="0b2f6c8f85a3d02fde2efc0ced4657869d73fccfce59defb4e8d29233116e6db"
ENV RUSTUP_ARM64_SHA256="673e336c81c65e6b16dcdede33f4cc9ed0f08bde1dbe7a935f113605292dc800"

COPY install.sh .
RUN ./install.sh

RUN echo "[build]\ntarget = \"$RUST_TARGET\"\n\n\
  [target.$RUST_TARGET]\nlinker = \"$RUST_TARGET-gcc\"\n" > /root/.cargo/config

ENV RUSTFLAGS=-L$PREFIX/lib
