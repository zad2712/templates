# Prerequisites

Before deploying the AWS Terraform Infrastructure, ensure you have all the necessary tools, access, and configurations in place.

## Required Tools

### 1. Terraform

**Minimum Version**: 1.9.0

#### Installation

**macOS (using Homebrew)**
```bash
brew tap hashicorp/tap
brew install hashicorp/tap/terraform
```

**Ubuntu/Debian**
```bash
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform
```

**Windows (using Chocolatey)**
```powershell
choco install terraform
```

**Manual Installation**
1. Download from [Terraform Downloads](https://www.terraform.io/downloads)
2. Extract and add to PATH
3. Verify installation:
   ```bash
   terraform version
   ```

#### Verification
```bash
terraform version
# Expected output:
# Terraform v1.9.0 or higher
```

### 2. AWS CLI

**Minimum Version**: 2.0

#### Installation

**macOS**
```bash
# Using Homebrew
brew install awscli

# Or download installer
curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
sudo installer -pkg AWSCLIV2.pkg -target /
```

**Linux**
```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```

**Windows**
```powershell
# Download and install from: https://awscli.amazonaws.com/AWSCLIV2.msi
# Or use PowerShell
Invoke-WebRequest -Uri "https://awscli.amazonaws.com/AWSCLIV2.msi" -Outfile "AWSCLIV2.msi"
Start-Process msiexec.exe -ArgumentList "/i AWSCLIV2.msi /quiet" -Wait
```

#### Verification
```bash
aws --version
# Expected output:
# aws-cli/2.x.x Python/3.x.x
```

### 3. Git

Required for cloning the repository and version control.

#### Installation
```bash
# macOS
brew install git

# Ubuntu/Debian
sudo apt update && sudo apt install git

# CentOS/RHEL
sudo yum install git

# Windows
# Download from: https://git-scm.com/download/win
```

#### Verification
```bash
git --version
# Expected output:
# git version 2.x.x
```

### 4. Optional Tools

#### kubectl (for EKS management)
```bash
# macOS
brew install kubectl

# Linux
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Windows
choco install kubernetes-cli
```

#### jq (for JSON processing)
```bash
# macOS
brew install jq

# Ubuntu/Debian
sudo apt install jq

# Windows
choco install jq
```

#### Docker (for local testing)
```bash
# Installation varies by platform
# See: https://docs.docker.com/get-docker/
```

## AWS Account Requirements

### 1. AWS Account Setup

You need an AWS account with appropriate permissions and service limits.

#### Account Checklist
- [ ] Active AWS account
- [ ] Billing information configured
- [ ] Service quotas reviewed
- [ ] Cost budgets and alerts configured

### 2. IAM Permissions

The deployment requires extensive AWS permissions. For production environments, create a dedicated deployment role.

#### Required Service Permissions
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:*",
        "ecs:*",
        "eks:*",
        "lambda:*",
        "apigateway:*",
        "rds:*",
        "dynamodb:*",
        "s3:*",
        "iam:*",
        "kms:*",
        "secretsmanager:*",
        "wafv2:*",
        "cloudtrail:*",
        "logs:*",
        "cloudwatch:*",
        "elasticache:*",
        "kinesis:*",
        "application-autoscaling:*",
        "elasticloadbalancing:*",
        "cloudfront:*",
        "route53:*",
        "backup:*"
      ],
      "Resource": "*"
    }
  ]
}
```

#### Deployment Role Creation (Recommended)

1. **Create IAM Role**
   ```bash
   aws iam create-role \
     --role-name TerraformDeploymentRole \
     --assume-role-policy-document file://trust-policy.json
   ```

2. **Trust Policy** (`trust-policy.json`)
   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Effect": "Allow",
         "Principal": {
           "AWS": "arn:aws:iam::ACCOUNT-ID:user/YOUR-USER"
         },
         "Action": "sts:AssumeRole"
       }
     ]
   }
   ```

3. **Attach Policies**
   ```bash
   aws iam attach-role-policy \
     --role-name TerraformDeploymentRole \
     --policy-arn arn:aws:iam::aws:policy/PowerUserAccess
   
   aws iam attach-role-policy \
     --role-name TerraformDeploymentRole \
     --policy-arn arn:aws:iam::aws:policy/IAMFullAccess
   ```

### 3. Service Quotas

Verify and request increases for the following service quotas:

#### EC2 Quotas
```bash
# Check current limits
aws service-quotas get-service-quota \
  --service-code ec2 \
  --quota-code L-1216C47A  # Running On-Demand instances

# Request increase if needed
aws service-quotas request-service-quota-increase \
  --service-code ec2 \
  --quota-code L-1216C47A \
  --desired-value 100
```

#### Common Quota Requirements

| Service | Quota | Recommended Minimum |
|---------|-------|-------------------|
| EC2 On-Demand Instances | L-1216C47A | 50 |
| VPC per Region | L-F678F1CE | 5 |
| Internet Gateways per Region | L-A4707A72 | 5 |
| NAT Gateways per AZ | L-FE5A380F | 5 |
| Security Groups per VPC | L-E79EC296 | 60 |
| Rules per Security Group | L-0EA8095F | 120 |
| RDS DB Instances | L-7B6409FD | 40 |
| Lambda Function Count | L-2E09F805 | 1000 |

## AWS Credentials Configuration

### 1. AWS Credentials Setup

#### Method 1: AWS CLI Configuration (Recommended)
```bash
aws configure
# AWS Access Key ID [None]: YOUR_ACCESS_KEY
# AWS Secret Access Key [None]: YOUR_SECRET_KEY
# Default region name [None]: us-east-1
# Default output format [None]: json
```

#### Method 2: Environment Variables
```bash
export AWS_ACCESS_KEY_ID="YOUR_ACCESS_KEY"
export AWS_SECRET_ACCESS_KEY="YOUR_SECRET_KEY"
export AWS_DEFAULT_REGION="us-east-1"
```

#### Method 3: IAM Role (Production Recommended)
```bash
# Assume role
aws sts assume-role \
  --role-arn arn:aws:iam::ACCOUNT-ID:role/TerraformDeploymentRole \
  --role-session-name terraform-deployment

# Export credentials from assume-role output
export AWS_ACCESS_KEY_ID="TEMPORARY_ACCESS_KEY"
export AWS_SECRET_ACCESS_KEY="TEMPORARY_SECRET_KEY"
export AWS_SESSION_TOKEN="TEMPORARY_SESSION_TOKEN"
```

### 2. Credential Verification
```bash
# Test AWS access
aws sts get-caller-identity

# Expected output:
{
    "UserId": "AIDACKCEVSQ6C2EXAMPLE",
    "Account": "123456789012",
    "Arn": "arn:aws:iam::123456789012:user/DevAdmin"
}
```

### 3. Multi-Factor Authentication (MFA)

For enhanced security, configure MFA:

```bash
# Get MFA token
aws sts get-session-token \
  --serial-number arn:aws:iam::ACCOUNT-ID:mfa/USER-NAME \
  --token-code MFA-CODE

# Use temporary credentials
export AWS_ACCESS_KEY_ID="TEMPORARY_KEY"
export AWS_SECRET_ACCESS_KEY="TEMPORARY_SECRET"
export AWS_SESSION_TOKEN="TEMPORARY_TOKEN"
```

## Network Requirements

### 1. Internet Connectivity

Ensure stable internet connection for:
- Downloading Terraform providers
- Accessing AWS APIs
- Pulling container images
- Downloading packages and dependencies

### 2. Firewall Configuration

If behind a corporate firewall, ensure access to:

#### AWS Endpoints
```
*.amazonaws.com (port 443)
*.s3.amazonaws.com (port 443)
registry.terraform.io (port 443)
releases.hashicorp.com (port 443)
```

#### Container Registries
```
*.dkr.ecr.*.amazonaws.com (port 443)
docker.io (port 443)
registry-1.docker.io (port 443)
```

### 3. VPN/Proxy Configuration

If using VPN or proxy:

```bash
# Configure git for proxy
git config --global http.proxy http://proxy.company.com:8080
git config --global https.proxy http://proxy.company.com:8080

# Configure AWS CLI for proxy
export HTTP_PROXY=http://proxy.company.com:8080
export HTTPS_PROXY=http://proxy.company.com:8080
export NO_PROXY=localhost,127.0.0.1
```

## Development Environment

### 1. Operating System Support

The infrastructure supports deployment from:
- **macOS**: 10.15+ (Catalina)
- **Linux**: Ubuntu 18.04+, CentOS 7+, Amazon Linux 2
- **Windows**: Windows 10+ (with WSL2 recommended)

### 2. Resource Requirements

#### Minimum System Requirements
- **CPU**: 2 cores
- **RAM**: 4 GB
- **Disk**: 10 GB free space
- **Network**: Stable internet connection

#### Recommended System Requirements
- **CPU**: 4+ cores
- **RAM**: 8+ GB
- **Disk**: 20+ GB free space (SSD preferred)
- **Network**: High-speed internet connection

### 3. Editor/IDE Setup

#### VS Code (Recommended)
```bash
# Install VS Code extensions
code --install-extension HashiCorp.terraform
code --install-extension ms-vscode.vscode-json
code --install-extension redhat.vscode-yaml
code --install-extension ms-kubernetes-tools.vscode-kubernetes-tools
```

#### Vim/Neovim
```bash
# Install Terraform syntax highlighting
git clone https://github.com/hashivim/vim-terraform.git ~/.vim/pack/plugins/start/vim-terraform
```

## Security Requirements

### 1. Workstation Security

#### Security Checklist
- [ ] Operating system up to date
- [ ] Antivirus software installed and updated
- [ ] Full disk encryption enabled
- [ ] Strong passwords/passphrases
- [ ] Automatic screen lock configured
- [ ] VPN configured for remote access

### 2. Credential Security

#### Best Practices
- **Never commit credentials to version control**
- **Use IAM roles instead of long-term keys when possible**
- **Rotate access keys regularly**
- **Enable MFA on all AWS accounts**
- **Use AWS SSO for team access**

#### Credential Storage
```bash
# Use AWS CLI credential files
~/.aws/credentials
~/.aws/config

# Or environment variables
# But never hardcode in scripts!
```

### 3. Network Security

#### VPN Requirements (if applicable)
- Company VPN connected
- Split tunneling configured appropriately
- DNS resolution working for AWS services

## Project-Specific Requirements

### 1. Repository Access

```bash
# Clone repository
git clone <repository-url>
cd terraform-infra-aws

# Verify repository structure
ls -la
# Should see: layers/, modules/, docs/, README.md
```

### 2. Configuration Files

#### Required Configuration Files
- `terraform.auto.tfvars` - Variable definitions
- `backend.conf` - Terraform backend configuration
- `versions.tf` - Provider version constraints

#### Example Directory Structure
```
layers/networking/environments/dev/
├── backend.conf
├── terraform.auto.tfvars
└── versions.tf (optional override)
```

### 3. State Storage Preparation

#### S3 Bucket for Terraform State
```bash
# Create state bucket
aws s3 mb s3://your-terraform-state-bucket --region us-east-1

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket your-terraform-state-bucket \
  --versioning-configuration Status=Enabled

# Enable encryption
aws s3api put-bucket-encryption \
  --bucket your-terraform-state-bucket \
  --server-side-encryption-configuration '{
    "Rules": [
      {
        "ApplyServerSideEncryptionByDefault": {
          "SSEAlgorithm": "AES256"
        }
      }
    ]
  }'
```

#### DynamoDB Table for State Locking
```bash
# Create lock table
aws dynamodb create-table \
  --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
  --region us-east-1
```

## Validation Checklist

Before proceeding with deployment, verify:

### Tool Installation
- [ ] Terraform >= 1.9.0 installed and in PATH
- [ ] AWS CLI >= 2.0 installed and configured
- [ ] Git installed and configured
- [ ] kubectl installed (if using EKS)

### AWS Account Setup
- [ ] AWS account accessible
- [ ] Appropriate IAM permissions configured
- [ ] Service quotas verified/increased
- [ ] Billing alerts configured

### Credentials and Access
- [ ] AWS credentials configured and tested
- [ ] Multi-factor authentication enabled
- [ ] Network connectivity to AWS services verified
- [ ] Corporate firewall/proxy configured (if applicable)

### Project Setup
- [ ] Repository cloned successfully
- [ ] S3 bucket for Terraform state created
- [ ] DynamoDB table for state locking created
- [ ] Backend configuration files prepared

### Security
- [ ] Workstation security measures in place
- [ ] Credential security best practices followed
- [ ] Network security configured

## Getting Help

If you encounter issues during prerequisite setup:

1. **Tool Installation Issues**
   - Check official documentation for each tool
   - Verify system compatibility
   - Consider using package managers (brew, apt, yum, choco)

2. **AWS Access Issues**
   - Verify account status and billing
   - Check IAM permissions
   - Review AWS support documentation

3. **Network Issues**
   - Test internet connectivity
   - Verify firewall/proxy configuration
   - Check corporate network policies

4. **Credential Issues**
   - Verify AWS CLI configuration
   - Test with `aws sts get-caller-identity`
   - Check for MFA requirements

---

**Next Step**: Once all prerequisites are met, proceed to the [Getting Started Guide](./getting-started.md) to begin your infrastructure deployment.