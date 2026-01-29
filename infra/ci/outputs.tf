output "github_oidc_provider_arn" {
  description = "IAM OIDC provider ARN for GitHub Actions"
  value       = aws_iam_openid_connect_provider.github_actions.arn
}
