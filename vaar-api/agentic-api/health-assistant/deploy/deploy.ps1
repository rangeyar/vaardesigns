# Health Assistant Deployment Script (PowerShell)
# This script builds and deploys the Lambda container to AWS

param(
    [string]$AwsRegion = "us-east-1",
    [string]$Environment = "dev",
    [string]$ProjectName = "health-assistant"
)

$ErrorActionPreference = "Stop"

Write-Host "================================================" -ForegroundColor Green
Write-Host "Health Assistant Deployment Script" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Green

# Check prerequisites
Write-Host "`nChecking prerequisites..." -ForegroundColor Yellow

if (!(Get-Command aws -ErrorAction SilentlyContinue)) {
    Write-Host "Error: AWS CLI not found. Please install it first." -ForegroundColor Red
    exit 1
}

if (!(Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Host "Error: Docker not found. Please install it first." -ForegroundColor Red
    exit 1
}

if (!(Get-Command terraform -ErrorAction SilentlyContinue)) {
    Write-Host "Error: Terraform not found. Please install it first." -ForegroundColor Red
    exit 1
}

Write-Host "✓ Prerequisites check passed" -ForegroundColor Green

# Get AWS account ID
$AwsAccountId = aws sts get-caller-identity --query Account --output text
Write-Host "AWS Account ID: $AwsAccountId" -ForegroundColor Green

# Navigate to terraform directory
Push-Location "$PSScriptRoot\terraform"

# Initialize Terraform
Write-Host "`nInitializing Terraform..." -ForegroundColor Yellow
terraform init

# Apply Terraform (create infrastructure)
Write-Host "`nDeploying infrastructure..." -ForegroundColor Yellow
terraform apply -auto-approve

# Get ECR repository URL
$EcrRepo = terraform output -raw ecr_repository_url
Write-Host "ECR Repository: $EcrRepo" -ForegroundColor Green

# Navigate back to project root
Pop-Location
Push-Location "$PSScriptRoot\.."

# Login to ECR
Write-Host "`nLogging in to ECR..." -ForegroundColor Yellow
aws ecr get-login-password --region $AwsRegion | docker login --username AWS --password-stdin "$AwsAccountId.dkr.ecr.$AwsRegion.amazonaws.com"

# Build Docker image
Write-Host "`nBuilding Docker image..." -ForegroundColor Yellow
docker build -t "${ProjectName}:latest" .

# Tag image for ECR
Write-Host "`nTagging image..." -ForegroundColor Yellow
docker tag "${ProjectName}:latest" "${EcrRepo}:latest"

# Push to ECR
Write-Host "`nPushing image to ECR..." -ForegroundColor Yellow
docker push "${EcrRepo}:latest"

# Update Lambda function
Write-Host "`nUpdating Lambda function..." -ForegroundColor Yellow
Push-Location "$PSScriptRoot\terraform"
$LambdaFunction = terraform output -raw lambda_function_name
Pop-Location

aws lambda update-function-code `
    --function-name $LambdaFunction `
    --image-uri "${EcrRepo}:latest" `
    --region $AwsRegion

# Wait for Lambda update to complete
Write-Host "`nWaiting for Lambda update to complete..." -ForegroundColor Yellow
aws lambda wait function-updated `
    --function-name $LambdaFunction `
    --region $AwsRegion

# Get API Gateway URL
Push-Location "$PSScriptRoot\terraform"
$ApiUrl = terraform output -raw api_gateway_url
Pop-Location

Pop-Location

Write-Host "`n================================================" -ForegroundColor Green
Write-Host "Deployment completed successfully!" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Green
Write-Host "API URL: $ApiUrl" -ForegroundColor Green
Write-Host "Test with: curl $ApiUrl/health" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Green
