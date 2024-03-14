BUILDDIR ?= $(CURDIR)/build
TOOLS_DIR := tools

GO_BIN := ${GOPATH}/bin
ldflags := $(LDFLAGS)
build_tags := $(BUILD_TAGS)
build_args := $(BUILD_ARGS)

DOCKER := $(shell which docker)
CUR_DIR := $(shell pwd)
MOCKS_DIR=$(CUR_DIR)/testutil/mocks
MOCKGEN_REPO=github.com/golang/mock/mockgen
MOCKGEN_VERSION=v1.6.0
MOCKGEN_CMD=go run ${MOCKGEN_REPO}@${MOCKGEN_VERSION}

PACKAGES_E2E=$(shell go list ./... | grep '/itest')

ifeq ($(LINK_STATICALLY),true)
	ldflags += -linkmode=external -extldflags "-Wl,-z,muldefs -static" -v
endif

ifeq ($(VERBOSE),true)
	build_args += -v
endif

BUILD_TARGETS := build install
BUILD_FLAGS := --tags "$(build_tags)" --ldflags '$(ldflags)'

# Update changelog vars
ifneq (,$(SINCE_TAG))
       sinceTag := --since-tag $(SINCE_TAG)
endif
ifneq (,$(UPCOMING_TAG))
       upcomingTag := --future-release $(UPCOMING_TAG)
endif

all: build install

build: BUILD_ARGS := $(build_args) -o $(BUILDDIR)

$(BUILD_TARGETS): go.sum $(BUILDDIR)/
	go $@ -mod=readonly $(BUILD_FLAGS) $(BUILD_ARGS) ./...

$(BUILDDIR)/:
	mkdir -p $(BUILDDIR)/

build-docker:
	$(DOCKER) build --tag babylonchain/staking-indexer -f Dockerfile \
		$(shell git rev-parse --show-toplevel)

.PHONY: build build-docker

test:
	go test ./...
