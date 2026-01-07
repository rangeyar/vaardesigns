# Managing IAM Permissions with Terraform

## What This Does

The `github_actions_iam.tf` file:

1. ✅ References your existing IAM user (`github-actions-vaar-ui-deploy`)
2. ✅ Creates custom IAM policies for:
   - ECR access (Docker image push/pull)
   - Lambda access (function updates)
   - Terraform state access (S3 + DynamoDB)
3. ✅ Attaches all policies to your existing user

## How to Apply

```powershell
cd deploy\terraform

# Set OpenAI API key
$env:TF_VAR_openai_api_key = "sk-your-key"

# Initialize (downloads AWS provider)
terraform init

# Preview changes
terraform plan

# Apply changes
terraform apply
```

Type `yes` when prompted.

## What Gets Created

### Policies Created:

1. **GitHubActionsECRPolicy** - Docker image operations
2. **GitHubActionsLambdaPolicy** - Lambda function updates
3. **GitHubActionsTerraformStatePolicy** - Terraform state management

### Policies Attached To:

- User: `github-actions-vaar-ui-deploy` (your existing user)

## After Applying

Your IAM user will have ALL needed permissions:

- ✅ ECR: Push Docker images
- ✅ Lambda: Update functions
- ✅ S3: Access Terraform state
- ✅ DynamoDB: Manage state locks
- ✅ API Gateway: Read API info

## Verify Permissions

```powershell
# List all policies attached to user
aws iam list-attached-user-policies --user-name github-actions-vaar-ui-deploy

# Should show:
# - GitHubActionsECRPolicy
# - GitHubActionsLambdaPolicy
# - GitHubActionsTerraformStatePolicy
# - (plus any other existing policies)
```

## Re-run Failed Workflow

After applying Terraform:

1. Go to GitHub → Actions tab
2. Find the failed workflow run
3. Click "Re-run all jobs"

OR push a new commit to trigger the workflow.

## Benefits of Managing via Terraform

✅ **Version Controlled** - IAM policies tracked in git
✅ **Reproducible** - Easy to recreate in other environments
✅ **Documented** - Clear what permissions are granted
✅ **Auditable** - Changes reviewed via pull requests
✅ **Least Privilege** - Only grants necessary permissions

## Cleanup Old Manual Policies

After Terraform creates the new policies, you may have duplicate policies (manual + Terraform).

To remove manual policies:

```powershell
# List policies on user
aws iam list-attached-user-policies --user-name github-actions-vaar-ui-deploy

# If you see duplicates like "AmazonEC2ContainerRegistryPowerUser", detach:
aws iam detach-user-policy `
  --user-name github-actions-vaar-ui-deploy `
  --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser
```

**Note:** Only remove duplicates AFTER confirming Terraform policies are attached and working.

## Troubleshooting

### "User not found" error

- The user name might be different
- Check: `aws iam list-users --path /ci-cd/`
- Update the data source in `github_actions_iam.tf` with correct name

### "Policy already exists" error

- You might have manually created a policy with the same name
- Either delete the manual policy first, or rename the Terraform policy

### Permissions still not working

- Wait 1-2 minutes for IAM changes to propagate
- Check policy is attached: `aws iam list-attached-user-policies --user-name github-actions-vaar-ui-deploy`
- Verify policy JSON is correct in AWS Console

## Future Improvements

When you have multiple services, create a shared IAM module:

```
infrastructure/
  iam/
    github-actions/
      main.tf
      variables.tf
      outputs.tf
```

Then reference it from each service's Terraform code.

## Summary

**Before:** Manual IAM policy management via AWS Console
**After:** Fully managed by Terraform, version controlled, documented

**All permissions for GitHub Actions CI/CD are now Infrastructure as Code!** 🎉
