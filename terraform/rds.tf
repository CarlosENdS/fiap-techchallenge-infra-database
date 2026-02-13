# rds.tf - RDS PostgreSQL for Car Garage (Monolito + OS Service)

# ==============================================================================
# DATABASE VARIABLES
# ==============================================================================

locals {
  # Main database (monolito cargarage) - default database created by RDS
  db_name     = "cargarage"
  db_username = "postgres"
  db_password = "Cargarage2024!" # Educational environment - use AWS Secrets Manager in production
  
  # OS Service database (will be created via provisioner)
  os_service_db_name     = "os_service_db"
  os_service_db_username = "os_service_user"
  os_service_db_password = "OsService2024!"
}

# ==============================================================================
# SUBNET GROUP
# ==============================================================================

resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet-group-${var.environment}"
  subnet_ids = data.terraform_remote_state.k8s.outputs.private_subnet_ids

  tags = {
    Name        = "${var.project_name}-db-subnet-group-${var.environment}"
    Type        = "database"
    Environment = var.environment
  }
}

# ==============================================================================
# SECURITY GROUP
# ==============================================================================

resource "aws_security_group" "rds_sg" {
  name        = "${var.project_name}-rds-sg-${var.environment}"
  vpc_id      = data.terraform_remote_state.k8s.outputs.vpc_id
  description = "Security group for PostgreSQL RDS - Car Garage (Monolito + Microservices)"

  # Allow access from EKS nodes
  ingress {
    description     = "PostgreSQL from EKS nodes"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [data.terraform_remote_state.k8s.outputs.eks_nodes_security_group_id]
  }

  # Allow access from within VPC (for DB init job)
  ingress {
    description = "PostgreSQL from VPC"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [data.terraform_remote_state.k8s.outputs.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-rds-sg-${var.environment}"
    Type        = "database"
    Service     = "cargarage"
    Environment = var.environment
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ==============================================================================
# RDS INSTANCE - Optimized for educational/low-cost environment
# ==============================================================================

resource "aws_db_instance" "postgres" {
  identifier = "${var.project_name}-postgres-${var.environment}"
  
  # Engine configuration
  engine         = "postgres"
  engine_version = "16.4"
  
  # Instance size - smallest available for cost optimization
  instance_class = "db.t3.micro"
  
  # Storage - minimal for educational purposes
  allocated_storage     = 20
  max_allocated_storage = 50 # Auto-scaling limit
  storage_type          = "gp2"
  
  # Database configuration (default database = cargarage monolito)
  db_name  = local.db_name
  username = local.db_username
  password = local.db_password
  port     = 5432
  
  # Network configuration
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  publicly_accessible    = false
  
  # Backup configuration - minimal for educational
  backup_retention_period = 1
  backup_window           = "03:00-04:00"
  maintenance_window      = "Mon:04:00-Mon:05:00"
  
  # Performance Insights - disabled for cost
  performance_insights_enabled = false
  
  # Encryption - enabled for best practices
  storage_encrypted = true
  
  # Snapshot configuration
  skip_final_snapshot       = true
  delete_automated_backups  = true
  copy_tags_to_snapshot     = true
  
  # Multi-AZ - disabled for cost optimization (educational)
  multi_az = false

  tags = {
    Name        = "${var.project_name}-postgres-${var.environment}"
    Type        = "database"
    Service     = "cargarage,os-service"
    Environment = var.environment
  }
}

# ==============================================================================
# DATABASE INITIALIZATION
# ==============================================================================
# The databases (cargarage and os_service_db) are initialized via Kubernetes Jobs
# managed by Terraform. See: db-init.tf
#
# Jobs executed in order:
# 1. cargarage-db-seed: Seeds the cargarage database (monolith)
# 2. os-service-db-init: Creates os_service_db database and user
# 3. os-service-db-seed: Seeds the os_service_db (microservice)
#
# SQL Scripts:
# - scripts/seed-cargarage.sql: Schema and data for monolith
# - scripts/init-os-service-db.sql: Creates database and user
# - scripts/seed-os-service.sql: Schema and data for os-service microservice
# ==============================================================================


