#####################################################################################################
# Makefile for Salesforce Application Infrastructure
# Simplifies Terraform operations across all layers and environments
#####################################################################################################

# Default values
ENV ?= dev
LAYER ?= core
REGION ?= us-east-1
PROJECT_NAME ?= salesforce-app

# Colors for output
RED := \033[31m
GREEN := \033[32m
YELLOW := \033[33m
BLUE := \033[34m
MAGENTA := \033[35m
CYAN := \033[36m
WHITE := \033[37m
RESET := \033[0m

# Directories
LAYERS_DIR := layer
MODULES_DIR := modules
CORE_DIR := $(LAYERS_DIR)/core
BACKEND_DIR := $(LAYERS_DIR)/backend
FRONTEND_DIR := $(LAYERS_DIR)/frontend
DATA_DIR := $(LAYERS_DIR)/data
CONFIG_DIR := $(LAYERS_DIR)/config

#####################################################################################################
# Help and Information
#####################################################################################################

.PHONY: help
help: ## Display this help message
	@echo "$(CYAN)Salesforce Application Infrastructure Management$(RESET)"
	@echo "$(CYAN)=============================================$(RESET)"
	@echo ""
	@echo "$(GREEN)Usage:$(RESET)"
	@echo "  make <target> [ENV=<environment>] [LAYER=<layer>]"
	@echo ""
	@echo "$(GREEN)Available Environments:$(RESET)"
	@echo "  $(YELLOW)dev$(RESET)  - Development environment (default)"
	@echo "  $(YELLOW)qa$(RESET)   - Quality Assurance environment"
	@echo "  $(YELLOW)uat$(RESET)  - User Acceptance Testing environment"
	@echo "  $(YELLOW)prod$(RESET) - Production environment"
	@echo ""
	@echo "$(GREEN)Available Layers:$(RESET)"
	@echo "  $(YELLOW)core$(RESET)     - VPC and networking infrastructure (default)"
	@echo "  $(YELLOW)data$(RESET)     - Databases and data storage"
	@echo "  $(YELLOW)backend$(RESET)  - Application services and APIs"
	@echo "  $(YELLOW)frontend$(RESET) - Web applications and CDN"
	@echo "  $(YELLOW)config$(RESET)   - Configuration and secrets"
	@echo ""
	@echo "$(GREEN)Common Targets:$(RESET)"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  $(CYAN)%-15s$(RESET) %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo ""
	@echo "$(GREEN)Examples:$(RESET)"
	@echo "  make plan ENV=dev LAYER=core"
	@echo "  make apply ENV=prod LAYER=core"
	@echo "  make destroy ENV=dev"
	@echo "  make deploy-all ENV=prod"

.PHONY: version
version: ## Display version information
	@echo "$(CYAN)Version Information$(RESET)"
	@echo "$(CYAN)==================$(RESET)"
	@terraform version
	@aws --version
	@echo "Project: $(PROJECT_NAME)"
	@echo "Default Environment: $(ENV)"
	@echo "Default Layer: $(LAYER)"
	@echo "Default Region: $(REGION)"

#####################################################################################################
# Environment Validation
#####################################################################################################

.PHONY: validate-env
validate-env:
	@if [ "$(ENV)" != "dev" ] && [ "$(ENV)" != "qa" ] && [ "$(ENV)" != "uat" ] && [ "$(ENV)" != "prod" ]; then \
		echo "$(RED)Error: Invalid environment '$(ENV)'. Must be one of: dev, qa, uat, prod$(RESET)"; \
		exit 1; \
	fi

.PHONY: validate-layer
validate-layer:
	@if [ "$(LAYER)" != "core" ] && [ "$(LAYER)" != "data" ] && [ "$(LAYER)" != "backend" ] && [ "$(LAYER)" != "frontend" ] && [ "$(LAYER)" != "config" ]; then \
		echo "$(RED)Error: Invalid layer '$(LAYER)'. Must be one of: core, data, backend, frontend, config$(RESET)"; \
		exit 1; \
	fi

.PHONY: validate-layer-exists
validate-layer-exists: validate-layer
	@if [ ! -d "$(LAYERS_DIR)/$(LAYER)" ]; then \
		echo "$(RED)Error: Layer directory '$(LAYERS_DIR)/$(LAYER)' does not exist$(RESET)"; \
		exit 1; \
	fi

.PHONY: validate-tfvars
validate-tfvars: validate-env validate-layer-exists
	@if [ ! -f "$(LAYERS_DIR)/$(LAYER)/environments/$(ENV)/$(ENV).tfvars" ]; then \
		echo "$(RED)Error: Environment file '$(LAYERS_DIR)/$(LAYER)/environments/$(ENV)/$(ENV).tfvars' does not exist$(RESET)"; \
		exit 1; \
	fi

#####################################################################################################
# AWS and Terraform Setup
#####################################################################################################

.PHONY: check-aws
check-aws: ## Check AWS CLI configuration
	@echo "$(BLUE)Checking AWS Configuration...$(RESET)"
	@aws sts get-caller-identity
	@echo "$(GREEN)AWS CLI is configured correctly$(RESET)"

.PHONY: check-terraform
check-terraform: ## Check Terraform installation
	@echo "$(BLUE)Checking Terraform Installation...$(RESET)"
	@terraform version
	@echo "$(GREEN)Terraform is installed correctly$(RESET)"

.PHONY: check-prereqs
check-prereqs: check-aws check-terraform ## Check all prerequisites
	@echo "$(GREEN)All prerequisites are satisfied$(RESET)"

#####################################################################################################
# Workspace Management
#####################################################################################################

.PHONY: workspace-list
workspace-list: validate-layer-exists ## List Terraform workspaces for a layer
	@echo "$(BLUE)Listing workspaces for layer: $(LAYER)$(RESET)"
	@cd $(LAYERS_DIR)/$(LAYER) && terraform workspace list

.PHONY: workspace-select
workspace-select: validate-env validate-layer-exists ## Select or create Terraform workspace
	@echo "$(BLUE)Selecting workspace '$(ENV)' for layer '$(LAYER)'$(RESET)"
	@cd $(LAYERS_DIR)/$(LAYER) && (terraform workspace select $(ENV) || terraform workspace new $(ENV))
	@echo "$(GREEN)Workspace '$(ENV)' is now active$(RESET)"

.PHONY: workspace-show
workspace-show: validate-layer-exists ## Show current Terraform workspace
	@echo "$(BLUE)Current workspace for layer: $(LAYER)$(RESET)"
	@cd $(LAYERS_DIR)/$(LAYER) && terraform workspace show

#####################################################################################################
# Core Terraform Operations
#####################################################################################################

.PHONY: init
init: validate-layer-exists ## Initialize Terraform for a layer
	@echo "$(BLUE)Initializing Terraform for layer: $(LAYER)$(RESET)"
	@cd $(LAYERS_DIR)/$(LAYER) && terraform init
	@echo "$(GREEN)Terraform initialized successfully$(RESET)"

.PHONY: validate
validate: validate-layer-exists ## Validate Terraform configuration for a layer
	@echo "$(BLUE)Validating Terraform configuration for layer: $(LAYER)$(RESET)"
	@cd $(LAYERS_DIR)/$(LAYER) && terraform validate
	@echo "$(GREEN)Terraform configuration is valid$(RESET)"

.PHONY: format
format: validate-layer-exists ## Format Terraform files for a layer
	@echo "$(BLUE)Formatting Terraform files for layer: $(LAYER)$(RESET)"
	@cd $(LAYERS_DIR)/$(LAYER) && terraform fmt -recursive
	@echo "$(GREEN)Terraform files formatted successfully$(RESET)"

.PHONY: plan
plan: validate-tfvars workspace-select ## Plan Terraform deployment for an environment and layer
	@echo "$(BLUE)Planning deployment for $(ENV)/$(LAYER)$(RESET)"
	@cd $(LAYERS_DIR)/$(LAYER) && terraform plan -var-file="environments/$(ENV)/$(ENV).tfvars" -out="$(ENV).tfplan"
	@echo "$(GREEN)Plan completed successfully$(RESET)"

.PHONY: apply
apply: validate-tfvars workspace-select ## Apply Terraform deployment for an environment and layer
	@echo "$(YELLOW)Applying deployment for $(ENV)/$(LAYER)$(RESET)"
	@echo "$(YELLOW)This will make changes to your AWS infrastructure!$(RESET)"
	@read -p "Are you sure you want to continue? [y/N] " -n 1 -r; \
	echo ""; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		cd $(LAYERS_DIR)/$(LAYER) && terraform apply -var-file="environments/$(ENV)/$(ENV).tfvars" -auto-approve; \
		echo "$(GREEN)Deployment completed successfully$(RESET)"; \
	else \
		echo "$(YELLOW)Deployment cancelled$(RESET)"; \
	fi

.PHONY: apply-plan
apply-plan: validate-env validate-layer-exists ## Apply existing Terraform plan
	@echo "$(YELLOW)Applying existing plan for $(ENV)/$(LAYER)$(RESET)"
	@if [ -f "$(LAYERS_DIR)/$(LAYER)/$(ENV).tfplan" ]; then \
		cd $(LAYERS_DIR)/$(LAYER) && terraform apply "$(ENV).tfplan"; \
		echo "$(GREEN)Plan applied successfully$(RESET)"; \
	else \
		echo "$(RED)Error: Plan file '$(ENV).tfplan' not found. Run 'make plan' first$(RESET)"; \
		exit 1; \
	fi

.PHONY: destroy
destroy: validate-tfvars workspace-select ## Destroy Terraform infrastructure for an environment and layer
	@echo "$(RED)Destroying infrastructure for $(ENV)/$(LAYER)$(RESET)"
	@echo "$(RED)This will PERMANENTLY DELETE your AWS resources!$(RESET)"
	@read -p "Are you absolutely sure you want to continue? Type 'yes' to confirm: " -r; \
	if [ "$$REPLY" = "yes" ]; then \
		cd $(LAYERS_DIR)/$(LAYER) && terraform destroy -var-file="environments/$(ENV)/$(ENV).tfvars" -auto-approve; \
		echo "$(GREEN)Infrastructure destroyed successfully$(RESET)"; \
	else \
		echo "$(YELLOW)Destruction cancelled$(RESET)"; \
	fi

.PHONY: output
output: validate-env validate-layer-exists workspace-select ## Show Terraform outputs for an environment and layer
	@echo "$(BLUE)Showing outputs for $(ENV)/$(LAYER)$(RESET)"
	@cd $(LAYERS_DIR)/$(LAYER) && terraform output

.PHONY: state-list
state-list: validate-env validate-layer-exists workspace-select ## List Terraform state resources
	@echo "$(BLUE)Listing state resources for $(ENV)/$(LAYER)$(RESET)"
	@cd $(LAYERS_DIR)/$(LAYER) && terraform state list

.PHONY: refresh
refresh: validate-tfvars workspace-select ## Refresh Terraform state
	@echo "$(BLUE)Refreshing Terraform state for $(ENV)/$(LAYER)$(RESET)"
	@cd $(LAYERS_DIR)/$(LAYER) && terraform refresh -var-file="environments/$(ENV)/$(ENV).tfvars"

#####################################################################################################
# Multi-Layer Operations
#####################################################################################################

.PHONY: init-all
init-all: ## Initialize all layers
	@echo "$(BLUE)Initializing all layers$(RESET)"
	@for layer in core data backend frontend config; do \
		if [ -d "$(LAYERS_DIR)/$$layer" ]; then \
			echo "$(CYAN)Initializing $$layer layer$(RESET)"; \
			cd $(LAYERS_DIR)/$$layer && terraform init; \
		fi; \
	done
	@echo "$(GREEN)All layers initialized$(RESET)"

.PHONY: validate-all
validate-all: ## Validate all layers
	@echo "$(BLUE)Validating all layers$(RESET)"
	@for layer in core data backend frontend config; do \
		if [ -d "$(LAYERS_DIR)/$$layer" ]; then \
			echo "$(CYAN)Validating $$layer layer$(RESET)"; \
			cd $(LAYERS_DIR)/$$layer && terraform validate; \
		fi; \
	done
	@echo "$(GREEN)All layers validated$(RESET)"

.PHONY: format-all
format-all: ## Format all Terraform files
	@echo "$(BLUE)Formatting all Terraform files$(RESET)"
	@terraform fmt -recursive .
	@echo "$(GREEN)All files formatted$(RESET)"

.PHONY: plan-all
plan-all: validate-env ## Plan deployment for all layers in an environment
	@echo "$(BLUE)Planning deployment for all layers in environment: $(ENV)$(RESET)"
	@for layer in core data backend frontend config; do \
		if [ -d "$(LAYERS_DIR)/$$layer" ] && [ -f "$(LAYERS_DIR)/$$layer/environments/$(ENV)/$(ENV).tfvars" ]; then \
			echo "$(CYAN)Planning $$layer layer$(RESET)"; \
			$(MAKE) plan ENV=$(ENV) LAYER=$$layer; \
		fi; \
	done
	@echo "$(GREEN)All layers planned$(RESET)"

.PHONY: deploy-all
deploy-all: validate-env ## Deploy all layers in correct order for an environment
	@echo "$(BLUE)Deploying all layers for environment: $(ENV)$(RESET)"
	@echo "$(YELLOW)This will deploy in the correct dependency order: core -> data -> backend -> frontend -> config$(RESET)"
	@read -p "Are you sure you want to continue? [y/N] " -n 1 -r; \
	echo ""; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		for layer in core data backend frontend config; do \
			if [ -d "$(LAYERS_DIR)/$$layer" ] && [ -f "$(LAYERS_DIR)/$$layer/environments/$(ENV)/$(ENV).tfvars" ]; then \
				echo "$(CYAN)Deploying $$layer layer$(RESET)"; \
				$(MAKE) apply ENV=$(ENV) LAYER=$$layer; \
			fi; \
		done; \
		echo "$(GREEN)All layers deployed successfully$(RESET)"; \
	else \
		echo "$(YELLOW)Deployment cancelled$(RESET)"; \
	fi

.PHONY: destroy-all
destroy-all: validate-env ## Destroy all layers in reverse order for an environment
	@echo "$(RED)Destroying all layers for environment: $(ENV)$(RESET)"
	@echo "$(RED)This will PERMANENTLY DELETE ALL resources in the correct dependency order!$(RESET)"
	@read -p "Type 'destroy-everything' to confirm: " -r; \
	if [ "$$REPLY" = "destroy-everything" ]; then \
		for layer in config frontend backend data core; do \
			if [ -d "$(LAYERS_DIR)/$$layer" ] && [ -f "$(LAYERS_DIR)/$$layer/environments/$(ENV)/$(ENV).tfvars" ]; then \
				echo "$(RED)Destroying $$layer layer$(RESET)"; \
				$(MAKE) destroy ENV=$(ENV) LAYER=$$layer; \
			fi; \
		done; \
		echo "$(GREEN)All layers destroyed$(RESET)"; \
	else \
		echo "$(YELLOW)Destruction cancelled$(RESET)"; \
	fi

#####################################################################################################
# Development and Testing
#####################################################################################################

.PHONY: dev-setup
dev-setup: ## Quick setup for development environment
	@echo "$(BLUE)Setting up development environment$(RESET)"
	$(MAKE) check-prereqs
	$(MAKE) init ENV=dev LAYER=core
	$(MAKE) plan ENV=dev LAYER=core
	@echo "$(GREEN)Development environment ready. Run 'make apply ENV=dev LAYER=core' to deploy$(RESET)"

.PHONY: dev-deploy
dev-deploy: ## Deploy development environment (core layer only)
	@echo "$(BLUE)Deploying development environment$(RESET)"
	$(MAKE) apply ENV=dev LAYER=core

.PHONY: dev-destroy
dev-destroy: ## Destroy development environment
	@echo "$(RED)Destroying development environment$(RESET)"
	$(MAKE) destroy ENV=dev LAYER=core

.PHONY: test-module
test-module: ## Test VPC module with basic example
	@echo "$(BLUE)Testing VPC module$(RESET)"
	@cd $(MODULES_DIR)/vpc/examples && terraform init && terraform validate
	@echo "$(GREEN)VPC module test completed$(RESET)"

#####################################################################################################
# Utilities and Maintenance
#####################################################################################################

.PHONY: clean
clean: ## Clean temporary files and plans
	@echo "$(BLUE)Cleaning temporary files$(RESET)"
	@find . -name "*.tfplan" -delete
	@find . -name ".terraform.lock.hcl" -delete
	@find . -name "terraform.tfstate.backup" -delete
	@echo "$(GREEN)Cleanup completed$(RESET)"

.PHONY: clean-all
clean-all: clean ## Clean all Terraform files including .terraform directories
	@echo "$(YELLOW)Cleaning all Terraform files including state$(RESET)"
	@find . -name ".terraform" -type d -exec rm -rf {} + 2>/dev/null || true
	@echo "$(GREEN)Full cleanup completed$(RESET)"

.PHONY: docs
docs: ## Generate documentation for all modules
	@echo "$(BLUE)Generating documentation$(RESET)"
	@if command -v terraform-docs >/dev/null 2>&1; then \
		terraform-docs markdown table --output-file README.md $(MODULES_DIR)/vpc/; \
		echo "$(GREEN)Documentation updated$(RESET)"; \
	else \
		echo "$(YELLOW)terraform-docs not found. Install it to generate documentation$(RESET)"; \
	fi

.PHONY: security-scan
security-scan: ## Run security scan on Terraform code
	@echo "$(BLUE)Running security scan$(RESET)"
	@if command -v tfsec >/dev/null 2>&1; then \
		tfsec .; \
		echo "$(GREEN)Security scan completed$(RESET)"; \
	else \
		echo "$(YELLOW)tfsec not found. Install it to run security scans$(RESET)"; \
	fi

.PHONY: lint
lint: ## Lint Terraform code
	@echo "$(BLUE)Linting Terraform code$(RESET)"
	@if command -v tflint >/dev/null 2>&1; then \
		tflint --recursive .; \
		echo "$(GREEN)Linting completed$(RESET)"; \
	else \
		echo "$(YELLOW)tflint not found. Install it to run linting$(RESET)"; \
	fi

#####################################################################################################
# Information and Status
#####################################################################################################

.PHONY: status
status: validate-env ## Show status of all layers for an environment
	@echo "$(CYAN)Infrastructure Status for Environment: $(ENV)$(RESET)"
	@echo "$(CYAN)=======================================$(RESET)"
	@for layer in core data backend frontend config; do \
		if [ -d "$(LAYERS_DIR)/$$layer" ]; then \
			echo "$(BLUE)$$layer layer:$(RESET)"; \
			if [ -f "$(LAYERS_DIR)/$$layer/environments/$(ENV)/$(ENV).tfvars" ]; then \
				cd $(LAYERS_DIR)/$$layer && terraform workspace select $(ENV) 2>/dev/null || echo "  Workspace not created"; \
				if terraform workspace list 2>/dev/null | grep -q "$(ENV)"; then \
					echo "  $(GREEN)✓$(RESET) Workspace exists"; \
				else \
					echo "  $(RED)✗$(RESET) Workspace not found"; \
				fi; \
			else \
				echo "  $(RED)✗$(RESET) Environment config not found"; \
			fi; \
		else \
			echo "$(BLUE)$$layer layer:$(RESET) $(RED)✗$(RESET) Directory not found"; \
		fi; \
		echo ""; \
	done

.PHONY: costs
costs: validate-env ## Estimate costs for an environment (requires infracost)
	@echo "$(BLUE)Estimating costs for environment: $(ENV)$(RESET)"
	@if command -v infracost >/dev/null 2>&1; then \
		for layer in core data backend frontend config; do \
			if [ -d "$(LAYERS_DIR)/$$layer" ] && [ -f "$(LAYERS_DIR)/$$layer/environments/$(ENV)/$(ENV).tfvars" ]; then \
				echo "$(CYAN)Cost estimate for $$layer layer:$(RESET)"; \
				cd $(LAYERS_DIR)/$$layer && infracost breakdown --path . --terraform-var-file="environments/$(ENV)/$(ENV).tfvars"; \
			fi; \
		done; \
	else \
		echo "$(YELLOW)infracost not found. Install it to get cost estimates$(RESET)"; \
	fi

#####################################################################################################
# Default Target
#####################################################################################################

.DEFAULT_GOAL := help