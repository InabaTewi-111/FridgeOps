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