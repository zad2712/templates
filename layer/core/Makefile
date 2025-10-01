#####################################################################################################
# Core Layer Makefile
# Simplified operations for the core networking layer
#####################################################################################################

# Default environment
ENV ?= dev
PROJECT_NAME ?= salesforce-app

# Colors
GREEN := \033[32m
YELLOW := \033[33m
BLUE := \033[34m
RED := \033[31m
RESET := \033[0m

.PHONY: help
help: ## Display help for core layer operations
	@echo "$(BLUE)Core Layer Operations$(RESET)"
	@echo "$(BLUE)====================$(RESET)"
	@echo ""
	@echo "Usage: make <target> [ENV=<environment>]"
	@echo ""
	@echo "Environments: dev (default), qa, uat, prod"
	@echo ""
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  $(GREEN)%-15s$(RESET) %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.PHONY: init
init: ## Initialize Terraform
	@echo "$(BLUE)Initializing Terraform for core layer$(RESET)"
	terraform init

.PHONY: plan
plan: ## Plan deployment for environment
	@echo "$(BLUE)Planning core layer deployment for $(ENV)$(RESET)"
	terraform workspace select $(ENV) || terraform workspace new $(ENV)
	terraform plan -var-file="environments/$(ENV)/$(ENV).tfvars"

.PHONY: apply
apply: ## Apply deployment for environment
	@echo "$(YELLOW)Applying core layer deployment for $(ENV)$(RESET)"
	terraform workspace select $(ENV) || terraform workspace new $(ENV)
	terraform apply -var-file="environments/$(ENV)/$(ENV).tfvars"

.PHONY: destroy
destroy: ## Destroy infrastructure for environment
	@echo "$(RED)Destroying core layer infrastructure for $(ENV)$(RESET)"
	terraform workspace select $(ENV)
	terraform destroy -var-file="environments/$(ENV)/$(ENV).tfvars"

.PHONY: output
output: ## Show outputs for environment
	@echo "$(BLUE)Showing core layer outputs for $(ENV)$(RESET)"
	terraform workspace select $(ENV)
	terraform output

.PHONY: validate
validate: ## Validate Terraform configuration
	@echo "$(BLUE)Validating core layer configuration$(RESET)"
	terraform validate

.PHONY: format
format: ## Format Terraform files
	@echo "$(BLUE)Formatting Terraform files$(RESET)"
	terraform fmt -recursive

.PHONY: clean
clean: ## Clean temporary files
	@echo "$(BLUE)Cleaning temporary files$(RESET)"
	rm -f *.tfplan terraform.tfstate.backup

.DEFAULT_GOAL := help