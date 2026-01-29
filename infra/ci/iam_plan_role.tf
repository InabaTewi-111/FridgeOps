# --- Context helpers (avoid hardcoding account/region) ---
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  github_oidc_host = replace(local.github_oidc_url, "https://", "")
  tfstate_bucket   = "fridgeops-dev-tfstate-fd25e7e4"
  lock_table_name  = "fridgeops-dev-tf-lock"
}

# --- Trust policy: allow GitHub Actions OIDC to assume this role (restricted by repo/ref) ---
data "aws_iam_policy_document" "github_actions_assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github_actions.arn]
    }

    # audience must be STS
    condition {
      test     = "StringEquals"
      variable = "${local.github_oidc_host}:aud"
      values   = ["sts.amazonaws.com"]
    }

    # sub claim restriction:
    # - push to main: repo:OWNER/REPO:ref:refs/heads/main
    # - pull_request: repo:OWNER/REPO:pull_request
    condition {
      test     = "StringLike"
      variable = "${local.github_oidc_host}:sub"
      values = [
        "repo:${var.github_repo}:ref:${var.github_ref}",
        "repo:${var.github_repo}:pull_request",
      ]
    }
  }
}

resource "aws_iam_role" "tf_plan" {
  name                 = "fridgeops-ci-tf-plan"
  description          = "GitHub Actions OIDC role for terraform plan (AWS ReadOnly + tfstate/lock access)"
  assume_role_policy   = data.aws_iam_policy_document.github_actions_assume_role.json
  max_session_duration = 3600
}

# --- AWS resources: read-only (for plan/refresh) ---
resource "aws_iam_role_policy_attachment" "tf_plan_readonly" {
  role       = aws_iam_role.tf_plan.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

# --- Terraform backend access: S3 state + DynamoDB lock (needs write even for plan/refresh) ---
data "aws_iam_policy_document" "tf_backend_access" {
  statement {
    sid       = "ListStateBucket"
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::${local.tfstate_bucket}"]
  }

  statement {
    sid = "StateObjectRW"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject"
    ]
    resources = [
      "arn:aws:s3:::${local.tfstate_bucket}/ci/*",
      "arn:aws:s3:::${local.tfstate_bucket}/main/*"
    ]
  }

  statement {
    sid = "DynamoDBLockRW"
    actions = [
      "dynamodb:DescribeTable",
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:DeleteItem",
      "dynamodb:UpdateItem"
    ]
    resources = [
      "arn:aws:dynamodb:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:table/${local.lock_table_name}"
    ]
  }
}

resource "aws_iam_policy" "tf_backend_access" {
  name   = "fridgeops-ci-tf-backend-access"
  policy = data.aws_iam_policy_document.tf_backend_access.json
}

resource "aws_iam_role_policy_attachment" "tf_plan_backend_access" {
  role       = aws_iam_role.tf_plan.name
  policy_arn = aws_iam_policy.tf_backend_access.arn
}

output "tf_plan_role_arn" {
  description = "IAM role ARN assumed by GitHub Actions via OIDC"
  value       = aws_iam_role.tf_plan.arn
}
