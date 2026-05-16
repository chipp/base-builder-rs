#!/bin/bash
set -ex

curl -sSL -O https://curl.haxx.se/download/curl-$CURL_VER.tar.gz
echo "$CURL_SHA256  curl-$CURL_VER.tar.gz" | sha256sum -c -
tar xfz curl-${CURL_VER}.tar.gz
cd curl-$CURL_VER
CC="$CC -fPIC -pie $ADDITIONAL_CFLAGS" LIBS="-ldl ${ADDITIONAL_LIBS}" \
./configure --enable-shared=no --with-zlib --with-openssl --enable-optimize --prefix=$PREFIX \
--with-ca-path=/etc/ssl/certs/ --with-ca-bundle=/etc/ssl/certs/ca-certificates.crt --without-ca-fallback \
--disable-shared --disable-ldap --disable-sspi --without-librtmp --disable-ftp \
--disable-file --disable-dict --disable-telnet --disable-tftp --disable-manual --disable-ldaps \
--disable-dependency-tracking --disable-rtsp --disable-pop3  --disable-imap --disable-smtp \
--disable-gopher --disable-smb --without-libidn --disable-proxy --host=$TARGET
make -j$(nproc) curl_LDFLAGS="-all-static"
make install
cd ..
rm -rf curl-$CURL_VER curl-$CURL_VER.tar.gz
