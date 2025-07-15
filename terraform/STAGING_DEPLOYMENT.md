# Staging System Setup

## Overview
The staging system has been added to the existing Terraform infrastructure with minimal changes. Both production and staging environments share:
- Same Azure Resource Group
- Same Azure Container Registry (ACR)
- Same App Service Plan (cost-effective)

## Resources Added
- **Staging App Service**: `git-proxy-staging-appservice`
- **ACR Role Assignment**: Grants staging app access to pull images
- **Output**: Staging app service principal ID

## Deployment Workflow

The GitHub Actions pipeline (`build-and-deploy.yml`) now implements automatic staging-to-production deployment:

### 1. Automatic Staging Deployment
When code is pushed to `main` branch:
- **Build & Push**: Docker image built with tag `github.run_id` and pushed to ACR
- **Deploy Staging**: Image automatically deployed to staging environment
- **Staging URL**: `https://git-proxy-staging-appservice.azurewebsites.net`

### 2. Manual Approval for Production  
After staging deployment succeeds:
- **Manual Approval Required**: Production deployment waits for approval
- **Deploy Production**: Same image tag deployed to production after approval
- **Production URL**: `https://git-proxy-appservice.azurewebsites.net`

### 3. Pipeline Jobs
```yaml
create-infrastructure → build-and-push → deploy-staging → [MANUAL APPROVAL] → deploy-production
```

## CI/CD Pipeline Details
The updated pipeline:
1. **Creates Infrastructure**: Shared resources (ACR, Service Plan, etc.)
2. **Builds and Pushes**: Docker image to shared ACR
3. **Deploys to Staging**: Using Terraform targets for staging resources only
4. **Deploys to Production**: Using Terraform targets for production resources only

Each deployment step uses the same Docker image tag (`github.run_id`) ensuring consistency.

## App Service URLs
- **Production**: `https://git-proxy-appservice.azurewebsites.net`
- **Staging**: `https://git-proxy-staging-appservice.azurewebsites.net`

## Setting Up Manual Approval

To enable the manual approval for production deployments, you need to configure a GitHub Environment:

### 1. Create Production Environment
1. Go to your GitHub repository → Settings → Environments
2. Click "New environment" and name it `production`
3. Configure protection rules:
   - ✅ **Required reviewers**: Add team members who can approve production deployments
   - ✅ **Wait timer**: Optional delay before deployment
   - ✅ **Deployment branches**: Restrict to `main` branch

### 2. How Approval Works
1. **Push to main** → Automatic staging deployment
2. **Production job waits** → GitHub sends notification to reviewers
3. **Reviewer approves** → Production deployment proceeds
4. **Deployment completes** → Production is updated

### 3. Approval Notifications
- Email notifications sent to required reviewers
- GitHub UI shows pending deployments
- Mobile notifications via GitHub app

## Benefits
- Zero risk to production (completely separate app service)
- Shared infrastructure reduces costs
- Same Terraform state (no additional complexity)
- Sequential deployment with manual approval gate
- Full audit trail of production deployments
