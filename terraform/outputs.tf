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

output "sqs_service_order_events_queue_url" {
  description = "URL of the Service Order Events standard queue (OS -> Billing)"
  value       = aws_sqs_queue.service_order_events.url
}

output "sqs_service_order_events_queue_name" {
  description = "Name of the Service Order Events standard queue"
  value       = aws_sqs_queue.service_order_events.name
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
    SQS_OS_EVENTS_QUEUE_URL         = base64encode(aws_sqs_queue.os_order_events_fifo.url)
    SQS_BILLING_ORDER_EVENTS_URL     = base64encode(aws_sqs_queue.service_order_events.url)
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

# ==============================================================================
# BILLING SERVICE - DynamoDB & SQS
# ==============================================================================

output "billing_dynamodb_budgets_table_name" {
  description = "DynamoDB table name for Billing Service budgets"
  value       = aws_dynamodb_table.billing_budgets.name
}

output "billing_dynamodb_payments_table_name" {
  description = "DynamoDB table name for Billing Service payments"
  value       = aws_dynamodb_table.billing_payments.name
}

output "sqs_billing_events_queue_url" {
  description = "URL of the Billing Events FIFO queue (Billing publishes)"
  value       = aws_sqs_queue.billing_events_fifo.url
}

output "sqs_billing_events_queue_name" {
  description = "Name of the Billing Events queue"
  value       = aws_sqs_queue.billing_events_fifo.name
}

# Billing consumes from the same queue OS publishes to
output "sqs_os_order_events_queue_name" {
  description = "Name of the OS Order Events queue (Billing consumes from this)"
  value       = aws_sqs_queue.os_order_events_fifo.name
}

output "billing_service_irsa_role_arn" {
  description = "IRSA role ARN for Billing Service pods"
  value       = aws_iam_role.billing_service_irsa.arn
}

output "billing_service_k8s_config" {
  description = "Values for Billing Service ConfigMap (queue URLs, table names)"
  value = {
    DYNAMODB_TABLE_BUDGETS              = aws_dynamodb_table.billing_budgets.name
    DYNAMODB_TABLE_PAYMENTS             = aws_dynamodb_table.billing_payments.name
    SQS_QUEUE_SERVICE_ORDER_EVENTS_URL  = aws_sqs_queue.service_order_events.url
    SQS_QUEUE_BILLING_EVENTS_URL        = aws_sqs_queue.billing_events_fifo.url
    SQS_QUEUE_QUOTE_APPROVED_URL        = aws_sqs_queue.quote_approved.url
    SQS_QUEUE_PAYMENT_FAILED_URL        = aws_sqs_queue.payment_failed.url
  }
}

# ==============================================================================
# EXECUTION SERVICE OUTPUTS
# ==============================================================================

output "execution_service_database_name" {
  description = "Execution Service database name"
  value       = local.execution_service_db_name
}

output "execution_service_database_username" {
  description = "Execution Service database username"
  value       = local.execution_service_db_username
  sensitive   = true
}

output "execution_service_jdbc_url" {
  description = "JDBC connection URL for Execution Service"
  value       = "jdbc:postgresql://${aws_db_instance.postgres.endpoint}/${local.execution_service_db_name}"
}

output "execution_service_irsa_role_arn" {
  description = "IRSA role ARN for Execution Service pods"
  value       = aws_iam_role.execution_service_irsa.arn
}

output "sqs_execution_events_queue_url" {
  description = "URL of the Execution Service Events FIFO queue (output)"
  value       = aws_sqs_queue.execution_events_fifo.url
}

output "sqs_execution_events_queue_name" {
  description = "Name of the Execution Service Events FIFO queue"
  value       = aws_sqs_queue.execution_events_fifo.name
}

output "execution_service_k8s_secrets_base64" {
  description = "Base64-encoded values for Execution Service Kubernetes secrets"
  value = {
    DB_URL                         = base64encode("jdbc:postgresql://${aws_db_instance.postgres.endpoint}/${local.execution_service_db_name}")
    DB_USERNAME                    = base64encode(local.execution_service_db_username)
    DB_PASSWORD                    = base64encode(local.execution_service_db_password)
    SQS_EXECUTION_EVENTS_QUEUE_URL = base64encode(aws_sqs_queue.execution_events_fifo.url)
  }
  sensitive = true
}

output "execution_service_k8s_config" {
  description = "Values for Execution Service ConfigMap (queue URLs)"
  value = {
    SQS_EXECUTION_COMPLETED_QUEUE_URL = aws_sqs_queue.execution_completed.url
    SQS_RESOURCE_UNAVAILABLE_QUEUE_URL = aws_sqs_queue.resource_unavailable.url
    SQS_BILLING_EVENTS_QUEUE_URL      = aws_sqs_queue.billing_events_fifo.url
    SQS_OS_EVENTS_QUEUE_URL            = aws_sqs_queue.os_order_events_fifo.url
  }
}