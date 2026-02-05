resource "aws_dynamodb_table" "items" {
  name         = "${local.project}-${local.env}-items"
  billing_mode = "PAY_PER_REQUEST"

  hash_key = "id"

  attribute {
    name = "id"
    type = "S"
  }

  server_side_encryption {
    enabled = true
  }

  ttl {
    attribute_name = "expiresAt"
    enabled        = true
  }

  tags = {
    Project = local.project
    Env     = local.env
  }
}
