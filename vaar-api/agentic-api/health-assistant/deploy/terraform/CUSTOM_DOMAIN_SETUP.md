# Custom Domain Setup Guide

## What You Get

After running `terraform apply`, you'll have:

- ✅ **`api.vaardesigns.com`** - Your custom API domain
- ✅ **FREE SSL certificate** from AWS Certificate Manager
- ✅ **Automatic HTTPS** (TLS 1.2)
- ✅ **No additional costs** (you already own the domain)

## Setup Steps

### Step 1: Apply Terraform

```powershell
cd deploy\terraform
terraform apply
```

**What happens:**

1. Creates ACM certificate for `api.vaardesigns.com`
2. Creates DNS records for certificate validation
3. Waits for certificate validation (~5-10 minutes)
4. Creates API Gateway custom domain
5. Maps your API to the custom domain
6. Creates Route53 A record

### Step 2: Wait for DNS Propagation

DNS changes can take **5-60 minutes** to propagate globally.

Check status:

```powershell
# Check if DNS is resolving
nslookup api.vaardesigns.com

# Test the API
Invoke-RestMethod -Uri "https://api.vaardesigns.com/health" -Method GET
```

### Step 3: Update Your UI Code

Change your API endpoint from:

```javascript
// OLD
const API_URL = "https://8qdfo3.execute-api.us-east-1.amazonaws.com";

// NEW
const API_URL = "https://api.vaardesigns.com";
```

### Step 4: Update CORS Origins

Update `terraform.tfvars`:

```hcl
cors_origins = "https://vaardesigns.com,https://www.vaardesigns.com,https://api.vaardesigns.com"
```

Then apply:

```powershell
terraform apply
```

## Optional: Add healthassistant Subdomain

If you want **both** `api.vaardesigns.com` AND `healthassistant.vaardesigns.com`:

Update `terraform.tfvars`:

```hcl
create_healthassistant_subdomain = true
```

Then apply:

```powershell
terraform apply
```

Both will work:

- `https://api.vaardesigns.com/health`
- `https://healthassistant.vaardesigns.com/health`

## Cost Breakdown

| Service                   | Cost                                |
| ------------------------- | ----------------------------------- |
| Route53 Hosted Zone       | $0.50/month (you already have this) |
| ACM Certificate           | **FREE**                            |
| API Gateway Custom Domain | **FREE**                            |
| Route53 DNS Queries       | ~$0.40/million queries              |

**Total Additional Cost: ~$0** (essentially free!)

## Troubleshooting

### Certificate validation takes too long

- Check Route53 has the validation CNAME records
- Wait up to 30 minutes for validation
- Check ACM console for validation status

### DNS not resolving

```powershell
# Check if Route53 record exists
aws route53 list-resource-record-sets --hosted-zone-id <your-zone-id> | Select-String "api.vaardesigns.com"

# Flush local DNS cache
ipconfig /flushdns

# Wait 5-15 minutes for global DNS propagation
```

### Certificate error in browser

- Ensure ACM certificate is validated
- Check certificate is in **us-east-1** region
- Verify API Gateway domain is using the correct certificate

### 403 Forbidden or CORS errors

- Update CORS origins in terraform.tfvars
- Apply terraform changes
- Clear browser cache

## Testing

```powershell
# Test custom domain
Invoke-RestMethod -Uri "https://api.vaardesigns.com/health" -Method GET

# Test query
$body = @{
    query = "What is Medicare Part A?"
} | ConvertTo-Json

Invoke-RestMethod -Uri "https://api.vaardesigns.com/query" -Method POST -Body $body -ContentType "application/json"

# Test from browser
# Open: https://api.vaardesigns.com/health
```

## Next Steps

1. ✅ Run `terraform apply` to create custom domain
2. ✅ Wait 10-15 minutes for certificate validation
3. ✅ Test `https://api.vaardesigns.com/health`
4. ✅ Update your UI to use new API URL
5. ✅ Deploy UI changes

## Rollback

If you want to remove the custom domain:

```powershell
# Comment out or delete custom_domain.tf
# Then apply
terraform apply

# Or just use the default API Gateway URL
```

The old API Gateway URL will continue to work even after setting up custom domain.
