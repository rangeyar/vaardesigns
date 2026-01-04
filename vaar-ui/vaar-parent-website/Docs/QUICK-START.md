# 🚀 Quick Start - GitHub Actions Deployment

## Step-by-Step Setup (5 minutes)

### ✅ Step 1: Get Your AWS Resource Information

Open PowerShell and navigate to your Terraform directory:

```powershell
cd C:\vaardesigns\terraform\vaar-terraform-ui
terraform output
```

**Write down these values:**

- S3 Bucket Name: `_________________`
- CloudFront Distribution ID: `_________________`
- AWS Region: `_________________`

---

### ✅ Step 2: Create IAM User for GitHub Actions

**Option A - Using Terraform (Recommended):**

1. Copy `terraform-github-actions-iam.tf` to `C:\vaardesigns\terraform\vaar-terraform-ui\`
2. Update resource names if needed (check comments in the file)
3. Run:
   ```powershell
   cd C:\vaardesigns\terraform\vaar-terraform-ui
   terraform plan
   terraform apply
   ```
4. Get credentials:
   ```powershell
   terraform output github_actions_access_key_id
   terraform output github_actions_secret_access_key
   ```

**Option B - Using AWS Console:**

1. Go to AWS Console → IAM → Users → Add users
2. Username: `github-actions-vaar-ui-deploy`
3. Access type: "Programmatic access"
4. Attach policy (see GITHUB-DEPLOYMENT-GUIDE.md for policy JSON)
5. Save Access Key ID and Secret Access Key

**Write down these credentials:**

- Access Key ID: `_________________`
- Secret Access Key: `_________________`

---

### ✅ Step 3: Add Secrets to GitHub

1. Go to: https://github.com/rangeyar/vaardesigns
2. Click: **Settings** → **Secrets and variables** → **Actions**
3. Add these 5 secrets:

| Secret Name                      | Where to Get Value |
| -------------------------------- | ------------------ |
| `AWS_ACCESS_KEY_ID`              | From Step 2        |
| `AWS_SECRET_ACCESS_KEY`          | From Step 2        |
| `AWS_REGION`                     | From Step 1        |
| `AWS_S3_BUCKET`                  | From Step 1        |
| `AWS_CLOUDFRONT_DISTRIBUTION_ID` | From Step 1        |

---

### ✅ Step 4: Push Workflow File

```powershell
cd "c:\Users\13124\Desktop\Skills\agentic-ai\main-website-vaar\test-git\vaardesigns\vaar-ui\vaar-parent-website"

git add .github/workflows/deploy-to-aws.yml
git add GITHUB-DEPLOYMENT-GUIDE.md
git add QUICK-START.md

git commit -m "Add GitHub Actions deployment workflow"
git push origin developer
```

---

### ✅ Step 5: Test Deployment

**Option 1 - Manual Trigger (Recommended for first time):**

1. Go to: https://github.com/rangeyar/vaardesigns/actions
2. Click: **Deploy to AWS**
3. Click: **Run workflow** dropdown
4. Select branch: `developer`
5. Click: **Run workflow** button
6. Watch it deploy! 🎉

**Option 2 - Automatic Trigger:**
Just push any code change to `developer` or `main` branch

---

## 🎯 Expected Result

The workflow will:

1. ✅ Build your React app
2. ✅ Upload to S3
3. ✅ Invalidate CloudFront cache
4. ✅ Show success message

Your website will be updated in **5-10 minutes** (CloudFront cache invalidation time)

---

## 🔍 Troubleshooting

### "Workflow not found"

- Make sure you pushed the workflow file to GitHub
- Check file is in `.github/workflows/` directory

### "AWS Authentication Failed"

- Verify all 5 secrets are added correctly
- No extra spaces in secret values
- Check IAM user has correct permissions

### "S3 Access Denied"

- Verify bucket name is correct
- Check IAM policy includes S3 permissions

### Need detailed help?

See **GITHUB-DEPLOYMENT-GUIDE.md** for complete troubleshooting guide

---

## 📝 Current Configuration

- **Repository:** rangeyar/vaardesigns
- **Current Branch:** developer
- **Triggers:** Push to `main` or `developer`, or manual trigger
- **Node Version:** 20
- **Build Command:** `npm run build`
- **Build Output:** `dist/`

---

## 🎨 Customization

### Change Trigger Branches

Edit `.github/workflows/deploy-to-aws.yml`:

```yaml
on:
  push:
    branches:
      - main
      - your-branch-name
```

### Add Environment Variables

Edit build step in workflow:

```yaml
- name: Build application
  run: npm run build
  env:
    VITE_API_URL: ${{ secrets.VITE_API_URL }}
```

---

## ✨ That's It!

You now have automated deployments! Every time you push to `developer` or `main` branch, your app will automatically deploy to AWS.

### Next Steps:

- [ ] Set up branch protection rules on `main`
- [ ] Create separate staging environment
- [ ] Add deployment notifications (Slack/Discord)
- [ ] Set up automated testing before deployment

**Happy Deploying! 🚀**
