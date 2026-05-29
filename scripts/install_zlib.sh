#!/bin/bash
set -ex

curl -sSL -o zlib-ng-$ZLIB_NG_VER.tar.gz https://github.com/zlib-ng/zlib-ng/archive/refs/tags/$ZLIB_NG_VER.tar.gz
echo "$ZLIB_NG_SHA256  zlib-ng-$ZLIB_NG_VER.tar.gz" | sha256sum -c -
tar xfz zlib-ng-${ZLIB_NG_VER}.tar.gz
cd zlib-ng-$ZLIB_NG_VER
CC="$CC -fPIC -pie" LDFLAGS="-L$PREFIX/lib" CFLAGS="-I$PREFIX/include" \
./configure --static --zlib-compat --prefix=$PREFIX
make -j$(nproc)
make install
cd ..
rm -rf zlib-ng-$ZLIB_NG_VER zlib-ng-$ZLIB_NG_VER.tar.gz
