# Fix ECR Permissions for GitHub Actions

## Problem

Your GitHub Actions IAM user (`github-actions-vaar-ui-deploy`) doesn't have ECR permissions.

Error:

```
User: arn:aws:iam::062377979444:user/ci-cd/github-actions-vaar-ui-deploy is not authorized to perform: ecr:GetAuthorizationToken
```

## Solution

You need to add ECR permissions to your IAM user.

### Option 1: Using AWS Console (Easiest)

1. **Go to IAM Console:**

   - https://console.aws.amazon.com/iam/

2. **Navigate to User:**

   - Click "Users" in left sidebar
   - Search for: `github-actions-vaar-ui-deploy`
   - Click on the user

3. **Add Permissions:**

   - Click "Add permissions" → "Attach policies directly"
   - Search and select these policies:
     - ✅ `AmazonEC2ContainerRegistryPowerUser` (for ECR push/pull)
     - OR create a custom policy (see Option 2)
   - Click "Add permissions"

4. **Verify:**
   - User should now have ECR permissions
   - Retry GitHub Actions workflow

---

### Option 2: Using AWS CLI (Recommended - More Secure)

Create a custom policy with only needed permissions:

```powershell
# Save this policy to a file: ecr-policy.json
```

Create this file: **ecr-policy.json**

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["ecr:GetAuthorizationToken"],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:PutImage",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload",
        "ecr:DescribeRepositories",
        "ecr:ListImages",
        "ecr:DescribeImages"
      ],
      "Resource": "arn:aws:ecr:us-east-1:062377979444:repository/vaardesigns-health-assistant-prod"
    }
  ]
}
```

Then run these commands:

```powershell
# Create the policy
aws iam create-policy `
  --policy-name GitHubActionsHealthAssistantECRPolicy `
  --policy-document file://ecr-policy.json `
  --description "Allows GitHub Actions to push Docker images to Health Assistant ECR"

# Attach policy to user
aws iam attach-user-policy `
  --user-name github-actions-vaar-ui-deploy `
  --policy-arn arn:aws:iam::062377979444:policy/GitHubActionsHealthAssistantECRPolicy
```

---

### Option 3: Quick Fix with Managed Policy (Fast but Less Secure)

```powershell
# Attach AWS managed policy for ECR power user
aws iam attach-user-policy `
  --user-name github-actions-vaar-ui-deploy `
  --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser
```

This gives full ECR access - good for quick testing, but Option 2 is more secure for production.

---

### Option 4: Add Lambda Permissions Too (Complete Solution)

If you want to add ALL needed permissions for the health assistant deployment:

Create this file: **github-actions-health-assistant-policy.json**

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ECRAuthentication",
      "Effect": "Allow",
      "Action": ["ecr:GetAuthorizationToken"],
      "Resource": "*"
    },
    {
      "Sid": "ECRPushPull",
      "Effect": "Allow",
      "Action": [
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:PutImage",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload",
        "ecr:DescribeRepositories",
        "ecr:ListImages",
        "ecr:DescribeImages"
      ],
      "Resource": [
        "arn:aws:ecr:us-east-1:062377979444:repository/vaardesigns-health-assistant-prod"
      ]
    },
    {
      "Sid": "LambdaUpdate",
      "Effect": "Allow",
      "Action": [
        "lambda:UpdateFunctionCode",
        "lambda:GetFunction",
        "lambda:GetFunctionConfiguration",
        "lambda:UpdateFunctionConfiguration"
      ],
      "Resource": [
        "arn:aws:lambda:us-east-1:062377979444:function:vaardesigns-health-assistant-prod"
      ]
    },
    {
      "Sid": "APIGatewayRead",
      "Effect": "Allow",
      "Action": ["apigatewayv2:GET", "apigatewayv2:GetApis"],
      "Resource": "*"
    }
  ]
}
```

Then run:

```powershell
# Create the comprehensive policy
aws iam create-policy `
  --policy-name GitHubActionsHealthAssistantFullPolicy `
  --policy-document file://github-actions-health-assistant-policy.json `
  --description "Full permissions for GitHub Actions to deploy Health Assistant API"

# Attach policy to user
aws iam attach-user-policy `
  --user-name github-actions-vaar-ui-deploy `
  --policy-arn arn:aws:iam::062377979444:policy/GitHubActionsHealthAssistantFullPolicy
```

---

## Verify Permissions

After adding permissions, verify they're attached:

```powershell
# List all policies attached to user
aws iam list-attached-user-policies --user-name github-actions-vaar-ui-deploy

# Test ECR login (should work now)
aws ecr get-login-password --region us-east-1
```

---

## After Fixing Permissions

1. **Re-run the failed GitHub Actions workflow:**

   - Go to GitHub → Actions tab
   - Click on the failed workflow run
   - Click "Re-run all jobs"

2. **Or push a new commit:**
   ```powershell
   git commit --allow-empty -m "trigger: retry deployment after fixing ECR permissions"
   git push origin developer
   ```

---

## Recommended Approach

**For Production:** Use **Option 4** (comprehensive custom policy)

- Most secure - only grants needed permissions
- Scoped to specific resources
- Easy to audit

**For Quick Testing:** Use **Option 3** (managed policy)

- Fast to set up
- Broader permissions
- Good for POC/development

---

## Additional Notes

### If you're using the same IAM user for UI and API:

That's fine! The policies are additive. Your user will have:

- ✅ Existing UI deployment permissions
- ✅ NEW API/ECR/Lambda permissions

### If you want separate users:

Create a new IAM user specifically for API deployments:

```powershell
# Create new user
aws iam create-user --user-name github-actions-health-assistant

# Create access key
aws iam create-access-key --user-name github-actions-health-assistant

# Attach policy
aws iam attach-user-policy `
  --user-name github-actions-health-assistant `
  --policy-arn arn:aws:iam::062377979444:policy/GitHubActionsHealthAssistantFullPolicy

# Update GitHub secrets with new credentials
```

---

## Troubleshooting

### Still getting permission errors after adding policy?

- Wait 1-2 minutes for IAM changes to propagate
- Clear GitHub Actions cache by re-running workflow
- Verify policy is attached: `aws iam list-attached-user-policies --user-name github-actions-vaar-ui-deploy`

### Need to add more permissions later?

- Create new policy version OR
- Attach additional policies (users can have up to 10 managed policies)

---

## Quick Command Reference

```powershell
# List user policies
aws iam list-attached-user-policies --user-name github-actions-vaar-ui-deploy

# Detach policy (if needed)
aws iam detach-user-policy --user-name github-actions-vaar-ui-deploy --policy-arn <policy-arn>

# Delete policy (if needed to recreate)
aws iam delete-policy --policy-arn <policy-arn>

# Test ECR access
aws ecr describe-repositories --region us-east-1
```

---

## Summary

**Choose one option above** → **Add permissions** → **Re-run GitHub Actions** → **Done!** ✅

I recommend **Option 4** for a complete, secure solution that includes all permissions needed for the health assistant API deployment.
