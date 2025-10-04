# 🚀 Terraform Deployment Guide

[![Terraform](https://img.shields.io/badge/Terraform-≥1.9.0-blue.svg)](https://terraform.io)
[![PowerShell](https://img.shields.io/badge/PowerShell-≥5.1-blue.svg)](https://docs.microsoft.com/powershell/)
[![Bash](https://img.shields.io/badge/Bash-≥4.0-blue.svg)](https://www.gnu.org/software/bash/)

This guide provides comprehensive instructions for deploying the Azure infrastructure using the provided Terraform management scripts. The project includes both PowerShell (`terraform-manager.ps1`) and Bash (`terraform-manager.sh`) scripts for cross-platform deployment support.

## 🎯 **Overview**

The Terraform infrastructure is organized in a **layered architecture** where each layer depends on the previous ones:

```
1. Networking Layer    ← Foundation (VNets, subnets, NSGs)
2. Security Layer      ← Identity, encryption, monitoring  
3. Data Layer         ← Databases, storage, caching
4. Compute Layer      ← AKS, Functions, Web Apps
```

## 📋 **Prerequisites**

### **Required Tools**

| Tool | Version | Purpose | Installation |
|------|---------|---------|--------------|
| **Terraform** | ≥ 1.9.0 | Infrastructure as Code | [Install Guide](https://learn.hashicorp.com/tutorials/terraform/install-cli) |
| **Azure CLI** | ≥ 2.50.0 | Azure authentication | [Install Guide](https://docs.microsoft.com/cli/azure/install-azure-cli) |
| **PowerShell** | ≥ 5.1 | Windows deployment | Pre-installed on Windows |
| **Bash** | ≥ 4.0 | Linux/macOS deployment | Pre-installed on Linux/macOS |

### **Azure Setup**

```bash
# 1. Login to Azure
az login

# 2. Set the active subscription
az account set --subscription "your-subscription-id"

# 3. Verify current subscription
az account show

# 4. Register required resource providers (if not already registered)
az provider register --namespace Microsoft.Network
az provider register --namespace Microsoft.Compute
az provider register --namespace Microsoft.ContainerService
az provider register --namespace Microsoft.Storage
az provider register --namespace Microsoft.Sql
az provider register --namespace Microsoft.KeyVault
az provider register --namespace Microsoft.OperationalInsights
```

### **Service Principal Setup (for CI/CD)**

```bash
# Create service principal for Terraform
az ad sp create-for-rbac --name "terraform-sp" \
  --role "Contributor" \
  --scopes "/subscriptions/your-subscription-id"

# Output will be:
# {
#   "appId": "12345678-1234-1234-1234-123456789012",
#   "displayName": "terraform-sp",
#   "password": "your-client-secret",
#   "tenant": "your-tenant-id"
# }

# Set environment variables (for automated deployments)
export ARM_CLIENT_ID="12345678-1234-1234-1234-123456789012"
export ARM_CLIENT_SECRET="your-client-secret"
export ARM_SUBSCRIPTION_ID="your-subscription-id"
export ARM_TENANT_ID="your-tenant-id"
```

## 🛠️ **Deployment Scripts**

### **PowerShell Script (terraform-manager.ps1)**

**Features:**
- ✅ Cross-platform PowerShell Core support
- ✅ Comprehensive error handling and validation
- ✅ Interactive and automated deployment modes
- ✅ Layer dependency management
- ✅ State management and cleanup utilities
- ✅ Comprehensive logging and progress tracking

**Usage:**
```powershell
# Make script executable (if needed)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# View help and available commands
.\terraform-manager.ps1 -Help

# Initialize a specific layer and environment
.\terraform-manager.ps1 -Action init -Layer networking -Environment dev

# Plan deployment for a specific layer
.\terraform-manager.ps1 -Action plan -Layer networking -Environment prod

# Deploy a complete environment (all layers in order)
.\terraform-manager.ps1 -Action deploy-all -Environment prod

# Destroy resources in reverse order
.\terraform-manager.ps1 -Action destroy-all -Environment dev -AutoApprove
```

### **Bash Script (terraform-manager.sh)**

**Features:**
- ✅ POSIX-compliant shell scripting
- ✅ Robust error handling with set -euo pipefail
- ✅ Color-coded output and progress indicators
- ✅ Parallel execution support for compatible operations
- ✅ State validation and backup management
- ✅ Integration with CI/CD pipelines

**Usage:**
```bash
# Make script executable
chmod +x terraform-manager.sh

# View help and available commands
./terraform-manager.sh --help

# Initialize and deploy a single layer
./terraform-manager.sh init networking dev
./terraform-manager.sh apply networking dev

# Deploy all layers for an environment
./terraform-manager.sh deploy-all prod

# Check deployment status
./terraform-manager.sh status networking prod

# Destroy resources
./terraform-manager.sh destroy networking dev --auto-approve
```

## 🚀 **Deployment Scenarios**

### **Scenario 1: New Environment Deployment**

Deploy a complete new environment from scratch:

#### **Method 1: Layer-by-Layer (Recommended for first deployment)**

```bash
# 1. Deploy networking foundation
./terraform-manager.sh init networking prod
./terraform-manager.sh plan networking prod
./terraform-manager.sh apply networking prod

# 2. Deploy security layer
./terraform-manager.sh init security prod  
./terraform-manager.sh plan security prod
./terraform-manager.sh apply security prod

# 3. Deploy data layer
./terraform-manager.sh init data prod
./terraform-manager.sh plan data prod
./terraform-manager.sh apply data prod

# 4. Deploy compute layer
./terraform-manager.sh init compute prod
./terraform-manager.sh plan compute prod
./terraform-manager.sh apply compute prod
```

#### **Method 2: Automated Full Deployment**

```bash
# Deploy all layers automatically with dependency management
./terraform-manager.sh deploy-all prod

# Or with PowerShell
.\terraform-manager.ps1 -Action deploy-all -Environment prod -Verbose
```

### **Scenario 2: Development Environment**

Quick setup for development environment:

```bash
# Fast deployment with minimal resources
./terraform-manager.sh deploy-all dev --fast

# Or specific layers only for development
./terraform-manager.sh apply networking dev
./terraform-manager.sh apply compute dev  # Skip security and data for dev
```

### **Scenario 3: Production Deployment**

Production deployment with comprehensive validation:

```powershell
# PowerShell with full validation and backup
.\terraform-manager.ps1 -Action validate-all -Environment prod
.\terraform-manager.ps1 -Action backup-state -Environment prod
.\terraform-manager.ps1 -Action deploy-all -Environment prod -CreateBackup -ValidateFirst
```

### **Scenario 4: Disaster Recovery Setup**

Setup secondary region for disaster recovery:

```bash
# Deploy to secondary region
export TF_VAR_primary_region="East US"
export TF_VAR_secondary_region="West US 2"
export TF_VAR_enable_dr="true"

# Deploy DR infrastructure
./terraform-manager.sh deploy-all prod-dr
```

### **Scenario 5: Blue-Green Deployment**

Deploy new version alongside existing (blue-green deployment):

```bash
# Deploy green environment
export TF_VAR_deployment_slot="green"
./terraform-manager.sh deploy-all prod-green

# Switch traffic after validation
export TF_VAR_active_slot="green"
./terraform-manager.sh apply compute prod

# Cleanup blue environment
export TF_VAR_deployment_slot="blue"
./terraform-manager.sh destroy compute prod-blue --auto-approve
```

## 🔧 **Advanced Usage**

### **Custom Variable Files**

```bash
# Use custom variable file
export TF_VAR_FILE="custom-variables.tfvars"
./terraform-manager.sh apply networking prod

# Multiple variable files
export TF_VAR_FILES="base.tfvars,override.tfvars,secrets.tfvars"
./terraform-manager.sh apply networking prod
```

### **Targeted Resource Deployment**

```bash
# Deploy specific resources only
./terraform-manager.sh apply networking prod --target="module.vpc"
./terraform-manager.sh apply networking prod --target="module.vpc.azurerm_virtual_network.main"

# Deploy multiple specific resources
./terraform-manager.sh apply compute prod \
  --target="module.aks" \
  --target="module.functions"
```

### **State Management**

```bash
# Import existing resources
./terraform-manager.sh import networking prod \
  "module.vpc.azurerm_resource_group.main" \
  "/subscriptions/xxx/resourceGroups/existing-rg"

# Move state between modules
./terraform-manager.sh state-mv networking prod \
  "azurerm_virtual_network.old" \
  "module.vpc.azurerm_virtual_network.main"

# Remove resource from state (without destroying)
./terraform-manager.sh state-rm networking prod \
  "module.legacy.azurerm_storage_account.old"
```

### **Workspace Management**

```bash
# Create and use workspace
./terraform-manager.sh workspace-new networking feature-branch
./terraform-manager.sh workspace-select networking feature-branch
./terraform-manager.sh apply networking feature-branch

# List workspaces
./terraform-manager.sh workspace-list networking

# Delete workspace
./terraform-manager.sh workspace-delete networking feature-branch
```

## 📊 **Validation and Testing**

### **Pre-deployment Validation**

```bash
# Validate Terraform configurations
./terraform-manager.sh validate networking prod

# Check formatting
./terraform-manager.sh fmt networking --check

# Security scanning (if tfsec is installed)
./terraform-manager.sh security-scan networking

# Cost estimation (if infracost is installed)
./terraform-manager.sh cost-estimate networking prod
```

### **Post-deployment Testing**

```bash
# Verify deployment status
./terraform-manager.sh status networking prod

# Test connectivity
./terraform-manager.sh test networking prod

# Generate deployment report
./terraform-manager.sh report networking prod --format json > deployment-report.json
```

### **Health Checks**

```bash
# Built-in health checks
./terraform-manager.sh health-check networking prod

# Custom health checks
./terraform-manager.sh health-check compute prod --check-pods --check-services
```

## 🔒 **Security Best Practices**

### **Secret Management**

```bash
# Use Azure Key Vault for secrets
export TF_VAR_key_vault_name="myapp-prod-kv"

# Environment-specific secret references
export TF_VAR_sql_admin_password="@Microsoft.KeyVault(VaultName=myapp-prod-kv;SecretName=sql-admin-password)"
export TF_VAR_storage_key="@Microsoft.KeyVault(VaultName=myapp-prod-kv;SecretName=storage-key)"

./terraform-manager.sh apply data prod
```

### **State Security**

```bash
# Enable state encryption
export TF_VAR_enable_state_encryption="true"
export TF_VAR_state_encryption_key_id="/subscriptions/xxx/resourceGroups/xxx/providers/Microsoft.KeyVault/vaults/xxx/keys/terraform-state"

# Use managed identity for state access
export ARM_USE_MSI="true"
./terraform-manager.sh apply networking prod
```

### **Access Control**

```bash
# Use specific service principal per environment
export ARM_CLIENT_ID_DEV="dev-sp-client-id"
export ARM_CLIENT_ID_PROD="prod-sp-client-id"

# Environment-specific deployment
./terraform-manager.sh apply networking dev    # Uses dev SP
./terraform-manager.sh apply networking prod   # Uses prod SP
```

## 📈 **Monitoring and Logging**

### **Deployment Logging**

```bash
# Enable verbose logging
export TF_LOG="INFO"
export TF_LOG_PATH="./terraform-$(date +%Y%m%d-%H%M%S).log"

./terraform-manager.sh apply networking prod

# Enable debug logging for troubleshooting
export TF_LOG="DEBUG"
./terraform-manager.sh apply networking prod
```

### **Deployment Metrics**

```bash
# Generate deployment metrics
./terraform-manager.sh metrics networking prod

# Send metrics to Azure Monitor
export AZURE_MONITOR_WORKSPACE_ID="your-workspace-id"
./terraform-manager.sh apply networking prod --send-metrics
```

### **Notification Integration**

```bash
# Slack notifications
export SLACK_WEBHOOK_URL="https://hooks.slack.com/services/xxx"
export SLACK_CHANNEL="#infrastructure"

./terraform-manager.sh apply networking prod --notify-slack

# Teams notifications  
export TEAMS_WEBHOOK_URL="https://outlook.office.com/webhook/xxx"
./terraform-manager.sh apply networking prod --notify-teams
```

## 🚨 **Troubleshooting Guide**

### **Common Issues and Solutions**

#### **Authentication Issues**
```bash
# Clear Azure CLI cache
az account clear
az login

# Verify service principal
az ad sp show --id $ARM_CLIENT_ID

# Test service principal authentication
az login --service-principal \
  --username $ARM_CLIENT_ID \
  --password $ARM_CLIENT_SECRET \
  --tenant $ARM_TENANT_ID
```

#### **State Lock Issues**
```bash
# Force unlock state (use with caution)
./terraform-manager.sh force-unlock networking prod LOCK_ID

# Break glass - remove lock manually
az storage blob delete \
  --account-name "terraformstate" \
  --container-name "tfstate" \
  --name "networking/prod/terraform.tfstate.lock"
```

#### **Resource Provider Issues**
```bash
# Register required providers
az provider register --namespace Microsoft.Network --wait
az provider register --namespace Microsoft.Compute --wait
az provider register --namespace Microsoft.ContainerService --wait

# Check provider registration status
az provider show --namespace Microsoft.Network --query "registrationState"
```

#### **Quota and Limits**
```bash
# Check subscription quotas
az vm list-usage --location "East US" --query "[?currentValue >= limit]"

# Request quota increase
az support tickets create \
  --ticket-name "VM Quota Increase" \
  --severity "minimal" \
  --contact-country "US" \
  --contact-email "admin@company.com" \
  --contact-first-name "Admin" \
  --contact-last-name "User" \
  --contact-language "en-us" \
  --contact-method "email" \
  --contact-timezone "Pacific Standard Time"
```

#### **Network Connectivity Issues**
```bash
# Test network connectivity between layers
./terraform-manager.sh test-connectivity networking prod

# Validate NSG rules
az network nsg rule list --resource-group "myapp-prod-networking-rg" --nsg-name "app-nsg"

# Check DNS resolution
nslookup myapp-prod-sql.database.windows.net
```

### **Debug Mode**

```bash
# Enable comprehensive debugging
export TF_LOG="DEBUG"
export TF_LOG_PATH="debug.log"
export VERBOSE_MODE="true"

./terraform-manager.sh apply networking prod --debug

# Review debug output
tail -f debug.log
grep -i error debug.log
```

### **Recovery Procedures**

#### **State Corruption Recovery**
```bash
# Backup current state
./terraform-manager.sh backup-state networking prod

# Restore from backup
./terraform-manager.sh restore-state networking prod --backup-date "2025-01-04"

# Rebuild state from existing resources
./terraform-manager.sh import-all networking prod
```

#### **Partial Deployment Failure**
```bash
# Continue deployment from failure point
./terraform-manager.sh apply networking prod --continue-on-error

# Apply targeted fixes
./terraform-manager.sh apply networking prod --target="module.failed_resource"

# Retry with different strategy
./terraform-manager.sh apply networking prod --parallelism=1
```

## 🔄 **CI/CD Integration**

### **GitHub Actions Integration**

```yaml
# .github/workflows/terraform-deploy.yml
name: Terraform Deploy

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  terraform:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v4
    
    - name: Setup Terraform
      uses: hashicorp/setup-terraform@v3
      with:
        terraform_version: 1.9.0
        
    - name: Azure Login
      uses: azure/login@v2
      with:
        creds: ${{ secrets.AZURE_CREDENTIALS }}
        
    - name: Terraform Deploy
      run: |
        chmod +x terraform-manager.sh
        ./terraform-manager.sh deploy-all prod
      env:
        ARM_CLIENT_ID: ${{ secrets.ARM_CLIENT_ID }}
        ARM_CLIENT_SECRET: ${{ secrets.ARM_CLIENT_SECRET }}
        ARM_SUBSCRIPTION_ID: ${{ secrets.ARM_SUBSCRIPTION_ID }}
        ARM_TENANT_ID: ${{ secrets.ARM_TENANT_ID }}
```

### **Azure DevOps Integration**

```yaml
# azure-pipelines.yml
trigger:
  branches:
    include:
    - main
    - develop

pool:
  vmImage: 'ubuntu-latest'

variables:
- group: terraform-variables

stages:
- stage: Plan
  jobs:
  - job: TerraformPlan
    steps:
    - task: AzureCLI@2
      displayName: 'Terraform Plan'
      inputs:
        azureSubscription: '$(serviceConnection)'
        scriptType: 'bash'
        scriptLocation: 'inlineScript'
        inlineScript: |
          chmod +x terraform-manager.sh
          ./terraform-manager.sh plan networking $(environment)

- stage: Apply
  condition: and(succeeded(), eq(variables['Build.SourceBranch'], 'refs/heads/main'))
  jobs:
  - deployment: TerraformApply
    environment: 'production'
    strategy:
      runOnce:
        deploy:
          steps:
          - task: AzureCLI@2
            displayName: 'Terraform Apply'
            inputs:
              azureSubscription: '$(serviceConnection)'
              scriptType: 'bash'
              scriptLocation: 'inlineScript'  
              inlineScript: |
                chmod +x terraform-manager.sh
                ./terraform-manager.sh deploy-all $(environment)
```

## 📚 **Reference Commands**

### **Quick Reference**

```bash
# Essential commands
./terraform-manager.sh --help                    # Show help
./terraform-manager.sh init <layer> <env>        # Initialize layer
./terraform-manager.sh plan <layer> <env>        # Plan deployment
./terraform-manager.sh apply <layer> <env>       # Apply changes
./terraform-manager.sh destroy <layer> <env>     # Destroy resources
./terraform-manager.sh deploy-all <env>          # Deploy all layers
./terraform-manager.sh status <layer> <env>      # Check status

# State management
./terraform-manager.sh state-list <layer> <env>  # List state resources
./terraform-manager.sh state-show <layer> <env> <resource>  # Show resource
./terraform-manager.sh import <layer> <env> <addr> <id>     # Import resource
./terraform-manager.sh state-rm <layer> <env> <addr>       # Remove from state

# Validation and testing
./terraform-manager.sh validate <layer>          # Validate configuration
./terraform-manager.sh fmt <layer>               # Format code
./terraform-manager.sh test <layer> <env>        # Run tests
./terraform-manager.sh health-check <layer> <env> # Health check

# Utilities
./terraform-manager.sh backup-state <layer> <env>    # Backup state
./terraform-manager.sh restore-state <layer> <env>   # Restore state
./terraform-manager.sh clean <layer> <env>           # Clean cache
./terraform-manager.sh refresh <layer> <env>         # Refresh state
```

### **Environment Variables**

| Variable | Description | Example |
|----------|-------------|---------|
| `TF_VAR_FILE` | Custom variable file | `custom.tfvars` |
| `TF_VAR_FILES` | Multiple variable files | `base.tfvars,prod.tfvars` |
| `TF_LOG` | Terraform log level | `INFO`, `DEBUG` |
| `TF_LOG_PATH` | Log file path | `terraform.log` |
| `ARM_CLIENT_ID` | Azure service principal ID | `12345678-1234-...` |
| `ARM_CLIENT_SECRET` | Azure service principal secret | `your-secret` |
| `ARM_SUBSCRIPTION_ID` | Azure subscription ID | `87654321-4321-...` |
| `ARM_TENANT_ID` | Azure tenant ID | `abcdefgh-abcd-...` |
| `VERBOSE_MODE` | Enable verbose output | `true`, `false` |
| `AUTO_APPROVE` | Skip confirmation prompts | `true`, `false` |

---

**📍 Navigation**: [🏠 Main README](README.md) | [📁 Layers Documentation](layers/README.md) | [🔧 Modules Documentation](modules/README.md)