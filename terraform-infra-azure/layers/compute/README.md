# 🖥️ Compute Layer - Azure Workload Services

[![Terraform](https://img.shields.io/badge/Terraform-≥1.9.0-blue.svg)](https://terraform.io)
[![Azure](https://img.shields.io/badge/Azure-Provider~4.0-blue.svg)](https://registry.terraform.io/providers/hashicorp/azurerm/latest)

**Author**: Diego A. Zarate

The **Compute Layer** provides comprehensive container orchestration, serverless computing, and web application hosting capabilities on Azure. This layer builds upon the networking, security, and data layers to deliver production-ready compute workloads with enterprise-grade features.

## 🎯 **Layer Overview**

> **Purpose**: Deploy and manage compute workloads including containers, serverless functions, and web applications  
> **Dependencies**: Networking Layer → Security Layer → Data Layer → **Compute Layer**  
> **Deployment Time**: ~10-15 minutes  
> **Resources**: AKS, Azure Functions, App Services, Web Apps, Virtual Machines, Container Instances

## 🏗️ **Architecture Components**

### **🐳 Azure Kubernetes Service (AKS)**
- **Production-Ready Clusters**: Multi-node pools with auto-scaling
- **Security**: Private clusters, network policies, Azure AD integration
- **Observability**: Container Insights, Prometheus, Grafana integration
- **GitOps Ready**: ArgoCD and Flux deployment patterns

### **⚡ Azure Functions**
- **Serverless Computing**: Event-driven, auto-scaling functions
- **Multiple Runtimes**: .NET, Node.js, Python, Java support
- **Integration**: Event Grid, Service Bus, Cosmos DB triggers
- **Deployment**: Blue/green with staging slots

### **🌐 Web Applications**
- **Modern App Service**: Linux/Windows hosting with containers
- **Security**: Private endpoints, managed identities, SSL/TLS
- **Performance**: Auto-scaling, CDN integration, caching
- **DevOps**: CI/CD integration, deployment slots, traffic routing

### **💻 Virtual Machines (Optional)**
- **Legacy Workloads**: Support for existing applications
- **Hybrid Integration**: Azure Arc, Azure Stack compatibility
- **Management**: Auto-patching, backup, monitoring
- **Security**: Disk encryption, security baselines

## 📋 **Supported Services**

| Service | Purpose | Production Ready | Auto-Scaling | Private Endpoints |
|---------|---------|------------------|--------------|-------------------|
| 🐳 **AKS** | Container orchestration | ✅ | ✅ | ✅ |
| ⚡ **Functions** | Serverless compute | ✅ | ✅ | ✅ |
| 🌐 **Web Apps** | Web application hosting | ✅ | ✅ | ✅ |
| 🖥️ **App Services** | Legacy web hosting | ✅ | ✅ | ✅ |
| 💻 **Virtual Machines** | Custom workloads | ✅ | ✅ | ✅ |
| 📦 **Container Instances** | Serverless containers | ✅ | ✅ | ✅ |
| ⚙️ **Batch** | Parallel processing | ✅ | ✅ | ❌ |
| ⚖️ **Load Balancer** | Traffic distribution | ✅ | N/A | ❌ |

## 🚀 **Quick Start**

### **1. Deploy Complete Compute Layer**

```bash
# Deploy all compute services for development
cd layers/compute/environments/dev
terraform init -backend-config=backend.conf
terraform plan -var-file=terraform.auto.tfvars
terraform apply -var-file=terraform.auto.tfvars

# Or use the management script
./terraform-manager.sh deploy-compute dev
```

### **2. Deploy Individual Services**

```bash
# Deploy only AKS cluster
terraform apply -target=module.aks_cluster -var-file=terraform.auto.tfvars

# Deploy only Web Apps
terraform apply -target=module.web_app -var-file=terraform.auto.tfvars

# Deploy Functions and Web Apps
terraform apply -target=module.function_app -target=module.web_app -var-file=terraform.auto.tfvars
```

## 🔧 **Configuration Examples**

### **🐳 Production AKS Cluster**

```hcl
# terraform.auto.tfvars
aks_clusters = {
  "production" = {
    kubernetes_version = "1.29.7"
    sku_tier          = "Standard"
    private_cluster   = true
    
    # Node pools for different workload types
    node_pools = {
      "system" = {
        name                 = "system"
        vm_size             = "Standard_D4s_v4"
        node_count          = 3
        min_count           = 3
        max_count           = 6
        enable_auto_scaling = true
        node_taints         = ["CriticalAddonsOnly=true:NoSchedule"]
        
        node_labels = {
          "nodepool-type" = "system"
          "environment"   = "production"
        }
      }
      
      "user-general" = {
        name                 = "usergeneral"
        vm_size             = "Standard_D8s_v4"
        node_count          = 2
        min_count           = 1
        max_count           = 20
        enable_auto_scaling = true
        
        node_labels = {
          "nodepool-type" = "user"
          "workload-type" = "general"
        }
      }
      
      "user-memory" = {
        name                 = "usermemory"
        vm_size             = "Standard_E8s_v4"
        node_count          = 0
        min_count           = 0
        max_count           = 10
        enable_auto_scaling = true
        
        node_labels = {
          "nodepool-type" = "user"
          "workload-type" = "memory-intensive"
        }
        
        node_taints = ["workload=memory-intensive:NoSchedule"]
      }
    }
    
    # Advanced features
    enable_azure_policy            = true
    enable_secret_rotation         = true
    enable_workload_identity       = true
    enable_azure_defender         = true
    
    # Auto-scaler configuration
    auto_scaler_profile = {
      balance_similar_node_groups      = true
      expander                        = "least-waste"
      scale_down_utilization_threshold = 0.5
      scale_down_unneeded           = "10m"
    }
  }
}
```

### **⚡ Production Azure Functions**

```hcl
function_apps = {
  "api-backend" = {
    os_type      = "Linux"
    sku_name     = "EP2"                    # Premium v2
    worker_count = 2                       # Multiple workers
    
    runtime_stack = {
      dotnet_version = "8.0"               # .NET 8 LTS
    }
    
    app_settings = {
      "FUNCTIONS_EXTENSION_VERSION"        = "~4"
      "FUNCTIONS_WORKER_RUNTIME"          = "dotnet"
      "AzureWebJobsFeatureFlags"          = "EnableWorkerIndexing"
      "WEBSITE_CONTENTOVERVNET"           = "1"
      "WEBSITE_VNET_ROUTE_ALL"           = "1"
      
      # Performance optimizations
      "WEBSITE_MAX_DYNAMIC_APPLICATION_SCALE_OUT" = "20"
      "AzureWebJobsSecretStorageType"     = "keyvault"
      "AzureWebJobsSecretStorageKeyVaultUri" = "@Microsoft.KeyVault(VaultName=myproject-prod-kv;SecretName=storage-connection)"
    }
    
    # Production features
    enable_staging_slot         = true
    client_certificate_enabled  = true
    
    # Connection strings from Key Vault
    connection_strings = {
      "DefaultConnection" = {
        type  = "SQLAzure"
        value = "@Microsoft.KeyVault(VaultName=myproject-prod-kv;SecretName=sql-connection-string)"
      }
      "ServiceBusConnection" = {
        type  = "ServiceBus"
        value = "@Microsoft.KeyVault(VaultName=myproject-prod-kv;SecretName=servicebus-connection)"
      }
    }
  }
  
  "event-processor" = {
    os_type      = "Linux"
    sku_name     = "EP1"                    # Cost-optimized for events
    worker_count = 1
    
    runtime_stack = {
      python_version = "3.11"              # Python runtime
    }
    
    app_settings = {
      "FUNCTIONS_EXTENSION_VERSION"        = "~4"
      "FUNCTIONS_WORKER_RUNTIME"          = "python"
      "PYTHON_ENABLE_WORKER_EXTENSIONS"   = "1"
      
      # Event processing settings
      "EventHub_MaxBatchSize"             = "100"
      "EventHub_PrefetchCount"            = "300"
      "EventHub_BatchCheckpointFrequency" = "1"
    }
    
    enable_staging_slot = false             # Simple event processing
  }
}
```

### **🌐 Production Web Applications**

```hcl
web_apps = {
  "frontend-portal" = {
    os_type                      = "Linux"
    sku_name                    = "P1v3"
    worker_count                = 3
    enable_zone_redundancy      = true
    
    # Security configuration
    https_only                  = true
    client_certificate_enabled  = true
    client_certificate_mode     = "Optional"
    minimum_tls_version         = "1.3"
    public_network_access_enabled = false
    
    # Identity and access
    enable_managed_identity     = true
    identity_type              = "UserAssigned"
    
    # Application configuration
    application_stack = {
      node_version = "18-lts"
    }
    
    # Performance and reliability
    always_on              = true
    http2_enabled         = true
    websockets_enabled    = true
    
    # Auto-healing
    auto_heal_enabled    = true
    auto_heal_setting = {
      triggers = {
        requests = {
          count    = 100
          interval = "PT1M"
        }
        status_codes = [500, 502, 503, 504]
      }
      actions = {
        action_type                    = "Recycle"
        minimum_process_execution_time = "PT2M"
      }
    }
    
    # Application settings
    app_settings = {
      "NODE_ENV"                         = "production"
      "WEBSITE_NODE_DEFAULT_VERSION"     = "~18"
      "WEBSITE_VNET_ROUTE_ALL"          = "1"
      "WEBSITE_CONTENTOVERVNET"         = "1"
      
      # Feature flags
      "FEATURE_ADVANCED_LOGGING"        = "true"
      "FEATURE_PERFORMANCE_MONITORING"  = "true"
      "FEATURE_SECURITY_HEADERS"        = "true"
    }
    
    # CORS configuration
    cors_configuration = {
      allowed_origins = [
        "https://app.mycompany.com",
        "https://admin.mycompany.com"
      ]
      support_credentials = true
    }
    
    # Custom domains with SSL
    custom_domains = [
      {
        hostname         = "app.mycompany.com"
        certificate_name = "production-ssl-cert"
        ssl_state       = "SniEnabled"
      }
    ]
    
    # Backup configuration
    backup_configuration = {
      enabled = true
      schedule = {
        frequency_interval       = 1
        frequency_unit          = "Day"
        keep_at_least_one_backup = true
        retention_period_days    = 30
        start_time              = "02:00:00Z"
      }
    }
    
    # Authentication with Azure AD
    enable_authentication = true
    auth_settings = {
      enabled         = true
      default_provider = "AzureActiveDirectory"
      
      active_directory = {
        client_id     = "your-app-registration-id"
        client_secret = "@Microsoft.KeyVault(VaultName=myproject-prod-kv;SecretName=aad-client-secret)"
        tenant_id     = "your-tenant-id"
      }
    }
  }
  
  "api-gateway" = {
    os_type                      = "Linux"
    sku_name                    = "P2v3"
    worker_count                = 2
    
    # API-specific configuration
    application_stack = {
      dotnet_version = "8.0"
    }
    
    app_settings = {
      "ASPNETCORE_ENVIRONMENT"           = "Production"
      "ASPNETCORE_FORWARDEDHEADERS_ENABLED" = "true"
      
      # API settings
      "API_RATE_LIMIT_ENABLED"          = "true"
      "API_RATE_LIMIT_REQUESTS"         = "1000"
      "API_RATE_LIMIT_WINDOW"           = "3600"
      
      # Logging and monitoring
      "LOGGING_LEVEL"                   = "Information"
      "TELEMETRY_ENABLED"               = "true"
    }
    
    # Health check endpoint
    health_check_path = "/health"
    
    # IP restrictions for security
    ip_restrictions = [
      {
        ip_address = "10.0.0.0/16"        # Internal network only
        action     = "Allow"
        priority   = 1000
        name       = "AllowInternalNetwork"
      }
    ]
  }
}
```

## 🔄 **Environment Configurations**

### **Development Environment**
- **Focus**: Cost optimization, developer productivity
- **Features**: Public access, basic monitoring, minimal scaling
- **Resources**: Single-node AKS, consumption Functions, basic App Service

### **QA Environment** 
- **Focus**: Testing scenarios, performance validation
- **Features**: Production-like setup, load testing capabilities
- **Resources**: Multi-node AKS, premium Functions, staging slots

### **UAT Environment**
- **Focus**: User acceptance, security validation
- **Features**: Private endpoints, authentication, compliance
- **Resources**: Production configuration, security hardening

### **Production Environment**
- **Focus**: High availability, performance, security
- **Features**: Zone redundancy, auto-scaling, advanced monitoring
- **Resources**: Multi-region, premium tiers, full observability

## 📊 **Monitoring & Observability**

### **AKS Monitoring**
```bash
# Enable Container Insights
az aks enable-addons --resource-group myproject-prod-compute-rg --name myproject-prod-primary-aks --addons monitoring

# View cluster metrics
kubectl top nodes
kubectl top pods --all-namespaces

# Check cluster health
az aks check-acr --resource-group myproject-prod-compute-rg --name myproject-prod-primary-aks
```

### **Function App Monitoring**
```bash
# View function metrics
az functionapp show --name myproject-prod-api-func --resource-group myproject-prod-compute-rg

# Stream logs
az webapp log tail --name myproject-prod-api-func --resource-group myproject-prod-compute-rg

# Check function health
az functionapp function show --function-name HttpTrigger --name myproject-prod-api-func --resource-group myproject-prod-compute-rg
```

### **Web App Monitoring**
```bash
# Application Insights queries
az monitor app-insights query --app myproject-prod-frontend-ai --analytics-query "requests | summarize count() by bin(timestamp, 1h)"

# Performance metrics
az webapp show --name myproject-prod-frontend --resource-group myproject-prod-compute-rg --query "siteConfig.alwaysOn"

# Check scaling status
az webapp show --name myproject-prod-frontend --resource-group myproject-prod-compute-rg --query "sku"
```

## 🛠️ **Troubleshooting**

### **Common Issues**

#### **AKS Connection Issues**
```bash
# Get cluster credentials
az aks get-credentials --resource-group myproject-prod-compute-rg --name myproject-prod-primary-aks

# Check cluster connectivity
kubectl cluster-info

# Verify node status
kubectl get nodes -o wide

# Check for network issues
kubectl describe node <node-name>
```

#### **Function App Cold Start**
```bash
# Check function host status
az functionapp show --name myproject-prod-api-func --resource-group myproject-prod-compute-rg --query "state"

# Enable Always On for Premium plans
az functionapp config set --name myproject-prod-api-func --resource-group myproject-prod-compute-rg --always-on true

# Monitor function execution
az functionapp function show --function-name HttpTrigger --name myproject-prod-api-func --resource-group myproject-prod-compute-rg
```

#### **Web App Performance Issues**
```bash
# Check application settings
az webapp config appsettings list --name myproject-prod-frontend --resource-group myproject-prod-compute-rg

# Verify scaling configuration
az webapp show --name myproject-prod-frontend --resource-group myproject-prod-compute-rg --query "siteConfig.autoHealEnabled"

# Check network connectivity
az network vnet subnet show --name app-services-subnet --vnet-name myproject-prod-vnet --resource-group myproject-prod-networking-rg
```

## 🔐 **Security Best Practices**

### **Network Security**
- **Private Endpoints**: All services use private connectivity
- **VNet Integration**: Applications deployed within virtual networks
- **Network Policies**: Kubernetes network policies for AKS
- **WAF Protection**: Application Gateway with Web Application Firewall

### **Identity & Access**
- **Managed Identities**: All services use managed identities
- **RBAC**: Role-based access control for all resources
- **Azure AD Integration**: Authentication through Azure Active Directory
- **Key Vault Integration**: Secrets managed through Azure Key Vault

### **Data Protection**
- **Encryption in Transit**: TLS 1.2+ for all communications
- **Encryption at Rest**: All storage encrypted with customer-managed keys
- **Certificate Management**: SSL certificates managed through Key Vault
- **Secure Configuration**: Security headers and HTTPS enforcement

## 📈 **Performance Optimization**

### **Auto-Scaling Configuration**
- **AKS**: Horizontal Pod Autoscaler and Cluster Autoscaler
- **Functions**: Consumption and Premium plan auto-scaling
- **Web Apps**: Auto-scale rules based on CPU and memory
- **Load Balancing**: Application Gateway and Load Balancer integration

### **Caching Strategies**
- **CDN**: Azure CDN for static content delivery
- **Redis Cache**: In-memory caching for session and application data
- **Application Insights**: Performance monitoring and optimization
- **Query Optimization**: Database query performance tuning

### **Resource Rightsizing**
- **Environment-Specific**: Different SKUs for different environments
- **Cost Optimization**: Spot instances and reserved capacity
- **Performance Monitoring**: Continuous monitoring and adjustment
- **Scaling Policies**: Proactive scaling based on metrics

## 📚 **Additional Resources**

### **Documentation**
- [Azure Kubernetes Service Documentation](https://docs.microsoft.com/en-us/azure/aks/)
- [Azure Functions Documentation](https://docs.microsoft.com/en-us/azure/azure-functions/)
- [Azure App Service Documentation](https://docs.microsoft.com/en-us/azure/app-service/)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest)

### **Best Practices Guides**
- [AKS Best Practices](https://docs.microsoft.com/en-us/azure/aks/best-practices)
- [Azure Functions Best Practices](https://docs.microsoft.com/en-us/azure/azure-functions/functions-best-practices)
- [App Service Best Practices](https://docs.microsoft.com/en-us/azure/app-service/app-service-best-practices)

### **Monitoring & Troubleshooting**
- [Container Insights](https://docs.microsoft.com/en-us/azure/azure-monitor/containers/container-insights-overview)
- [Application Insights](https://docs.microsoft.com/en-us/azure/azure-monitor/app/app-insights-overview)
- [Azure Monitor](https://docs.microsoft.com/en-us/azure/azure-monitor/)

---

## 🤝 **Support & Contributing**

For issues, questions, or contributions related to the Compute Layer:

- 📝 **Create an Issue**: [GitHub Issues](https://github.com/your-org/terraform-infra-azure/issues)
- 💬 **Discussions**: [GitHub Discussions](https://github.com/your-org/terraform-infra-azure/discussions)
- 📧 **Contact**: devops@your-company.com

---

**📍 Navigation**: [⬅️ Data Layer](../data/README.md) | [🏠 Main README](../../README.md) | [📊 Monitoring Guide](../../docs/monitoring.md)