# New "analytics" service — added in a PR to demonstrate NimbusGuard catching
# misconfigurations before they merge. (Deliberately insecure; never deployed.)

# A public data lake bucket — NG-AWS-S3-001 will flag this at PR time.
resource "aws_s3_bucket" "analytics_lake" {
  bucket = "acme-analytics-lake-demo"
  tags   = { environment = "prod", data_classification = "confidential" }
}

resource "aws_s3_bucket_public_access_block" "analytics_lake" {
  bucket                  = aws_s3_bucket.analytics_lake.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# Postgres exposed to the whole internet — NG-AWS-RDS-001 + unencrypted (-002).
resource "aws_db_instance" "analytics" {
  identifier          = "analytics-db"
  engine              = "postgres"
  instance_class      = "db.t3.large"
  allocated_storage   = 100
  publicly_accessible = true
  storage_encrypted   = false
  tags                = { environment = "prod" }
}
