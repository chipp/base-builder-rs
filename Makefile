.DEFAULT_GOAL := tag

tag: RUST_VERSION=$(shell cat Dockerfile | grep "ENV RUST_VERSION" | sed -e 's,ENV RUST_VERSION=\(.*\),\1,' | tr -d '\n')
tag: NEXT_REVISION=$(shell echo $$(( $(shell git tag -l | grep $(RUST_VERSION) | sort -r | head -n 1 | sed -e 's,.*_\(.*\),\1,') + 1 )))
tag:
	git tag $(RUST_VERSION)_$(NEXT_REVISION) HEAD
	git push origin $(RUST_VERSION)_$(NEXT_REVISION)

test:
	docker buildx build . \
		--push \
		--build-arg VARIANT=x86_64_musl \
		--build-arg RUST_TARGET=x86_64-unknown-linux-musl \
		--build-arg OPENSSL_ARCH=linux-x86_64 \
		--platform linux/arm64 \
		--progress plain \
		--tag ghcr.io/chipp/build.rust.x86_64_musl:test
	docker buildx build validate \
		--load \
		--platform linux/arm64 \
		--progress plain \
		--no-cache \
		--tag ghcr.io/chipp/build.rust.x86_64_musl.validate:test
	docker rmi \
		ghcr.io/chipp/build.rust.x86_64_musl.validate:test

release_x86_64: VERSION=$(shell git tag --sort=committerdate | tail -1 | tr -d '\n')
release_x86_64: RUST_VERSION=$(shell printf ${VERSION} | sed -e 's,\(.*\)_.*,\1,')
release_x86_64:
	docker buildx build . \
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
	docker buildx build . \
		--push \
		--build-arg VARIANT=armv7_musl \
		--build-arg RUST_TARGET=armv7-unknown-linux-musleabihf \
		--build-arg OPENSSL_ARCH=linux-generic32 \
		--label "org.opencontainers.image.source=https://github.com/chipp/base-builder-rs" \
		--platform linux/amd64,linux/arm64 \
		--tag ghcr.io/chipp/build.rust.armv7_musl:${VERSION} \
		--tag ghcr.io/chipp/build.rust.armv7_musl:${RUST_VERSION} \
		--tag ghcr.io/chipp/build.rust.armv7_musl:latest \
		--cache-from=type=registry,ref=ghcr.io/chipp/build.rust.armv7_musl:cache \
		--cache-to=type=registry,ref=ghcr.io/chipp/build.rust.armv7_musl:cache,mode=max

release: release_x86_64 release_armv7
