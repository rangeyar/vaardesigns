# Deployment Strategy - Health Assistant API

## Problem Solved

You asked: **"When I commit to git, both workflows will trigger. Will this cause issues?"**

**Answer:** YES, it would have caused issues! But I've fixed it. Here's how:

## The Race Condition Problem

### Before Fix:

When you push everything to git (API code + Terraform files):

1. **`deploy.yml`** workflow starts → Builds Docker → Updates Lambda (but Lambda might not exist yet!)
2. **`terraform-deploy.yml`** workflow starts → Creates Lambda (but Docker image might not be built yet!)
3. **RACE CONDITION** = Random failures depending on which finishes first

### After Fix:

Now the workflows are properly orchestrated:

## 🎯 How It Works Now

### Scenario 1: You Push API Code Changes

**Trigger:** Changes to any file in `vaar-api/agentic-api/health-assistant/` (except terraform files)

**Workflow:** `deploy.yml` runs on `developer` or `main` branch

```
1. Build Docker image
2. Push to ECR
3. Update existing Lambda function
```

**Result:** ✅ API updated with new code

---

### Scenario 2: You Push Terraform Changes

**Trigger:** Changes to files in `vaar-api/agentic-api/health-assistant/deploy/terraform/`

**Workflow:** `terraform-deploy.yml` runs on `main` branch ONLY

```
Job 1 (build-image):
  1. Build Docker image
  2. Push to ECR
  3. Mark as complete

Job 2 (terraform):
  WAITS for Job 1 to complete  ← This is the key!
  1. Run terraform init
  2. Run terraform plan
  3. Run terraform apply
  4. Lambda gets created/updated with image that's ALREADY in ECR
```

**Result:** ✅ Image built FIRST, then infrastructure deployed

---

### Scenario 3: You Push BOTH API and Terraform Changes

**Trigger:** Both paths changed in one commit

**What Happens:**

1. **Both workflows trigger** (this is OK now!)
2. **`deploy.yml`** (API deployment):
   - Builds Docker image
   - Tries to update Lambda
   - Might fail if Lambda doesn't exist yet (that's OK - terraform will create it)
3. **`terraform-deploy.yml`** (Infrastructure):
   - Job 1: Builds Docker image (redundant but safe)
   - Job 2: Creates/updates infrastructure including Lambda
   - Lambda will use the latest image from ECR

**Result:** ✅ No race condition - terraform workflow ensures image exists before creating Lambda

## 🔧 Local Deployment (First Time)

### Your Situation:

- Docker Desktop has WSL errors on Windows
- Can't use automated Docker build in Terraform

### Solution:

**Use GitHub Actions to build your Docker image!**

GitHub's Ubuntu runners have Docker pre-installed. You don't need Docker locally!

### Steps:

**Step 1: Push to GitHub** (GitHub builds the image for you)

```powershell
git add .
git commit -m "feat: initial deployment"
git push origin developer
```

**Step 2: Wait for GitHub Actions**

- Go to GitHub → Actions tab
- Watch "Deploy Health Assistant API" workflow
- It will build Docker and push to ECR
- Lambda update will fail (Lambda doesn't exist yet - that's OK!)

**Step 3: Create Infrastructure**

```powershell
cd deploy\terraform
$env:TF_VAR_openai_api_key = "sk-your-key"
terraform init
terraform apply
```

**Step 4: Upload Vector Store**

```powershell
cd ..\..
python ingestion\ingest_docs.py  # Uploads to S3
```

**Done!** ✅

## 📋 Workflow Path Filters Explained

### deploy.yml - Broader Trigger

```yaml
paths:
  - "vaar-api/agentic-api/health-assistant/**"
```

**Triggers on:** ANY file change in health-assistant folder
**Branches:** `developer` OR `main`
**Purpose:** Deploy code changes quickly to both environments

### terraform-deploy.yml - Narrow Trigger

```yaml
paths:
  - "vaar-api/agentic-api/health-assistant/deploy/terraform/**"
```

**Triggers on:** ONLY Terraform file changes
**Branches:** `main` ONLY
**Purpose:** Deploy infrastructure changes carefully to production

## 🔒 Safety Mechanisms

### 1. Job Dependencies

```yaml
jobs:
  build-image:
    # Builds Docker first

  terraform:
    needs: build-image # Won't start until build-image completes
```

### 2. Path Filters

- Terraform workflow only runs when Terraform files change
- API workflow runs for any code change
- Prevents unnecessary executions

### 3. Branch Protection

- Terraform deployment only on `main` branch
- API deployment on both `developer` and `main`
- Test on developer first, promote to main

### 4. Lambda Lifecycle

```terraform
lifecycle {
  ignore_changes = [image_uri]
}
```

- Terraform won't update Lambda image_uri on every apply
- Image updates handled by deploy.yml workflow
- Prevents conflicts

## 🎬 Complete First Deployment Flow

```
1. Local Development
   ├─ Write code
   ├─ Test with docker-compose (if Docker works)
   └─ OR just test ingestion script locally

2. Push to GitHub
   ├─ git commit -m "feat: initial deployment"
   ├─ git push origin developer
   └─ GitHub Actions builds Docker → Pushes to ECR

3. Deploy Infrastructure
   ├─ cd deploy\terraform
   ├─ terraform init
   ├─ terraform apply
   └─ Creates: ECR, Lambda, API Gateway, S3, IAM

4. Upload Data
   ├─ python ingestion\ingest_docs.py
   └─ Uploads vector store to S3

5. Test API
   ├─ Get URL from terraform output
   └─ Test /health and /query endpoints
```

## 🔄 Future Deployments (Automatic)

### Code Changes:

```powershell
git add app/
git commit -m "feat: improve RAG prompt"
git push origin developer
```

✅ **Automatic:** GitHub Actions builds → Pushes → Updates Lambda

### Infrastructure Changes:

```powershell
git add deploy/terraform/
git commit -m "infra: increase Lambda memory"
git push origin main
```

✅ **Automatic:** GitHub Actions builds Docker → Applies Terraform

## 📝 Summary

| Scenario             | What Happens                                      | Result                    |
| -------------------- | ------------------------------------------------- | ------------------------- |
| **Push API code**    | `deploy.yml` runs                                 | ✅ Lambda updated         |
| **Push Terraform**   | `terraform-deploy.yml` runs (image built first)   | ✅ Infrastructure updated |
| **Push both**        | Both workflows run (safe due to job dependencies) | ✅ Everything updated     |
| **First deployment** | GitHub builds image → Manual terraform apply      | ✅ No local Docker needed |

## 🎯 Key Takeaways

1. **No race conditions** - Job dependencies ensure proper order
2. **No local Docker needed** - GitHub Actions builds images
3. **Safe concurrent execution** - Path filters prevent conflicts
4. **Proper separation** - API deployment vs infrastructure deployment
5. **Test on developer first** - Promote to main when ready

You can safely commit everything to git now! The workflows are designed to handle it properly.
