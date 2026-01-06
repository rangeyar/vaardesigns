terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Variables
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "health-assistant"
}

variable "organization" {
  description = "Organization name"
  type        = string
  default     = "vaardesigns"
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
  default     = "prod"
}

variable "domain_name" {
  description = "Root domain name"
  type        = string
  default     = "vaardesigns.com"
}

variable "openai_api_key" {
  description = "OpenAI API key"
  type        = string
  sensitive   = true
}

variable "s3_bucket_name" {
  description = "S3 bucket name for vector store"
  type        = string
  default     = "vaardesigns-health-assistant"
}

variable "cors_origins" {
  description = "CORS origins for API Gateway"
  type        = string
  default     = "https://vaardesigns.com,https://www.vaardesigns.com"
}

variable "create_healthassistant_subdomain" {
  description = "Create healthassistant.vaardesigns.com subdomain (in addition to api.vaardesigns.com)"
  type        = bool
  default     = false
}

# Locals
locals {
  function_name = "${var.organization}-${var.project_name}-${var.environment}"
  api_subdomain = "api.${var.domain_name}"
  common_tags = {
    Project      = var.project_name
    Organization = var.organization
    Environment  = var.environment
    ManagedBy    = "Terraform"
  }
}
