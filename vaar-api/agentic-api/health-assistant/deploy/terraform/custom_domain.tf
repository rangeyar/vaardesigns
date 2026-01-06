# Custom Domain for API Gateway

# Data source to fetch existing Route53 hosted zone
data "aws_route53_zone" "main" {
  name         = var.domain_name
  private_zone = false
}

# Request ACM certificate for API subdomain
resource "aws_acm_certificate" "api" {
  domain_name       = "healthassistant.${var.domain_name}"
  validation_method = "DNS"

  subject_alternative_names = [
    "api.${var.domain_name}" # Optional: if you want both domains
  ]

  tags = merge(
    local.common_tags,
    {
      Name = "${var.organization}-api-certificate"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# Create DNS records for certificate validation
resource "aws_route53_record" "api_cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.api.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.main.zone_id
}

# Wait for certificate validation
resource "aws_acm_certificate_validation" "api" {
  certificate_arn         = aws_acm_certificate.api.arn
  validation_record_fqdns = [for record in aws_route53_record.api_cert_validation : record.fqdn]
}

# Create custom domain for API Gateway
resource "aws_apigatewayv2_domain_name" "api" {
  domain_name = "healthassistant.${var.domain_name}"

  domain_name_configuration {
    certificate_arn = aws_acm_certificate.api.arn
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
  }

  depends_on = [aws_acm_certificate_validation.api]

  tags = merge(
    local.common_tags,
    {
      Name = "${var.organization}-api-domain"
    }
  )
}

# Map custom domain to API Gateway stage
resource "aws_apigatewayv2_api_mapping" "api" {
  api_id      = aws_apigatewayv2_api.api.id
  domain_name = aws_apigatewayv2_domain_name.api.id
  stage       = aws_apigatewayv2_stage.default.id
}

# Create Route53 A record pointing to API Gateway custom domain
resource "aws_route53_record" "api" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "healthassistant.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_apigatewayv2_domain_name.api.domain_name_configuration[0].target_domain_name
    zone_id                = aws_apigatewayv2_domain_name.api.domain_name_configuration[0].hosted_zone_id
    evaluate_target_health = false
  }
}

# Optional: Create CNAME for api subdomain (points to healthassistant subdomain)
resource "aws_route53_record" "api_alias" {
  count   = var.create_healthassistant_subdomain ? 1 : 0
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "api.${var.domain_name}"
  type    = "CNAME"
  ttl     = 300
  records = ["healthassistant.${var.domain_name}"]
}

# Outputs
output "custom_domain_url" {
  description = "Custom domain URL for API"
  value       = "https://healthassistant.${var.domain_name}"
}

output "api_certificate_arn" {
  description = "ARN of ACM certificate"
  value       = aws_acm_certificate.api.arn
}

output "api_domain_name" {
  description = "API Gateway custom domain name"
  value       = aws_apigatewayv2_domain_name.api.domain_name
}
