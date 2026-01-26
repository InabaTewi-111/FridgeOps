terraform {
  backend "s3" {
    bucket         = "fridgeops-dev-tfstate-fd25e7e4"
    key            = "infra/main/terraform.tfstate"
    region         = "ap-northeast-1"
    dynamodb_table = "fridgeops-dev-tf-lock"
    encrypt        = true
  }
}

