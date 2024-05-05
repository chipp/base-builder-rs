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

ENV SSL_VER=3.2.1
ENV SSL_SHA256="83c7329fe52c850677d75e5d0b0ca245309b97e8ecbcfdc1dfdc4ab9fac35b39"
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

ENV CURL_VER=8.7.1
ENV CURL_SHA256="f91249c87f68ea00cf27c44fdfa5a78423e41e71b7d408e5901a9896d905c495"
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

ENV SQLITE_VER=3450300
ENV SQLITE_SHA256="b2809ca53124c19c60f42bf627736eae011afdcc205bb48270a5ee9a38191531"
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

ENV RUST_VERSION=1.78.0

ENV RUSTUP_VER=1.27.0

ENV RUSTUP_AMD64_SHA256="a3d541a5484c8fa2f1c21478a6f6c505a778d473c21d60a18a4df5185d320ef8"
ENV RUSTUP_ARM64_SHA256="76cd420cb8a82e540025c5f97bda3c65ceb0b0661d5843e6ef177479813b0367"

COPY install.sh .
RUN ./install.sh && rm -rf install.sh

RUN echo "[build]\ntarget = \"$RUST_TARGET\"\n\n\
  [target.$RUST_TARGET]\nlinker = \"$TARGET-gcc\"\n" > /root/.cargo/config
