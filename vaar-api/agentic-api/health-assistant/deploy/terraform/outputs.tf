output "all_outputs" {
  description = "All deployment outputs"
  value = {
    api_url           = aws_apigatewayv2_api.api.api_endpoint
    api_custom_domain = "api.${var.domain_name}"
    lambda_function   = aws_lambda_function.api.function_name
    s3_bucket         = aws_s3_bucket.vector_store.id
    ecr_repository    = aws_ecr_repository.lambda_repo.repository_url
    region            = var.aws_region
    organization      = var.organization
    cors_origins      = var.cors_origins
  }
}

output "api_endpoint" {
  description = "API Gateway endpoint URL"
  value       = aws_apigatewayv2_api.api.api_endpoint
}

output "recommended_custom_domain" {
  description = "Recommended custom domain for API"
  value       = "api.${var.domain_name}"
}

output "next_steps" {
  description = "Next steps for setup"
  value       = <<-EOT
    ✅ Infrastructure deployed successfully!
    
    📋 Next Steps:
    1. Upload vector store to S3:
       python ingestion/ingest_docs.py
    
    2. Build and push Docker image:
       cd deploy && .\deploy.ps1
    
    3. Test API Gateway endpoint:
       ${aws_apigatewayv2_api.api.api_endpoint}/health
    
    4. (Optional) Set up custom domain:
       - Create Route53 record for api.${var.domain_name}
       - Point to API Gateway
       - Request ACM certificate
    
    5. Update frontend API URL to:
       ${aws_apigatewayv2_api.api.api_endpoint}
       (or api.${var.domain_name} after custom domain setup)
  EOT
}
