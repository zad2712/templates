# Makefile for Terraform Infrastructure Management
# Usage: make <target> ENV=<environment> LAYER=<layer>
# Example: make plan ENV=dev LAYER=networking

.DEFAULT_GOAL := help
.PHONY: help bootstrap init plan apply destroy validate format lint

# Default values
ENV ?= dev
LAYER ?= networking
AWS_PROFILE ?= default
AWS_REGION ?= us-east-1

# Colors for output
RED := \033[31m
GREEN := \033[32m
YELLOW := \033[33m
BLUE := \033[34m
RESET := \033[0m

# Project configuration - UPDATE THESE VALUES
PROJECT_NAME := myproject
STATE_BUCKET_PREFIX := $(PROJECT_NAME)-terraform-state
LOCK_TABLE_PREFIX := $(PROJECT_NAME)-terraform-locks

# Validate required parameters
check-params:
	@if [ "$(ENV)" != "dev" ] && [ "$(ENV)" != "qa" ] && [ "$(ENV)" != "uat" ] && [ "$(ENV)" != "prod" ]; then \
		echo "$(RED)Error: ENV must be one of: dev, qa, uat, prod$(RESET)"; \
		exit 1; \
	fi
	@if [ "$(LAYER)" != "networking" ] && [ "$(LAYER)" != "security" ] && [ "$(LAYER)" != "compute" ] && [ "$(LAYER)" != "data" ]; then \
		echo "$(RED)Error: LAYER must be one of: networking, security, compute, data$(RESET)"; \
		exit 1; \
	fi

# Help target
help: ## Show this help message
	@echo "$(BLUE)Terraform Infrastructure Management$(RESET)"
	@echo ""
	@echo "$(YELLOW)Usage:$(RESET)"
	@echo "  make <target> ENV=<environment> LAYER=<layer>"
	@echo ""
	@echo "$(YELLOW)Available targets:$(RESET)"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  $(GREEN)%-15s$(RESET) %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo ""
	@echo "$(YELLOW)Examples:$(RESET)"
	@echo "  make bootstrap ENV=dev"
	@echo "  make init ENV=dev LAYER=networking"
	@echo "  make plan ENV=dev LAYER=networking"
	@echo "  make apply ENV=dev LAYER=networking"

# Bootstrap AWS infrastructure (S3 bucket and DynamoDB table)
bootstrap: ## Bootstrap AWS infrastructure for state management
	@echo "$(YELLOW)Bootstrapping AWS infrastructure for $(ENV) environment...$(RESET)"
	@aws s3api head-bucket --bucket $(STATE_BUCKET_PREFIX)-$(ENV) --profile $(AWS_PROFILE) 2>/dev/null || \
		(echo "$(BLUE)Creating S3 bucket: $(STATE_BUCKET_PREFIX)-$(ENV)$(RESET)" && \
		aws s3api create-bucket --bucket $(STATE_BUCKET_PREFIX)-$(ENV) --region $(AWS_REGION) --profile $(AWS_PROFILE) && \
		aws s3api put-bucket-versioning --bucket $(STATE_BUCKET_PREFIX)-$(ENV) --versioning-configuration Status=Enabled --profile $(AWS_PROFILE) && \
		aws s3api put-bucket-encryption --bucket $(STATE_BUCKET_PREFIX)-$(ENV) --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}' --profile $(AWS_PROFILE))
	@aws dynamodb describe-table --table-name $(LOCK_TABLE_PREFIX)-$(ENV) --profile $(AWS_PROFILE) --region $(AWS_REGION) 2>/dev/null || \
		(echo "$(BLUE)Creating DynamoDB table: $(LOCK_TABLE_PREFIX)-$(ENV)$(RESET)" && \
		aws dynamodb create-table --table-name $(LOCK_TABLE_PREFIX)-$(ENV) \
			--attribute-definitions AttributeName=LockID,AttributeType=S \
			--key-schema AttributeName=LockID,KeyType=HASH \
			--billing-mode PAY_PER_REQUEST \
			--profile $(AWS_PROFILE) --region $(AWS_REGION))
	@echo "$(GREEN)Bootstrap completed for $(ENV) environment$(RESET)"

# Initialize Terraform
init: check-params ## Initialize Terraform for the specified layer and environment
	@echo "$(YELLOW)Initializing Terraform for $(LAYER)/$(ENV)...$(RESET)"
	@cd layers/$(LAYER) && \
		sed 's/PROJECT_NAME/$(PROJECT_NAME)/g' environments/$(ENV)/backend.conf > /tmp/backend-$(ENV).conf && \
		terraform init -backend-config=/tmp/backend-$(ENV).conf -reconfigure
	@echo "$(GREEN)Terraform initialized for $(LAYER)/$(ENV)$(RESET)"

# Plan Terraform changes
plan: check-params ## Plan Terraform changes for the specified layer and environment
	@echo "$(YELLOW)Planning Terraform changes for $(LAYER)/$(ENV)...$(RESET)"
	@cd layers/$(LAYER) && \
		terraform plan -var-file=environments/$(ENV)/terraform.auto.tfvars -out=$(ENV).tfplan
	@echo "$(GREEN)Plan completed for $(LAYER)/$(ENV)$(RESET)"

# Apply Terraform changes
apply: check-params ## Apply Terraform changes for the specified layer and environment
	@echo "$(YELLOW)Applying Terraform changes for $(LAYER)/$(ENV)...$(RESET)"
	@cd layers/$(LAYER) && \
		terraform apply $(ENV).tfplan
	@echo "$(GREEN)Apply completed for $(LAYER)/$(ENV)$(RESET)"

# Destroy Terraform resources
destroy: check-params ## Destroy Terraform resources for the specified layer and environment
	@echo "$(RED)WARNING: This will destroy all resources for $(LAYER)/$(ENV)!$(RESET)"
	@read -p "Are you sure? Type 'yes' to continue: " confirm && [ "$$confirm" = "yes" ] || exit 1
	@cd layers/$(LAYER) && \
		terraform destroy -var-file=environments/$(ENV)/terraform.auto.tfvars -auto-approve
	@echo "$(GREEN)Destroy completed for $(LAYER)/$(ENV)$(RESET)"

# Validate Terraform configuration
validate: check-params ## Validate Terraform configuration for the specified layer
	@echo "$(YELLOW)Validating Terraform configuration for $(LAYER)...$(RESET)"
	@cd layers/$(LAYER) && terraform validate
	@echo "$(GREEN)Validation completed for $(LAYER)$(RESET)"

# Format Terraform files
format: ## Format all Terraform files in the project
	@echo "$(YELLOW)Formatting Terraform files...$(RESET)"
	@terraform fmt -recursive .
	@echo "$(GREEN)Formatting completed$(RESET)"

# Lint Terraform files (requires tflint)
lint: ## Lint Terraform files (requires tflint)
	@echo "$(YELLOW)Linting Terraform files...$(RESET)"
	@if command -v tflint >/dev/null 2>&1; then \
		tflint --recursive; \
	else \
		echo "$(YELLOW)tflint not found. Install it with: curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash$(RESET)"; \
	fi
	@echo "$(GREEN)Linting completed$(RESET)"

# Show Terraform output
output: check-params ## Show Terraform outputs for the specified layer and environment
	@echo "$(YELLOW)Showing outputs for $(LAYER)/$(ENV)...$(RESET)"
	@cd layers/$(LAYER) && terraform output

# Clean up temporary files
clean: ## Clean up temporary files
	@echo "$(YELLOW)Cleaning up temporary files...$(RESET)"
	@find . -name "*.tfplan" -delete
	@find . -name ".terraform" -type d -exec rm -rf {} + 2>/dev/null || true
	@find . -name ".terraform.lock.hcl" -delete
	@rm -f /tmp/backend-*.conf
	@echo "$(GREEN)Cleanup completed$(RESET)"

# Deploy all layers for an environment
deploy-all: check-params ## Deploy all layers in order for the specified environment
	@echo "$(YELLOW)Deploying all layers for $(ENV) environment...$(RESET)"
	@$(MAKE) init plan apply ENV=$(ENV) LAYER=networking
	@$(MAKE) init plan apply ENV=$(ENV) LAYER=security
	@$(MAKE) init plan apply ENV=$(ENV) LAYER=compute
	@$(MAKE) init plan apply ENV=$(ENV) LAYER=data
	@echo "$(GREEN)All layers deployed for $(ENV) environment$(RESET)"