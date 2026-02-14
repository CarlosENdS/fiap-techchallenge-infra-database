# dynamodb.tf - DynamoDB Tables for Billing Service
# Same pattern as RDS/SQS for OS Service: one Terraform in infra-database

# ==============================================================================
# BUDGETS TABLE
# ==============================================================================

resource "aws_dynamodb_table" "billing_budgets" {
  name         = "billing-service-budgets"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "budgetId"

  attribute {
    name = "budgetId"
    type = "S"
  }

  attribute {
    name = "serviceOrderId"
    type = "S"
  }

  global_secondary_index {
    name            = "ServiceOrderIndex"
    hash_key        = "serviceOrderId"
    projection_type = "ALL"
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled = true
  }

  tags = {
    Name        = "billing-service-budgets"
    Service     = "billing-service"
    Type        = "database"
    Environment = var.environment
  }
}

# ==============================================================================
# PAYMENTS TABLE
# ==============================================================================

resource "aws_dynamodb_table" "billing_payments" {
  name         = "billing-service-payments"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "paymentId"

  attribute {
    name = "paymentId"
    type = "S"
  }

  attribute {
    name = "budgetId"
    type = "S"
  }

  attribute {
    name = "serviceOrderId"
    type = "S"
  }

  global_secondary_index {
    name            = "BudgetIndex"
    hash_key        = "budgetId"
    projection_type = "ALL"
  }

  global_secondary_index {
    name            = "ServiceOrderIndex"
    hash_key        = "serviceOrderId"
    projection_type = "ALL"
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled = true
  }

  tags = {
    Name        = "billing-service-payments"
    Service     = "billing-service"
    Type        = "database"
    Environment = var.environment
  }
}
