# GitHub Actions Deployment Setup Guide

This guide will help you set up automated deployment from GitHub to your AWS infrastructure (S3, CloudFront, Route 53, ACM) that was provisioned with Terraform.

## 📋 Prerequisites

You should already have:

- ✅ S3 bucket (created via Terraform)
- ✅ CloudFront distribution (created via Terraform)
- ✅ Route 53 domain configuration (created via Terraform)
- ✅ ACM SSL certificate (created via Terraform)
- ✅ GitHub repository with your code

## 🔧 Setup Steps

### Step 1: Get Your Terraform Output Values

Navigate to your Terraform directory and run:

```bash
cd C:\vaardesigns\terraform\vaar-terraform-ui
terraform output
```

You need to note down:

- **S3 Bucket Name** (e.g., `vaardesigns-ui` or similar)
- **CloudFront Distribution ID** (starts with `E`, e.g., `E1234ABCD5678`)
- **AWS Region** (e.g., `us-east-1`)

If these aren't in your outputs, you can find them:

**S3 Bucket Name:**

```bash
terraform show | grep -A 5 "aws_s3_bucket"
```

Or check AWS Console → S3

**CloudFront Distribution ID:**

```bash
terraform show | grep -A 5 "aws_cloudfront_distribution"
```

Or check AWS Console → CloudFront → Your distribution

### Step 2: Create IAM User for GitHub Actions

You need an IAM user with programmatic access. You can either:

#### Option A: Add to Terraform (Recommended)

Create a new file `iam-github-actions.tf` in your Terraform directory:

```hcl
# IAM User for GitHub Actions
resource "aws_iam_user" "github_actions" {
  name = "github-actions-deploy"
  path = "/ci-cd/"
}

resource "aws_iam_access_key" "github_actions" {
  user = aws_iam_user.github_actions.name
}

# IAM Policy for deployment
resource "aws_iam_user_policy" "github_actions_deploy" {
  name = "GithubActionsDeployPolicy"
  user = aws_iam_user.github_actions.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3Deployment"
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ]
        Resource = [
          "arn:aws:s3:::${var.bucket_name}/*",
          "arn:aws:s3:::${var.bucket_name}"
        ]
      },
      {
        Sid    = "CloudFrontInvalidation"
        Effect = "Allow"
        Action = [
          "cloudfront:CreateInvalidation",
          "cloudfront:GetInvalidation",
          "cloudfront:ListInvalidations"
        ]
        Resource = aws_cloudfront_distribution.main.arn
      }
    ]
  })
}

# Output the credentials (sensitive - only shown once)
output "github_actions_access_key_id" {
  value     = aws_iam_access_key.github_actions.id
  sensitive = true
}

output "github_actions_secret_access_key" {
  value     = aws_iam_access_key.github_actions.secret
  sensitive = true
}
```

Then run:

```bash
terraform apply
terraform output github_actions_access_key_id
terraform output github_actions_secret_access_key
```

**⚠️ Important:** Save these credentials immediately - the secret key is only shown once!

#### Option B: Create Manually via AWS Console

1. Go to AWS Console → IAM → Users → Add users
2. Username: `github-actions-deploy`
3. Select "Access key - Programmatic access"
4. Create and attach this policy:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "S3Deployment",
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:DeleteObject",
        "s3:ListBucket",
        "s3:GetBucketLocation"
      ],
      "Resource": [
        "arn:aws:s3:::YOUR_BUCKET_NAME/*",
        "arn:aws:s3:::YOUR_BUCKET_NAME"
      ]
    },
    {
      "Sid": "CloudFrontInvalidation",
      "Effect": "Allow",
      "Action": [
        "cloudfront:CreateInvalidation",
        "cloudfront:GetInvalidation",
        "cloudfront:ListInvalidations"
      ],
      "Resource": "arn:aws:cloudfront::YOUR_ACCOUNT_ID:distribution/YOUR_DISTRIBUTION_ID"
    }
  ]
}
```

5. Save the Access Key ID and Secret Access Key

### Step 3: Add Secrets to GitHub Repository

1. Go to your GitHub repository: https://github.com/rangeyar/vaardesigns
2. Click **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret** and add each of the following:

| Secret Name                      | Value                               | Example                           |
| -------------------------------- | ----------------------------------- | --------------------------------- |
| `AWS_ACCESS_KEY_ID`              | IAM user access key                 | `AKIAIOSFODNN7EXAMPLE`            |
| `AWS_SECRET_ACCESS_KEY`          | IAM user secret key                 | `wJalrXUtnFEMI/K7MDENG/bPxRfi...` |
| `AWS_REGION`                     | AWS region where your resources are | `us-east-1`                       |
| `AWS_S3_BUCKET`                  | Your S3 bucket name                 | `vaardesigns-ui`                  |
| `AWS_CLOUDFRONT_DISTRIBUTION_ID` | CloudFront distribution ID          | `E1234ABCD5678`                   |

### Step 4: Test the Workflow

#### Option 1: Push to Trigger Deployment

```bash
git add .github/workflows/deploy-to-aws.yml
git commit -m "Add GitHub Actions deployment workflow"
git push origin developer
```

#### Option 2: Manually Trigger (Recommended for First Test)

1. Go to your GitHub repository
2. Click **Actions** tab
3. Select **Deploy to AWS** workflow
4. Click **Run workflow** button
5. Select your branch (developer)
6. Click **Run workflow**

### Step 5: Monitor the Deployment

1. Watch the workflow execution in the Actions tab
2. Each step will show its progress
3. If any step fails, click on it to see detailed logs

## 🎯 How It Works

The workflow automatically:

1. ✅ Checks out your code
2. ✅ Sets up Node.js 20
3. ✅ Installs dependencies (`npm ci`)
4. ✅ Runs ESLint (continues even if warnings exist)
5. ✅ Builds your React app (`npm run build`)
6. ✅ Uploads build files to S3
7. ✅ Invalidates CloudFront cache
8. ✅ Shows deployment summary

## 📝 Workflow Triggers

The workflow runs automatically when you:

- Push to `main` branch
- Push to `developer` branch
- Manually trigger it from GitHub Actions UI

To change branches, edit `.github/workflows/deploy-to-aws.yml`:

```yaml
on:
  push:
    branches:
      - main
      - developer
      - your-custom-branch
```

## 🔒 Security Best Practices

1. **Never commit AWS credentials** to your repository
2. **Use GitHub Secrets** for all sensitive data
3. **Limit IAM permissions** to only what's needed
4. **Rotate credentials regularly**
5. **Enable branch protection** on main/production branches
6. **Require pull request reviews** before merging

## 🐛 Troubleshooting

### Build Fails

```
Error: Cannot find module...
```

**Solution:** Ensure all dependencies are in `package.json` and committed

### AWS Authentication Failed

```
Error: The security token included in the request is invalid
```

**Solution:**

- Verify AWS credentials in GitHub Secrets
- Check IAM user still exists and has access keys
- Ensure no typos in secret names

### S3 Upload Failed

```
Error: Access Denied
```

**Solution:**

- Verify S3 bucket name is correct
- Check IAM policy includes `s3:PutObject` permission
- Ensure bucket exists in the specified region

### CloudFront Invalidation Failed

```
Error: User is not authorized to perform: cloudfront:CreateInvalidation
```

**Solution:**

- Verify CloudFront distribution ID is correct
- Check IAM policy includes CloudFront permissions
- Ensure distribution ID doesn't have extra spaces

### Website Shows Old Version

**Solution:**

- Wait 5-10 minutes for CloudFront cache invalidation
- Hard refresh browser (Ctrl+Shift+R / Cmd+Shift+R)
- Check if deployment actually succeeded in Actions tab

## 🚀 Advanced Configuration

### Add Environment Variables

If your app needs environment variables at build time:

1. Add secrets to GitHub (e.g., `VITE_API_URL`)
2. Update workflow file:

```yaml
- name: Build application
  run: npm run build
  env:
    VITE_API_URL: ${{ secrets.VITE_API_URL }}
    VITE_APP_ENV: production
```

### Deploy to Multiple Environments

Create separate workflow files:

- `.github/workflows/deploy-staging.yml` (triggers on `developer` branch)
- `.github/workflows/deploy-production.yml` (triggers on `main` branch)

Use different secrets for each environment:

- `AWS_S3_BUCKET_STAGING` / `AWS_S3_BUCKET_PRODUCTION`
- `AWS_CLOUDFRONT_DISTRIBUTION_ID_STAGING` / `AWS_CLOUDFRONT_DISTRIBUTION_ID_PRODUCTION`

### Add Slack/Discord Notifications

Add this step at the end:

```yaml
- name: Notify deployment
  if: always()
  run: |
    curl -X POST ${{ secrets.SLACK_WEBHOOK_URL }} \
      -H 'Content-Type: application/json' \
      -d '{"text":"Deployment ${{ job.status }}: ${{ github.ref_name }}"}'
```

## 📊 Monitoring Deployments

### View Deployment History

1. Go to GitHub → Actions tab
2. See all workflow runs
3. Click any run to see detailed logs

### Add Status Badge to README

Add this to your `README.md`:

```markdown
![Deployment Status](https://github.com/rangeyar/vaardesigns/actions/workflows/deploy-to-aws.yml/badge.svg)
```

## 💰 Cost Considerations

- **GitHub Actions**: 2,000 free minutes/month for private repos
- **S3**: Pay for storage and requests (minimal for static sites)
- **CloudFront**: Free tier includes 1TB data transfer/month
- **IAM**: Free

Your typical deployment should cost pennies per month!

## 📚 Additional Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [AWS S3 Static Website Hosting](https://docs.aws.amazon.com/AmazonS3/latest/userguide/WebsiteHosting.html)
- [CloudFront Invalidation](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/Invalidation.html)
- [Vite Build Documentation](https://vitejs.dev/guide/build.html)

## ✅ Quick Checklist

- [ ] Retrieved S3 bucket name from Terraform
- [ ] Retrieved CloudFront distribution ID from Terraform
- [ ] Created IAM user with deployment permissions
- [ ] Added all 5 secrets to GitHub repository
- [ ] Pushed workflow file to repository
- [ ] Triggered first deployment (manual or push)
- [ ] Verified deployment in Actions tab
- [ ] Checked website is live with new version
- [ ] Set up branch protection rules (optional)
- [ ] Added deployment status badge (optional)

---

**Need Help?** Check the workflow logs in GitHub Actions for detailed error messages, or refer to the troubleshooting section above.
