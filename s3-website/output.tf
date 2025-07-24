output "file_hash" {
  value = filemd5("${path.module}/index.html")
}

output "website_endpoint" {
  value = aws_s3_bucket_website_configuration.my_website.website_endpoint
}