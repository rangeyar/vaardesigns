# AWS Configuration
aws_region  = "us-east-1"
environment = "prod"

# Organization & Domain
organization = "vaardesigns"
domain_name  = "vaardesigns.com"

# S3 Configuration
s3_bucket_name = "vaardesigns-health-assistant"

# OpenAI Configuration
# Set via environment variable: $env:TF_VAR_openai_api_key = "sk-..."
# openai_api_key = "will be set via environment variable"

# CORS Configuration (your website domains + localhost for development)
cors_origins = "https://vaardesigns.com,https://www.vaardesigns.com,http://localhost:5173,http://localhost:3000"
