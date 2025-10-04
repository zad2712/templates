# Azure Web Application Module

This Terraform module creates and manages Azure Web Applications (App Services) with comprehensive configuration options for modern web application deployment.

## Features

- **Multi-OS Support**: Both Linux and Windows App Services
- **Application Stacks**: Support for .NET, Node.js, Python, PHP, Java, Ruby, Go, and Docker
- **Security**: Private endpoints, IP restrictions, SSL/TLS, managed identity
- **Monitoring**: Application Insights integration and diagnostic settings
- **High Availability**: Zone redundancy and auto-healing capabilities
- **Custom Domains**: SSL certificate binding and custom hostname support
- **Authentication**: Azure AD and other provider integration
- **Backup & Recovery**: Automated backup configuration
- **Performance**: Auto-scaling, load balancing, and performance optimization

## Usage

### Basic Web App Example

```hcl
module "web_app" {
  source = "../../modules/web-app"

  name                = "my-web-app"
  location            = "East US"
  resource_group_name = "my-rg"

  # App Service Plan configuration
  sku_name = "B1"
  os_type  = "Linux"

  # Application stack
  application_stack = {
    node_version = "18-lts"
  }

  # Basic settings
  https_only  = true
  always_on   = true

  tags = {
    Environment = "dev"
    Project     = "myproject"
  }
}
```

### Advanced Production Web App

```hcl
module "production_web_app" {
  source = "../../modules/web-app"

  name                = "prod-web-app"
  location            = "East US"
  resource_group_name = "production-rg"

  # Premium App Service Plan with zone redundancy
  sku_name                = "P1V3"
  os_type                = "Linux"
  worker_count           = 3
  enable_zone_redundancy = true
  per_site_scaling_enabled = true

  # Security configuration
  https_only                    = true
  client_certificate_enabled   = true
  client_certificate_mode      = "Required"
  public_network_access_enabled = false
  minimum_tls_version          = "1.2"

  # VNet integration
  virtual_network_subnet_id = "/subscriptions/.../subnets/webapp-subnet"
  vnet_route_all_enabled   = true

  # Managed Identity
  enable_managed_identity = true
  identity_type          = "SystemAssigned"

  # Application stack
  application_stack = {
    node_version = "18-lts"
  }

  # Site configuration
  always_on                = true
  http2_enabled           = true
  websockets_enabled      = true
  ftps_state             = "Disabled"
  remote_debugging_enabled = false
  
  # Health check
  health_check_path                 = "/health"
  health_check_eviction_time_in_min = 5

  # Auto heal configuration
  auto_heal_enabled = true
  auto_heal_setting = {
    action = {
      action_type                    = "Recycle"
      minimum_process_execution_time = "00:01:00"
    }
    trigger = {
      requests = {
        count    = 100
        interval = "00:01:00"
      }
      slow_request = {
        count      = 10
        interval   = "00:01:00"
        time_taken = "00:00:30"
      }
      status_code = [
        {
          status_code_range = "500-599"
          count            = 10
          interval         = "00:01:00"
        }
      ]
    }
  }

  # Application settings
  app_settings = {
    "NODE_ENV"                          = "production"
    "WEBSITE_NODE_DEFAULT_VERSION"      = "18-lts"
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = module.application_insights.connection_string
    "APPINSIGHTS_INSTRUMENTATIONKEY"    = module.application_insights.instrumentation_key
  }

  # Connection strings
  connection_strings = {
    "DefaultConnection" = {
      type  = "SQLAzure"
      value = "Server=tcp:myserver.database.windows.net,1433;Database=mydb;"
    }
  }

  # CORS configuration
  cors_configuration = {
    allowed_origins     = ["https://mydomain.com", "https://www.mydomain.com"]
    support_credentials = true
  }

  # IP restrictions
  ip_restrictions = [
    {
      name       = "AllowOfficeNetwork"
      ip_address = "203.0.113.0/24"
      priority   = 100
      action     = "Allow"
    },
    {
      name        = "AllowCDN"
      service_tag = "AzureFrontDoor.Backend"
      priority    = 200
      action      = "Allow"
      headers = {
        x_azure_fdid = ["12345678-1234-1234-1234-123456789012"]
      }
    }
  ]

  # Custom domains
  custom_domains = {
    "myapp.mydomain.com" = {
      ssl_state = "SniEnabled"
    }
  }

  # Private endpoint
  enable_private_endpoint    = true
  private_endpoint_subnet_id = "/subscriptions/.../subnets/pe-subnet"
  private_dns_zone_id        = "/subscriptions/.../privateDnsZones/privatelink.azurewebsites.net"

  # Application Insights
  enable_application_insights = true
  application_insights_type   = "web"
  log_analytics_workspace_id  = "/subscriptions/.../workspaces/prod-workspace"

  # Diagnostic settings
  enable_diagnostic_settings = true

  # Backup configuration
  backup_configuration = {
    name                = "daily-backup"
    enabled             = true
    storage_account_url = "https://backupstorage.blob.core.windows.net/backups?sp=..."
    schedule = {
      frequency_interval       = 1
      frequency_unit          = "Day"
      retention_period_days    = 30
      keep_at_least_one_backup = true
      start_time              = "2023-01-01T02:00:00Z"
    }
  }

  # Authentication with Azure AD
  enable_authentication = true
  auth_settings = {
    enabled                        = true
    default_provider              = "AzureActiveDirectory"
    unauthenticated_client_action = "RedirectToLoginPage"
    token_store_enabled           = true
    token_refresh_extension_hours = 72
    active_directory = {
      client_id = "12345678-1234-1234-1234-123456789012"
      allowed_audiences = ["https://myapp.mydomain.com"]
    }
  }

  tags = {
    Environment = "production"
    Project     = "myproject"
    Owner       = "platform-team"
    Backup      = "required"
  }
}
```

### Container-based Web App

```hcl
module "container_web_app" {
  source = "../../modules/web-app"

  name                = "container-web-app"
  location            = "East US"
  resource_group_name = "my-rg"

  sku_name = "P1V3"
  os_type  = "Linux"

  # Docker container configuration
  application_stack = {
    docker_image     = "myregistry.azurecr.io/myapp"
    docker_image_tag = "latest"
  }

  # Container registry integration
  container_registry_use_managed_identity = true
  enable_managed_identity                = true

  app_settings = {
    "DOCKER_REGISTRY_SERVER_URL"      = "https://myregistry.azurecr.io"
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = "false"
  }

  tags = {
    Environment = "production"
    Type        = "container"
  }
}
```

### Windows .NET Web App

```hcl
module "dotnet_web_app" {
  source = "../../modules/web-app"

  name                = "dotnet-web-app"
  location            = "East US"
  resource_group_name = "my-rg"

  sku_name = "S1"
  os_type  = "Windows"

  # .NET application stack
  windows_application_stack = {
    current_stack  = "dotnet"
    dotnet_version = "v6.0"
  }

  app_settings = {
    "ASPNETCORE_ENVIRONMENT" = "Production"
  }

  tags = {
    Environment = "production"
    Framework   = "dotnet"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.9.0 |
| azurerm | >= 3.116.0 |

## Providers

| Name | Version |
|------|---------|
| azurerm | >= 3.116.0 |

## Resources

| Name | Type |
|------|------|
| [azurerm_service_plan.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/service_plan) | resource |
| [azurerm_linux_web_app.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_web_app) | resource |
| [azurerm_windows_web_app.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/windows_web_app) | resource |
| [azurerm_app_service_custom_hostname_binding.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/app_service_custom_hostname_binding) | resource |
| [azurerm_application_insights.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/application_insights) | resource |
| [azurerm_private_endpoint.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_endpoint) | resource |
| [azurerm_monitor_diagnostic_setting.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_diagnostic_setting) | resource |

## Inputs

### Required Inputs

| Name | Description | Type |
|------|-------------|------|
| name | Name of the web application | `string` |
| location | Azure region where resources will be created | `string` |
| resource_group_name | Name of the resource group | `string` |

### Optional Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| os_type | Operating system type | `string` | `"Linux"` |
| sku_name | SKU name for App Service Plan | `string` | `"B1"` |
| worker_count | Number of workers | `number` | `1` |
| enable_zone_redundancy | Enable zone redundancy | `bool` | `false` |
| https_only | Force HTTPS only | `bool` | `true` |
| always_on | Enable always on | `bool` | `true` |
| enable_managed_identity | Enable managed identity | `bool` | `false` |
| enable_application_insights | Enable Application Insights | `bool` | `false` |
| enable_private_endpoint | Enable private endpoint | `bool` | `false` |
| tags | Resource tags | `map(string)` | `{}` |

## Outputs

| Name | Description |
|------|-------------|
| web_app_id | ID of the web app |
| web_app_name | Name of the web app |
| web_app_url | URL of the web app |
| web_app_default_hostname | Default hostname |
| web_app_outbound_ip_addresses | Outbound IP addresses |
| web_app_identity | Managed identity information |
| application_insights_instrumentation_key | Application Insights instrumentation key |
| private_endpoint_ip_address | Private endpoint IP address |

## App Service Plan SKUs

### Free Tier
- **F1**: 1 GB RAM, 60 minutes/day

### Shared Tier  
- **D1**: 1 GB RAM, 240 minutes/day

### Basic Tier
- **B1**: 1.75 GB RAM, A-Series compute
- **B2**: 3.5 GB RAM, A-Series compute  
- **B3**: 7 GB RAM, A-Series compute

### Standard Tier
- **S1**: 1.75 GB RAM, A-Series compute
- **S2**: 3.5 GB RAM, A-Series compute
- **S3**: 7 GB RAM, A-Series compute

### Premium V2
- **P1V2**: 3.5 GB RAM, Dv2-Series compute
- **P2V2**: 7 GB RAM, Dv2-Series compute
- **P3V2**: 14 GB RAM, Dv2-Series compute

### Premium V3
- **P1V3**: 4 GB RAM, Dv3-Series compute
- **P2V3**: 8 GB RAM, Dv3-Series compute
- **P3V3**: 16 GB RAM, Dv3-Series compute

### Isolated
- **I1**: 3.5 GB RAM, Dedicated environment
- **I2**: 7 GB RAM, Dedicated environment
- **I3**: 14 GB RAM, Dedicated environment

## Application Stacks

### Linux Stacks
```hcl
application_stack = {
  # .NET
  dotnet_version = "6.0"  # 3.1, 6.0, 7.0
  
  # Node.js
  node_version = "18-lts"  # 14-lts, 16-lts, 18-lts, 19-lts
  
  # Python
  python_version = "3.9"  # 3.7, 3.8, 3.9, 3.10, 3.11
  
  # PHP
  php_version = "8.1"  # 7.4, 8.0, 8.1, 8.2
  
  # Java
  java_version = "11"  # 8, 11, 17
  java_server = "TOMCAT"  # TOMCAT, JAVA
  java_server_version = "10.0"
  
  # Ruby
  ruby_version = "2.7"  # 2.6, 2.7
  
  # Go
  go_version = "1.19"  # 1.18, 1.19
  
  # Docker
  docker_image = "nginx"
  docker_image_tag = "latest"
}
```

### Windows Stacks
```hcl
windows_application_stack = {
  # .NET Framework
  current_stack = "dotnetframework"
  
  # .NET
  current_stack = "dotnet"
  dotnet_version = "v6.0"
  
  # Node.js
  current_stack = "node"
  node_version = "18-LTS"
  
  # PHP
  current_stack = "php"
  php_version = "v8.1"
  
  # Python
  current_stack = "python"
  python_version = "3.9"
  
  # Java
  current_stack = "java"
  java_version = "11"
  java_container = "TOMCAT"
  java_container_version = "10.0"
}
```

## Security Configuration

### IP Restrictions
```hcl
ip_restrictions = [
  {
    name       = "AllowOffice"
    ip_address = "203.0.113.0/24"
    priority   = 100
    action     = "Allow"
  },
  {
    name        = "AllowCDN"
    service_tag = "AzureFrontDoor.Backend"
    priority    = 200
    action      = "Allow"
  }
]
```

### Authentication with Azure AD
```hcl
enable_authentication = true
auth_settings = {
  enabled                        = true
  default_provider              = "AzureActiveDirectory"
  unauthenticated_client_action = "RedirectToLoginPage"
  active_directory = {
    client_id = "your-app-registration-id"
  }
}
```

### Private Endpoint Configuration
```hcl
enable_private_endpoint    = true
private_endpoint_subnet_id = "/subscriptions/.../subnets/pe-subnet"
private_dns_zone_id        = "/subscriptions/.../privateDnsZones/privatelink.azurewebsites.net"
```

## Monitoring and Diagnostics

### Application Insights Integration
```hcl
enable_application_insights = true
application_insights_type   = "web"
log_analytics_workspace_id  = "/subscriptions/.../workspaces/my-workspace"
```

### Diagnostic Logs Available
- **AppServiceAppLogs**: Application logs
- **AppServiceAuditLogs**: Audit logs
- **AppServiceConsoleLogs**: Console logs
- **AppServiceHTTPLogs**: HTTP access logs
- **AppServiceIPSecAuditLogs**: IP security audit logs
- **AppServicePlatformLogs**: Platform logs

### Auto-Healing Configuration
```hcl
auto_heal_enabled = true
auto_heal_setting = {
  action = {
    action_type = "Recycle"
  }
  trigger = {
    requests = {
      count    = 100
      interval = "00:01:00"
    }
    slow_request = {
      count      = 10
      interval   = "00:01:00"
      time_taken = "00:00:30"
    }
  }
}
```

## Best Practices

1. **Security**: Use HTTPS only and disable FTP
2. **Performance**: Enable HTTP/2 and configure appropriate SKU
3. **Monitoring**: Enable Application Insights and diagnostic settings
4. **Identity**: Use managed identities for Azure service authentication
5. **Networking**: Use private endpoints in production environments
6. **Backup**: Configure automated backups for production workloads
7. **Scaling**: Use auto-scaling rules and appropriate App Service Plan
8. **Configuration**: Use App Settings for environment-specific configuration

## Troubleshooting

### Common Issues

1. **Startup errors**: Check Application Insights and diagnostic logs
2. **Performance issues**: Monitor Application Insights metrics and enable auto-healing
3. **Authentication problems**: Verify Azure AD configuration and redirect URLs
4. **SSL certificate issues**: Check custom domain and certificate binding

### Useful Application Settings

```hcl
app_settings = {
  # Debugging
  "ASPNETCORE_ENVIRONMENT" = "Development"
  "ASPNETCORE_DETAILEDERRORS" = "true"
  
  # Performance
  "WEBSITE_TIME_ZONE" = "UTC"
  "WEBSITE_RUN_FROM_PACKAGE" = "1"
  
  # Security
  "WEBSITE_HTTPLOGGING_RETENTION_DAYS" = "7"
}
```

## License

This module is licensed under the MIT License. See LICENSE file for details.