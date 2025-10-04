# Backend Configuration Template System

This system replaces hardcoded `PROJECT_NAME` values with dynamic variables read from `terraform.auto.tfvars` files.

## 🚀 Quick Start

### PowerShell (Recommended for Windows)

```powershell
# Generate backend configuration for specific environment/layer
.\generate-backend.ps1 -Environment dev -Layer compute

# The script will:
# 1. Read project_name, aws_region, aws_profile from terraform.auto.tfvars
# 2. Replace placeholders in backend.conf.template
# 3. Generate the actual backend.conf file
```

### Makefile (Linux/macOS/WSL)

```bash
# Generate backend configuration
make generate-backend ENV=dev LAYER=compute

# Initialize terraform (automatically generates backend)
make init ENV=dev LAYER=compute
```

## 📁 File Structure

```
terraform-infra/
├── backend.conf.template          # Template with {{placeholders}}
├── generate-backend.ps1           # PowerShell generation script
├── Makefile                      # Unix/Linux automation
├── .gitignore                    # Excludes generated backend.conf files
└── layers/
    └── compute/environments/dev/
        ├── terraform.auto.tfvars  # Contains: project_name = "myproject"
        └── backend.conf          # Generated (git-ignored)
```

## 🔧 How It Works

### 1. Template File (`backend.conf.template`)
```hcl
bucket         = "{{PROJECT_NAME}}-terraform-state-{{ENVIRONMENT}}"
key            = "{{LAYER}}/{{ENVIRONMENT}}/terraform.tfstate"
region         = "{{AWS_REGION}}"
profile        = "{{AWS_PROFILE}}"
dynamodb_table = "{{PROJECT_NAME}}-terraform-locks-{{ENVIRONMENT}}"
encrypt        = true
```

### 2. Variables Source (`terraform.auto.tfvars`)
```hcl
project_name = "myproject"
aws_region   = "us-east-1"
aws_profile  = "default"
```

### 3. Generated Output (`backend.conf`)
```hcl
bucket         = "myproject-terraform-state-dev"
key            = "compute/dev/terraform.tfstate"
region         = "us-east-1"
profile        = "default"
dynamodb_table = "myproject-terraform-locks-dev"
encrypt        = true
```

## ⚙️ Configuration

### Required Variables in terraform.auto.tfvars
```hcl
project_name = "your-project-name"  # Required
aws_region   = "us-east-1"          # Optional (defaults to us-east-1)
aws_profile  = "default"            # Optional (defaults to default)
```

### Supported Placeholders
- `{{PROJECT_NAME}}` → `project_name` from terraform.auto.tfvars
- `{{ENVIRONMENT}}` → Environment parameter (dev, qa, uat, prod)
- `{{LAYER}}` → Layer parameter (networking, security, compute, data)
- `{{AWS_REGION}}` → `aws_region` from terraform.auto.tfvars
- `{{AWS_PROFILE}}` → `aws_profile` from terraform.auto.tfvars

## 🔐 Security Benefits

1. **No Hardcoded Values**: PROJECT_NAME is read dynamically
2. **Version Control Safe**: Generated files are git-ignored
3. **Environment Isolation**: Each environment has its own backend
4. **Consistent Naming**: All resources follow the same naming pattern

## 🛠️ Usage Examples

### Generate for Different Environments
```powershell
.\generate-backend.ps1 -Environment dev -Layer compute
.\generate-backend.ps1 -Environment prod -Layer networking
.\generate-backend.ps1 -Environment qa -Layer data
```

### Use with Terraform
```bash
# Generate backend first
.\generate-backend.ps1 -Environment dev -Layer compute

# Then use with terraform
cd layers/compute
terraform init -backend-config=environments/dev/backend.conf
terraform plan -var-file=environments/dev/terraform.auto.tfvars
terraform apply -var-file=environments/dev/terraform.auto.tfvars
```

## 🔍 Troubleshooting

### Error: "project_name not found"
Ensure your `terraform.auto.tfvars` contains:
```hcl
project_name = "your-project-name"
```

### Error: "Template file not found"
Ensure `backend.conf.template` exists in the root directory.

### PowerShell Execution Policy Error
Run: `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`

## 📝 Notes

- Generated `backend.conf` files are excluded from version control
- The `backend.conf.template` file is version controlled
- Changes to `project_name` require regenerating all backend configurations
- Script validates all required files exist before generation