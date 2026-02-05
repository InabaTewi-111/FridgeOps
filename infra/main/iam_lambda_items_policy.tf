data "aws_iam_policy_document" "lambda_items_rw" {
  statement {
    sid = "DynamoDBItemsRW"

    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
      "dynamodb:DeleteItem",
      "dynamodb:Query",
      "dynamodb:Scan",
    ]

    resources = [
      aws_dynamodb_table.items.arn
    ]
  }
}
resource "aws_iam_policy" "lambda_items_rw" {
  name   = "${local.project}-${local.env}-lambda-items-rw"
  policy = data.aws_iam_policy_document.lambda_items_rw.json
}
