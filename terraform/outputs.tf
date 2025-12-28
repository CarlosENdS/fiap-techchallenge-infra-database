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