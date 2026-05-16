ARG VARIANT=x86_64_musl

FROM ghcr.io/chipp/build.musl.${VARIANT}:latest

# used in install.sh, provided by docker builder
ARG TARGETARCH

ARG RUST_TARGET=x86_64-unknown-linux-musl
ARG OPENSSL_ARCH=linux-x86_64
ARG ADDITIONAL_CFLAGS
ARG ADDITIONAL_LIBS

RUN apt-get update && apt-get install -y \
    tcl-dev \
    --no-install-recommends && \
    rm -rf /var/lib/apt/lists/*

COPY versions.env /versions.env
COPY scripts/ /scripts/

ENV BASH_ENV=/versions.env
SHELL ["/bin/bash", "-c"]

RUN chmod +x /scripts/*.sh

RUN /scripts/install_zlib.sh
RUN /scripts/install_openssl.sh
RUN /scripts/install_libpsl.sh
RUN /scripts/install_curl.sh
RUN /scripts/install_sqlite.sh

RUN rm -rf /scripts

ENV OPENSSL_STATIC=1 \
    OPENSSL_DIR=$PREFIX \
    OPENSSL_INCLUDE_DIR=$PREFIX/include/ \
    DEP_OPENSSL_INCLUDE=$PREFIX/include/ \
    LIBZ_SYS_STATIC=1 \
    SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt \
    SSL_CERT_DIR=/etc/ssl/certs \
    SQLITE3_STATIC=1 \
    LIBSQLITE3_SYS_USE_PKG_CONFIG=1

ENV PATH=/root/.cargo/bin:$PATH

COPY install.sh .
RUN chmod +x install.sh && ./install.sh && rm install.sh

RUN rm /versions.env

COPY conf.sh .
RUN chmod +x conf.sh && ./conf.sh && rm conf.sh
