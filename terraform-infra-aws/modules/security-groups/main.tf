# Security Groups Module - Main Configuration
# Author: Diego A. Zarate
# This module creates security groups with predefined and custom rules following AWS best practices

# Web-tier security group (ALB/NLB)
resource "aws_security_group" "web" {
  count = var.create_web_sg ? 1 : 0

  name        = "${var.name_prefix}-web-sg"
  description = "Security group for web tier load balancers"
  vpc_id      = var.vpc_id

  # HTTP ingress
  dynamic "ingress" {
    for_each = var.web_http_ingress_cidr_blocks
    content {
      description = "HTTP from ${ingress.value}"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
    }
  }

  # HTTPS ingress
  dynamic "ingress" {
    for_each = var.web_https_ingress_cidr_blocks
    content {
      description = "HTTPS from ${ingress.value}"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
    }
  }

  # Custom ports ingress
  dynamic "ingress" {
    for_each = var.web_custom_ingress_rules
    content {
      description = ingress.value.description
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }

  # Egress to application tier
  egress {
    description     = "To application tier"
    from_port       = var.app_port
    to_port         = var.app_port
    protocol        = "tcp"
    security_groups = var.create_app_sg ? [aws_security_group.app[0].id] : []
  }

  # Internet egress for health checks and external services
  egress {
    description = "Internet egress"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = var.enable_internet_egress ? ["0.0.0.0/0"] : []
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-web-sg"
    Tier = "web"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Application-tier security group
resource "aws_security_group" "app" {
  count = var.create_app_sg ? 1 : 0

  name        = "${var.name_prefix}-app-sg"
  description = "Security group for application tier"
  vpc_id      = var.vpc_id

  # Ingress from web tier
  dynamic "ingress" {
    for_each = var.create_web_sg ? [1] : []
    content {
      description     = "From web tier"
      from_port       = var.app_port
      to_port         = var.app_port
      protocol        = "tcp"
      security_groups = [aws_security_group.web[0].id]
    }
  }

  # Ingress from bastion/management
  dynamic "ingress" {
    for_each = var.app_management_ingress_cidr_blocks
    content {
      description = "SSH from management"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
    }
  }

  # Custom ingress rules
  dynamic "ingress" {
    for_each = var.app_custom_ingress_rules
    content {
      description = ingress.value.description
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = lookup(ingress.value, "cidr_blocks", null)
      security_groups = lookup(ingress.value, "security_groups", null)
    }
  }

  # Egress to database tier
  egress {
    description     = "To database tier"
    from_port       = var.database_port
    to_port         = var.database_port
    protocol        = "tcp"
    security_groups = var.create_db_sg ? [aws_security_group.db[0].id] : []
  }

  # Egress to cache tier
  egress {
    description     = "To cache tier"
    from_port       = var.cache_port
    to_port         = var.cache_port
    protocol        = "tcp"
    security_groups = var.create_cache_sg ? [aws_security_group.cache[0].id] : []
  }

  # Internet egress for package updates and external APIs
  egress {
    description = "Internet egress"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = var.enable_internet_egress ? ["0.0.0.0/0"] : []
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-app-sg"
    Tier = "application"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Database-tier security group
resource "aws_security_group" "db" {
  count = var.create_db_sg ? 1 : 0

  name        = "${var.name_prefix}-db-sg"
  description = "Security group for database tier"
  vpc_id      = var.vpc_id

  # Ingress from application tier
  dynamic "ingress" {
    for_each = var.create_app_sg ? [1] : []
    content {
      description     = "From application tier"
      from_port       = var.database_port
      to_port         = var.database_port
      protocol        = "tcp"
      security_groups = [aws_security_group.app[0].id]
    }
  }

  # Ingress from management/bastion for maintenance
  dynamic "ingress" {
    for_each = var.db_management_ingress_cidr_blocks
    content {
      description = "Database access from management"
      from_port   = var.database_port
      to_port     = var.database_port
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
    }
  }

  # Custom ingress rules for database
  dynamic "ingress" {
    for_each = var.db_custom_ingress_rules
    content {
      description = ingress.value.description
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = lookup(ingress.value, "cidr_blocks", null)
      security_groups = lookup(ingress.value, "security_groups", null)
    }
  }

  # No egress rules by default (databases should not initiate outbound connections)
  # Custom egress rules can be added via variables if needed

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-db-sg"
    Tier = "database"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Cache-tier security group (ElastiCache)
resource "aws_security_group" "cache" {
  count = var.create_cache_sg ? 1 : 0

  name        = "${var.name_prefix}-cache-sg"
  description = "Security group for cache tier (ElastiCache)"
  vpc_id      = var.vpc_id

  # Ingress from application tier
  dynamic "ingress" {
    for_each = var.create_app_sg ? [1] : []
    content {
      description     = "From application tier"
      from_port       = var.cache_port
      to_port         = var.cache_port
      protocol        = "tcp"
      security_groups = [aws_security_group.app[0].id]
    }
  }

  # Custom ingress rules for cache
  dynamic "ingress" {
    for_each = var.cache_custom_ingress_rules
    content {
      description = ingress.value.description
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = lookup(ingress.value, "cidr_blocks", null)
      security_groups = lookup(ingress.value, "security_groups", null)
    }
  }

  # No egress rules by default (cache should not initiate outbound connections)

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-cache-sg"
    Tier = "cache"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Management/Bastion security group
resource "aws_security_group" "management" {
  count = var.create_management_sg ? 1 : 0

  name        = "${var.name_prefix}-management-sg"
  description = "Security group for management/bastion hosts"
  vpc_id      = var.vpc_id

  # SSH ingress from allowed IP ranges
  dynamic "ingress" {
    for_each = var.management_ssh_ingress_cidr_blocks
    content {
      description = "SSH from ${ingress.value}"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
    }
  }

  # RDP ingress for Windows bastion hosts
  dynamic "ingress" {
    for_each = var.management_rdp_ingress_cidr_blocks
    content {
      description = "RDP from ${ingress.value}"
      from_port   = 3389
      to_port     = 3389
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
    }
  }

  # Custom management ingress rules
  dynamic "ingress" {
    for_each = var.management_custom_ingress_rules
    content {
      description = ingress.value.description
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }

  # Egress to managed resources
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-management-sg"
    Tier = "management"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Lambda security group
resource "aws_security_group" "lambda" {
  count = var.create_lambda_sg ? 1 : 0

  name        = "${var.name_prefix}-lambda-sg"
  description = "Security group for Lambda functions"
  vpc_id      = var.vpc_id

  # Custom ingress rules for Lambda (usually none needed)
  dynamic "ingress" {
    for_each = var.lambda_custom_ingress_rules
    content {
      description = ingress.value.description
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = lookup(ingress.value, "cidr_blocks", null)
      security_groups = lookup(ingress.value, "security_groups", null)
    }
  }

  # Egress to databases and external services
  egress {
    description = "Database access"
    from_port   = var.database_port
    to_port     = var.database_port
    protocol    = "tcp"
    security_groups = var.create_db_sg ? [aws_security_group.db[0].id] : []
  }

  egress {
    description = "Cache access"
    from_port   = var.cache_port
    to_port     = var.cache_port
    protocol    = "tcp"
    security_groups = var.create_cache_sg ? [aws_security_group.cache[0].id] : []
  }

  egress {
    description = "Internet egress"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = var.enable_internet_egress ? ["0.0.0.0/0"] : []
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-lambda-sg"
    Tier = "serverless"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# EKS cluster security group
resource "aws_security_group" "eks_cluster" {
  count = var.create_eks_cluster_sg ? 1 : 0

  name        = "${var.name_prefix}-eks-cluster-sg"
  description = "Security group for EKS cluster control plane"
  vpc_id      = var.vpc_id

  # HTTPS ingress from worker nodes
  ingress {
    description     = "HTTPS from worker nodes"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = var.create_eks_workers_sg ? [aws_security_group.eks_workers[0].id] : []
  }

  # Custom ingress for EKS API access
  dynamic "ingress" {
    for_each = var.eks_cluster_custom_ingress_rules
    content {
      description = ingress.value.description
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = lookup(ingress.value, "cidr_blocks", null)
      security_groups = lookup(ingress.value, "security_groups", null)
    }
  }

  # Egress to worker nodes
  egress {
    description     = "All traffic to worker nodes"
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = var.create_eks_workers_sg ? [aws_security_group.eks_workers[0].id] : []
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-eks-cluster-sg"
    Tier = "kubernetes-control"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# EKS worker nodes security group
resource "aws_security_group" "eks_workers" {
  count = var.create_eks_workers_sg ? 1 : 0

  name        = "${var.name_prefix}-eks-workers-sg"
  description = "Security group for EKS worker nodes"
  vpc_id      = var.vpc_id

  # Ingress from cluster control plane
  ingress {
    description     = "From EKS cluster control plane"
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = var.create_eks_cluster_sg ? [aws_security_group.eks_cluster[0].id] : []
  }

  # Node-to-node communication
  ingress {
    description = "Node to node communication"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  # Pod-to-pod communication
  dynamic "ingress" {
    for_each = var.eks_pod_cidr_blocks
    content {
      description = "Pod to pod communication"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = [ingress.value]
    }
  }

  # Custom worker node ingress
  dynamic "ingress" {
    for_each = var.eks_workers_custom_ingress_rules
    content {
      description = ingress.value.description
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = lookup(ingress.value, "cidr_blocks", null)
      security_groups = lookup(ingress.value, "security_groups", null)
    }
  }

  # Egress to cluster control plane
  egress {
    description     = "To EKS cluster control plane"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = var.create_eks_cluster_sg ? [aws_security_group.eks_cluster[0].id] : []
  }

  # Internet egress for pulling images and updates
  egress {
    description = "Internet egress"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-eks-workers-sg"
    Tier = "kubernetes-workers"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Custom security groups from variable definitions
resource "aws_security_group" "custom" {
  for_each = var.custom_security_groups

  name        = "${var.name_prefix}-${each.key}-sg"
  description = each.value.description
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = each.value.ingress_rules
    content {
      description     = ingress.value.description
      from_port       = ingress.value.from_port
      to_port         = ingress.value.to_port
      protocol        = ingress.value.protocol
      cidr_blocks     = lookup(ingress.value, "cidr_blocks", null)
      security_groups = lookup(ingress.value, "security_groups", null)
      self            = lookup(ingress.value, "self", false)
    }
  }

  dynamic "egress" {
    for_each = each.value.egress_rules
    content {
      description     = egress.value.description
      from_port       = egress.value.from_port
      to_port         = egress.value.to_port
      protocol        = egress.value.protocol
      cidr_blocks     = lookup(egress.value, "cidr_blocks", null)
      security_groups = lookup(egress.value, "security_groups", null)
      self            = lookup(egress.value, "self", false)
    }
  }

  tags = merge(var.tags, each.value.tags, {
    Name = "${var.name_prefix}-${each.key}-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}