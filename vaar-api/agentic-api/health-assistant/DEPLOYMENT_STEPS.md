# Deployment Guide - Step by Step

## 🚀 Complete Deployment Process

### **Step 1: Create Infrastructure (Without Lambda)**

First, we need to create ECR repository and S3 bucket:

```powershell
cd deploy\terraform

# Set your OpenAI API key
$env:TF_VAR_openai_api_key = "sk-your-actual-key"

# Target only the resources needed first
terraform apply -target=aws_ecr_repository.lambda_repo -target=aws_s3_bucket.vector_store -target=aws_iam_role.lambda_role
```

This creates:

- ✅ ECR repository (to push Docker image)
- ✅ S3 bucket (to upload vector store)
- ✅ IAM role (for Lambda permissions)

---

### **Step 2: Upload Vector Store to S3**

```powershell
cd ..\..  # Back to project root

# Run ingestion WITHOUT --skip-upload flag
python ingestion\ingest_docs.py
```

This will:

- Process PDFs from `health-doc/`
- Create embeddings
- Upload to S3 bucket: `vaardesigns-health-assistant`

---

### **Step 3: Build and Push Docker Image**

```powershell
# Get ECR repository URL
cd deploy\terraform
$ECR_REPO = terraform output -raw ecr_repository_url
cd ..\..

# Login to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $ECR_REPO

# Build Docker image
docker build -t vaardesigns-health-assistant:latest .

# Tag image for ECR
docker tag vaardesigns-health-assistant:latest ${ECR_REPO}:latest

# Push to ECR
docker push ${ECR_REPO}:latest
```

---

### **Step 4: Create Remaining Infrastructure**

Now create Lambda and API Gateway:

```powershell
cd deploy\terraform

# Apply all remaining resources
terraform apply
```

This creates:

- ✅ Lambda function (using the Docker image you just pushed)
- ✅ API Gateway
- ✅ CloudWatch logs
- ✅ All integrations

---

### **Step 5: Test the API**

```powershell
# Get API Gateway URL
$API_URL = terraform output -raw api_endpoint

# Test health endpoint
Invoke-RestMethod -Uri "$API_URL/health"

# Test query
$body = @{
    question = "What does Medicare Part A cover?"
} | ConvertTo-Json

Invoke-RestMethod -Uri "$API_URL/query" -Method Post -Body $body -ContentType "application/json"
```

---

## 📋 **Quick Command Reference**

### All-in-One Deployment (After first time):

```powershell
# 1. Set API key
$env:TF_VAR_openai_api_key = "sk-your-key"

# 2. Deploy infrastructure
cd deploy\terraform
terraform apply

# 3. Build and push image (if code changed)
cd ..\..
$ECR_REPO = terraform output -raw ecr_repository_url
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $ECR_REPO
docker build -t vaardesigns-health-assistant:latest .
docker tag vaardesigns-health-assistant:latest ${ECR_REPO}:latest
docker push ${ECR_REPO}:latest

# 4. Update Lambda
aws lambda update-function-code --function-name vaardesigns-health-assistant-prod --image-uri ${ECR_REPO}:latest
```

---

## 🐛 **Troubleshooting**

### Error: "Source image does not exist"

**Solution:** You need to push Docker image first (Step 3)

### Error: "No such image"

**Solution:** Build the Docker image: `docker build -t vaardesigns-health-assistant:latest .`

### Error: "Access denied to ECR"

**Solution:** Login to ECR first with `aws ecr get-login-password`

### Error: "Vector store not loaded"

**Solution:** Upload vector store: `python ingestion\ingest_docs.py`

---

## ✅ **Current Status Check**

Run these to see what's created:

```powershell
# Check ECR repository
aws ecr describe-repositories --repository-names vaardesigns-health-assistant-prod

# Check S3 bucket
aws s3 ls vaardesigns-health-assistant

# Check Lambda function
aws lambda get-function --function-name vaardesigns-health-assistant-prod

# Check API Gateway
aws apigatewayv2 get-apis --query 'Items[?Name==`vaardesigns-health-assistant-prod-api`]'
```
