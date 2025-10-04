# Makefile for AWS Terraform Infrastructure
# Author: Diego A. Zarate
# Description: Common operations for managing AWS infrastructure with Terraform

.DEFAULT_GOAL := help

# Variables
SHELL := /bin/bash
TERRAFORM_VERSION := 1.9.0
AWS_REGION := us-east-1
PROJECT_NAME := terraform-infra-aws

# Colors for output
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[1;33m
BLUE := \033[0;34m
NC := \033[0m # No Color

# Available layers and environments
LAYERS := networking security data compute
ENVIRONMENTS := dev qa uat prod

# Help target
.PHONY: help
help: ## Show this help message
	@echo -e "$(BLUE)AWS Terraform Infrastructure Management$(NC)"
	@echo -e "$(BLUE)Author: Diego A. Zarate$(NC)"
	@echo ""
	@echo -e "$(YELLOW)Usage:$(NC)"
	@echo "  make <target> [LAYER=<layer>] [ENV=<environment>]"
	@echo ""
	@echo -e "$(YELLOW)Available targets:$(NC)"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  $(GREEN)%-20s$(NC) %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo ""
	@echo -e "$(YELLOW)Available layers:$(NC) $(LAYERS)"
	@echo -e "$(YELLOW)Available environments:$(NC) $(ENVIRONMENTS)"
	@echo ""
	@echo -e "$(YELLOW)Examples:$(NC)"
	@echo "  make init LAYER=networking ENV=dev"
	@echo "  make plan LAYER=security ENV=prod"
	@echo "  make apply LAYER=compute ENV=qa"
	@echo "  make init-all ENV=dev"
	@echo "  make format-all"

# Dependency checks
.PHONY: check-deps
check-deps: ## Check if required tools are installed
	@echo -e "$(BLUE)Checking dependencies...$(NC)"
	@command -v terraform >/dev/null 2>&1 || { echo -e "$(RED)Error: terraform is not installed$(NC)" >&2; exit 1; }
	@command -v aws >/dev/null 2>&1 || { echo -e "$(RED)Error: aws cli is not installed$(NC)" >&2; exit 1; }
	@command -v jq >/dev/null 2>&1 || { echo -e "$(RED)Error: jq is not installed$(NC)" >&2; exit 1; }
	@echo -e "$(GREEN)All dependencies are installed$(NC)"

# Version checks
.PHONY: check-versions
check-versions: check-deps ## Check versions of required tools
	@echo -e "$(BLUE)Tool versions:$(NC)"
	@echo "Terraform: $$(terraform version -json | jq -r '.terraform_version')"
	@echo "AWS CLI: $$(aws --version | head -n1)"
	@echo "jq: $$(jq --version)"

# Validation functions
define validate_layer
	@if [[ ! " $(LAYERS) " =~ " $(1) " ]]; then \
		echo -e "$(RED)Error: Invalid layer '$(1)'. Available: $(LAYERS)$(NC)"; \
		exit 1; \
	fi
endef

define validate_env
	@if [[ ! " $(ENVIRONMENTS) " =~ " $(1) " ]]; then \
		echo -e "$(RED)Error: Invalid environment '$(1)'. Available: $(ENVIRONMENTS)$(NC)"; \
		exit 1; \
	fi
endef

define validate_layer_env
	$(call validate_layer,$(LAYER))
	$(call validate_env,$(ENV))
	@if [[ ! -d "layers/$(LAYER)/environments/$(ENV)" ]]; then \
		echo -e "$(RED)Error: Directory layers/$(LAYER)/environments/$(ENV) does not exist$(NC)"; \
		exit 1; \
	fi
endef

# Terraform operations for specific layer and environment
.PHONY: init
init: check-deps ## Initialize Terraform for a specific layer and environment
	@$(call validate_layer_env)
	@echo -e "$(BLUE)Initializing $(LAYER) layer for $(ENV) environment...$(NC)"
	@cd layers/$(LAYER)/environments/$(ENV) && terraform init -backend-config=backend.conf

.PHONY: validate
validate: ## Validate Terraform configuration for a specific layer and environment
	@$(call validate_layer_env)
	@echo -e "$(BLUE)Validating $(LAYER) layer for $(ENV) environment...$(NC)"
	@cd layers/$(LAYER)/environments/$(ENV) && terraform validate

.PHONY: plan
plan: ## Create execution plan for a specific layer and environment
	@$(call validate_layer_env)
	@echo -e "$(BLUE)Planning $(LAYER) layer for $(ENV) environment...$(NC)"
	@cd layers/$(LAYER)/environments/$(ENV) && terraform plan

.PHONY: apply
apply: ## Apply Terraform changes for a specific layer and environment
	@$(call validate_layer_env)
	@echo -e "$(BLUE)Applying $(LAYER) layer for $(ENV) environment...$(NC)"
	@cd layers/$(LAYER)/environments/$(ENV) && terraform apply

.PHONY: destroy
destroy: ## Destroy Terraform-managed infrastructure for a specific layer and environment
	@$(call validate_layer_env)
	@echo -e "$(YELLOW)Warning: This will destroy resources in $(LAYER) layer for $(ENV) environment!$(NC)"
	@read -p "Are you sure? (yes/no): " confirm && [[ $$confirm == "yes" ]] || exit 1
	@cd layers/$(LAYER)/environments/$(ENV) && terraform destroy

.PHONY: output
output: ## Show output values for a specific layer and environment
	@$(call validate_layer_env)
	@echo -e "$(BLUE)Getting outputs for $(LAYER) layer in $(ENV) environment...$(NC)"
	@cd layers/$(LAYER)/environments/$(ENV) && terraform output

# Operations for all layers in an environment
.PHONY: init-all
init-all: check-deps ## Initialize all layers for an environment
	$(call validate_env,$(ENV))
	@echo -e "$(BLUE)Initializing all layers for $(ENV) environment...$(NC)"
	@for layer in $(LAYERS); do \
		echo -e "$(BLUE)Initializing $$layer layer...$(NC)"; \
		cd layers/$$layer/environments/$(ENV) && terraform init -backend-config=backend.conf; \
		cd - > /dev/null; \
	done

.PHONY: plan-all
plan-all: ## Plan all layers for an environment
	$(call validate_env,$(ENV))
	@echo -e "$(BLUE)Planning all layers for $(ENV) environment...$(NC)"
	@for layer in $(LAYERS); do \
		echo -e "$(BLUE)Planning $$layer layer...$(NC)"; \
		cd layers/$$layer/environments/$(ENV) && terraform plan; \
		cd - > /dev/null; \
	done

.PHONY: apply-all
apply-all: ## Apply all layers for an environment (in dependency order)
	$(call validate_env,$(ENV))
	@echo -e "$(YELLOW)Warning: This will apply changes to ALL layers in $(ENV) environment!$(NC)"
	@read -p "Are you sure? (yes/no): " confirm && [[ $$confirm == "yes" ]] || exit 1
	@echo -e "$(BLUE)Applying all layers for $(ENV) environment (in dependency order)...$(NC)"
	@for layer in $(LAYERS); do \
		echo -e "$(BLUE)Applying $$layer layer...$(NC)"; \
		cd layers/$$layer/environments/$(ENV) && terraform apply -auto-approve; \
		cd - > /dev/null; \
	done

.PHONY: validate-all
validate-all: ## Validate all layers for an environment
	$(call validate_env,$(ENV))
	@echo -e "$(BLUE)Validating all layers for $(ENV) environment...$(NC)"
	@for layer in $(LAYERS); do \
		echo -e "$(BLUE)Validating $$layer layer...$(NC)"; \
		cd layers/$$layer/environments/$(ENV) && terraform validate; \
		cd - > /dev/null; \
	done

.PHONY: output-all
output-all: ## Show outputs for all layers in an environment
	$(call validate_env,$(ENV))
	@echo -e "$(BLUE)Getting outputs for all layers in $(ENV) environment...$(NC)"
	@for layer in $(LAYERS); do \
		echo -e "$(BLUE)Outputs for $$layer layer:$(NC)"; \
		cd layers/$$layer/environments/$(ENV) && terraform output; \
		cd - > /dev/null; \
		echo ""; \
	done

# Code quality and formatting
.PHONY: format
format: ## Format Terraform files for a specific layer
	$(call validate_layer,$(LAYER))
	@echo -e "$(BLUE)Formatting $(LAYER) layer...$(NC)"
	@cd layers/$(LAYER) && terraform fmt -recursive

.PHONY: format-all
format-all: ## Format all Terraform files
	@echo -e "$(BLUE)Formatting all Terraform files...$(NC)"
	@terraform fmt -recursive

.PHONY: lint
lint: ## Lint Terraform configuration for a specific layer and environment
	@$(call validate_layer_env)
	@echo -e "$(BLUE)Linting $(LAYER) layer for $(ENV) environment...$(NC)"
	@cd layers/$(LAYER)/environments/$(ENV) && terraform fmt -check=true -diff=true
	@cd layers/$(LAYER)/environments/$(ENV) && terraform validate

.PHONY: lint-all
lint-all: ## Lint all Terraform configurations
	@echo -e "$(BLUE)Linting all Terraform configurations...$(NC)"
	@for layer in $(LAYERS); do \
		for env in $(ENVIRONMENTS); do \
			if [[ -d "layers/$$layer/environments/$$env" ]]; then \
				echo -e "$(BLUE)Linting $$layer layer for $$env environment...$(NC)"; \
				cd layers/$$layer/environments/$$env && terraform fmt -check=true -diff=true && terraform validate; \
				cd - > /dev/null; \
			fi \
		done \
	done

# Cleanup operations
.PHONY: clean
clean: ## Clean temporary files for a specific layer and environment
	@$(call validate_layer_env)
	@echo -e "$(BLUE)Cleaning $(LAYER) layer for $(ENV) environment...$(NC)"
	@cd layers/$(LAYER)/environments/$(ENV) && rm -rf .terraform .terraform.lock.hcl terraform.tfplan

.PHONY: clean-all
clean-all: ## Clean all temporary files
	@echo -e "$(BLUE)Cleaning all temporary files...$(NC)"
	@find . -name ".terraform" -type d -exec rm -rf {} + 2>/dev/null || true
	@find . -name ".terraform.lock.hcl" -type f -delete 2>/dev/null || true
	@find . -name "terraform.tfplan" -type f -delete 2>/dev/null || true

# Documentation
.PHONY: docs
docs: ## Generate documentation
	@echo -e "$(BLUE)Generating documentation...$(NC)"
	@echo "Documentation generation not implemented yet"

# Security scanning
.PHONY: security-scan
security-scan: ## Run security scanning on Terraform configurations
	@echo -e "$(BLUE)Running security scan...$(NC)"
	@if command -v tfsec >/dev/null 2>&1; then \
		tfsec .; \
	else \
		echo -e "$(YELLOW)tfsec not installed. Install with: go install github.com/aquasecurity/tfsec/cmd/tfsec@latest$(NC)"; \
	fi

# Cost estimation
.PHONY: cost-estimate
cost-estimate: ## Estimate costs using infracost (if available)
	@$(call validate_layer_env)
	@echo -e "$(BLUE)Estimating costs for $(LAYER) layer in $(ENV) environment...$(NC)"
	@if command -v infracost >/dev/null 2>&1; then \
		cd layers/$(LAYER)/environments/$(ENV) && infracost breakdown --path .; \
	else \
		echo -e "$(YELLOW)infracost not installed. Visit: https://www.infracost.io/docs/$(NC)"; \
	fi

# Graph generation
.PHONY: graph
graph: ## Generate Terraform dependency graph
	@$(call validate_layer_env)
	@echo -e "$(BLUE)Generating dependency graph for $(LAYER) layer in $(ENV) environment...$(NC)"
	@cd layers/$(LAYER)/environments/$(ENV) && terraform graph | dot -Tpng > terraform-graph.png
	@echo -e "$(GREEN)Graph saved as terraform-graph.png$(NC)"

# State operations
.PHONY: state-list
state-list: ## List resources in Terraform state
	@$(call validate_layer_env)
	@echo -e "$(BLUE)Listing resources in $(LAYER) layer for $(ENV) environment...$(NC)"
	@cd layers/$(LAYER)/environments/$(ENV) && terraform state list

.PHONY: state-show
state-show: ## Show detailed resource information (requires RESOURCE variable)
	@$(call validate_layer_env)
	@if [[ -z "$(RESOURCE)" ]]; then \
		echo -e "$(RED)Error: RESOURCE variable is required$(NC)"; \
		echo "Usage: make state-show LAYER=<layer> ENV=<env> RESOURCE=<resource_name>"; \
		exit 1; \
	fi
	@echo -e "$(BLUE)Showing resource $(RESOURCE) in $(LAYER) layer for $(ENV) environment...$(NC)"
	@cd layers/$(LAYER)/environments/$(ENV) && terraform state show $(RESOURCE)

# Import operations
.PHONY: import
import: ## Import existing resource (requires RESOURCE and RESOURCE_ID variables)
	@$(call validate_layer_env)
	@if [[ -z "$(RESOURCE)" ]] || [[ -z "$(RESOURCE_ID)" ]]; then \
		echo -e "$(RED)Error: RESOURCE and RESOURCE_ID variables are required$(NC)"; \
		echo "Usage: make import LAYER=<layer> ENV=<env> RESOURCE=<resource_name> RESOURCE_ID=<aws_resource_id>"; \
		exit 1; \
	fi
	@echo -e "$(BLUE)Importing resource $(RESOURCE) with ID $(RESOURCE_ID)...$(NC)"
	@cd layers/$(LAYER)/environments/$(ENV) && terraform import $(RESOURCE) $(RESOURCE_ID)

# Workspace operations
.PHONY: workspace-list
workspace-list: ## List Terraform workspaces
	@$(call validate_layer_env)
	@echo -e "$(BLUE)Listing workspaces for $(LAYER) layer in $(ENV) environment...$(NC)"
	@cd layers/$(LAYER)/environments/$(ENV) && terraform workspace list

.PHONY: workspace-show
workspace-show: ## Show current workspace
	@$(call validate_layer_env)
	@echo -e "$(BLUE)Current workspace for $(LAYER) layer in $(ENV) environment:$(NC)"
	@cd layers/$(LAYER)/environments/$(ENV) && terraform workspace show

# All-in-one operations
.PHONY: deploy
deploy: init-all plan-all apply-all ## Deploy entire infrastructure for an environment
	@echo -e "$(GREEN)Deployment completed for $(ENV) environment!$(NC)"

.PHONY: setup-env
setup-env: check-versions init-all validate-all ## Setup and validate an environment
	@echo -e "$(GREEN)Environment $(ENV) setup completed!$(NC)"

# Development helpers
.PHONY: dev-setup
dev-setup: ## Quick setup for development environment
	@$(MAKE) setup-env ENV=dev

.PHONY: dev-deploy
dev-deploy: ## Quick deploy for development environment
	@$(MAKE) deploy ENV=dev

.PHONY: dev-destroy
dev-destroy: ## Quick destroy for development environment
	@echo -e "$(YELLOW)Warning: This will destroy the entire dev environment!$(NC)"
	@read -p "Are you sure? (yes/no): " confirm && [[ $$confirm == "yes" ]] || exit 1
	@for layer in $(shell echo $(LAYERS) | tr ' ' '\n' | tac); do \
		echo -e "$(BLUE)Destroying $$layer layer...$(NC)"; \
		cd layers/$$layer/environments/dev && terraform destroy -auto-approve; \
		cd - > /dev/null; \
	done

# CI/CD helpers
.PHONY: ci-validate
ci-validate: format-all lint-all security-scan ## Run all validation checks for CI/CD
	@echo -e "$(GREEN)All validation checks passed!$(NC)"

.PHONY: ci-plan
ci-plan: ## Plan for CI/CD (requires ENV variable)
	$(call validate_env,$(ENV))
	@$(MAKE) init-all ENV=$(ENV)
	@$(MAKE) plan-all ENV=$(ENV)

# Information targets
.PHONY: info
info: ## Show project information
	@echo -e "$(BLUE)AWS Terraform Infrastructure Project$(NC)"
	@echo -e "$(BLUE)Author: Diego A. Zarate$(NC)"
	@echo ""
	@echo "Project: $(PROJECT_NAME)"
	@echo "Layers: $(LAYERS)"
	@echo "Environments: $(ENVIRONMENTS)"
	@echo "Default AWS Region: $(AWS_REGION)"
	@echo "Required Terraform Version: $(TERRAFORM_VERSION)"

.PHONY: status
status: ## Show status of all environments
	@echo -e "$(BLUE)Infrastructure Status$(NC)"
	@echo ""
	@for env in $(ENVIRONMENTS); do \
		echo -e "$(YELLOW)Environment: $$env$(NC)"; \
		for layer in $(LAYERS); do \
			if [[ -d "layers/$$layer/environments/$$env" ]]; then \
				echo -n "  $$layer: "; \
				if [[ -f "layers/$$layer/environments/$$env/.terraform/terraform.tfstate" ]]; then \
					echo -e "$(GREEN)initialized$(NC)"; \
				else \
					echo -e "$(RED)not initialized$(NC)"; \
				fi \
			fi \
		done \
		echo ""; \
	done