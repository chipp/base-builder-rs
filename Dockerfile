FROM debian:buster-slim

ARG TARGET=x86_64-unknown-linux-musl
ARG OPENSSL_ARCH=linux-x86_64

RUN apt-get update && apt-get install -y \
  curl \
  xutils-dev \
  unzip \
  xz-utils \
  bzip2 \
  patch \
  build-essential \
  file \
  pkg-config \
  ca-certificates \
  --no-install-recommends && \
  rm -rf /var/lib/apt/lists/*

COPY config.mak config.mak

RUN curl -sSL -o musl.zip https://github.com/richfelker/musl-cross-make/archive/v0.9.9.zip && \
  echo "6cbe2f6ce92e7f8f3973786aaf0b990d0db380c0e0fc419a7d516df5bb03c891  musl.zip" | sha256sum -c -; \
  unzip musl.zip && mv musl-cross-make-0.9.9 musl-cross-make && cd musl-cross-make && \
  mv ../config.mak ./ && \
  TARGET=$TARGET make -j$(nproc) install > /dev/null && \
  cd .. && rm -rf musl-cross-make musl.zip

ENV PREFIX=/musl/$TARGET \
  PKG_CONFIG_PATH=/usr/local/lib/pkgconfig \
  LD_LIBRARY_PATH=$PREFIX \
  PATH=/musl/bin:$PATH

ENV TARGET_CC=/musl/bin/$TARGET-gcc \
  TARGET_CXX=/musl/bin/$TARGET-g++ \
  TARGET_C_INCLUDE_PATH=$PREFIX/include/

ENV CC=$TARGET_CC \
  CXX=$TARGET_CXX \
  C_INCLUDE_PATH=$TARGET_C_INCLUDE_PATH

ENV ZLIB_VER="1.2.13" ZLIB_SHA256="b3a24de97a8fdbc835b9833169501030b8977031bcb54b3b3ac13740f846ab30"
RUN curl -sSL -O https://zlib.net/zlib-$ZLIB_VER.tar.gz && \
  echo "$ZLIB_SHA256  zlib-$ZLIB_VER.tar.gz" | sha256sum -c - && \
  tar xfz zlib-${ZLIB_VER}.tar.gz && cd zlib-$ZLIB_VER && \
  CC="$CC -fPIC -pie" LDFLAGS="-L$PREFIX/lib" CFLAGS="-I$PREFIX/include" \
  CHOST=arm ./configure --static --prefix=$PREFIX && \
  make -j$(nproc) && make install && \
  cd .. && rm -rf zlib-$ZLIB_VER zlib-$ZLIB_VER.tar.gz

ENV SSL_VER="1.1.1s" SSL_SHA256="c5ac01e760ee6ff0dab61d6b2bbd30146724d063eb322180c6f18a6f74e4b6aa"
RUN curl -sSL -O https://www.openssl.org/source/openssl-$SSL_VER.tar.gz && \
  echo "$SSL_SHA256  openssl-$SSL_VER.tar.gz" | sha256sum -c - && \
  tar xfz openssl-${SSL_VER}.tar.gz && cd openssl-$SSL_VER && \
  CC=gcc ./Configure no-zlib no-shared -fPIC --cross-compile-prefix=$TARGET- --prefix=$PREFIX --openssldir=$PREFIX/ssl $OPENSSL_ARCH && \
  env C_INCLUDE_PATH=$PREFIX/include make depend 2> /dev/null && \
  make -j$(nproc) && make install_sw && \
  cd .. && rm -rf openssl-$SSL_VER openssl-$SSL_VER.tar.gz

ENV CURL_VER="7.86.0" CURL_SHA256="3dfdd39ba95e18847965cd3051ea6d22586609d9011d91df7bc5521288987a82"
RUN curl -sSL -O https://curl.haxx.se/download/curl-$CURL_VER.tar.gz && \
  echo "$CURL_SHA256  curl-$CURL_VER.tar.gz" | sha256sum -c - && \
  tar xfz curl-${CURL_VER}.tar.gz && cd curl-$CURL_VER && \
  CC="$CC -fPIC -pie" LIBS="-ldl" LDFLAGS="-L$PREFIX/lib" CPPFLAGS="-I$PREFIX/include" CFLAGS="-I$PREFIX/include" \
  ./configure --enable-shared=no --with-zlib --enable-static=ssl --with-ssl="$PREFIX" --enable-optimize --prefix=$PREFIX \
  --with-ca-path=/etc/ssl/certs/ --with-ca-bundle=/etc/ssl/certs/ca-certificates.crt --without-ca-fallback \
  --disable-shared --disable-ldap --disable-sspi --without-librtmp --disable-ftp \
  --disable-file --disable-dict --disable-telnet --disable-tftp --disable-manual --disable-ldaps \
  --disable-dependency-tracking --disable-rtsp --disable-pop3  --disable-imap --disable-smtp \
  --disable-gopher --disable-smb --without-libidn --disable-proxy --host armv7 && \
  make -j$(nproc) curl_LDFLAGS="-all-static" && make install && \
  cd .. && rm -rf curl-$CURL_VER curl-$CURL_VER.tar.gz

ENV PATH=/root/.cargo/bin:$PATH

ENV RUST_VERSION=1.66.0

ENV RUSTUP_VER="1.25.1" RUSTUP_SHA256="5cc9ffd1026e82e7fb2eec2121ad71f4b0f044e88bca39207b3f6b769aaa799c"
RUN curl -O https://static.rust-lang.org/rustup/archive/$RUSTUP_VER/x86_64-unknown-linux-gnu/rustup-init && \
  echo "$RUSTUP_SHA256 *rustup-init" | sha256sum -c - && \
  chmod +x rustup-init && \
  ./rustup-init -y --no-modify-path --profile minimal --default-toolchain $RUST_VERSION --default-host x86_64-unknown-linux-gnu && \
  rm rustup-init && \
  rustup target add $TARGET

RUN echo "[build]\ntarget = \"$TARGET\"\n\n\
  [target.$TARGET]\nlinker = \"$TARGET-gcc\"\n" > /root/.cargo/config

ENV OPENSSL_STATIC=1 \
  OPENSSL_DIR=$PREFIX \
  OPENSSL_INCLUDE_DIR=$PREFIX/include/ \
  DEP_OPENSSL_INCLUDE=$PREFIX/include/ \
  OPENSSL_LIB_DIR=$PREFIX/lib/ \
  LIBZ_SYS_STATIC=1 \
  SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt \
  SSL_CERT_DIR=/etc/ssl/certs

ENV CHOST=armv7-unknown-linux-musleabihf \
  CROSS_PREFIX=armv7-unknown-linux-musleabihf- \
  CXX=armv7-unknown-linux-musleabihf-g++ \
  LDFLAGS="-L$PREFIX/lib" \
  CFLAGS="-I$PREFIX/include" \
  PKG_CONFIG_ALLOW_CROSS=true \
  PKG_CONFIG_ALL_STATIC=true \
  PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig

ENV RUSTFLAGS=-L$PREFIX/lib
