resource "aws_s3_object" "index_html" {
  bucket       = aws_s3_bucket.static.id
  key          = "index.html"
  content_type = "text/html; charset=utf-8"

  content = <<HTML
<!doctype html>
<html lang="zh-CN">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width,initial-scale=1" />
  <title>FridgeOps Static</title>
</head>
<body>
  <h1>FridgeOps Static OK</h1>
  <p>If you see this via CloudFront, OAC + bucket policy is working.</p>
</body>
</html>
HTML
}
