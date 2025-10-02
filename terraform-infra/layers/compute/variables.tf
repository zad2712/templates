# =============================================================================
# COMPUTE LAYER VARIABLES
# =============================================================================

variable "environment" {
  description = "Environment name (dev, qa, uat, prod)"
  type        = string
  validation {
    condition = contains(["dev", "qa", "uat", "prod"], var.environment)
    error_message = "Environment must be one of: dev, qa, uat, prod."
  }
}

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "AWS CLI profile to use"
  type        = string
  default     = "default"
}

variable "state_bucket" {
  description = "S3 bucket for storing Terraform state"
  type        = string
}

# =============================================================================
# LOAD BALANCER CONFIGURATION
# =============================================================================

variable "enable_load_balancer" {
  description = "Enable Application Load Balancer"
  type        = bool
  default     = true
}

variable "target_groups" {
  description = "Map of target groups for the load balancer"
  type = map(object({
    port     = number
    protocol = string
    health_check = object({
      enabled             = bool
      healthy_threshold   = number
      interval            = number
      matcher             = string
      path                = string
      port                = string
      protocol            = string
      timeout             = number
      unhealthy_threshold = number
    })
  }))
  default = {
    app = {
      port     = 80
      protocol = "HTTP"
      health_check = {
        enabled             = true
        healthy_threshold   = 2
        interval            = 30
        matcher             = "200"
        path                = "/"
        port                = "traffic-port"
        protocol            = "HTTP"
        timeout             = 5
        unhealthy_threshold = 2
      }
    }
  }
}

variable "alb_listeners" {
  description = "Map of listeners for the load balancer"
  type = map(object({
    port     = number
    protocol = string
    default_action = object({
      type             = string
      target_group_arn = optional(string)
      redirect = optional(object({
        port        = string
        protocol    = string
        status_code = string
      }))
    })
  }))
  default = {}
}

variable "ssl_certificate_arn" {
  description = "SSL certificate ARN for HTTPS listeners"
  type        = string
  default     = ""
}

# =============================================================================
# AUTO SCALING CONFIGURATION
# =============================================================================

variable "enable_auto_scaling" {
  description = "Enable Auto Scaling Group"
  type        = bool
  default     = true
}

variable "ami_id" {
  description = "AMI ID for EC2 instances"
  type        = string
  default     = ""
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "key_pair_name" {
  description = "EC2 Key Pair name"
  type        = string
  default     = ""
}

variable "user_data_script" {
  description = "User data script for EC2 instances"
  type        = string
  default     = ""
}

variable "asg_min_size" {
  description = "Minimum size of Auto Scaling Group"
  type        = number
  default     = 1
}

variable "asg_max_size" {
  description = "Maximum size of Auto Scaling Group"
  type        = number
  default     = 3
}

variable "asg_desired_capacity" {
  description = "Desired capacity of Auto Scaling Group"
  type        = number
  default     = 2
}

variable "ebs_volumes" {
  description = "EBS volumes configuration for EC2 instances"
  type = list(object({
    device_name = string
    ebs = object({
      volume_size           = number
      volume_type           = string
      delete_on_termination = bool
      encrypted             = bool
    })
  }))
  default = [
    {
      device_name = "/dev/xvda"
      ebs = {
        volume_size           = 20
        volume_type           = "gp3"
        delete_on_termination = true
        encrypted             = true
      }
    }
  ]
}

# =============================================================================
# ECS CONFIGURATION
# =============================================================================

variable "enable_ecs" {
  description = "Enable ECS cluster"
  type        = bool
  default     = false
}

variable "ecs_capacity_providers" {
  description = "ECS capacity providers"
  type        = list(string)
  default     = ["FARGATE", "FARGATE_SPOT"]
}

variable "enable_container_insights" {
  description = "Enable container insights for ECS"
  type        = bool
  default     = true
}

# =============================================================================
# LAMBDA CONFIGURATION
# =============================================================================

variable "lambda_functions" {
  description = "Map of Lambda functions to create"
  type = map(object({
    description  = string
    runtime      = string
    handler      = string
    filename     = optional(string)
    s3_bucket    = optional(string)
    s3_key       = optional(string)
    memory_size  = optional(number, 128)
    timeout      = optional(number, 3)
    environment_variables = optional(map(string), {})
  }))
  default = {}
}

# =============================================================================
# EKS CONFIGURATION
# =============================================================================

variable "enable_eks" {
  description = "Enable EKS cluster"
  type        = bool
  default     = false
}

variable "eks_cluster_version" {
  description = "Kubernetes version to use for the EKS cluster"
  type        = string
  default     = "1.30"
}

variable "eks_endpoint_private_access" {
  description = "Indicates whether or not the Amazon EKS private API server endpoint is enabled"
  type        = bool
  default     = true
}

variable "eks_endpoint_public_access" {
  description = "Indicates whether or not the Amazon EKS public API server endpoint is enabled"
  type        = bool
  default     = false
}

variable "eks_endpoint_public_access_cidrs" {
  description = "List of CIDR blocks that can access the Amazon EKS public API server endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "eks_cluster_log_types" {
  description = "A list of the desired control plane logging to enable"
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

variable "eks_log_retention_days" {
  description = "Number of days to retain log events in CloudWatch log group"
  type        = number
  default     = 7
}

variable "eks_encryption_enabled" {
  description = "Enable encryption of Kubernetes secrets"
  type        = bool
  default     = true
}

variable "eks_kms_key_id" {
  description = "The ARN of the Key Management Service (KMS) customer master key (CMK)"
  type        = string
  default     = ""
}

variable "eks_node_groups" {
  description = "Map of node group configurations"
  type = map(object({
    ami_type        = optional(string, "AL2_x86_64")
    instance_types  = optional(list(string), ["t3.medium"])
    capacity_type   = optional(string, "SPOT")
    disk_size       = optional(number, 20)
    desired_size    = optional(number, 1)
    max_size        = optional(number, 3)
    min_size        = optional(number, 1)
    max_unavailable_percentage = optional(number, 25)
    labels          = optional(map(string), {})
    taints          = optional(list(object({
      key    = string
      value  = string
      effect = string
    })), [])
  }))
  default = {}
}

variable "eks_fargate_profiles" {
  description = "Map of Fargate profiles configurations"
  type = map(object({
    selectors = list(object({
      namespace = string
      labels    = optional(map(string), {})
    }))
  }))
  default = {}
}

variable "eks_addons" {
  description = "Map of cluster addon configurations"
  type = map(object({
    addon_version               = optional(string)
    resolve_conflicts_on_create = optional(string, "OVERWRITE")
    resolve_conflicts_on_update = optional(string, "PRESERVE")
    service_account_role_arn    = optional(string)
  }))
  default = {
    vpc-cni = {
      addon_version = "v1.18.1-eksbuild.1"
    }
    coredns = {
      addon_version = "v1.11.1-eksbuild.4"
    }
    kube-proxy = {
      addon_version = "v1.30.0-eksbuild.2"
    }
    aws-ebs-csi-driver = {
      addon_version = "v1.30.0-eksbuild.1"
    }
  }
}

# =============================================================================
# EKS MARKETPLACE ADDONS CONFIGURATION
# =============================================================================

variable "enable_aws_load_balancer_controller" {
  description = "Enable AWS Load Balancer Controller"
  type        = bool
  default     = false
}

variable "aws_load_balancer_controller_chart_version" {
  description = "AWS Load Balancer Controller Helm chart version"
  type        = string
  default     = "1.8.1"
}

variable "aws_load_balancer_controller_namespace" {
  description = "Namespace to deploy AWS Load Balancer Controller"
  type        = string
  default     = "kube-system"
}

variable "enable_cluster_autoscaler" {
  description = "Enable Cluster Autoscaler"
  type        = bool
  default     = false
}

variable "cluster_autoscaler_chart_version" {
  description = "Cluster Autoscaler Helm chart version"
  type        = string
  default     = "9.37.0"
}

variable "cluster_autoscaler_namespace" {
  description = "Namespace to deploy Cluster Autoscaler"
  type        = string
  default     = "kube-system"
}

variable "enable_metrics_server" {
  description = "Enable Metrics Server"
  type        = bool
  default     = false
}

variable "metrics_server_chart_version" {
  description = "Metrics Server Helm chart version"
  type        = string
  default     = "3.12.1"
}

variable "metrics_server_namespace" {
  description = "Namespace to deploy Metrics Server"
  type        = string
  default     = "kube-system"
}

variable "enable_aws_node_termination_handler" {
  description = "Enable AWS Node Termination Handler"
  type        = bool
  default     = false
}

variable "aws_node_termination_handler_chart_version" {
  description = "AWS Node Termination Handler Helm chart version"
  type        = string
  default     = "0.21.0"
}

variable "aws_node_termination_handler_namespace" {
  description = "Namespace to deploy AWS Node Termination Handler"
  type        = string
  default     = "kube-system"
}

variable "enable_external_dns" {
  description = "Enable External DNS"
  type        = bool
  default     = false
}

variable "external_dns_chart_version" {
  description = "External DNS Helm chart version"
  type        = string
  default     = "1.13.1"
}

variable "external_dns_namespace" {
  description = "Namespace to deploy External DNS"
  type        = string
  default     = "kube-system"
}

variable "external_dns_domain_name" {
  description = "Domain name for External DNS"
  type        = string
  default     = ""
}

# =============================================================================
# TAGGING
# =============================================================================

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
