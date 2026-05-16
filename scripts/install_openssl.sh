#!/bin/bash
set -ex

curl -sSL -O https://www.openssl.org/source/openssl-$SSL_VER.tar.gz
echo "$SSL_SHA256  openssl-$SSL_VER.tar.gz" | sha256sum -c -
tar xfz openssl-${SSL_VER}.tar.gz
cd openssl-$SSL_VER
CC=gcc ./Configure --cross-compile-prefix=${TARGET}- \
--prefix=$PREFIX --openssldir=$PREFIX/ssl ${ADDITIONAL_LIBS} \
no-dso no-shared no-ssl3 no-tests no-comp no-zlib no-zlib-dynamic \
no-md2 no-rc5 no-weak-ssl-ciphers no-camellia no-idea no-seed \
no-engine no-async no-apps $OPENSSL_ARCH $ADDITIONAL_CFLAGS \
-fdata-sections -ffunction-sections -fPIC -O2 \
-DOPENSSL_NO_SECURE_MEMORY
env C_INCLUDE_PATH=$PREFIX/include make depend 2> /dev/null
make -j$(nproc)
make install_sw
cd ..
rm -rf openssl-$SSL_VER openssl-$SSL_VER.tar.gz
