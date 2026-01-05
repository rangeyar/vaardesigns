# ECR Repository for Lambda Container
resource "aws_ecr_repository" "lambda_repo" {
  name                 = local.function_name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = local.common_tags
}

# ECR Lifecycle Policy
resource "aws_ecr_lifecycle_policy" "lambda_repo_policy" {
  repository = aws_ecr_repository.lambda_repo.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 5 images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 5
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# Lambda Function
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
      AWS_REGION             = var.aws_region
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

  # Prevent deployment before image is pushed
  lifecycle {
    ignore_changes = [image_uri]
  }
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${local.function_name}"
  retention_in_days = 7

  tags = local.common_tags
}

# Outputs
output "lambda_function_name" {
  description = "Lambda function name"
  value       = aws_lambda_function.api.function_name
}

output "lambda_function_arn" {
  description = "Lambda function ARN"
  value       = aws_lambda_function.api.arn
}

output "ecr_repository_url" {
  description = "ECR repository URL"
  value       = aws_ecr_repository.lambda_repo.repository_url
}
