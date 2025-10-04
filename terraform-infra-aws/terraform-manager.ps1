# Terraform AWS Infrastructure Management Script
# Author: Diego A. Zarate
# Description: PowerShell script for managing Terraform operations for AWS infrastructure layers

param(
    [Parameter(Mandatory=$false, Position=0)]
    [string]$Command,
    
    [Parameter(Mandatory=$false, Position=1)]
    [string]$Layer,
    
    [Parameter(Mandatory=$false, Position=2)]
    [string]$Environment,
    
    [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
    [string[]]$ExtraArgs = @()
)

# Set error handling
$ErrorActionPreference = "Stop"

# Script configuration
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = $ScriptDir

# Available options
$ValidLayers = @("networking", "security", "data", "compute")
$ValidEnvironments = @("dev", "qa", "uat", "prod") 
$ValidCommands = @("init", "validate", "plan", "apply", "destroy", "output", "format", "lint", "clean")

# Color functions for output
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    
    $ColorMap = @{
        "Red" = "Red"
        "Green" = "Green" 
        "Yellow" = "Yellow"
        "Blue" = "Blue"
        "White" = "White"
        "Cyan" = "Cyan"
    }
    
    Write-Host $Message -ForegroundColor $ColorMap[$Color]
}

function Write-Info {
    param([string]$Message)
    Write-ColorOutput "[INFO] $Message" "Blue"
}

function Write-Success {
    param([string]$Message)
    Write-ColorOutput "[SUCCESS] $Message" "Green"
}

function Write-Warning {
    param([string]$Message)
    Write-ColorOutput "[WARNING] $Message" "Yellow"
}

function Write-ErrorMessage {
    param([string]$Message)
    Write-ColorOutput "[ERROR] $Message" "Red"
}

# Usage function
function Show-Usage {
    Write-ColorOutput "AWS Terraform Infrastructure Management" "Blue"
    Write-ColorOutput "Author: Diego A. Zarate" "Blue"
    Write-Host ""
    Write-Host "Usage: .\terraform-manager.ps1 <command> <layer> <environment> [options]"
    Write-Host ""
    Write-ColorOutput "Commands:" "Yellow"
    Write-Host "  init      - Initialize Terraform for the specified layer and environment"
    Write-Host "  validate  - Validate Terraform configuration"
    Write-Host "  plan      - Create execution plan"
    Write-Host "  apply     - Apply Terraform changes"
    Write-Host "  destroy   - Destroy Terraform-managed infrastructure"
    Write-Host "  output    - Show output values"
    Write-Host "  format    - Format Terraform files"
    Write-Host "  lint      - Run terraform validate and fmt check"
    Write-Host "  clean     - Clean temporary files and .terraform directories"
    Write-Host ""
    Write-ColorOutput "Layers:" "Yellow"
    foreach ($layer in $ValidLayers) {
        Write-Host "  $layer"
    }
    Write-Host ""
    Write-ColorOutput "Environments:" "Yellow"
    foreach ($env in $ValidEnvironments) {
        Write-Host "  $env"
    }
    Write-Host ""
    Write-ColorOutput "Examples:" "Yellow"
    Write-Host "  .\terraform-manager.ps1 init networking dev"
    Write-Host "  .\terraform-manager.ps1 plan security prod"
    Write-Host "  .\terraform-manager.ps1 apply compute qa -auto-approve"
    Write-Host "  .\terraform-manager.ps1 destroy data uat"
    Write-Host "  .\terraform-manager.ps1 output networking prod"
    Write-Host ""
    Write-ColorOutput "Special Commands:" "Yellow"
    Write-Host "  .\terraform-manager.ps1 init-all <environment>     - Initialize all layers for an environment"
    Write-Host "  .\terraform-manager.ps1 plan-all <environment>     - Plan all layers for an environment"
    Write-Host "  .\terraform-manager.ps1 apply-all <environment>    - Apply all layers for an environment (in order)"
    Write-Host "  .\terraform-manager.ps1 format-all                 - Format all Terraform files"
    Write-Host "  .\terraform-manager.ps1 lint-all                   - Lint all Terraform configurations"
}

# Validation functions
function Test-Layer {
    param([string]$LayerName)
    
    if ($LayerName -notin $ValidLayers) {
        Write-ErrorMessage "Invalid layer: $LayerName"
        Write-Host "Available layers: $($ValidLayers -join ', ')"
        exit 1
    }
}

function Test-Environment {
    param([string]$EnvironmentName)
    
    if ($EnvironmentName -notin $ValidEnvironments) {
        Write-ErrorMessage "Invalid environment: $EnvironmentName"
        Write-Host "Available environments: $($ValidEnvironments -join ', ')"
        exit 1
    }
}

function Test-Command {
    param([string]$CommandName)
    
    if ($CommandName -notin $ValidCommands) {
        Write-ErrorMessage "Invalid command: $CommandName"
        Write-Host "Available commands: $($ValidCommands -join ', ')"
        exit 1
    }
}

# Check dependencies
function Test-Dependencies {
    $MissingDeps = @()
    
    # Check for Terraform
    try {
        $null = Get-Command terraform -ErrorAction Stop
    }
    catch {
        $MissingDeps += "terraform"
    }
    
    # Check for AWS CLI
    try {
        $null = Get-Command aws -ErrorAction Stop
    }
    catch {
        $MissingDeps += "aws-cli"
    }
    
    if ($MissingDeps.Count -gt 0) {
        Write-ErrorMessage "Missing dependencies: $($MissingDeps -join ', ')"
        Write-Host "Please install the missing dependencies and try again."
        exit 1
    }
}

# Get layer directory path
function Get-LayerPath {
    param(
        [string]$Layer,
        [string]$Environment
    )
    
    return Join-Path $ProjectRoot "layers\$Layer\environments\$Environment"
}

# Change to layer directory
function Set-LayerDirectory {
    param(
        [string]$Layer,
        [string]$Environment
    )
    
    $LayerPath = Get-LayerPath $Layer $Environment
    
    if (-not (Test-Path $LayerPath)) {
        Write-ErrorMessage "Layer directory does not exist: $LayerPath"
        exit 1
    }
    
    Set-Location $LayerPath
    Write-Info "Changed to directory: $LayerPath"
}

# Run Terraform command
function Invoke-TerraformCommand {
    param(
        [string]$Command,
        [string]$Layer,
        [string]$Environment,
        [string[]]$AdditionalArgs = @()
    )
    
    Set-LayerDirectory $Layer $Environment
    
    switch ($Command) {
        "init" {
            Write-Info "Initializing Terraform for $Layer ($Environment)..."
            & terraform init -backend-config=backend.conf @AdditionalArgs
        }
        "validate" {
            Write-Info "Validating Terraform configuration for $Layer ($Environment)..."
            & terraform validate
        }
        "plan" {
            Write-Info "Planning Terraform changes for $Layer ($Environment)..."
            & terraform plan @AdditionalArgs
        }
        "apply" {
            Write-Info "Applying Terraform changes for $Layer ($Environment)..."
            & terraform apply @AdditionalArgs
        }
        "destroy" {
            Write-Warning "This will destroy resources in $Layer ($Environment)!"
            $Confirm = Read-Host "Are you sure? (yes/no)"
            if ($Confirm -eq "yes") {
                & terraform destroy @AdditionalArgs
            } else {
                Write-Info "Destroy cancelled."
            }
        }
        "output" {
            Write-Info "Getting outputs for $Layer ($Environment)..."
            & terraform output @AdditionalArgs
        }
        "format" {
            Write-Info "Formatting Terraform files for $Layer ($Environment)..."
            & terraform fmt -recursive
        }
        "lint" {
            Write-Info "Linting Terraform configuration for $Layer ($Environment)..."
            & terraform fmt -check=true -diff=true
            & terraform validate
        }
        "clean" {
            Write-Info "Cleaning temporary files for $Layer ($Environment)..."
            Remove-Item -Path ".terraform", ".terraform.lock.hcl", "terraform.tfplan" -Recurse -Force -ErrorAction SilentlyContinue
        }
        default {
            Write-ErrorMessage "Unknown command: $Command"
            exit 1
        }
    }
}

# Special commands for multiple layers/environments
function Invoke-SpecialCommand {
    param(
        [string]$Command,
        [string]$Environment = ""
    )
    
    switch ($Command) {
        "init-all" {
            Test-Environment $Environment
            Write-Info "Initializing all layers for $Environment environment..."
            foreach ($layer in $ValidLayers) {
                Invoke-TerraformCommand "init" $layer $Environment
            }
        }
        "plan-all" {
            Test-Environment $Environment
            Write-Info "Planning all layers for $Environment environment..."
            foreach ($layer in $ValidLayers) {
                Invoke-TerraformCommand "plan" $layer $Environment
            }
        }
        "apply-all" {
            Test-Environment $Environment
            Write-Warning "This will apply changes to ALL layers in $Environment environment!"
            $Confirm = Read-Host "Are you sure? (yes/no)"
            if ($Confirm -eq "yes") {
                Write-Info "Applying all layers for $Environment environment (in dependency order)..."
                foreach ($layer in $ValidLayers) {
                    Invoke-TerraformCommand "apply" $layer $Environment @("-auto-approve")
                }
            } else {
                Write-Info "Apply cancelled."
            }
        }
        "format-all" {
            Write-Info "Formatting all Terraform files..."
            Set-Location $ProjectRoot
            & terraform fmt -recursive
        }
        "lint-all" {
            Write-Info "Linting all Terraform configurations..."
            foreach ($layer in $ValidLayers) {
                foreach ($env in $ValidEnvironments) {
                    $LayerPath = Get-LayerPath $layer $env
                    if (Test-Path $LayerPath) {
                        Invoke-TerraformCommand "lint" $layer $env
                    }
                }
            }
        }
        default {
            Write-ErrorMessage "Unknown special command: $Command"
            exit 1
        }
    }
}

# Main execution logic
try {
    # Show help if no parameters or help requested
    if (-not $Command -or $Command -eq "-h" -or $Command -eq "--help") {
        Show-Usage
        exit 0
    }
    
    # Check dependencies
    Test-Dependencies
    
    # Handle special commands
    $SpecialCommands = @("init-all", "plan-all", "apply-all", "format-all", "lint-all")
    
    if ($Command -in $SpecialCommands) {
        if ($Command -in @("init-all", "plan-all", "apply-all") -and -not $Layer) {
            Write-ErrorMessage "Missing environment for $Command"
            Show-Usage
            exit 1
        }
        
        if ($Command -in @("format-all", "lint-all")) {
            Invoke-SpecialCommand $Command
        } else {
            Invoke-SpecialCommand $Command $Layer
        }
        exit 0
    }
    
    # Validate regular command parameters
    if (-not $Layer -or -not $Environment) {
        Write-ErrorMessage "Missing required arguments"
        Show-Usage
        exit 1
    }
    
    # Validate inputs
    Test-Command $Command
    Test-Layer $Layer
    Test-Environment $Environment
    
    # Run the command
    Write-Info "Running $Command for $Layer layer in $Environment environment..."
    Invoke-TerraformCommand $Command $Layer $Environment $ExtraArgs
    Write-Success "Command completed successfully!"
    
} catch {
    Write-ErrorMessage "An error occurred: $($_.Exception.Message)"
    exit 1
}