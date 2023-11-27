.DEFAULT_GOAL := tag

tag: RUST_VERSION=$(shell cat Dockerfile | grep "ENV RUST_VERSION" | sed -e 's,ENV RUST_VERSION=\(.*\),\1,' | tr -d '\n')
tag: NEXT_REVISION=$(shell echo $$(( $(shell git tag -l | grep $(RUST_VERSION) | sort -r | head -n 1 | sed -e 's,.*_\(.*\),\1,') + 1 )))
tag:
	git tag $(RUST_VERSION)_$(NEXT_REVISION) HEAD
	git push origin $(RUST_VERSION)_$(NEXT_REVISION)

test_x86_64:
	DOCKER_BUILDKIT=0 docker build . \
		--build-arg VARIANT=x86_64_musl \
		--build-arg RUST_TARGET=x86_64-unknown-linux-musl \
		--build-arg OPENSSL_ARCH=linux-x86_64 \
		--tag ghcr.io/chipp/build.rust.x86_64_musl:test1
	DOCKER_BUILDKIT=0 docker build validate \
		--build-arg VARIANT=x86_64_musl \
		--no-cache \
		--tag ghcr.io/chipp/build.rust.x86_64_musl.validate:test
	docker rmi ghcr.io/chipp/build.rust.x86_64_musl.validate:test

test_armv7:
	DOCKER_BUILDKIT=0 docker build . \
		--build-arg VARIANT=armv7_musl \
		--build-arg RUST_TARGET=armv7-unknown-linux-musleabihf \
		--build-arg OPENSSL_ARCH=linux-armv4 \
		--build-arg OPENSSL_CFLAGS="-march=armv7-a -mfpu=vfpv3-d16" \
		--build-arg ADDITIONAL_LIBS="-latomic" \
		--tag ghcr.io/chipp/build.rust.armv7_musl:test
	DOCKER_BUILDKIT=0 docker build validate \
		--build-arg VARIANT=armv7_musl \
		--no-cache \
		--tag ghcr.io/chipp/build.rust.armv7_musl.validate:test
	docker rmi ghcr.io/chipp/build.rust.armv7_musl:test

release_x86_64: VERSION=$(shell git tag --sort=committerdate | tail -1 | tr -d '\n')
release_x86_64: RUST_VERSION=$(shell printf ${VERSION} | sed -e 's,\(.*\)_.*,\1,')
release_x86_64:
	docker build . \
		--push \
		--build-arg VARIANT=x86_64_musl \
		--build-arg RUST_TARGET=x86_64-unknown-linux-musl \
		--build-arg OPENSSL_ARCH=linux-x86_64 \
		--label "org.opencontainers.image.source=https://github.com/chipp/base-builder-rs" \
		--platform linux/amd64,linux/arm64 \
		--tag ghcr.io/chipp/build.rust.x86_64_musl:${VERSION} \
		--tag ghcr.io/chipp/build.rust.x86_64_musl:${RUST_VERSION} \
		--tag ghcr.io/chipp/build.rust.x86_64_musl:latest \
		--cache-from=type=registry,ref=ghcr.io/chipp/build.rust.x86_64_musl:cache \
		--cache-to=type=registry,ref=ghcr.io/chipp/build.rust.x86_64_musl:cache,mode=max

release_armv7: VERSION=$(shell git tag --sort=committerdate | tail -1 | tr -d '\n')
release_armv7: RUST_VERSION=$(shell printf ${VERSION} | sed -e 's,\(.*\)_.*,\1,')
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
		--tag ghcr.io/chipp/build.rust.armv7_musl:${VERSION} \
		--tag ghcr.io/chipp/build.rust.armv7_musl:${RUST_VERSION} \
		--tag ghcr.io/chipp/build.rust.armv7_musl:latest \
		--cache-from=type=registry,ref=ghcr.io/chipp/build.rust.armv7_musl:cache \
		--cache-to=type=registry,ref=ghcr.io/chipp/build.rust.armv7_musl:cache,mode=max

release: release_x86_64 release_armv7
