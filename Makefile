.DEFAULT_GOAL := tag

tag: RUST_VERSION=$(shell cat Dockerfile | grep "ENV RUST_VERSION" | sed -e 's,ENV RUST_VERSION=\(.*\),\1,' | tr -d '\n')
tag: NEXT_REVISION=$(shell echo $$(( $(shell git tag -l | grep $(RUST_VERSION) | sort -r | head -n 1 | sed -e 's,.*_\(.*\),\1,') + 1 )))
tag:
	git tag $(RUST_VERSION)_$(NEXT_REVISION) HEAD
	git push origin $(RUST_VERSION)_$(NEXT_REVISION)
