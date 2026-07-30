SHELL := /bin/sh
GO_TAGS := -tags=nomsgpack
# ponytail: bounded for 2 GiB development hosts; raise if measured bundle growth requires it.
WEB_NODE_OPTIONS ?= --max-old-space-size=384

.PHONY: generate test check check-generated build

generate:
	pnpm --dir web run generate:api

test:
	go test $(GO_TAGS) ./...
	node --experimental-strip-types --test .pi/tests/safety-gate.test.ts
	pnpm --dir web run test

check: check-generated
	@files="$$(gofmt -l cmd internal)"; test -z "$$files" || { echo "Go files need formatting:"; echo "$$files"; exit 1; }
	go vet $(GO_TAGS) ./...
	$(MAKE) test
	pnpm --dir web run typecheck
	pnpm --dir web run lint

check-generated:
	@before="$$(mktemp)"; trap 'rm -f "$$before"' EXIT; \
	cp web/src/api/schema.d.ts "$$before"; \
	$(MAKE) generate; \
	cmp -s "$$before" web/src/api/schema.d.ts || { diff -u "$$before" web/src/api/schema.d.ts; exit 1; }

build:
	mkdir -p bin
	go build $(GO_TAGS) -o bin/cloudpilot ./cmd/cloudpilot
	NODE_OPTIONS='$(WEB_NODE_OPTIONS)' pnpm --dir web run build
