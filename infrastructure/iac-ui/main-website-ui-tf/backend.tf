# Terraform Backend Configuration
# This configures remote state storage in S3 with DynamoDB locking

terraform {
  backend "s3" {
    bucket         = "vaardesigns-terraform-state"
    key            = "website/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "vaardesigns-terraform-lock"
    encrypt        = true
  }
}
