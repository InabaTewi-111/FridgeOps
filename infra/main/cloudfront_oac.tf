resource "aws_cloudfront_origin_access_control" "static" {
  name                              = "${local.project}-${local.env}-static-oac"
  description                       = "OAC for private S3 static bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}