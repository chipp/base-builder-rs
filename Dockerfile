ARG VARIANT=x86_64_musl

FROM ghcr.io/chipp/build.musl.${VARIANT}:latest

# used in install.sh, provided by docker builder
ARG TARGETARCH

ARG RUST_TARGET=x86_64-unknown-linux-musl
ARG OPENSSL_ARCH=linux-x86_64
ARG OPENSSL_CFLAGS
ARG ADDITIONAL_LIBS

ENV ZLIB_VER=1.3
ENV ZLIB_SHA256="ff0ba4c292013dbc27530b3a81e1f9a813cd39de01ca5e0f8bf355702efa593e"
RUN curl -sSL -O https://zlib.net/zlib-$ZLIB_VER.tar.gz && \
  echo "$ZLIB_SHA256  zlib-$ZLIB_VER.tar.gz" | sha256sum -c - && \
  tar xfz zlib-${ZLIB_VER}.tar.gz && cd zlib-$ZLIB_VER && \
  CC="$CC -fPIC -pie" LDFLAGS="-L$PREFIX/lib" CFLAGS="-I$PREFIX/include" \
  ./configure --static --prefix=$PREFIX && \
  make -j$(nproc) && make install && \
  cd .. && rm -rf zlib-$ZLIB_VER zlib-$ZLIB_VER.tar.gz

ENV SSL_VER=3.2.0
ENV SSL_SHA256="14c826f07c7e433706fb5c69fa9e25dab95684844b4c962a2cf1bf183eb4690e"
RUN curl -sSL -O https://www.openssl.org/source/openssl-$SSL_VER.tar.gz && \
  echo "$SSL_SHA256  openssl-$SSL_VER.tar.gz" | sha256sum -c - && \
  tar xfz openssl-${SSL_VER}.tar.gz && cd openssl-$SSL_VER && \
  CC=gcc ./Configure --cross-compile-prefix=${TARGET}- \
  --prefix=$PREFIX --openssldir=$PREFIX/ssl ${ADDITIONAL_LIBS} \
  no-dso no-shared no-ssl3 no-tests no-comp no-zlib no-zlib-dynamic \
  no-md2 no-rc5 no-weak-ssl-ciphers no-camellia no-idea no-seed \
  no-engine no-async $OPENSSL_ARCH $OPENSSL_CFLAGS \
  -fdata-sections -ffunction-sections -fPIC -O2 \
  -DOPENSSL_NO_SECURE_MEMORY && \
  env C_INCLUDE_PATH=$PREFIX/include make depend 2> /dev/null && \
  make -j$(nproc) && make install_sw && \
  cd .. && rm -rf openssl-$SSL_VER openssl-$SSL_VER.tar.gz

ENV CURL_VER=8.4.0
ENV CURL_SHA256="816e41809c043ff285e8c0f06a75a1fa250211bbfb2dc0a037eeef39f1a9e427"
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

ENV SQLITE_VER=3440000
ENV SQLITE_SHA256="b9cd386e7cd22af6e0d2a0f06d0404951e1bef109e42ea06cc0450e10cd15550"
RUN curl -sSL -O https://www.sqlite.org/2023/sqlite-autoconf-$SQLITE_VER.tar.gz && \
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

ENV RUST_VERSION=1.76.0

ENV RUSTUP_VER=1.26.0

ENV RUSTUP_AMD64_SHA256="0b2f6c8f85a3d02fde2efc0ced4657869d73fccfce59defb4e8d29233116e6db"
ENV RUSTUP_ARM64_SHA256="673e336c81c65e6b16dcdede33f4cc9ed0f08bde1dbe7a935f113605292dc800"

COPY install.sh .
RUN ./install.sh && rm -rf install.sh

RUN echo "[build]\ntarget = \"$RUST_TARGET\"\n\n\
  [target.$RUST_TARGET]\nlinker = \"$TARGET-gcc\"\n" > /root/.cargo/config
