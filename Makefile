.DEFAULT_GOAL := tag

checksums: checksum_zlib_ng checksum_ssl checksum_libpsl checksum_curl checksum_sqlite checksum_rustup

checksum_zlib_ng checksum_ssl checksum_libpsl checksum_curl checksum_sqlite checksum_rustup_amd64 checksum_rustup_arm64:
	@bash scripts/update_checksum.sh $@

checksum_rustup: checksum_rustup_amd64 checksum_rustup_arm64

.NOTPARALLEL: checksums checksum_rustup

tag: RUST_VERSION=$(shell cat rust-version)
tag: NEXT_REVISION=$(shell echo $$(( $(shell git tag -l | grep $(RUST_VERSION) | sort -r | head -n 1 | sed -e 's,.*_\(.*\),\1,') + 1 )))
tag:
	git tag $(RUST_VERSION)_$(NEXT_REVISION) HEAD
	git push origin $(RUST_VERSION)_$(NEXT_REVISION)

test_x86_64:
	@set -e; \
	layout=$$(mktemp -d); \
	trap 'rm -rf "$$layout"' EXIT; \
	docker buildx build . \
		--output "type=oci,tar=false,dest=$$layout" \
		--build-arg VARIANT=x86_64_musl \
		--build-arg RUST_TARGET=x86_64-unknown-linux-musl \
		--build-arg OPENSSL_ARCH=linux-x86_64 \
		--tag local/base-builder-x86_64:test; \
	docker buildx build validate \
		--load \
		--platform linux/amd64 \
		--build-context "base-builder-rs=oci-layout://$$layout:test" \
		--build-context project=. \
		--build-context emulator=docker-image://amd64/alpine \
		--tag local/base-builder-x86_64-validate:test; \
	docker rmi local/base-builder-x86_64-validate:test

test_armv7:
	@set -e; \
	layout=$$(mktemp -d); \
	trap 'rm -rf "$$layout"' EXIT; \
	docker buildx build . \
		--output "type=oci,tar=false,dest=$$layout" \
		--build-arg VARIANT=armv7_musl \
		--build-arg RUST_TARGET=armv7-unknown-linux-musleabihf \
		--build-arg OPENSSL_ARCH=linux-armv4 \
		--build-arg ADDITIONAL_CFLAGS="-march=armv7-a -mfpu=vfpv3-d16" \
		--build-arg ADDITIONAL_LIBS="-latomic" \
		--tag local/base-builder-armv7:test; \
	docker buildx build validate \
		--load \
		--platform linux/arm/v7 \
		--build-context "base-builder-rs=oci-layout://$$layout:test" \
		--build-context project=. \
		--build-context emulator=docker-image://arm32v7/alpine \
		--tag local/base-builder-armv7-validate:test; \
	docker rmi local/base-builder-armv7-validate:test

test_arm64:
	@set -e; \
	layout=$$(mktemp -d); \
	trap 'rm -rf "$$layout"' EXIT; \
	docker buildx build . \
		--output "type=oci,tar=false,dest=$$layout" \
		--build-arg VARIANT=arm64_musl \
		--build-arg RUST_TARGET=aarch64-unknown-linux-musl \
		--build-arg OPENSSL_ARCH=linux-aarch64 \
		--tag local/base-builder-arm64:test; \
	docker buildx build validate \
		--load \
		--platform linux/arm64 \
		--build-context "base-builder-rs=oci-layout://$$layout:test" \
		--build-context project=. \
		--build-context emulator=docker-image://arm64v8/alpine \
		--tag local/base-builder-arm64-validate:test; \
	docker rmi local/base-builder-arm64-validate:test

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
