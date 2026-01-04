# Terraform Backend Setup Guide

# Enable versioning

aws s3api put-bucket-versioning --bucket vaardesigns-terraform-state --versioning-configuration Status=Enabled

# Enable encryption (single line for PowerShell)

aws s3api put-bucket-encryption --bucket vaardesigns-terraform-state --server-side-encryption-configuration '{\"Rules\":[{\"ApplyServerSideEncryptionByDefault\":{\"SSEAlgorithm\":\"AES256\"}}]}'

# Block public access

aws s3api put-public-access-block --bucket vaardesigns-terraform-state --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=trueill help you migrate your existing Terraform state from local storage to AWS S3 with DynamoDB locking.

---

## 📋 Prerequisites

- AWS CLI configured with appropriate credentials
- Existing `terraform.tfstate` file (which you have)
- AWS account with permissions to create S3 buckets and DynamoDB tables

---

## 🎯 Overview

We'll create:

1. **S3 Bucket**: `vaardesigns-terraform-state` (stores state file)
2. **DynamoDB Table**: `vaardesigns-terraform-lock` (prevents concurrent modifications)

---

## 🚀 Step-by-Step Instructions

### **Step 1: Create S3 Bucket** (2 minutes)

**Option A: Using AWS CLI** (Recommended)

```powershell
# Create S3 bucket
aws s3api create-bucket --bucket vaardesigns-terraform-state --region us-east-1

# Enable versioning (protects against accidental deletion)
aws s3api put-bucket-versioning --bucket vaardesigns-terraform-state --versioning-configuration Status=Enabled

# Enable encryption
aws s3api put-bucket-encryption --bucket vaardesigns-terraform-state --server-side-encryption-configuration '{
  "Rules": [{
    "ApplyServerSideEncryptionByDefault": {
      "SSEAlgorithm": "AES256"
    }
  }]
}'

# Block public access
aws s3api put-public-access-block --bucket vaardesigns-terraform-state --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
```

**Option B: Using AWS Console**

1. Go to [S3 Console](https://console.aws.amazon.com/s3/)
2. Click **"Create bucket"**
3. **Bucket name**: `vaardesigns-terraform-state`
4. **Region**: `us-east-1`
5. **Block Public Access**: Enable all (keep defaults)
6. **Bucket Versioning**: Enable
7. **Default encryption**: Enable (AES-256)
8. Click **"Create bucket"**

---

### **Step 2: Create DynamoDB Table** (2 minutes)

**Option A: Using AWS CLI** (Recommended)

```powershell
# Create DynamoDB table for state locking
aws dynamodb create-table `
  --table-name vaardesigns-terraform-lock `
  --attribute-definitions AttributeName=LockID,AttributeType=S `
  --key-schema AttributeName=LockID,KeyType=HASH `
  --billing-mode PAY_PER_REQUEST `
  --region us-east-1
```

**Option B: Using AWS Console**

1. Go to [DynamoDB Console](https://console.aws.amazon.com/dynamodb/)
2. Click **"Create table"**
3. **Table name**: `vaardesigns-terraform-lock`
4. **Partition key**: `LockID` (String)
5. **Table settings**: Use default settings
6. **Read/write capacity**: On-demand
7. Click **"Create table"**

---

### **Step 3: Verify Backend Resources** (1 minute)

```powershell
# Verify S3 bucket exists
aws s3 ls | Select-String "vaardesigns-terraform-state"

# Verify DynamoDB table exists
aws dynamodb describe-table --table-name vaardesigns-terraform-lock --query "Table.TableName"
```

**Expected Output:**

```
vaardesigns-terraform-state
"vaardesigns-terraform-lock"
```

---

### **Step 4: Backup Current State** (IMPORTANT!) ⚠️

```powershell
# Create backup directory
New-Item -ItemType Directory -Force -Path .\backup

# Backup current state file
Copy-Item terraform.tfstate .\backup\terraform.tfstate.backup-$(Get-Date -Format "yyyyMMdd-HHmmss")

# Verify backup exists
Get-ChildItem .\backup\
```

---

### **Step 5: Initialize Backend** (3 minutes)

The `backend.tf` file is already created in your project. Now initialize:

```powershell
# Initialize Terraform with new backend (will prompt for migration)
terraform init -migrate-state
```

**You'll see a prompt like:**

```
Terraform has detected that the configuration specified for the backend
has changed. Terraform will now migrate the state from the previous
backend to the newly configured backend.

Do you want to copy existing state to the new backend?
  Enter a value: yes
```

**Type:** `yes` and press Enter

---

### **Step 6: Verify Migration** (2 minutes)

```powershell
# Check that state is now in S3
aws s3 ls s3://vaardesigns-terraform-state/website/

# Run terraform plan (should show NO changes)
terraform plan
```

**Expected Output:**

```
No changes. Your infrastructure matches the configuration.
```

If you see this, **migration successful!** ✅

---

### **Step 7: Verify State in S3** (Optional)

```powershell
# Download state from S3 to verify
aws s3 cp s3://vaardesigns-terraform-state/website/terraform.tfstate ./verify-state.tfstate

# Check file size (should be similar to your backup)
Get-Item ./verify-state.tfstate | Select-Object Name, Length

# Clean up verification file
Remove-Item ./verify-state.tfstate
```

---

### **Step 8: Clean Up Local State** (Optional)

Once verified, you can delete local state files:

```powershell
# Remove local state files (they're now in S3)
Remove-Item terraform.tfstate
Remove-Item terraform.tfstate.backup

# Keep only backup folder for safety
```

**Note:** You can keep local files for extra safety, but they're no longer used.

---

## ✅ Success Checklist

- [ ] S3 bucket `vaardesigns-terraform-state` created
- [ ] Bucket versioning enabled
- [ ] Bucket encryption enabled
- [ ] DynamoDB table `vaardesigns-terraform-lock` created
- [ ] Local state backed up to `./backup/`
- [ ] `terraform init -migrate-state` completed successfully
- [ ] `terraform plan` shows **"No changes"**
- [ ] State file visible in S3 bucket

---

## 🎉 What You've Achieved

✅ **State Backup**: Automatic versioning in S3  
✅ **State Locking**: Prevents concurrent modifications  
✅ **Multi-Machine**: Can run Terraform from anywhere  
✅ **Encrypted**: State file encrypted at rest  
✅ **CI/CD Ready**: Foundation for GitHub Actions

---

## 🔄 How to Use Going Forward

### **From Any Machine:**

```powershell
# Clone your repo
git clone <your-repo-url>
cd vaar-terraform-ui

# Initialize (will download state from S3)
terraform init

# Use Terraform normally
terraform plan
terraform apply
```

**That's it!** Terraform automatically uses S3 backend.

---

## 🚨 Troubleshooting

### **Issue 1: "Error acquiring state lock"**

```
Error: Error acquiring the state lock
```

**Solution:**
Someone else (or previous failed run) has the lock. Check DynamoDB table:

```powershell
# List locks
aws dynamodb scan --table-name vaardesigns-terraform-lock

# If no one is running Terraform, force unlock (use with caution!)
terraform force-unlock <LOCK_ID>
```

---

### **Issue 2: "Backend configuration changed"**

```
Error: Backend configuration changed
```

**Solution:**

```powershell
# Reinitialize backend
terraform init -reconfigure
```

---

### **Issue 3: "Access Denied" to S3 bucket**

**Solution:**
Check your AWS credentials have permission:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:*"],
      "Resource": [
        "arn:aws:s3:::vaardesigns-terraform-state",
        "arn:aws:s3:::vaardesigns-terraform-state/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": ["dynamodb:*"],
      "Resource": "arn:aws:dynamodb:us-east-1:*:table/vaardesigns-terraform-lock"
    }
  ]
}
```

---

## 💰 Cost Estimate

- **S3 Storage**: ~$0.023 per GB/month (~$0.01/month for typical state file)
- **S3 Requests**: Negligible (a few cents per month)
- **DynamoDB**: Free tier covers it (25GB storage, 25 WCU/RCU)
- **Total**: Less than **$0.10 per month** 💰

---

## 🔐 Security Best Practices

✅ **Never commit** `terraform.tfstate` to Git (already in `.gitignore`)  
✅ **Enable MFA Delete** on S3 bucket (optional, extra protection)  
✅ **Use IAM roles** instead of access keys when possible  
✅ **Enable CloudTrail** to audit access to state bucket  
✅ **Restrict bucket access** to specific IAM users/roles

---

## 📚 Additional Resources

- [Terraform S3 Backend Documentation](https://www.terraform.io/docs/language/settings/backends/s3.html)
- [AWS S3 Versioning](https://docs.aws.amazon.com/AmazonS3/latest/userguide/Versioning.html)
- [DynamoDB State Locking](https://www.terraform.io/docs/language/settings/backends/s3.html#dynamodb-state-locking)

---

## ❓ Need Help?

If you encounter any issues:

1. Check the troubleshooting section above
2. Verify AWS credentials: `aws sts get-caller-identity`
3. Check region is correct: `us-east-1`
4. Ensure S3 bucket and DynamoDB table exist

---

**You're all set! Your Terraform state is now safely managed in AWS S3.** 🎉
