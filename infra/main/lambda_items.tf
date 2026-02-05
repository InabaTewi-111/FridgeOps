data "archive_file" "lambda_items_zip" {
  type        = "zip"
  source_dir  = abspath("${path.module}/../../workload/lambda/items")
  output_path = "${path.module}/.terraform/lambda_items.zip"
}

resource "aws_lambda_function" "items" {
  function_name = "${local.project}-${local.env}-items"
  runtime       = "python3.11"
  handler       = "handler.handler"

  role             = aws_iam_role.lambda_items.arn
  filename         = data.archive_file.lambda_items_zip.output_path
  source_code_hash = data.archive_file.lambda_items_zip.output_base64sha256

  timeout     = 10
  memory_size = 128

  environment {
    variables = {
      ITEMS_TABLE_NAME = aws_dynamodb_table.items.name
    }
  }
}
