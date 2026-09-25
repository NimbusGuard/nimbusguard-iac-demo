# =============================================================================
#  NimbusGuard IaC scanning demo — AWS (Terraform)
#
#  ⚠️  DEMO ONLY. None of this is applied to any cloud account. Every resource
#  below is DELIBERATELY misconfigured so NimbusGuard's shift-left scanner
#  flags it at PR time, against the SAME control catalog it uses at runtime.
#  The control ID each resource trips is noted in its comment.
#
#  A few hardened resources at the bottom show the PASS side.
# =============================================================================

# ── NG-AWS-S3-001 — bucket open to the public (Block Public Access disabled) ──
resource "aws_s3_bucket" "customer_exports" {
  bucket = "acme-customer-exports-demo"
  tags = {
    environment         = "prod"
    data_classification = "confidential"
  }
}

resource "aws_s3_bucket_public_access_block" "customer_exports" {
  bucket                  = aws_s3_bucket.customer_exports.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# ── NG-AWS-EC2-001 — SSH (22) open to the entire internet ────────────────────
resource "aws_security_group" "bastion" {
  name        = "bastion-sg"
  description = "bastion host"

  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { environment = "prod" }
}

# ── NG-AWS-RDS-001 / -002 — publicly reachable AND unencrypted database ───────
resource "aws_db_instance" "orders" {
  identifier          = "orders-primary"
  engine              = "postgres"
  instance_class      = "db.t3.medium"
  allocated_storage   = 50
  publicly_accessible = true
  storage_encrypted   = false
  tags                = { environment = "prod" }
}

# ── NG-AWS-KMS-001 — customer key without automatic rotation ─────────────────
resource "aws_kms_key" "app_data" {
  description         = "application data key"
  enable_key_rotation = true
  tags                = { environment = "prod" }
}

# ── NG-AWS-CLOUDTRAIL-001 — audit trail that isn't actually logging ──────────
resource "aws_cloudtrail" "org_trail" {
  name           = "org-trail"
  s3_bucket_name = "acme-cloudtrail-demo"
  enable_logging = false
  tags           = { environment = "prod" }
}

# ── NG-AWS-EBS — unencrypted volume ──────────────────────────────────────────
resource "aws_ebs_volume" "app_data" {
  availability_zone = "us-east-1a"
  size              = 100
  encrypted         = false
  tags              = { environment = "prod" }
}

# ── NG-AWS-IAM-012 — role with full AdministratorAccess attached ─────────────
resource "aws_iam_role" "ci_deployer" {
  name               = "ci-deployer"
  assume_role_policy = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
  tags               = { environment = "prod" }
}

resource "aws_iam_role_policy_attachment" "ci_deployer_admin" {
  role       = aws_iam_role.ci_deployer.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# ── NG-AWS-IAM-008 / -009 / -010 — weak account password policy ──────────────
resource "aws_iam_account_password_policy" "this" {
  minimum_password_length      = 6
  require_symbols              = false
  require_numbers              = false
  require_uppercase_characters = false
  require_lowercase_characters = false
  max_password_age             = 0
}

# ── NG-AWS-SNS-001 — topic without KMS encryption ────────────────────────────
resource "aws_sns_topic" "alerts" {
  name = "billing-alerts"
  tags = { environment = "prod" }
}

# ── NG-AWS-SQS-001 — queue without encryption ────────────────────────────────
resource "aws_sqs_queue" "jobs" {
  name = "background-jobs"
  tags = { environment = "prod" }
}

# ── NG-AWS-ECR-001 / -002 — mutable tags, no scan-on-push ────────────────────
resource "aws_ecr_repository" "api" {
  name                 = "acme/api"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = false
  }

  tags = { environment = "prod" }
}

# ── NG-AWS-EFS-001 — unencrypted file system ─────────────────────────────────
resource "aws_efs_file_system" "shared" {
  creation_token = "shared-fs"
  encrypted      = false
  tags           = { environment = "prod" }
}

# ── NG-AWS-DYNAMODB — no point-in-time recovery, no deletion protection ──────
resource "aws_dynamodb_table" "sessions" {
  name         = "sessions"
  hash_key     = "id"
  billing_mode = "PAY_PER_REQUEST"

  attribute {
    name = "id"
    type = "S"
  }

  tags = { environment = "prod" }
}

# ── NG-AWS-SAGEMAKER — root access + direct internet on a notebook ───────────
resource "aws_sagemaker_notebook_instance" "research" {
  name                   = "research-nb"
  instance_type          = "ml.t3.medium"
  role_arn               = "arn:aws:iam::123456789012:role/sm"
  root_access            = "Enabled"
  direct_internet_access = "Enabled"
  tags                   = { environment = "prod" }
}

# ── NG-AWS-EC2-011 — IMDSv2 not enforced (metadata_options.http_tokens = optional) ──
resource "aws_instance" "app" {
  ami           = "ami-0abcdef1234567890"
  instance_type = "t3.small"

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "optional"
  }

  tags = { environment = "prod" }
}

# =============================================================================
#  Hardened resources — these PASS. NimbusGuard blesses good IaC too, so a
#  clean PR isn't blocked and the report shows what "right" looks like.
# =============================================================================

# ── PASS — private bucket, Block Public Access fully on ──────────────────────
resource "aws_s3_bucket" "internal_logs" {
  bucket = "acme-internal-logs-demo"
  tags   = { environment = "prod" }
}

resource "aws_s3_bucket_public_access_block" "internal_logs" {
  bucket                  = aws_s3_bucket.internal_logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ── PASS — SSH restricted to the corporate CIDR ──────────────────────────────
resource "aws_security_group" "internal_ssh" {
  name = "internal-ssh-sg"

  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["10.0.0.0/8"]
  }

  tags = { environment = "prod" }
}

# ── PASS — key with rotation enabled ─────────────────────────────────────────
resource "aws_kms_key" "logs" {
  description         = "log encryption key"
  enable_key_rotation = true
  tags                = { environment = "prod" }
}
