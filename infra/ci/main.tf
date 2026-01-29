# GitHub Actions OIDC endpoint
locals {
  github_oidc_url = "https://token.actions.githubusercontent.com"
}

# Fetch cert chain and compute SHA1 thumbprint automatically
data "tls_certificate" "github_actions" {
  url = local.github_oidc_url
}

# IAM OIDC Provider for GitHub Actions
resource "aws_iam_openid_connect_provider" "github_actions" {
  url = local.github_oidc_url

  # AWS STS is the audience for AssumeRoleWithWebIdentity
  client_id_list = ["sts.amazonaws.com"]

  # Use the first certificate's SHA1 fingerprint (computed by tls provider)
  thumbprint_list = [data.tls_certificate.github_actions.certificates[0].sha1_fingerprint]
}
