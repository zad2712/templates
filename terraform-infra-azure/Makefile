# Makefile for Terraform Azure Infrastructure
# Usage: make <target> ENV=<environment> LAYER=<layer>

# Default values
ENV ?= dev
LAYER ?= networking
SUBSCRIPTION_ID ?= 
LOCATION ?= "East US"

# Colors for output
RED := \033[31m
GREEN := \033[32m
YELLOW := \033[33m
BLUE := \033[34m
RESET := \033[0m

# Check if running on Windows
ifeq ($(OS),Windows_NT)
    SHELL := powershell.exe
    .SHELLFLAGS := -NoProfile -Command
    TERRAFORM_MANAGER := .\terraform-manager.ps1
else
    SHELL := /bin/bash
    TERRAFORM_MANAGER := ./terraform-manager.sh
endif

.DEFAULT_GOAL := help

.PHONY: help
help: ## Show this help message
	@echo "$(BLUE)Terraform Azure Infrastructure Management$(RESET)"
	@echo "$(YELLOW)Usage: make <target> ENV=<environment> LAYER=<layer>$(RESET)"
	@echo ""
	@echo "$(GREEN)Available targets:$(RESET)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(BLUE)%-20s$(RESET) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(GREEN)Parameters:$(RESET)"
	@echo "  ENV              Environment (dev, qa, uat, prod) [default: $(ENV)]"
	@echo "  LAYER            Infrastructure layer (networking, security, data, compute) [default: $(LAYER)]"
	@echo "  SUBSCRIPTION_ID  Azure subscription ID (optional)"
	@echo "  LOCATION         Azure location [default: $(LOCATION)]"
	@echo ""
	@echo "$(GREEN)Examples:$(RESET)"
	@echo "  make bootstrap ENV=dev"
	@echo "  make deploy ENV=prod LAYER=networking"
	@echo "  make plan ENV=dev LAYER=security"

.PHONY: check-env
check-env:
	@if [ -z "$(ENV)" ] || ! echo "dev qa uat prod" | grep -q "$(ENV)"; then \
		echo "$(RED)Error: Invalid environment. Must be one of: dev, qa, uat, prod$(RESET)"; \
		exit 1; \
	fi
	@if [ -z "$(LAYER)" ] || ! echo "networking security data compute" | grep -q "$(LAYER)"; then \
		echo "$(RED)Error: Invalid layer. Must be one of: networking, security, data, compute$(RESET)"; \
		exit 1; \
	fi
	@echo "$(GREEN)Environment: $(ENV), Layer: $(LAYER)$(RESET)"

.PHONY: bootstrap
bootstrap: check-env ## Create Terraform backend resources for an environment
	@echo "$(BLUE)Bootstrapping Terraform backend for $(ENV) environment...$(RESET)"
ifeq ($(OS),Windows_NT)
	$(TERRAFORM_MANAGER) -Action bootstrap -Environment $(ENV) $(if $(SUBSCRIPTION_ID),-SubscriptionId $(SUBSCRIPTION_ID)) -Location $(LOCATION)
else
	$(TERRAFORM_MANAGER) bootstrap $(ENV) $(SUBSCRIPTION_ID) $(LOCATION)
endif

.PHONY: init
init: check-env ## Initialize Terraform for a specific layer and environment
	@echo "$(BLUE)Initializing Terraform for $(LAYER) layer in $(ENV) environment...$(RESET)"
ifeq ($(OS),Windows_NT)
	$(TERRAFORM_MANAGER) -Action init -Environment $(ENV) -Layer $(LAYER) $(if $(SUBSCRIPTION_ID),-SubscriptionId $(SUBSCRIPTION_ID))
else
	$(TERRAFORM_MANAGER) init $(ENV) $(LAYER) $(SUBSCRIPTION_ID)
endif

.PHONY: plan
plan: check-env ## Generate Terraform execution plan
	@echo "$(BLUE)Planning Terraform changes for $(LAYER) layer in $(ENV) environment...$(RESET)"
ifeq ($(OS),Windows_NT)
	$(TERRAFORM_MANAGER) -Action plan -Environment $(ENV) -Layer $(LAYER) $(if $(SUBSCRIPTION_ID),-SubscriptionId $(SUBSCRIPTION_ID))
else
	$(TERRAFORM_MANAGER) plan $(ENV) $(LAYER) $(SUBSCRIPTION_ID)
endif

.PHONY: apply
apply: check-env ## Apply Terraform changes
	@echo "$(YELLOW)WARNING: This will apply changes to $(ENV) environment!$(RESET)"
	@read -p "Continue? (y/N): " confirm && [ "$$confirm" = "y" ] || [ "$$confirm" = "Y" ] || (echo "$(RED)Aborted$(RESET)" && exit 1)
ifeq ($(OS),Windows_NT)
	$(TERRAFORM_MANAGER) -Action apply -Environment $(ENV) -Layer $(LAYER) $(if $(SUBSCRIPTION_ID),-SubscriptionId $(SUBSCRIPTION_ID))
else
	$(TERRAFORM_MANAGER) apply $(ENV) $(LAYER) $(SUBSCRIPTION_ID)
endif

.PHONY: deploy
deploy: check-env ## Complete deployment (init + plan + apply)
	@echo "$(BLUE)Starting complete deployment for $(LAYER) layer in $(ENV) environment...$(RESET)"
ifeq ($(OS),Windows_NT)
	$(TERRAFORM_MANAGER) -Action deploy-all -Environment $(ENV) -Layer $(LAYER) $(if $(SUBSCRIPTION_ID),-SubscriptionId $(SUBSCRIPTION_ID))
else
	$(TERRAFORM_MANAGER) deploy-all $(ENV) $(LAYER) $(SUBSCRIPTION_ID)
endif

.PHONY: destroy
destroy: check-env ## Destroy Terraform resources (DANGEROUS!)
	@echo "$(RED)WARNING: This will DESTROY all resources in $(LAYER) layer for $(ENV) environment!$(RESET)"
	@read -p "Type 'yes' to confirm destruction: " confirm && [ "$$confirm" = "yes" ] || (echo "$(RED)Aborted$(RESET)" && exit 1)
ifeq ($(OS),Windows_NT)
	$(TERRAFORM_MANAGER) -Action destroy -Environment $(ENV) -Layer $(LAYER) $(if $(SUBSCRIPTION_ID),-SubscriptionId $(SUBSCRIPTION_ID))
else
	$(TERRAFORM_MANAGER) destroy $(ENV) $(LAYER) $(SUBSCRIPTION_ID)
endif

.PHONY: validate
validate: check-env ## Validate Terraform configuration
	@echo "$(BLUE)Validating Terraform configuration for $(LAYER) layer...$(RESET)"
ifeq ($(OS),Windows_NT)
	$(TERRAFORM_MANAGER) -Action validate -Environment $(ENV) -Layer $(LAYER)
else
	$(TERRAFORM_MANAGER) validate $(ENV) $(LAYER)
endif

.PHONY: format
format: ## Format all Terraform files
	@echo "$(BLUE)Formatting Terraform files...$(RESET)"
ifeq ($(OS),Windows_NT)
	$(TERRAFORM_MANAGER) -Action format
else
	$(TERRAFORM_MANAGER) format
endif

.PHONY: output
output: check-env ## Show Terraform outputs
	@echo "$(BLUE)Showing Terraform outputs for $(LAYER) layer in $(ENV) environment...$(RESET)"
ifeq ($(OS),Windows_NT)
	$(TERRAFORM_MANAGER) -Action output -Environment $(ENV) -Layer $(LAYER)
else
	$(TERRAFORM_MANAGER) output $(ENV) $(LAYER)
endif

.PHONY: clean
clean: ## Clean local Terraform state and cache
	@echo "$(BLUE)Cleaning local Terraform state and cache...$(RESET)"
ifeq ($(OS),Windows_NT)
	$(TERRAFORM_MANAGER) -Action clean
else
	$(TERRAFORM_MANAGER) clean
endif

.PHONY: deploy-all-layers
deploy-all-layers: check-env ## Deploy all layers in correct order
	@echo "$(BLUE)Deploying all layers for $(ENV) environment...$(RESET)"
	$(MAKE) deploy ENV=$(ENV) LAYER=networking
	$(MAKE) deploy ENV=$(ENV) LAYER=security
	$(MAKE) deploy ENV=$(ENV) LAYER=data
	$(MAKE) deploy ENV=$(ENV) LAYER=compute

.PHONY: plan-all-layers
plan-all-layers: check-env ## Plan all layers
	@echo "$(BLUE)Planning all layers for $(ENV) environment...$(RESET)"
	$(MAKE) plan ENV=$(ENV) LAYER=networking
	$(MAKE) plan ENV=$(ENV) LAYER=security
	$(MAKE) plan ENV=$(ENV) LAYER=data
	$(MAKE) plan ENV=$(ENV) LAYER=compute

.PHONY: status
status: ## Show current infrastructure status
	@echo "$(BLUE)Infrastructure Status$(RESET)"
	@echo "$(GREEN)Current Configuration:$(RESET)"
	@echo "  Environment: $(ENV)"
	@echo "  Layer: $(LAYER)"
	@echo "  Location: $(LOCATION)"
	@if [ -n "$(SUBSCRIPTION_ID)" ]; then echo "  Subscription: $(SUBSCRIPTION_ID)"; fi

.PHONY: docs
docs: ## Generate documentation
	@echo "$(BLUE)Generating documentation...$(RESET)"
	@find . -name "*.md" -exec echo "Found: {}" \;

.PHONY: check-prereqs
check-prereqs: ## Check prerequisites
	@echo "$(BLUE)Checking prerequisites...$(RESET)"
	@command -v az >/dev/null 2>&1 || { echo "$(RED)Azure CLI not found$(RESET)"; exit 1; }
	@command -v terraform >/dev/null 2>&1 || { echo "$(RED)Terraform not found$(RESET)"; exit 1; }
	@az account show >/dev/null 2>&1 || { echo "$(RED)Not logged into Azure CLI$(RESET)"; exit 1; }
	@echo "$(GREEN)All prerequisites met!$(RESET)"