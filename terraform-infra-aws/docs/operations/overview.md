# Operations Guide

This comprehensive operations guide covers the day-to-day management, monitoring, maintenance, and troubleshooting of your AWS infrastructure deployed using Terraform.

## Table of Contents

- [Infrastructure Monitoring](#infrastructure-monitoring)
- [Backup and Recovery](#backup-and-recovery)
- [Performance Management](#performance-management)
- [Cost Optimization](#cost-optimization)
- [Security Operations](#security-operations)
- [Incident Response](#incident-response)
- [Maintenance Procedures](#maintenance-procedures)
- [Automation and Runbooks](#automation-and-runbooks)

## Infrastructure Monitoring

### CloudWatch Integration

#### Core Metrics Dashboard

Monitor essential infrastructure metrics across all environments:

```json
{
  "widgets": [
    {
      "type": "metric",
      "properties": {
        "metrics": [
          ["AWS/EC2", "CPUUtilization"],
          ["AWS/RDS", "CPUUtilization"],
          ["AWS/ApplicationELB", "RequestCount"],
          ["AWS/Lambda", "Duration"],
          ["AWS/EKS", "cluster_node_count"]
        ],
        "period": 300,
        "stat": "Average",
        "region": "us-east-1",
        "title": "Infrastructure Overview"
      }
    }
  ]
}
```

#### Application Monitoring

**EKS Cluster Monitoring**:
```bash
# Check cluster health
kubectl get nodes
kubectl get pods --all-namespaces

# View cluster metrics
kubectl top nodes
kubectl top pods

# Check cluster events
kubectl get events --sort-by=.metadata.creationTimestamp
```

**ECS Service Monitoring**:
```bash
# Check service status
aws ecs describe-services --cluster prod-cluster --services api-service

# View task definitions
aws ecs describe-task-definition --task-definition api-service:latest

# Monitor service events
aws ecs describe-services --cluster prod-cluster --services api-service \
  --query 'services[0].events[:10]'
```

**Lambda Function Monitoring**:
```bash
# Get function metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Duration \
  --dimensions Name=FunctionName,Value=api-handler \
  --start-time 2024-01-01T00:00:00Z \
  --end-time 2024-01-01T23:59:59Z \
  --period 3600 \
  --statistics Average
```

#### Database Monitoring

**RDS Performance Monitoring**:
```bash
# Check database metrics
aws rds describe-db-instances --db-instance-identifier prod-database

# Monitor performance insights
aws pi get-resource-metrics \
  --service-type RDS \
  --identifier prod-database-resource-id \
  --metric-queries file://db-metrics.json
```

**DynamoDB Monitoring**:
```bash
# Check table metrics
aws dynamodb describe-table --table-name user-sessions

# Monitor consumed capacity
aws cloudwatch get-metric-statistics \
  --namespace AWS/DynamoDB \
  --metric-name ConsumedReadCapacityUnits \
  --dimensions Name=TableName,Value=user-sessions
```

### Alerting Configuration

#### Critical Alerts

**High CPU Utilization**:
```json
{
  "AlarmName": "HighCPUUtilization",
  "ComparisonOperator": "GreaterThanThreshold",
  "EvaluationPeriods": 2,
  "MetricName": "CPUUtilization",
  "Namespace": "AWS/EC2",
  "Period": 300,
  "Statistic": "Average",
  "Threshold": 80.0,
  "ActionsEnabled": true,
  "AlarmActions": ["arn:aws:sns:us-east-1:123456789012:critical-alerts"]
}
```

**Database Connection Issues**:
```json
{
  "AlarmName": "DatabaseConnectionFailures",
  "ComparisonOperator": "GreaterThanThreshold",
  "EvaluationPeriods": 1,
  "MetricName": "DatabaseConnections",
  "Namespace": "AWS/RDS",
  "Period": 60,
  "Statistic": "Maximum",
  "Threshold": 80.0
}
```

#### Warning Alerts

**High Memory Usage**:
```json
{
  "AlarmName": "HighMemoryUsage",
  "ComparisonOperator": "GreaterThanThreshold",
  "EvaluationPeriods": 3,
  "MetricName": "MemoryUtilization",
  "Namespace": "CWAgent",
  "Period": 300,
  "Statistic": "Average",
  "Threshold": 70.0
}
```

### Log Management

#### Centralized Logging

**CloudWatch Logs Configuration**:
```bash
# Create log groups
aws logs create-log-group --log-group-name /aws/ecs/api-service
aws logs create-log-group --log-group-name /aws/lambda/data-processor

# Set retention policies
aws logs put-retention-policy \
  --log-group-name /aws/ecs/api-service \
  --retention-in-days 30
```

**Log Analysis Queries**:
```sql
-- Find error patterns
fields @timestamp, @message
| filter @message like /ERROR/
| stats count() by bin(5m)

-- Monitor API response times
fields @timestamp, @duration
| filter @type = "REPORT"
| stats avg(@duration), max(@duration), min(@duration) by bin(5m)

-- Database connection analysis
fields @timestamp, @message
| filter @message like /connection/
| stats count() by bin(1h)
```

## Backup and Recovery

### Database Backup Strategy

#### RDS Automated Backups

**Configuration**:
```hcl
resource "aws_db_instance" "main" {
  backup_retention_period = 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "Sun:04:00-Sun:05:00"
  
  final_snapshot_identifier = "${var.db_identifier}-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"
  skip_final_snapshot      = false
  
  copy_tags_to_snapshot = true
}
```

**Manual Snapshots**:
```bash
# Create manual snapshot
aws rds create-db-snapshot \
  --db-instance-identifier prod-database \
  --db-snapshot-identifier "prod-db-manual-$(date +%Y%m%d)"

# Restore from snapshot
aws rds restore-db-instance-from-db-snapshot \
  --db-instance-identifier restored-database \
  --db-snapshot-identifier prod-db-backup-20240101
```

#### DynamoDB Backup

**Point-in-Time Recovery**:
```bash
# Enable PITR
aws dynamodb update-continuous-backups \
  --table-name user-sessions \
  --point-in-time-recovery-specification PointInTimeRecoveryEnabled=true

# Restore to point in time
aws dynamodb restore-table-to-point-in-time \
  --source-table-name user-sessions \
  --target-table-name user-sessions-restored \
  --restore-date-time 2024-01-01T12:00:00Z
```

### File System Backups

#### EFS Backup

```bash
# Create backup vault
aws backup create-backup-vault --backup-vault-name efs-backup-vault

# Create backup plan
aws backup create-backup-plan --backup-plan file://efs-backup-plan.json
```

#### S3 Cross-Region Replication

```hcl
resource "aws_s3_bucket_replication_configuration" "main" {
  depends_on = [aws_s3_bucket_versioning.main]

  role   = aws_iam_role.replication.arn
  bucket = aws_s3_bucket.main.id

  rule {
    id     = "replicate_all"
    status = "Enabled"

    destination {
      bucket        = aws_s3_bucket.replica.arn
      storage_class = "STANDARD_IA"
    }
  }
}
```

### Recovery Procedures

#### Database Recovery

**RDS Recovery Steps**:
1. Identify the restore point
2. Create new instance from snapshot/PITR
3. Update application configuration
4. Verify data integrity
5. Switch application traffic

```bash
# Recovery script
#!/bin/bash
BACKUP_DATE="2024-01-01T12:00:00Z"
NEW_DB_ID="recovered-database-$(date +%s)"

# Restore database
aws rds restore-db-instance-to-point-in-time \
  --source-db-instance-identifier prod-database \
  --target-db-instance-identifier $NEW_DB_ID \
  --restore-time $BACKUP_DATE

# Wait for availability
aws rds wait db-instance-available --db-instance-identifier $NEW_DB_ID

echo "Database $NEW_DB_ID is ready"
```

#### Application Recovery

**EKS Application Recovery**:
```bash
# Restore from backup manifests
kubectl apply -f backup/manifests/

# Verify pods are running
kubectl get pods -n production

# Check service endpoints
kubectl get svc -n production
```

**ECS Service Recovery**:
```bash
# Update service to previous task definition
aws ecs update-service \
  --cluster prod-cluster \
  --service api-service \
  --task-definition api-service:stable
```

## Performance Management

### Performance Monitoring

#### Application Performance

**EKS Performance Tuning**:
```yaml
# Resource limits and requests
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: app
    resources:
      requests:
        memory: "256Mi"
        cpu: "250m"
      limits:
        memory: "512Mi"
        cpu: "500m"
```

**ECS Performance Optimization**:
```json
{
  "family": "api-service",
  "cpu": "512",
  "memory": "1024",
  "containerDefinitions": [{
    "name": "api",
    "cpu": 256,
    "memoryReservation": 512,
    "essential": true
  }]
}
```

#### Database Performance

**RDS Performance Optimization**:
```bash
# Enable Performance Insights
aws rds modify-db-instance \
  --db-instance-identifier prod-database \
  --enable-performance-insights \
  --performance-insights-retention-period 7

# Monitor slow queries
aws pi get-resource-metrics \
  --service-type RDS \
  --identifier $DB_RESOURCE_ID \
  --metric-queries '[{
    "Metric": "db.SQL.Select.Avg_timer_wait.avg",
    "GroupBy": {"Group": "db.sql_tokenized.statement"}
  }]'
```

**DynamoDB Performance Tuning**:
```bash
# Enable auto-scaling
aws application-autoscaling register-scalable-target \
  --service-namespace dynamodb \
  --resource-id "table/user-sessions" \
  --scalable-dimension "dynamodb:table:ReadCapacityUnits" \
  --min-capacity 5 \
  --max-capacity 40000

# Create scaling policy
aws application-autoscaling put-scaling-policy \
  --service-namespace dynamodb \
  --resource-id "table/user-sessions" \
  --scalable-dimension "dynamodb:table:ReadCapacityUnits" \
  --policy-name "user-sessions-read-scaling-policy" \
  --policy-type "TargetTrackingScaling" \
  --target-tracking-scaling-policy-configuration file://scaling-policy.json
```

### Capacity Planning

#### Resource Scaling

**Horizontal Pod Autoscaler (EKS)**:
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: api-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: api-deployment
  minReplicas: 3
  maxReplicas: 100
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
```

**ECS Service Auto Scaling**:
```bash
# Register scalable target
aws application-autoscaling register-scalable-target \
  --service-namespace ecs \
  --resource-id service/prod-cluster/api-service \
  --scalable-dimension ecs:service:DesiredCount \
  --min-capacity 2 \
  --max-capacity 20
```

## Cost Optimization

### Cost Monitoring

#### Cost Analysis

**Daily Cost Reporting**:
```bash
# Get daily costs by service
aws ce get-cost-and-usage \
  --time-period Start=2024-01-01,End=2024-01-31 \
  --granularity DAILY \
  --metrics BlendedCost \
  --group-by Type=DIMENSION,Key=SERVICE
```

**Resource Utilization Analysis**:
```bash
# Check EC2 utilization
aws ce get-rightsizing-recommendation \
  --service EC2-Instance

# Check RDS utilization
aws ce get-usage-forecast \
  --time-period Start=2024-01-01,End=2024-02-01 \
  --metric USAGE_QUANTITY \
  --granularity MONTHLY
```

### Optimization Strategies

#### Reserved Instances

**RI Recommendations**:
```bash
# Get RI recommendations
aws ce get-reservation-purchase-recommendation \
  --service EC2-Instance \
  --account-scope PAYER

# Purchase recommendations
aws ec2 purchase-reserved-instances-offering \
  --reserved-instances-offering-id $OFFERING_ID \
  --instance-count 2
```

#### Spot Instances

**EKS Spot Node Groups**:
```hcl
resource "aws_eks_node_group" "spot_nodes" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "spot-nodes"
  node_role_arn   = aws_iam_role.node_group.arn
  subnet_ids      = var.private_subnet_ids

  capacity_type  = "SPOT"
  instance_types = ["m5.large", "m5.xlarge", "m4.large", "m4.xlarge"]

  scaling_config {
    desired_size = 3
    max_size     = 10
    min_size     = 1
  }
}
```

#### Lifecycle Management

**S3 Intelligent Tiering**:
```hcl
resource "aws_s3_bucket_intelligent_tiering_configuration" "main" {
  bucket = aws_s3_bucket.main.id
  name   = "entire-bucket"

  status = "Enabled"

  tiering {
    access_tier = "DEEP_ARCHIVE_ACCESS"
    days        = 180
  }
}
```

**EBS Snapshot Lifecycle**:
```hcl
resource "aws_dlm_lifecycle_policy" "ebs_snapshots" {
  description        = "EBS snapshot lifecycle policy"
  execution_role_arn = aws_iam_role.dlm_lifecycle_role.arn
  state              = "ENABLED"

  policy_details {
    resource_types   = ["VOLUME"]
    target_tags = {
      Backup = "true"
    }

    schedule {
      name = "daily-snapshots"

      create_rule {
        interval      = 24
        interval_unit = "HOURS"
        times         = ["23:45"]
      }

      retain_rule {
        count = 7
      }

      copy_tags = true
    }
  }
}
```

## Security Operations

### Security Monitoring

#### AWS Config Rules

**Compliance Monitoring**:
```bash
# Check Config compliance
aws configservice get-compliance-summary-by-config-rule

# Get specific rule compliance
aws configservice get-compliance-details-by-config-rule \
  --config-rule-name encrypted-volumes
```

#### GuardDuty Integration

**Threat Detection**:
```bash
# Get GuardDuty findings
aws guardduty get-findings \
  --detector-id $DETECTOR_ID \
  --finding-ids $FINDING_ID

# Create custom threat intel
aws guardduty create-threat-intel-set \
  --detector-id $DETECTOR_ID \
  --name "custom-threat-intel" \
  --format TXT \
  --location s3://threat-intel-bucket/indicators.txt
```

### Access Management

#### IAM Policy Validation

**Policy Simulation**:
```bash
# Simulate IAM policy
aws iam simulate-principal-policy \
  --policy-source-arn arn:aws:iam::123456789012:role/app-role \
  --action-names s3:GetObject \
  --resource-arns arn:aws:s3:::app-data/*
```

#### Access Key Rotation

**Automated Key Rotation**:
```bash
#!/bin/bash
# Rotate IAM user access keys
USER_NAME="service-user"

# Create new access key
NEW_KEY=$(aws iam create-access-key --user-name $USER_NAME --query 'AccessKey.AccessKeyId' --output text)

# Update application with new key
kubectl patch secret aws-credentials \
  -p '{"data":{"access-key-id":"'$(echo -n $NEW_KEY | base64)'"}}'

# Wait for application to pick up new key
sleep 300

# Delete old access key
OLD_KEY=$(aws iam list-access-keys --user-name $USER_NAME --query 'AccessKeyMetadata[?AccessKeyId!=`'$NEW_KEY'`].AccessKeyId' --output text)
aws iam delete-access-key --user-name $USER_NAME --access-key-id $OLD_KEY
```

### Vulnerability Management

#### Container Security

**ECR Image Scanning**:
```bash
# Enable image scanning
aws ecr put-image-scanning-configuration \
  --repository-name app-repo \
  --image-scanning-configuration scanOnPush=true

# Get scan results
aws ecr describe-image-scan-findings \
  --repository-name app-repo \
  --image-id imageTag=latest
```

#### Patch Management

**Systems Manager Patch Management**:
```bash
# Create patch baseline
aws ssm create-patch-baseline \
  --name "prod-patch-baseline" \
  --operating-system AMAZON_LINUX_2 \
  --approval-rules file://patch-rules.json

# Execute patch scan
aws ssm send-command \
  --document-name "AWS-RunPatchBaseline" \
  --parameters "Operation=Scan" \
  --targets "Key=tag:Environment,Values=production"
```

## Incident Response

### Incident Management

#### Incident Detection

**Automated Alerting**:
```python
# Lambda function for incident detection
import json
import boto3

def lambda_handler(event, context):
    # Parse CloudWatch alarm
    message = json.loads(event['Records'][0]['Sns']['Message'])
    
    if message['NewStateValue'] == 'ALARM':
        # Create incident ticket
        create_incident_ticket(message)
        
        # Scale resources if needed
        if 'HighCPU' in message['AlarmName']:
            scale_application()
    
    return {'statusCode': 200}

def scale_application():
    ecs = boto3.client('ecs')
    ecs.update_service(
        cluster='prod-cluster',
        service='api-service',
        desiredCount=10
    )
```

#### Incident Response Procedures

**Service Outage Response**:
1. **Immediate Response** (0-5 minutes)
   - Acknowledge alert
   - Assess impact scope
   - Activate incident commander

2. **Investigation** (5-15 minutes)
   - Check service dependencies
   - Review recent deployments
   - Analyze metrics and logs

3. **Mitigation** (15-30 minutes)
   - Implement workarounds
   - Scale resources if needed
   - Consider rollback

4. **Resolution** (30+ minutes)
   - Apply permanent fix
   - Verify service restoration
   - Update stakeholders

#### Runbook Templates

**Database Incident Response**:
```bash
#!/bin/bash
# Database incident response runbook

echo "Starting database incident response..."

# Check database status
DB_STATUS=$(aws rds describe-db-instances --db-instance-identifier prod-database \
  --query 'DBInstances[0].DBInstanceStatus' --output text)

echo "Database status: $DB_STATUS"

if [ "$DB_STATUS" != "available" ]; then
    echo "Database is not available. Checking for recent events..."
    
    # Check recent events
    aws rds describe-events --source-identifier prod-database \
      --source-type db-instance --duration 60
    
    # Check CloudWatch metrics
    aws cloudwatch get-metric-statistics \
      --namespace AWS/RDS \
      --metric-name CPUUtilization \
      --dimensions Name=DBInstanceIdentifier,Value=prod-database \
      --start-time $(date -d '1 hour ago' -u +%Y-%m-%dT%H:%M:%S) \
      --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
      --period 300 \
      --statistics Average
fi
```

## Maintenance Procedures

### Scheduled Maintenance

#### Infrastructure Updates

**Terraform State Management**:
```bash
# Backup Terraform state
aws s3 cp s3://terraform-state-bucket/prod/terraform.tfstate \
  s3://terraform-state-bucket/prod/backups/terraform.tfstate.$(date +%Y%m%d)

# Plan infrastructure updates
terraform plan -var-file=environments/prod/terraform.tfvars

# Apply with approval
terraform apply -var-file=environments/prod/terraform.tfvars
```

#### Application Updates

**EKS Rolling Updates**:
```bash
# Update deployment image
kubectl set image deployment/api-deployment api=api:v1.2.3

# Monitor rollout status
kubectl rollout status deployment/api-deployment

# Rollback if needed
kubectl rollout undo deployment/api-deployment
```

**ECS Service Updates**:
```bash
# Register new task definition
aws ecs register-task-definition --cli-input-json file://task-definition.json

# Update service
aws ecs update-service \
  --cluster prod-cluster \
  --service api-service \
  --task-definition api-service:latest

# Monitor deployment
aws ecs wait services-stable \
  --cluster prod-cluster \
  --services api-service
```

### Database Maintenance

#### RDS Maintenance

**Minor Version Updates**:
```bash
# Check available updates
aws rds describe-db-engine-versions \
  --engine mysql \
  --engine-version 8.0.35 \
  --query 'DBEngineVersions[0].ValidUpgradeTarget[*].EngineVersion'

# Schedule update
aws rds modify-db-instance \
  --db-instance-identifier prod-database \
  --engine-version 8.0.36 \
  --allow-major-version-upgrade \
  --apply-immediately
```

#### Database Optimization

**Performance Tuning**:
```sql
-- Analyze table statistics
ANALYZE TABLE users;

-- Optimize tables
OPTIMIZE TABLE user_sessions;

-- Check index usage
SELECT 
    TABLE_NAME,
    INDEX_NAME,
    CARDINALITY,
    NULLABLE
FROM INFORMATION_SCHEMA.STATISTICS 
WHERE TABLE_SCHEMA = 'application'
ORDER BY CARDINALITY DESC;
```

## Automation and Runbooks

### Automated Operations

#### Auto-remediation

**Lambda-based Auto-remediation**:
```python
import boto3
import json

def lambda_handler(event, context):
    # Parse CloudWatch alarm
    alarm_name = event['detail']['alarmName']
    
    if 'HighMemoryUtilization' in alarm_name:
        # Restart application
        restart_ecs_service()
    elif 'HighDiskUsage' in alarm_name:
        # Clean up old logs
        cleanup_logs()
    elif 'DatabaseConnections' in alarm_name:
        # Kill long-running queries
        kill_long_queries()
    
    return {'statusCode': 200}

def restart_ecs_service():
    ecs = boto3.client('ecs')
    ecs.update_service(
        cluster='prod-cluster',
        service='api-service',
        forceNewDeployment=True
    )
```

#### Scheduled Tasks

**CloudWatch Events Rules**:
```json
{
  "Rules": [{
    "Name": "DailyBackup",
    "ScheduleExpression": "cron(0 2 * * ? *)",
    "State": "ENABLED",
    "Targets": [{
      "Id": "1",
      "Arn": "arn:aws:lambda:us-east-1:123456789012:function:daily-backup"
    }]
  }]
}
```

### Runbook Library

#### Common Operations

**Service Restart Runbook**:
```bash
#!/bin/bash
# Service restart runbook

SERVICE_NAME=${1:-api-service}
CLUSTER_NAME=${2:-prod-cluster}

echo "Restarting service: $SERVICE_NAME in cluster: $CLUSTER_NAME"

# Force new deployment
aws ecs update-service \
  --cluster $CLUSTER_NAME \
  --service $SERVICE_NAME \
  --force-new-deployment

# Wait for stability
aws ecs wait services-stable \
  --cluster $CLUSTER_NAME \
  --services $SERVICE_NAME

echo "Service restart completed successfully"
```

**Cache Clear Runbook**:
```bash
#!/bin/bash
# Clear application cache

REDIS_ENDPOINT=${1:-prod-redis.abc123.cache.amazonaws.com}

echo "Clearing cache on: $REDIS_ENDPOINT"

# Connect and flush cache
redis-cli -h $REDIS_ENDPOINT FLUSHALL

echo "Cache cleared successfully"
```

---

**Related Documentation**:
- [Security Guide](../security/overview.md) - Security operations and compliance
- [Architecture Guide](../architecture/overview.md) - Infrastructure architecture details
- [Deployment Guide](../deployment/getting-started.md) - Initial deployment procedures
- [Troubleshooting Guide](./troubleshooting.md) - Common issues and solutions