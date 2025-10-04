#!/bin/bash

# EKS Node Group User Data Script
# This script bootstraps EC2 instances to join the EKS cluster

/etc/eks/bootstrap.sh ${cluster_name} ${bootstrap_arguments}

# Additional customizations can be added here
echo "EKS node initialization completed"