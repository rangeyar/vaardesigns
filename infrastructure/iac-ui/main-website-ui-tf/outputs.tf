# S3 Outputs
output "website_bucket_name" {
  description = "Name of the S3 bucket hosting the website"
  value       = aws_s3_bucket.website.id
}

output "website_bucket_arn" {
  description = "ARN of the S3 bucket hosting the website"
  value       = aws_s3_bucket.website.arn
}

output "website_bucket_endpoint" {
  description = "S3 website endpoint"
  value       = aws_s3_bucket_website_configuration.website.website_endpoint
}

# CloudFront Outputs
output "cloudfront_distribution_id" {
  description = "ID of the CloudFront distribution"
  value       = aws_cloudfront_distribution.website.id
}

output "cloudfront_distribution_arn" {
  description = "ARN of the CloudFront distribution"
  value       = aws_cloudfront_distribution.website.arn
}

output "cloudfront_domain_name" {
  description = "Domain name of the CloudFront distribution"
  value       = aws_cloudfront_distribution.website.domain_name
}

output "www_cloudfront_distribution_id" {
  description = "ID of the WWW CloudFront distribution"
  value       = aws_cloudfront_distribution.www_redirect.id
}

# ACM Outputs
output "acm_certificate_arn" {
  description = "ARN of the ACM certificate"
  value       = aws_acm_certificate.website.arn
}

output "acm_certificate_status" {
  description = "Status of the ACM certificate"
  value       = aws_acm_certificate.website.status
}

# Route53 Outputs
output "route53_zone_id" {
  description = "ID of the Route53 hosted zone"
  value       = data.aws_route53_zone.main.zone_id
}

output "route53_name_servers" {
  description = "Name servers for the Route53 hosted zone"
  value       = data.aws_route53_zone.main.name_servers
}

# Website URLs
output "website_url" {
  description = "URL of the website"
  value       = "https://${var.domain_name}"
}

output "www_website_url" {
  description = "URL of the www subdomain"
  value       = "https://${var.www_domain_name}"
}

# Deployment Instructions
output "deployment_instructions" {
  description = "Instructions for deploying website content"
  value       = <<-EOT
    To deploy your website:
    1. Run: aws s3 sync ./your-website-folder s3://${aws_s3_bucket.website.id}
    2. Invalidate CloudFront cache: aws cloudfront create-invalidation --distribution-id ${aws_cloudfront_distribution.website.id} --paths "/*"
    3. Visit: https://${var.domain_name}
  EOT
}
