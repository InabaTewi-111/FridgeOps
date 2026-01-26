variable "aws_region" {
  description = "AWS region where bootstrap resources will be created."
  type        = string
  default     = "ap-northeast-1"
}

variable "project" {
  description = "Project short name used for resource naming."
  type        = string
  default     = "fridgeops"
}

variable "env" {
  description = "Environment name used for resource naming."
  type        = string
  default     = "dev"
}
