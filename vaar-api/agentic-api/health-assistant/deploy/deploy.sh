#!/bin/bash

# Health Assistant Deployment Script
# This script builds and deploys the Lambda container to AWS

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
AWS_REGION=${AWS_REGION:-us-east-1}
ENVIRONMENT=${ENVIRONMENT:-dev}
PROJECT_NAME="health-assistant"

echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}Health Assistant Deployment Script${NC}"
echo -e "${GREEN}================================================${NC}"

# Check prerequisites
echo -e "\n${YELLOW}Checking prerequisites...${NC}"

if ! command -v aws &> /dev/null; then
    echo -e "${RED}Error: AWS CLI not found. Please install it first.${NC}"
    exit 1
fi

if ! command -v docker &> /dev/null; then
    echo -e "${RED}Error: Docker not found. Please install it first.${NC}"
    exit 1
fi

if ! command -v terraform &> /dev/null; then
    echo -e "${RED}Error: Terraform not found. Please install it first.${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Prerequisites check passed${NC}"

# Get AWS account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo -e "${GREEN}AWS Account ID: ${AWS_ACCOUNT_ID}${NC}"

# Navigate to terraform directory
cd "$(dirname "$0")/terraform"

# Initialize Terraform
echo -e "\n${YELLOW}Initializing Terraform...${NC}"
terraform init

# Apply Terraform (create infrastructure)
echo -e "\n${YELLOW}Deploying infrastructure...${NC}"
terraform apply -auto-approve

# Get ECR repository URL
ECR_REPO=$(terraform output -raw ecr_repository_url)
echo -e "${GREEN}ECR Repository: ${ECR_REPO}${NC}"

# Navigate back to project root
cd ../..

# Login to ECR
echo -e "\n${YELLOW}Logging in to ECR...${NC}"
aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

# Build Docker image
echo -e "\n${YELLOW}Building Docker image...${NC}"
docker build -t ${PROJECT_NAME}:latest .

# Tag image for ECR
echo -e "\n${YELLOW}Tagging image...${NC}"
docker tag ${PROJECT_NAME}:latest ${ECR_REPO}:latest

# Push to ECR
echo -e "\n${YELLOW}Pushing image to ECR...${NC}"
docker push ${ECR_REPO}:latest

# Update Lambda function
echo -e "\n${YELLOW}Updating Lambda function...${NC}"
LAMBDA_FUNCTION=$(cd deploy/terraform && terraform output -raw lambda_function_name)
aws lambda update-function-code \
    --function-name ${LAMBDA_FUNCTION} \
    --image-uri ${ECR_REPO}:latest \
    --region ${AWS_REGION}

# Wait for Lambda update to complete
echo -e "\n${YELLOW}Waiting for Lambda update to complete...${NC}"
aws lambda wait function-updated \
    --function-name ${LAMBDA_FUNCTION} \
    --region ${AWS_REGION}

# Get API Gateway URL
API_URL=$(cd deploy/terraform && terraform output -raw api_gateway_url)

echo -e "\n${GREEN}================================================${NC}"
echo -e "${GREEN}Deployment completed successfully!${NC}"
echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}API URL: ${API_URL}${NC}"
echo -e "${GREEN}Test with: curl ${API_URL}/health${NC}"
echo -e "${GREEN}================================================${NC}"
