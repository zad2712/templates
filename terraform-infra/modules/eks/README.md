# EKS Terraform Module

## Overview

This Terraform module creates a production-ready **Amazon Elastic Kubernetes Service (EKS)** cluster with cost optimization features, enterprise security, and the latest marketplace add-ons. The module follows AWS best practices and provides a complete Kubernetes platform with monitoring, autoscaling, and security features built-in.

## Features

### 🚀 **Core EKS Features**
- **Managed Control Plane**: AWS-managed Kubernetes API server with automatic updates
- **Multi-AZ Worker Nodes**: Highly available node groups across availability zones
- **Fargate Support**: Serverless container execution for specific workloads
- **Latest Kubernetes**: Version 1.30 with latest EKS add-ons
- **Cost Optimization**: SPOT instances, right-sizing, and efficient resource allocation

### 🔒 **Security & Compliance**
- **IAM Integration**: Fine-grained access control with RBAC
- **Network Security**: Private API endpoints, security groups, and network policies
- **Encryption**: Secrets encryption at rest with KMS
- **Pod Security**: Security contexts and admission controllers
- **Audit Logging**: Comprehensive cluster activity logging

### 📦 **Marketplace Add-ons**
- **AWS Load Balancer Controller** v1.8.1 - ALB/NLB Ingress support
- **Cluster Autoscaler** v9.37.0 - Automatic node scaling
- **Metrics Server** v3.12.1 - Resource utilization metrics for HPA
- **AWS Node Termination Handler** - Graceful SPOT instance handling
- **External DNS** - Automatic DNS record management

### 📊 **Monitoring & Observability**
- **CloudWatch Container Insights**: Detailed cluster and pod metrics
- **Prometheus Ready**: Metrics collection for custom monitoring
- **Audit Logging**: API server activity tracking
- **VPC Flow Logs Integration**: Network traffic analysis

## Architecture

### 🏗️ **Cluster Architecture**

```
┌─────────────────────────────────────────────────────────────────┐
│                     EKS Control Plane                          │
│                   (AWS Managed)                                │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│  │  Worker Nodes   │  │  Worker Nodes   │  │  Worker Nodes   │ │
│  │    (AZ-1)       │  │    (AZ-2)       │  │    (AZ-3)       │ │
│  │                 │  │                 │  │                 │ │
│  │ ┌─────────────┐ │  │ ┌─────────────┐ │  │ ┌─────────────┐ │ │
│  │ │   Pod       │ │  │ │   Pod       │ │  │ │   Pod       │ │ │
│  │ │             │ │  │ │             │ │  │ │             │ │ │
│  │ └─────────────┘ │  │ └─────────────┘ │  │ └─────────────┘ │ │
│  │ ┌─────────────┐ │  │ ┌─────────────┐ │  │ ┌─────────────┐ │ │
│  │ │   Pod       │ │  │ │   Pod       │ │  │ │   Pod       │ │ │
│  │ └─────────────┘ │  │ └─────────────┘ │  │ └─────────────┘ │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘ │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                Fargate Profiles                         │   │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐     │   │
│  │  │ Serverless  │  │ Serverless  │  │ Serverless  │     │   │
│  │  │    Pod      │  │    Pod      │  │    Pod      │     │   │
│  │  └─────────────┘  └─────────────┘  └─────────────┘     │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

### 📋 **Add-ons Architecture**

```
┌─────────────────────────────────────────────────────────────────┐
│                    EKS Cluster                                  │
├─────────────────────────────────────────────────────────────────┤
│  kube-system namespace                                          │
│  ├─ AWS Load Balancer Controller (ALB/NLB Ingress)            │
│  ├─ Cluster Autoscaler (Node Scaling)                         │
│  ├─ Metrics Server (HPA Support)                              │
│  ├─ CoreDNS (Service Discovery)                               │
│  ├─ AWS VPC CNI (Networking)                                  │
│  └─ kube-proxy (Load Balancing)                               │
│                                                                 │
│  monitoring namespace (optional)                                │
│  ├─ Prometheus (Metrics Collection)                            │
│  ├─ Grafana (Visualization)                                    │
│  └─ AlertManager (Alerting)                                    │
└─────────────────────────────────────────────────────────────────┘
```

## Usage Examples

### Basic EKS Cluster

```hcl
module "eks" {
  source = "../../modules/eks"

  # Basic configuration
  create_cluster  = true
  cluster_name    = "my-eks-cluster"
  cluster_version = "1.30"
  
  # Network configuration
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets
  
  # Basic node group
  node_groups = {
    general = {
      instance_types = ["t3.medium"]
      capacity_type  = "ON_DEMAND"
      desired_size   = 2
      max_size      = 5
      min_size      = 1
      disk_size     = 50
    }
  }
  
  # Essential add-ons
  enable_aws_load_balancer_controller = true
  enable_cluster_autoscaler          = true
  enable_metrics_server              = true
  
  tags = {
    Environment = "development"
    Project     = "my-app"
  }
}
```

### Production EKS Cluster with Cost Optimization

```hcl
module "production_eks" {
  source = "../../modules/eks"

  # Cluster configuration
  create_cluster  = true
  cluster_name    = "prod-eks-cluster"
  cluster_version = "1.30"
  
  # Network and security
  vpc_id                                 = module.vpc.vpc_id
  subnet_ids                            = module.vpc.private_subnets
  cluster_endpoint_private_access       = true
  cluster_endpoint_public_access        = false  # Private cluster
  cluster_endpoint_public_access_cidrs  = []
  
  # Comprehensive logging
  cluster_enabled_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  
  # Multiple node groups for different workloads
  node_groups = {
    # General purpose nodes with SPOT instances
    general = {
      instance_types = ["m5.large", "m5.xlarge", "m5a.large", "m5a.xlarge"]
      capacity_type  = "SPOT"  # 90% cost savings
      desired_size   = 3
      max_size      = 20
      min_size      = 3
      disk_size     = 100
      
      labels = {
        role = "general"
        instance-type = "spot"
      }
      
      taints = []
    }
    
    # On-demand nodes for critical workloads
    critical = {
      instance_types = ["m5.large"]
      capacity_type  = "ON_DEMAND"
      desired_size   = 2
      max_size      = 5
      min_size      = 1
      disk_size     = 100
      
      labels = {
        role = "critical"
        instance-type = "on-demand"
      }
      
      taints = [
        {
          key    = "critical-workload"
          value  = "true"
          effect = "NO_SCHEDULE"
        }
      ]
    }
    
    # Monitoring nodes
    monitoring = {
      instance_types = ["t3.medium"]
      capacity_type  = "ON_DEMAND"
      desired_size   = 2
      max_size      = 3
      min_size      = 1
      disk_size     = 50
      
      labels = {
        role = "monitoring"
      }
      
      taints = [
        {
          key    = "monitoring"
          value  = "true"
          effect = "NO_SCHEDULE"
        }
      ]
    }
  }
  
  # Fargate profiles for serverless workloads
  fargate_profiles = {
    # System components on Fargate
    system = {
      selectors = [
        {
          namespace = "kube-system"
          labels = {
            component = "fargate"
          }
        }
      ]
    }
    
    # Application workloads on Fargate
    applications = {
      selectors = [
        {
          namespace = "prod-apps"
          labels = {
            compute-type = "fargate"
          }
        },
        {
          namespace = "staging-apps"
          labels = {
            compute-type = "fargate"
          }
        }
      ]
    }
  }
  
  # Latest EKS managed add-ons
  cluster_addons = {
    vpc-cni = {
      addon_version = "v1.18.1-eksbuild.1"
      resolve_conflicts = "OVERWRITE"
    }
    coredns = {
      addon_version = "v1.11.1-eksbuild.4"
      resolve_conflicts = "OVERWRITE"
    }
    kube-proxy = {
      addon_version = "v1.30.0-eksbuild.2"
      resolve_conflicts = "OVERWRITE"
    }
    aws-ebs-csi-driver = {
      addon_version = "v1.30.0-eksbuild.1"
      resolve_conflicts = "OVERWRITE"
    }
  }
  
  # Marketplace add-ons with latest versions
  enable_aws_load_balancer_controller = true
  aws_load_balancer_controller_chart_version = "1.8.1"
  
  enable_cluster_autoscaler = true
  cluster_autoscaler_chart_version = "9.37.0"
  
  enable_metrics_server = true
  metrics_server_chart_version = "3.12.1"
  
  enable_aws_node_termination_handler = true
  enable_external_dns = true
  external_dns_domain_name = "company.com"
  
  tags = {
    Environment = "production"
    Project     = "my-app"
    Backup      = "required"
    Compliance  = "SOC2"
    CostCenter  = "engineering"
  }
}
```

### Development EKS Cluster (Cost-Optimized)

```hcl
module "dev_eks" {
  source = "../../modules/eks"

  # Minimal configuration for development
  create_cluster  = true
  cluster_name    = "dev-eks-cluster"
  cluster_version = "1.30"
  
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets
  
  # Allow public access for development
  cluster_endpoint_public_access = true
  
  # Minimal logging
  cluster_enabled_log_types = ["api", "audit"]
  
  # Single node group with SPOT instances
  node_groups = {
    general = {
      instance_types = ["t3.small", "t3.medium"]
      capacity_type  = "SPOT"  # Maximum cost savings
      desired_size   = 1
      max_size      = 3
      min_size      = 1
      disk_size     = 20  # Smaller disks for development
      
      labels = {
        environment = "dev"
        cost-optimized = "true"
      }
    }
  }
  
  # Essential add-ons only
  cluster_addons = {
    vpc-cni = {
      addon_version = "v1.18.1-eksbuild.1"
    }
    coredns = {
      addon_version = "v1.11.1-eksbuild.4"
    }
    kube-proxy = {
      addon_version = "v1.30.0-eksbuild.2"
    }
  }
  
  # Minimal marketplace add-ons
  enable_aws_load_balancer_controller = true
  enable_metrics_server              = true
  
  tags = {
    Environment = "development"
    CostOptimized = "true"
  }
}
```

### Multi-Environment EKS Setup

```hcl
# Production cluster
module "prod_eks" {
  source = "../../modules/eks"
  
  cluster_name = "prod-cluster"
  # ... production configuration
}

# Staging cluster
module "staging_eks" {
  source = "../../modules/eks"
  
  cluster_name = "staging-cluster"
  # ... staging configuration
}

# Development cluster
module "dev_eks" {
  source = "../../modules/eks"
  
  cluster_name = "dev-cluster"
  # ... development configuration
}
```

## Configuration Options

### Required Variables

| Variable | Type | Description |
|----------|------|-------------|
| `cluster_name` | `string` | Name of the EKS cluster |
| `vpc_id` | `string` | ID of the VPC where cluster will be created |
| `subnet_ids` | `list(string)` | List of subnet IDs for the cluster |

### Core Configuration

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `create_cluster` | `bool` | `false` | Whether to create the EKS cluster |
| `cluster_version` | `string` | `"1.30"` | Kubernetes version |
| `cluster_endpoint_private_access` | `bool` | `true` | Enable private API access |
| `cluster_endpoint_public_access` | `bool` | `true` | Enable public API access |
| `cluster_enabled_log_types` | `list(string)` | `[]` | CloudWatch log types to enable |

### Node Groups Configuration

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `node_groups` | `map(object)` | `{}` | Map of node group configurations |

#### Node Group Object Structure

```hcl
{
  instance_types = list(string)  # EC2 instance types
  capacity_type  = string        # "ON_DEMAND" or "SPOT"
  desired_size   = number        # Desired number of nodes
  max_size      = number         # Maximum number of nodes
  min_size      = number         # Minimum number of nodes
  disk_size     = number         # EBS volume size in GB
  labels        = map(string)    # Kubernetes labels
  taints        = list(object)   # Kubernetes taints
}
```

### Fargate Configuration

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `fargate_profiles` | `map(object)` | `{}` | Map of Fargate profile configurations |

### Add-ons Configuration

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `cluster_addons` | `map(object)` | `{}` | EKS managed add-ons configuration |
| `enable_aws_load_balancer_controller` | `bool` | `false` | Enable AWS Load Balancer Controller |
| `enable_cluster_autoscaler` | `bool` | `false` | Enable Cluster Autoscaler |
| `enable_metrics_server` | `bool` | `false` | Enable Metrics Server |

## Outputs

### Cluster Information

| Output | Description |
|--------|-------------|
| `cluster_id` | EKS cluster ID |
| `cluster_arn` | EKS cluster ARN |
| `cluster_endpoint` | EKS cluster API server endpoint |
| `cluster_version` | EKS cluster Kubernetes version |
| `cluster_security_group_id` | EKS cluster security group ID |

### Authentication

| Output | Description |
|--------|-------------|
| `cluster_certificate_authority_data` | Base64 encoded certificate data |
| `cluster_oidc_issuer_url` | OIDC issuer URL for IAM roles |

### Node Groups

| Output | Description |
|--------|-------------|
| `node_groups` | Map of node group attributes |
| `fargate_profiles` | Map of Fargate profile attributes |

### IAM

| Output | Description |
|--------|-------------|
| `cluster_iam_role_arn` | EKS cluster IAM role ARN |
| `node_group_iam_role_arn` | EKS node group IAM role ARN |

## Best Practices

### 🔒 **Security Best Practices**

1. **Network Security**
   - Use private API endpoints for production clusters
   - Implement network policies to restrict pod-to-pod communication
   - Use security groups to control access to worker nodes

2. **IAM and RBAC**
   - Implement least-privilege access with IAM roles
   - Use Kubernetes RBAC for fine-grained permissions
   - Enable audit logging for compliance requirements

3. **Secrets Management**
   - Use AWS Secrets Manager or Parameter Store for sensitive data
   - Enable secrets encryption with customer-managed KMS keys
   - Rotate secrets regularly

### ⚡ **Performance Best Practices**

1. **Node Group Strategy**
   - Use multiple node groups for different workload types
   - Mix ON_DEMAND and SPOT instances based on workload criticality
   - Right-size instances based on actual resource usage

2. **Cluster Autoscaling**
   - Configure appropriate scaling policies
   - Use node affinity and anti-affinity rules
   - Implement pod disruption budgets for critical workloads

3. **Resource Management**
   - Set resource requests and limits for all containers
   - Use Horizontal Pod Autoscaler (HPA) for application scaling
   - Monitor and optimize cluster utilization

### 💰 **Cost Optimization**

1. **Instance Selection**
   - **SPOT Instances**: Use for development and fault-tolerant workloads (90% savings)
   - **Reserved Instances**: Purchase for predictable production workloads (30-50% savings)
   - **Rightsizing**: Monitor and adjust instance types based on actual usage

2. **Cluster Efficiency**
   - Use cluster autoscaler to scale down unused nodes
   - Implement pod packing to maximize node utilization
   - Consider Fargate for workloads with variable traffic patterns

3. **Monitoring and Optimization**
   - Use AWS Cost Explorer to analyze EKS costs
   - Implement resource quotas and limits
   - Regular cost reviews and optimization cycles

## Integration Examples

### ALB Ingress Integration

```yaml
# Application Load Balancer Ingress
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-app-ingress
  annotations:
    kubernetes.io/ingress.class: alb
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
spec:
  rules:
    - http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: my-app-service
                port:
                  number: 80
```

### Horizontal Pod Autoscaler

```yaml
# HPA with custom metrics
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: my-app-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: my-app
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
```

### SPOT Instance Handling

```yaml
# Node affinity for SPOT instances
apiVersion: apps/v1
kind: Deployment
metadata:
  name: batch-job
spec:
  replicas: 3
  template:
    spec:
      affinity:
        nodeAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 50
            preference:
              matchExpressions:
              - key: node.kubernetes.io/instance-type
                operator: In
                values: ["m5.large", "m5.xlarge"]
              - key: eks.amazonaws.com/capacityType
                operator: In
                values: ["SPOT"]
```

## Post-Deployment Configuration

### kubectl Configuration

```bash
# Configure kubectl to access the cluster
aws eks update-kubeconfig --region us-east-1 --name my-eks-cluster

# Verify cluster access
kubectl get nodes
kubectl get pods --all-namespaces

# Check cluster info
kubectl cluster-info
```

### Add-on Verification

```bash
# Verify AWS Load Balancer Controller
kubectl get deployment -n kube-system aws-load-balancer-controller

# Check Cluster Autoscaler
kubectl get deployment -n kube-system cluster-autoscaler

# Verify Metrics Server
kubectl get deployment -n kube-system metrics-server

# Test HPA functionality
kubectl top nodes
kubectl top pods
```

### Cluster Monitoring

```bash
# Check node status
kubectl describe nodes

# Monitor cluster events
kubectl get events --sort-by=.metadata.creationTimestamp

# Check resource utilization
kubectl top nodes
kubectl top pods --all-namespaces
```

## Troubleshooting

### Common Issues

#### **Node Group Scaling Issues**
```bash
# Check autoscaler logs
kubectl logs -f deployment/cluster-autoscaler -n kube-system

# Verify node group configuration
aws eks describe-nodegroup --cluster-name my-cluster --nodegroup-name my-nodegroup
```

#### **Pod Scheduling Problems**
```bash
# Check pod status
kubectl get pods -o wide

# Describe problematic pods
kubectl describe pod <pod-name>

# Check node resources
kubectl describe nodes
```

#### **Load Balancer Controller Issues**
```bash
# Check controller logs
kubectl logs -f deployment/aws-load-balancer-controller -n kube-system

# Verify IAM permissions
aws iam get-role --role-name AmazonEKSLoadBalancerControllerRole
```

## Requirements

- **Terraform**: >= 1.6.0
- **AWS Provider**: ~> 5.70
- **Kubernetes Provider**: ~> 2.24
- **Helm Provider**: ~> 2.10
- **AWS CLI**: Latest version for post-deployment configuration
- **kubectl**: Compatible with Kubernetes 1.30

## Related Documentation

- [Amazon EKS User Guide](https://docs.aws.amazon.com/eks/latest/userguide/)
- [EKS Best Practices Guide](https://aws.github.io/aws-eks-best-practices/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [AWS Load Balancer Controller](https://kubernetes-sigs.github.io/aws-load-balancer-controller/)
- [Cluster Autoscaler](https://github.com/kubernetes/autoscaler/tree/master/cluster-autoscaler)

---

> 🚀 **Container Orchestration Excellence**: This EKS module provides enterprise-grade Kubernetes infrastructure with cost optimization, security, and operational excellence built-in from day one.