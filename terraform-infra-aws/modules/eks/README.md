# EKS Module

[![Terraform](https://img.shields.io/badge/terraform-%235835CC.svg?style=for-the-badge&logo=terraform&logoColor=white)](https://www.terraform.io/)
[![AWS](https://img.shields.io/badge/AWS-%23FF9900.svg?style=for-the-badge&logo=amazon-aws&logoColor=white)](https://aws.amazon.com/)
[![Kubernetes](https://img.shields.io/badge/kubernetes-%23326ce5.svg?style=for-the-badge&logo=kubernetes&logoColor=white)](https://kubernetes.io/)

## Overview

This Terraform module creates and manages Amazon EKS (Elastic Kubernetes Service) clusters with comprehensive configuration options following AWS best practices and Kubernetes security guidelines. The module supports multiple deployment patterns, managed node groups, Fargate profiles, add-ons, and advanced security configurations.

## Features

- **EKS Cluster Management**: Complete cluster lifecycle with version management and upgrades
- **Multiple Compute Options**: Managed node groups, Fargate profiles, and self-managed nodes
- **Security**: Private clusters, RBAC integration, pod security policies, and encryption
- **Networking**: VPC integration, custom CNI, service mesh ready, and load balancer integration
- **Add-ons**: AWS managed add-ons (VPC CNI, CoreDNS, kube-proxy, EBS CSI, etc.)
- **Monitoring**: CloudWatch Container Insights, control plane logging, and metrics
- **Autoscaling**: Cluster Autoscaler, Horizontal Pod Autoscaler, and Vertical Pod Autoscaler
- **IRSA Support**: IAM Roles for Service Accounts with OIDC integration
- **Multi-AZ Deployment**: High availability across multiple availability zones
- **Cost Optimization**: Spot instances, Fargate, and right-sizing recommendations

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                            EKS Cluster Architecture                         │
├─────────────────────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────────────┐  │
│  │   Control Plane │    │   Data Plane    │    │      Add-ons           │  │
│  │   (AWS Managed) │    │                 │    │                        │  │
│  │                 │    │  ┌───────────┐  │    │  • VPC CNI             │  │
│  │  • API Server   │    │  │Node Groups│  │    │  • CoreDNS             │  │
│  │  • etcd         │◄───┤  │           │  │    │  • kube-proxy          │  │
│  │  • Scheduler    │    │  │  ┌─────┐  │  │    │  • EBS CSI Driver      │  │
│  │  • Controller  │    │  │  │Pods │  │  │    │  • EFS CSI Driver      │  │
│  │    Manager      │    │  │  └─────┘  │  │    │  • AWS Load Balancer   │  │
│  └─────────────────┘    │  └───────────┘  │    │    Controller          │  │
│                         │                 │    │  • Cluster Autoscaler  │  │
│                         │  ┌───────────┐  │    │  • Metrics Server      │  │
│                         │  │ Fargate   │  │    └─────────────────────────┘  │
│                         │  │ Profiles  │  │                                │
│                         │  │           │  │                                │
│                         │  │  ┌─────┐  │  │                                │
│                         │  │  │Pods │  │  │                                │
│                         │  │  └─────┘  │  │                                │
│                         │  └───────────┘  │                                │
│                         └─────────────────┘                                │
├─────────────────────────────────────────────────────────────────────────────┤
│                             Networking & Security                           │
│  • Private Subnets          • Security Groups        • RBAC Integration    │
│  • VPC Integration          • Network Policies       • Pod Security        │
│  • Service Discovery        • IAM Integration        • Encryption at Rest  │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Usage

### Basic EKS Cluster

```hcl
module "eks_basic" {
  source = "./modules/eks"

  name_prefix = "my-app"

  eks_clusters = {
    "main" = {
      version    = "1.28"
      subnet_ids = ["subnet-12345678", "subnet-87654321", "subnet-11111111"]
      
      endpoint_private_access = true
      endpoint_public_access  = false
      
      enabled_cluster_log_types = ["api", "audit", "authenticator"]
      
      node_groups = {
        "general" = {
          subnet_ids     = ["subnet-12345678", "subnet-87654321"]
          instance_types = ["t3.medium"]
          
          scaling_config = {
            desired_size = 2
            max_size     = 5
            min_size     = 1
          }
        }
      }
    }
  }

  tags = {
    Environment = "production"
    Project     = "my-application"
  }
}
```

### Advanced EKS Cluster with Multiple Node Groups

```hcl
module "eks_advanced" {
  source = "./modules/eks"

  name_prefix = "enterprise"

  eks_clusters = {
    "production" = {
      version    = "1.28"
      subnet_ids = ["subnet-private-1", "subnet-private-2", "subnet-private-3"]
      
      # Private cluster configuration
      endpoint_private_access = true
      endpoint_public_access  = false
      security_group_ids      = [module.security_groups.eks_cluster_sg_id]
      
      # Encryption configuration
      encryption_config = {
        provider = {
          key_arn = module.kms.key_arns["eks"]
        }
        resources = ["secrets"]
      }
      
      # Comprehensive logging
      enabled_cluster_log_types = [
        "api", "audit", "authenticator", 
        "controllerManager", "scheduler"
      ]
      
      # Access configuration
      access_config = {
        authentication_mode                         = "API_AND_CONFIG_MAP"
        bootstrap_cluster_creator_admin_permissions = true
      }
      
      # Multiple node groups for different workloads
      node_groups = {
        # General purpose nodes
        "general" = {
          subnet_ids     = ["subnet-private-1", "subnet-private-2"]
          capacity_type  = "ON_DEMAND"
          ami_type      = "AL2_x86_64"
          instance_types = ["m5.large", "m5.xlarge"]
          disk_size     = 50
          
          scaling_config = {
            desired_size = 3
            max_size     = 10
            min_size     = 2
          }
          
          update_config = {
            max_unavailable_percentage = 25
          }
          
          labels = {
            role = "general"
            team = "platform"
          }
        }
        
        # Compute-optimized nodes for CPU-intensive workloads
        "compute" = {
          subnet_ids     = ["subnet-private-1", "subnet-private-2"]
          capacity_type  = "ON_DEMAND"
          ami_type      = "AL2_x86_64"
          instance_types = ["c5.large", "c5.xlarge"]
          disk_size     = 30
          
          scaling_config = {
            desired_size = 2
            max_size     = 8
            min_size     = 1
          }
          
          labels = {
            role = "compute"
            workload = "cpu-intensive"
          }
          
          taints = [
            {
              key    = "workload"
              value  = "compute"
              effect = "NoSchedule"
            }
          ]
        }
        
        # Spot instances for cost optimization
        "spot" = {
          subnet_ids     = ["subnet-private-1", "subnet-private-2"]
          capacity_type  = "SPOT"
          ami_type      = "AL2_x86_64"
          instance_types = ["t3.medium", "t3.large", "m5.large"]
          disk_size     = 30
          
          scaling_config = {
            desired_size = 2
            max_size     = 15
            min_size     = 0
          }
          
          labels = {
            role = "spot"
            cost-optimized = "true"
          }
          
          taints = [
            {
              key    = "kubernetes.io/arch"
              value  = "spot"
              effect = "NoSchedule"
            }
          ]
        }
      }
      
      # Fargate profiles for serverless workloads
      fargate_profiles = {
        "default" = {
          subnet_ids = ["subnet-private-1", "subnet-private-2"]
          selectors = [
            {
              namespace = "default"
              labels = {
                compute-type = "fargate"
              }
            },
            {
              namespace = "kube-system"
              labels = {
                k8s-app = "kube-dns"
              }
            }
          ]
        }
        
        "applications" = {
          subnet_ids = ["subnet-private-1", "subnet-private-2"]
          selectors = [
            {
              namespace = "applications"
            }
          ]
        }
      }
      
      # Essential add-ons
      addons = {
        "vpc-cni" = {
          addon_version = "v1.15.1-eksbuild.1"
          resolve_conflicts_on_create = "OVERWRITE"
          resolve_conflicts_on_update = "OVERWRITE"
          configuration_values = jsonencode({
            enableNetworkPolicy = "true"
          })
        }
        
        "coredns" = {
          addon_version = "v1.10.1-eksbuild.4"
          resolve_conflicts_on_create = "OVERWRITE"
          configuration_values = jsonencode({
            computeType = "Fargate"
          })
        }
        
        "kube-proxy" = {
          addon_version = "v1.28.2-eksbuild.2"
          resolve_conflicts_on_create = "OVERWRITE"
        }
        
        "aws-ebs-csi-driver" = {
          addon_version = "v1.24.1-eksbuild.1"
          service_account_role_arn = module.iam.ebs_csi_driver_role_arn
          resolve_conflicts_on_create = "OVERWRITE"
        }
        
        "aws-efs-csi-driver" = {
          addon_version = "v1.7.1-eksbuild.1"
          service_account_role_arn = module.iam.efs_csi_driver_role_arn
          resolve_conflicts_on_create = "OVERWRITE"
        }
        
        "aws-load-balancer-controller" = {
          addon_version = "v2.6.1-eksbuild.1"
          service_account_role_arn = module.iam.aws_load_balancer_controller_role_arn
          resolve_conflicts_on_create = "OVERWRITE"
        }
      }
    }
  }

  tags = {
    Environment = "production"
    Project     = "enterprise-app"
    Team        = "platform"
    CostCenter  = "engineering"
  }
}
```

### Development Environment with Fargate

```hcl
module "eks_dev" {
  source = "./modules/eks"

  name_prefix = "dev"

  eks_clusters = {
    "development" = {
      version    = "1.28"
      subnet_ids = ["subnet-dev-1", "subnet-dev-2"]
      
      # Allow public access for development
      endpoint_private_access = true
      endpoint_public_access  = true
      public_access_cidrs    = ["10.0.0.0/8"]  # Restrict to VPC
      
      enabled_cluster_log_types = ["api", "audit"]
      
      # Only Fargate for cost optimization
      fargate_profiles = {
        "development" = {
          subnet_ids = ["subnet-dev-1", "subnet-dev-2"]
          selectors = [
            {
              namespace = "default"
            },
            {
              namespace = "kube-system"
            },
            {
              namespace = "development"
            }
          ]
        }
      }
      
      addons = {
        "vpc-cni" = {
          resolve_conflicts_on_create = "OVERWRITE"
        }
        "coredns" = {
          resolve_conflicts_on_create = "OVERWRITE"
          configuration_values = jsonencode({
            computeType = "Fargate"
          })
        }
        "kube-proxy" = {
          resolve_conflicts_on_create = "OVERWRITE"
        }
      }
    }
  }

  tags = {
    Environment = "development"
    AutoShutdown = "enabled"
    CostOptimized = "true"
  }
}
```

### GPU-Enabled Cluster for ML Workloads

```hcl
module "eks_gpu" {
  source = "./modules/eks"

  name_prefix = "ml"

  eks_clusters = {
    "machine-learning" = {
      version    = "1.28"
      subnet_ids = ["subnet-private-1", "subnet-private-2"]
      
      endpoint_private_access = true
      endpoint_public_access  = false
      
      enabled_cluster_log_types = ["api", "audit"]
      
      node_groups = {
        # CPU nodes for general workloads
        "cpu" = {
          subnet_ids     = ["subnet-private-1", "subnet-private-2"]
          capacity_type  = "ON_DEMAND"
          ami_type      = "AL2_x86_64"
          instance_types = ["m5.large"]
          
          scaling_config = {
            desired_size = 2
            max_size     = 5
            min_size     = 1
          }
          
          labels = {
            node-type = "cpu"
          }
        }
        
        # GPU nodes for ML training
        "gpu" = {
          subnet_ids     = ["subnet-private-1", "subnet-private-2"]
          capacity_type  = "ON_DEMAND"
          ami_type      = "AL2_x86_64_GPU"
          instance_types = ["g4dn.xlarge", "g4dn.2xlarge"]
          
          scaling_config = {
            desired_size = 0
            max_size     = 10
            min_size     = 0
          }
          
          labels = {
            node-type = "gpu"
            accelerator = "nvidia-tesla-t4"
          }
          
          taints = [
            {
              key    = "nvidia.com/gpu"
              value  = "true"
              effect = "NoSchedule"
            }
          ]
        }
      }
      
      addons = {
        "vpc-cni" = {
          resolve_conflicts_on_create = "OVERWRITE"
        }
        "coredns" = {
          resolve_conflicts_on_create = "OVERWRITE"
        }
        "kube-proxy" = {
          resolve_conflicts_on_create = "OVERWRITE"
        }
        "aws-ebs-csi-driver" = {
          service_account_role_arn = module.iam.ebs_csi_driver_role_arn
        }
      }
    }
  }

  tags = {
    Environment = "production"
    Workload    = "machine-learning"
    GPUEnabled  = "true"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.9.0 |
| aws | ~> 5.0 |
| tls | ~> 4.0 |

## Providers

| Name | Version |
|------|---------|
| aws | ~> 5.0 |
| tls | ~> 4.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| name_prefix | Name prefix for EKS resources | `string` | `"app"` | no |
| tags | A map of tags to assign to EKS resources | `map(string)` | `{}` | no |
| log_retention_in_days | Number of days to retain EKS cluster logs | `number` | `7` | no |
| kms_key_id | KMS key ID for encrypting CloudWatch logs | `string` | `null` | no |
| eks_clusters | Map of EKS clusters to create | `map(object)` | `{}` | no |

### EKS Cluster Configuration Options

Each EKS cluster in the `eks_clusters` map supports the following configuration options:

| Parameter | Description | Type | Default |
|-----------|-------------|------|---------|
| `version` | Kubernetes version | `string` | Latest |
| `subnet_ids` | List of subnet IDs for the cluster | `list(string)` | Required |
| `endpoint_private_access` | Enable private API server endpoint | `bool` | `true` |
| `endpoint_public_access` | Enable public API server endpoint | `bool` | `false` |
| `public_access_cidrs` | CIDR blocks for public access | `list(string)` | `["0.0.0.0/0"]` |
| `security_group_ids` | Additional security groups | `list(string)` | `[]` |
| `encryption_config` | Encryption configuration for secrets | `object` | `null` |
| `enabled_cluster_log_types` | Control plane logging types | `list(string)` | `[]` |
| `access_config` | Cluster access configuration | `object` | `null` |
| `node_groups` | Managed node groups | `map(object)` | `{}` |
| `fargate_profiles` | Fargate profiles | `map(object)` | `{}` |
| `addons` | EKS add-ons | `map(object)` | `{}` |

## Outputs

| Name | Description |
|------|-------------|
| eks_clusters | Map of EKS cluster information |
| cluster_endpoints | EKS cluster endpoints |
| cluster_arns | EKS cluster ARNs |
| cluster_certificate_authorities | EKS cluster certificate authority data |
| node_groups | Map of EKS node group information |
| fargate_profiles | Map of EKS Fargate profile information |
| addons | Map of EKS add-on information |
| oidc_provider_arns | EKS OIDC identity provider ARNs |
| kubeconfig | kubectl configuration for connecting to clusters |

## Supported Kubernetes Versions

The module supports all currently available EKS Kubernetes versions:
- **1.24** (Deprecated - use for legacy workloads only)
- **1.25** (Deprecated - upgrade recommended)
- **1.26** (Supported)
- **1.27** (Supported)
- **1.28** (Recommended)
- **1.29** (Latest)

## Node Group Types

### Managed Node Groups
- **On-Demand**: Predictable pricing and availability
- **Spot**: Cost-optimized with potential interruptions
- **Mixed**: Combination of On-Demand and Spot instances

### AMI Types
- **AL2_x86_64**: Amazon Linux 2 with x86_64 architecture
- **AL2_x86_64_GPU**: Amazon Linux 2 with GPU support
- **AL2_ARM_64**: Amazon Linux 2 with ARM64 architecture (Graviton processors)
- **BOTTLEROCKET_ARM_64**: Bottlerocket Linux with ARM64
- **BOTTLEROCKET_x86_64**: Bottlerocket Linux with x86_64
- **WINDOWS_CORE_2019_x86_64**: Windows Server 2019 Core
- **WINDOWS_FULL_2019_x86_64**: Windows Server 2019 Full
- **WINDOWS_CORE_2022_x86_64**: Windows Server 2022 Core
- **WINDOWS_FULL_2022_x86_64**: Windows Server 2022 Full

## Essential Add-ons

### Core Add-ons
```hcl
addons = {
  "vpc-cni" = {
    addon_version = "v1.15.1-eksbuild.1"
    configuration_values = jsonencode({
      enableNetworkPolicy = "true"
      warmENITarget      = "1"
      warmIPTarget       = "5"
    })
  }
  
  "coredns" = {
    addon_version = "v1.10.1-eksbuild.4"
    configuration_values = jsonencode({
      computeType = "Fargate"  # or "ec2"
      resources = {
        limits = {
          memory = "170Mi"
        }
        requests = {
          cpu    = "100m"
          memory = "70Mi"
        }
      }
    })
  }
  
  "kube-proxy" = {
    addon_version = "v1.28.2-eksbuild.2"
  }
}
```

### Storage Add-ons
```hcl
addons = {
  "aws-ebs-csi-driver" = {
    addon_version            = "v1.24.1-eksbuild.1"
    service_account_role_arn = aws_iam_role.ebs_csi_driver.arn
    configuration_values = jsonencode({
      defaultStorageClass = {
        enabled = true
      }
      storageClasses = [
        {
          name = "gp3"
          annotations = {
            "storageclass.kubernetes.io/is-default-class" = "true"
          }
          parameters = {
            type = "gp3"
            fsType = "ext4"
          }
        }
      ]
    })
  }
  
  "aws-efs-csi-driver" = {
    addon_version            = "v1.7.1-eksbuild.1"
    service_account_role_arn = aws_iam_role.efs_csi_driver.arn
  }
}
```

### Networking Add-ons
```hcl
addons = {
  "aws-load-balancer-controller" = {
    addon_version            = "v2.6.1-eksbuild.1"
    service_account_role_arn = aws_iam_role.aws_load_balancer_controller.arn
    configuration_values = jsonencode({
      clusterName = var.cluster_name
      serviceAccount = {
        create = false
        name   = "aws-load-balancer-controller"
      }
    })
  }
}
```

## Security Best Practices

### 1. Network Security
- **Private Clusters**: Deploy clusters with private endpoints only
- **Security Groups**: Implement least-privilege security group rules
- **Network Policies**: Use Calico or other CNI plugins for pod-to-pod security
- **VPC Integration**: Deploy in private subnets with NAT gateway access

### 2. IAM and RBAC
- **IRSA (IAM Roles for Service Accounts)**: Use OIDC for secure pod-to-AWS API access
- **Cluster Access**: Implement proper RBAC with AWS IAM integration
- **Service Accounts**: Create dedicated service accounts for each application
- **Least Privilege**: Grant minimal required permissions

### 3. Encryption and Secrets Management
- **Encryption at Rest**: Enable envelope encryption for Kubernetes secrets
- **Encryption in Transit**: All communication encrypted with TLS
- **External Secrets**: Use AWS Secrets Manager or Parameter Store
- **Key Management**: Customer-managed KMS keys for enhanced security

### 4. Pod Security
- **Pod Security Standards**: Implement Kubernetes Pod Security Standards
- **Security Contexts**: Configure appropriate security contexts for pods
- **Network Policies**: Restrict pod-to-pod communication
- **Image Security**: Use trusted registries and scan images for vulnerabilities

## Monitoring and Observability

### Control Plane Logging
```hcl
enabled_cluster_log_types = [
  "api",              # API server requests
  "audit",            # Audit logs
  "authenticator",    # Authenticator logs
  "controllerManager", # Controller manager logs
  "scheduler"         # Scheduler logs
]
```

### Container Insights
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: amazon-cloudwatch
  labels:
    name: amazon-cloudwatch

---
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: cloudwatch-agent
  namespace: amazon-cloudwatch
spec:
  # CloudWatch Agent configuration
```

### Prometheus and Grafana
```yaml
# Install using Helm
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --set grafana.adminPassword=admin123
```

## Cost Optimization

### 1. Right-sizing Node Groups
```hcl
# Use diverse instance types for better spot availability
instance_types = ["t3.medium", "t3.large", "m5.large", "m5a.large"]

# Enable cluster autoscaler
labels = {
  "k8s.io/cluster-autoscaler/enabled" = "true"
  "k8s.io/cluster-autoscaler/${cluster_name}" = "owned"
}
```

### 2. Spot Instances
```hcl
node_groups = {
  "spot-workers" = {
    capacity_type  = "SPOT"
    instance_types = ["t3.medium", "t3.large", "m5.large"]
    
    scaling_config = {
      desired_size = 3
      max_size     = 20
      min_size     = 0
    }
  }
}
```

### 3. Fargate for Batch Jobs
```hcl
fargate_profiles = {
  "batch-jobs" = {
    selectors = [
      {
        namespace = "batch"
        labels = {
          compute-type = "fargate"
        }
      }
    ]
  }
}
```

## Troubleshooting

### Common Issues

#### 1. Node Group Creation Fails
```
Error: InvalidParameterException: The following supplied subnets do not exist
```
**Solution**: Verify subnet IDs are correct and exist in the same region.

#### 2. Pods Cannot Pull Images
```
Error: ImagePullBackOff
```
**Solutions**:
- Check IAM permissions for ECR access
- Verify VPC endpoints for ECR if using private subnets
- Ensure internet connectivity through NAT gateway

#### 3. Load Balancer Controller Issues
```
Error: failed to build load balancer configuration
```
**Solutions**:
- Verify IAM role for service account is correctly configured
- Check subnet tags for load balancer discovery
- Ensure security groups allow required traffic

#### 4. Cluster Autoscaler Not Working
```
Warning: FailedScheduling - insufficient cpu
```
**Solutions**:
- Verify cluster autoscaler has proper IAM permissions
- Check node group tags for cluster autoscaler discovery
- Review scaling policies and limits

### Debugging Commands

```bash
# Check cluster status
aws eks describe-cluster --name cluster-name

# Get cluster endpoint and certificate
aws eks update-kubeconfig --name cluster-name

# Check node groups
aws eks describe-nodegroup --cluster-name cluster-name --nodegroup-name nodegroup-name

# View cluster logs
aws logs describe-log-groups --log-group-name-prefix /aws/eks/cluster-name

# Check add-on status
aws eks describe-addon --cluster-name cluster-name --addon-name vpc-cni

# Kubernetes troubleshooting
kubectl get nodes
kubectl describe node node-name
kubectl get pods --all-namespaces
kubectl describe pod pod-name -n namespace
kubectl logs pod-name -n namespace
```

## Integration Examples

### CI/CD Pipeline Integration
```yaml
# GitHub Actions example
name: Deploy to EKS
on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    
    - name: Configure AWS credentials
      uses: aws-actions/configure-aws-credentials@v2
      with:
        aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
        aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        aws-region: us-west-2
    
    - name: Update kubeconfig
      run: |
        aws eks update-kubeconfig --name ${{ secrets.CLUSTER_NAME }}
    
    - name: Deploy to EKS
      run: |
        kubectl apply -f k8s/
```

### Application Deployment
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: sample-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: sample-app
  template:
    metadata:
      labels:
        app: sample-app
    spec:
      serviceAccountName: sample-app-sa
      nodeSelector:
        role: general
      containers:
      - name: app
        image: nginx:latest
        ports:
        - containerPort: 80
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "200m"

---
apiVersion: v1
kind: Service
metadata:
  name: sample-app-service
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-type: "nlb"
spec:
  type: LoadBalancer
  selector:
    app: sample-app
  ports:
  - port: 80
    targetPort: 80
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make changes following the coding standards
4. Add tests for new functionality
5. Update documentation
6. Submit a pull request

### Development Guidelines

- Follow Terraform best practices
- Use meaningful variable names and descriptions
- Add comprehensive validation rules
- Include examples in documentation
- Test with multiple Kubernetes versions
- Ensure backward compatibility

## License

This module is licensed under the MIT License. See [LICENSE](LICENSE) for full details.

## Authors

- **Diego A. Zarate** - *Initial work* - [GitHub Profile](https://github.com/dzarate)

## Acknowledgments

- AWS EKS documentation and best practices
- Kubernetes community documentation
- Terraform AWS Provider documentation
- AWS Well-Architected Framework
- Community feedback and contributions

---

**Note**: This module follows semantic versioning. Please check the [CHANGELOG](CHANGELOG.md) for version-specific changes and migration guides.