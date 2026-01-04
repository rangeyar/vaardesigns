# Rollback Guide - Return to Local State

If you need to rollback from S3 backend to local state, follow these steps.

---

## ⚠️ When to Use This

- Migration failed or caused issues
- Want to return to local state temporarily
- Testing or debugging purposes

---

## 🔄 Rollback Steps

### **Step 1: Remove Backend Configuration**

Delete or comment out the `backend.tf` file:

```powershell
# Rename backend.tf to disable it
Rename-Item backend.tf backend.tf.disabled
```

Or comment out the backend block in `backend.tf`:

```terraform
# terraform {
#   backend "s3" {
#     bucket         = "vaardesigns-terraform-state"
#     key            = "website/terraform.tfstate"
#     region         = "us-east-1"
#     dynamodb_table = "vaardesigns-terraform-lock"
#     encrypt        = true
#   }
# }
```

---

### **Step 2: Reconfigure Backend to Local**

```powershell
# Reinitialize with local backend
terraform init -migrate-state
```

**When prompted:**

```
Do you want to copy existing state from "s3" to "local"?
  Enter a value: yes
```

Type `yes` to copy state from S3 back to local file.

---

### **Step 3: Verify Local State**

```powershell
# Check local state file exists
Get-Item terraform.tfstate

# Verify with plan
terraform plan
```

Should show: `No changes. Your infrastructure matches the configuration.`

---

### **Step 4: Optional - Clean Up S3 Resources**

If you want to remove backend resources (optional):

```powershell
# Delete state from S3 (if you're sure!)
aws s3 rm s3://vaardesigns-terraform-state/website/terraform.tfstate

# Delete S3 bucket (if empty)
aws s3 rb s3://vaardesigns-terraform-state --force

# Delete DynamoDB table
aws dynamodb delete-table --table-name vaardesigns-terraform-lock
```

**Warning:** Only do this if you're completely sure!

---

## ✅ Verification

- [ ] `backend.tf` removed or disabled
- [ ] `terraform init -migrate-state` completed
- [ ] Local `terraform.tfstate` file exists
- [ ] `terraform plan` shows no changes

---

**You're back to local state!**
