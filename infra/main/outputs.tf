output "static_bucket_name" {
  description = "Private S3 bucket for static site origin (used by CloudFront OAC)"
  value       = aws_s3_bucket.static.bucket
}

output "items_table_name" {
  value = aws_dynamodb_table.items.name
}

output "lambda_items_role_arn" {
  value = aws_iam_role.lambda_items.arn
}

output "items_lambda_function_name" {
  value = aws_lambda_function.items.function_name
}

output "items_lambda_function_arn" {
  value = aws_lambda_function.items.arn
}

# For v1 frontend: paste this into the Settings input on the CloudFront page
output "api_base_url" {
  description = "HTTP API base endpoint for frontend (paste into Settings)"
  value       = aws_apigatewayv2_api.items.api_endpoint
}
