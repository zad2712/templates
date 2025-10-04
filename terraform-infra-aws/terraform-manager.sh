#!/bin/bash
# Terraform AWS Infrastructure Management Script
# Author: Diego A. Zarate
# Description: Manages Terraform operations for AWS infrastructure layers

set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"

# Available layers
LAYERS=("networking" "security" "data" "compute")
# Available environments  
ENVIRONMENTS=("dev" "qa" "uat" "prod")
# Available commands
COMMANDS=("init" "validate" "plan" "apply" "destroy" "output" "format" "lint" "clean")

# Usage function
usage() {
    echo -e "${BLUE}AWS Terraform Infrastructure Management${NC}"
    echo -e "${BLUE}Author: Diego A. Zarate${NC}"
    echo ""
    echo "Usage: $0 <command> <layer> <environment> [options]"
    echo ""
    echo -e "${YELLOW}Commands:${NC}"
    echo "  init      - Initialize Terraform for the specified layer and environment"
    echo "  validate  - Validate Terraform configuration"
    echo "  plan      - Create execution plan"
    echo "  apply     - Apply Terraform changes"
    echo "  destroy   - Destroy Terraform-managed infrastructure"
    echo "  output    - Show output values"
    echo "  format    - Format Terraform files"
    echo "  lint      - Run terraform validate and fmt check"
    echo "  clean     - Clean temporary files and .terraform directories"
    echo ""
    echo -e "${YELLOW}Layers:${NC}"
    for layer in "${LAYERS[@]}"; do
        echo "  $layer"
    done
    echo ""
    echo -e "${YELLOW}Environments:${NC}"
    for env in "${ENVIRONMENTS[@]}"; do
        echo "  $env"
    done
    echo ""
    echo -e "${YELLOW}Examples:${NC}"
    echo "  $0 init networking dev"
    echo "  $0 plan security prod"
    echo "  $0 apply compute qa -auto-approve"
    echo "  $0 destroy data uat"
    echo "  $0 output networking prod"
    echo ""
    echo -e "${YELLOW}Special Commands:${NC}"
    echo "  $0 init-all <environment>     - Initialize all layers for an environment"
    echo "  $0 plan-all <environment>     - Plan all layers for an environment"
    echo "  $0 apply-all <environment>    - Apply all layers for an environment (in order)"
    echo "  $0 format-all                 - Format all Terraform files"
    echo "  $0 lint-all                   - Lint all Terraform configurations"
}

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Validation functions
validate_layer() {
    local layer="$1"
    if [[ ! " ${LAYERS[*]} " =~ " ${layer} " ]]; then
        log_error "Invalid layer: $layer"
        echo "Available layers: ${LAYERS[*]}"
        exit 1
    fi
}

validate_environment() {
    local environment="$1"
    if [[ ! " ${ENVIRONMENTS[*]} " =~ " ${environment} " ]]; then
        log_error "Invalid environment: $environment"
        echo "Available environments: ${ENVIRONMENTS[*]}"
        exit 1
    fi
}

validate_command() {
    local command="$1"
    if [[ ! " ${COMMANDS[*]} " =~ " ${command} " ]]; then
        log_error "Invalid command: $command"
        echo "Available commands: ${COMMANDS[*]}"
        exit 1
    fi
}

# Check if required tools are installed
check_dependencies() {
    local missing_deps=()
    
    if ! command -v terraform &> /dev/null; then
        missing_deps+=("terraform")
    fi
    
    if ! command -v aws &> /dev/null; then
        missing_deps+=("aws-cli")
    fi
    
    if ! command -v jq &> /dev/null; then
        missing_deps+=("jq")
    fi
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log_error "Missing dependencies: ${missing_deps[*]}"
        echo "Please install the missing dependencies and try again."
        exit 1
    fi
}

# Get layer directory path
get_layer_path() {
    local layer="$1"
    local environment="$2"
    echo "$PROJECT_ROOT/layers/$layer/environments/$environment"
}

# Change to layer directory
change_to_layer_dir() {
    local layer="$1"
    local environment="$2"
    local layer_path
    
    layer_path=$(get_layer_path "$layer" "$environment")
    
    if [[ ! -d "$layer_path" ]]; then
        log_error "Layer directory does not exist: $layer_path"
        exit 1
    fi
    
    cd "$layer_path"
    log_info "Changed to directory: $layer_path"
}

# Run Terraform command
run_terraform() {
    local command="$1"
    local layer="$2" 
    local environment="$3"
    shift 3
    local extra_args=("$@")
    
    change_to_layer_dir "$layer" "$environment"
    
    case "$command" in
        "init")
            log_info "Initializing Terraform for $layer ($environment)..."
            terraform init -backend-config=backend.conf "${extra_args[@]}"
            ;;
        "validate")
            log_info "Validating Terraform configuration for $layer ($environment)..."
            terraform validate
            ;;
        "plan")
            log_info "Planning Terraform changes for $layer ($environment)..."
            terraform plan "${extra_args[@]}"
            ;;
        "apply")
            log_info "Applying Terraform changes for $layer ($environment)..."
            terraform apply "${extra_args[@]}"
            ;;
        "destroy")
            log_warning "This will destroy resources in $layer ($environment)!"
            read -p "Are you sure? (yes/no): " confirm
            if [[ "$confirm" == "yes" ]]; then
                terraform destroy "${extra_args[@]}"
            else
                log_info "Destroy cancelled."
            fi
            ;;
        "output")
            log_info "Getting outputs for $layer ($environment)..."
            terraform output "${extra_args[@]}"
            ;;
        "format")
            log_info "Formatting Terraform files for $layer ($environment)..."
            terraform fmt -recursive
            ;;
        "lint")
            log_info "Linting Terraform configuration for $layer ($environment)..."
            terraform fmt -check=true -diff=true
            terraform validate
            ;;
        "clean")
            log_info "Cleaning temporary files for $layer ($environment)..."
            rm -rf .terraform .terraform.lock.hcl terraform.tfplan
            ;;
        *)
            log_error "Unknown command: $command"
            exit 1
            ;;
    esac
}

# Special commands for multiple layers/environments
run_special_command() {
    local command="$1"
    local environment="$2"
    
    case "$command" in
        "init-all")
            validate_environment "$environment"
            log_info "Initializing all layers for $environment environment..."
            for layer in "${LAYERS[@]}"; do
                run_terraform "init" "$layer" "$environment"
            done
            ;;
        "plan-all")
            validate_environment "$environment"
            log_info "Planning all layers for $environment environment..."
            for layer in "${LAYERS[@]}"; do
                run_terraform "plan" "$layer" "$environment"
            done
            ;;
        "apply-all")
            validate_environment "$environment"
            log_warning "This will apply changes to ALL layers in $environment environment!"
            read -p "Are you sure? (yes/no): " confirm
            if [[ "$confirm" == "yes" ]]; then
                log_info "Applying all layers for $environment environment (in dependency order)..."
                for layer in "${LAYERS[@]}"; do
                    run_terraform "apply" "$layer" "$environment" "-auto-approve"
                done
            else
                log_info "Apply cancelled."
            fi
            ;;
        "format-all")
            log_info "Formatting all Terraform files..."
            cd "$PROJECT_ROOT"
            terraform fmt -recursive
            ;;
        "lint-all")
            log_info "Linting all Terraform configurations..."
            for layer in "${LAYERS[@]}"; do
                for env in "${ENVIRONMENTS[@]}"; do
                    if [[ -d "$(get_layer_path "$layer" "$env")" ]]; then
                        run_terraform "lint" "$layer" "$env"
                    fi
                done
            done
            ;;
        *)
            log_error "Unknown special command: $command"
            exit 1
            ;;
    esac
}

# Main function
main() {
    # Check if help is requested
    if [[ $# -eq 0 ]] || [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
        usage
        exit 0
    fi
    
    # Check dependencies
    check_dependencies
    
    local command="$1"
    
    # Handle special commands
    if [[ "$command" == "init-all" ]] || [[ "$command" == "plan-all" ]] || [[ "$command" == "apply-all" ]]; then
        if [[ $# -lt 2 ]]; then
            log_error "Missing environment for $command"
            usage
            exit 1
        fi
        run_special_command "$command" "$2"
        exit 0
    fi
    
    if [[ "$command" == "format-all" ]] || [[ "$command" == "lint-all" ]]; then
        run_special_command "$command"
        exit 0
    fi
    
    # Validate arguments for regular commands
    if [[ $# -lt 3 ]]; then
        log_error "Missing required arguments"
        usage
        exit 1
    fi
    
    local layer="$2"
    local environment="$3"
    shift 3
    local extra_args=("$@")
    
    # Validate inputs
    validate_command "$command"
    validate_layer "$layer"
    validate_environment "$environment"
    
    # Run the command
    log_info "Running $command for $layer layer in $environment environment..."
    run_terraform "$command" "$layer" "$environment" "${extra_args[@]}"
    log_success "Command completed successfully!"
}

# Run main function with all arguments
main "$@"