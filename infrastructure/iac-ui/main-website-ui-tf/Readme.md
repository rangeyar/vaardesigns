# Website Hosting with S3, CloudFront, and Route53

This Terraform configuration sets up a complete website hosting infrastructure on AWS for **vaardesigns.com**.

## Architecture

- **S3**: Static website hosting
- **CloudFront**: CDN for global content delivery with HTTPS
- **Route53**: DNS management
- **ACM**: SSL/TLS certificate for HTTPS
- **S3 Backend**: Remote state storage with DynamoDB locking

## Features

✅ HTTPS enabled with automatic SSL certificate  
✅ WWW to root domain redirect  
✅ IPv6 support  
✅ Global CDN distribution  
✅ Custom error pages  
✅ Gzip compression  
✅ Bucket versioning enabled  
✅ Remote state management with S3 + DynamoDB

## File Structure

```
.
├── providers.tf         # Terraform and AWS provider configuration
├── backend.tf          # S3 backend configuration for state management
├── variables.tf        # Input variables
├── data.tf            # Data sources (Route53 zone)
├── s3.tf              # S3 bucket resources
├── acm.tf             # ACM certificate and validation
├── cloudfront.tf      # CloudFront distributions
├── route53.tf         # DNS records
├── outputs.tf         # Output values
├── README.md          # This file
├── BACKEND-SETUP.md   # Detailed backend setup guide
├── QUICK-START.md     # Quick 5-minute setup guide
└── ROLLBACK-GUIDE.md  # How to rollback to local state
```

## Prerequisites

1. AWS CLI configured with appropriate credentials
2. Terraform >= 1.0 installed
3. Route53 hosted zone for `vaardesigns.com` already created in AWS
4. S3 bucket and DynamoDB table for backend (see setup below)

## 🚀 Quick Setup

### First Time Setup (Backend Configuration)

**Choose your path:**

- **Fast Track** (5 minutes): See `QUICK-START.md`
- **Detailed Guide** (10 minutes): See `BACKEND-SETUP.md`

**Summary:**

```powershell
# 1. Create S3 bucket and DynamoDB table (see QUICK-START.md)

# 2. Initialize and migrate state
terraform init -migrate-state

# 3. Verify
terraform plan
```

## Usage

### 1. Initialize Terraform

```powershell
terraform init
```

### 2. Review the Plan

```powershell
terraform plan
```

### 3. Apply Configuration

```powershell
terraform apply
```

**Note**: The initial deployment takes 15-20 minutes due to CloudFront distribution propagation and SSL certificate validation.

### 4. Upload Website Content

```powershell
aws s3 sync ./your-website-folder s3://vaardesigns.com
```

### 5. Invalidate CloudFront Cache (when updating content)

```powershell
aws cloudfront create-invalidation --distribution-id <DISTRIBUTION_ID> --paths "/*"
```

## Variables

You can customize the deployment by modifying `variables.tf` or creating a `terraform.tfvars` file:

```hcl
domain_name     = "vaardesigns.com"
www_domain_name = "www.vaardesigns.com"
aws_region      = "us-east-1"
environment     = "production"
price_class     = "PriceClass_100"
```

## Outputs

After successful deployment, Terraform will output:

- Website URLs
- S3 bucket names
- CloudFront distribution IDs
- ACM certificate ARN
- Route53 name servers
- Deployment instructions

## Important Notes

- ACM certificate **must** be in `us-east-1` region for CloudFront
- Certificate validation may take 5-10 minutes
- DNS propagation can take up to 48 hours
- Both `vaardesigns.com` and `www.vaardesigns.com` will work (www redirects to root)
- State file is stored in S3: `vaardesigns-terraform-state`
- State locking uses DynamoDB: `vaardesigns-terraform-lock`

## Backend Management

### Remote State Location

- **S3 Bucket**: `vaardesigns-terraform-state`
- **State File Path**: `website/terraform.tfstate`
- **DynamoDB Table**: `vaardesigns-terraform-lock`
- **Region**: `us-east-1`

### Working from Different Machines

```powershell
# Clone repo
git clone <your-repo>

# Initialize (downloads state from S3)
terraform init

# Use normally
terraform plan
terraform apply
```

### Rollback to Local State

See `ROLLBACK-GUIDE.md` if you need to revert to local state management.

## Clean Up

To destroy all resources:

```powershell
terraform destroy
```

**Warning**: This will delete all resources including the S3 bucket and its contents!

## Cost Estimate

- S3: ~$0.023 per GB stored + $0.09 per GB transferred
- CloudFront: ~$0.085 per GB transferred (first 10TB)
- Route53: $0.50 per hosted zone per month
- ACM: Free

## Security

- S3 bucket is configured for public read access (required for website hosting)
- HTTPS enforced on all requests
- CloudFront provides DDoS protection

## Support

For issues or questions, refer to AWS documentation:

- [S3 Static Website Hosting](https://docs.aws.amazon.com/AmazonS3/latest/dev/WebsiteHosting.html)
- [CloudFront Documentation](https://docs.aws.amazon.com/cloudfront/)
- [Route53 Documentation](https://docs.aws.amazon.com/route53/)
