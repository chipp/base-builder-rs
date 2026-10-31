#!/bin/bash
set -euo pipefail

source versions.env
case "$1" in
    checksum_zlib_ng)
        key=ZLIB_NG_SHA256
        url="https://github.com/zlib-ng/zlib-ng/archive/refs/tags/$ZLIB_NG_VER.tar.gz" ;;
    checksum_ssl)
        key=SSL_SHA256
        url="https://www.openssl.org/source/openssl-$SSL_VER.tar.gz" ;;
    checksum_libpsl)
        key=LIBPSL_SHA256
        url="https://github.com/rockdaboot/libpsl/releases/download/$LIBPSL_VER/libpsl-$LIBPSL_VER.tar.gz" ;;
    checksum_curl)
        key=CURL_SHA256
        url="https://curl.haxx.se/download/curl-$CURL_VER.tar.gz" ;;
    checksum_sqlite)
        key=SQLITE_SHA256
        url="https://www.sqlite.org/2026/sqlite-autoconf-$SQLITE_VER.tar.gz" ;;
    checksum_rustup_amd64)
        key=RUSTUP_AMD64_SHA256
        url="https://static.rust-lang.org/rustup/archive/$RUSTUP_VER/x86_64-unknown-linux-gnu/rustup-init" ;;
    checksum_rustup_arm64)
        key=RUSTUP_ARM64_SHA256
        url="https://static.rust-lang.org/rustup/archive/$RUSTUP_VER/aarch64-unknown-linux-gnu/rustup-init" ;;
    *) echo "Unknown checksum target: $1" >&2; exit 1 ;;
esac

archive=$(mktemp)
trap 'rm -f "$archive"' EXIT
curl -fLsS --retry 3 "$url" -o "$archive"
checksum=$(shasum -a 256 "$archive")
checksum=${checksum%% *}
python3 - "$key" "$checksum" <<'PY'
from pathlib import Path
import re
import sys

path = Path("versions.env")
content = path.read_text()
updated, count = re.subn(rf'(?m)^{re.escape(sys.argv[1])}="[0-9a-f]{{64}}"$',
                         f'{sys.argv[1]}="{sys.argv[2]}"', content)
if count != 1:
    raise SystemExit(f"Expected exactly one valid {sys.argv[1]} entry, found {count}")
path.write_text(updated)
PY
printf '%s %s\n' "$key" "$checksum"
