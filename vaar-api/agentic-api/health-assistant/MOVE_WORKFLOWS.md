# 📋 Action Required: Move Workflow Files

## Problem
The GitHub Actions workflow files are currently in the WRONG location:
- ❌ `vaar-api/agentic-api/health-assistant/.github/workflows/`

They need to be at the REPOSITORY ROOT:
- ✅ `.github/workflows/` (at vaardesigns repository root)

## Why?
GitHub Actions only reads workflows from the repository root `.github/workflows/` folder, just like your UI workflows.

## Steps to Fix

### Option 1: Using File Explorer (Easiest)

1. **Navigate to your repository root:**
   ```
   c:\Users\13124\Desktop\Skills\agentic-ai\main-website-vaar\test-terraform\vaardesigns\
   ```

2. **Check if `.github/workflows/` exists at root level**
   - If YES: Great! You already have it (for your UI)
   - If NO: Create the folders

3. **Copy/Move these 2 workflow files:**
   
   **FROM:**
   ```
   vaardesigns/vaar-api/agentic-api/health-assistant/.github/workflows/deploy.yml
   vaardesigns/vaar-api/agentic-api/health-assistant/.github/workflows/terraform-deploy.yml
   ```
   
   **TO:**
   ```
   vaardesigns/.github/workflows/deploy-health-assistant-api.yml
   vaardesigns/.github/workflows/terraform-deploy-health-assistant.yml
   ```
   
   **Note:** I renamed them to be more descriptive since they're at root level with other workflows

4. **Delete the old workflow folder:**
   ```
   vaardesigns/vaar-api/agentic-api/health-assistant/.github/
   ```

### Option 2: Using PowerShell

```powershell
# Navigate to repository root
cd c:\Users\13124\Desktop\Skills\agentic-ai\main-website-vaar\test-terraform\vaardesigns

# Create .github/workflows if it doesn't exist (it probably already exists from your UI workflows)
# New-Item -ItemType Directory -Path ".github\workflows" -Force

# Copy workflow files to root
Copy-Item "vaar-api\agentic-api\health-assistant\.github\workflows\deploy.yml" ".github\workflows\deploy-health-assistant-api.yml"
Copy-Item "vaar-api\agentic-api\health-assistant\.github\workflows\terraform-deploy.yml" ".github\workflows\terraform-deploy-health-assistant.yml"

# Delete old .github folder from health-assistant
Remove-Item "vaar-api\agentic-api\health-assistant\.github" -Recurse -Force

# Verify files are in correct location
Get-ChildItem ".github\workflows\*health-assistant*.yml"
```

## After Moving Files

### Commit the changes:
```powershell
git add .github/workflows/
git add vaar-api/agentic-api/health-assistant/
git commit -m "fix: move GitHub Actions workflows to repository root"
git push origin developer
```

## Final Structure

Your repository should look like this:

```
vaardesigns/  (repository root)
├── .github/
│   └── workflows/
│       ├── deploy-health-assistant-api.yml          # ✅ NEW: API deployment
│       ├── terraform-deploy-health-assistant.yml    # ✅ NEW: Infrastructure deployment
│       └── [your existing UI workflows...]          # ✅ Your existing workflows
│
├── infrastructure/                                   # Your UI infrastructure
│
├── vaar-api/
│   └── agentic-api/
│       └── health-assistant/
│           ├── app/                                 # ✅ API code (no .github folder here!)
│           ├── deploy/terraform/                    # ✅ Terraform files
│           ├── health-doc/                          # ✅ PDF documents
│           ├── ingestion/                           # ✅ Ingestion script
│           ├── QUICK_START.md                       # ✅ Quick start guide
│           ├── Dockerfile                           # ✅ Docker config
│           └── requirements.txt                     # ✅ Python dependencies
│
└── vaar-ui/                                         # Your UI code
```

## Verification

After moving files, verify GitHub can see them:

1. Push to GitHub
2. Go to your repo → **Actions** tab
3. You should see:
   - "Deploy Health Assistant API" workflow
   - "Terraform Deploy Health Assistant (Infrastructure)" workflow

If you don't see them, the files are not in the correct location.

## Important Notes

- ✅ The `working-directory` in workflows handles the path to health-assistant folder
- ✅ The `paths` filter ensures workflows only trigger for health-assistant changes
- ✅ Keep all your API code in `vaar-api/agentic-api/health-assistant/`
- ✅ Only workflows go to root `.github/workflows/`

## Ready to Deploy?

Once you've moved the workflow files:

1. ✅ Add GitHub Secrets (AWS credentials, OpenAI key)
2. ✅ Push code to developer branch
3. ✅ Wait for GitHub Actions to build Docker image
4. ✅ Run `terraform apply` locally
5. ✅ Upload vector store with `python ingestion/ingest_docs.py`
6. ✅ Test your API!

See `QUICK_START.md` for detailed step-by-step instructions.
