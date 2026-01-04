# This file can be added to your Terraform project at:
# C:\vaardesigns\terraform\vaar-terraform-ui\github-actions-iam.tf
#
# This will create an IAM user specifically for GitHub Actions deployments
# with minimal required permissions.

# IAM User for GitHub Actions
resource "aws_iam_user" "github_actions" {
  name = "github-actions-vaar-ui-deploy"
  path = "/ci-cd/"

  tags = {
    Name        = "GitHub Actions Deploy User"
    Environment = "production"
    ManagedBy   = "Terraform"
    Purpose     = "CI/CD Deployment"
  }
}

# Access key for the user
resource "aws_iam_access_key" "github_actions" {
  user = aws_iam_user.github_actions.name
}

# Policy for S3 deployment
resource "aws_iam_user_policy" "github_actions_s3" {
  name = "VaarUIDeploymentS3Policy"
  user = aws_iam_user.github_actions.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ListS3Bucket"
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ]
        Resource = [
          aws_s3_bucket.website.arn
        ]
      },
      {
        Sid    = "ManageS3Objects"
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:PutObjectAcl"
        ]
        Resource = [
          "${aws_s3_bucket.website.arn}/*"
        ]
      }
    ]
  })
}

# Policy for CloudFront invalidation
resource "aws_iam_user_policy" "github_actions_cloudfront" {
  name = "VaarUIDeploymentCloudFrontPolicy"
  user = aws_iam_user.github_actions.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "CloudFrontInvalidation"
        Effect = "Allow"
        Action = [
          "cloudfront:CreateInvalidation",
          "cloudfront:GetInvalidation",
          "cloudfront:ListInvalidations"
        ]
        Resource = aws_cloudfront_distribution.website.arn
      }
    ]
  })
}

# Outputs (marked as sensitive)
output "github_actions_access_key_id" {
  description = "Access Key ID for GitHub Actions (add to GitHub Secrets)"
  value       = aws_iam_access_key.github_actions.id
  sensitive   = true
}

output "github_actions_secret_access_key" {
  description = "Secret Access Key for GitHub Actions (add to GitHub Secrets)"
  value       = aws_iam_access_key.github_actions.secret
  sensitive   = true
}

output "github_actions_user_arn" {
  description = "ARN of the GitHub Actions IAM user"
  value       = aws_iam_user.github_actions.arn
}

# Instructions output
output "github_actions_setup_instructions" {
  description = "Instructions for setting up GitHub Secrets"
  value       = <<-EOT
    
    ========================================
    GitHub Actions Setup Instructions
    ========================================
    
    Add these secrets to your GitHub repository:
    Settings → Secrets and variables → Actions → New repository secret
    
    1. AWS_ACCESS_KEY_ID
       Value: Run 'terraform output github_actions_access_key_id'
    
    2. AWS_SECRET_ACCESS_KEY
       Value: Run 'terraform output github_actions_secret_access_key'
    
    3. AWS_REGION
       Value: ${data.aws_region.current.name}
    
    4. AWS_S3_BUCKET
       Value: ${aws_s3_bucket.website.id}
    
    5. AWS_CLOUDFRONT_DISTRIBUTION_ID
       Value: ${aws_cloudfront_distribution.website.id}
    
    ========================================
  EOT
}

# Data source to get current region
data "aws_region" "current" {}

# Note: This configuration references:
# - aws_s3_bucket.website (your S3 bucket)
# - aws_cloudfront_distribution.website (your CloudFront distribution)
