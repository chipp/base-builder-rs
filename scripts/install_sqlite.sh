#!/bin/bash
set -ex

curl -sSL -O https://www.sqlite.org/2026/sqlite-autoconf-$SQLITE_VER.tar.gz
echo "$SQLITE_SHA256  sqlite-autoconf-$SQLITE_VER.tar.gz" | sha256sum -c -
tar xfz sqlite-autoconf-${SQLITE_VER}.tar.gz
mkdir -p sqlite-autoconf-$SQLITE_VER/build
cd sqlite-autoconf-$SQLITE_VER/build
CC="$CC -fPIC -pie $ADDITIONAL_CFLAGS $ADDITIONAL_LIBS" ../configure --disable-shared \
--host=$TARGET --prefix=$PREFIX
make -j$(nproc)
make install
cd ../..
rm -rf sqlite-autoconf-$SQLITE_VER sqlite-autoconf-$SQLITE_VER.tar.gz
