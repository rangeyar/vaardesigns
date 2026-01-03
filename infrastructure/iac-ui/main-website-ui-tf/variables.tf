variable "domain_name" {
  description = "The domain name for the website"
  type        = string
  default     = "vaardesigns.com"
}

variable "www_domain_name" {
  description = "The www subdomain"
  type        = string
  default     = "www.vaardesigns.com"
}

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "price_class" {
  description = "CloudFront distribution price class"
  type        = string
  default     = "PriceClass_100"
}
