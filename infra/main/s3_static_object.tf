resource "aws_s3_object" "index_html" {
  bucket = aws_s3_bucket.static.id
  key    = "index.html"

  # Always upload the file we ship with infra/main
  source = "${path.module}/index.html"

  content_type = "text/html; charset=utf-8"

  # Force Terraform to notice changes in the file content
  etag = filemd5("${path.module}/index.html")
}

