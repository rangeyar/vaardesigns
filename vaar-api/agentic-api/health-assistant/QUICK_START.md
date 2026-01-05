# 🚀 Quick Start - Health Assistant API Deployment

## ✅ First Time Deployment (4 Simple Steps)

### Prerequisites
- GitHub repo with code pushed
- AWS credentials configured locally
- OpenAI API key

---

### Step 1: Add GitHub Secrets (One-Time Setup)

Go to: **GitHub repo → Settings → Secrets and variables → Actions**

Add these 3 secrets:
- `AWS_ACCESS_KEY_ID` - Your AWS access key
- `AWS_SECRET_ACCESS_KEY` - Your AWS secret key
- `OPENAI_API_KEY` - Your OpenAI key (sk-...)

---

### Step 2: Push Code to GitHub (GitHub Builds Docker for You!)

```powershell
# Make sure you're in the repository root
cd c:\Users\13124\Desktop\Skills\agentic-ai\main-website-vaar\test-terraform\vaardesigns

# Add all files
git add .

# Commit
git commit -m "feat: initial health assistant API deployment"

# Push to developer branch
git push origin developer
```

**What happens:**
- ✅ GitHub Actions workflow triggers
- ✅ Docker image gets built on GitHub's Ubuntu runner
- ✅ Image pushed to AWS ECR
- ❌ Lambda update will fail (Lambda doesn't exist yet - that's OK!)

**Check progress:** Go to GitHub → Actions tab → Watch "Deploy Health Assistant API" workflow

---

### Step 3: Deploy Infrastructure with Terraform

```powershell
# Navigate to terraform directory
cd vaar-api\agentic-api\health-assistant\deploy\terraform

# Set your OpenAI API key
$env:TF_VAR_openai_api_key = "sk-your-actual-openai-api-key"

# Initialize Terraform
terraform init

# Deploy everything
terraform apply
# Type 'yes' when prompted
```

**What gets created:**
- ✅ ECR repository (Docker registry)
- ✅ Lambda function (your API)
- ✅ API Gateway (public endpoint)
- ✅ S3 bucket (for vector store)
- ✅ IAM roles and policies
- ✅ CloudWatch logs

**This takes ~2-3 minutes**

---

### Step 4: Upload Vector Store to S3

```powershell
# Go back to health-assistant root
cd ..\..

# Run ingestion script (uploads to S3)
python ingestion\ingest_docs.py
```

**What happens:**
- ✅ Processes PDFs from health-doc/ folder
- ✅ Creates FAISS vector embeddings
- ✅ Uploads to S3 bucket

---

### Step 5: Test Your API! 🎉

```powershell
# Get your API endpoint
cd deploy\terraform
terraform output api_endpoint
```

**Test in browser:**
```
https://xxxxx.execute-api.us-east-1.amazonaws.com/health
```

**Test query with PowerShell:**
```powershell
$API_URL = (terraform output -raw api_endpoint)

# Health check
Invoke-RestMethod -Uri "$API_URL/health" -Method GET

# Query
$body = @{
    query = "What is Medicare Part A?"
} | ConvertTo-Json

Invoke-RestMethod -Uri "$API_URL/query" -Method POST -Body $body -ContentType "application/json"
```

---

## 🎯 After First Deployment = FULLY AUTOMATIC

### For Code Changes:
```powershell
# Edit your code (app/main.py, app/rag.py, etc.)
git add .
git commit -m "feat: improve RAG prompt"
git push origin developer
```
✅ **GitHub Actions automatically:**
- Builds Docker
- Pushes to ECR
- Updates Lambda
- Done!

### For Infrastructure Changes:
```powershell
# Edit Terraform files (deploy/terraform/*.tf)
git add .
git commit -m "infra: increase Lambda memory"
git push origin main
```
✅ **GitHub Actions automatically:**
- Builds Docker (Job 1)
- Applies Terraform changes (Job 2)
- Done!

---

## 📋 Troubleshooting

### "Lambda function not found" during GitHub Actions
**Solution:** This is expected on first push. Run terraform apply first, then future pushes will work.

### "Vector store not found" when querying API
**Solution:** Run the ingestion script to upload vector store to S3:
```powershell
python ingestion\ingest_docs.py
```

### GitHub Actions workflow not triggering
**Solution:** Workflows must be in root `.github/workflows/` folder:
- ✅ `vaardesigns/.github/workflows/deploy-health-assistant-api.yml`
- ✅ `vaardesigns/.github/workflows/terraform-deploy-health-assistant.yml`

### Docker build fails in GitHub Actions
**Solution:** Check that Dockerfile and requirements.txt are correct. View logs in GitHub Actions tab.

---

## 📁 File Locations

```
vaardesigns/  (repository root)
├── .github/
│   └── workflows/
│       ├── deploy-health-assistant-api.yml          # API deployment workflow
│       └── terraform-deploy-health-assistant.yml    # Infrastructure workflow
└── vaar-api/
    └── agentic-api/
        └── health-assistant/
            ├── app/                    # FastAPI application code
            ├── deploy/terraform/       # Infrastructure as Code
            ├── health-doc/            # PDF documents
            ├── ingestion/             # Document processing
            └── vector_store/          # Local FAISS index (not committed)
```

---

## 🎬 Complete Workflow Summary

| Step | What | How | Time |
|------|------|-----|------|
| 1 | Add secrets | GitHub UI | 2 min |
| 2 | Push code | `git push` | 1 min |
| 3 | Wait for Docker build | GitHub Actions | 3 min |
| 4 | Deploy infrastructure | `terraform apply` | 3 min |
| 5 | Upload vector store | `python ingestion/ingest_docs.py` | 2 min |
| 6 | Test API | Browser or curl | 1 min |

**Total first deployment: ~12 minutes**

**Future deployments: ~3 minutes (automatic!)**

---

## 🔑 Key Points

✅ **No Docker Desktop needed** - GitHub Actions has Docker pre-installed
✅ **Workflows at repo root** - `.github/workflows/` in vaardesigns folder
✅ **Manual steps only ONCE** - terraform apply and vector store upload
✅ **Everything else automatic** - Push to git = automatic deployment
✅ **Safe concurrent workflows** - Job dependencies prevent race conditions

---

## 🆘 Need Help?

Check these files in the project:
- `DEPLOYMENT_STRATEGY.md` - Detailed explanation of CI/CD workflow
- `CICD_SETUP.md` - Complete CI/CD setup guide
- `FIRST_DEPLOY_UPDATED.md` - Alternative deployment methods

**You're all set! 🚀**
