# Website Hosting with S3, CloudFront, and Route53

This Terraform configuration sets up a complete website hosting infrastructure on AWS for **arvashu.com**.

## Architecture

- **S3**: Static website hosting
- **CloudFront**: CDN for global content delivery with HTTPS
- **Route53**: DNS management
- **ACM**: SSL/TLS certificate for HTTPS

## Features

✅ HTTPS enabled with automatic SSL certificate  
✅ WWW to root domain redirect  
✅ IPv6 support  
✅ Global CDN distribution  
✅ Custom error pages  
✅ Gzip compression  
✅ Bucket versioning enabled

## File Structure

```
.
├── providers.tf      # Terraform and AWS provider configuration
├── variables.tf      # Input variables
├── data.tf          # Data sources (Route53 zone)
├── s3.tf            # S3 bucket resources
├── acm.tf           # ACM certificate and validation
├── cloudfront.tf    # CloudFront distributions
├── route53.tf       # DNS records
├── outputs.tf       # Output values
└── README.md        # This file
```

## Prerequisites

1. AWS CLI configured with appropriate credentials
2. Terraform >= 1.0 installed
3. Route53 hosted zone for `arvashu.com` already created in AWS

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
aws s3 sync ./your-website-folder s3://arvashu.com
```

### 5. Invalidate CloudFront Cache (when updating content)

```powershell
aws cloudfront create-invalidation --distribution-id <DISTRIBUTION_ID> --paths "/*"
```

## Variables

You can customize the deployment by modifying `variables.tf` or creating a `terraform.tfvars` file:

```hcl
domain_name     = "arvashu.com"
www_domain_name = "www.arvashu.com"
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
- Both `arvashu.com` and `www.arvashu.com` will work (www redirects to root)

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
