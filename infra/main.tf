# Tutorial Avanzado de DevSecOps — Terraform con misconfigurations intencionales
# Estos recursos tienen 5 problemas que deberás corregir en el Paso 6.

terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# ✅SOLUCIÓN 1: Bucket privado con versioning y cifrado:
resource "aws_s3_bucket_versioning" "app_data" {
  bucket = aws_s3_bucket.app_data.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "app_data" {
  bucket = aws_s3_bucket.app_data.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}

# ✅SOLUCIÓN 3: Base de datos privada y cifrada
resource "aws_db_instance" "app_db" {
  identifier          = "${var.project_name}-db-${var.environment}"
  engine              = "mysql"
  engine_version      = "8.0"
  instance_class      = "db.t3.micro"
  allocated_storage   = 20
  db_name             = "appdb"
  username            = "admin"
  password            = var.db_password
  skip_final_snapshot = true
  publicly_accessible = false
  storage_encrypted   = true
  kms_key_id          = aws_kms_key.rds.arn
  tags = var.common_tags
}

# ✅SOLUCIÓN: Security group con reglas específicas
resource "aws_security_group" "web_sg" {
  name        = "${var.project_name}-web-sg"
  description = "Security group for web application servers"

  # ✅ Corregido: solo HTTPS desde internet
  ingress {
    description = "HTTPS desde internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # Sin regla de ingress para los puertos 0-65535
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.common_tags
}
