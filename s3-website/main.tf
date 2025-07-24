terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-south-1"
}


resource "aws_s3_bucket" "my_s3_bucket_for_website" {
    bucket = "flash-web"
    tags = {
        Name: "My Static Web site buckcet"
    }
}

resource "aws_s3_bucket_public_access_block" "public_access" {
    bucket = aws_s3_bucket.my_s3_bucket_for_website.id
    block_public_acls = false
    block_public_policy = false
}


resource "aws_s3_object" "index_file_upload" {
  bucket = aws_s3_bucket.my_s3_bucket_for_website.bucket
  key = "index.html"
  source = "${path.module}/index.html"
  source_hash = filemd5("${path.module}/index.html")
  content_type = "text/html"
}

resource "aws_s3_object" "error_file_upload" {
  bucket = aws_s3_bucket.my_s3_bucket_for_website.bucket
  key = "error.html"
  source = "${path.module}/error.html"
  source_hash = filemd5("${path.module}/error.html")
  content_type = "text/html"
}

resource "aws_s3_bucket_website_configuration" "my_website" {
  bucket = aws_s3_bucket.my_s3_bucket_for_website.id
  index_document {
    suffix = "index.html"
  }
  error_document {
    key = "error.html"
  }
}
resource "aws_s3_bucket_policy" "my_custom_public_policy" {
    bucket = aws_s3_bucket.my_s3_bucket_for_website.id
    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = ["s3:GetObject"]
        Resource  = "${aws_s3_bucket.my_s3_bucket_for_website.arn}/*"
        }]
  })
}
