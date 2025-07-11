.DEFAULT_GOAL := tag

checksums: checksum_zlib checksum_ssl checksum_libpsl checksum_curl checksum_sqlite checksum_rustup

checksum_zlib: ZLIB_VER=$(shell cat Dockerfile | grep "ENV ZLIB_VER" | sed -e 's,ENV ZLIB_VER=\(.*\),\1,' | tr -d '\n')
checksum_zlib: ZLIB_SHA256=$(shell curl -sSL https://zlib.net/zlib-$(ZLIB_VER).tar.gz | sha256sum - | tr -d '-' | tr -d ' ')
checksum_zlib:
	@sed -i '' "s/ENV ZLIB_SHA256=\"[0-9,a-f]*\"/ENV ZLIB_SHA256=\"$(ZLIB_SHA256)\"/g" ./Dockerfile
	@echo "zlib $(ZLIB_VER) $(ZLIB_SHA256)"

checksum_ssl: SSL_VER=$(shell cat Dockerfile | grep "ENV SSL_VER" | sed -e 's,ENV SSL_VER=\(.*\),\1,' | tr -d '\n')
checksum_ssl: SSL_SHA256=$(shell curl -sSL https://www.openssl.org/source/openssl-$(SSL_VER).tar.gz | sha256sum - | tr -d '-' | tr -d ' ')
checksum_ssl:
	@sed -i '' "s/ENV SSL_SHA256=\"[0-9,a-f]*\"/ENV SSL_SHA256=\"$(SSL_SHA256)\"/g" ./Dockerfile
	@echo "ssl $(SSL_VER) $(SSL_SHA256)"

checksum_libpsl: LIBPSL_VER=$(shell cat Dockerfile | grep "ENV LIBPSL_VER" | sed -e 's,ENV LIBPSL_VER=\(.*\),\1,' | tr -d '\n')
checksum_libpsl: LIBPSL_SHA256=$(shell curl -sSL https://github.com/rockdaboot/libpsl/releases/download/${LIBPSL_VER}/libpsl-${LIBPSL_VER}.tar.gz | sha256sum - | tr -d '-' | tr -d ' ')
checksum_libpsl:
	@sed -i '' "s/ENV LIBPSL_SHA256=\"[0-9,a-f]*\"/ENV LIBPSL_SHA256=\"$(LIBPSL_SHA256)\"/g" ./Dockerfile
	@echo "libpsl $(LIBPSL_VER) $(LIBPSL_SHA256)"

checksum_curl: CURL_VER=$(shell cat Dockerfile | grep "ENV CURL_VER" | sed -e 's,ENV CURL_VER=\(.*\),\1,' | tr -d '\n')
checksum_curl: CURL_SHA256=$(shell curl -sSL https://curl.haxx.se/download/curl-$(CURL_VER).tar.gz | sha256sum - | tr -d '-' | tr -d ' ')
checksum_curl:
	@sed -i '' "s/ENV CURL_SHA256=\"[0-9,a-f]*\"/ENV CURL_SHA256=\"$(CURL_SHA256)\"/g" ./Dockerfile
	@echo "curl $(CURL_VER) $(CURL_SHA256)"

checksum_sqlite: SQLITE_VER=$(shell cat Dockerfile | grep "ENV SQLITE_VER" | sed -e 's,ENV SQLITE_VER=\(.*\),\1,' | tr -d '\n')
checksum_sqlite: SQLITE_SHA256=$(shell curl -sSL https://www.sqlite.org/2025/sqlite-autoconf-$(SQLITE_VER).tar.gz | sha256sum - | tr -d '-' | tr -d ' ')
checksum_sqlite:
	@sed -i '' "s/ENV SQLITE_SHA256=\"[0-9,a-f]*\"/ENV SQLITE_SHA256=\"$(SQLITE_SHA256)\"/g" ./Dockerfile
	@echo "sqlite $(SQLITE_VER) $(SQLITE_SHA256)"

checksum_rustup: checksum_rustup_amd64 checksum_rustup_arm64

checksum_rustup_amd64: RUSTUP_VER=$(shell cat Dockerfile | grep "ENV RUSTUP_VER" | sed -e 's,ENV RUSTUP_VER=\(.*\),\1,' | tr -d '\n')
checksum_rustup_amd64: RUSTUP_AMD64_SHA256=$(shell curl -sSL https://static.rust-lang.org/rustup/archive/$(RUSTUP_VER)/x86_64-unknown-linux-gnu/rustup-init | sha256sum - | tr -d '-' | tr -d ' ')
checksum_rustup_amd64:
	@sed -i '' "s/ENV RUSTUP_AMD64_SHA256=\"[0-9,a-f]*\"/ENV RUSTUP_AMD64_SHA256=\"$(RUSTUP_AMD64_SHA256)\"/g" ./Dockerfile
	@echo "rustup amd64 $(RUSTUP_VER) $(RUSTUP_AMD64_SHA256)"

checksum_rustup_arm64: RUSTUP_VER=$(shell cat Dockerfile | grep "ENV RUSTUP_VER" | sed -e 's,ENV RUSTUP_VER=\(.*\),\1,' | tr -d '\n')
checksum_rustup_arm64: RUSTUP_ARM64_SHA256=$(shell curl -sSL https://static.rust-lang.org/rustup/archive/$(RUSTUP_VER)/aarch64-unknown-linux-gnu/rustup-init | sha256sum - | tr -d '-' | tr -d ' ')
checksum_rustup_arm64:
	@sed -i '' "s/ENV RUSTUP_ARM64_SHA256=\"[0-9,a-f]*\"/ENV RUSTUP_ARM64_SHA256=\"$(RUSTUP_ARM64_SHA256)\"/g" ./Dockerfile
	@echo "rustup amd64 $(RUSTUP_VER) $(RUSTUP_ARM64_SHA256)"

tag: RUST_VERSION=$(shell cat Dockerfile | grep "ENV RUST_VERSION" | sed -e 's,ENV RUST_VERSION=\(.*\),\1,' | tr -d '\n')
tag: NEXT_REVISION=$(shell echo $$(( $(shell git tag -l | grep $(RUST_VERSION) | sort -r | head -n 1 | sed -e 's,.*_\(.*\),\1,') + 1 )))
tag:
	git tag $(RUST_VERSION)_$(NEXT_REVISION) HEAD
	git push origin $(RUST_VERSION)_$(NEXT_REVISION)

test_x86_64:
	BUILDX_EXPERIMENTAL=1 docker buildx debug build . \
		--load \
		--build-arg VARIANT=x86_64_musl \
		--build-arg RUST_TARGET=x86_64-unknown-linux-musl \
		--build-arg OPENSSL_ARCH=linux-x86_64 \
		--tag ghcr.io/chipp/build.rust.x86_64_musl:test
	BUILDX_EXPERIMENTAL=1 docker buildx debug build validate \
		--load \
		--platform linux/amd64 \
		--build-context base-builder-rs=docker-image://ghcr.io/chipp/build.rust.x86_64_musl:test \
		--build-context emulator=docker-image://amd64/alpine \
		--tag ghcr.io/chipp/build.rust.x86_64_musl.validate:test
	docker rmi ghcr.io/chipp/build.rust.x86_64_musl.validate:test ghcr.io/chipp/build.rust.x86_64_musl:test

test_armv7:
	BUILDX_EXPERIMENTAL=1 docker buildx debug build . \
		--load \
		--build-arg VARIANT=armv7_musl \
		--build-arg RUST_TARGET=armv7-unknown-linux-musleabihf \
		--build-arg OPENSSL_ARCH=linux-armv4 \
		--build-arg ADDITIONAL_CFLAGS="-march=armv7-a -mfpu=vfpv3-d16" \
		--build-arg ADDITIONAL_LIBS="-latomic" \
		--tag ghcr.io/chipp/build.rust.armv7_musl:test
	BUILDX_EXPERIMENTAL=1 docker buildx debug build validate \
		--load \
		--platform linux/arm/v7 \
		--build-context base-builder-rs=docker-image://ghcr.io/chipp/build.rust.armv7_musl:test \
		--build-context emulator=docker-image://arm32v7/alpine \
		--tag ghcr.io/chipp/build.rust.armv7_musl.validate:test
	docker rmi ghcr.io/chipp/build.rust.armv7_musl.validate:test ghcr.io/chipp/build.rust.armv7_musl:test 

test_arm64:
	BUILDX_EXPERIMENTAL=1 docker buildx debug build . \
		--load \
		--build-arg VARIANT=arm64_musl \
		--build-arg RUST_TARGET=aarch64-unknown-linux-musl \
		--build-arg OPENSSL_ARCH=linux-aarch64 \
		--tag ghcr.io/chipp/build.rust.arm64_musl:test
	BUILDX_EXPERIMENTAL=1 docker buildx debug build validate \
		--load \
		--platform linux/arm64 \
		--build-context base-builder-rs=docker-image://ghcr.io/chipp/build.rust.arm64_musl:test \
		--build-context emulator=docker-image://arm64v8/alpine \
		--tag ghcr.io/chipp/build.rust.arm64_musl.validate:test
	docker rmi ghcr.io/chipp/build.rust.arm64_musl.validate:test ghcr.io/chipp/build.rust.arm64_musl:test

test: test_x86_64 test_armv7 test_arm64

release_x86_64: VERSION=$(shell git tag --sort=committerdate | tail -1 | tr -d '\n')
release_x86_64: RUST_VERSION=$(shell printf $(VERSION) | sed -e 's,\(.*\)_.*,\1,')
release_x86_64:
	docker build . \
		--push \
		--build-arg VARIANT=x86_64_musl \
		--build-arg RUST_TARGET=x86_64-unknown-linux-musl \
		--build-arg OPENSSL_ARCH=linux-x86_64 \
		--label "org.opencontainers.image.source=https://github.com/chipp/base-builder-rs" \
		--platform linux/amd64,linux/arm64 \
		--tag ghcr.io/chipp/build.rust.x86_64_musl:$(VERSION) \
		--tag ghcr.io/chipp/build.rust.x86_64_musl:$(RUST_VERSION) \
		--tag ghcr.io/chipp/build.rust.x86_64_musl:latest \
		--cache-from=type=registry,ref=ghcr.io/chipp/build.rust.x86_64_musl:cache \
		--cache-to=type=registry,ref=ghcr.io/chipp/build.rust.x86_64_musl:cache,mode=max

release_armv7: VERSION=$(shell git tag --sort=committerdate | tail -1 | tr -d '\n')
release_armv7: RUST_VERSION=$(shell printf $(VERSION) | sed -e 's,\(.*\)_.*,\1,')
release_armv7:
	docker build . \
		--push \
		--build-arg VARIANT=armv7_musl \
		--build-arg RUST_TARGET=armv7-unknown-linux-musleabihf \
		--build-arg OPENSSL_ARCH=linux-armv4 \
		--build-arg OPENSSL_CFLAGS="-march=armv7-a -mfpu=vfpv3-d16" \
		--build-arg ADDITIONAL_LIBS="-latomic" \
		--label "org.opencontainers.image.source=https://github.com/chipp/base-builder-rs" \
		--platform linux/amd64,linux/arm64 \
		--tag ghcr.io/chipp/build.rust.armv7_musl:$(VERSION) \
		--tag ghcr.io/chipp/build.rust.armv7_musl:$(RUST_VERSION) \
		--tag ghcr.io/chipp/build.rust.armv7_musl:latest \
		--cache-from=type=registry,ref=ghcr.io/chipp/build.rust.armv7_musl:cache \
		--cache-to=type=registry,ref=ghcr.io/chipp/build.rust.armv7_musl:cache,mode=max

release_arm64: VERSION=$(shell git tag --sort=committerdate | tail -1 | tr -d '\n')
release_arm64: RUST_VERSION=$(shell printf $(VERSION) | sed -e 's,\(.*\)_.*,\1,')
release_arm64:
	docker build . \
		--push \
		--build-arg VARIANT=arm64_musl \
		--build-arg RUST_TARGET=aarch64-unknown-linux-musl \
		--build-arg OPENSSL_ARCH=linux-aarch64 \
		--label "org.opencontainers.image.source=https://github.com/chipp/base-builder-rs" \
		--platform linux/amd64,linux/arm64 \
		--tag ghcr.io/chipp/build.rust.arm64_musl:$(VERSION) \
		--tag ghcr.io/chipp/build.rust.arm64_musl:$(RUST_VERSION) \
		--tag ghcr.io/chipp/build.rust.arm64_musl:latest \
		--cache-from=type=registry,ref=ghcr.io/chipp/build.rust.arm64_musl:cache \
		--cache-to=type=registry,ref=ghcr.io/chipp/build.rust.arm64_musl:cache,mode=max

release: release_x86_64 release_armv7 release_arm64
