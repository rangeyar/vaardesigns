# This resource builds and pushes Docker image before Lambda creation
# NOTE: This is DISABLED for CI/CD - GitHub Actions handles Docker builds
# For local deployment without Docker Desktop: build manually (see FIRST_DEPLOY.md)

# Uncomment this block ONLY if you want Terraform to build Docker locally
/*
resource "null_resource" "build_and_push_image" {
  # Trigger rebuild when these files change
  triggers = {
    dockerfile_hash = filemd5("${path.module}/../../Dockerfile")
    requirements    = filemd5("${path.module}/../../requirements.txt")
    app_code        = sha1(join("", [for f in fileset("${path.module}/../../app", "**/*.py") : filesha1("${path.module}/../../app/${f}")]))
  }

  # Build and push Docker image
  provisioner "local-exec" {
    command     = <<-EOT
      # Get AWS account ID and region
      $AWS_ACCOUNT_ID = (aws sts get-caller-identity --query Account --output text)
      $AWS_REGION = "${var.aws_region}"
      $ECR_REPO = "${aws_ecr_repository.lambda_repo.repository_url}"
      
      Write-Host "Building Docker image..."
      docker build -t ${local.function_name}:latest ${path.module}/../..
      
      Write-Host "Logging into ECR..."
      aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REPO
      
      Write-Host "Tagging image..."
      docker tag ${local.function_name}:latest $ECR_REPO:latest
      
      Write-Host "Pushing to ECR..."
      docker push $ECR_REPO:latest
    EOT
    interpreter = ["PowerShell", "-Command"]
  }

  depends_on = [aws_ecr_repository.lambda_repo]
}
*/

# Update Lambda function to depend on image being pushed
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

  # Wait for IAM policies to be attached
  depends_on = [
    # null_resource.build_and_push_image,  # Disabled - image built via GitHub Actions or manual build
    aws_iam_role_policy_attachment.lambda_basic,
    aws_iam_role_policy.lambda_s3_policy
  ]

  # Prevent re-deployment when image updates (handled separately)
  lifecycle {
    ignore_changes = [image_uri]
  }
}
