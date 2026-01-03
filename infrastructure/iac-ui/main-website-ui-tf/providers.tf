terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "Website Hosting"
      Domain      = var.domain_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}
