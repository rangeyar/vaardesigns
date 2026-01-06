# First Time Deployment Guide (Without Docker Desktop)

Since you're getting WSL errors with Docker Desktop, follow this manual approach for first deployment.

## Prerequisites

- AWS CLI configured with credentials
- Terraform installed
- Git repository ready

## Step-by-Step Deployment

### Step 1: Build Docker Image Using WSL/Linux or GitHub Actions

**Option A: Use GitHub Actions (RECOMMENDED - No local Docker needed!)**

1. Push your code to GitHub first:

```powershell
git add .
git commit -m "feat: initial health assistant API deployment"
git push origin developer
```

2. GitHub Actions will automatically:

   - Build Docker image (Ubuntu runner has Docker)
   - Push to ECR
   - Try to update Lambda (will fail first time since Lambda doesn't exist yet - that's OK!)

3. After GitHub Actions completes the Docker build, proceed to Step 2

**Option B: Use a Linux Machine or WSL2 (if available)**

If you have access to a Linux machine or working WSL2:

```bash
# From WSL2 or Linux machine
cd /path/to/health-assistant
docker build -t vaardesigns-health-assistant-prod:latest .

# Login to ECR (need to create repo first via Terraform)
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <ECR_REPO_URL>

# Push image
docker tag vaardesigns-health-assistant-prod:latest <ECR_REPO_URL>:latest
docker push <ECR_REPO_URL>:latest
```

### Step 2: Deploy Infrastructure with Terraform

```powershell
cd deploy\terraform

# Set your OpenAI API key
$env:TF_VAR_openai_api_key = "sk-your-actual-key"

# Initialize Terraform
terraform init

# First, create just the ECR repository
terraform apply -target=aws_ecr_repository.lambda_repo

# Get the ECR repository URL
$ECR_REPO = (terraform output -raw ecr_repository_url)
Write-Host "ECR Repository URL: $ECR_REPO"
```

### Step 3: Build and Push Image (Choose One Method)

**Method 1: GitHub Actions (EASIEST)**

- If you already pushed to GitHub in Step 1, the image is already in ECR
- Skip to Step 4

**Method 2: Manual Build via GitHub Actions**

- Go to your GitHub repo → Actions tab
- Click on "Deploy Health Assistant API" workflow
- Click "Run workflow" → Select "developer" branch → Run workflow
- Wait for it to complete (builds and pushes image)

**Method 3: Use another machine with Docker**

- Copy the Dockerfile and app code to a machine with Docker
- Build and push from there using the commands above

### Step 4: Deploy Everything Else

```powershell
# Now deploy all infrastructure
terraform apply

# Upload vector store to S3 (from your local machine - doesn't need Docker)
cd ..\..
python ingestion\ingest_docs.py  # Will upload to S3

# Get API endpoint
cd deploy\terraform
terraform output api_endpoint
```

### Step 5: Test Your API

```powershell
# Test health endpoint
$API_URL = (terraform output -raw api_endpoint)
Invoke-RestMethod -Uri "$API_URL/health" -Method GET

# Test query endpoint
$body = @{
    query = "What is Medicare Part A?"
} | ConvertTo-Json

Invoke-RestMethod -Uri "$API_URL/query" -Method POST -Body $body -ContentType "application/json"
```

## Understanding the CI/CD Flow

Once initial deployment is complete, this is how it works:

### For API Code Changes:

1. **You push to developer/main**
2. **GitHub Actions workflow `deploy.yml` triggers:**
   - Builds Docker image (on Ubuntu runner - Docker available!)
   - Pushes to ECR
   - Updates Lambda function with new image

### For Infrastructure Changes:

1. **You push Terraform changes to main**
2. **GitHub Actions workflow `terraform-deploy.yml` triggers:**
   - **Job 1:** Builds and pushes Docker image FIRST
   - **Job 2:** Runs terraform apply (waits for Job 1 to complete)
   - This ensures image exists before Lambda is created/updated

### Both workflows ensure proper ordering:

- Docker image is ALWAYS built before Lambda updates
- No race conditions or missing image errors
- Everything happens automatically in the cloud

## Troubleshooting

### "Image not found" error during terraform apply:

- Make sure you completed Step 3 (image pushed to ECR)
- Verify image exists:
  ```powershell
  aws ecr describe-images --repository-name vaardesigns-health-assistant-prod --region us-east-1
  ```

### GitHub Actions fails to update Lambda (first time):

- This is EXPECTED on first push - Lambda doesn't exist yet
- After running terraform apply, future pushes will work

### Vector store not loading:

- Run the ingestion script to upload to S3:
  ```powershell
  python ingestion\ingest_docs.py
  ```

## Summary

**First Time (Manual):**

1. Push to GitHub → GitHub Actions builds image
2. Run terraform apply → Creates infrastructure
3. Upload vector store → S3

**Every Time After (Automatic):**

1. Push code changes → GitHub Actions deploys automatically
2. Push Terraform changes → GitHub Actions builds image THEN deploys infrastructure
3. No manual steps needed!

The key insight: **GitHub Actions has Docker**, so you don't need Docker Desktop locally. Use GitHub's infrastructure for building images!
