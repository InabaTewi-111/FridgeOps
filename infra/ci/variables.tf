variable "github_repo" {
  description = "GitHub repository in OWNER/REPO format"
  type        = string
}

variable "github_ref" {
  description = "Git reference to allow (e.g. refs/heads/main)"
  type        = string
  default     = "refs/heads/main"
}
