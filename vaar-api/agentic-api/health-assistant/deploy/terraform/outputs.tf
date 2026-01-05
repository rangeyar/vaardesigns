output "all_outputs" {
  description = "All deployment outputs"
  value = {
    api_url         = aws_apigatewayv2_api.api.api_endpoint
    lambda_function = aws_lambda_function.api.function_name
    s3_bucket       = aws_s3_bucket.vector_store.id
    ecr_repository  = aws_ecr_repository.lambda_repo.repository_url
    region          = var.aws_region
  }
}
