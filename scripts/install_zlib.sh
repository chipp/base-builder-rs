#!/bin/bash
set -ex

curl -sSL -O https://zlib.net/zlib-$ZLIB_VER.tar.gz
echo "$ZLIB_SHA256  zlib-$ZLIB_VER.tar.gz" | sha256sum -c -
tar xfz zlib-${ZLIB_VER}.tar.gz
cd zlib-$ZLIB_VER
CC="$CC -fPIC -pie" LDFLAGS="-L$PREFIX/lib" CFLAGS="-I$PREFIX/include" \
./configure --static --prefix=$PREFIX
make -j$(nproc)
make install
cd ..
rm -rf zlib-$ZLIB_VER zlib-$ZLIB_VER.tar.gz
