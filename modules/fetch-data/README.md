# Fetch Data Module

A Terraform module designed to fetch outputs from infrastructure modules using remote state data sources. This module provides a centralized way to access infrastructure data across multiple layers while following best practices for remote state management.

## 🎯 Purpose

This module enables:
- **Centralized Data Access**: Fetch infrastructure outputs from multiple layers through a single interface
- **Remote State Best Practices**: Uses `terraform_remote_state` data sources for reliable data fetching
- **Multi-Environment Support**: Environment-specific configurations with proper workspace handling
- **Extensible Architecture**: Designed to support future modules and layers beyond the initial VPC focus
- **Flexible Output Formats**: Structured, flat, or raw output formats to suit different use cases

## 📋 Features

### ✅ Current Capabilities
- **VPC Module Data Fetching**: Complete access to core layer (VPC) infrastructure outputs
- **Remote State Integration**: S3 backend with encryption, locking, and cross-account support
- **Environment Management**: Multi-environment support (dev, qa, uat, prod) with workspace handling
- **Output Organization**: Multiple output formats with metadata and health information
- **Configuration Validation**: Built-in validation and error handling

### 🚀 Future Extensibility
- **Backend Layer**: Ready for backend application infrastructure data
- **Frontend Layer**: Prepared for frontend/CDN infrastructure data
- **Data Layer**: Extensible for database and analytics infrastructure data
- **Custom Modules**: Configurable architecture for additional module types

## 🏗️ Architecture

```
fetch-data module
├── Remote State Data Sources
│   ├── Core Layer (VPC) ✅
│   ├── Backend Layer 🔮
│   ├── Frontend Layer 🔮
│   └── Data Layer 🔮
├── Output Processing
│   ├── Structured Format
│   ├── Flat Format
│   └── Raw Format
└── Metadata & Health Checks
```

## 📦 Usage

### Basic VPC Data Fetching

```hcl
module "fetch_data" {
  source = "../../modules/fetch-data"

  # Environment Configuration
  environment = "dev"
  name_prefix = "myproject"
  aws_region  = "us-west-2"

  # Remote State Configuration
  terraform_state_bucket = "myproject-terraform-state"
  state_bucket_region    = "us-west-2"
  state_key_prefix      = "layers"

  # Module Selection
  fetch_vpc_module = true

  # Core Layer Configuration
  core_layer_config = {
    enabled          = true
    state_key        = null  # Uses computed default
    workspace        = null  # Uses environment
    specific_outputs = null  # Fetches all outputs
  }

  # Output Configuration
  output_format      = "structured"
  include_metadata   = true
  sensitive_outputs  = false
}
```

### Advanced Configuration with Specific Outputs

```hcl
module "fetch_data" {
  source = "../../modules/fetch-data"

  environment = "prod"
  name_prefix = "enterprise"

  terraform_state_bucket = "enterprise-terraform-state-prod"
  state_bucket_region    = "us-east-1"
  state_key_prefix      = "infrastructure/layers"

  # Fetch only specific VPC outputs
  core_layer_config = {
    enabled = true
    specific_outputs = [
      "vpc_id",
      "vpc_cidr_block",
      "public_subnets",
      "private_subnets",
      "nat_gateway_ids"
    ]
  }

  # Advanced S3 Configuration
  state_lock_table = "enterprise-terraform-locks"
  kms_key_id      = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"

  # Cross-account access
  assume_role_arn = "arn:aws:iam::123456789012:role/TerraformStateReader"

  output_format = "flat"
  include_metadata = true
}
```

### Multi-Layer Configuration (Future)

```hcl
module "fetch_data" {
  source = "../../modules/fetch-data"

  environment = "prod"
  
  terraform_state_bucket = "myproject-terraform-state"
  
  # Enable multiple layers
  fetch_vpc_module      = true
  fetch_backend_module  = true
  fetch_frontend_module = true
  fetch_data_module     = true

  # Layer-specific configurations
  core_layer_config = {
    enabled = true
  }
  
  backend_layer_config = {
    enabled = true
    state_key = "layers/prod/backend/terraform.tfstate"
  }
  
  frontend_layer_config = {
    enabled = true
    state_key = "layers/prod/frontend/terraform.tfstate"
  }
  
  data_layer_config = {
    enabled = true
    state_key = "layers/prod/data/terraform.tfstate"
  }

  output_format = "structured"
}
```

## 📤 Outputs

### Primary Outputs

| Output | Type | Description |
|--------|------|-------------|
| `all_data` | `map(any)` | All infrastructure data in selected format |
| `vpc` | `map(any)` | VPC module outputs from core layer |
| `metadata` | `map(any)` | Module metadata and generation info |
| `configuration_summary` | `map(any)` | Configuration summary for debugging |

### VPC-Specific Outputs

| Output | Type | Description |
|--------|------|-------------|
| `vpc_id` | `string` | ID of the VPC |
| `vpc_cidr_block` | `string` | CIDR block of the VPC |
| `vpc_arn` | `string` | ARN of the VPC |
| `availability_zones` | `list(string)` | List of availability zones |
| `public_subnets` | `list(string)` | List of public subnet IDs |
| `private_subnets` | `list(string)` | List of private subnet IDs |
| `database_subnets` | `list(string)` | List of database subnet IDs |
| `internet_gateway_id` | `string` | ID of the Internet Gateway |
| `nat_gateway_ids` | `list(string)` | List of NAT Gateway IDs |
| `nat_public_ips` | `list(string)` | List of NAT Gateway public IPs |

### Health and State Information

| Output | Type | Description |
|--------|------|-------------|
| `enabled_modules` | `list(string)` | List of enabled modules |
| `health_status` | `map(any)` | Health status of remote state connections |
| `state_configuration` | `map(any)` | Remote state configuration used |
| `state_keys` | `map(string)` | State keys used for each layer |

## 📋 Variables

### Required Variables

| Variable | Type | Description |
|----------|------|-------------|
| `environment` | `string` | Environment name (dev, qa, uat, prod) |
| `terraform_state_bucket` | `string` | S3 bucket for Terraform state files |

### Optional Configuration Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `name_prefix` | `string` | `""` | Name prefix for resource identification |
| `aws_region` | `string` | `null` | AWS region (auto-detected if null) |
| `state_bucket_region` | `string` | `null` | State bucket region (uses aws_region if null) |
| `state_key_prefix` | `string` | `"layers"` | Prefix for state file keys |
| `use_workspace_in_state_key` | `bool` | `true` | Include workspace in state key path |

### Module Selection Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `fetch_vpc_module` | `bool` | `true` | Fetch VPC module data |
| `fetch_backend_module` | `bool` | `false` | Fetch backend module data |
| `fetch_frontend_module` | `bool` | `false` | Fetch frontend module data |
| `fetch_data_module` | `bool` | `false` | Fetch data module data |

### Advanced Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `state_lock_table` | `string` | `null` | DynamoDB table for state locking |
| `kms_key_id` | `string` | `null` | KMS key for state encryption |
| `assume_role_arn` | `string` | `null` | IAM role for cross-account access |
| `output_format` | `string` | `"structured"` | Output format (structured, flat, raw) |
| `include_metadata` | `bool` | `true` | Include metadata in outputs |
| `sensitive_outputs` | `bool` | `false` | Mark outputs as sensitive |

## 🏗️ Layer Configuration Objects

Each layer accepts a configuration object with the following structure:

```hcl
{
  enabled          = bool           # Enable this layer
  state_key        = string         # Custom state key (optional)
  workspace        = string         # Custom workspace (optional)
  specific_outputs = list(string)   # Specific outputs to fetch (optional)
}
```

## 📁 State Key Structure

The module uses a flexible state key structure:

### With Workspace in State Key (default)
```
{state_key_prefix}/{environment}/{layer}/terraform.tfstate
```
Example: `layers/prod/core/terraform.tfstate`

### Without Workspace in State Key
```
{state_key_prefix}/{layer}/terraform.tfstate
```
Example: `layers/core/terraform.tfstate`

## 🔄 Output Formats

### Structured Format (default)
```hcl
{
  core = {
    vpc_id = "vpc-123456"
    # ... other core outputs
  }
  backend = {
    # ... backend outputs
  }
  metadata = {
    # ... metadata info
  }
}
```

### Flat Format
```hcl
{
  core_vpc_id = "vpc-123456"
  core_vpc_cidr_block = "10.0.0.0/16"
  backend_app_url = "https://api.example.com"
  # ... flattened outputs
}
```

### Raw Format
```hcl
{
  vpc_id = "vpc-123456"
  vpc_cidr_block = "10.0.0.0/16"
  app_url = "https://api.example.com"
  # ... raw outputs (potential conflicts)
}
```

## 🔧 Integration Examples

### Using Fetched Data in Another Module

```hcl
# Fetch infrastructure data
module "infrastructure_data" {
  source = "../../modules/fetch-data"
  
  environment = var.environment
  terraform_state_bucket = var.terraform_state_bucket
  fetch_vpc_module = true
}

# Use the data in a new module
module "application" {
  source = "../../modules/application"
  
  # Use VPC data
  vpc_id = module.infrastructure_data.vpc_id
  private_subnets = module.infrastructure_data.private_subnets
  vpc_cidr_block = module.infrastructure_data.vpc_cidr_block
  
  # Use all structured data
  infrastructure = module.infrastructure_data.all_data
}
```

### Integration with Existing Terraform Configuration

```hcl
# In your main.tf
module "fetch_data" {
  source = "./modules/fetch-data"
  
  environment = "prod"
  terraform_state_bucket = "myproject-terraform-state"
}

# Create resources using fetched data
resource "aws_security_group" "app" {
  name_prefix = "app-"
  vpc_id      = module.fetch_data.vpc_id
  
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [module.fetch_data.vpc_cidr_block]
  }
}

# Output combined information
output "infrastructure_summary" {
  value = {
    environment = var.environment
    vpc_info    = module.fetch_data.vpc
    metadata    = module.fetch_data.metadata
  }
}
```

## 🔐 Security Best Practices

### State Bucket Security
```hcl
# Ensure your state bucket is configured with:
# - Versioning enabled
# - Encryption at rest (KMS)
# - Access logging
# - Bucket policy restricting access
```

### Cross-Account Access
```hcl
# Use assume role for cross-account state access
assume_role_arn = "arn:aws:iam::ACCOUNT:role/TerraformStateReader"

# Ensure the role has minimal permissions:
# - s3:GetObject on state files
# - s3:ListBucket on state bucket
# - dynamodb:GetItem on lock table (if using)
# - kms:Decrypt on KMS key (if using)
```

## 🚀 Future Extensibility

### Adding New Modules

1. **Add Module Variables**:
```hcl
variable "fetch_monitoring_module" {
  description = "Whether to fetch data from monitoring modules"
  type        = bool
  default     = false
}

variable "monitoring_layer_config" {
  description = "Configuration for accessing monitoring layer state"
  type = object({
    enabled          = bool
    state_key        = optional(string)
    workspace        = optional(string)
    specific_outputs = optional(list(string))
  })
  default = {
    enabled = false
    # ...
  }
}
```

2. **Add Local Logic**:
```hcl
# In locals.tf
monitoring_enabled = var.fetch_monitoring_module && var.monitoring_layer_config.enabled
monitoring_state_key = var.monitoring_layer_config.state_key != null ? var.monitoring_layer_config.state_key : format(local.base_state_key_format, "monitoring")
```

3. **Add Remote State Data Source**:
```hcl
# In main.tf
data "terraform_remote_state" "monitoring" {
  count   = local.monitoring_enabled ? 1 : 0
  backend = "s3"
  
  config = {
    bucket = var.terraform_state_bucket
    key    = local.monitoring_state_key
    region = local.resolved_state_bucket_region
    # ... other config
  }
  
  workspace = local.monitoring_workspace
}
```

4. **Add Outputs**:
```hcl
# In outputs.tf
output "monitoring" {
  description = "Monitoring module outputs"
  value       = local.monitoring_enabled ? local.monitoring_outputs : {}
  sensitive   = local.mark_outputs_sensitive
}
```

## 🔍 Troubleshooting

### Common Issues

1. **State File Not Found**
   - Verify state bucket name and region
   - Check state key path format
   - Ensure workspace/environment exists

2. **Access Denied**
   - Verify IAM permissions for state bucket access
   - Check assume role configuration
   - Ensure KMS permissions for encrypted state

3. **No Outputs Available**
   - Ensure source module has outputs defined
   - Verify module is enabled in configuration
   - Check workspace selection

### Debug Information

The module provides extensive debug information through outputs:
- `configuration_summary`: Complete configuration overview
- `health_status`: Connection and fetch status
- `state_configuration`: Remote state setup details
- `state_keys`: Actual state keys being used

## 📊 Version Requirements

- **Terraform**: `>= 1.13.0`
- **AWS Provider**: `>= 5.0.0, < 6.0.0`

## 📄 License

This module follows the same license as the broader infrastructure project.

---

**Note**: This module is designed to grow with your infrastructure. Start with VPC data fetching and gradually extend to include additional layers and modules as your infrastructure evolves.