FROM ghcr.io/chipp/build.rust.x86_64_musl:test AS builder

RUN pkg-config --static --libs --cflags libcrypto libssl openssl zlib libcurl sqlite3
