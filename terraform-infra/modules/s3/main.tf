terraform {
  required_version = ">= 1.9.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.80"
    }
  }
}

resource "aws_s3_bucket" "main" {
  count = var.bucket_name != null && var.bucket_name != "" ? 1 : 0

  bucket        = var.bucket_name
  force_destroy = var.force_destroy
  tags          = var.tags
}

resource "aws_s3_bucket_versioning" "main" {
  count = var.bucket_name != null && var.bucket_name != "" ? 1 : 0

  bucket = aws_s3_bucket.main[0].id
  versioning_configuration {
    status = var.versioning_enabled ? "Enabled" : "Suspended"
  }
}

resource "aws_s3_bucket_encryption" "main" {
  count = var.bucket_name != null && var.bucket_name != "" ? 1 : 0

  bucket = aws_s3_bucket.main[0].id
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm     = var.sse_algorithm
        kms_master_key_id = var.kms_key_id
      }
    }
  }
}

resource "aws_s3_bucket_public_access_block" "main" {
  count = var.bucket_name != null && var.bucket_name != "" ? 1 : 0

  bucket = aws_s3_bucket.main[0].id

  block_public_acls       = var.block_public_acls
  block_public_policy     = var.block_public_policy
  ignore_public_acls      = var.ignore_public_acls
  restrict_public_buckets = var.restrict_public_buckets
}
