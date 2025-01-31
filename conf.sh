#! /bin/bash

cat <<EOT > /root/.cargo/config.toml
[build]
target = "$RUST_TARGET"

[target.$RUST_TARGET]
linker = "$TARGET-gcc"
EOT
