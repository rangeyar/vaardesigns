# GitHub Actions IAM User and Permissions
# This manages the IAM user for GitHub Actions CI/CD

# Data source: Get existing IAM user (if it exists)
# Use this if the user was created manually
data "aws_iam_user" "github_actions" {
  user_name = "github-actions-vaar-ui-deploy"
}

# Policy: ECR Access (for Docker image push/pull)
resource "aws_iam_policy" "github_actions_ecr" {
  name        = "GitHubActionsECRPolicy"
  path        = "/ci-cd/"
  description = "Allows GitHub Actions to push/pull Docker images to/from ECR"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ECRAuthentication"
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken"
        ]
        Resource = "*"
      },
      {
        Sid    = "ECRPushPull"
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:DescribeRepositories",
          "ecr:ListImages",
          "ecr:DescribeImages"
        ]
        Resource = aws_ecr_repository.lambda_repo.arn
      }
    ]
  })

  tags = local.common_tags
}

# Policy: Lambda Access (for function updates)
resource "aws_iam_policy" "github_actions_lambda" {
  name        = "GitHubActionsLambdaPolicy"
  path        = "/ci-cd/"
  description = "Allows GitHub Actions to update Lambda functions"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "LambdaUpdate"
        Effect = "Allow"
        Action = [
          "lambda:UpdateFunctionCode",
          "lambda:GetFunction",
          "lambda:GetFunctionConfiguration",
          "lambda:UpdateFunctionConfiguration"
        ]
        Resource = aws_lambda_function.api.arn
      },
      {
        Sid    = "APIGatewayRead"
        Effect = "Allow"
        Action = [
          "apigatewayv2:GET",
          "apigatewayv2:GetApis"
        ]
        Resource = "*"
      }
    ]
  })

  tags = local.common_tags
}

# Policy: Terraform State Access (S3 + DynamoDB)
resource "aws_iam_policy" "github_actions_terraform_state" {
  name        = "GitHubActionsTerraformStatePolicy"
  path        = "/ci-cd/"
  description = "Allows GitHub Actions to access Terraform state in S3 and DynamoDB"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "TerraformStateS3Access"
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = [
          "arn:aws:s3:::vaardesigns-terraform-state",
          "arn:aws:s3:::vaardesigns-terraform-state/*"
        ]
      },
      {
        Sid    = "TerraformStateLockDynamoDB"
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem",
          "dynamodb:DescribeTable"
        ]
        Resource = "arn:aws:dynamodb:${var.aws_region}:${data.aws_caller_identity.current.account_id}:table/vaardesigns-terraform-lock"
      }
    ]
  })

  tags = local.common_tags
}

# Data source to get current AWS account ID
data "aws_caller_identity" "current" {}

# Attach ECR policy to existing user
resource "aws_iam_user_policy_attachment" "github_actions_ecr" {
  user       = data.aws_iam_user.github_actions.user_name
  policy_arn = aws_iam_policy.github_actions_ecr.arn
}

# Attach Lambda policy to existing user
resource "aws_iam_user_policy_attachment" "github_actions_lambda" {
  user       = data.aws_iam_user.github_actions.user_name
  policy_arn = aws_iam_policy.github_actions_lambda.arn
}

# Attach Terraform state policy to existing user
resource "aws_iam_user_policy_attachment" "github_actions_terraform_state" {
  user       = data.aws_iam_user.github_actions.user_name
  policy_arn = aws_iam_policy.github_actions_terraform_state.arn
}

# Output policy ARNs for reference
output "github_actions_policies" {
  description = "IAM policies attached to GitHub Actions user"
  value = {
    ecr_policy_arn             = aws_iam_policy.github_actions_ecr.arn
    lambda_policy_arn          = aws_iam_policy.github_actions_lambda.arn
    terraform_state_policy_arn = aws_iam_policy.github_actions_terraform_state.arn
    user_name                  = data.aws_iam_user.github_actions.user_name
  }
}
