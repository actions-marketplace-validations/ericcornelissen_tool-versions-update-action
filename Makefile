SHELL_SCRIPTS:=./bin/*.sh

TMP_DIR:=./.tmp
ASDF:=$(TMP_DIR)/.asdf
DEV_IMG:=$(TMP_DIR)/.dev-img

DEV_ENV_NAME:=tool-versions-update-action-dev
DEV_IMG_NAME:=$(DEV_ENV_NAME)-img

################################################################################
### Commands ###################################################################
################################################################################

.PHONY: default
default: help

.PHONY: clean
clean: ## Clean the repository
	@git clean -fx \
		$(TMP_DIR)

.PHONY: dev-env dev-img
dev-env: dev-img ## Run an ephemeral development environment with Docker
	@docker run \
		-it \
		--rm \
		--workdir "/tool-versions-update-action" \
		--mount "type=bind,source=$(shell pwd),target=/tool-versions-update-action" \
		--name $(DEV_ENV_NAME) \
		$(DEV_IMG_NAME)

dev-img: $(DEV_IMG) ## Build a development environment image with Docker

.PHONY: format format-check
format: $(ASDF) ## Format the source code
	@shfmt --simplify --write $(SHELL_SCRIPTS)

format-check: $(ASDF) ## Check the source code formatting
	@shfmt --diff $(SHELL_SCRIPTS)

.PHONY: help
help: ## Show this help message
	@printf "Usage: make <command>\n\n"
	@printf "Commands:\n"
	@awk -F ':(.*)## ' '/^[a-zA-Z0-9%\\\/_.-]+:(.*)##/ { \
		printf "  \033[36m%-30s\033[0m %s\n", $$1, $$NF \
	}' $(MAKEFILE_LIST)

.PHONY: lint lint-ci lint-docker lint-sh lint-yml
lint: lint-ci lint-docker lint-sh lint-yml ## Run lint-*

lint-ci: $(ASDF) ## Lint CI workflow files
	@actionlint

lint-docker: $(ASDF) ## Lint the Dockerfile
	@hadolint Dockerfile

lint-sh: $(ASDF) ## Lint shell scripts
	@shellcheck $(SHELL_SCRIPTS)

lint-yml: $(ASDF) ## Lint YAML files
	@yamllint -c .yamllint.yml .

.PHONY: verify
verify: format-check lint ## Verify project is in a good state

################################################################################
### Targets ####################################################################
################################################################################

$(TMP_DIR):
	@mkdir $(TMP_DIR)

$(ASDF): .tool-versions | $(TMP_DIR)
	@asdf install
	@touch $(ASDF)

$(DEV_IMG): Dockerfile | $(TMP_DIR)
	@docker build --tag $(DEV_IMG_NAME) .
	@touch $(DEV_IMG)
