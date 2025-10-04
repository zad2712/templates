# Azure Private Endpoint Module

This Terraform module creates and manages Azure Private Endpoints with comprehensive configuration for secure connectivity to Azure services.

## Features

- **Multi-Service Support**: Works with 15+ Azure services
- **DNS Integration**: Automatic private DNS zone integration
- **Network Security**: Subnet and network security group association
- **Service Validation**: Automatic validation of service types and subresources
- **Custom DNS**: Support for custom DNS configurations
- **Monitoring**: Diagnostic settings integration
- **Flexible Configuration**: Support for manual and automatic connections

## Supported Azure Services

| Service | Subresources |
|---------|-------------|
| Storage Account | blob, file, queue, table, web, dfs |
| SQL Database | sqlServer |
| Cosmos DB | sql, mongodb, cassandra, gremlin, table |
| Key Vault | vault |
| Service Bus | namespace |
| Event Hubs | namespace |
| Container Registry | registry |
| App Service | sites |
| Function App | sites |
| Redis Cache | redisCache |
| MySQL | mysqlServer |
| PostgreSQL | postgresqlServer |
| Synapse | sql, sqlOnDemand, dev |
| Cognitive Services | account |
| IoT Hub | iotHub |

## Usage

### Basic Storage Account Example

```hcl
module "storage_private_endpoint" {
  source = "../../modules/private-endpoint"

  name                = "storage-pe"
  location            = "East US"
  resource_group_name = "my-rg"
  subnet_id           = "/subscriptions/.../subnets/pe-subnet"

  private_connection_resource_id = "/subscriptions/.../storageAccounts/mystorageaccount"
  subresource_names             = ["blob"]

  private_dns_zone_ids = [
    "/subscriptions/.../privateDnsZones/privatelink.blob.core.windows.net"
  ]

  tags = {
    Environment = "production"
    Service     = "storage"
  }
}
```

### Advanced SQL Database Example

```hcl
module "sql_private_endpoint" {
  source = "../../modules/private-endpoint"

  name                = "sql-pe"
  location            = "East US" 
  resource_group_name = "my-rg"
  subnet_id           = "/subscriptions/.../subnets/pe-subnet"

  private_connection_resource_id = "/subscriptions/.../servers/my-sql-server"
  subresource_names             = ["sqlServer"]
  is_manual_connection          = false

  private_dns_zone_ids = [
    "/subscriptions/.../privateDnsZones/privatelink.database.windows.net"
  ]

  # Custom DNS configuration
  custom_dns_configs = [
    {
      fqdn         = "myserver.database.windows.net"
      ip_addresses = ["10.0.1.10"]
    }
  ]

  # IP configuration
  ip_configuration = [
    {
      name               = "internal"
      private_ip_address = "10.0.1.10"
      subresource_name   = "sqlServer"
    }
  ]

  tags = {
    Environment = "production"
    Service     = "database"
    Project     = "myapp"
  }
}
```

### Multi-Service Key Vault Example

```hcl
module "keyvault_private_endpoint" {
  source = "../../modules/private-endpoint"

  name                = "kv-pe"
  location            = "East US"
  resource_group_name = "my-rg"
  subnet_id           = "/subscriptions/.../subnets/pe-subnet"

  private_connection_resource_id = "/subscriptions/.../vaults/my-keyvault"
  subresource_names             = ["vault"]

  private_dns_zone_ids = [
    "/subscriptions/.../privateDnsZones/privatelink.vaultcore.azure.net"
  ]

  # Application security group
  application_security_group_ids = [
    "/subscriptions/.../applicationSecurityGroups/app-asg"
  ]

  tags = {
    Environment = "production"
    Service     = "keyvault"
  }
}
```

### Cosmos DB with Multiple Subresources

```hcl
module "cosmos_private_endpoint" {
  source = "../../modules/private-endpoint"

  name                = "cosmos-pe"
  location            = "East US"
  resource_group_name = "my-rg"
  subnet_id           = "/subscriptions/.../subnets/pe-subnet"

  private_connection_resource_id = "/subscriptions/.../databaseAccounts/my-cosmos"
  subresource_names             = ["sql"]

  private_dns_zone_ids = [
    "/subscriptions/.../privateDnsZones/privatelink.documents.azure.com"
  ]

  # Multiple IP configurations for different regions
  ip_configuration = [
    {
      name               = "primary"
      private_ip_address = "10.0.1.20"
      subresource_name   = "sql"
    },
    {
      name               = "secondary" 
      private_ip_address = "10.0.1.21"
      subresource_name   = "sql"
    }
  ]

  tags = {
    Environment = "production"
    Service     = "cosmosdb"
  }
}
```

### Manual Connection Example

```hcl
module "manual_private_endpoint" {
  source = "../../modules/private-endpoint"

  name                = "manual-pe"
  location            = "East US"
  resource_group_name = "my-rg"
  subnet_id           = "/subscriptions/.../subnets/pe-subnet"

  private_connection_resource_id = "/subscriptions/.../servers/external-server"
  subresource_names             = ["sqlServer"]
  is_manual_connection          = true
  request_message               = "Please approve this private endpoint connection for production workload."

  tags = {
    Environment = "production"
    Type        = "manual"
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
| [azurerm_private_endpoint.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_endpoint) | resource |

## Inputs

### Required Inputs

| Name | Description | Type |
|------|-------------|------|
| name | Name of the private endpoint | `string` |
| location | Azure region where the private endpoint will be created | `string` |
| resource_group_name | Name of the resource group | `string` |
| subnet_id | ID of the subnet where the private endpoint will be created | `string` |
| private_connection_resource_id | Resource ID of the service to connect to | `string` |
| subresource_names | List of subresource names for the private endpoint | `list(string)` |

### Optional Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| is_manual_connection | Whether the private endpoint connection is manual | `bool` | `false` |
| request_message | Message for manual connection requests | `string` | `null` |
| private_dns_zone_ids | List of private DNS zone IDs | `list(string)` | `[]` |
| custom_dns_configs | List of custom DNS configurations | `list(object)` | `[]` |
| ip_configuration | List of IP configurations | `list(object)` | `[]` |
| application_security_group_ids | List of application security group IDs | `list(string)` | `[]` |
| tags | Resource tags | `map(string)` | `{}` |

## Outputs

| Name | Description |
|------|-------------|
| private_endpoint_id | ID of the private endpoint |
| private_endpoint_name | Name of the private endpoint |
| network_interface | Network interface information |
| custom_dns_configs | Custom DNS configuration |
| private_dns_zone_configs | Private DNS zone configuration |
| private_ip_address | Private IP address assigned |

## Service-Specific Configurations

### Storage Account Subresources
```hcl
# For blob storage
subresource_names = ["blob"]
private_dns_zone_ids = ["privatelink.blob.core.windows.net"]

# For file shares  
subresource_names = ["file"]
private_dns_zone_ids = ["privatelink.file.core.windows.net"]

# For queues
subresource_names = ["queue"] 
private_dns_zone_ids = ["privatelink.queue.core.windows.net"]

# For tables
subresource_names = ["table"]
private_dns_zone_ids = ["privatelink.table.core.windows.net"]
```

### Database Services
```hcl
# SQL Database
subresource_names = ["sqlServer"]
private_dns_zone_ids = ["privatelink.database.windows.net"]

# MySQL  
subresource_names = ["mysqlServer"]
private_dns_zone_ids = ["privatelink.mysql.database.azure.com"]

# PostgreSQL
subresource_names = ["postgresqlServer"] 
private_dns_zone_ids = ["privatelink.postgres.database.azure.com"]
```

### Cosmos DB APIs
```hcl
# SQL API
subresource_names = ["sql"]
private_dns_zone_ids = ["privatelink.documents.azure.com"]

# MongoDB API
subresource_names = ["mongodb"]
private_dns_zone_ids = ["privatelink.mongo.cosmos.azure.com"]

# Cassandra API  
subresource_names = ["cassandra"]
private_dns_zone_ids = ["privatelink.cassandra.cosmos.azure.com"]

# Gremlin API
subresource_names = ["gremlin"] 
private_dns_zone_ids = ["privatelink.gremlin.cosmos.azure.com"]

# Table API
subresource_names = ["table"]
private_dns_zone_ids = ["privatelink.table.cosmos.azure.com"]
```

## Network Security Considerations

### Subnet Requirements
- Subnet must have sufficient IP addresses available
- Network policies for private endpoints should be disabled:
  ```hcl
  enforce_private_link_endpoint_network_policies = false
  ```

### Network Security Groups
- NSG rules are not applied to private endpoint traffic
- Use application security groups for additional segmentation

### DNS Resolution
```hcl
# Automatic DNS integration
private_dns_zone_ids = [
  "/subscriptions/.../privateDnsZones/privatelink.blob.core.windows.net"
]

# Custom DNS configuration
custom_dns_configs = [
  {
    fqdn         = "mystorageaccount.blob.core.windows.net"
    ip_addresses = ["10.0.1.4", "10.0.1.5"]
  }
]
```

## IP Configuration

### Static IP Assignment
```hcl
ip_configuration = [
  {
    name               = "internal-config"
    private_ip_address = "10.0.1.10"
    subresource_name   = "blob"
    member_name        = null
  }
]
```

### Dynamic IP Assignment
```hcl
# Omit ip_configuration for dynamic assignment
# Azure will automatically assign available IPs from the subnet
```

## DNS Zone Names by Service

| Service | Private DNS Zone |
|---------|------------------|
| Storage Blob | privatelink.blob.core.windows.net |
| Storage File | privatelink.file.core.windows.net |
| Storage Queue | privatelink.queue.core.windows.net |
| Storage Table | privatelink.table.core.windows.net |
| SQL Database | privatelink.database.windows.net |
| Cosmos DB SQL | privatelink.documents.azure.com |
| Key Vault | privatelink.vaultcore.azure.net |
| Service Bus | privatelink.servicebus.windows.net |
| Event Hubs | privatelink.servicebus.windows.net |
| Container Registry | privatelink.azurecr.io |
| App Service | privatelink.azurewebsites.net |
| Redis Cache | privatelink.redis.cache.windows.net |
| MySQL | privatelink.mysql.database.azure.com |
| PostgreSQL | privatelink.postgres.database.azure.com |
| Cognitive Services | privatelink.cognitiveservices.azure.com |

## Best Practices

1. **DNS Integration**: Always configure private DNS zones for proper name resolution
2. **Subnet Planning**: Use dedicated subnets for private endpoints
3. **IP Management**: Use static IP assignment for critical services
4. **Security**: Combine with NSGs and application security groups
5. **Monitoring**: Enable diagnostic settings for connectivity troubleshooting
6. **Documentation**: Document private endpoint mappings and IP assignments
7. **Testing**: Validate connectivity from different network segments
8. **Automation**: Use consistent naming conventions across environments

## Troubleshooting

### Common Issues

1. **DNS Resolution**: Verify private DNS zone configuration and links
2. **Connectivity**: Check subnet routing and firewall rules
3. **IP Conflicts**: Ensure no IP address conflicts in the subnet
4. **Service Compatibility**: Verify the service supports private endpoints

### Validation Commands

```bash
# Test DNS resolution
nslookup mystorageaccount.blob.core.windows.net

# Test connectivity
telnet 10.0.1.4 443

# Check private endpoint status
az network private-endpoint show --name pe-name --resource-group rg-name
```

## License

This module is licensed under the MIT License. See LICENSE file for details.