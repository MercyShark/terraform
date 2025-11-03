provider "aws" {
  region  = "ap-south-1"
  profile = "sova-profile"
}

resource "aws_s3_bucket" "public_bucket" {
  bucket = "my-public-bucket-rishabh-demo"
    
  tags = {
    Name        = "PrivateBucket"
    Environment = "Dev"
  }
}

resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket = aws_s3_bucket.public_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "private_policy" {
  bucket = aws_s3_bucket.public_bucket.id
    
  depends_on = [aws_s3_bucket_public_access_block.public_access]
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowIAMRootAccess"
        Effect    = "Allow"
        Principal = {
          AWS = "arn:aws:iam::905418130401:root"
        }
        Action    = "s3:*"
        Resource  = [
          aws_s3_bucket.public_bucket.arn,
          "${aws_s3_bucket.public_bucket.arn}/*"
        ]
      }
    ]
  })
}

output "s3_endpoint" {
  value = aws_s3_bucket.public_bucket.bucket_domain_name
}