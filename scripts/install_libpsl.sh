#!/bin/bash
set -ex

curl -sSL -O https://github.com/rockdaboot/libpsl/releases/download/${LIBPSL_VER}/libpsl-${LIBPSL_VER}.tar.gz
echo "$LIBPSL_SHA256  libpsl-$LIBPSL_VER.tar.gz" | sha256sum -c -
tar xfz libpsl-${LIBPSL_VER}.tar.gz
cd libpsl-$LIBPSL_VER
CC="$CC -fPIC -pie $ADDITIONAL_CFLAGS" LIBS="-ldl ${ADDITIONAL_LIBS}" \
./configure --prefix=$PREFIX \
--disable-shared --disable-man --enable-builtin --host=$TARGET
make -j$(nproc)
make install
cd ..
rm -rf libpsl-$LIBPSL_VER libpsl-$LIBPSL_VER.tar.gz
