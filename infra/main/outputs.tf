output "static_bucket_name" {
  description = "Private S3 bucket for static site origin (used by CloudFront OAC)"
  value       = aws_s3_bucket.static.bucket
}
