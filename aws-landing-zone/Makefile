# Makefile for AWS Landing Zone Terraform Module

.PHONY: help init plan apply destroy validate format check clean docs

# Default target
help: ## Show this help message
	@echo "AWS Landing Zone Terraform Module"
	@echo "================================="
	@echo ""
	@echo "Available targets:"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-15s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

init: ## Initialize Terraform
	terraform init

validate: ## Validate Terraform configuration
	terraform validate

format: ## Format Terraform files
	terraform fmt -recursive

check: validate format ## Run validation and formatting

plan: ## Create Terraform execution plan
	terraform plan

apply: ## Apply Terraform configuration
	terraform apply

destroy: ## Destroy Terraform-managed infrastructure
	terraform destroy

clean: ## Clean up temporary files
	rm -rf .terraform/
	rm -f .terraform.lock.hcl
	rm -f terraform.tfstate*
	rm -f crash.log

docs: ## Generate documentation (requires terraform-docs)
	@command -v terraform-docs >/dev/null 2>&1 || { echo "terraform-docs is not installed. Install it from https://terraform-docs.io/"; exit 1; }
	terraform-docs markdown table --output-file README.md --output-mode inject .

# Example-specific targets
plan-complete: ## Plan the complete example
	cd examples/complete && terraform init && terraform plan

apply-complete: ## Apply the complete example
	cd examples/complete && terraform init && terraform apply

plan-minimal: ## Plan the minimal example  
	cd examples/minimal && terraform init && terraform plan

apply-minimal: ## Apply the minimal example
	cd examples/minimal && terraform init && terraform apply

# Security and compliance checks
security-scan: ## Run security scan (requires checkov)
	@command -v checkov >/dev/null 2>&1 || { echo "checkov is not installed. Install it with 'pip install checkov'"; exit 1; }
	checkov -d . --framework terraform

lint: ## Run terraform linting (requires tflint)
	@command -v tflint >/dev/null 2>&1 || { echo "tflint is not installed. Install it from https://github.com/terraform-linters/tflint"; exit 1; }
	tflint --init
	tflint