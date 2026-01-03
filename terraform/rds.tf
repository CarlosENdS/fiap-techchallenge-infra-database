# rds.tf

# Grupo de Subnets para o RDS (Usando as privadas do Repo 1)
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet-group-${var.environment}"
  subnet_ids = data.terraform_remote_state.k8s.outputs.public_subnet_ids

  tags = {
    Name = "${var.project_name}-db-subnet-group-${var.environment}"
    Type = "database"
  }
}

# Security Group do Banco de Dados
resource "aws_security_group" "rds_sg" {
  name        = "${var.project_name}-rds-sg-${var.environment}"
  vpc_id      = data.terraform_remote_state.k8s.outputs.vpc_id
  description = "Acesso ao Postgres"

  # Regra de entrada: Apenas o SG dos Nodes do EKS pode conectar na porta 5432
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [data.terraform_remote_state.k8s.outputs.eks_nodes_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-rds-sg-${var.environment}"
    Type = "database"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Instância do RDS
resource "aws_db_instance" "postgres" {
  identifier           = "${var.project_name}-postgres-${var.environment}"
  engine               = "postgres"
  engine_version       = "16.4"
  instance_class       = "db.t3.micro"
  allocated_storage     = 20
  db_name              = "cargarage"
  username             = "postgres"
  password             = "Cargarage2024!" # Em prod, use uma secret!
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  skip_final_snapshot    = true
  publicly_accessible    = false 

  tags = {
    Name = "${var.project_name}-postgres-${var.environment}"
    Type = "database"
  }
}

