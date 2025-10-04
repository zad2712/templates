#!/usr/bin/env bash

# Bash Script for Terraform Infrastructure Management - Azure
# Usage: ./terraform-manager.sh <action> <environment> [layer] [subscription_id] [location]
# Example: ./terraform-manager.sh plan dev networking

set -euo pipefail

# Project configuration - UPDATE THESE VALUES
PROJECT_NAME="myproject"
RESOURCE_GROUP_PREFIX="$PROJECT_NAME-terraform-state"
STORAGE_ACCOUNT_PREFIX="${PROJECT_NAME}tfstate"
CONTAINER_NAME="tfstate"

# Default values
ACTION=${1:-help}
ENVIRONMENT=${2:-dev}
LAYER=${3:-networking}
SUBSCRIPTION_ID=${4:-""}
LOCATION=${5:-"East US"}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_color() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to check prerequisites
check_prerequisites() {
    print_color $BLUE "🔍 Checking prerequisites..."
    
    # Check Azure CLI
    if ! command -v az &> /dev/null; then
        print_color $RED "❌ Azure CLI is not installed or not in PATH"
        exit 1
    fi
    
    local az_version=$(az --version 2>/dev/null | grep "azure-cli" | head -n1)
    print_color $GREEN "✅ Azure CLI: $az_version"
    
    # Check Terraform
    if ! command -v terraform &> /dev/null; then
        print_color $RED "❌ Terraform is not installed or not in PATH"
        exit 1
    fi
    
    local tf_version=$(terraform version | head -n1)
    print_color $GREEN "✅ $tf_version"
    
    # Check Azure CLI login
    if ! az account show &> /dev/null; then
        print_color $RED "❌ Not logged into Azure CLI. Run 'az login'"
        exit 1
    fi
    
    local account=$(az account show --query name -o tsv 2>/dev/null)
    local subscription=$(az account show --query id -o tsv 2>/dev/null)
    print_color $GREEN "✅ Azure Account: $account"
    print_color $GREEN "✅ Subscription: $subscription"
    
    print_color $GREEN "✅ All prerequisites met!"
}

# Function to create Terraform backend resources
create_backend() {
    local env=$1
    
    print_color $BLUE "🚀 Creating Terraform backend for environment: $env"
    
    local resource_group="$RESOURCE_GROUP_PREFIX-$env"
    local storage_account="$STORAGE_ACCOUNT_PREFIX$env"
    local key_vault_name="$PROJECT_NAME-kv-$env"
    
    # Remove hyphens and ensure storage account name is valid (lowercase alphanumeric, max 24 chars)
    storage_account=$(echo "$storage_account" | tr -d '-' | tr '[:upper:]' '[:lower:]' | cut -c1-24)
    
    # Create Resource Group
    print_color $YELLOW "📦 Creating resource group: $resource_group"
    az group create \
        --name "$resource_group" \
        --location "$LOCATION" \
        --tags Environment="$env" Project="$PROJECT_NAME" ManagedBy="terraform" \
        || { print_color $RED "❌ Failed to create resource group"; exit 1; }
    
    # Create Storage Account
    print_color $YELLOW "💾 Creating storage account: $storage_account"
    az storage account create \
        --resource-group "$resource_group" \
        --name "$storage_account" \
        --location "$LOCATION" \
        --sku Standard_LRS \
        --encryption-services blob \
        --https-only true \
        --min-tls-version TLS1_2 \
        --tags Environment="$env" Project="$PROJECT_NAME" ManagedBy="terraform" \
        || { print_color $RED "❌ Failed to create storage account"; exit 1; }
    
    # Create Storage Container
    print_color $YELLOW "📁 Creating storage container: $CONTAINER_NAME"
    az storage container create \
        --name "$CONTAINER_NAME" \
        --account-name "$storage_account" \
        --auth-mode login \
        || { print_color $RED "❌ Failed to create storage container"; exit 1; }
    
    # Create Key Vault
    print_color $YELLOW "🔐 Creating Key Vault: $key_vault_name"
    az keyvault create \
        --resource-group "$resource_group" \
        --name "$key_vault_name" \
        --location "$LOCATION" \
        --enable-rbac-authorization \
        --tags Environment="$env" Project="$PROJECT_NAME" ManagedBy="terraform" \
        || { print_color $RED "❌ Failed to create Key Vault"; exit 1; }
    
    print_color $GREEN "✅ Backend resources created successfully!"
    print_color $BLUE "📝 Backend Configuration:"
    print_color $YELLOW "   Resource Group: $resource_group"
    print_color $YELLOW "   Storage Account: $storage_account"
    print_color $YELLOW "   Container: $CONTAINER_NAME"
    print_color $YELLOW "   Key Vault: $key_vault_name"
}

# Function to initialize Terraform
init_terraform() {
    local env=$1
    local layer=$2
    
    local layer_path="layers/$layer"
    local backend_config="$layer_path/environments/$env/backend.conf"
    
    if [ ! -d "$layer_path" ]; then
        print_color $RED "❌ Layer path not found: $layer_path"
        exit 1
    fi
    
    if [ ! -f "$backend_config" ]; then
        print_color $RED "❌ Backend config not found: $backend_config"
        print_color $YELLOW "💡 Run bootstrap first: ./terraform-manager.sh bootstrap $env"
        exit 1
    fi
    
    cd "$layer_path"
    
    print_color $BLUE "🔧 Initializing Terraform for $layer layer in $env environment..."
    terraform init -backend-config="environments/$env/backend.conf" -reconfigure
    
    if [ $? -ne 0 ]; then
        print_color $RED "❌ Terraform initialization failed"
        exit 1
    fi
    
    print_color $GREEN "✅ Terraform initialized successfully!"
    cd - > /dev/null
}

# Function to run Terraform plan
plan_terraform() {
    local env=$1
    local layer=$2
    
    local layer_path="layers/$layer"
    local vars_file="$layer_path/environments/$env/terraform.auto.tfvars"
    
    cd "$layer_path"
    
    print_color $BLUE "📋 Running Terraform plan for $layer layer in $env environment..."
    
    if [ -f "$vars_file" ]; then
        terraform plan -var-file="environments/$env/terraform.auto.tfvars"
    else
        terraform plan
    fi
    
    if [ $? -ne 0 ]; then
        print_color $RED "❌ Terraform plan failed"
        exit 1
    fi
    
    print_color $GREEN "✅ Terraform plan completed successfully!"
    cd - > /dev/null
}

# Function to apply Terraform configuration
apply_terraform() {
    local env=$1
    local layer=$2
    
    local layer_path="layers/$layer"
    local vars_file="$layer_path/environments/$env/terraform.auto.tfvars"
    
    cd "$layer_path"
    
    print_color $BLUE "🚀 Applying Terraform configuration for $layer layer in $env environment..."
    
    if [ -f "$vars_file" ]; then
        terraform apply -var-file="environments/$env/terraform.auto.tfvars" -auto-approve
    else
        terraform apply -auto-approve
    fi
    
    if [ $? -ne 0 ]; then
        print_color $RED "❌ Terraform apply failed"
        exit 1
    fi
    
    print_color $GREEN "✅ Terraform apply completed successfully!"
    cd - > /dev/null
}

# Function to destroy Terraform resources
destroy_terraform() {
    local env=$1
    local layer=$2
    
    local layer_path="layers/$layer"
    local vars_file="$layer_path/environments/$env/terraform.auto.tfvars"
    
    print_color $RED "⚠️  WARNING: This will destroy all resources in $layer layer for $env environment!"
    read -p "Type 'yes' to continue: " confirm
    
    if [ "$confirm" != "yes" ]; then
        print_color $YELLOW "❌ Destruction cancelled"
        return
    fi
    
    cd "$layer_path"
    
    print_color $RED "💥 Destroying Terraform resources for $layer layer in $env environment..."
    
    if [ -f "$vars_file" ]; then
        terraform destroy -var-file="environments/$env/terraform.auto.tfvars" -auto-approve
    else
        terraform destroy -auto-approve
    fi
    
    if [ $? -ne 0 ]; then
        print_color $RED "❌ Terraform destroy failed"
        exit 1
    fi
    
    print_color $GREEN "✅ Resources destroyed successfully!"
    cd - > /dev/null
}

# Function to validate Terraform configuration
validate_terraform() {
    local env=$1
    local layer=$2
    
    local layer_path="layers/$layer"
    
    cd "$layer_path"
    
    print_color $BLUE "🔍 Validating Terraform configuration for $layer layer..."
    terraform validate
    
    if [ $? -ne 0 ]; then
        print_color $RED "❌ Configuration validation failed"
        exit 1
    fi
    
    print_color $GREEN "✅ Configuration is valid!"
    cd - > /dev/null
}

# Function to format Terraform files
format_terraform() {
    print_color $BLUE "🎨 Formatting Terraform files..."
    terraform fmt -recursive
    print_color $GREEN "✅ Files formatted successfully!"
}

# Function to show Terraform outputs
show_outputs() {
    local env=$1
    local layer=$2
    
    local layer_path="layers/$layer"
    
    cd "$layer_path"
    
    print_color $BLUE "📤 Showing Terraform outputs for $layer layer in $env environment..."
    terraform output
    print_color $GREEN "✅ Outputs displayed successfully!"
    cd - > /dev/null
}

# Function to clean local state
clean_state() {
    print_color $BLUE "🧹 Cleaning local Terraform state and cache..."
    find . -type d -name ".terraform" -exec rm -rf {} + 2>/dev/null || true
    find . -name "*.tfplan" -delete 2>/dev/null || true
    find . -name ".terraform.lock.hcl" -delete 2>/dev/null || true
    print_color $GREEN "✅ Local state cleaned successfully!"
}

# Function for complete deployment
deploy_all() {
    local env=$1
    local layer=$2
    
    print_color $BLUE "🚀 Starting complete deployment for $layer layer in $env environment..."
    
    # Initialize
    init_terraform "$env" "$layer"
    
    # Plan
    plan_terraform "$env" "$layer"
    
    # Apply
    apply_terraform "$env" "$layer"
    
    print_color $GREEN "✅ Complete deployment finished successfully!"
}

# Function to show help
show_help() {
    echo "Terraform Infrastructure Manager for Azure"
    echo ""
    echo "Usage: $0 <action> <environment> [layer] [subscription_id] [location]"
    echo ""
    echo "Actions:"
    echo "  bootstrap    Create Terraform backend resources"
    echo "  init         Initialize Terraform"
    echo "  plan         Generate execution plan"
    echo "  apply        Apply infrastructure changes"
    echo "  destroy      Destroy infrastructure (DANGEROUS)"
    echo "  validate     Validate Terraform configuration"
    echo "  format       Format Terraform files"
    echo "  output       Show Terraform outputs"
    echo "  clean        Clean local state and cache"
    echo "  deploy-all   Complete deployment workflow"
    echo "  help         Show this help"
    echo ""
    echo "Environments: dev, qa, uat, prod"
    echo "Layers: networking, security, data, compute"
    echo ""
    echo "Examples:"
    echo "  $0 bootstrap dev"
    echo "  $0 plan dev networking"
    echo "  $0 apply prod compute"
    echo "  $0 deploy-all dev networking"
}

# Validate environment
validate_environment() {
    case $ENVIRONMENT in
        dev|qa|uat|prod) ;;
        *) print_color $RED "❌ Invalid environment: $ENVIRONMENT. Must be one of: dev, qa, uat, prod"; exit 1 ;;
    esac
}

# Validate layer
validate_layer() {
    case $LAYER in
        networking|security|data|compute) ;;
        *) print_color $RED "❌ Invalid layer: $LAYER. Must be one of: networking, security, data, compute"; exit 1 ;;
    esac
}

# Main script execution
main() {
    print_color $BLUE "🏗️  Terraform Infrastructure Manager for Azure"
    print_color $YELLOW "Environment: $ENVIRONMENT | Layer: $LAYER | Action: $ACTION"
    
    # Show help if requested
    if [ "$ACTION" = "help" ] || [ "$ACTION" = "-h" ] || [ "$ACTION" = "--help" ]; then
        show_help
        exit 0
    fi
    
    # Check prerequisites for all actions except clean and format
    if [ "$ACTION" != "clean" ] && [ "$ACTION" != "format" ] && [ "$ACTION" != "help" ]; then
        check_prerequisites
        validate_environment
        validate_layer
    fi
    
    # Set subscription if provided
    if [ -n "$SUBSCRIPTION_ID" ]; then
        print_color $BLUE "🔄 Setting Azure subscription: $SUBSCRIPTION_ID"
        az account set --subscription "$SUBSCRIPTION_ID"
    fi
    
    # Execute action
    case $ACTION in
        bootstrap)
            create_backend "$ENVIRONMENT"
            ;;
        init)
            init_terraform "$ENVIRONMENT" "$LAYER"
            ;;
        plan)
            init_terraform "$ENVIRONMENT" "$LAYER"
            plan_terraform "$ENVIRONMENT" "$LAYER"
            ;;
        apply)
            init_terraform "$ENVIRONMENT" "$LAYER"
            apply_terraform "$ENVIRONMENT" "$LAYER"
            ;;
        destroy)
            init_terraform "$ENVIRONMENT" "$LAYER"
            destroy_terraform "$ENVIRONMENT" "$LAYER"
            ;;
        validate)
            validate_terraform "$ENVIRONMENT" "$LAYER"
            ;;
        format)
            format_terraform
            ;;
        output)
            show_outputs "$ENVIRONMENT" "$LAYER"
            ;;
        clean)
            clean_state
            ;;
        deploy-all)
            deploy_all "$ENVIRONMENT" "$LAYER"
            ;;
        *)
            print_color $RED "❌ Unknown action: $ACTION"
            show_help
            exit 1
            ;;
    esac
    
    print_color $GREEN "🎉 Action '$ACTION' completed successfully!"
}

# Run main function
main "$@"