#!/bin/bash

# Bash Script for Terraform Infrastructure Management
# Usage: ./terraform-manager.sh -a <action> -e <env> -l <layer> [-p <profile>] [-r <region>]
# Example: ./terraform-manager.sh -a plan -e dev -l networking

# Script configuration
set -euo pipefail  # Exit on error, undefined vars, and pipe failures

# Default values
ACTION=""
ENVIRONMENT="dev"
LAYER="networking"
AWS_PROFILE="default"
AWS_REGION="us-east-1"

# Project configuration - UPDATE THESE VALUES
PROJECT_NAME="myproject"
STATE_BUCKET_PREFIX="${PROJECT_NAME}-terraform-state"
LOCK_TABLE_PREFIX="${PROJECT_NAME}-terraform-locks"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Function to display colored output
function echo_color() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to display help
function show_help() {
    cat << EOF
Terraform Infrastructure Management Script

USAGE:
    $0 -a <action> [-e <environment>] [-l <layer>] [-p <aws_profile>] [-r <aws_region>]

ACTIONS:
    bootstrap    Initialize AWS backend resources (S3 bucket, DynamoDB table)
    init         Initialize Terraform for specified layer/environment
    plan         Generate and show Terraform execution plan
    apply        Apply Terraform changes
    destroy      Destroy Terraform-managed infrastructure
    validate     Validate Terraform configuration syntax
    format       Format Terraform files
    output       Show Terraform outputs
    clean        Clean up temporary files
    deploy-all   Deploy all layers for specified environment

PARAMETERS:
    -a, --action       Required. Action to perform
    -e, --environment  Environment (dev, qa, uat, prod). Default: dev
    -l, --layer        Layer (networking, security, compute, data). Default: networking
    -p, --profile      AWS profile to use. Default: default
    -r, --region       AWS region. Default: us-east-1
    -h, --help         Show this help message

EXAMPLES:
    $0 -a bootstrap -e dev
    $0 -a init -e dev -l networking
    $0 -a plan -e prod -l security -p production
    $0 -a deploy-all -e dev -r us-west-2
EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -a|--action)
            ACTION="$2"
            shift 2
            ;;
        -e|--environment)
            ENVIRONMENT="$2"
            shift 2
            ;;
        -l|--layer)
            LAYER="$2"
            shift 2
            ;;
        -p|--profile)
            AWS_PROFILE="$2"
            shift 2
            ;;
        -r|--region)
            AWS_REGION="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo_color $RED "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Validate required parameters
if [[ -z "$ACTION" ]]; then
    echo_color $RED "Error: Action parameter is required"
    show_help
    exit 1
fi

# Validate action
case "$ACTION" in
    bootstrap|init|plan|apply|destroy|validate|format|output|clean|deploy-all)
        ;;
    *)
        echo_color $RED "Error: Invalid action '$ACTION'"
        show_help
        exit 1
        ;;
esac

# Validate environment
case "$ENVIRONMENT" in
    dev|qa|uat|prod)
        ;;
    *)
        echo_color $RED "Error: Invalid environment '$ENVIRONMENT'. Must be: dev, qa, uat, prod"
        exit 1
        ;;
esac

# Validate layer
case "$LAYER" in
    networking|security|compute|data)
        ;;
    *)
        echo_color $RED "Error: Invalid layer '$LAYER'. Must be: networking, security, compute, data"
        exit 1
        ;;
esac

# Function to check if AWS CLI is installed
function check_aws_cli() {
    if ! command -v aws &> /dev/null; then
        echo_color $RED "Error: AWS CLI not found. Please install AWS CLI first."
        return 1
    fi
    return 0
}

# Function to check if Terraform is installed
function check_terraform() {
    if ! command -v terraform &> /dev/null; then
        echo_color $RED "Error: Terraform not found. Please install Terraform first."
        return 1
    fi
    return 0
}

# Function to bootstrap AWS infrastructure
function bootstrap() {
    echo_color $YELLOW "Bootstrapping AWS infrastructure for $ENVIRONMENT environment..."
    
    # Check if S3 bucket exists
    local bucket_name="${STATE_BUCKET_PREFIX}-${ENVIRONMENT}"
    
    if aws s3api head-bucket --bucket "$bucket_name" --profile "$AWS_PROFILE" >/dev/null 2>&1; then
        echo_color $BLUE "S3 bucket $bucket_name already exists"
    else
        echo_color $BLUE "Creating S3 bucket: $bucket_name"
        
        if [[ "$AWS_REGION" == "us-east-1" ]]; then
            aws s3api create-bucket \
                --bucket "$bucket_name" \
                --region "$AWS_REGION" \
                --profile "$AWS_PROFILE"
        else
            aws s3api create-bucket \
                --bucket "$bucket_name" \
                --region "$AWS_REGION" \
                --profile "$AWS_PROFILE" \
                --create-bucket-configuration LocationConstraint="$AWS_REGION"
        fi
        
        # Enable versioning
        aws s3api put-bucket-versioning \
            --bucket "$bucket_name" \
            --versioning-configuration Status=Enabled \
            --profile "$AWS_PROFILE"
        
        # Enable server-side encryption
        aws s3api put-bucket-encryption \
            --bucket "$bucket_name" \
            --server-side-encryption-configuration '{
                "Rules": [{
                    "ApplyServerSideEncryptionByDefault": {
                        "SSEAlgorithm": "AES256"
                    }
                }]
            }' \
            --profile "$AWS_PROFILE"
    fi
    
    # Check if DynamoDB table exists
    local table_name="${LOCK_TABLE_PREFIX}-${ENVIRONMENT}"
    
    if aws dynamodb describe-table \
        --table-name "$table_name" \
        --profile "$AWS_PROFILE" \
        --region "$AWS_REGION" >/dev/null 2>&1; then
        echo_color $BLUE "DynamoDB table $table_name already exists"
    else
        echo_color $BLUE "Creating DynamoDB table: $table_name"
        aws dynamodb create-table \
            --table-name "$table_name" \
            --attribute-definitions AttributeName=LockID,AttributeType=S \
            --key-schema AttributeName=LockID,KeyType=HASH \
            --billing-mode PAY_PER_REQUEST \
            --profile "$AWS_PROFILE" \
            --region "$AWS_REGION"
    fi
    
    echo_color $GREEN "Bootstrap completed for $ENVIRONMENT environment"
}

# Function to initialize Terraform
function terraform_init() {
    echo_color $YELLOW "Initializing Terraform for $LAYER/$ENVIRONMENT..."
    
    # Read backend configuration and substitute project name
    local backend_config_file="layers/$LAYER/environments/$ENVIRONMENT/backend.conf"
    
    if [[ ! -f "$backend_config_file" ]]; then
        echo_color $RED "Error: Backend configuration file not found: $backend_config_file"
        exit 1
    fi
    
    # Create temporary backend config with substituted values
    local temp_backend_file
    temp_backend_file=$(mktemp)
    sed "s/PROJECT_NAME/$PROJECT_NAME/g" "$backend_config_file" > "$temp_backend_file"
    
    # Change to layer directory
    pushd "layers/$LAYER" > /dev/null
    
    # Initialize Terraform
    terraform init -backend-config="$temp_backend_file" -reconfigure
    local exit_code=$?
    
    # Cleanup
    popd > /dev/null
    rm -f "$temp_backend_file"
    
    if [[ $exit_code -eq 0 ]]; then
        echo_color $GREEN "Terraform initialized for $LAYER/$ENVIRONMENT"
    else
        echo_color $RED "Terraform initialization failed"
        exit $exit_code
    fi
}

# Function to plan Terraform changes
function terraform_plan() {
    echo_color $YELLOW "Planning Terraform changes for $LAYER/$ENVIRONMENT..."
    
    pushd "layers/$LAYER" > /dev/null
    
    terraform plan \
        -var-file="environments/$ENVIRONMENT/terraform.auto.tfvars" \
        -out="$ENVIRONMENT.tfplan"
    local exit_code=$?
    
    popd > /dev/null
    
    if [[ $exit_code -eq 0 ]]; then
        echo_color $GREEN "Plan completed for $LAYER/$ENVIRONMENT"
    else
        echo_color $RED "Plan failed for $LAYER/$ENVIRONMENT"
        exit $exit_code
    fi
}

# Function to apply Terraform changes
function terraform_apply() {
    echo_color $YELLOW "Applying Terraform changes for $LAYER/$ENVIRONMENT..."
    
    pushd "layers/$LAYER" > /dev/null
    
    if [[ ! -f "$ENVIRONMENT.tfplan" ]]; then
        echo_color $RED "Error: Plan file not found. Please run 'plan' action first."
        popd > /dev/null
        exit 1
    fi
    
    terraform apply "$ENVIRONMENT.tfplan"
    local exit_code=$?
    
    popd > /dev/null
    
    if [[ $exit_code -eq 0 ]]; then
        echo_color $GREEN "Apply completed for $LAYER/$ENVIRONMENT"
    else
        echo_color $RED "Apply failed for $LAYER/$ENVIRONMENT"
        exit $exit_code
    fi
}

# Function to destroy Terraform resources
function terraform_destroy() {
    echo_color $RED "WARNING: This will destroy all resources for $LAYER/$ENVIRONMENT!"
    read -p "Are you sure? Type 'yes' to continue: " confirm
    
    if [[ "$confirm" == "yes" ]]; then
        pushd "layers/$LAYER" > /dev/null
        
        terraform destroy \
            -var-file="environments/$ENVIRONMENT/terraform.auto.tfvars" \
            -auto-approve
        local exit_code=$?
        
        popd > /dev/null
        
        if [[ $exit_code -eq 0 ]]; then
            echo_color $GREEN "Destroy completed for $LAYER/$ENVIRONMENT"
        else
            echo_color $RED "Destroy failed for $LAYER/$ENVIRONMENT"
            exit $exit_code
        fi
    else
        echo_color $YELLOW "Destroy cancelled"
    fi
}

# Function to validate Terraform configuration
function terraform_validate() {
    echo_color $YELLOW "Validating Terraform configuration for $LAYER..."
    
    pushd "layers/$LAYER" > /dev/null
    
    terraform validate
    local exit_code=$?
    
    popd > /dev/null
    
    if [[ $exit_code -eq 0 ]]; then
        echo_color $GREEN "Validation completed for $LAYER"
    else
        echo_color $RED "Validation failed for $LAYER"
        exit $exit_code
    fi
}

# Function to format Terraform files
function terraform_format() {
    echo_color $YELLOW "Formatting Terraform files..."
    
    terraform fmt -recursive .
    local exit_code=$?
    
    if [[ $exit_code -eq 0 ]]; then
        echo_color $GREEN "Formatting completed"
    else
        echo_color $RED "Formatting failed"
        exit $exit_code
    fi
}

# Function to show Terraform outputs
function terraform_output() {
    echo_color $YELLOW "Showing outputs for $LAYER/$ENVIRONMENT..."
    
    pushd "layers/$LAYER" > /dev/null
    
    terraform output
    
    popd > /dev/null
}

# Function to clean up temporary files
function clean() {
    echo_color $YELLOW "Cleaning up temporary files..."
    
    # Remove plan files
    find . -name "*.tfplan" -type f -delete
    
    # Remove .terraform directories
    find . -name ".terraform" -type d -exec rm -rf {} + 2>/dev/null || true
    
    # Remove .terraform.lock.hcl files
    find . -name ".terraform.lock.hcl" -type f -delete
    
    echo_color $GREEN "Cleanup completed"
}

# Function to deploy all layers
function deploy_all() {
    echo_color $YELLOW "Deploying all layers for $ENVIRONMENT environment..."
    
    local layers=("networking" "security" "compute" "data")
    
    for current_layer in "${layers[@]}"; do
        echo_color $BLUE "Processing layer: $current_layer"
        
        # Initialize
        ACTION="init"
        LAYER="$current_layer"
        terraform_init
        
        # Plan
        ACTION="plan"
        terraform_plan
        
        # Apply
        ACTION="apply"
        terraform_apply
    done
    
    echo_color $GREEN "All layers deployed for $ENVIRONMENT environment"
}

# Main execution
function main() {
    # Check prerequisites
    if ! check_aws_cli; then
        exit 1
    fi
    
    if ! check_terraform; then
        exit 1
    fi
    
    # Execute the requested action
    case "$ACTION" in
        bootstrap)
            bootstrap
            ;;
        init)
            terraform_init
            ;;
        plan)
            terraform_plan
            ;;
        apply)
            terraform_apply
            ;;
        destroy)
            terraform_destroy
            ;;
        validate)
            terraform_validate
            ;;
        format)
            terraform_format
            ;;
        output)
            terraform_output
            ;;
        clean)
            clean
            ;;
        deploy-all)
            deploy_all
            ;;
    esac
}

# Execute main function
main "$@"