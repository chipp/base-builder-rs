ARG VARIANT=x86_64_musl

FROM ghcr.io/chipp/build.rust.${VARIANT}:test AS builder

WORKDIR /home/rust/src
COPY ./Cargo.lock ./Cargo.lock
COPY ./Cargo.toml ./Cargo.toml

COPY ./src ./src

RUN cargo build --release -p validate && \
    rm -rf target
