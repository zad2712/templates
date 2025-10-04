# Security Operations Guide

This comprehensive security guide provides detailed procedures, best practices, and compliance frameworks for securing your AWS infrastructure.

## Table of Contents

- [Security Framework Overview](#security-framework-overview)
- [Identity and Access Management](#identity-and-access-management)
- [Network Security](#network-security)
- [Data Protection](#data-protection)
- [Security Monitoring](#security-monitoring)
- [Incident Response](#incident-response)
- [Compliance and Governance](#compliance-and-governance)
- [Security Automation](#security-automation)
- [Vulnerability Management](#vulnerability-management)
- [Security Best Practices](#security-best-practices)

## Security Framework Overview

### Security Model

Our security implementation follows the **AWS Well-Architected Security Pillar** with defense-in-depth principles:

**Security Layers:**
1. **Identity & Access Management** - Authentication and authorization
2. **Infrastructure Security** - Network and compute protection
3. **Data Protection** - Encryption and data lifecycle management
4. **Detective Controls** - Monitoring and logging
5. **Incident Response** - Automated response and recovery
6. **Application Security** - Code security and runtime protection

### Security Responsibilities Matrix

| Layer | AWS Responsibility | Our Responsibility |
|-------|-------------------|-------------------|
| **Physical** | Data center security, hardware disposal | N/A |
| **Network** | Network infrastructure, DDoS protection | Security groups, NACLs, WAF rules |
| **Hypervisor** | Hypervisor patches, isolation | N/A |
| **Guest OS** | N/A | OS patches, configuration hardening |
| **Application** | N/A | Code security, application configuration |
| **Data** | N/A | Data encryption, access controls, backup |

### Security Standards Compliance

Our infrastructure maintains compliance with:

- **SOC 2 Type II** - Security, availability, processing integrity
- **PCI DSS** - Payment card industry standards
- **HIPAA** - Healthcare data protection (where applicable)
- **GDPR** - General Data Protection Regulation
- **ISO 27001** - Information security management
- **NIST Cybersecurity Framework** - Risk management framework

## Identity and Access Management

### IAM Policy Framework

**Principle of Least Privilege Implementation:**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DeveloperBasePermissions",
      "Effect": "Allow",
      "Action": [
        "ec2:DescribeInstances",
        "ec2:DescribeImages",
        "ec2:DescribeSecurityGroups",
        "ecs:DescribeClusters",
        "ecs:DescribeServices",
        "ecs:DescribeTasks",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams",
        "cloudwatch:DescribeAlarms",
        "cloudwatch:GetMetricStatistics"
      ],
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "aws:RequestedRegion": ["us-east-1", "us-west-2"]
        }
      }
    },
    {
      "Sid": "EnvironmentSpecificAccess",
      "Effect": "Allow",
      "Action": [
        "ec2:StartInstances",
        "ec2:StopInstances",
        "ec2:RebootInstances",
        "ecs:UpdateService",
        "ecs:StopTask"
      ],
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "ec2:ResourceTag/Environment": "${aws:PrincipalTag/AllowedEnvironments}"
        }
      }
    },
    {
      "Sid": "DenyProductionWrite",
      "Effect": "Deny",
      "Action": [
        "ec2:TerminateInstances",
        "rds:DeleteDBInstance",
        "s3:DeleteBucket"
      ],
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "ec2:ResourceTag/Environment": "prod"
        }
      }
    }
  ]
}
```

### Multi-Factor Authentication (MFA) Setup

**MFA Enforcement Script:**
```bash
#!/bin/bash
# Enforce MFA for all IAM users

echo "🔐 MFA Enforcement Report"
echo "========================"

# Get all IAM users
USERS=$(aws iam list-users --query 'Users[].UserName' --output text)

echo "👥 User MFA Status:"
echo "-------------------"

for user in $USERS; do
    # Check if user has MFA device
    MFA_DEVICES=$(aws iam list-mfa-devices --user-name $user --query 'MFADevices[].SerialNumber' --output text)
    
    if [ -n "$MFA_DEVICES" ]; then
        echo "✅ $user: MFA Enabled"
    else
        echo "❌ $user: MFA NOT Enabled"
        
        # Check if user has console access
        LOGIN_PROFILE=$(aws iam get-login-profile --user-name $user 2>/dev/null)
        
        if [ $? -eq 0 ]; then
            echo "   ⚠️  User has console access without MFA!"
            
            # Optionally enforce MFA policy
            echo "   🔧 Applying MFA enforcement policy..."
            
            cat > /tmp/enforce-mfa-policy.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowViewAccountInfo",
            "Effect": "Allow",
            "Action": [
                "iam:GetAccountPasswordPolicy",
                "iam:GetAccountSummary",
                "iam:ListVirtualMFADevices"
            ],
            "Resource": "*"
        },
        {
            "Sid": "AllowManageOwnPasswords",
            "Effect": "Allow",
            "Action": [
                "iam:ChangePassword",
                "iam:GetUser"
            ],
            "Resource": "arn:aws:iam::*:user/\${aws:username}"
        },
        {
            "Sid": "AllowManageOwnMFA",
            "Effect": "Allow",
            "Action": [
                "iam:CreateVirtualMFADevice",
                "iam:DeleteVirtualMFADevice",
                "iam:EnableMFADevice",
                "iam:ListMFADevices",
                "iam:ResyncMFADevice"
            ],
            "Resource": [
                "arn:aws:iam::*:mfa/\${aws:username}",
                "arn:aws:iam::*:user/\${aws:username}"
            ]
        },
        {
            "Sid": "DenyAllExceptUnlessSignedInWithMFA",
            "Effect": "Deny",
            "NotAction": [
                "iam:CreateVirtualMFADevice",
                "iam:EnableMFADevice",
                "iam:GetUser",
                "iam:ListMFADevices",
                "iam:ListVirtualMFADevices",
                "iam:ResyncMFADevice",
                "sts:GetSessionToken"
            ],
            "Resource": "*",
            "Condition": {
                "BoolIfExists": {
                    "aws:MultiFactorAuthPresent": "false"
                }
            }
        }
    ]
}
EOF
            
            # Create or update the policy
            aws iam put-user-policy \
                --user-name $user \
                --policy-name "EnforceMFA" \
                --policy-document file:///tmp/enforce-mfa-policy.json
                
            echo "   ✅ MFA enforcement policy applied to $user"
        fi
    fi
done

echo ""
echo "🔐 Service Account Analysis:"
echo "---------------------------"

# Check for service accounts with access keys
for user in $USERS; do
    ACCESS_KEYS=$(aws iam list-access-keys --user-name $user --query 'AccessKeyMetadata[].AccessKeyId' --output text)
    
    if [ -n "$ACCESS_KEYS" ]; then
        echo "🔑 $user: Has access keys"
        
        for key in $ACCESS_KEYS; do
            LAST_USED=$(aws iam get-access-key-last-used --access-key-id $key --query 'AccessKeyLastUsed.LastUsedDate' --output text)
            STATUS=$(aws iam list-access-keys --user-name $user --query "AccessKeyMetadata[?AccessKeyId=='$key'].Status" --output text)
            
            echo "   Key: $key"
            echo "   Status: $STATUS"
            echo "   Last Used: ${LAST_USED:-Never}"
            
            # Flag old or unused keys
            if [ "$LAST_USED" = "None" ] || [ -z "$LAST_USED" ]; then
                echo "   ⚠️  Key never used - consider deletion"
            else
                DAYS_AGO=$(( ($(date +%s) - $(date -d "$LAST_USED" +%s)) / 86400 ))
                if [ $DAYS_AGO -gt 90 ]; then
                    echo "   ⚠️  Key not used in $DAYS_AGO days - consider rotation"
                fi
            fi
            echo ""
        done
    fi
done

rm -f /tmp/enforce-mfa-policy.json
echo "✅ MFA enforcement analysis completed"
```

### Cross-Account Access Management

**Cross-Account Role Setup:**
```bash
#!/bin/bash
# Setup secure cross-account access

TRUSTED_ACCOUNT_ID=$1
ROLE_NAME=$2
ENVIRONMENT=$3

if [ -z "$TRUSTED_ACCOUNT_ID" ] || [ -z "$ROLE_NAME" ] || [ -z "$ENVIRONMENT" ]; then
    echo "❌ Usage: $0 <trusted_account_id> <role_name> <environment>"
    exit 1
fi

echo "🔗 Setting up cross-account access"
echo "=================================="
echo "Trusted Account: $TRUSTED_ACCOUNT_ID"
echo "Role Name: $ROLE_NAME"
echo "Environment: $ENVIRONMENT"
echo ""

# Create trust policy
cat > /tmp/trust-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::$TRUSTED_ACCOUNT_ID:root"
      },
      "Action": "sts:AssumeRole",
      "Condition": {
        "StringEquals": {
          "sts:ExternalId": "$(openssl rand -hex 32)"
        },
        "Bool": {
          "aws:MultiFactorAuthPresent": "true"
        },
        "NumericLessThan": {
          "aws:MultiFactorAuthAge": "3600"
        }
      }
    }
  ]
}
EOF

# Create the role
aws iam create-role \
    --role-name $ROLE_NAME \
    --assume-role-policy-document file:///tmp/trust-policy.json \
    --description "Cross-account access for $ENVIRONMENT environment"

# Create permission policy based on environment
case $ENVIRONMENT in
    "dev"|"staging")
        PERMISSIONS_POLICY='{
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Effect": "Allow",
                    "Action": [
                        "ec2:*",
                        "ecs:*",
                        "logs:*",
                        "cloudwatch:*"
                    ],
                    "Resource": "*",
                    "Condition": {
                        "StringEquals": {
                            "ec2:ResourceTag/Environment": "'$ENVIRONMENT'"
                        }
                    }
                }
            ]
        }'
        ;;
    "prod")
        PERMISSIONS_POLICY='{
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Effect": "Allow",
                    "Action": [
                        "ec2:Describe*",
                        "ecs:Describe*",
                        "ecs:List*",
                        "logs:Describe*",
                        "logs:Get*",
                        "cloudwatch:Describe*",
                        "cloudwatch:Get*",
                        "cloudwatch:List*"
                    ],
                    "Resource": "*"
                }
            ]
        }'
        ;;
esac

# Attach the policy
echo "$PERMISSIONS_POLICY" > /tmp/permissions-policy.json
aws iam put-role-policy \
    --role-name $ROLE_NAME \
    --policy-name "${ROLE_NAME}Policy" \
    --policy-document file:///tmp/permissions-policy.json

echo "✅ Cross-account role created: $ROLE_NAME"
echo "Role ARN: arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):role/$ROLE_NAME"

# Clean up
rm -f /tmp/trust-policy.json /tmp/permissions-policy.json
```

## Network Security

### Security Groups Management

**Security Group Audit Script:**
```bash
#!/bin/bash
# Comprehensive security group audit

ENVIRONMENT=${1:-all}

echo "🛡️  Security Group Security Audit"
echo "================================="
echo "Environment: $ENVIRONMENT"
echo "Date: $(date)"
echo ""

# Get security groups
if [ "$ENVIRONMENT" = "all" ]; then
    SECURITY_GROUPS=$(aws ec2 describe-security-groups --query 'SecurityGroups[].[GroupId,GroupName,VpcId]' --output text)
else
    SECURITY_GROUPS=$(aws ec2 describe-security-groups \
        --filters "Name=tag:Environment,Values=$ENVIRONMENT" \
        --query 'SecurityGroups[].[GroupId,GroupName,VpcId]' \
        --output text)
fi

echo "🔍 Security Group Analysis:"
echo "---------------------------"

while read -r group_id group_name vpc_id; do
    if [ -n "$group_id" ]; then
        echo "Security Group: $group_name ($group_id)"
        echo "VPC: $vpc_id"
        
        # Check for overly permissive rules
        RISKY_RULES=$(aws ec2 describe-security-groups \
            --group-ids $group_id \
            --query 'SecurityGroups[0].IpPermissions[?contains(IpRanges[].CidrIp, `0.0.0.0/0`) || contains(Ipv6Ranges[].CidrIpv6, `::/0`)]')
        
        if [ "$RISKY_RULES" != "[]" ]; then
            echo "⚠️  RISKY: Open to internet (0.0.0.0/0)"
            
            # Detail the risky rules
            aws ec2 describe-security-groups \
                --group-ids $group_id \
                --query 'SecurityGroups[0].IpPermissions[?contains(IpRanges[].CidrIp, `0.0.0.0/0`)].{Protocol:IpProtocol,FromPort:FromPort,ToPort:ToPort,Source:IpRanges[0].CidrIp}' \
                --output table
        fi
        
        # Check for unused security groups
        USAGE_CHECK=$(aws ec2 describe-network-interfaces \
            --filters "Name=group-id,Values=$group_id" \
            --query 'NetworkInterfaces[0].NetworkInterfaceId' \
            --output text)
        
        if [ "$USAGE_CHECK" = "None" ]; then
            echo "💰 UNUSED: No network interfaces attached"
        fi
        
        # Check for SSH access
        SSH_ACCESS=$(aws ec2 describe-security-groups \
            --group-ids $group_id \
            --query 'SecurityGroups[0].IpPermissions[?FromPort==`22` && ToPort==`22`]')
        
        if [ "$SSH_ACCESS" != "[]" ]; then
            echo "🔑 SSH access enabled"
            
            # Check if SSH is open to internet
            SSH_INTERNET=$(aws ec2 describe-security-groups \
                --group-ids $group_id \
                --query 'SecurityGroups[0].IpPermissions[?FromPort==`22` && ToPort==`22` && contains(IpRanges[].CidrIp, `0.0.0.0/0`)]')
            
            if [ "$SSH_INTERNET" != "[]" ]; then
                echo "🚨 CRITICAL: SSH open to internet!"
            fi
        fi
        
        echo "---"
    fi
done <<< "$SECURITY_GROUPS"

echo ""
echo "🔒 Security Recommendations:"
echo "----------------------------"
echo "1. Remove 0.0.0.0/0 access where not absolutely necessary"
echo "2. Use specific IP ranges or security group references"
echo "3. Implement SSH bastion hosts instead of direct SSH access"
echo "4. Remove unused security groups to reduce attack surface"
echo "5. Regularly audit and review security group rules"
echo ""

echo "🚨 Critical Issues Summary:"
echo "---------------------------"

# Count critical issues
INTERNET_SSH=$(aws ec2 describe-security-groups \
    --query 'SecurityGroups[*].IpPermissions[?FromPort==`22` && ToPort==`22` && contains(IpRanges[].CidrIp, `0.0.0.0/0`)]' \
    --output text | wc -l)

INTERNET_RDP=$(aws ec2 describe-security-groups \
    --query 'SecurityGroups[*].IpPermissions[?FromPort==`3389` && ToPort==`3389` && contains(IpRanges[].CidrIp, `0.0.0.0/0`)]' \
    --output text | wc -l)

OPEN_ALL_PORTS=$(aws ec2 describe-security-groups \
    --query 'SecurityGroups[*].IpPermissions[?FromPort==`0` && ToPort==`65535` && contains(IpRanges[].CidrIp, `0.0.0.0/0`)]' \
    --output text | wc -l)

echo "SSH open to internet: $INTERNET_SSH groups"
echo "RDP open to internet: $INTERNET_RDP groups"
echo "All ports open to internet: $OPEN_ALL_PORTS groups"

if [ $INTERNET_SSH -gt 0 ] || [ $INTERNET_RDP -gt 0 ] || [ $OPEN_ALL_PORTS -gt 0 ]; then
    echo ""
    echo "🚨 IMMEDIATE ACTION REQUIRED: Critical security vulnerabilities found!"
fi

echo ""
echo "✅ Security group audit completed"
```

### Network Access Control Lists (NACLs)

**NACL Hardening Configuration:**
```bash
#!/bin/bash
# Configure Network ACLs for enhanced security

VPC_ID=$1
ENVIRONMENT=$2

if [ -z "$VPC_ID" ] || [ -z "$ENVIRONMENT" ]; then
    echo "❌ Usage: $0 <vpc_id> <environment>"
    exit 1
fi

echo "🛡️  Configuring Network ACLs for Enhanced Security"
echo "================================================="
echo "VPC: $VPC_ID"
echo "Environment: $ENVIRONMENT"
echo ""

# Create custom NACL for public subnets
PUBLIC_NACL_ID=$(aws ec2 create-network-acl \
    --vpc-id $VPC_ID \
    --query 'NetworkAcl.NetworkAclId' \
    --output text)

aws ec2 create-tags \
    --resources $PUBLIC_NACL_ID \
    --tags Key=Name,Value="$ENVIRONMENT-public-nacl" Key=Environment,Value="$ENVIRONMENT"

echo "✅ Created public NACL: $PUBLIC_NACL_ID"

# Public subnet NACL rules
echo "🔧 Configuring public subnet NACL rules..."

# Inbound rules for public subnets
aws ec2 create-network-acl-entry \
    --network-acl-id $PUBLIC_NACL_ID \
    --rule-number 100 \
    --protocol tcp \
    --rule-action allow \
    --port-range From=80,To=80 \
    --cidr-block 0.0.0.0/0

aws ec2 create-network-acl-entry \
    --network-acl-id $PUBLIC_NACL_ID \
    --rule-number 110 \
    --protocol tcp \
    --rule-action allow \
    --port-range From=443,To=443 \
    --cidr-block 0.0.0.0/0

# SSH access only from corporate IP ranges
aws ec2 create-network-acl-entry \
    --network-acl-id $PUBLIC_NACL_ID \
    --rule-number 120 \
    --protocol tcp \
    --rule-action allow \
    --port-range From=22,To=22 \
    --cidr-block 203.0.113.0/24  # Replace with actual corporate IP range

# Ephemeral ports for return traffic
aws ec2 create-network-acl-entry \
    --network-acl-id $PUBLIC_NACL_ID \
    --rule-number 130 \
    --protocol tcp \
    --rule-action allow \
    --port-range From=1024,To=65535 \
    --cidr-block 0.0.0.0/0

# Outbound rules for public subnets
aws ec2 create-network-acl-entry \
    --network-acl-id $PUBLIC_NACL_ID \
    --rule-number 100 \
    --protocol tcp \
    --rule-action allow \
    --port-range From=80,To=80 \
    --cidr-block 0.0.0.0/0 \
    --egress

aws ec2 create-network-acl-entry \
    --network-acl-id $PUBLIC_NACL_ID \
    --rule-number 110 \
    --protocol tcp \
    --rule-action allow \
    --port-range From=443,To=443 \
    --cidr-block 0.0.0.0/0 \
    --egress

# Create custom NACL for private subnets
PRIVATE_NACL_ID=$(aws ec2 create-network-acl \
    --vpc-id $VPC_ID \
    --query 'NetworkAcl.NetworkAclId' \
    --output text)

aws ec2 create-tags \
    --resources $PRIVATE_NACL_ID \
    --tags Key=Name,Value="$ENVIRONMENT-private-nacl" Key=Environment,Value="$ENVIRONMENT"

echo "✅ Created private NACL: $PRIVATE_NACL_ID"

# Private subnet NACL rules (more restrictive)
echo "🔧 Configuring private subnet NACL rules..."

# Get VPC CIDR for internal communication
VPC_CIDR=$(aws ec2 describe-vpcs \
    --vpc-ids $VPC_ID \
    --query 'Vpcs[0].CidrBlock' \
    --output text)

# Inbound rules for private subnets (only from VPC)
aws ec2 create-network-acl-entry \
    --network-acl-id $PRIVATE_NACL_ID \
    --rule-number 100 \
    --protocol tcp \
    --rule-action allow \
    --port-range From=80,To=80 \
    --cidr-block $VPC_CIDR

aws ec2 create-network-acl-entry \
    --network-acl-id $PRIVATE_NACL_ID \
    --rule-number 110 \
    --protocol tcp \
    --rule-action allow \
    --port-range From=443,To=443 \
    --cidr-block $VPC_CIDR

# Database access (adjust ports as needed)
aws ec2 create-network-acl-entry \
    --network-acl-id $PRIVATE_NACL_ID \
    --rule-number 120 \
    --protocol tcp \
    --rule-action allow \
    --port-range From=3306,To=3306 \
    --cidr-block $VPC_CIDR

aws ec2 create-network-acl-entry \
    --network-acl-id $PRIVATE_NACL_ID \
    --rule-number 130 \
    --protocol tcp \
    --rule-action allow \
    --port-range From=5432,To=5432 \
    --cidr-block $VPC_CIDR

# Ephemeral ports for return traffic
aws ec2 create-network-acl-entry \
    --network-acl-id $PRIVATE_NACL_ID \
    --rule-number 140 \
    --protocol tcp \
    --rule-action allow \
    --port-range From=1024,To=65535 \
    --cidr-block 0.0.0.0/0

# Outbound rules for private subnets
aws ec2 create-network-acl-entry \
    --network-acl-id $PRIVATE_NACL_ID \
    --rule-number 100 \
    --protocol tcp \
    --rule-action allow \
    --port-range From=80,To=80 \
    --cidr-block 0.0.0.0/0 \
    --egress

aws ec2 create-network-acl-entry \
    --network-acl-id $PRIVATE_NACL_ID \
    --rule-number 110 \
    --protocol tcp \
    --rule-action allow \
    --port-range From=443,To=443 \
    --cidr-block 0.0.0.0/0 \
    --egress

echo ""
echo "📋 NACL Configuration Summary:"
echo "------------------------------"
echo "Public NACL ID: $PUBLIC_NACL_ID"
echo "Private NACL ID: $PRIVATE_NACL_ID"
echo ""
echo "Next steps:"
echo "1. Associate public NACL with public subnets"
echo "2. Associate private NACL with private subnets"
echo "3. Test connectivity after NACL association"
echo ""
echo "✅ NACL configuration completed"
```

## Data Protection

### Encryption at Rest Implementation

**S3 Bucket Encryption Audit:**
```bash
#!/bin/bash
# Audit and enforce S3 bucket encryption

ENVIRONMENT=${1:-all}

echo "🔐 S3 Bucket Encryption Audit"
echo "============================="
echo "Environment: $ENVIRONMENT"
echo ""

# Get list of buckets
if [ "$ENVIRONMENT" = "all" ]; then
    BUCKETS=$(aws s3api list-buckets --query 'Buckets[].Name' --output text)
else
    BUCKETS=$(aws s3api list-buckets \
        --query "Buckets[?contains(Name, '$ENVIRONMENT')].Name" \
        --output text)
fi

echo "🪣 Bucket Encryption Status:"
echo "----------------------------"

for bucket in $BUCKETS; do
    echo "Bucket: $bucket"
    
    # Check encryption configuration
    ENCRYPTION=$(aws s3api get-bucket-encryption \
        --bucket $bucket \
        --query 'ServerSideEncryptionConfiguration.Rules[0].ApplyServerSideEncryptionByDefault' \
        --output json 2>/dev/null)
    
    if [ -n "$ENCRYPTION" ] && [ "$ENCRYPTION" != "null" ]; then
        SSE_ALGORITHM=$(echo $ENCRYPTION | jq -r '.SSEAlgorithm')
        KMS_KEY=$(echo $ENCRYPTION | jq -r '.KMSMasterKeyID // "Default"')
        echo "  ✅ Encryption: $SSE_ALGORITHM"
        echo "  🔑 KMS Key: $KMS_KEY"
    else
        echo "  ❌ Encryption: NOT CONFIGURED"
        
        # Auto-remediate: Enable default encryption
        echo "  🔧 Enabling default encryption..."
        
        aws s3api put-bucket-encryption \
            --bucket $bucket \
            --server-side-encryption-configuration '{
                "Rules": [
                    {
                        "ApplyServerSideEncryptionByDefault": {
                            "SSEAlgorithm": "aws:kms"
                        },
                        "BucketKeyEnabled": true
                    }
                ]
            }'
        
        echo "  ✅ Default KMS encryption enabled"
    fi
    
    # Check public access block
    PUBLIC_BLOCK=$(aws s3api get-public-access-block \
        --bucket $bucket \
        --query 'PublicAccessBlockConfiguration' \
        --output json 2>/dev/null)
    
    if [ -n "$PUBLIC_BLOCK" ] && [ "$PUBLIC_BLOCK" != "null" ]; then
        BLOCK_ALL=$(echo $PUBLIC_BLOCK | jq -r '.BlockPublicAcls and .BlockPublicPolicy and .IgnorePublicAcls and .RestrictPublicBuckets')
        if [ "$BLOCK_ALL" = "true" ]; then
            echo "  🔒 Public Access: BLOCKED"
        else
            echo "  ⚠️  Public Access: PARTIALLY BLOCKED"
        fi
    else
        echo "  🚨 Public Access: NOT BLOCKED"
        
        # Auto-remediate: Block public access
        echo "  🔧 Blocking public access..."
        
        aws s3api put-public-access-block \
            --bucket $bucket \
            --public-access-block-configuration \
                BlockPublicAcls=true,\
                IgnorePublicAcls=true,\
                BlockPublicPolicy=true,\
                RestrictPublicBuckets=true
        
        echo "  ✅ Public access blocked"
    fi
    
    # Check versioning
    VERSIONING=$(aws s3api get-bucket-versioning \
        --bucket $bucket \
        --query 'Status' \
        --output text)
    
    echo "  📚 Versioning: ${VERSIONING:-Disabled}"
    
    # Check MFA Delete
    MFA_DELETE=$(aws s3api get-bucket-versioning \
        --bucket $bucket \
        --query 'MfaDelete' \
        --output text)
    
    if [ "$MFA_DELETE" = "Enabled" ]; then
        echo "  🔐 MFA Delete: ENABLED"
    else
        echo "  ⚠️  MFA Delete: DISABLED"
    fi
    
    echo "  ---"
done

echo ""
echo "🗄️  EBS Volume Encryption Status:"
echo "---------------------------------"

# Check EBS volume encryption
VOLUMES=$(aws ec2 describe-volumes \
    --query 'Volumes[*].[VolumeId,Encrypted,KmsKeyId,State]' \
    --output text)

echo "$VOLUMES" | while read -r volume_id encrypted kms_key state; do
    if [ "$state" = "available" ] || [ "$state" = "in-use" ]; then
        echo "Volume: $volume_id"
        if [ "$encrypted" = "True" ]; then
            echo "  ✅ Encrypted: Yes"
            echo "  🔑 KMS Key: ${kms_key:-Default}"
        else
            echo "  ❌ Encrypted: No"
            echo "  ⚠️  SECURITY RISK: Unencrypted EBS volume"
        fi
        echo "  ---"
    fi
done

echo ""
echo "🗃️  RDS Encryption Status:"
echo "-------------------------"

# Check RDS encryption
INSTANCES=$(aws rds describe-db-instances \
    --query 'DBInstances[*].[DBInstanceIdentifier,StorageEncrypted,KmsKeyId]' \
    --output text)

echo "$INSTANCES" | while read -r db_id encrypted kms_key; do
    echo "Database: $db_id"
    if [ "$encrypted" = "True" ]; then
        echo "  ✅ Storage Encrypted: Yes"
        echo "  🔑 KMS Key: ${kms_key:-Default}"
    else
        echo "  ❌ Storage Encrypted: No"
        echo "  ⚠️  SECURITY RISK: Unencrypted RDS instance"
    fi
    echo "  ---"
done

echo ""
echo "✅ Encryption audit completed"
```

### Key Management Service (KMS) Setup

**KMS Key Management Script:**
```bash
#!/bin/bash
# Manage KMS keys for data encryption

ENVIRONMENT=$1
ACTION=${2:-create}
KEY_ALIAS=$3

if [ -z "$ENVIRONMENT" ]; then
    echo "❌ Usage: $0 <environment> [action] [key_alias]"
    echo "   Actions: create, rotate, audit, disable"
    exit 1
fi

echo "🔐 KMS Key Management"
echo "===================="
echo "Environment: $ENVIRONMENT"
echo "Action: $ACTION"
echo ""

case $ACTION in
    "create")
        KEY_ALIAS=${KEY_ALIAS:-"$ENVIRONMENT-master-key"}
        
        echo "🔧 Creating KMS key for environment: $ENVIRONMENT"
        
        # Create key policy
        ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
        
        cat > /tmp/key-policy.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "Enable IAM User Permissions",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::$ACCOUNT_ID:root"
            },
            "Action": "kms:*",
            "Resource": "*"
        },
        {
            "Sid": "Allow use of the key for $ENVIRONMENT environment",
            "Effect": "Allow",
            "Principal": {
                "AWS": "*"
            },
            "Action": [
                "kms:Encrypt",
                "kms:Decrypt",
                "kms:ReEncrypt*",
                "kms:GenerateDataKey*",
                "kms:DescribeKey"
            ],
            "Resource": "*",
            "Condition": {
                "StringEquals": {
                    "kms:ViaService": [
                        "s3.us-east-1.amazonaws.com",
                        "rds.us-east-1.amazonaws.com",
                        "ec2.us-east-1.amazonaws.com"
                    ]
                }
            }
        },
        {
            "Sid": "Allow attachment of persistent resources",
            "Effect": "Allow",
            "Principal": {
                "AWS": "*"
            },
            "Action": [
                "kms:CreateGrant",
                "kms:ListGrants",
                "kms:RevokeGrant"
            ],
            "Resource": "*",
            "Condition": {
                "Bool": {
                    "kms:GrantIsForAWSResource": "true"
                }
            }
        }
    ]
}
EOF
        
        # Create the key
        KEY_ID=$(aws kms create-key \
            --description "Master key for $ENVIRONMENT environment" \
            --key-usage ENCRYPT_DECRYPT \
            --key-spec SYMMETRIC_DEFAULT \
            --policy file:///tmp/key-policy.json \
            --query 'KeyMetadata.KeyId' \
            --output text)
        
        # Create alias
        aws kms create-alias \
            --alias-name "alias/$KEY_ALIAS" \
            --target-key-id $KEY_ID
        
        # Tag the key
        aws kms tag-resource \
            --key-id $KEY_ID \
            --tags TagKey=Environment,TagValue=$ENVIRONMENT \
                   TagKey=Purpose,TagValue="Data Encryption" \
                   TagKey=ManagedBy,TagValue="Security Team"
        
        echo "✅ KMS key created successfully"
        echo "   Key ID: $KEY_ID"
        echo "   Alias: alias/$KEY_ALIAS"
        
        rm -f /tmp/key-policy.json
        ;;
        
    "rotate")
        KEY_ALIAS=${KEY_ALIAS:-"$ENVIRONMENT-master-key"}
        
        echo "🔄 Enabling key rotation for: $KEY_ALIAS"
        
        # Get key ID from alias
        KEY_ID=$(aws kms describe-key \
            --key-id "alias/$KEY_ALIAS" \
            --query 'KeyMetadata.KeyId' \
            --output text 2>/dev/null)
        
        if [ -n "$KEY_ID" ] && [ "$KEY_ID" != "None" ]; then
            # Enable automatic rotation
            aws kms enable-key-rotation --key-id $KEY_ID
            
            # Check rotation status
            ROTATION_STATUS=$(aws kms get-key-rotation-status \
                --key-id $KEY_ID \
                --query 'KeyRotationEnabled' \
                --output text)
            
            echo "✅ Key rotation status: $ROTATION_STATUS"
        else
            echo "❌ Key not found: alias/$KEY_ALIAS"
        fi
        ;;
        
    "audit")
        echo "🔍 KMS Key Audit for environment: $ENVIRONMENT"
        echo "----------------------------------------------"
        
        # List all keys
        KEYS=$(aws kms list-keys --query 'Keys[].KeyId' --output text)
        
        for key_id in $KEYS; do
            # Get key details
            KEY_INFO=$(aws kms describe-key \
                --key-id $key_id \
                --query 'KeyMetadata.[KeyId,Description,KeyState,KeyUsage]' \
                --output text 2>/dev/null)
            
            if [ -n "$KEY_INFO" ]; then
                echo "Key ID: $(echo $KEY_INFO | cut -d' ' -f1)"
                echo "Description: $(echo $KEY_INFO | cut -d' ' -f2-)"
                echo "State: $(echo $KEY_INFO | cut -d' ' -f3)"
                echo "Usage: $(echo $KEY_INFO | cut -d' ' -f4)"
                
                # Check rotation status
                ROTATION=$(aws kms get-key-rotation-status \
                    --key-id $key_id \
                    --query 'KeyRotationEnabled' \
                    --output text 2>/dev/null || echo "N/A")
                
                echo "Rotation: $ROTATION"
                
                # List aliases
                ALIASES=$(aws kms list-aliases \
                    --key-id $key_id \
                    --query 'Aliases[].AliasName' \
                    --output text 2>/dev/null)
                
                if [ -n "$ALIASES" ]; then
                    echo "Aliases: $ALIASES"
                fi
                
                echo "---"
            fi
        done
        ;;
        
    "disable")
        KEY_ALIAS=${KEY_ALIAS:-"$ENVIRONMENT-master-key"}
        
        echo "⚠️  Disabling KMS key: $KEY_ALIAS"
        echo "This action should only be performed after careful consideration!"
        echo "Type 'DISABLE' to confirm:"
        read -r CONFIRM
        
        if [ "$CONFIRM" = "DISABLE" ]; then
            KEY_ID=$(aws kms describe-key \
                --key-id "alias/$KEY_ALIAS" \
                --query 'KeyMetadata.KeyId' \
                --output text 2>/dev/null)
            
            if [ -n "$KEY_ID" ] && [ "$KEY_ID" != "None" ]; then
                aws kms disable-key --key-id $KEY_ID
                echo "✅ Key disabled: $KEY_ID"
            else
                echo "❌ Key not found: alias/$KEY_ALIAS"
            fi
        else
            echo "❌ Action cancelled"
        fi
        ;;
        
    *)
        echo "❌ Unknown action: $ACTION"
        echo "Available actions: create, rotate, audit, disable"
        exit 1
        ;;
esac

echo ""
echo "✅ KMS key management completed"
```

## Security Monitoring

### CloudTrail Configuration

**Enhanced CloudTrail Setup:**
```bash
#!/bin/bash
# Setup comprehensive CloudTrail logging

ENVIRONMENT=$1
S3_BUCKET_NAME=$2

if [ -z "$ENVIRONMENT" ] || [ -z "$S3_BUCKET_NAME" ]; then
    echo "❌ Usage: $0 <environment> <s3_bucket_name>"
    exit 1
fi

echo "📊 Setting up CloudTrail for: $ENVIRONMENT"
echo "========================================"

TRAIL_NAME="$ENVIRONMENT-cloudtrail"
KMS_KEY_ALIAS="alias/$ENVIRONMENT-cloudtrail-key"

# Create S3 bucket for CloudTrail logs if it doesn't exist
if ! aws s3api head-bucket --bucket $S3_BUCKET_NAME 2>/dev/null; then
    echo "🪣 Creating S3 bucket for CloudTrail logs..."
    
    aws s3api create-bucket \
        --bucket $S3_BUCKET_NAME \
        --create-bucket-configuration LocationConstraint=us-west-2
    
    # Enable versioning
    aws s3api put-bucket-versioning \
        --bucket $S3_BUCKET_NAME \
        --versioning-configuration Status=Enabled
    
    # Block public access
    aws s3api put-public-access-block \
        --bucket $S3_BUCKET_NAME \
        --public-access-block-configuration \
            BlockPublicAcls=true,\
            IgnorePublicAcls=true,\
            BlockPublicPolicy=true,\
            RestrictPublicBuckets=true
    
    echo "✅ S3 bucket created: $S3_BUCKET_NAME"
fi

# Create bucket policy for CloudTrail
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

cat > /tmp/cloudtrail-bucket-policy.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AWSCloudTrailAclCheck",
            "Effect": "Allow",
            "Principal": {
                "Service": "cloudtrail.amazonaws.com"
            },
            "Action": "s3:GetBucketAcl",
            "Resource": "arn:aws:s3:::$S3_BUCKET_NAME"
        },
        {
            "Sid": "AWSCloudTrailWrite",
            "Effect": "Allow",
            "Principal": {
                "Service": "cloudtrail.amazonaws.com"
            },
            "Action": "s3:PutObject",
            "Resource": "arn:aws:s3:::$S3_BUCKET_NAME/*",
            "Condition": {
                "StringEquals": {
                    "s3:x-amz-acl": "bucket-owner-full-control"
                }
            }
        }
    ]
}
EOF

aws s3api put-bucket-policy \
    --bucket $S3_BUCKET_NAME \
    --policy file:///tmp/cloudtrail-bucket-policy.json

# Create KMS key for CloudTrail encryption
echo "🔐 Creating KMS key for CloudTrail encryption..."

cat > /tmp/cloudtrail-key-policy.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "Enable IAM User Permissions",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::$ACCOUNT_ID:root"
            },
            "Action": "kms:*",
            "Resource": "*"
        },
        {
            "Sid": "Allow CloudTrail to encrypt logs",
            "Effect": "Allow",
            "Principal": {
                "Service": "cloudtrail.amazonaws.com"
            },
            "Action": [
                "kms:GenerateDataKey*",
                "kms:DescribeKey"
            ],
            "Resource": "*"
        },
        {
            "Sid": "Allow CloudTrail to describe key",
            "Effect": "Allow",
            "Principal": {
                "Service": "cloudtrail.amazonaws.com"
            },
            "Action": [
                "kms:DescribeKey"
            ],
            "Resource": "*"
        }
    ]
}
EOF

KMS_KEY_ID=$(aws kms create-key \
    --description "CloudTrail encryption key for $ENVIRONMENT" \
    --policy file:///tmp/cloudtrail-key-policy.json \
    --query 'KeyMetadata.KeyId' \
    --output text)

aws kms create-alias \
    --alias-name $KMS_KEY_ALIAS \
    --target-key-id $KMS_KEY_ID

echo "✅ KMS key created: $KMS_KEY_ALIAS"

# Create CloudTrail
echo "📝 Creating CloudTrail..."

aws cloudtrail create-trail \
    --name $TRAIL_NAME \
    --s3-bucket-name $S3_BUCKET_NAME \
    --s3-key-prefix "cloudtrail-logs/$ENVIRONMENT" \
    --include-global-service-events \
    --is-multi-region-trail \
    --enable-log-file-validation \
    --kms-key-id $KMS_KEY_ALIAS \
    --event-selectors '[
        {
            "ReadWriteType": "All",
            "IncludeManagementEvents": true,
            "DataResources": [
                {
                    "Type": "AWS::S3::Object",
                    "Values": ["arn:aws:s3:::*/*"]
                },
                {
                    "Type": "AWS::Lambda::Function",
                    "Values": ["arn:aws:lambda:*"]
                }
            ]
        }
    ]'

# Start logging
aws cloudtrail start-logging --name $TRAIL_NAME

# Add tags
aws cloudtrail add-tags \
    --resource-id "arn:aws:cloudtrail:$(aws configure get region):$ACCOUNT_ID:trail/$TRAIL_NAME" \
    --tags-list Key=Environment,Value=$ENVIRONMENT Key=Purpose,Value="Security Logging"

echo "✅ CloudTrail created and started: $TRAIL_NAME"

# Setup CloudWatch integration for real-time monitoring
echo "⏰ Setting up CloudWatch integration..."

LOG_GROUP_NAME="/aws/cloudtrail/$ENVIRONMENT"

# Create log group
aws logs create-log-group \
    --log-group-name $LOG_GROUP_NAME

aws logs put-retention-policy \
    --log-group-name $LOG_GROUP_NAME \
    --retention-in-days 90

# Create IAM role for CloudTrail to CloudWatch
cat > /tmp/cloudtrail-cloudwatch-role.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "cloudtrail.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
EOF

cat > /tmp/cloudtrail-cloudwatch-policy.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:PutLogEvents",
                "logs:CreateLogStream"
            ],
            "Resource": "arn:aws:logs:*:*:log-group:$LOG_GROUP_NAME*"
        }
    ]
}
EOF

ROLE_NAME="$ENVIRONMENT-CloudTrail-CloudWatchLogs-Role"

aws iam create-role \
    --role-name $ROLE_NAME \
    --assume-role-policy-document file:///tmp/cloudtrail-cloudwatch-role.json

aws iam put-role-policy \
    --role-name $ROLE_NAME \
    --policy-name "CloudTrail-CloudWatchLogs-Policy" \
    --policy-document file:///tmp/cloudtrail-cloudwatch-policy.json

# Wait for role to be available
sleep 10

# Update CloudTrail with CloudWatch integration
aws cloudtrail update-trail \
    --name $TRAIL_NAME \
    --cloud-watch-logs-log-group-arn "arn:aws:logs:$(aws configure get region):$ACCOUNT_ID:log-group:$LOG_GROUP_NAME:*" \
    --cloud-watch-logs-role-arn "arn:aws:iam::$ACCOUNT_ID:role/$ROLE_NAME"

echo "✅ CloudWatch integration configured"

# Clean up temporary files
rm -f /tmp/cloudtrail-*.json

echo ""
echo "📋 CloudTrail Setup Summary:"
echo "----------------------------"
echo "Trail Name: $TRAIL_NAME"
echo "S3 Bucket: $S3_BUCKET_NAME"
echo "KMS Key: $KMS_KEY_ALIAS"
echo "CloudWatch Log Group: $LOG_GROUP_NAME"
echo ""
echo "✅ CloudTrail setup completed successfully"
```

### GuardDuty Integration

**GuardDuty Setup and Management:**
```bash
#!/bin/bash
# Setup and manage GuardDuty for threat detection

ACTION=${1:-enable}
ENVIRONMENT=${2:-prod}

echo "🛡️  GuardDuty Threat Detection Management"
echo "========================================"
echo "Action: $ACTION"
echo "Environment: $ENVIRONMENT"
echo ""

case $ACTION in
    "enable")
        echo "🔧 Enabling GuardDuty..."
        
        # Enable GuardDuty
        DETECTOR_ID=$(aws guardduty create-detector \
            --enable \
            --finding-publishing-frequency FIFTEEN_MINUTES \
            --query 'DetectorId' \
            --output text)
        
        echo "✅ GuardDuty enabled with Detector ID: $DETECTOR_ID"
        
        # Configure threat intelligence feeds
        echo "📡 Configuring threat intelligence feeds..."
        
        # Enable malware protection
        aws guardduty update-malware-protection-plan \
            --detector-id $DETECTOR_ID \
            --role "arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):role/aws-guardduty-malware-protection-service-role" \
            --actions '{
                "Tagging": {
                    "Status": "ENABLED"
                }
            }'
        
        echo "✅ Malware protection configured"
        
        # Setup SNS topic for findings
        TOPIC_ARN=$(aws sns create-topic \
            --name "$ENVIRONMENT-guardduty-findings" \
            --query 'TopicArn' \
            --output text)
        
        echo "📧 SNS topic created: $TOPIC_ARN"
        
        # Create EventBridge rule for GuardDuty findings
        aws events put-rule \
            --name "$ENVIRONMENT-guardduty-findings" \
            --description "Route GuardDuty findings to SNS" \
            --event-pattern '{
                "source": ["aws.guardduty"],
                "detail-type": ["GuardDuty Finding"]
            }' \
            --state ENABLED
        
        # Add SNS target to EventBridge rule
        aws events put-targets \
            --rule "$ENVIRONMENT-guardduty-findings" \
            --targets "Id=1,Arn=$TOPIC_ARN"
        
        echo "✅ EventBridge rule configured for findings"
        ;;
        
    "status")
        echo "📊 GuardDuty Status Report:"
        echo "---------------------------"
        
        # Get detector information
        DETECTORS=$(aws guardduty list-detectors --query 'DetectorIds' --output text)
        
        if [ -n "$DETECTORS" ]; then
            for detector in $DETECTORS; do
                echo "Detector ID: $detector"
                
                # Get detector details
                DETECTOR_INFO=$(aws guardduty get-detector \
                    --detector-id $detector \
                    --query '[Status,FindingPublishingFrequency]' \
                    --output text)
                
                STATUS=$(echo $DETECTOR_INFO | cut -d' ' -f1)
                FREQUENCY=$(echo $DETECTOR_INFO | cut -d' ' -f2)
                
                echo "Status: $STATUS"
                echo "Publishing Frequency: $FREQUENCY"
                
                # Get recent findings count
                FINDINGS_COUNT=$(aws guardduty list-findings \
                    --detector-id $detector \
                    --finding-criteria '{
                        "Criterion": {
                            "updatedAt": {
                                "GreaterThan": '$(date -d "24 hours ago" +%s)'000'
                            }
                        }
                    }' \
                    --query 'length(FindingIds)' \
                    --output text)
                
                echo "Recent Findings (24h): $FINDINGS_COUNT"
                
                # Get finding statistics by severity
                HIGH_FINDINGS=$(aws guardduty list-findings \
                    --detector-id $detector \
                    --finding-criteria '{
                        "Criterion": {
                            "severity": {
                                "GreaterThanOrEqual": 7.0
                            }
                        }
                    }' \
                    --query 'length(FindingIds)' \
                    --output text)
                
                MEDIUM_FINDINGS=$(aws guardduty list-findings \
                    --detector-id $detector \
                    --finding-criteria '{
                        "Criterion": {
                            "severity": {
                                "GreaterThanOrEqual": 4.0,
                                "LessThan": 7.0
                            }
                        }
                    }' \
                    --query 'length(FindingIds)' \
                    --output text)
                
                echo "High Severity Findings: $HIGH_FINDINGS"
                echo "Medium Severity Findings: $MEDIUM_FINDINGS"
                echo "---"
            done
        else
            echo "❌ GuardDuty is not enabled"
        fi
        ;;
        
    "findings")
        echo "🔍 Recent GuardDuty Findings:"
        echo "----------------------------"
        
        DETECTORS=$(aws guardduty list-detectors --query 'DetectorIds' --output text)
        
        for detector in $DETECTORS; do
            # Get recent high and medium severity findings
            FINDINGS=$(aws guardduty list-findings \
                --detector-id $detector \
                --finding-criteria '{
                    "Criterion": {
                        "severity": {
                            "GreaterThanOrEqual": 4.0
                        },
                        "updatedAt": {
                            "GreaterThan": '$(date -d "7 days ago" +%s)'000'
                        }
                    }
                }' \
                --max-results 10 \
                --query 'FindingIds' \
                --output text)
            
            if [ -n "$FINDINGS" ]; then
                # Get finding details
                aws guardduty get-findings \
                    --detector-id $detector \
                    --finding-ids $FINDINGS \
                    --query 'Findings[*].{
                        ID:Id,
                        Type:Type,
                        Severity:Severity,
                        Title:Title,
                        UpdatedAt:UpdatedAt,
                        Resource:Resource.InstanceDetails.InstanceId
                    }' \
                    --output table
            else
                echo "No recent high/medium severity findings"
            fi
        done
        ;;
        
    "remediate")
        echo "🔧 Automated Remediation for GuardDuty Findings"
        echo "----------------------------------------------"
        
        DETECTORS=$(aws guardduty list-detectors --query 'DetectorIds' --output text)
        
        for detector in $DETECTORS; do
            # Get findings that can be auto-remediated
            FINDINGS=$(aws guardduty list-findings \
                --detector-id $detector \
                --finding-criteria '{
                    "Criterion": {
                        "type": {
                            "Eq": [
                                "Recon:EC2/PortProbeUnprotectedPort",
                                "UnauthorizedAPI:EC2/MaliciousIPCaller.Custom"
                            ]
                        }
                    }
                }' \
                --query 'FindingIds' \
                --output text)
            
            for finding_id in $FINDINGS; do
                echo "Processing finding: $finding_id"
                
                # Get finding details
                FINDING_DETAILS=$(aws guardduty get-findings \
                    --detector-id $detector \
                    --finding-ids $finding_id \
                    --query 'Findings[0].{
                        Type:Type,
                        InstanceId:Resource.InstanceDetails.InstanceId,
                        RemoteIpDetails:Service.RemoteIpDetails.IpAddressV4
                    }' \
                    --output json)
                
                FINDING_TYPE=$(echo $FINDING_DETAILS | jq -r '.Type')
                INSTANCE_ID=$(echo $FINDING_DETAILS | jq -r '.InstanceId')
                MALICIOUS_IP=$(echo $FINDING_DETAILS | jq -r '.RemoteIpDetails')
                
                case $FINDING_TYPE in
                    "Recon:EC2/PortProbeUnprotectedPort")
                        echo "  Remediating port probe finding..."
                        # Add restrictive security group rule
                        # This is a placeholder - implement based on your security policies
                        echo "  ⚠️  Manual review required for instance: $INSTANCE_ID"
                        ;;
                        
                    "UnauthorizedAPI:EC2/MaliciousIPCaller.Custom")
                        echo "  Blocking malicious IP: $MALICIOUS_IP"
                        # Add IP to WAF IP set or security group block rule
                        # This is a placeholder - implement based on your infrastructure
                        echo "  ⚠️  Manual review required for IP: $MALICIOUS_IP"
                        ;;
                esac
                
                # Archive the finding after remediation
                aws guardduty archive-findings \
                    --detector-id $detector \
                    --finding-ids $finding_id
                
                echo "  ✅ Finding archived: $finding_id"
            done
        done
        ;;
        
    "disable")
        echo "⚠️  Disabling GuardDuty"
        echo "This will stop threat detection. Type 'DISABLE' to confirm:"
        read -r CONFIRM
        
        if [ "$CONFIRM" = "DISABLE" ]; then
            DETECTORS=$(aws guardduty list-detectors --query 'DetectorIds' --output text)
            
            for detector in $DETECTORS; do
                aws guardduty delete-detector --detector-id $detector
                echo "✅ Detector disabled: $detector"
            done
        else
            echo "❌ Action cancelled"
        fi
        ;;
        
    *)
        echo "❌ Unknown action: $ACTION"
        echo "Available actions: enable, status, findings, remediate, disable"
        exit 1
        ;;
esac

echo ""
echo "✅ GuardDuty management completed"
```

---

**Related Documentation**:
- [Operations Guide](OPERATIONS.md) - Day-to-day operational procedures  
- [CI/CD Guide](CICD.md) - Secure deployment pipelines
- [Deployment Guide](DEPLOYMENT.md) - Secure deployment procedures
- [Architecture Guide](architecture/overview.md) - Security architecture overview