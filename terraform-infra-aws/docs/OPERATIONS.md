# Operations Manual

This comprehensive operations manual provides detailed guidance for the day-to-day management, monitoring, maintenance, and troubleshooting of your AWS infrastructure.

## Table of Contents

- [Operations Overview](#operations-overview)
- [Daily Operations](#daily-operations)
- [Infrastructure Monitoring](#infrastructure-monitoring)
- [Performance Management](#performance-management)
- [Backup and Recovery Operations](#backup-and-recovery-operations)
- [Capacity Management](#capacity-management)
- [Incident Response](#incident-response)
- [Maintenance Procedures](#maintenance-procedures)
- [Cost Management](#cost-management)
- [Automation and Tools](#automation-and-tools)

## Operations Overview

### Operational Model

The operations team follows a 24/7 support model with the following tiers:

**Tier 1 - Monitoring & Initial Response**
- Monitor dashboards and alerts
- Initial incident triage
- Basic troubleshooting
- Escalation to Tier 2

**Tier 2 - Technical Investigation**
- Advanced troubleshooting
- Infrastructure modifications
- Performance optimization
- Escalation to Tier 3

**Tier 3 - Expert Resolution**
- Architecture changes
- Complex problem resolution
- Vendor escalation
- Post-incident reviews

### Operational Responsibilities

| Team | Primary Responsibilities | Secondary Responsibilities |
|------|-------------------------|---------------------------|
| **Platform Team** | Infrastructure deployment, Architecture changes, Security compliance | Application support, Performance tuning |
| **DevOps Team** | CI/CD pipelines, Deployment automation, Monitoring setup | Infrastructure maintenance, Incident response |
| **SRE Team** | System reliability, Performance optimization, Capacity planning | Monitoring, Automation, Documentation |
| **Security Team** | Security monitoring, Compliance audits, Access management | Incident response, Security training |

### Service Level Objectives (SLOs)

| Service | Availability | Response Time | Error Rate | Recovery Time |
|---------|--------------|---------------|------------|---------------|
| **Web Application** | 99.9% | < 500ms (95th percentile) | < 0.1% | < 15 minutes |
| **API Services** | 99.95% | < 200ms (95th percentile) | < 0.05% | < 10 minutes |
| **Database** | 99.99% | < 100ms (95th percentile) | < 0.01% | < 5 minutes |
| **Background Jobs** | 99.5% | < 30 seconds | < 1% | < 30 minutes |

## Daily Operations

### Morning Checklist

**Infrastructure Health Check:**
```bash
#!/bin/bash
# Daily morning infrastructure health check

echo "🌅 Daily Infrastructure Health Check - $(date)"
echo "=============================================="

# Check AWS service health
echo "☁️  AWS Service Health:"
aws health describe-events \
    --filter eventTypeCategories=issue,eventStatusCodes=open \
    --query 'events[?startTime>`2024-01-01`].[eventTypeCode,eventScopeCode,statusCode]' \
    --output table

# Check all environments
ENVIRONMENTS=("dev" "staging" "prod")

for env in "${ENVIRONMENTS[@]}"; do
    echo ""
    echo "🏗️  Environment: $env"
    echo "-------------------"
    
    # VPC Status
    VPC_ID=$(aws ec2 describe-vpcs \
        --filters "Name=tag:Environment,Values=$env" \
        --query 'Vpcs[0].VpcId' \
        --output text 2>/dev/null || echo "None")
    
    if [ "$VPC_ID" != "None" ]; then
        echo "✅ VPC: $VPC_ID"
    else
        echo "❌ VPC: Not found"
        continue
    fi
    
    # Load Balancer Status
    ALB_STATUS=$(aws elbv2 describe-load-balancers \
        --query "LoadBalancers[?contains(LoadBalancerName, '$env')].State.Code" \
        --output text 2>/dev/null || echo "None")
    
    if [ "$ALB_STATUS" = "active" ]; then
        echo "✅ Load Balancer: Active"
    else
        echo "❌ Load Balancer: $ALB_STATUS"
    fi
    
    # Database Status
    DB_STATUS=$(aws rds describe-db-instances \
        --query "DBInstances[?contains(DBInstanceIdentifier, '$env')].DBInstanceStatus" \
        --output text 2>/dev/null || echo "None")
    
    if [ "$DB_STATUS" = "available" ]; then
        echo "✅ Database: Available"
    else
        echo "❌ Database: $DB_STATUS"
    fi
    
    # ECS/EKS Status
    if aws ecs describe-clusters --query "clusters[?contains(clusterName, '$env')]" | grep -q clusterName; then
        CLUSTER_STATUS=$(aws ecs describe-clusters \
            --query "clusters[?contains(clusterName, '$env')].status" \
            --output text)
        echo "✅ ECS Cluster: $CLUSTER_STATUS"
    fi
    
    # Application Health Check
    if [ "$ALB_STATUS" = "active" ]; then
        ALB_DNS=$(aws elbv2 describe-load-balancers \
            --query "LoadBalancers[?contains(LoadBalancerName, '$env')].DNSName" \
            --output text)
        
        if [ -n "$ALB_DNS" ]; then
            HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 http://$ALB_DNS/health || echo "000")
            if [ "$HTTP_STATUS" = "200" ]; then
                echo "✅ Application Health: OK"
            else
                echo "❌ Application Health: HTTP $HTTP_STATUS"
            fi
        fi
    fi
done

echo ""
echo "🔍 Security & Compliance Check:"
echo "--------------------------------"

# Check GuardDuty findings
GUARDDUTY_FINDINGS=$(aws guardduty list-findings \
    --detector-id $(aws guardduty list-detectors --query 'DetectorIds[0]' --output text) \
    --finding-criteria Criterion={severity={Eq=[\"HIGH\",\"CRITICAL\"]}} \
    --query 'FindingIds' \
    --output text | wc -w)

echo "🛡️  GuardDuty High/Critical Findings: $GUARDDUTY_FINDINGS"

# Check Config compliance
CONFIG_NONCOMPLIANT=$(aws configservice get-compliance-summary-by-config-rule \
    --query 'ComplianceSummary.NonCompliantResourceCount.CappedCount' \
    --output text 2>/dev/null || echo "0")

echo "⚖️  Config Non-Compliant Resources: $CONFIG_NONCOMPLIANT"

echo ""
echo "💰 Cost Overview (Last 24h):"
echo "-----------------------------"

# Get yesterday's cost
YESTERDAY=$(date -d "yesterday" +%Y-%m-%d)
TODAY=$(date +%Y-%m-%d)

DAILY_COST=$(aws ce get-cost-and-usage \
    --time-period Start=$YESTERDAY,End=$TODAY \
    --granularity DAILY \
    --metrics BlendedCost \
    --query 'ResultsByTime[0].Total.BlendedCost.Amount' \
    --output text 2>/dev/null || echo "N/A")

echo "💵 Yesterday's Cost: \$${DAILY_COST}"

echo ""
echo "✅ Daily health check completed!"
```

### Monitoring Dashboard Review

**Key Metrics to Review Daily:**

1. **Application Performance:**
   - Response time trends
   - Error rate patterns
   - Request volume
   - User session metrics

2. **Infrastructure Health:**
   - CPU and memory utilization
   - Network throughput
   - Storage usage
   - Database performance

3. **Security Metrics:**
   - Failed authentication attempts
   - Security group changes
   - GuardDuty findings
   - CloudTrail anomalies

4. **Cost Metrics:**
   - Daily spend trends
   - Resource utilization
   - Untagged resources
   - Right-sizing opportunities

### Weekly Operations Tasks

**Weekly Infrastructure Review:**
```bash
#!/bin/bash
# Weekly infrastructure review script

echo "📊 Weekly Infrastructure Review - $(date)"
echo "========================================="

# Generate weekly cost report
echo "💰 Weekly Cost Analysis:"
LAST_WEEK=$(date -d "7 days ago" +%Y-%m-%d)
TODAY=$(date +%Y-%m-%d)

aws ce get-cost-and-usage \
    --time-period Start=$LAST_WEEK,End=$TODAY \
    --granularity DAILY \
    --metrics BlendedCost \
    --group-by Type=DIMENSION,Key=SERVICE \
    --query 'ResultsByTime[*].Groups[*].[Keys[0],Metrics.BlendedCost.Amount]' \
    --output table

# Security review
echo ""
echo "🔒 Security Review:"
echo "-------------------"

# Check for unused security groups
echo "🔍 Unused Security Groups:"
aws ec2 describe-security-groups \
    --query 'SecurityGroups[?length(IpPermissions)==`0` && length(IpPermissionsEgress)==`1`].[GroupId,GroupName]' \
    --output table

# Check for public S3 buckets
echo ""
echo "🔍 Public S3 Buckets:"
for bucket in $(aws s3api list-buckets --query 'Buckets[].Name' --output text); do
    PUBLIC_BLOCK=$(aws s3api get-public-access-block --bucket $bucket 2>/dev/null || echo "None")
    if [ "$PUBLIC_BLOCK" = "None" ]; then
        echo "⚠️  Bucket may be public: $bucket"
    fi
done

# Performance review
echo ""
echo "📈 Performance Review:"
echo "----------------------"

# Database performance
echo "Database Performance (7 days):"
aws cloudwatch get-metric-statistics \
    --namespace AWS/RDS \
    --metric-name CPUUtilization \
    --start-time $(date -d "7 days ago" -u +%Y-%m-%dT%H:%M:%S) \
    --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
    --period 86400 \
    --statistics Average,Maximum \
    --query 'Datapoints[*].[Timestamp,Average,Maximum]' \
    --output table

echo ""
echo "📋 Action Items Generated - Review and address findings above"
```

## Infrastructure Monitoring

### Real-Time Monitoring Setup

**CloudWatch Dashboard Configuration:**
```json
{
  "widgets": [
    {
      "type": "metric",
      "properties": {
        "metrics": [
          ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", "prod-alb"],
          ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", "prod-alb"],
          ["AWS/ApplicationELB", "HTTPCode_ELB_5XX_Count", "LoadBalancer", "prod-alb"]
        ],
        "period": 300,
        "stat": "Sum",
        "region": "us-east-1",
        "title": "Application Load Balancer Metrics",
        "yAxis": {
          "left": {
            "min": 0
          }
        }
      }
    },
    {
      "type": "metric",
      "properties": {
        "metrics": [
          ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", "prod-database"],
          ["AWS/RDS", "DatabaseConnections", "DBInstanceIdentifier", "prod-database"],
          ["AWS/RDS", "FreeableMemory", "DBInstanceIdentifier", "prod-database"]
        ],
        "period": 300,
        "stat": "Average",
        "region": "us-east-1",
        "title": "Database Performance"
      }
    },
    {
      "type": "log",
      "properties": {
        "query": "SOURCE '/aws/lambda/api-handler'\n| filter @type = \"REPORT\"\n| stats avg(@duration), max(@duration), min(@duration) by bin(5m)",
        "region": "us-east-1",
        "title": "Lambda Performance",
        "view": "table"
      }
    }
  ]
}
```

### Alerting Configuration

**Critical Alerts Setup:**
```bash
#!/bin/bash
# Setup critical infrastructure alerts

ENVIRONMENT=$1
SNS_TOPIC_ARN=$2

if [ -z "$ENVIRONMENT" ] || [ -z "$SNS_TOPIC_ARN" ]; then
    echo "❌ Usage: $0 <environment> <sns_topic_arn>"
    exit 1
fi

echo "🚨 Setting up critical alerts for: $ENVIRONMENT"

# High CPU Utilization - RDS
aws cloudwatch put-metric-alarm \
    --alarm-name "$ENVIRONMENT-rds-high-cpu" \
    --alarm-description "RDS CPU utilization is high" \
    --metric-name CPUUtilization \
    --namespace AWS/RDS \
    --statistic Average \
    --period 300 \
    --threshold 80 \
    --comparison-operator GreaterThanThreshold \
    --evaluation-periods 2 \
    --alarm-actions $SNS_TOPIC_ARN \
    --ok-actions $SNS_TOPIC_ARN \
    --dimensions Name=DBInstanceIdentifier,Value=$ENVIRONMENT-database

# High Response Time - ALB
aws cloudwatch put-metric-alarm \
    --alarm-name "$ENVIRONMENT-alb-high-response-time" \
    --alarm-description "ALB response time is high" \
    --metric-name TargetResponseTime \
    --namespace AWS/ApplicationELB \
    --statistic Average \
    --period 300 \
    --threshold 2.0 \
    --comparison-operator GreaterThanThreshold \
    --evaluation-periods 2 \
    --alarm-actions $SNS_TOPIC_ARN \
    --dimensions Name=LoadBalancer,Value=$ENVIRONMENT-alb

# High Error Rate - ALB
aws cloudwatch put-metric-alarm \
    --alarm-name "$ENVIRONMENT-alb-high-error-rate" \
    --alarm-description "ALB error rate is high" \
    --metric-name HTTPCode_ELB_5XX_Count \
    --namespace AWS/ApplicationELB \
    --statistic Sum \
    --period 300 \
    --threshold 10 \
    --comparison-operator GreaterThanThreshold \
    --evaluation-periods 1 \
    --alarm-actions $SNS_TOPIC_ARN \
    --dimensions Name=LoadBalancer,Value=$ENVIRONMENT-alb

# Database Connection Issues
aws cloudwatch put-metric-alarm \
    --alarm-name "$ENVIRONMENT-rds-connection-count" \
    --alarm-description "RDS connection count is high" \
    --metric-name DatabaseConnections \
    --namespace AWS/RDS \
    --statistic Average \
    --period 300 \
    --threshold 40 \
    --comparison-operator GreaterThanThreshold \
    --evaluation-periods 2 \
    --alarm-actions $SNS_TOPIC_ARN \
    --dimensions Name=DBInstanceIdentifier,Value=$ENVIRONMENT-database

echo "✅ Critical alerts configured"
```

### Log Management

**Centralized Logging Setup:**
```bash
#!/bin/bash
# Configure centralized logging

ENVIRONMENT=$1

echo "📋 Setting up centralized logging for: $ENVIRONMENT"

# Create log groups with retention
LOG_GROUPS=(
    "/aws/ecs/$ENVIRONMENT-api"
    "/aws/ecs/$ENVIRONMENT-web" 
    "/aws/lambda/$ENVIRONMENT-processor"
    "/aws/rds/instance/$ENVIRONMENT-database/error"
    "/aws/apigateway/$ENVIRONMENT-api"
)

for log_group in "${LOG_GROUPS[@]}"; do
    echo "Creating log group: $log_group"
    
    aws logs create-log-group \
        --log-group-name $log_group \
        2>/dev/null || echo "Log group already exists"
    
    # Set retention policy based on environment
    if [ "$ENVIRONMENT" = "prod" ]; then
        RETENTION_DAYS=90
    elif [ "$ENVIRONMENT" = "staging" ]; then
        RETENTION_DAYS=30
    else
        RETENTION_DAYS=7
    fi
    
    aws logs put-retention-policy \
        --log-group-name $log_group \
        --retention-in-days $RETENTION_DAYS
        
    echo "✅ Log group configured: $log_group (${RETENTION_DAYS} days retention)"
done

# Set up log insights queries
echo ""
echo "📊 Creating CloudWatch Insights queries..."

# Error analysis query
aws logs put-query-definition \
    --name "$ENVIRONMENT-error-analysis" \
    --log-group-names "/aws/ecs/$ENVIRONMENT-api" \
    --query-string 'fields @timestamp, @message
| filter @message like /ERROR/
| stats count() by bin(5m)
| sort @timestamp desc'

# Performance analysis query  
aws logs put-query-definition \
    --name "$ENVIRONMENT-performance-analysis" \
    --log-group-names "/aws/lambda/$ENVIRONMENT-processor" \
    --query-string 'filter @type = "REPORT"
| fields @requestId, @duration, @billedDuration, @memorySize, @maxMemoryUsed
| sort @duration desc
| limit 100'

echo "✅ Centralized logging setup completed"
```

## Performance Management

### Performance Monitoring

**Application Performance Monitoring:**
```bash
#!/bin/bash
# Monitor application performance

ENVIRONMENT=$1
TIME_RANGE=${2:-"1h"}

echo "📊 Application Performance Report - $ENVIRONMENT"
echo "Time Range: Last $TIME_RANGE"
echo "============================================="

# Calculate time range
case $TIME_RANGE in
    "1h") SECONDS=3600 ;;
    "6h") SECONDS=21600 ;;
    "1d") SECONDS=86400 ;;
    "1w") SECONDS=604800 ;;
    *) SECONDS=3600 ;;
esac

START_TIME=$(date -d "$SECONDS seconds ago" -u +%Y-%m-%dT%H:%M:%S)
END_TIME=$(date -u +%Y-%m-%dT%H:%M:%S)

# ALB Performance Metrics
echo "🌐 Load Balancer Performance:"
echo "-----------------------------"

ALB_METRICS=$(aws cloudwatch get-metric-statistics \
    --namespace AWS/ApplicationELB \
    --metric-name TargetResponseTime \
    --start-time $START_TIME \
    --end-time $END_TIME \
    --period 300 \
    --statistics Average,Maximum \
    --dimensions Name=LoadBalancer,Value=$ENVIRONMENT-alb \
    --query 'Datapoints[0].[Average,Maximum]' \
    --output text)

if [ -n "$ALB_METRICS" ]; then
    AVG_RESPONSE=$(echo $ALB_METRICS | cut -d' ' -f1)
    MAX_RESPONSE=$(echo $ALB_METRICS | cut -d' ' -f2)
    echo "Average Response Time: ${AVG_RESPONSE}s"
    echo "Maximum Response Time: ${MAX_RESPONSE}s"
else
    echo "No ALB metrics available"
fi

# Request Count
REQUEST_COUNT=$(aws cloudwatch get-metric-statistics \
    --namespace AWS/ApplicationELB \
    --metric-name RequestCount \
    --start-time $START_TIME \
    --end-time $END_TIME \
    --period $SECONDS \
    --statistics Sum \
    --dimensions Name=LoadBalancer,Value=$ENVIRONMENT-alb \
    --query 'Datapoints[0].Sum' \
    --output text)

echo "Total Requests: ${REQUEST_COUNT:-0}"

# Error Rate
ERROR_COUNT=$(aws cloudwatch get-metric-statistics \
    --namespace AWS/ApplicationELB \
    --metric-name HTTPCode_ELB_5XX_Count \
    --start-time $START_TIME \
    --end-time $END_TIME \
    --period $SECONDS \
    --statistics Sum \
    --dimensions Name=LoadBalancer,Value=$ENVIRONMENT-alb \
    --query 'Datapoints[0].Sum' \
    --output text)

if [ -n "$REQUEST_COUNT" ] && [ "$REQUEST_COUNT" -gt 0 ] && [ -n "$ERROR_COUNT" ]; then
    ERROR_RATE=$(echo "scale=4; $ERROR_COUNT * 100 / $REQUEST_COUNT" | bc)
    echo "Error Rate: ${ERROR_RATE}%"
else
    echo "Error Rate: 0%"
fi

# Database Performance
echo ""
echo "🗄️  Database Performance:"
echo "-------------------------"

DB_CPU=$(aws cloudwatch get-metric-statistics \
    --namespace AWS/RDS \
    --metric-name CPUUtilization \
    --start-time $START_TIME \
    --end-time $END_TIME \
    --period 300 \
    --statistics Average,Maximum \
    --dimensions Name=DBInstanceIdentifier,Value=$ENVIRONMENT-database \
    --query 'Datapoints[0].[Average,Maximum]' \
    --output text)

if [ -n "$DB_CPU" ]; then
    AVG_CPU=$(echo $DB_CPU | cut -d' ' -f1)
    MAX_CPU=$(echo $DB_CPU | cut -d' ' -f2)
    echo "Average CPU: ${AVG_CPU}%"
    echo "Maximum CPU: ${MAX_CPU}%"
fi

DB_CONNECTIONS=$(aws cloudwatch get-metric-statistics \
    --namespace AWS/RDS \
    --metric-name DatabaseConnections \
    --start-time $START_TIME \
    --end-time $END_TIME \
    --period 300 \
    --statistics Average,Maximum \
    --dimensions Name=DBInstanceIdentifier,Value=$ENVIRONMENT-database \
    --query 'Datapoints[0].[Average,Maximum]' \
    --output text)

if [ -n "$DB_CONNECTIONS" ]; then
    AVG_CONN=$(echo $DB_CONNECTIONS | cut -d' ' -f1)
    MAX_CONN=$(echo $DB_CONNECTIONS | cut -d' ' -f2)
    echo "Average Connections: ${AVG_CONN}"
    echo "Maximum Connections: ${MAX_CONN}"
fi

echo ""
echo "✅ Performance report completed"
```

### Performance Optimization

**Database Optimization:**
```bash
#!/bin/bash
# Database performance optimization

ENVIRONMENT=$1

echo "🔧 Database Performance Optimization - $ENVIRONMENT"
echo "=================================================="

DB_IDENTIFIER="$ENVIRONMENT-database"

# Check if Performance Insights is enabled
PI_ENABLED=$(aws rds describe-db-instances \
    --db-instance-identifier $DB_IDENTIFIER \
    --query 'DBInstances[0].PerformanceInsightsEnabled' \
    --output text)

if [ "$PI_ENABLED" != "True" ]; then
    echo "⚡ Enabling Performance Insights..."
    aws rds modify-db-instance \
        --db-instance-identifier $DB_IDENTIFIER \
        --enable-performance-insights \
        --performance-insights-retention-period 7
    echo "✅ Performance Insights enabled"
fi

# Analyze slow queries
echo ""
echo "🐌 Analyzing slow queries..."

DB_RESOURCE_ID=$(aws rds describe-db-instances \
    --db-instance-identifier $DB_IDENTIFIER \
    --query 'DBInstances[0].DbiResourceId' \
    --output text)

if [ -n "$DB_RESOURCE_ID" ]; then
    # Get top SQL statements by execution time
    aws pi get-resource-metrics \
        --service-type RDS \
        --identifier $DB_RESOURCE_ID \
        --metric-queries '[
            {
                "Metric": "db.SQL.Innodb_rows_read.avg",
                "GroupBy": {"Group": "db.sql_tokenized.statement", "Limit": 10}
            }
        ]' \
        --start-time $(date -d "1 hour ago" -u +%Y-%m-%dT%H:%M:%S) \
        --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
        --period-in-seconds 300
fi

# Check database parameters
echo ""
echo "⚙️  Database Parameter Analysis:"
echo "--------------------------------"

PARAM_GROUP=$(aws rds describe-db-instances \
    --db-instance-identifier $DB_IDENTIFIER \
    --query 'DBInstances[0].DBParameterGroups[0].DBParameterGroupName' \
    --output text)

echo "Parameter Group: $PARAM_GROUP"

# Key parameters to check
IMPORTANT_PARAMS=(
    "innodb_buffer_pool_size"
    "max_connections"
    "query_cache_size"
    "slow_query_log"
)

for param in "${IMPORTANT_PARAMS[@]}"; do
    VALUE=$(aws rds describe-db-parameters \
        --db-parameter-group-name $PARAM_GROUP \
        --source user \
        --query "Parameters[?ParameterName=='$param'].ParameterValue" \
        --output text)
    echo "$param: ${VALUE:-default}"
done

echo ""
echo "💡 Optimization Recommendations:"
echo "--------------------------------"
echo "1. Monitor Performance Insights for query optimization opportunities"
echo "2. Consider read replicas for read-heavy workloads"
echo "3. Review and optimize slow queries"
echo "4. Monitor connection pooling effectiveness"
```

## Backup and Recovery Operations

### Automated Backup Management

**Backup Status Check:**
```bash
#!/bin/bash
# Check backup status across all services

ENVIRONMENT=$1

echo "💾 Backup Status Report - $ENVIRONMENT"
echo "====================================="

# RDS Automated Backups
echo "🗄️  RDS Backup Status:"
echo "----------------------"

DB_IDENTIFIER="$ENVIRONMENT-database"
BACKUP_INFO=$(aws rds describe-db-instances \
    --db-instance-identifier $DB_IDENTIFIER \
    --query 'DBInstances[0].[BackupRetentionPeriod,PreferredBackupWindow,LatestRestorableTime]' \
    --output text 2>/dev/null)

if [ -n "$BACKUP_INFO" ]; then
    RETENTION=$(echo $BACKUP_INFO | cut -d' ' -f1)
    WINDOW=$(echo $BACKUP_INFO | cut -d' ' -f2)
    LATEST=$(echo $BACKUP_INFO | cut -d' ' -f3)
    
    echo "Retention Period: $RETENTION days"
    echo "Backup Window: $WINDOW"
    echo "Latest Restorable Time: $LATEST"
    
    # Check recent snapshots
    echo ""
    echo "Recent Manual Snapshots:"
    aws rds describe-db-snapshots \
        --db-instance-identifier $DB_IDENTIFIER \
        --snapshot-type manual \
        --query 'DBSnapshots[:5].[DBSnapshotIdentifier,SnapshotCreateTime,Status]' \
        --output table
else
    echo "❌ Database not found or no backup info available"
fi

# DynamoDB Backups
echo ""
echo "📊 DynamoDB Backup Status:"
echo "-------------------------"

TABLES=$(aws dynamodb list-tables \
    --query "TableNames[?contains(@, '$ENVIRONMENT')]" \
    --output text)

for table in $TABLES; do
    echo "Table: $table"
    
    # Check PITR status
    PITR_STATUS=$(aws dynamodb describe-continuous-backups \
        --table-name $table \
        --query 'ContinuousBackupsDescription.PointInTimeRecoveryDescription.PointInTimeRecoveryStatus' \
        --output text 2>/dev/null)
    
    echo "  Point-in-Time Recovery: ${PITR_STATUS:-DISABLED}"
    
    # Check on-demand backups
    BACKUP_COUNT=$(aws dynamodb list-backups \
        --table-name $table \
        --query 'BackupSummaries' \
        --output text | wc -l)
    
    echo "  On-Demand Backups: $BACKUP_COUNT"
    echo ""
done

# S3 Versioning and Replication
echo "🪣 S3 Backup Configuration:"
echo "---------------------------"

BUCKETS=$(aws s3api list-buckets \
    --query "Buckets[?contains(Name, '$ENVIRONMENT')].Name" \
    --output text)

for bucket in $BUCKETS; do
    echo "Bucket: $bucket"
    
    # Check versioning
    VERSIONING=$(aws s3api get-bucket-versioning \
        --bucket $bucket \
        --query 'Status' \
        --output text 2>/dev/null)
    
    echo "  Versioning: ${VERSIONING:-Disabled}"
    
    # Check replication
    REPLICATION=$(aws s3api get-bucket-replication \
        --bucket $bucket \
        --query 'ReplicationConfiguration.Rules[0].Status' \
        --output text 2>/dev/null || echo "None")
    
    echo "  Cross-Region Replication: $REPLICATION"
    echo ""
done

echo "✅ Backup status check completed"
```

### Recovery Procedures

**Database Point-in-Time Recovery:**
```bash
#!/bin/bash
# Perform database point-in-time recovery

ENVIRONMENT=$1
RESTORE_TIME=$2
NEW_DB_IDENTIFIER=$3

if [ -z "$ENVIRONMENT" ] || [ -z "$RESTORE_TIME" ] || [ -z "$NEW_DB_IDENTIFIER" ]; then
    echo "❌ Usage: $0 <environment> <restore_time> <new_db_identifier>"
    echo "   restore_time format: YYYY-MM-DDTHH:MM:SS.000Z"
    echo "   Example: 2024-01-15T14:30:00.000Z"
    exit 1
fi

echo "🔄 Starting Point-in-Time Recovery"
echo "================================="
echo "Environment: $ENVIRONMENT"
echo "Restore Time: $RESTORE_TIME"
echo "New DB Identifier: $NEW_DB_IDENTIFIER"
echo ""

SOURCE_DB="$ENVIRONMENT-database"

# Validate source database exists
aws rds describe-db-instances \
    --db-instance-identifier $SOURCE_DB \
    --query 'DBInstances[0].DBInstanceIdentifier' \
    --output text >/dev/null

if [ $? -ne 0 ]; then
    echo "❌ Source database not found: $SOURCE_DB"
    exit 1
fi

# Check if restore time is valid
LATEST_RESTORE_TIME=$(aws rds describe-db-instances \
    --db-instance-identifier $SOURCE_DB \
    --query 'DBInstances[0].LatestRestorableTime' \
    --output text)

echo "📅 Latest restorable time: $LATEST_RESTORE_TIME"

# Confirm recovery
echo "⚠️  This will create a new database instance. Continue? (yes/no)"
read -r CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "❌ Recovery cancelled"
    exit 1
fi

# Perform restore
echo "🔄 Starting restore operation..."
aws rds restore-db-instance-to-point-in-time \
    --source-db-instance-identifier $SOURCE_DB \
    --target-db-instance-identifier $NEW_DB_IDENTIFIER \
    --restore-time $RESTORE_TIME \
    --no-multi-az \
    --no-publicly-accessible

if [ $? -eq 0 ]; then
    echo "✅ Restore initiated successfully"
    echo "⏳ Waiting for database to become available..."
    
    aws rds wait db-instance-available \
        --db-instance-identifier $NEW_DB_IDENTIFIER
    
    echo "✅ Database restore completed: $NEW_DB_IDENTIFIER"
    
    # Get endpoint
    ENDPOINT=$(aws rds describe-db-instances \
        --db-instance-identifier $NEW_DB_IDENTIFIER \
        --query 'DBInstances[0].Endpoint.Address' \
        --output text)
    
    echo "🔗 New database endpoint: $ENDPOINT"
else
    echo "❌ Restore failed"
    exit 1
fi
```

## Capacity Management

### Resource Utilization Analysis

**Capacity Planning Report:**
```bash
#!/bin/bash
# Generate capacity planning report

ENVIRONMENT=$1
DAYS=${2:-7}

echo "📊 Capacity Planning Report - $ENVIRONMENT"
echo "Time Period: Last $DAYS days"
echo "=========================================="

START_TIME=$(date -d "$DAYS days ago" -u +%Y-%m-%dT%H:%M:%S)
END_TIME=$(date -u +%Y-%m-%dT%H:%M:%S)

# EC2 Instance Analysis
echo "💻 EC2 Instance Utilization:"
echo "----------------------------"

INSTANCES=$(aws ec2 describe-instances \
    --filters "Name=tag:Environment,Values=$ENVIRONMENT" "Name=instance-state-name,Values=running" \
    --query 'Reservations[].Instances[].[InstanceId,InstanceType]' \
    --output text)

while read -r instance_id instance_type; do
    if [ -n "$instance_id" ]; then
        echo "Instance: $instance_id ($instance_type)"
        
        # CPU Utilization
        CPU_STATS=$(aws cloudwatch get-metric-statistics \
            --namespace AWS/EC2 \
            --metric-name CPUUtilization \
            --start-time $START_TIME \
            --end-time $END_TIME \
            --period 86400 \
            --statistics Average,Maximum \
            --dimensions Name=InstanceId,Value=$instance_id \
            --query 'Datapoints[*].[Average,Maximum]' \
            --output text)
        
        if [ -n "$CPU_STATS" ]; then
            AVG_CPU=$(echo "$CPU_STATS" | awk '{sum+=$1; count++} END {print sum/count}')
            MAX_CPU=$(echo "$CPU_STATS" | awk 'BEGIN{max=0} {if($2>max) max=$2} END {print max}')
            echo "  Average CPU: ${AVG_CPU}%"
            echo "  Peak CPU: ${MAX_CPU}%"
        fi
        
        # Memory utilization (requires CloudWatch agent)
        MEMORY_STATS=$(aws cloudwatch get-metric-statistics \
            --namespace CWAgent \
            --metric-name mem_used_percent \
            --start-time $START_TIME \
            --end-time $END_TIME \
            --period 86400 \
            --statistics Average,Maximum \
            --dimensions Name=InstanceId,Value=$instance_id \
            --query 'Datapoints[*].[Average,Maximum]' \
            --output text 2>/dev/null)
        
        if [ -n "$MEMORY_STATS" ]; then
            AVG_MEM=$(echo "$MEMORY_STATS" | awk '{sum+=$1; count++} END {print sum/count}')
            MAX_MEM=$(echo "$MEMORY_STATS" | awk 'BEGIN{max=0} {if($2>max) max=$2} END {print max}')
            echo "  Average Memory: ${AVG_MEM}%"
            echo "  Peak Memory: ${MAX_MEM}%"
        fi
        echo ""
    fi
done <<< "$INSTANCES"

# RDS Analysis
echo "🗄️  Database Utilization:"
echo "-------------------------"

DB_IDENTIFIER="$ENVIRONMENT-database"

# Database CPU
DB_CPU_STATS=$(aws cloudwatch get-metric-statistics \
    --namespace AWS/RDS \
    --metric-name CPUUtilization \
    --start-time $START_TIME \
    --end-time $END_TIME \
    --period 86400 \
    --statistics Average,Maximum \
    --dimensions Name=DBInstanceIdentifier,Value=$DB_IDENTIFIER \
    --query 'Datapoints[*].[Average,Maximum]' \
    --output text)

if [ -n "$DB_CPU_STATS" ]; then
    AVG_DB_CPU=$(echo "$DB_CPU_STATS" | awk '{sum+=$1; count++} END {print sum/count}')
    MAX_DB_CPU=$(echo "$DB_CPU_STATS" | awk 'BEGIN{max=0} {if($2>max) max=$2} END {print max}')
    echo "Average CPU: ${AVG_DB_CPU}%"
    echo "Peak CPU: ${MAX_DB_CPU}%"
fi

# Database Connections
DB_CONN_STATS=$(aws cloudwatch get-metric-statistics \
    --namespace AWS/RDS \
    --metric-name DatabaseConnections \
    --start-time $START_TIME \
    --end-time $END_TIME \
    --period 86400 \
    --statistics Average,Maximum \
    --dimensions Name=DBInstanceIdentifier,Value=$DB_IDENTIFIER \
    --query 'Datapoints[*].[Average,Maximum]' \
    --output text)

if [ -n "$DB_CONN_STATS" ]; then
    AVG_CONN=$(echo "$DB_CONN_STATS" | awk '{sum+=$1; count++} END {print sum/count}')
    MAX_CONN=$(echo "$DB_CONN_STATS" | awk 'BEGIN{max=0} {if($2>max) max=$2} END {print max}')
    echo "Average Connections: ${AVG_CONN}"
    echo "Peak Connections: ${MAX_CONN}"
fi

# Storage usage
STORAGE_STATS=$(aws cloudwatch get-metric-statistics \
    --namespace AWS/RDS \
    --metric-name FreeStorageSpace \
    --start-time $START_TIME \
    --end-time $END_TIME \
    --period 86400 \
    --statistics Average \
    --dimensions Name=DBInstanceIdentifier,Value=$DB_IDENTIFIER \
    --query 'Datapoints[*].Average' \
    --output text)

if [ -n "$STORAGE_STATS" ]; then
    FREE_STORAGE=$(echo "$STORAGE_STATS" | awk '{sum+=$1; count++} END {print sum/count}')
    FREE_STORAGE_GB=$(echo "scale=2; $FREE_STORAGE / 1073741824" | bc)
    echo "Average Free Storage: ${FREE_STORAGE_GB} GB"
fi

echo ""
echo "💡 Capacity Recommendations:"
echo "-----------------------------"

# Generate recommendations based on utilization
if [ -n "$AVG_DB_CPU" ]; then
    if (( $(echo "$AVG_DB_CPU > 70" | bc -l) )); then
        echo "🔥 Database CPU usage is high - consider upgrading instance type"
    elif (( $(echo "$AVG_DB_CPU < 20" | bc -l) )); then
        echo "💰 Database CPU usage is low - consider downsizing to save costs"
    fi
fi

if [ -n "$FREE_STORAGE_GB" ]; then
    if (( $(echo "$FREE_STORAGE_GB < 10" | bc -l) )); then
        echo "💾 Database storage is running low - plan for storage increase"
    fi
fi

echo ""
echo "✅ Capacity planning report completed"
```

### Auto Scaling Management

**ECS Auto Scaling Configuration:**
```bash
#!/bin/bash
# Configure and manage ECS auto scaling

ENVIRONMENT=$1
SERVICE_NAME=$2
ACTION=${3:-status}

if [ -z "$ENVIRONMENT" ] || [ -z "$SERVICE_NAME" ]; then
    echo "❌ Usage: $0 <environment> <service_name> [action]"
    echo "   Actions: status, enable, disable, update"
    exit 1
fi

CLUSTER_NAME="$ENVIRONMENT-cluster"
RESOURCE_ID="service/$CLUSTER_NAME/$SERVICE_NAME"

echo "⚡ ECS Auto Scaling Management"
echo "============================="
echo "Service: $SERVICE_NAME"
echo "Environment: $ENVIRONMENT"
echo "Action: $ACTION"
echo ""

case $ACTION in
    "status")
        echo "📊 Current Auto Scaling Status:"
        echo "-------------------------------"
        
        # Check if scalable target exists
        SCALABLE_TARGET=$(aws application-autoscaling describe-scalable-targets \
            --service-namespace ecs \
            --resource-ids $RESOURCE_ID \
            --query 'ScalableTargets[0].[MinCapacity,MaxCapacity,RoleARN]' \
            --output text 2>/dev/null)
        
        if [ -n "$SCALABLE_TARGET" ] && [ "$SCALABLE_TARGET" != "None" ]; then
            MIN_CAP=$(echo $SCALABLE_TARGET | cut -d' ' -f1)
            MAX_CAP=$(echo $SCALABLE_TARGET | cut -d' ' -f2)
            echo "✅ Auto Scaling: ENABLED"
            echo "   Min Capacity: $MIN_CAP"
            echo "   Max Capacity: $MAX_CAP"
            
            # Get scaling policies
            echo ""
            echo "📋 Scaling Policies:"
            aws application-autoscaling describe-scaling-policies \
                --service-namespace ecs \
                --resource-id $RESOURCE_ID \
                --query 'ScalingPolicies[].[PolicyName,PolicyType,TargetTrackingScalingPolicyConfiguration.TargetValue]' \
                --output table
        else
            echo "❌ Auto Scaling: DISABLED"
        fi
        ;;
        
    "enable")
        echo "🔧 Enabling Auto Scaling..."
        
        # Register scalable target
        aws application-autoscaling register-scalable-target \
            --service-namespace ecs \
            --resource-id $RESOURCE_ID \
            --scalable-dimension ecs:service:DesiredCount \
            --min-capacity 2 \
            --max-capacity 10
        
        # Create CPU-based scaling policy
        aws application-autoscaling put-scaling-policy \
            --service-namespace ecs \
            --resource-id $RESOURCE_ID \
            --scalable-dimension ecs:service:DesiredCount \
            --policy-name "$SERVICE_NAME-cpu-scaling" \
            --policy-type TargetTrackingScaling \
            --target-tracking-scaling-policy-configuration '{
                "TargetValue": 70.0,
                "PredefinedMetricSpecification": {
                    "PredefinedMetricType": "ECSServiceAverageCPUUtilization"
                },
                "ScaleOutCooldown": 300,
                "ScaleInCooldown": 300
            }'
        
        echo "✅ Auto Scaling enabled with CPU target of 70%"
        ;;
        
    "disable")
        echo "🛑 Disabling Auto Scaling..."
        
        # Delete scaling policies first
        POLICIES=$(aws application-autoscaling describe-scaling-policies \
            --service-namespace ecs \
            --resource-id $RESOURCE_ID \
            --query 'ScalingPolicies[].PolicyName' \
            --output text)
        
        for policy in $POLICIES; do
            aws application-autoscaling delete-scaling-policy \
                --service-namespace ecs \
                --resource-id $RESOURCE_ID \
                --scalable-dimension ecs:service:DesiredCount \
                --policy-name $policy
        done
        
        # Deregister scalable target
        aws application-autoscaling deregister-scalable-target \
            --service-namespace ecs \
            --resource-id $RESOURCE_ID \
            --scalable-dimension ecs:service:DesiredCount
        
        echo "✅ Auto Scaling disabled"
        ;;
        
    "update")
        echo "📝 Updating Auto Scaling Configuration..."
        echo "Enter new minimum capacity:"
        read -r MIN_CAP
        echo "Enter new maximum capacity:"
        read -r MAX_CAP
        
        aws application-autoscaling register-scalable-target \
            --service-namespace ecs \
            --resource-id $RESOURCE_ID \
            --scalable-dimension ecs:service:DesiredCount \
            --min-capacity $MIN_CAP \
            --max-capacity $MAX_CAP
        
        echo "✅ Auto Scaling limits updated: $MIN_CAP - $MAX_CAP"
        ;;
        
    *)
        echo "❌ Unknown action: $ACTION"
        echo "Available actions: status, enable, disable, update"
        exit 1
        ;;
esac
```

## Cost Management

### Daily Cost Monitoring

**Cost Analysis Script:**
```bash
#!/bin/bash
# Daily cost analysis and reporting

ENVIRONMENT=${1:-all}
DAYS=${2:-7}

echo "💰 Cost Analysis Report"
echo "======================="
echo "Environment: $ENVIRONMENT"
echo "Period: Last $DAYS days"
echo "Date: $(date)"
echo ""

# Calculate date range
END_DATE=$(date +%Y-%m-%d)
START_DATE=$(date -d "$DAYS days ago" +%Y-%m-%d)

# Overall cost trend
echo "📊 Cost Trend Analysis:"
echo "----------------------"

if [ "$ENVIRONMENT" = "all" ]; then
    FILTER_JSON='{}'
else
    FILTER_JSON='{
        "Tags": {
            "Key": "Environment",
            "Values": ["'$ENVIRONMENT'"]
        }
    }'
fi

aws ce get-cost-and-usage \
    --time-period Start=$START_DATE,End=$END_DATE \
    --granularity DAILY \
    --metrics BlendedCost \
    --filter "$FILTER_JSON" \
    --query 'ResultsByTime[*].[TimePeriod.Start,Total.BlendedCost.Amount]' \
    --output table

# Cost by service
echo ""
echo "🏷️  Cost by Service (Last 24h):"
echo "--------------------------------"

YESTERDAY=$(date -d "yesterday" +%Y-%m-%d)
TODAY=$(date +%Y-%m-%d)

aws ce get-cost-and-usage \
    --time-period Start=$YESTERDAY,End=$TODAY \
    --granularity DAILY \
    --metrics BlendedCost \
    --group-by Type=DIMENSION,Key=SERVICE \
    --filter "$FILTER_JSON" \
    --query 'ResultsByTime[0].Groups[*].[Keys[0],Metrics.BlendedCost.Amount]' \
    --output table

# Largest cost contributors
echo ""
echo "💸 Top Cost Contributors:"
echo "------------------------"

aws ce get-cost-and-usage \
    --time-period Start=$START_DATE,End=$END_DATE \
    --granularity DAILY \
    --metrics BlendedCost \
    --group-by Type=DIMENSION,Key=SERVICE \
    --filter "$FILTER_JSON" \
    --query 'ResultsByTime[*].Groups[*].[Keys[0],Metrics.BlendedCost.Amount]' \
    --output text | \
    awk '{service=$1; cost=$2; total[service]+=cost} END {for(s in total) printf "%-30s $%.2f\n", s, total[s]}' | \
    sort -k2 -nr | head -10

# Untagged resources cost
echo ""
echo "🏷️  Untagged Resources Cost:"
echo "----------------------------"

aws ce get-cost-and-usage \
    --time-period Start=$YESTERDAY,End=$TODAY \
    --granularity DAILY \
    --metrics BlendedCost \
    --filter '{
        "Not": {
            "Tags": {
                "Key": "Environment"
            }
        }
    }' \
    --query 'ResultsByTime[0].Total.BlendedCost.Amount' \
    --output text | \
    xargs -I {} echo "Untagged resources cost: \${}"

# Cost optimization recommendations
echo ""
echo "💡 Cost Optimization Opportunities:"
echo "-----------------------------------"

# Check for idle resources
echo "🔍 Checking for optimization opportunities..."

# Idle ELBs
IDLE_ELBS=$(aws elbv2 describe-load-balancers \
    --query "LoadBalancers[?State.Code=='active']" \
    --output text | wc -l)

# Unused EBS volumes
UNUSED_VOLUMES=$(aws ec2 describe-volumes \
    --filters "Name=status,Values=available" \
    --query 'Volumes[].VolumeId' \
    --output text | wc -w)

# Idle EC2 instances (CPU < 5% for 7 days)
echo "🖥️  Low-utilization EC2 instances:"
INSTANCES=$(aws ec2 describe-instances \
    --filters "Name=instance-state-name,Values=running" \
    --query 'Reservations[].Instances[].[InstanceId,InstanceType]' \
    --output text)

while read -r instance_id instance_type; do
    if [ -n "$instance_id" ]; then
        AVG_CPU=$(aws cloudwatch get-metric-statistics \
            --namespace AWS/EC2 \
            --metric-name CPUUtilization \
            --start-time $(date -d "7 days ago" -u +%Y-%m-%dT%H:%M:%S) \
            --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
            --period 86400 \
            --statistics Average \
            --dimensions Name=InstanceId,Value=$instance_id \
            --query 'Datapoints[*].Average' \
            --output text | \
            awk '{sum+=$1; count++} END {if(count>0) print sum/count; else print 0}')
        
        if (( $(echo "$AVG_CPU < 5" | bc -l) )); then
            echo "   $instance_id ($instance_type): ${AVG_CPU}% CPU - Consider downsizing"
        fi
    fi
done <<< "$INSTANCES"

echo ""
echo "Unused EBS Volumes: $UNUSED_VOLUMES"
echo ""
echo "💰 Potential Savings:"
echo "   - Review idle load balancers"
echo "   - Delete unused EBS volumes"
echo "   - Consider reserved instances for consistent workloads"
echo "   - Implement auto-scaling to optimize resource usage"
echo ""
echo "✅ Cost analysis completed"
```

## Automation and Tools

### Operations Automation

**Automated Maintenance Tasks:**
```bash
#!/bin/bash
# Automated maintenance tasks

ENVIRONMENT=$1
TASK=${2:-all}

echo "🔧 Automated Maintenance - $ENVIRONMENT"
echo "======================================"

case $TASK in
    "all"|"cleanup")
        echo "🧹 Running cleanup tasks..."
        
        # Clean up old ECS task definitions
        echo "  Cleaning ECS task definitions..."
        FAMILIES=$(aws ecs list-task-definition-families --status ACTIVE --query 'families' --output text)
        
        for family in $FAMILIES; do
            if [[ $family == *"$ENVIRONMENT"* ]]; then
                # Keep only last 5 revisions
                OLD_REVISIONS=$(aws ecs list-task-definitions \
                    --family-prefix $family \
                    --status ACTIVE \
                    --sort DESC \
                    --query 'taskDefinitionArns[5:]' \
                    --output text)
                
                for revision in $OLD_REVISIONS; do
                    if [ -n "$revision" ]; then
                        aws ecs deregister-task-definition --task-definition $revision
                        echo "    Deregistered: $revision"
                    fi
                done
            fi
        done
        
        # Clean up old AMIs (keep last 10)
        echo "  Cleaning old AMIs..."
        OLD_AMIS=$(aws ec2 describe-images \
            --owners self \
            --filters "Name=tag:Environment,Values=$ENVIRONMENT" \
            --query 'Images | sort_by(@, &CreationDate) | [:-10].ImageId' \
            --output text)
        
        for ami in $OLD_AMIS; do
            if [ -n "$ami" ]; then
                aws ec2 deregister-image --image-id $ami
                echo "    Deregistered AMI: $ami"
            fi
        done
        
        if [ "$TASK" != "all" ]; then break; fi
        ;&
        
    "all"|"snapshots")
        echo "📸 Managing EBS snapshots..."
        
        # Delete snapshots older than 30 days (except tagged for long-term retention)
        CUTOFF_DATE=$(date -d "30 days ago" +%Y-%m-%d)
        
        OLD_SNAPSHOTS=$(aws ec2 describe-snapshots \
            --owner-ids self \
            --query "Snapshots[?StartTime<='$CUTOFF_DATE' && !contains(Tags[?Key=='Retention'].Value, 'long-term')].SnapshotId" \
            --output text)
        
        for snapshot in $OLD_SNAPSHOTS; do
            if [ -n "$snapshot" ]; then
                aws ec2 delete-snapshot --snapshot-id $snapshot
                echo "  Deleted old snapshot: $snapshot"
            fi
        done
        
        if [ "$TASK" != "all" ]; then break; fi
        ;&
        
    "all"|"logs")
        echo "📋 Cleaning CloudWatch logs..."
        
        # Set appropriate retention for log groups without retention
        LOG_GROUPS=$(aws logs describe-log-groups \
            --query "logGroups[?!retentionInDays && contains(logGroupName, '$ENVIRONMENT')].logGroupName" \
            --output text)
        
        for log_group in $LOG_GROUPS; do
            if [ -n "$log_group" ]; then
                # Set retention based on environment
                case $ENVIRONMENT in
                    "prod") RETENTION=90 ;;
                    "staging") RETENTION=30 ;;
                    *) RETENTION=7 ;;
                esac
                
                aws logs put-retention-policy \
                    --log-group-name $log_group \
                    --retention-in-days $RETENTION
                
                echo "  Set retention for $log_group: $RETENTION days"
            fi
        done
        
        if [ "$TASK" != "all" ]; then break; fi
        ;&
        
    "all"|"security")
        echo "🔒 Security maintenance..."
        
        # Remove unused security groups
        echo "  Checking for unused security groups..."
        
        # Get all security groups
        ALL_SGS=$(aws ec2 describe-security-groups \
            --filters "Name=tag:Environment,Values=$ENVIRONMENT" \
            --query 'SecurityGroups[].GroupId' \
            --output text)
        
        # Get security groups in use
        USED_SGS=$(aws ec2 describe-network-interfaces \
            --query 'NetworkInterfaces[].Groups[].GroupId' \
            --output text | tr '\t' '\n' | sort -u)
        
        for sg in $ALL_SGS; do
            if [ -n "$sg" ] && ! echo "$USED_SGS" | grep -q "$sg"; then
                SG_NAME=$(aws ec2 describe-security-groups \
                    --group-ids $sg \
                    --query 'SecurityGroups[0].GroupName' \
                    --output text)
                
                # Don't delete default security groups
                if [ "$SG_NAME" != "default" ]; then
                    echo "    Unused security group found: $sg ($SG_NAME)"
                    # Uncomment to actually delete:
                    # aws ec2 delete-security-group --group-id $sg
                fi
            fi
        done
        ;;
        
    *)
        echo "❌ Unknown task: $TASK"
        echo "Available tasks: cleanup, snapshots, logs, security, all"
        exit 1
        ;;
esac

echo ""
echo "✅ Maintenance tasks completed"
```

### Monitoring Tools

**Health Check Dashboard:**
```bash
#!/bin/bash
# Real-time health dashboard

while true; do
    clear
    echo "🎛️  Infrastructure Health Dashboard"
    echo "=================================="
    echo "Last Updated: $(date)"
    echo ""
    
    # Environment status
    for ENV in dev staging prod; do
        echo "🏗️  Environment: $ENV"
        echo "-------------------"
        
        # Quick health check
        VPC_STATUS="❌"
        ALB_STATUS="❌"
        DB_STATUS="❌"
        APP_STATUS="❌"
        
        # VPC Check
        VPC_ID=$(aws ec2 describe-vpcs \
            --filters "Name=tag:Environment,Values=$ENV" \
            --query 'Vpcs[0].VpcId' \
            --output text 2>/dev/null)
        [ "$VPC_ID" != "None" ] && VPC_STATUS="✅"
        
        # ALB Check
        ALB_STATE=$(aws elbv2 describe-load-balancers \
            --query "LoadBalancers[?contains(LoadBalancerName, '$ENV')].State.Code" \
            --output text 2>/dev/null)
        [ "$ALB_STATE" = "active" ] && ALB_STATUS="✅"
        
        # Database Check
        DB_STATE=$(aws rds describe-db-instances \
            --query "DBInstances[?contains(DBInstanceIdentifier, '$ENV')].DBInstanceStatus" \
            --output text 2>/dev/null)
        [ "$DB_STATE" = "available" ] && DB_STATUS="✅"
        
        # Application Check
        if [ "$ALB_STATUS" = "✅" ]; then
            ALB_DNS=$(aws elbv2 describe-load-balancers \
                --query "LoadBalancers[?contains(LoadBalancerName, '$ENV')].DNSName" \
                --output text 2>/dev/null)
            
            HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "http://$ALB_DNS/health" 2>/dev/null || echo "000")
            [ "$HTTP_CODE" = "200" ] && APP_STATUS="✅"
        fi
        
        echo "VPC: $VPC_STATUS  ALB: $ALB_STATUS  DB: $DB_STATUS  APP: $APP_STATUS"
        echo ""
    done
    
    # Recent alarms
    echo "🚨 Recent Alarms (Last 1 hour):"
    echo "-------------------------------"
    
    RECENT_ALARMS=$(aws cloudwatch describe-alarm-history \
        --start-date $(date -d "1 hour ago" -u +%Y-%m-%dT%H:%M:%S) \
        --query 'AlarmHistoryItems[?HistoryItemType==`StateUpdate`].[AlarmName,NewValue,Timestamp]' \
        --output text 2>/dev/null)
    
    if [ -n "$RECENT_ALARMS" ]; then
        echo "$RECENT_ALARMS" | while read -r alarm_name state timestamp; do
            if [ "$state" = "ALARM" ]; then
                echo "🔥 $alarm_name: $state ($timestamp)"
            else
                echo "✅ $alarm_name: $state ($timestamp)"
            fi
        done
    else
        echo "No recent alarm state changes"
    fi
    
    echo ""
    echo "Press Ctrl+C to exit, refreshing in 30 seconds..."
    sleep 30
done
```

---

**Related Documentation**:
- [CI/CD Guide](CICD.md) - Automated deployment and testing
- [Deployment Guide](DEPLOYMENT.md) - Infrastructure deployment procedures
- [Security Guide](SECURITY.md) - Security operations and monitoring
- [Architecture Guide](architecture/overview.md) - Infrastructure architecture