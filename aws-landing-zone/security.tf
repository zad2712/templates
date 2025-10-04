# Security Configuration for AWS Landing Zone

# Default Security Group
resource "aws_security_group" "default" {
  name_prefix = "${var.organization_name}-${var.environment}-default-"
  vpc_id      = aws_vpc.main.id
  description = "Default security group for ${var.organization_name} ${var.environment} environment"

  # No ingress rules by default (deny all inbound)
  
  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = merge(local.common_tags, {
    Name = "${var.organization_name}-${var.environment}-default-sg"
    Type = "Security"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Web Security Group (for load balancers)
resource "aws_security_group" "web" {
  name_prefix = "${var.organization_name}-${var.environment}-web-"
  vpc_id      = aws_vpc.main.id
  description = "Security group for web-facing resources"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = merge(local.common_tags, {
    Name = "${var.organization_name}-${var.environment}-web-sg"
    Type = "Security"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Application Security Group
resource "aws_security_group" "application" {
  name_prefix = "${var.organization_name}-${var.environment}-app-"
  vpc_id      = aws_vpc.main.id
  description = "Security group for application servers"

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.web.id]
    description     = "HTTP from web tier"
  }

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.web.id]
    description     = "HTTPS from web tier"
  }

  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.web.id]
    description     = "Application port from web tier"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = merge(local.common_tags, {
    Name = "${var.organization_name}-${var.environment}-app-sg"
    Type = "Security"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Database Security Group
resource "aws_security_group" "database" {
  name_prefix = "${var.organization_name}-${var.environment}-db-"
  vpc_id      = aws_vpc.main.id
  description = "Security group for database servers"

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.application.id]
    description     = "MySQL from application tier"
  }

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.application.id]
    description     = "PostgreSQL from application tier"
  }

  ingress {
    from_port       = 1433
    to_port         = 1433
    protocol        = "tcp"
    security_groups = [aws_security_group.application.id]
    description     = "SQL Server from application tier"
  }

  ingress {
    from_port       = 1521
    to_port         = 1521
    protocol        = "tcp"
    security_groups = [aws_security_group.application.id]
    description     = "Oracle from application tier"
  }

  # No outbound rules needed for database tier

  tags = merge(local.common_tags, {
    Name = "${var.organization_name}-${var.environment}-db-sg"
    Type = "Security"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Management Security Group (for bastion hosts, etc.)
resource "aws_security_group" "management" {
  name_prefix = "${var.organization_name}-${var.environment}-mgmt-"
  vpc_id      = aws_vpc.main.id
  description = "Security group for management resources"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Should be restricted to specific IP ranges in production
    description = "SSH access"
  }

  ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Should be restricted to specific IP ranges in production
    description = "RDP access"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = merge(local.common_tags, {
    Name = "${var.organization_name}-${var.environment}-mgmt-sg"
    Type = "Security"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Network ACLs - Public
resource "aws_network_acl" "public" {
  vpc_id     = aws_vpc.main.id
  subnet_ids = aws_subnet.public[*].id

  # Inbound rules
  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 110
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 120
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 22
    to_port    = 22
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 130
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 3389
    to_port    = 3389
  }

  # Allow return traffic
  ingress {
    protocol   = "tcp"
    rule_no    = 140
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  # Outbound rules
  egress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = merge(local.common_tags, {
    Name = "${var.organization_name}-${var.environment}-public-nacl"
    Type = "Security"
  })
}

# Network ACLs - Private
resource "aws_network_acl" "private" {
  vpc_id     = aws_vpc.main.id
  subnet_ids = aws_subnet.private[*].id

  # Allow traffic from VPC
  ingress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = var.vpc_cidr
    from_port  = 0
    to_port    = 0
  }

  # Allow return traffic
  ingress {
    protocol   = "tcp"
    rule_no    = 110
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  # Outbound rules
  egress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = merge(local.common_tags, {
    Name = "${var.organization_name}-${var.environment}-private-nacl"
    Type = "Security"
  })
}

# Network ACLs - Database
resource "aws_network_acl" "database" {
  vpc_id     = aws_vpc.main.id
  subnet_ids = aws_subnet.database[*].id

  # Allow traffic from private subnets only
  ingress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = local.private_subnets[0]
    from_port  = 0
    to_port    = 0
  }

  dynamic "ingress" {
    for_each = length(local.private_subnets) > 1 ? slice(local.private_subnets, 1, length(local.private_subnets)) : []
    content {
      protocol   = -1
      rule_no    = 100 + (index(slice(local.private_subnets, 1, length(local.private_subnets)), ingress.value) + 1) * 10
      action     = "allow"
      cidr_block = ingress.value
      from_port  = 0
      to_port    = 0
    }
  }

  # Allow return traffic to private subnets
  egress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = local.private_subnets[0]
    from_port  = 0
    to_port    = 0
  }

  dynamic "egress" {
    for_each = length(local.private_subnets) > 1 ? slice(local.private_subnets, 1, length(local.private_subnets)) : []
    content {
      protocol   = -1
      rule_no    = 100 + (index(slice(local.private_subnets, 1, length(local.private_subnets)), egress.value) + 1) * 10
      action     = "allow"
      cidr_block = egress.value
      from_port  = 0
      to_port    = 0
    }
  }

  tags = merge(local.common_tags, {
    Name = "${var.organization_name}-${var.environment}-database-nacl"
    Type = "Security"
  })
}

# IAM Role for EC2 instances
resource "aws_iam_role" "ec2_role" {
  name_prefix = "${var.organization_name}-${var.environment}-ec2-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "${var.organization_name}-${var.environment}-ec2-role"
    Type = "Security"
  })
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "ec2_profile" {
  name_prefix = "${var.organization_name}-${var.environment}-ec2-"
  role        = aws_iam_role.ec2_role.name

  tags = merge(local.common_tags, {
    Name = "${var.organization_name}-${var.environment}-ec2-profile"
    Type = "Security"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# IAM Policy for EC2 CloudWatch and Systems Manager
resource "aws_iam_role_policy" "ec2_policy" {
  name_prefix = "${var.organization_name}-${var.environment}-ec2-"
  role        = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:ListMetrics",
          "ec2:DescribeVolumes",
          "ec2:DescribeTags",
          "logs:PutLogEvents",
          "logs:CreateLogGroup",
          "logs:CreateLogStream"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ssm:UpdateInstanceInformation",
          "ssm:SendCommand",
          "ssm:ListCommands",
          "ssm:ListCommandInvocations",
          "ssm:DescribeInstanceInformation",
          "ssm:GetParameters",
          "ssm:GetParameter"
        ]
        Resource = "*"
      }
    ]
  })
}