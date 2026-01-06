# CI/CD Setup Guide

This guide explains how to set up automated deployments for the Health Assistant API using GitHub Actions.

## Overview

Two workflows are configured:

1. **`deploy.yml`** - Deploys API code changes (runs on `developer` and `main` branches)
2. **`terraform-deploy.yml`** - Deploys infrastructure changes (runs only on `main` branch)

## Prerequisites

1. Successfully deployed the infrastructure manually from your local machine
2. GitHub repository with the code pushed
3. AWS credentials with appropriate permissions

## Setup Instructions

### Step 1: Configure GitHub Secrets

Go to your GitHub repository → Settings → Secrets and variables → Actions → New repository secret

Add the following secrets:

1. **`AWS_ACCESS_KEY_ID`**

   - Your AWS access key ID
   - Should have permissions for: ECR, Lambda, API Gateway, S3, IAM

2. **`AWS_SECRET_ACCESS_KEY`**

   - Your AWS secret access key

3. **`OPENAI_API_KEY`**
   - Your OpenAI API key (e.g., `sk-...`)

### Step 2: Verify Workflow Files

The following workflow files should be in your repository:

```
.github/
  workflows/
    deploy.yml              # API code deployment
    terraform-deploy.yml    # Infrastructure deployment
```

### Step 3: Test the CI/CD Pipeline

#### Test API Code Deployment:

1. Make a small change to any file in `vaar-api/agentic-api/health-assistant/`
2. Commit and push to `developer` branch:
   ```powershell
   git add .
   git commit -m "test: trigger ci/cd deployment"
   git push origin developer
   ```
3. Go to GitHub → Actions tab
4. Watch the "Deploy Health Assistant API" workflow run
5. Verify the Lambda function is updated with the new image

#### Test Infrastructure Deployment:

1. Make a change to Terraform files in `deploy/terraform/`
2. Commit and push to `main` branch:
   ```powershell
   git add .
   git commit -m "infra: update terraform configuration"
   git push origin main
   ```
3. Go to GitHub → Actions tab
4. Watch the "Terraform Deploy" workflow run
5. Verify infrastructure changes are applied

## Workflow Details

### API Deployment Workflow (deploy.yml)

**Triggers:**

- Push to `developer` or `main` branch
- Only when files in `vaar-api/agentic-api/health-assistant/` change
- Manual trigger via GitHub UI

**Steps:**

1. Checkout code
2. Set up Python 3.11
3. Configure AWS credentials
4. Login to Amazon ECR
5. Build Docker image
6. Push image to ECR with commit SHA tag and `latest` tag
7. Update Lambda function with new image
8. Wait for Lambda update to complete
9. Update Lambda environment variables
10. Display deployment success message

**Environment Variables Updated:**

- `OPENAI_API_KEY` - From GitHub secrets
- `S3_BUCKET_NAME` - vaardesigns-health-assistant
- `ENVIRONMENT` - production

### Infrastructure Deployment Workflow (terraform-deploy.yml)

**Triggers:**

- Push to `main` branch only
- Only when files in `deploy/terraform/` change
- Manual trigger via GitHub UI

**Steps:**

1. Checkout code
2. Set up Terraform
3. Configure AWS credentials
4. Initialize Terraform
5. Validate Terraform configuration
6. Plan infrastructure changes
7. Apply changes automatically
8. Output Terraform results

## Development Workflow

### Normal Development Process:

1. **Local Development & Testing:**

   ```powershell
   # Make changes to code
   docker-compose up --build
   # Test locally at http://localhost:8000
   ```

2. **Commit to Developer Branch:**

   ```powershell
   git add .
   git commit -m "feat: add new feature"
   git push origin developer
   ```

   - CI/CD automatically deploys to AWS Lambda
   - Test the deployed API

3. **Merge to Main (Production):**
   ```powershell
   git checkout main
   git merge developer
   git push origin main
   ```
   - CI/CD automatically deploys to production

### Infrastructure Changes:

1. **Test Locally:**

   ```powershell
   cd deploy\terraform
   terraform plan
   ```

2. **Commit and Push to Main:**
   ```powershell
   git add deploy/terraform/
   git commit -m "infra: update lambda memory"
   git push origin main
   ```
   - Terraform workflow automatically applies changes

## Monitoring Deployments

### View GitHub Actions:

- Go to: https://github.com/rangeyar/vaardesigns/actions
- Click on workflow runs to see logs
- Check for errors or successful deployments

### View AWS Resources:

- **Lambda Logs:** CloudWatch → Log groups → `/aws/lambda/vaardesigns-health-assistant-prod`
- **ECR Images:** ECR → Repositories → `vaardesigns-health-assistant-prod`
- **API Gateway:** API Gateway → `vaardesigns-health-assistant-prod-api`

## Troubleshooting

### Deployment Fails with AWS Permissions Error:

- Verify AWS credentials in GitHub secrets
- Check IAM permissions for the AWS user/role
- Required permissions: ECR, Lambda, S3, API Gateway, CloudWatch

### Docker Build Fails:

- Check Dockerfile syntax
- Verify all dependencies in requirements.txt
- Check GitHub Actions logs for specific error

### Lambda Update Fails:

- Verify Lambda function name: `vaardesigns-health-assistant-prod`
- Check if function exists in AWS Console
- Verify ECR image was pushed successfully

### Terraform Apply Fails:

- Check Terraform state lock in DynamoDB
- Verify S3 backend bucket access
- Check Terraform syntax: `terraform validate`

## Manual Deployment (Fallback)

If CI/CD fails, you can always deploy manually:

```powershell
# From your local machine
cd deploy\terraform
$env:TF_VAR_openai_api_key = "your-key"
terraform apply

# Or just update Lambda with new Docker image
docker build -t health-assistant .
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin YOUR_ECR_URI
docker tag health-assistant:latest YOUR_ECR_URI/vaardesigns-health-assistant-prod:latest
docker push YOUR_ECR_URI/vaardesigns-health-assistant-prod:latest
aws lambda update-function-code --function-name vaardesigns-health-assistant-prod --image-uri YOUR_ECR_URI/vaardesigns-health-assistant-prod:latest
```

## Best Practices

1. **Always test locally first** before pushing to developer/main
2. **Use developer branch** for testing deployments
3. **Merge to main** only after testing on developer
4. **Monitor CloudWatch logs** after each deployment
5. **Keep secrets secure** - never commit API keys to git
6. **Review GitHub Actions logs** if deployment fails
7. **Use descriptive commit messages** to track changes

## Security Notes

- AWS credentials and API keys are stored as GitHub secrets (encrypted)
- Secrets are never exposed in logs or workflow files
- Only authorized repository members can modify workflows
- Consider using AWS IAM roles for GitHub Actions (OIDC) for better security

## Future Enhancements

- [ ] Add automated tests before deployment
- [ ] Implement blue/green deployments
- [ ] Add Slack/email notifications on deployment
- [ ] Set up staging environment
- [ ] Implement rollback mechanism
- [ ] Add API performance monitoring
