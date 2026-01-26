output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID"
  value       = aws_cloudfront_distribution.static.id
}

output "cloudfront_domain_name" {
  description = "CloudFront domain name (open this in browser)"
  value       = aws_cloudfront_distribution.static.domain_name
}
