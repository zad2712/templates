# PowerShell Script for Terraform Infrastructure Management
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
    [string]$AwsProfile = "default",
    
    [Parameter(Mandatory=$false)]
    [string]$AwsRegion = "us-east-1"
)

# Project configuration - UPDATE THESE VALUES
$ProjectName = "myproject"
$StateBucketPrefix = "$ProjectName-terraform-state"
$LockTablePrefix = "$ProjectName-terraform-locks"

# Colors for output
$Colors = @{
    Red = [ConsoleColor]::Red
    Green = [ConsoleColor]::Green
    Yellow = [ConsoleColor]::Yellow
    Blue = [ConsoleColor]::Blue
    White = [ConsoleColor]::White
}

function Write-ColorOutput {
    param(
        [string]$Message,
        [ConsoleColor]$Color = [ConsoleColor]::White
    )
    Write-Host $Message -ForegroundColor $Color
}

function Test-AwsCommand {
    try {
        aws --version | Out-Null
        return $true
    }
    catch {
        Write-ColorOutput "Error: AWS CLI not found. Please install AWS CLI first." $Colors.Red
        return $false
    }
}

function Test-TerraformCommand {
    try {
        terraform version | Out-Null
        return $true
    }
    catch {
        Write-ColorOutput "Error: Terraform not found. Please install Terraform first." $Colors.Red
        return $false
    }
}

function Invoke-Bootstrap {
    Write-ColorOutput "Bootstrapping AWS infrastructure for $Environment environment..." $Colors.Yellow
    
    # Check if S3 bucket exists
    $bucketName = "$StateBucketPrefix-$Environment"
    try {
        aws s3api head-bucket --bucket $bucketName --profile $AwsProfile 2>$null
        Write-ColorOutput "S3 bucket $bucketName already exists" $Colors.Blue
    }
    catch {
        Write-ColorOutput "Creating S3 bucket: $bucketName" $Colors.Blue
        aws s3api create-bucket --bucket $bucketName --region $AwsRegion --profile $AwsProfile
        
        if ($AwsRegion -ne "us-east-1") {
            aws s3api create-bucket --bucket $bucketName --region $AwsRegion --profile $AwsProfile --create-bucket-configuration LocationConstraint=$AwsRegion
        }
        
        aws s3api put-bucket-versioning --bucket $bucketName --versioning-configuration Status=Enabled --profile $AwsProfile
        aws s3api put-bucket-encryption --bucket $bucketName --server-side-encryption-configuration '{\"Rules\":[{\"ApplyServerSideEncryptionByDefault\":{\"SSEAlgorithm\":\"AES256\"}}]}' --profile $AwsProfile
    }
    
    # Check if DynamoDB table exists
    $tableName = "$LockTablePrefix-$Environment"
    try {
        aws dynamodb describe-table --table-name $tableName --profile $AwsProfile --region $AwsRegion 2>$null
        Write-ColorOutput "DynamoDB table $tableName already exists" $Colors.Blue
    }
    catch {
        Write-ColorOutput "Creating DynamoDB table: $tableName" $Colors.Blue
        aws dynamodb create-table --table-name $tableName --attribute-definitions AttributeName=LockID,AttributeType=S --key-schema AttributeName=LockID,KeyType=HASH --billing-mode PAY_PER_REQUEST --profile $AwsProfile --region $AwsRegion
    }
    
    Write-ColorOutput "Bootstrap completed for $Environment environment" $Colors.Green
}

function Invoke-Init {
    Write-ColorOutput "Initializing Terraform for $Layer/$Environment..." $Colors.Yellow
    
    $backendConfig = Get-Content "layers\$Layer\environments\$Environment\backend.conf" | ForEach-Object { $_ -replace "PROJECT_NAME", $ProjectName }
    $tempBackendFile = New-TemporaryFile
    $backendConfig | Out-File -FilePath $tempBackendFile.FullName -Encoding UTF8
    
    Push-Location "layers\$Layer"
    try {
        terraform init -backend-config=$($tempBackendFile.FullName) -reconfigure
        Write-ColorOutput "Terraform initialized for $Layer/$Environment" $Colors.Green
    }
    finally {
        Pop-Location
        Remove-Item $tempBackendFile.FullName -ErrorAction SilentlyContinue
    }
}

function Invoke-Plan {
    Write-ColorOutput "Planning Terraform changes for $Layer/$Environment..." $Colors.Yellow
    
    Push-Location "layers\$Layer"
    try {
        terraform plan -var-file="environments\$Environment\terraform.auto.tfvars" -out="$Environment.tfplan"
        Write-ColorOutput "Plan completed for $Layer/$Environment" $Colors.Green
    }
    finally {
        Pop-Location
    }
}

function Invoke-Apply {
    Write-ColorOutput "Applying Terraform changes for $Layer/$Environment..." $Colors.Yellow
    
    Push-Location "layers\$Layer"
    try {
        terraform apply "$Environment.tfplan"
        Write-ColorOutput "Apply completed for $Layer/$Environment" $Colors.Green
    }
    finally {
        Pop-Location
    }
}

function Invoke-Destroy {
    Write-ColorOutput "WARNING: This will destroy all resources for $Layer/$Environment!" $Colors.Red
    $confirm = Read-Host "Are you sure? Type 'yes' to continue"
    
    if ($confirm -eq "yes") {
        Push-Location "layers\$Layer"
        try {
            terraform destroy -var-file="environments\$Environment\terraform.auto.tfvars" -auto-approve
            Write-ColorOutput "Destroy completed for $Layer/$Environment" $Colors.Green
        }
        finally {
            Pop-Location
        }
    } else {
        Write-ColorOutput "Destroy cancelled" $Colors.Yellow
    }
}

function Invoke-Validate {
    Write-ColorOutput "Validating Terraform configuration for $Layer..." $Colors.Yellow
    
    Push-Location "layers\$Layer"
    try {
        terraform validate
        Write-ColorOutput "Validation completed for $Layer" $Colors.Green
    }
    finally {
        Pop-Location
    }
}

function Invoke-Format {
    Write-ColorOutput "Formatting Terraform files..." $Colors.Yellow
    terraform fmt -recursive .
    Write-ColorOutput "Formatting completed" $Colors.Green
}

function Invoke-Output {
    Write-ColorOutput "Showing outputs for $Layer/$Environment..." $Colors.Yellow
    
    Push-Location "layers\$Layer"
    try {
        terraform output
    }
    finally {
        Pop-Location
    }
}

function Invoke-Clean {
    Write-ColorOutput "Cleaning up temporary files..." $Colors.Yellow
    
    Get-ChildItem -Recurse -Name "*.tfplan" | Remove-Item -Force
    Get-ChildItem -Recurse -Name ".terraform" -Directory | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    Get-ChildItem -Recurse -Name ".terraform.lock.hcl" | Remove-Item -Force -ErrorAction SilentlyContinue
    
    Write-ColorOutput "Cleanup completed" $Colors.Green
}

function Invoke-DeployAll {
    Write-ColorOutput "Deploying all layers for $Environment environment..." $Colors.Yellow
    
    $layers = @("networking", "security", "compute", "data")
    
    foreach ($currentLayer in $layers) {
        Write-ColorOutput "Processing layer: $currentLayer" $Colors.Blue
        
        & $PSCommandPath -Action init -Environment $Environment -Layer $currentLayer -AwsProfile $AwsProfile -AwsRegion $AwsRegion
        & $PSCommandPath -Action plan -Environment $Environment -Layer $currentLayer -AwsProfile $AwsProfile -AwsRegion $AwsRegion
        & $PSCommandPath -Action apply -Environment $Environment -Layer $currentLayer -AwsProfile $AwsProfile -AwsRegion $AwsRegion
    }
    
    Write-ColorOutput "All layers deployed for $Environment environment" $Colors.Green
}

# Main execution
if (-not (Test-AwsCommand)) {
    exit 1
}

if (-not (Test-TerraformCommand)) {
    exit 1
}

switch ($Action) {
    "bootstrap" { Invoke-Bootstrap }
    "init" { Invoke-Init }
    "plan" { Invoke-Plan }
    "apply" { Invoke-Apply }
    "destroy" { Invoke-Destroy }
    "validate" { Invoke-Validate }
    "format" { Invoke-Format }
    "output" { Invoke-Output }
    "clean" { Invoke-Clean }
    "deploy-all" { Invoke-DeployAll }
}