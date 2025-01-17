ARG VARIANT=x86_64_musl

FROM ghcr.io/chipp/build.musl.${VARIANT}:latest

# used in install.sh, provided by docker builder
ARG TARGETARCH

ARG RUST_TARGET=x86_64-unknown-linux-musl
ARG OPENSSL_ARCH=linux-x86_64
ARG OPENSSL_CFLAGS
ARG ADDITIONAL_LIBS

ENV ZLIB_VER=1.3.1
ENV ZLIB_SHA256="9a93b2b7dfdac77ceba5a558a580e74667dd6fede4585b91eefb60f03b72df23"
RUN curl -sSL -O https://zlib.net/zlib-$ZLIB_VER.tar.gz && \
    echo "$ZLIB_SHA256  zlib-$ZLIB_VER.tar.gz" | sha256sum -c - && \
    tar xfz zlib-${ZLIB_VER}.tar.gz && cd zlib-$ZLIB_VER && \
    CC="$CC -fPIC -pie" LDFLAGS="-L$PREFIX/lib" CFLAGS="-I$PREFIX/include" \
    ./configure --static --prefix=$PREFIX && \
    make -j$(nproc) && make install && \
    cd .. && rm -rf zlib-$ZLIB_VER zlib-$ZLIB_VER.tar.gz

ENV SSL_VER=3.2.3
ENV SSL_SHA256="52b5f1c6b8022bc5868c308c54fb77705e702d6c6f4594f99a0df216acf46239"
RUN curl -sSL -O https://www.openssl.org/source/openssl-$SSL_VER.tar.gz && \
    echo "$SSL_SHA256  openssl-$SSL_VER.tar.gz" | sha256sum -c - && \
    tar xfz openssl-${SSL_VER}.tar.gz && cd openssl-$SSL_VER && \
    CC=gcc ./Configure --cross-compile-prefix=${TARGET}- \
    --prefix=$PREFIX --openssldir=$PREFIX/ssl ${ADDITIONAL_LIBS} \
    no-dso no-shared no-ssl3 no-tests no-comp no-zlib no-zlib-dynamic \
    no-md2 no-rc5 no-weak-ssl-ciphers no-camellia no-idea no-seed \
    no-engine no-async no-apps $OPENSSL_ARCH $OPENSSL_CFLAGS \
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
    CC="$CC -fPIC -pie" LIBS="-ldl ${ADDITIONAL_LIBS}" \
    ./configure --prefix=$PREFIX \
    --disable-shared --disable-man --enable-builtin --host=$TARGET && \
    make -j$(nproc) && make install && \
    cd .. && rm -rf libpsl-$LIBPSL_VER libpsl-$LIBPSL_VER.tar.gz

ENV CURL_VER=8.10.1
ENV CURL_SHA256="d15ebab765d793e2e96db090f0e172d127859d78ca6f6391d7eafecfd894bbc0"
RUN curl -sSL -O https://curl.haxx.se/download/curl-$CURL_VER.tar.gz && \
    echo "$CURL_SHA256  curl-$CURL_VER.tar.gz" | sha256sum -c - && \
    tar xfz curl-${CURL_VER}.tar.gz && cd curl-$CURL_VER && \
    CC="$CC -fPIC -pie" LIBS="-ldl ${ADDITIONAL_LIBS}" \
    ./configure --enable-shared=no --with-zlib --with-openssl --enable-optimize --prefix=$PREFIX \
    --with-ca-path=/etc/ssl/certs/ --with-ca-bundle=/etc/ssl/certs/ca-certificates.crt --without-ca-fallback \
    --disable-shared --disable-ldap --disable-sspi --without-librtmp --disable-ftp \
    --disable-file --disable-dict --disable-telnet --disable-tftp --disable-manual --disable-ldaps \
    --disable-dependency-tracking --disable-rtsp --disable-pop3  --disable-imap --disable-smtp \
    --disable-gopher --disable-smb --without-libidn --disable-proxy --host=$TARGET && \
    make -j$(nproc) curl_LDFLAGS="-all-static" && make install && \
    cd .. && rm -rf curl-$CURL_VER curl-$CURL_VER.tar.gz

ENV SQLITE_VER=3470000
ENV SQLITE_SHA256="83eb21a6f6a649f506df8bd3aab85a08f7556ceed5dbd8dea743ea003fc3a957"
RUN curl -sSL -O https://www.sqlite.org/2024/sqlite-autoconf-$SQLITE_VER.tar.gz && \
    echo "$SQLITE_SHA256  sqlite-autoconf-$SQLITE_VER.tar.gz" | sha256sum -c - && \
    tar xfz sqlite-autoconf-${SQLITE_VER}.tar.gz && cd sqlite-autoconf-$SQLITE_VER && \
    CC="$CC -fPIC -pie" ./configure --enable-shared=no --host $TARGET --prefix=$PREFIX && \
    make -j$(nproc) && make install && \
    cd .. && rm -rf sqlite-autoconf-$SQLITE_VER sqlite-autoconf-$SQLITE_VER.tar.gz

ENV OPENSSL_STATIC=1 \
    OPENSSL_DIR=$PREFIX \
    OPENSSL_INCLUDE_DIR=$PREFIX/include/ \
    DEP_OPENSSL_INCLUDE=$PREFIX/include/ \
    X86_64_UNKNOWN_LINUX_MUSL_OPENSSL_LIB_DIR=$PREFIX/lib64/ \
    ARMV7_UNKNOWN_LINUX_MUSLEABIHF_OPENSSL_LIB_DIR=$PREFIX/lib/ \
    LIBZ_SYS_STATIC=1 \
    SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt \
    SSL_CERT_DIR=/etc/ssl/certs \
    LIBSQLITE3_SYS_USE_PKG_CONFIG=1

ENV PATH=/root/.cargo/bin:$PATH

ENV RUST_VERSION=1.84.0

ENV RUSTUP_VER=1.27.1

ENV RUSTUP_AMD64_SHA256="6aeece6993e902708983b209d04c0d1dbb14ebb405ddb87def578d41f920f56d"
ENV RUSTUP_ARM64_SHA256="1cffbf51e63e634c746f741de50649bbbcbd9dbe1de363c9ecef64e278dba2b2"

COPY install.sh .
RUN ./install.sh && rm -rf install.sh

RUN echo "[build]\ntarget = \"$RUST_TARGET\"\n\n\
    [target.$RUST_TARGET]\nlinker = \"$TARGET-gcc\"\n" > /root/.cargo/config.toml
