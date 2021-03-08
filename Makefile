PREFIX := $(HOME)
MAKE_PATH := $(dir $(realpath $(firstword $(MAKEFILE_LIST))))
DOCKERHUB_USER ?= ctxsh
VERSION ?= 3.6.1

.PHONY: all
all: zookeeper

###################################################################################################
# Zookeeper build and release targets
###################################################################################################
.PHONY: zookeeper
zookeeper:
	@docker build \
					--tag $(DOCKERHUB_USER)/zookeeper:$(VERSION) \
					--file Dockerfile \
					.

.PHONY: release
release:
	@docker push $(DOCKERHUB_USER)/zookeeper:$(VERSION)

###################################################################################################
# Local testing targets
###################################################################################################
.PHONY: kind
kind:
	@$(MAKE_PATH)test/kind.sh
	@kubectl cluster-info --context kind-kind

.PHONY: test
test: zookeeper
	@docker tag $(DOCKERHUB_USER)/zookeeper:$(VERSION) localhost:5000/zookeeper:$(VERSION)
	@docker push localhost:5000/zookeeper:$(VERSION)
	@./test/run.sh

###################################################################################################
# Utility targets
###################################################################################################
.PHONY: clean
clean:
	@kind delete cluster
	@docker stop kind-registry 2>/dev/null || true
	@docker rm kind-registry 2>/dev/null || true
	@docker rm $(shell docker ps -qa) 2>/dev/null || true
	@docker rmi $(shell docker images -q $(DOCKERHUB_USER)/zookeeper) --force 2>/dev/null || true
