MAKEFLAGS += --warn-undefined-variables
SHELL := bash
.SHELLFLAGS := -eu -o pipefail -c
.DEFAULT_GOAL := all
.DELETE_ON_ERROR:
.SUFFIXES:

# include makefiles
export SELF ?= $(MAKE)
PROJECT_PATH ?= $(shell pwd)
include $(PROJECT_PATH)/Makefile.*

# main
export UNAME_S ?= $(shell uname -s)

# Skip the AWS_PROFILE default when aws-vault has provided credential env vars.
ifndef AWS_ACCESS_KEY_ID
export AWS_PROFILE ?= unknown
endif
export AWS_DEFAULT_REGION ?= us-west-2
export REPO_NAME := $(shell basename ${PWD})

DOCKER_IMAGE ?= hansohn/terraform-aws
DOCKER_TAG   ?= latest
DOCKER_PULL  ?= always

DOCKER_ARGS ?=
DOCKER_ARGS += --interactive
DOCKER_ARGS += --tty
DOCKER_ARGS += --rm
DOCKER_ARGS += --env AWS_PROFILE --env AWS_DEFAULT_REGION
DOCKER_ARGS += --env REPO_NAME
# Credential env vars (set by aws-vault). Forwarded only when present; when they
# are absent the container falls back to AWS_PROFILE + the mounted ~/.aws, so
# `make dev` works with or without aws-vault.
DOCKER_ARGS += --env AWS_ACCESS_KEY_ID --env AWS_SECRET_ACCESS_KEY
DOCKER_ARGS += --env AWS_SESSION_TOKEN --env AWS_REGION
DOCKER_ARGS += --workdir /app
DOCKER_ARGS += --volume ${PWD}:/app
DOCKER_ARGS += --volume ${HOME}/.aws:/root/.aws
# Persist the provider cache (image's .terraformrc plugin_cache_dir) across runs.
DOCKER_ARGS += --volume ${HOME}/.terraform.d/plugin-cache:/opt/terraform/plugin-cache
DOCKER_ARGS += --volume ${HOME}/.ssh/known_hosts:/root/.ssh/known_hosts
DOCKER_ARGS += --volume ${HOME}/.gitconfig:/root/.gitconfig:ro
DOCKER_ARGS += --pull $(DOCKER_PULL)

SSH_AUTH_SOCK_MAGIC_PATH := /run/host-services/ssh-auth.sock
ifeq ($(UNAME_S),Darwin)
DOCKER_ARGS += --env SSH_AUTH_SOCK=$(SSH_AUTH_SOCK_MAGIC_PATH)
DOCKER_ARGS += --volume $(SSH_AUTH_SOCK_MAGIC_PATH):$(SSH_AUTH_SOCK_MAGIC_PATH)
endif

#-------------------------------------------------------------------------------
# lint
#-------------------------------------------------------------------------------

## Lint YAML files
lint/yaml:
	@command -v yamllint > /dev/null 2>&1 || (echo "[ERROR] yamllint is not installed." && exit 1)
	@echo "[INFO] Linting YAML files in '$(REPO_NAME)'."
	@yamllint --strict .
.PHONY: lint/yaml

## Lint and audit GitHub Actions workflows
lint/actions:
	@command -v actionlint > /dev/null 2>&1 || (echo "[ERROR] actionlint is not installed." && exit 1)
	@command -v zizmor > /dev/null 2>&1 || (echo "[ERROR] zizmor is not installed." && exit 1)
	@echo "[INFO] Linting GitHub Actions workflows in '$(REPO_NAME)'."
	@actionlint
	@echo "[INFO] Auditing GitHub Actions workflows in '$(REPO_NAME)'."
	@zizmor .
.PHONY: lint/actions

## Run all linters
lint: lint/yaml lint/actions
.PHONY: lint

#-------------------------------------------------------------------------------
# test
#-------------------------------------------------------------------------------

## Run tests
test:
	@echo "[INFO] No tests defined."
.PHONY: test

## Run all linters and tests
all: lint test
.PHONY: all

#-------------------------------------------------------------------------------
# dev
#-------------------------------------------------------------------------------

## Run local dev env
dev: ENTRYPOINT ?= bash

dev:
	docker run \
		$(DOCKER_ARGS) \
		$(DOCKER_IMAGE):$(DOCKER_TAG) \
		$(ENTRYPOINT)

.PHONY: dev

#-------------------------------------------------------------------------------
# clean
#-------------------------------------------------------------------------------

CLEAN_DIRS  += .terraform .terragrunt-cache
CLEAN_FILES += 'auto-*.tf' terraform.plan
$(CLEAN_DIRS):
	find . -type d -name $@ -prune -exec rm -rf {} \;
$(CLEAN_FILES):
	find . -type f -name $@ -exec rm -f {} \;

## Clean everything
clean: $(CLEAN_DIRS) $(CLEAN_FILES)
.PHONY: clean $(CLEAN_DIRS) $(CLEAN_FILES)
