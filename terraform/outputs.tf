# outputs.tf (Repositorio Database)

output "rds_endpoint" {
  description = "Endereço de conexão do banco (Host)"
  value       = aws_db_instance.postgres.address
}

output "rds_port" {
  description = "Porta do banco"
  value       = aws_db_instance.postgres.port
}

output "rds_database_name" {
  description = "Nome do schema do banco"
  value       = aws_db_instance.postgres.db_name
}

output "rds_username" {
  description = "Usuario do banco"
  value       = aws_db_instance.postgres.username
}

# String de conexao JDBC completa para facilitar no Java/Spring
output "rds_jdbc_url" {
  description = "URL JDBC pronta para a aplicacao"
  value       = "jdbc:postgresql://${aws_db_instance.postgres.endpoint}/${aws_db_instance.postgres.db_name}"
}

# Security Group ID do RDS (necessário para Lambda acessar)
output "rds_security_group_id" {
  description = "Security group ID for RDS (needed for Lambda access)"
  value       = aws_security_group.rds_sg.id
}

# VPC ID (para referência)
output "vpc_id" {
  description = "VPC ID where RDS is deployed"
  value       = data.terraform_remote_state.k8s.outputs.vpc_id
}

# Subnet IDs (para referência)
output "db_subnet_ids" {
  description = "Subnet IDs where RDS is deployed"
  value       = aws_db_subnet_group.main.subnet_ids
}