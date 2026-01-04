# Quick Start - Backend Setup (5 Minutes)

For the impatient developer who wants to get back to coding! 😄

---

## ⚡ TL;DR - Copy/Paste Commands

### **1. Create S3 Bucket & DynamoDB Table**

```powershell
# Create S3 bucket
aws s3api create-bucket --bucket vaardesigns-terraform-state --region us-east-1

# Enable versioning
aws s3api put-bucket-versioning --bucket vaardesigns-terraform-state --versioning-configuration Status=Enabled

# Enable encryption
aws s3api put-bucket-encryption --bucket vaardesigns-terraform-state --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'

# Block public access
aws s3api put-public-access-block --bucket vaardesigns-terraform-state --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

# Create DynamoDB table
aws dynamodb create-table --table-name vaardesigns-terraform-lock --attribute-definitions AttributeName=LockID,AttributeType=S --key-schema AttributeName=LockID,KeyType=HASH --billing-mode PAY_PER_REQUEST --region us-east-1
```

---

### **2. Backup Current State**

```powershell
# Backup existing state
New-Item -ItemType Directory -Force -Path .\backup
Copy-Item terraform.tfstate .\backup\terraform.tfstate.backup-$(Get-Date -Format "yyyyMMdd-HHmmss")
```

---

### **3. Migrate to S3 Backend**

```powershell
# Initialize with S3 backend (backend.tf already exists)
terraform init -migrate-state
# Type: yes when prompted
```

---

### **4. Verify**

```powershell
# Should show "No changes"
terraform plan
```

---

## ✅ Done! Back to UI Development! 🎨

Your Terraform state is now:

- ✅ Backed up in S3
- ✅ Protected with versioning
- ✅ Locked with DynamoDB
- ✅ Accessible from any machine

---

## 🚨 If Something Goes Wrong

See `BACKEND-SETUP.md` for detailed troubleshooting or `ROLLBACK-GUIDE.md` to revert.

---

**Now go build that awesome UI!** 🚀
