terraform {
  backend "s3" {
    bucket         = "vaardesigns-terraform-state"
    key            = "health-assistant/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "vaardesigns-terraform-lock"
    encrypt        = true
  }
}
