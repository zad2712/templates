# 🚀 CI/CD Pipeline Documentation

[![GitHub Actions](https://img.shields.io/badge/GitHub-Actions-blue.svg)](https://github.com/features/actions)
[![Azure DevOps](https://img.shields.io/badge/Azure-DevOps-blue.svg)](https://azure.microsoft.com/services/devops/)
[![Terraform](https://img.shields.io/badge/Terraform-≥1.9.0-blue.svg)](https://terraform.io)

**Author**: Diego A. Zarate

This document provides comprehensive CI/CD pipeline configurations for deploying Azure infrastructure using Terraform. It includes examples for GitHub Actions, Azure DevOps, and best practices for production deployments.

## 🎯 **Pipeline Strategy**

### **Deployment Philosophy**
- **🔄 GitOps**: Infrastructure as Code with Git-based workflows
- **🔒 Security**: Zero-trust security model with least privilege access
- **🧪 Testing**: Comprehensive validation and testing at each stage
- **📊 Observability**: Full visibility into deployment processes
- **🌊 Progressive**: Blue-green and canary deployment strategies

### **Branch Strategy**
```
main (production)     ← Protected, auto-deploy to prod
├── develop           ← Integration branch, auto-deploy to staging  
├── feature/*         ← Feature branches, deploy to dev environments
└── hotfix/*          ← Emergency fixes, fast-track to production
```

### **Environment Promotion Flow**
```
Pull Request → Dev Environment → Staging → Production
     ↓              ↓              ↓           ↓
  Validation     Integration    UAT Tests   Deployment
```

## 🔧 **GitHub Actions Pipelines**

### **Complete Production Pipeline**

```yaml
# .github/workflows/terraform-deploy.yml
name: 🚀 Terraform Infrastructure Deployment

on:
  push:
    branches: [main, develop]
    paths: 
      - 'layers/**'
      - 'modules/**'
      - '*.tf'
      - '*.tfvars'
  pull_request:
    branches: [main, develop]
    paths:
      - 'layers/**'
      - 'modules/**'
      - '*.tf'
      - '*.tfvars'
  workflow_dispatch:
    inputs:
      environment:
        description: 'Environment to deploy'
        required: true
        default: 'dev'
        type: choice
        options: ['dev', 'qa', 'uat', 'prod']
      layer:
        description: 'Layer to deploy (all for complete deployment)'
        required: true
        default: 'all'
        type: choice
        options: ['all', 'networking', 'security', 'data', 'compute']
      action:
        description: 'Action to perform'
        required: true
        default: 'plan'
        type: choice
        options: ['plan', 'apply', 'destroy']

env:
  TF_VERSION: '1.9.0'
  TERRAFORM_DOCS_VERSION: '0.16.0'
  TFSEC_VERSION: 'v1.28.0'
  CHECKOV_VERSION: '2.5.0'
  ARM_USE_MSI: false

jobs:
  # Environment setup and validation
  setup:
    name: 🔧 Setup and Validation
    runs-on: ubuntu-latest
    outputs:
      environment: ${{ steps.env-setup.outputs.environment }}
      changed-layers: ${{ steps.changes.outputs.layers }}
      should-deploy: ${{ steps.env-setup.outputs.should-deploy }}
    
    steps:
    - name: 📥 Checkout Repository
      uses: actions/checkout@v4
      with:
        fetch-depth: 0  # Full history for proper diff
    
    - name: 🎯 Determine Environment
      id: env-setup
      run: |
        if [[ "${{ github.event_name }}" == "workflow_dispatch" ]]; then
          echo "environment=${{ github.event.inputs.environment }}" >> $GITHUB_OUTPUT
          echo "should-deploy=true" >> $GITHUB_OUTPUT
        elif [[ "${{ github.ref }}" == "refs/heads/main" ]]; then
          echo "environment=prod" >> $GITHUB_OUTPUT
          echo "should-deploy=true" >> $GITHUB_OUTPUT
        elif [[ "${{ github.ref }}" == "refs/heads/develop" ]]; then
          echo "environment=uat" >> $GITHUB_OUTPUT
          echo "should-deploy=true" >> $GITHUB_OUTPUT
        elif [[ "${{ github.event_name }}" == "pull_request" ]]; then
          echo "environment=dev" >> $GITHUB_OUTPUT
          echo "should-deploy=false" >> $GITHUB_OUTPUT
        else
          echo "environment=dev" >> $GITHUB_OUTPUT
          echo "should-deploy=false" >> $GITHUB_OUTPUT
        fi
    
    - name: 📂 Detect Changed Layers
      id: changes
      uses: dorny/paths-filter@v2
      with:
        filters: |
          networking:
            - 'layers/networking/**'
            - 'modules/vpc/**'
            - 'modules/security-groups/**'
          security:
            - 'layers/security/**'
            - 'modules/kms/**'
            - 'modules/iam/**'
          data:
            - 'layers/data/**'
            - 'modules/rds/**'
            - 'modules/s3/**'
            - 'modules/dynamodb/**'
          compute:
            - 'layers/compute/**'
            - 'modules/eks/**'
            - 'modules/lambda/**'
          global:
            - 'modules/**'
            - 'global/**'
        list-files: json
        base: ${{ github.event.repository.default_branch }}

  # Security scanning and validation
  security-scan:
    name: 🔒 Security Scanning
    runs-on: ubuntu-latest
    needs: setup
    
    steps:
    - name: 📥 Checkout Repository
      uses: actions/checkout@v4
    
    - name: 🔍 Run TFSec Security Scan
      uses: aquasecurity/tfsec-action@v1.0.3
      with:
        version: ${{ env.TFSEC_VERSION }}
        soft_fail: false
        format: sarif
        output_file: tfsec-results.sarif
    
    - name: 📊 Upload TFSec Results
      uses: github/codeql-action/upload-sarif@v2
      if: always()
      with:
        sarif_file: tfsec-results.sarif
    
    - name: 🛡️ Run Checkov Security Scan
      uses: bridgecrewio/checkov-action@master
      with:
        version: ${{ env.CHECKOV_VERSION }}
        directory: .
        framework: terraform
        output_format: sarif
        output_file_path: checkov-results.sarif
        quiet: true
        soft_fail: true
    
    - name: 📊 Upload Checkov Results  
      uses: github/codeql-action/upload-sarif@v2
      if: always()
      with:
        sarif_file: checkov-results.sarif

  # Terraform validation and documentation
  terraform-validate:
    name: ✅ Terraform Validation
    runs-on: ubuntu-latest
    needs: setup
    
    strategy:
      matrix:
        layer: [networking, security, data, compute]
    
    steps:
    - name: 📥 Checkout Repository
      uses: actions/checkout@v4
    
    - name: 🔧 Setup Terraform
      uses: hashicorp/setup-terraform@v3
      with:
        terraform_version: ${{ env.TF_VERSION }}
    
    - name: 🎨 Terraform Format Check
      run: |
        terraform fmt -check -recursive -diff
        if [ $? -ne 0 ]; then
          echo "❌ Terraform files are not properly formatted"
          echo "Run 'terraform fmt -recursive' to fix formatting issues"
          exit 1
        fi
    
    - name: ✅ Terraform Validation
      run: |
        cd layers/${{ matrix.layer }}
        terraform init -backend=false
        terraform validate
    
    - name: 📚 Generate Documentation
      uses: terraform-docs/gh-actions@v1.0.0
      with:
        working-dir: layers/${{ matrix.layer }}
        output-file: README.md
        output-method: inject
        git-push: false
    
    - name: 📈 Terraform Cost Estimation
      if: github.event_name == 'pull_request'
      uses: infracost/infracost-gh-action@master
      env:
        INFRACOST_API_KEY: ${{ secrets.INFRACOST_API_KEY }}
      with:
        path: layers/${{ matrix.layer }}
        terraform_plan_flags: -var-file=environments/${{ needs.setup.outputs.environment }}/terraform.auto.tfvars

  # Terraform planning stage
  terraform-plan:
    name: 📋 Terraform Plan
    runs-on: ubuntu-latest
    needs: [setup, security-scan, terraform-validate]
    if: always() && needs.setup.outputs.should-deploy == 'true'
    
    environment: ${{ needs.setup.outputs.environment }}
    
    strategy:
      matrix:
        layer: [networking, security, data, compute]
      max-parallel: 1  # Ensure sequential deployment
    
    outputs:
      networking-changes: ${{ steps.plan.outputs.networking-changes }}
      security-changes: ${{ steps.plan.outputs.security-changes }}
      data-changes: ${{ steps.plan.outputs.data-changes }}
      compute-changes: ${{ steps.plan.outputs.compute-changes }}
    
    steps:
    - name: 📥 Checkout Repository
      uses: actions/checkout@v4
    
    - name: 🔧 Setup Terraform
      uses: hashicorp/setup-terraform@v3
      with:
        terraform_version: ${{ env.TF_VERSION }}
        terraform_wrapper: false
    
    - name: 🔐 Azure Login
      uses: azure/login@v1
      with:
        creds: ${{ secrets.AZURE_CREDENTIALS }}
    
    - name: 🚀 Terraform Plan
      id: plan
      working-directory: layers/${{ matrix.layer }}/environments/${{ needs.setup.outputs.environment }}
      env:
        ARM_CLIENT_ID: ${{ secrets.ARM_CLIENT_ID }}
        ARM_CLIENT_SECRET: ${{ secrets.ARM_CLIENT_SECRET }}
        ARM_SUBSCRIPTION_ID: ${{ secrets.ARM_SUBSCRIPTION_ID }}
        ARM_TENANT_ID: ${{ secrets.ARM_TENANT_ID }}
      run: |
        # Initialize Terraform
        terraform init -backend-config=backend.conf
        
        # Create plan
        terraform plan \
          -var-file=terraform.auto.tfvars \
          -out=tfplan \
          -detailed-exitcode
        
        # Store exit code
        PLAN_EXIT_CODE=$?
        echo "${PLAN_EXIT_CODE}" > plan_exit_code
        
        # Generate human-readable plan
        terraform show -no-color tfplan > ../../../plan-${{ matrix.layer }}-${{ needs.setup.outputs.environment }}.txt
        
        # Set output for changes detection
        if [ ${PLAN_EXIT_CODE} -eq 2 ]; then
          echo "${{ matrix.layer }}-changes=true" >> $GITHUB_OUTPUT
        else
          echo "${{ matrix.layer }}-changes=false" >> $GITHUB_OUTPUT
        fi
    
    - name: 📊 Upload Plan Artifacts
      uses: actions/upload-artifact@v3
      with:
        name: terraform-plan-${{ matrix.layer }}-${{ needs.setup.outputs.environment }}
        path: |
          layers/${{ matrix.layer }}/environments/${{ needs.setup.outputs.environment }}/tfplan
          plan-${{ matrix.layer }}-${{ needs.setup.outputs.environment }}.txt
        retention-days: 30
    
    - name: 💬 Comment Plan on PR
      if: github.event_name == 'pull_request'
      uses: actions/github-script@v6
      with:
        script: |
          const fs = require('fs');
          const plan = fs.readFileSync('plan-${{ matrix.layer }}-${{ needs.setup.outputs.environment }}.txt', 'utf8');
          const maxLength = 65536; // GitHub comment limit
          const truncatedPlan = plan.length > maxLength ? 
            plan.substring(0, maxLength) + '\n\n... (truncated)' : plan;
          
          const output = `## 🏗️ Terraform Plan - ${{ matrix.layer }} (${{ needs.setup.outputs.environment }})
          
          <details>
          <summary>Show Plan</summary>
          
          \`\`\`hcl
          ${truncatedPlan}
          \`\`\`
          
          </details>
          
          **Environment**: ${{ needs.setup.outputs.environment }}  
          **Layer**: ${{ matrix.layer }}  
          **Changes**: ${{ steps.plan.outputs[matrix.layer + '-changes'] }}`;
          
          github.rest.issues.createComment({
            issue_number: context.issue.number,
            owner: context.repo.owner,
            repo: context.repo.repo,
            body: output
          });

  # Approval gate for production
  approval:
    name: 🔐 Production Approval
    runs-on: ubuntu-latest
    needs: [setup, terraform-plan]
    if: needs.setup.outputs.environment == 'prod' && github.ref == 'refs/heads/main'
    environment: 
      name: production-approval
      url: https://github.com/${{ github.repository }}/actions/runs/${{ github.run_id }}
    
    steps:
    - name: ⏳ Wait for Approval
      run: |
        echo "🔐 Production deployment requires manual approval"
        echo "Environment: ${{ needs.setup.outputs.environment }}"
        echo "Review the Terraform plans before approving this deployment"

  # Terraform apply stage
  terraform-apply:
    name: 🚀 Terraform Apply
    runs-on: ubuntu-latest
    needs: [setup, terraform-plan, approval]
    if: |
      always() && 
      needs.setup.outputs.should-deploy == 'true' &&
      (needs.setup.outputs.environment != 'prod' || needs.approval.result == 'success') &&
      (github.event.inputs.action != 'destroy')
    
    environment: ${{ needs.setup.outputs.environment }}
    
    strategy:
      matrix:
        layer: [networking, security, data, compute]
      max-parallel: 1  # Sequential deployment for dependencies
    
    steps:
    - name: 📥 Checkout Repository  
      uses: actions/checkout@v4
    
    - name: 🔧 Setup Terraform
      uses: hashicorp/setup-terraform@v3
      with:
        terraform_version: ${{ env.TF_VERSION }}
        terraform_wrapper: false
    
    - name: 📥 Download Plan Artifacts
      uses: actions/download-artifact@v3
      with:
        name: terraform-plan-${{ matrix.layer }}-${{ needs.setup.outputs.environment }}
        path: layers/${{ matrix.layer }}/environments/${{ needs.setup.outputs.environment }}/
    
    - name: 🔐 Azure Login
      uses: azure/login@v1
      with:
        creds: ${{ secrets.AZURE_CREDENTIALS }}
    
    - name: 🚀 Terraform Apply
      working-directory: layers/${{ matrix.layer }}/environments/${{ needs.setup.outputs.environment }}
      env:
        ARM_CLIENT_ID: ${{ secrets.ARM_CLIENT_ID }}
        ARM_CLIENT_SECRET: ${{ secrets.ARM_CLIENT_SECRET }}
        ARM_SUBSCRIPTION_ID: ${{ secrets.ARM_SUBSCRIPTION_ID }}
        ARM_TENANT_ID: ${{ secrets.ARM_TENANT_ID }}
      run: |
        # Re-initialize to ensure backend is connected
        terraform init -backend-config=backend.conf
        
        # Apply the plan
        terraform apply -auto-approve tfplan
        
        # Generate outputs
        terraform output -json > ../../../outputs-${{ matrix.layer }}-${{ needs.setup.outputs.environment }}.json
    
    - name: 📊 Upload Apply Outputs
      uses: actions/upload-artifact@v3
      with:
        name: terraform-outputs-${{ matrix.layer }}-${{ needs.setup.outputs.environment }}
        path: outputs-${{ matrix.layer }}-${{ needs.setup.outputs.environment }}.json
        retention-days: 90

  # Post-deployment testing
  integration-tests:
    name: 🧪 Integration Tests
    runs-on: ubuntu-latest
    needs: [setup, terraform-apply]
    if: always() && needs.terraform-apply.result == 'success'
    
    steps:
    - name: 📥 Checkout Repository
      uses: actions/checkout@v4
    
    - name: 📥 Download Outputs
      uses: actions/download-artifact@v3
      with:
        pattern: terraform-outputs-*-${{ needs.setup.outputs.environment }}
        merge-multiple: true
    
    - name: 🔐 Azure Login
      uses: azure/login@v1
      with:
        creds: ${{ secrets.AZURE_CREDENTIALS }}
    
    - name: 🧪 Run Infrastructure Tests
      run: |
        # Test network connectivity
        echo "🌐 Testing network connectivity..."
        
        # Test AKS cluster health
        if [ -f "outputs-compute-${{ needs.setup.outputs.environment }}.json" ]; then
          echo "☸️ Testing AKS cluster..."
          CLUSTER_NAME=$(jq -r '.aks_cluster_name.value' outputs-compute-${{ needs.setup.outputs.environment }}.json)
          RESOURCE_GROUP=$(jq -r '.aks_resource_group.value' outputs-compute-${{ needs.setup.outputs.environment }}.json)
          
          # Get AKS credentials
          az aks get-credentials --name $CLUSTER_NAME --resource-group $RESOURCE_GROUP --overwrite-existing
          
          # Test cluster connectivity
          kubectl cluster-info
          kubectl get nodes
          kubectl get pods -A
        fi
        
        # Test database connectivity
        if [ -f "outputs-data-${{ needs.setup.outputs.environment }}.json" ]; then
          echo "🗄️ Testing database connectivity..."
          # Add database connectivity tests here
        fi
    
    - name: 📈 Performance Tests
      run: |
        echo "📈 Running performance tests..."
        # Add performance testing logic here
    
    - name: 🔒 Security Compliance Tests
      run: |
        echo "🔒 Running security compliance tests..."
        # Add security compliance validation here

  # Notification and reporting
  notify:
    name: 📢 Notification
    runs-on: ubuntu-latest
    needs: [setup, terraform-apply, integration-tests]
    if: always()
    
    steps:
    - name: 📢 Slack Notification - Success
      if: needs.terraform-apply.result == 'success' && needs.integration-tests.result == 'success'
      uses: 8398a7/action-slack@v3
      with:
        status: success
        channel: '#infrastructure'
        fields: repo,message,commit,author,action,eventName,ref,workflow
        text: |
          ✅ **Infrastructure Deployment Successful**
          
          **Environment**: ${{ needs.setup.outputs.environment }}
          **Commit**: ${{ github.sha }}
          **Author**: ${{ github.actor }}
          **Workflow**: ${{ github.workflow }}
      env:
        SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK_URL }}
    
    - name: 📢 Slack Notification - Failure
      if: needs.terraform-apply.result == 'failure' || needs.integration-tests.result == 'failure'
      uses: 8398a7/action-slack@v3
      with:
        status: failure
        channel: '#infrastructure-alerts'
        fields: repo,message,commit,author,action,eventName,ref,workflow
        text: |
          ❌ **Infrastructure Deployment Failed**
          
          **Environment**: ${{ needs.setup.outputs.environment }}
          **Commit**: ${{ github.sha }}
          **Author**: ${{ github.actor }}
          **Workflow**: ${{ github.workflow }}
          
          Please check the workflow logs: https://github.com/${{ github.repository }}/actions/runs/${{ github.run_id }}
      env:
        SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK_URL }}
    
    - name: 📊 Teams Notification
      if: always()
      uses: skitionek/notify-microsoft-teams@master
      with:
        webhook_url: ${{ secrets.TEAMS_WEBHOOK_URL }}
        overwrite: |
          {
            "themeColor": "${{ needs.terraform-apply.result == 'success' && needs.integration-tests.result == 'success' && '00FF00' || 'FF0000' }}",
            "summary": "Infrastructure Deployment ${{ needs.terraform-apply.result == 'success' && needs.integration-tests.result == 'success' && 'Successful' || 'Failed' }}",
            "sections": [{
              "activityTitle": "Terraform Deployment",
              "activitySubtitle": "${{ needs.setup.outputs.environment }} environment",
              "facts": [{
                "name": "Environment",
                "value": "${{ needs.setup.outputs.environment }}"
              }, {
                "name": "Status",
                "value": "${{ needs.terraform-apply.result == 'success' && needs.integration-tests.result == 'success' && '✅ Success' || '❌ Failed' }}"
              }, {
                "name": "Commit",
                "value": "${{ github.sha }}"
              }, {
                "name": "Author",
                "value": "${{ github.actor }}"
              }],
              "markdown": true
            }],
            "potentialAction": [{
              "@type": "OpenUri",
              "name": "View Workflow",
              "targets": [{
                "os": "default",
                "uri": "https://github.com/${{ github.repository }}/actions/runs/${{ github.run_id }}"
              }]
            }]
          }
```

### **Feature Branch Pipeline**

```yaml
# .github/workflows/feature-validation.yml
name: 🔍 Feature Branch Validation

on:
  pull_request:
    branches: [main, develop]
    types: [opened, synchronize, reopened]

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

jobs:
  validate:
    name: 🔍 Validate Changes
    runs-on: ubuntu-latest
    
    steps:
    - name: 📥 Checkout Repository
      uses: actions/checkout@v4
      with:
        fetch-depth: 0
    
    - name: 🔧 Setup Terraform
      uses: hashicorp/setup-terraform@v3
      with:
        terraform_version: 1.9.0
    
    - name: 📂 Detect Changed Files
      id: changes
      run: |
        # Get list of changed Terraform files
        CHANGED_FILES=$(git diff --name-only origin/${{ github.base_ref }}...HEAD | grep -E '\.(tf|tfvars)$' || true)
        echo "Changed Terraform files:"
        echo "$CHANGED_FILES"
        
        # Determine affected layers
        AFFECTED_LAYERS=""
        if echo "$CHANGED_FILES" | grep -q "layers/networking\|modules/vpc"; then
          AFFECTED_LAYERS="$AFFECTED_LAYERS networking"
        fi
        if echo "$CHANGED_FILES" | grep -q "layers/security\|modules/kms\|modules/iam"; then
          AFFECTED_LAYERS="$AFFECTED_LAYERS security"
        fi
        if echo "$CHANGED_FILES" | grep -q "layers/data\|modules/rds\|modules/s3"; then
          AFFECTED_LAYERS="$AFFECTED_LAYERS data"
        fi
        if echo "$CHANGED_FILES" | grep -q "layers/compute\|modules/eks\|modules/lambda"; then
          AFFECTED_LAYERS="$AFFECTED_LAYERS compute"
        fi
        
        echo "affected-layers=$AFFECTED_LAYERS" >> $GITHUB_OUTPUT
    
    - name: ✅ Validate Affected Layers
      env:
        AFFECTED_LAYERS: ${{ steps.changes.outputs.affected-layers }}
      run: |
        for layer in $AFFECTED_LAYERS; do
          echo "Validating layer: $layer"
          cd layers/$layer
          terraform init -backend=false
          terraform validate
          terraform fmt -check -diff
          cd ../..
        done
    
    - name: 💰 Cost Estimation
      if: steps.changes.outputs.affected-layers != ''
      uses: infracost/infracost-gh-action@master
      env:
        INFRACOST_API_KEY: ${{ secrets.INFRACOST_API_KEY }}
        AFFECTED_LAYERS: ${{ steps.changes.outputs.affected-layers }}
      with:
        path: |
          $(for layer in $AFFECTED_LAYERS; do echo "layers/$layer"; done)
        usage_file: infracost-usage.yml
```

## 🔵 **Azure DevOps Pipelines**

### **Multi-Stage Production Pipeline**

```yaml
# azure-pipelines.yml
trigger:
  branches:
    include:
    - main
    - develop
    - feature/*
  paths:
    include:
    - layers/**
    - modules/**
    - '*.tf'
    - '*.tfvars'

pr:
  branches:
    include:
    - main
    - develop
  paths:
    include:
    - layers/**
    - modules/**
    - '*.tf'
    - '*.tfvars'

variables:
- group: terraform-common
- name: terraformVersion
  value: '1.9.0'
- name: azureServiceConnection
  value: 'azure-terraform-sp'

stages:
- stage: Validate
  displayName: '🔍 Validate and Plan'
  jobs:
  - job: SecurityScan
    displayName: '🔒 Security Scanning'
    pool:
      vmImage: 'ubuntu-latest'
    
    steps:
    - task: TerraformInstaller@0
      displayName: '🔧 Install Terraform'
      inputs:
        terraformVersion: $(terraformVersion)
    
    - script: |
        # Install security scanning tools
        curl -L "$(curl -s https://api.github.com/repos/aquasecurity/tfsec/releases/latest | grep -o -E "https://.+?tfsec-linux-amd64" | head -n1)" > tfsec
        chmod +x tfsec
        sudo mv tfsec /usr/local/bin/
        
        # Run security scan
        tfsec . --format json --out tfsec-results.json
        tfsec . --format junit --out tfsec-results.xml
      displayName: '🔍 Run TFSec Security Scan'
      continueOnError: true
    
    - task: PublishTestResults@2
      displayName: '📊 Publish Security Scan Results'
      condition: always()
      inputs:
        testResultsFormat: 'JUnit'
        testResultsFiles: 'tfsec-results.xml'
        testRunTitle: 'TFSec Security Scan'
    
    - task: PublishBuildArtifacts@1
      displayName: '📦 Publish Security Results'
      inputs:
        pathToPublish: 'tfsec-results.json'
        artifactName: 'security-scan-results'

  - job: TerraformValidate
    displayName: '✅ Terraform Validation'
    pool:
      vmImage: 'ubuntu-latest'
    
    strategy:
      matrix:
        networking:
          layerName: 'networking'
        security:
          layerName: 'security'
        data:
          layerName: 'data'
        compute:
          layerName: 'compute'
    
    steps:
    - task: TerraformInstaller@0
      displayName: '🔧 Install Terraform'
      inputs:
        terraformVersion: $(terraformVersion)
    
    - script: |
        cd layers/$(layerName)
        terraform init -backend=false
        terraform validate
        terraform fmt -check -diff
      displayName: '✅ Validate $(layerName) Layer'
    
    - task: TerraformTaskV4@4
      displayName: '📋 Terraform Plan $(layerName)'
      condition: and(succeeded(), ne(variables['Build.Reason'], 'PullRequest'))
      inputs:
        provider: 'azurerm'
        command: 'plan'
        workingDirectory: 'layers/$(layerName)/environments/$(environment)'
        environmentServiceNameAzureRM: $(azureServiceConnection)
        commandOptions: |
          -var-file=terraform.auto.tfvars
          -out=tfplan-$(layerName)
    
    - task: PublishBuildArtifacts@1
      displayName: '📦 Publish Plan Artifacts'
      condition: and(succeeded(), ne(variables['Build.Reason'], 'PullRequest'))
      inputs:
        pathToPublish: 'layers/$(layerName)/environments/$(environment)/tfplan-$(layerName)'
        artifactName: 'terraform-plans'

- stage: DeployDev
  displayName: '🚀 Deploy to Development'
  dependsOn: Validate
  condition: and(succeeded(), eq(variables['Build.SourceBranch'], 'refs/heads/develop'))
  variables:
  - name: environment
    value: 'dev'
  
  jobs:
  - deployment: TerraformApplyDev
    displayName: '🚀 Apply Infrastructure - Dev'
    pool:
      vmImage: 'ubuntu-latest'
    environment: 'development'
    
    strategy:
      runOnce:
        deploy:
          steps:
          - template: templates/terraform-apply.yml
            parameters:
              environment: $(environment)
              layers: ['networking', 'security', 'data', 'compute']

- stage: DeployStaging
  displayName: '🚀 Deploy to Staging'
  dependsOn: DeployDev
  condition: and(succeeded(), eq(variables['Build.SourceBranch'], 'refs/heads/develop'))
  variables:
  - name: environment
    value: 'uat'
  
  jobs:
  - deployment: TerraformApplyStaging
    displayName: '🚀 Apply Infrastructure - Staging'
    pool:
      vmImage: 'ubuntu-latest'
    environment: 'staging'
    
    strategy:
      runOnce:
        deploy:
          steps:
          - template: templates/terraform-apply.yml
            parameters:
              environment: $(environment)
              layers: ['networking', 'security', 'data', 'compute']

- stage: DeployProduction
  displayName: '🚀 Deploy to Production'
  dependsOn: Validate
  condition: and(succeeded(), eq(variables['Build.SourceBranch'], 'refs/heads/main'))
  variables:
  - name: environment
    value: 'prod'
  
  jobs:
  - job: ManualApproval
    displayName: '⏳ Manual Approval Required'
    pool: server
    
    steps:
    - task: ManualValidation@0
      displayName: '🔐 Approve Production Deployment'
      inputs:
        notifyUsers: |
          platform-team@company.com
          devops-team@company.com
        instructions: |
          Please review the Terraform plan and approve the production deployment.
          
          Environment: Production
          Branch: $(Build.SourceBranch)
          Commit: $(Build.SourceVersion)
          
          Review the security scan results and validate all changes before approval.
        onTimeout: 'reject'
  
  - deployment: TerraformApplyProduction
    displayName: '🚀 Apply Infrastructure - Production'
    dependsOn: ManualApproval
    pool:
      vmImage: 'ubuntu-latest'
    environment: 'production'
    
    strategy:
      runOnce:
        deploy:
          steps:
          - template: templates/terraform-apply.yml
            parameters:
              environment: $(environment)
              layers: ['networking', 'security', 'data', 'compute']
          
          - task: AzureCLI@2
            displayName: '🧪 Run Post-Deployment Tests'
            inputs:
              azureSubscription: $(azureServiceConnection)
              scriptType: 'bash'
              scriptLocation: 'inlineScript'
              inlineScript: |
                echo "Running post-deployment validation tests..."
                
                # Test AKS cluster
                CLUSTER_NAME=$(terraform output -raw aks_cluster_name)
                RESOURCE_GROUP=$(terraform output -raw aks_resource_group)
                
                az aks get-credentials --name $CLUSTER_NAME --resource-group $RESOURCE_GROUP --overwrite-existing
                kubectl cluster-info
                kubectl get nodes
                
                echo "✅ Post-deployment tests completed successfully"
              workingDirectory: 'layers/compute/environments/$(environment)'

- stage: Monitoring
  displayName: '📊 Post-Deployment Monitoring'
  dependsOn: 
  - DeployProduction
  - DeployStaging
  condition: always()
  
  jobs:
  - job: HealthChecks
    displayName: '🔍 Infrastructure Health Checks'
    pool:
      vmImage: 'ubuntu-latest'
    
    steps:
    - task: AzureCLI@2
      displayName: '🔍 Run Health Checks'
      inputs:
        azureSubscription: $(azureServiceConnection)
        scriptType: 'bash'
        scriptLocation: 'inlineScript'
        inlineScript: |
          # Add comprehensive health checks here
          echo "Running infrastructure health checks..."
          
          # Check resource group status
          az group list --query "[?name=='myapp-prod-*'].{Name:name, State:properties.provisioningState}" -o table
          
          # Check AKS cluster health
          az aks show --name myapp-prod-aks --resource-group myapp-prod-compute-rg --query "powerState.code" -o tsv
          
          # Check SQL database status
          az sql db list --server myapp-prod-sql --resource-group myapp-prod-data-rg --query "[].status" -o table
          
          echo "✅ Health checks completed"
```

### **Terraform Apply Template**

```yaml
# templates/terraform-apply.yml
parameters:
- name: environment
  type: string
- name: layers
  type: object

steps:
- ${{ each layer in parameters.layers }}:
  - task: TerraformInstaller@0
    displayName: '🔧 Install Terraform - ${{ layer }}'
    inputs:
      terraformVersion: $(terraformVersion)
  
  - task: DownloadBuildArtifacts@1
    displayName: '📥 Download Plan Artifacts - ${{ layer }}'
    inputs:
      buildType: 'current'
      downloadType: 'single'
      artifactName: 'terraform-plans'
      downloadPath: '$(System.ArtifactsDirectory)'
  
  - task: TerraformTaskV4@4
    displayName: '🚀 Terraform Apply - ${{ layer }}'
    inputs:
      provider: 'azurerm'
      command: 'apply'
      workingDirectory: 'layers/${{ layer }}/environments/${{ parameters.environment }}'
      environmentServiceNameAzureRM: $(azureServiceConnection)
      commandOptions: '$(System.ArtifactsDirectory)/terraform-plans/tfplan-${{ layer }}'
  
  - task: TerraformTaskV4@4
    displayName: '📊 Generate Outputs - ${{ layer }}'
    inputs:
      provider: 'azurerm'
      command: 'output'
      workingDirectory: 'layers/${{ layer }}/environments/${{ parameters.environment }}'
      environmentServiceNameAzureRM: $(azureServiceConnection)
      commandOptions: '-json > $(Build.ArtifactStagingDirectory)/outputs-${{ layer }}-${{ parameters.environment }}.json'
  
  - task: PublishBuildArtifacts@1
    displayName: '📦 Publish Outputs - ${{ layer }}'
    inputs:
      pathToPublish: '$(Build.ArtifactStagingDirectory)/outputs-${{ layer }}-${{ parameters.environment }}.json'
      artifactName: 'terraform-outputs'
```

## 🔧 **Pipeline Best Practices**

### **Security Best Practices**

#### **Secret Management**
```yaml
# Store sensitive values in Azure Key Vault or GitHub Secrets
- name: 🔐 Retrieve Secrets from Key Vault
  uses: Azure/get-keyvault-secrets@v1
  with:
    keyvault: "myapp-devops-kv"
    secrets: 'terraform-backend-key, sql-admin-password'
  id: secrets

# Use secrets in Terraform
- name: 🚀 Deploy with Secrets
  env:
    TF_VAR_sql_admin_password: ${{ steps.secrets.outputs.sql-admin-password }}
    ARM_ACCESS_KEY: ${{ steps.secrets.outputs.terraform-backend-key }}
  run: terraform apply -auto-approve
```

#### **State Backend Security**
```yaml
# Secure state backend configuration
- name: 🔒 Configure Secure Backend
  run: |
    cat > backend.conf << EOF
    storage_account_name  = "${{ secrets.TF_STATE_STORAGE_ACCOUNT }}"
    container_name        = "${{ secrets.TF_STATE_CONTAINER }}"
    key                   = "${{ matrix.layer }}/${{ env.ENVIRONMENT }}/terraform.tfstate"
    resource_group_name   = "${{ secrets.TF_STATE_RESOURCE_GROUP }}"
    subscription_id       = "${{ secrets.ARM_SUBSCRIPTION_ID }}"
    tenant_id            = "${{ secrets.ARM_TENANT_ID }}"
    client_id            = "${{ secrets.ARM_CLIENT_ID }}"
    client_secret        = "${{ secrets.ARM_CLIENT_SECRET }}"
    EOF
```

### **Performance Optimization**

#### **Parallel Execution**
```yaml
# Optimize for parallel layer deployment where possible
strategy:
  matrix:
    include:
    - layer: networking
      depends_on: []
    - layer: security  
      depends_on: [networking]
    - layer: data
      depends_on: [networking, security]
    - layer: compute
      depends_on: [networking, security, data]
  max-parallel: 2  # Adjust based on dependencies
```

#### **Caching Strategy**
```yaml
# Cache Terraform providers and modules
- name: 📦 Cache Terraform
  uses: actions/cache@v3
  with:
    path: |
      ~/.terraform.d/plugin-cache
      .terraform/providers
    key: ${{ runner.os }}-terraform-${{ hashFiles('**/.terraform.lock.hcl') }}
    restore-keys: |
      ${{ runner.os }}-terraform-
```

### **Error Handling and Recovery**

#### **Retry Logic**
```yaml
# Implement retry logic for transient failures
- name: 🔄 Terraform Apply with Retry
  uses: nick-invision/retry@v2
  with:
    timeout_minutes: 30
    max_attempts: 3
    retry_wait_seconds: 60
    command: |
      cd layers/${{ matrix.layer }}/environments/${{ env.ENVIRONMENT }}
      terraform apply -auto-approve tfplan
```

#### **Rollback Capability**
```yaml
# Implement automatic rollback on failure
- name: 🔄 Rollback on Failure
  if: failure() && env.ENVIRONMENT == 'prod'
  run: |
    echo "Deployment failed, initiating rollback..."
    
    # Get previous successful commit
    PREVIOUS_COMMIT=$(git log --format="%H" --skip=1 -n 1)
    
    # Checkout previous version
    git checkout $PREVIOUS_COMMIT
    
    # Apply previous configuration
    terraform apply -auto-approve
```

## 📊 **Monitoring and Alerting**

### **Pipeline Monitoring**

```yaml
# Monitor pipeline performance and send metrics
- name: 📊 Send Pipeline Metrics
  if: always()
  run: |
    # Calculate deployment time
    DURATION=$(($(date +%s) - ${{ env.START_TIME }}))
    
    # Send metrics to Azure Monitor
    az monitor metrics emit \
      --resource-group monitoring-rg \
      --resource-name pipeline-metrics \
      --resource-type Microsoft.Insights/components \
      --metrics '[
        {
          "name": "deployment.duration",
          "value": '$DURATION',
          "dimensions": {
            "environment": "${{ env.ENVIRONMENT }}",
            "layer": "${{ matrix.layer }}",
            "status": "${{ job.status }}"
          }
        }
      ]'
```

### **Alert Configuration**

```yaml
# Configure alerts for pipeline failures
- name: 🚨 Configure Pipeline Alerts
  uses: azure/CLI@v1
  with:
    inlineScript: |
      # Create action group for notifications
      az monitor action-group create \
        --resource-group monitoring-rg \
        --name pipeline-alerts \
        --short-name pipeline \
        --email-receivers name=devops email=devops-team@company.com \
        --sms-receivers name=oncall phone=+1234567890
      
      # Create alert rule for failed deployments
      az monitor scheduled-query create \
        --resource-group monitoring-rg \
        --name deployment-failures \
        --scopes /subscriptions/${{ secrets.ARM_SUBSCRIPTION_ID }} \
        --condition "count 'exceptions | where timestamp > ago(5m) and outerMessage contains \"deployment failed\"' > 0" \
        --description "Alert when deployment fails" \
        --evaluation-frequency 5m \
        --window-size 5m \
        --severity 1 \
        --action-groups pipeline-alerts
```

---

**📍 Navigation**: [🏠 Main README](README.md) | [🚀 Deployment Guide](DEPLOYMENT.md) | [📁 Layers Documentation](layers/README.md)