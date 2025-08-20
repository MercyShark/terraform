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



variable "s3_bucket_name" {
}
variable "acm_certificate_arn" {
  
}

resource "aws_s3_bucket" "my_bucket" {
  bucket = var.s3_bucket_name

  tags = {
    Name = "Bucket for CloudFront CDN With presign url"
  }
}


resource "aws_s3_bucket_policy" "allow_cloudfront" {
  bucket = aws_s3_bucket.my_bucket.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "AllowCloudFrontServicePrincipalRead",
        Effect    = "Allow",
        Principal = {
          Service = "cloudfront.amazonaws.com"
        },
        Action = "s3:GetObject",
        Resource = "${aws_s3_bucket.my_bucket.arn}/*",
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.s3_distribution.arn
          }
        }
      }
    ]
  })
}


locals {
  s3_origin_id = "myS3Origin"
}



resource "aws_s3_object" "index_file_upload" {
  bucket = aws_s3_bucket.my_bucket.id
  key = "index.html"
  source = "${path.module}/index.html"
  source_hash = filemd5("${path.module}/index.html")
  content_type = "text/html"
}



resource "aws_s3_object" "text_file_upload" {
  bucket = aws_s3_bucket.my_bucket.id
  key = "files/hello.txt"
  source = "${path.module}/hello.txt"
  source_hash = filemd5("${path.module}/hello.txt")
}

resource "aws_s3_object" "error_page" {
  bucket = aws_s3_bucket.my_bucket.id
  key = "error.html"
  source = "${path.module}/error.html"
  source_hash = filemd5("${path.module}/error.html")
  content_type = "text/html"
}
resource "aws_cloudfront_origin_access_control" "default" {
  name                              = "s3-oac"
  description                       = "Origin Access Control for S3"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name = aws_s3_bucket.my_bucket.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.default.id
    origin_id = local.s3_origin_id
  }

  aliases = [ "cdn.iamrishabh.tech"]
  comment = "Creating cdn for showing secure content"
  enabled =  true
  is_ipv6_enabled = true

  default_root_object = "index.html"
  viewer_certificate {
    cloudfront_default_certificate = true
    acm_certificate_arn = var.acm_certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  
  custom_error_response {
    error_code = 403
    response_code = 403
    response_page_path = "/error.html"
  }


default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }


  restrictions {
  geo_restriction {
    restriction_type = "whitelist"
    locations = ["IN"] 
  }

  }
    tags = {
    Environment = "development"
  }

  
}

output "cloudfront_url" {
  value = aws_cloudfront_distribution.s3_distribution.domain_name
}

output "cloudfront_distribution_id" {
  value = aws_cloudfront_distribution.s3_distribution.id
}