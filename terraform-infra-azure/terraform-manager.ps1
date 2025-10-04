# PowerShell Script for Terraform Infrastructure Management - Azure
# Usage: .\terraform-manager.ps1 -Action <action> -Environment <env> -Layer <layer>
# Example: .\terraform-manager.ps1 -Action plan -Environment dev -Layer networking

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("bootstrap", "init", "plan", "apply", "destroy", "validate", "format", "output", "clean", "deploy-all")]
    [string]$Action,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("dev", "qa", "uat", "prod")]
    [string]$Environment = "dev",
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("networking", "security", "compute", "data")]
    [string]$Layer = "networking",
    
    [Parameter(Mandatory=$false)]
    [string]$SubscriptionId = "",
    
    [Parameter(Mandatory=$false)]
    [string]$Location = "East US"
)

# Project configuration - UPDATE THESE VALUES
$ProjectName = "myproject"
$ResourceGroupPrefix = "$ProjectName-terraform-state"
$StorageAccountPrefix = "$($ProjectName)tfstate"
$ContainerName = "tfstate"

# Colors for output
$Red = "Red"
$Green = "Green"
$Yellow = "Yellow"
$Blue = "Cyan"

# Function to write colored output
function Write-ColorOutput {
    param([string]$Message, [string]$Color = "White")
    Write-Host $Message -ForegroundColor $Color
}

# Function to check prerequisites
function Test-Prerequisites {
    Write-ColorOutput "🔍 Checking prerequisites..." $Blue
    
    # Check Azure CLI
    try {
        $azVersion = az --version 2>$null | Select-String "azure-cli"
        if (-not $azVersion) {
            throw "Azure CLI not found"
        }
        Write-ColorOutput "✅ Azure CLI: $($azVersion.ToString().Trim())" $Green
    } catch {
        Write-ColorOutput "❌ Azure CLI is not installed or not in PATH" $Red
        exit 1
    }
    
    # Check Terraform
    try {
        $tfVersion = terraform version 2>$null | Select-String "Terraform v"
        if (-not $tfVersion) {
            throw "Terraform not found"
        }
        Write-ColorOutput "✅ Terraform: $($tfVersion.ToString().Trim())" $Green
    } catch {
        Write-ColorOutput "❌ Terraform is not installed or not in PATH" $Red
        exit 1
    }
    
    # Check Azure CLI login
    try {
        $account = az account show 2>$null | ConvertFrom-Json
        if (-not $account) {
            throw "Not logged in"
        }
        Write-ColorOutput "✅ Azure Account: $($account.name)" $Green
        Write-ColorOutput "✅ Subscription: $($account.id)" $Green
    } catch {
        Write-ColorOutput "❌ Not logged into Azure CLI. Run 'az login'" $Red
        exit 1
    }
    
    Write-ColorOutput "✅ All prerequisites met!" $Green
}

# Function to create Terraform backend resources
function New-TerraformBackend {
    param([string]$Environment)
    
    Write-ColorOutput "🚀 Creating Terraform backend for environment: $Environment" $Blue
    
    $resourceGroup = "$ResourceGroupPrefix-$Environment"
    $storageAccount = "$StorageAccountPrefix$Environment"
    $keyVaultName = "$ProjectName-kv-$Environment"
    
    # Remove hyphens and ensure storage account name is valid
    $storageAccount = $storageAccount -replace '[^a-z0-9]', ''
    if ($storageAccount.Length -gt 24) {
        $storageAccount = $storageAccount.Substring(0, 24)
    }
    
    try {
        # Create Resource Group
        Write-ColorOutput "📦 Creating resource group: $resourceGroup" $Yellow
        az group create --name $resourceGroup --location $Location --tags Environment=$Environment Project=$ProjectName ManagedBy=terraform
        
        # Create Storage Account
        Write-ColorOutput "💾 Creating storage account: $storageAccount" $Yellow
        az storage account create `
            --resource-group $resourceGroup `
            --name $storageAccount `
            --location $Location `
            --sku Standard_LRS `
            --encryption-services blob `
            --https-only true `
            --min-tls-version TLS1_2 `
            --tags Environment=$Environment Project=$ProjectName ManagedBy=terraform
        
        # Create Storage Container
        Write-ColorOutput "📁 Creating storage container: $ContainerName" $Yellow
        az storage container create `
            --name $ContainerName `
            --account-name $storageAccount `
            --auth-mode login
        
        # Create Key Vault
        Write-ColorOutput "🔐 Creating Key Vault: $keyVaultName" $Yellow
        az keyvault create `
            --resource-group $resourceGroup `
            --name $keyVaultName `
            --location $Location `
            --enable-rbac-authorization `
            --tags Environment=$Environment Project=$ProjectName ManagedBy=terraform
        
        Write-ColorOutput "✅ Backend resources created successfully!" $Green
        Write-ColorOutput "📝 Backend Configuration:" $Blue
        Write-ColorOutput "   Resource Group: $resourceGroup" $Yellow
        Write-ColorOutput "   Storage Account: $storageAccount" $Yellow
        Write-ColorOutput "   Container: $ContainerName" $Yellow
        Write-ColorOutput "   Key Vault: $keyVaultName" $Yellow
        
    } catch {
        Write-ColorOutput "❌ Failed to create backend resources: $($_.Exception.Message)" $Red
        exit 1
    }
}

# Function to initialize Terraform
function Initialize-Terraform {
    param([string]$Environment, [string]$Layer)
    
    $layerPath = "layers/$Layer"
    $backendConfig = "$layerPath/environments/$Environment/backend.conf"
    
    if (-not (Test-Path $layerPath)) {
        Write-ColorOutput "❌ Layer path not found: $layerPath" $Red
        exit 1
    }
    
    if (-not (Test-Path $backendConfig)) {
        Write-ColorOutput "❌ Backend config not found: $backendConfig" $Red
        Write-ColorOutput "💡 Run bootstrap first: .\terraform-manager.ps1 -Action bootstrap -Environment $Environment" $Yellow
        exit 1
    }
    
    Push-Location $layerPath
    try {
        Write-ColorOutput "🔧 Initializing Terraform for $Layer layer in $Environment environment..." $Blue
        terraform init -backend-config="environments/$Environment/backend.conf" -reconfigure
        
        if ($LASTEXITCODE -ne 0) {
            throw "Terraform init failed"
        }
        
        Write-ColorOutput "✅ Terraform initialized successfully!" $Green
    } catch {
        Write-ColorOutput "❌ Terraform initialization failed: $($_.Exception.Message)" $Red
        exit 1
    } finally {
        Pop-Location
    }
}

# Function to run Terraform plan
function Invoke-TerraformPlan {
    param([string]$Environment, [string]$Layer)
    
    $layerPath = "layers/$Layer"
    $varsFile = "$layerPath/environments/$Environment/terraform.auto.tfvars"
    
    Push-Location $layerPath
    try {
        Write-ColorOutput "📋 Running Terraform plan for $Layer layer in $Environment environment..." $Blue
        
        if (Test-Path $varsFile) {
            terraform plan -var-file="environments/$Environment/terraform.auto.tfvars"
        } else {
            terraform plan
        }
        
        if ($LASTEXITCODE -ne 0) {
            throw "Terraform plan failed"
        }
        
        Write-ColorOutput "✅ Terraform plan completed successfully!" $Green
    } catch {
        Write-ColorOutput "❌ Terraform plan failed: $($_.Exception.Message)" $Red
        exit 1
    } finally {
        Pop-Location
    }
}

# Function to apply Terraform configuration
function Invoke-TerraformApply {
    param([string]$Environment, [string]$Layer)
    
    $layerPath = "layers/$Layer"
    $varsFile = "$layerPath/environments/$Environment/terraform.auto.tfvars"
    
    Push-Location $layerPath
    try {
        Write-ColorOutput "🚀 Applying Terraform configuration for $Layer layer in $Environment environment..." $Blue
        
        if (Test-Path $varsFile) {
            terraform apply -var-file="environments/$Environment/terraform.auto.tfvars" -auto-approve
        } else {
            terraform apply -auto-approve
        }
        
        if ($LASTEXITCODE -ne 0) {
            throw "Terraform apply failed"
        }
        
        Write-ColorOutput "✅ Terraform apply completed successfully!" $Green
    } catch {
        Write-ColorOutput "❌ Terraform apply failed: $($_.Exception.Message)" $Red
        exit 1
    } finally {
        Pop-Location
    }
}

# Function to destroy Terraform resources
function Remove-TerraformResources {
    param([string]$Environment, [string]$Layer)
    
    $layerPath = "layers/$Layer"
    $varsFile = "$layerPath/environments/$Environment/terraform.auto.tfvars"
    
    Write-ColorOutput "⚠️  WARNING: This will destroy all resources in $Layer layer for $Environment environment!" $Red
    $confirm = Read-Host "Type 'yes' to continue"
    
    if ($confirm -ne "yes") {
        Write-ColorOutput "❌ Destruction cancelled" $Yellow
        return
    }
    
    Push-Location $layerPath
    try {
        Write-ColorOutput "💥 Destroying Terraform resources for $Layer layer in $Environment environment..." $Red
        
        if (Test-Path $varsFile) {
            terraform destroy -var-file="environments/$Environment/terraform.auto.tfvars" -auto-approve
        } else {
            terraform destroy -auto-approve
        }
        
        if ($LASTEXITCODE -ne 0) {
            throw "Terraform destroy failed"
        }
        
        Write-ColorOutput "✅ Resources destroyed successfully!" $Green
    } catch {
        Write-ColorOutput "❌ Terraform destroy failed: $($_.Exception.Message)" $Red
        exit 1
    } finally {
        Pop-Location
    }
}

# Function to validate Terraform configuration
function Test-TerraformConfiguration {
    param([string]$Environment, [string]$Layer)
    
    $layerPath = "layers/$Layer"
    
    Push-Location $layerPath
    try {
        Write-ColorOutput "🔍 Validating Terraform configuration for $Layer layer..." $Blue
        terraform validate
        
        if ($LASTEXITCODE -ne 0) {
            throw "Terraform validate failed"
        }
        
        Write-ColorOutput "✅ Configuration is valid!" $Green
    } catch {
        Write-ColorOutput "❌ Configuration validation failed: $($_.Exception.Message)" $Red
        exit 1
    } finally {
        Pop-Location
    }
}

# Function to format Terraform files
function Format-TerraformFiles {
    Write-ColorOutput "🎨 Formatting Terraform files..." $Blue
    terraform fmt -recursive
    Write-ColorOutput "✅ Files formatted successfully!" $Green
}

# Function to show Terraform outputs
function Show-TerraformOutputs {
    param([string]$Environment, [string]$Layer)
    
    $layerPath = "layers/$Layer"
    
    Push-Location $layerPath
    try {
        Write-ColorOutput "📤 Showing Terraform outputs for $Layer layer in $Environment environment..." $Blue
        terraform output
        Write-ColorOutput "✅ Outputs displayed successfully!" $Green
    } catch {
        Write-ColorOutput "❌ Failed to show outputs: $($_.Exception.Message)" $Red
        exit 1
    } finally {
        Pop-Location
    }
}

# Function to clean local state
function Clear-LocalState {
    Write-ColorOutput "🧹 Cleaning local Terraform state and cache..." $Blue
    Get-ChildItem -Recurse -Name ".terraform" -Directory | Remove-Item -Recurse -Force
    Get-ChildItem -Recurse -Name "*.tfplan" | Remove-Item -Force
    Get-ChildItem -Recurse -Name ".terraform.lock.hcl" | Remove-Item -Force
    Write-ColorOutput "✅ Local state cleaned successfully!" $Green
}

# Function for complete deployment
function Start-CompleteDeployment {
    param([string]$Environment, [string]$Layer)
    
    Write-ColorOutput "🚀 Starting complete deployment for $Layer layer in $Environment environment..." $Blue
    
    # Initialize
    Initialize-Terraform $Environment $Layer
    
    # Plan
    Invoke-TerraformPlan $Environment $Layer
    
    # Apply
    Invoke-TerraformApply $Environment $Layer
    
    Write-ColorOutput "✅ Complete deployment finished successfully!" $Green
}

# Main script execution
try {
    Write-ColorOutput "🏗️  Terraform Infrastructure Manager for Azure" $Blue
    Write-ColorOutput "Environment: $Environment | Layer: $Layer | Action: $Action" $Yellow
    
    # Check prerequisites for all actions except clean
    if ($Action -ne "clean" -and $Action -ne "format") {
        Test-Prerequisites
    }
    
    # Set subscription if provided
    if ($SubscriptionId) {
        Write-ColorOutput "🔄 Setting Azure subscription: $SubscriptionId" $Blue
        az account set --subscription $SubscriptionId
    }
    
    # Execute action
    switch ($Action) {
        "bootstrap" { 
            New-TerraformBackend $Environment 
        }
        "init" { 
            Initialize-Terraform $Environment $Layer 
        }
        "plan" { 
            Initialize-Terraform $Environment $Layer
            Invoke-TerraformPlan $Environment $Layer 
        }
        "apply" { 
            Initialize-Terraform $Environment $Layer
            Invoke-TerraformApply $Environment $Layer 
        }
        "destroy" { 
            Initialize-Terraform $Environment $Layer
            Remove-TerraformResources $Environment $Layer 
        }
        "validate" { 
            Test-TerraformConfiguration $Environment $Layer 
        }
        "format" { 
            Format-TerraformFiles 
        }
        "output" { 
            Show-TerraformOutputs $Environment $Layer 
        }
        "clean" { 
            Clear-LocalState 
        }
        "deploy-all" { 
            Start-CompleteDeployment $Environment $Layer 
        }
        default { 
            Write-ColorOutput "❌ Unknown action: $Action" $Red
            exit 1
        }
    }
    
    Write-ColorOutput "🎉 Action '$Action' completed successfully!" $Green
    
} catch {
    Write-ColorOutput "❌ Script execution failed: $($_.Exception.Message)" $Red
    Write-ColorOutput "📚 For help, run: Get-Help .\terraform-manager.ps1" $Yellow
    exit 1
}