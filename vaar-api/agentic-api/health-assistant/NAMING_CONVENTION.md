# VaarDesigns Naming Convention - Health Assistant API

## 🎯 Consistent Naming Pattern

### **Organization**

- Name: `vaardesigns`
- Domain: `vaardesigns.com`

### **Infrastructure Resources**

#### **S3 Buckets:**

- State: `vaardesigns-terraform-state` (shared with UI)
- Vector Store: `vaardesigns-health-assistant`

#### **API Endpoints:**

- Production: `https://api.vaardesigns.com` (custom domain - to be configured)
- Default: `https://xxxxx.execute-api.us-east-1.amazonaws.com` (API Gateway URL)

#### **Lambda Function:**

- Name: `vaardesigns-health-assistant-prod`
- Pattern: `{organization}-{project}-{environment}`

#### **ECR Repository:**

- Name: `vaardesigns-health-assistant-prod`

#### **DynamoDB Table (State Lock):**

- Name: `vaardesigns-terraform-lock` (shared with UI)

### **Terraform State Paths**

```
vaardesigns-terraform-state/
├── website/terraform.tfstate              # UI state
└── health-assistant/terraform.tfstate     # API state
```

### **CORS Configuration**

Allowed origins:

- `https://vaardesigns.com`
- `https://www.vaardesigns.com`

### **Resource Tags**

All resources tagged with:

```hcl
{
  Organization = "vaardesigns"
  Project      = "health-assistant"
  Environment  = "prod"
  ManagedBy    = "Terraform"
}
```

### **Future Projects**

Follow same pattern:

- S3: `vaardesigns-{project-name}`
- Lambda: `vaardesigns-{project-name}-{env}`
- API: `{service}.vaardesigns.com`
- State: `vaardesigns-terraform-state/{project-name}/terraform.tfstate`

## 📋 Summary

✅ **Consistency**: All resources prefixed with `vaardesigns`
✅ **Clarity**: Project names clearly identify purpose
✅ **Scalability**: Pattern works for multiple projects
✅ **Organization**: Grouped by organization/project/environment
