# Generate Backend Configuration from Template and terraform.auto.tfvars
# This script reads variables from terraform.auto.tfvars and generates backend.conf from template

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("dev", "qa", "uat", "prod")]
    [string]$Environment,
    
    [Parameter(Mandatory=$true)]
    [ValidateSet("networking", "security", "compute", "data")]
    [string]$Layer,
    
    [Parameter(Mandatory=$false)]
    [string]$TemplatePath = "backend.conf.template"
)

# Function to extract variable value from terraform.auto.tfvars
function Get-TerraformVariable {
    param(
        [string]$FilePath,
        [string]$VariableName
    )
    
    if (Test-Path $FilePath) {
        $content = Get-Content $FilePath
        foreach ($line in $content) {
            if ($line -match "^\s*$VariableName\s*=\s*`"(.+)`"") {
                return $matches[1]
            }
        }
    }
    return $null
}

# Validate template exists
if (-not (Test-Path $TemplatePath)) {
    Write-Host "Error: Template file '$TemplatePath' not found" -ForegroundColor Red
    exit 1
}

# Build paths
$tfvarsPath = "layers\$Layer\environments\$Environment\terraform.auto.tfvars"
$backendPath = "layers\$Layer\environments\$Environment\backend.conf"

# Validate terraform.auto.tfvars exists
if (-not (Test-Path $tfvarsPath)) {
    Write-Host "Error: terraform.auto.tfvars file not found at: $tfvarsPath" -ForegroundColor Red
    exit 1
}

Write-Host "Reading configuration from $tfvarsPath..." -ForegroundColor Cyan

# Extract values from terraform.auto.tfvars
$projectName = Get-TerraformVariable -FilePath $tfvarsPath -VariableName "project_name"
$awsRegion = Get-TerraformVariable -FilePath $tfvarsPath -VariableName "aws_region"
$awsProfile = Get-TerraformVariable -FilePath $tfvarsPath -VariableName "aws_profile"

# Use defaults if not found
if (-not $awsRegion) { $awsRegion = "us-east-1" }
if (-not $awsProfile) { $awsProfile = "default" }

if (-not $projectName) {
    Write-Host "Error: project_name not found in $tfvarsPath" -ForegroundColor Red
    exit 1
}

Write-Host "Found configuration:" -ForegroundColor Green
Write-Host "  Project Name: $projectName" -ForegroundColor White
Write-Host "  AWS Region: $awsRegion" -ForegroundColor White
Write-Host "  AWS Profile: $awsProfile" -ForegroundColor White
Write-Host "  Environment: $Environment" -ForegroundColor White
Write-Host "  Layer: $Layer" -ForegroundColor White

# Read template
$template = Get-Content $TemplatePath -Raw

# Replace placeholders
$backendContent = $template
$backendContent = $backendContent -replace '\{\{PROJECT_NAME\}\}', $projectName
$backendContent = $backendContent -replace '\{\{ENVIRONMENT\}\}', $Environment
$backendContent = $backendContent -replace '\{\{LAYER\}\}', $Layer
$backendContent = $backendContent -replace '\{\{AWS_REGION\}\}', $awsRegion
$backendContent = $backendContent -replace '\{\{AWS_PROFILE\}\}', $awsProfile

# Ensure output directory exists
$backendDir = Split-Path $backendPath -Parent
if (-not (Test-Path $backendDir)) {
    New-Item -Path $backendDir -ItemType Directory -Force | Out-Null
}

# Write backend configuration
Set-Content -Path $backendPath -Value $backendContent -NoNewline

Write-Host "`nBackend configuration generated: $backendPath" -ForegroundColor Green
Write-Host "You can now run:" -ForegroundColor Yellow
Write-Host "  cd layers\$Layer" -ForegroundColor Cyan
Write-Host "  terraform init -backend-config=environments\$Environment\backend.conf" -ForegroundColor Cyan