#!/bin/bash

# ECS Instance User Data Script
# This script configures EC2 instances to join the ECS cluster

echo ECS_CLUSTER=${cluster_name} >> /etc/ecs/ecs.config

# Enable ECS container agent logs
echo ECS_ENABLE_CONTAINER_METADATA=true >> /etc/ecs/ecs.config

# Configure ECS logging
echo ECS_AVAILABLE_LOGGING_DRIVERS='["json-file","awslogs","syslog","none"]' >> /etc/ecs/ecs.config

# Start the ECS agent
start ecs

echo "ECS instance initialization completed"