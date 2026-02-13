# outputs.tf - Outputs for Car Garage Infrastructure (Monolito + Microservices)

# ==============================================================================
# RDS OUTPUTS (Shared Instance)
# ==============================================================================

output "rds_endpoint" {
  description = "RDS endpoint (host:port)"
  value       = aws_db_instance.postgres.endpoint
}

output "rds_address" {
  description = "RDS address (host only)"
  value       = aws_db_instance.postgres.address
}

output "rds_port" {
  description = "RDS port"
  value       = aws_db_instance.postgres.port
}

# ==============================================================================
# CARGARAGE DATABASE (Monolito)
# ==============================================================================

output "cargarage_database_name" {
  description = "Cargarage (monolito) database name"
  value       = local.db_name
}

output "cargarage_database_username" {
  description = "Cargarage (monolito) database username"
  value       = local.db_username
  sensitive   = true
}

output "cargarage_jdbc_url" {
  description = "JDBC connection URL for Cargarage monolito"
  value       = "jdbc:postgresql://${aws_db_instance.postgres.endpoint}/${local.db_name}"
}

# ==============================================================================
# OS SERVICE DATABASE (Microservice)
# ==============================================================================

output "os_service_database_name" {
  description = "OS Service database name"
  value       = local.os_service_db_name
}

output "os_service_database_username" {
  description = "OS Service database username"
  value       = local.os_service_db_username
  sensitive   = true
}

output "os_service_jdbc_url" {
  description = "JDBC connection URL for OS Service"
  value       = "jdbc:postgresql://${aws_db_instance.postgres.endpoint}/${local.os_service_db_name}"
}

# Legacy outputs for backward compatibility
output "rds_database_name" {
  description = "[DEPRECATED] Use cargarage_database_name or os_service_database_name"
  value       = local.db_name
}

output "rds_username" {
  description = "[DEPRECATED] Use cargarage_database_username"
  value       = local.db_username
  sensitive   = true
}

output "rds_jdbc_url" {
  description = "[DEPRECATED] Use cargarage_jdbc_url"
  value       = "jdbc:postgresql://${aws_db_instance.postgres.endpoint}/${local.db_name}"
}

output "rds_security_group_id" {
  description = "Security group ID for RDS"
  value       = aws_security_group.rds_sg.id
}

# ==============================================================================
# SQS OUTPUTS
# ==============================================================================

output "sqs_os_events_queue_url" {
  description = "URL of the OS Order Events FIFO queue (output)"
  value       = aws_sqs_queue.os_order_events_fifo.url
}

output "sqs_os_events_queue_arn" {
  description = "ARN of the OS Order Events FIFO queue"
  value       = aws_sqs_queue.os_order_events_fifo.arn
}

output "sqs_quote_approved_queue_url" {
  description = "URL of the Quote Approved queue (input)"
  value       = aws_sqs_queue.quote_approved.url
}

output "sqs_quote_approved_queue_name" {
  description = "Name of the Quote Approved queue"
  value       = aws_sqs_queue.quote_approved.name
}

output "sqs_execution_completed_queue_url" {
  description = "URL of the Execution Completed queue (input)"
  value       = aws_sqs_queue.execution_completed.url
}

output "sqs_execution_completed_queue_name" {
  description = "Name of the Execution Completed queue"
  value       = aws_sqs_queue.execution_completed.name
}

output "sqs_payment_failed_queue_url" {
  description = "URL of the Payment Failed queue (compensation)"
  value       = aws_sqs_queue.payment_failed.url
}

output "sqs_payment_failed_queue_name" {
  description = "Name of the Payment Failed queue"
  value       = aws_sqs_queue.payment_failed.name
}

output "sqs_resource_unavailable_queue_url" {
  description = "URL of the Resource Unavailable queue (compensation)"
  value       = aws_sqs_queue.resource_unavailable.url
}

output "sqs_resource_unavailable_queue_name" {
  description = "Name of the Resource Unavailable queue"
  value       = aws_sqs_queue.resource_unavailable.name
}

# ==============================================================================
# IAM OUTPUTS
# ==============================================================================

output "os_service_irsa_role_arn" {
  description = "IRSA role ARN for OS Service pods"
  value       = aws_iam_role.os_service_irsa.arn
}

output "github_actions_role_arn" {
  description = "IAM role ARN for GitHub Actions CD pipeline"
  value       = aws_iam_role.github_actions.arn
}

# ==============================================================================
# NETWORK OUTPUTS (from remote state)
# ==============================================================================

output "vpc_id" {
  description = "VPC ID where resources are deployed"
  value       = data.terraform_remote_state.k8s.outputs.vpc_id
}

output "eks_cluster_name" {
  description = "EKS cluster name for kubectl configuration"
  value       = data.terraform_remote_state.k8s.outputs.eks_cluster_name
}

# ==============================================================================
# KUBERNETES SECRETS HELPER
# ==============================================================================

output "cargarage_k8s_secrets_base64" {
  description = "Base64-encoded values for Cargarage (monolito) Kubernetes secrets"
  value = {
    DB_URL      = base64encode("jdbc:postgresql://${aws_db_instance.postgres.endpoint}/${local.db_name}")
    DB_USERNAME = base64encode(local.db_username)
    DB_PASSWORD = base64encode(local.db_password)
  }
  sensitive = true
}

output "os_service_k8s_secrets_base64" {
  description = "Base64-encoded values for OS Service Kubernetes secrets"
  value = {
    DB_URL      = base64encode("jdbc:postgresql://${aws_db_instance.postgres.endpoint}/${local.os_service_db_name}")
    DB_USERNAME = base64encode(local.os_service_db_username)
    DB_PASSWORD = base64encode(local.os_service_db_password)
    SQS_OS_EVENTS_QUEUE_URL = base64encode(aws_sqs_queue.os_order_events_fifo.url)
  }
  sensitive = true
}

# Legacy output for backward compatibility
output "k8s_secrets_base64" {
  description = "[DEPRECATED] Use cargarage_k8s_secrets_base64 or os_service_k8s_secrets_base64"
  value = {
    DB_URL      = base64encode("jdbc:postgresql://${aws_db_instance.postgres.endpoint}/${local.db_name}")
    DB_USERNAME = base64encode(local.db_username)
    DB_PASSWORD = base64encode(local.db_password)
    SQS_OS_EVENTS_QUEUE_URL = base64encode(aws_sqs_queue.os_order_events_fifo.url)
  }
  sensitive = true
}