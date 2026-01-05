# Docker Image Build
# 
# NOTE: Automated Docker build is DISABLED in this Terraform configuration.
# 
# Docker images are built and pushed via GitHub Actions workflows:
# - .github/workflows/deploy-health-assistant-api.yml (for API code changes)
# - .github/workflows/terraform-deploy-health-assistant.yml (for infrastructure changes)
#
# For manual deployment, see QUICK_START.md for instructions on:
# 1. Pushing code to GitHub (GitHub Actions builds Docker image)
# 2. Running terraform apply (uses pre-built image from ECR)
#
# Lambda function definition below assumes Docker image already exists in ECR

# Lambda function configuration
resource "aws_lambda_function" "api" {
  function_name = local.function_name
  role          = aws_iam_role.lambda_role.arn
  package_type  = "Image"
  image_uri     = "${aws_ecr_repository.lambda_repo.repository_url}:latest"

  timeout     = 60
  memory_size = 1024

  environment {
    variables = {
      OPENAI_API_KEY         = var.openai_api_key
      S3_BUCKET_NAME         = aws_s3_bucket.vector_store.id
      VECTOR_INDEX_KEY       = "faiss_index/health_insurance.index"
      ENVIRONMENT            = var.environment
      LOG_LEVEL              = "INFO"
      CORS_ORIGINS           = var.cors_origins
      OPENAI_MODEL           = "gpt-4o-mini"
      OPENAI_EMBEDDING_MODEL = "text-embedding-3-small"
      TEMPERATURE            = "0.7"
      MAX_TOKENS             = "1000"
      CHUNK_SIZE             = "1000"
      CHUNK_OVERLAP          = "200"
      TOP_K_RESULTS          = "4"
    }
  }

  tags = local.common_tags

  # Wait for IAM policies to be attached before creating Lambda
  depends_on = [
    aws_iam_role_policy_attachment.lambda_basic,
    aws_iam_role_policy.lambda_s3_policy
  ]

  # Prevent re-deployment when image updates
  # Image updates are handled by GitHub Actions workflows
  lifecycle {
    ignore_changes = [image_uri]
  }
}
