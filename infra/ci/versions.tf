terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }

  # Remote state (bootstrapで作成済みのS3/DynamoDBを利用)
  backend "s3" {
    bucket         = "fridgeops-dev-tfstate-fd25e7e4"
    key            = "ci/terraform.tfstate"
    region         = "ap-northeast-1"
    dynamodb_table = "fridgeops-dev-tf-lock"
    encrypt        = true
  }
}
