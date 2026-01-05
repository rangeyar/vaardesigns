# First Time Deployment Guide

For the first deployment, follow these steps to avoid Docker daemon issues with Terraform:

## Step 1: Start Docker Desktop

- Open Docker Desktop on Windows
- Wait until it shows "Docker Desktop is running"
- Verify: `docker ps` (should not error)

## Step 2: Create ECR Repository First

```powershell
cd deploy\terraform

# Set your OpenAI API key
$env:TF_VAR_openai_api_key = "sk-your-actual-key"

# Initialize Terraform
terraform init

# Create only the ECR repository first (to avoid Docker build during terraform apply)
terraform apply -target=aws_ecr_repository.lambda_repo
```

## Step 3: Build and Push Docker Image Manually

```powershell
# Get ECR repository URL from Terraform output
$ECR_REPO = (terraform output -raw ecr_repository_url)

# Build the Docker image (from health-assistant root directory)
cd ..\..
docker build -t vaardesigns-health-assistant-prod:latest .

# Login to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $ECR_REPO

# Tag the image
docker tag vaardesigns-health-assistant-prod:latest ${ECR_REPO}:latest

# Push to ECR
docker push ${ECR_REPO}:latest

# Go back to terraform directory
cd deploy\terraform
```

## Step 4: Deploy Rest of Infrastructure

```powershell
# Now deploy everything (Docker image is already in ECR)
terraform apply
```

## Alternative: Skip Docker Build in Terraform

If you prefer to always build Docker manually and skip the null_resource automation:

1. Comment out the null_resource in `docker_build.tf`
2. Remove `depends_on = [null_resource.build_and_push_image]` from Lambda function
3. Always build/push Docker manually before terraform apply

## For Subsequent Deployments

Once CI/CD is set up with GitHub Actions, you won't need to worry about this - GitHub's runners have Docker pre-installed and running.
