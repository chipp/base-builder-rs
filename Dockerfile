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

ENV ZLIB_VER=1.3.1
ENV ZLIB_SHA256="9a93b2b7dfdac77ceba5a558a580e74667dd6fede4585b91eefb60f03b72df23"
RUN curl -sSL -O https://zlib.net/zlib-$ZLIB_VER.tar.gz && \
    echo "$ZLIB_SHA256  zlib-$ZLIB_VER.tar.gz" | sha256sum -c - && \
    tar xfz zlib-${ZLIB_VER}.tar.gz && cd zlib-$ZLIB_VER && \
    CC="$CC -fPIC -pie" LDFLAGS="-L$PREFIX/lib" CFLAGS="-I$PREFIX/include" \
    ./configure --static --prefix=$PREFIX && \
    make -j$(nproc) && make install && \
    cd .. && rm -rf zlib-$ZLIB_VER zlib-$ZLIB_VER.tar.gz

ENV SSL_VER=3.5.0
ENV SSL_SHA256="344d0a79f1a9b08029b0744e2cc401a43f9c90acd1044d09a530b4885a8e9fc0"
RUN curl -sSL -O https://www.openssl.org/source/openssl-$SSL_VER.tar.gz && \
    echo "$SSL_SHA256  openssl-$SSL_VER.tar.gz" | sha256sum -c - && \
    tar xfz openssl-${SSL_VER}.tar.gz && cd openssl-$SSL_VER && \
    CC=gcc ./Configure --cross-compile-prefix=${TARGET}- \
    --prefix=$PREFIX --openssldir=$PREFIX/ssl ${ADDITIONAL_LIBS} \
    no-dso no-shared no-ssl3 no-tests no-comp no-zlib no-zlib-dynamic \
    no-md2 no-rc5 no-weak-ssl-ciphers no-camellia no-idea no-seed \
    no-engine no-async no-apps $OPENSSL_ARCH $ADDITIONAL_CFLAGS \
    -fdata-sections -ffunction-sections -fPIC -O2 \
    -DOPENSSL_NO_SECURE_MEMORY && \
    env C_INCLUDE_PATH=$PREFIX/include make depend 2> /dev/null && \
    make -j$(nproc) && make install_sw && \
    cd .. && rm -rf openssl-$SSL_VER openssl-$SSL_VER.tar.gz

ENV LIBPSL_VER=0.21.5
ENV LIBPSL_SHA256="1dcc9ceae8b128f3c0b3f654decd0e1e891afc6ff81098f227ef260449dae208"
RUN curl -sSL -O https://github.com/rockdaboot/libpsl/releases/download/${LIBPSL_VER}/libpsl-${LIBPSL_VER}.tar.gz && \
    echo "$LIBPSL_SHA256  libpsl-$LIBPSL_VER.tar.gz" | sha256sum -c - && \
    tar xfz libpsl-${LIBPSL_VER}.tar.gz && cd libpsl-$LIBPSL_VER && \
    CC="$CC -fPIC -pie $ADDITIONAL_CFLAGS" LIBS="-ldl ${ADDITIONAL_LIBS}" \
    ./configure --prefix=$PREFIX \
    --disable-shared --disable-man --enable-builtin --host=$TARGET && \
    make -j$(nproc) && make install && \
    cd .. && rm -rf libpsl-$LIBPSL_VER libpsl-$LIBPSL_VER.tar.gz

ENV CURL_VER=8.13.0
ENV CURL_SHA256="c261a4db579b289a7501565497658bbd52d3138fdbaccf1490fa918129ab45bc"
RUN curl -sSL -O https://curl.haxx.se/download/curl-$CURL_VER.tar.gz && \
    echo "$CURL_SHA256  curl-$CURL_VER.tar.gz" | sha256sum -c - && \
    tar xfz curl-${CURL_VER}.tar.gz && cd curl-$CURL_VER && \
    CC="$CC -fPIC -pie $ADDITIONAL_CFLAGS" LIBS="-ldl ${ADDITIONAL_LIBS}" \
    ./configure --enable-shared=no --with-zlib --with-openssl --enable-optimize --prefix=$PREFIX \
    --with-ca-path=/etc/ssl/certs/ --with-ca-bundle=/etc/ssl/certs/ca-certificates.crt --without-ca-fallback \
    --disable-shared --disable-ldap --disable-sspi --without-librtmp --disable-ftp \
    --disable-file --disable-dict --disable-telnet --disable-tftp --disable-manual --disable-ldaps \
    --disable-dependency-tracking --disable-rtsp --disable-pop3  --disable-imap --disable-smtp \
    --disable-gopher --disable-smb --without-libidn --disable-proxy --host=$TARGET && \
    make -j$(nproc) curl_LDFLAGS="-all-static" && make install && \
    cd .. && rm -rf curl-$CURL_VER curl-$CURL_VER.tar.gz

ENV SQLITE_VER=3490100
ENV SQLITE_SHA256="106642d8ccb36c5f7323b64e4152e9b719f7c0215acf5bfeac3d5e7f97b59254"
RUN curl -sSL -O https://www.sqlite.org/2025/sqlite-autoconf-$SQLITE_VER.tar.gz && \
    echo "$SQLITE_SHA256  sqlite-autoconf-$SQLITE_VER.tar.gz" | sha256sum -c - && \
    tar xfz sqlite-autoconf-${SQLITE_VER}.tar.gz && \
    mkdir -p sqlite-autoconf-$SQLITE_VER/build && cd sqlite-autoconf-$SQLITE_VER/build && \
    CC="$CC -fPIC -pie $ADDITIONAL_CFLAGS $ADDITIONAL_LIBS" ../configure --disable-shared \
    --host=$TARGET --prefix=$PREFIX && \
    make -j$(nproc) && make install && \
    cd ../.. && rm -rf sqlite-autoconf-$SQLITE_VER sqlite-autoconf-$SQLITE_VER.tar.gz

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

ENV RUST_VERSION=1.88.0
ENV RUSTUP_VER=1.28.2

ENV RUSTUP_AMD64_SHA256="20a06e644b0d9bd2fbdbfd52d42540bdde820ea7df86e92e533c073da0cdd43c"
ENV RUSTUP_ARM64_SHA256="e3853c5a252fca15252d07cb23a1bdd9377a8c6f3efa01531109281ae47f841c"

COPY install.sh .
RUN ./install.sh && rm -rf install.sh

COPY conf.sh .
RUN ./conf.sh && rm -rf conf.sh
