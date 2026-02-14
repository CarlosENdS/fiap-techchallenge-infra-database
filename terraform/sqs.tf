# sqs.tf - AWS SQS Queues for OS Service
# These queues support the Saga pattern for distributed transactions

# ==============================================================================
# FIFO QUEUE - Output Events (OS Service publishes lifecycle events)
# ==============================================================================
resource "aws_sqs_queue" "os_order_events_fifo" {
  name                        = "os-order-events-queue.fifo"
  fifo_queue                  = true
  content_based_deduplication = false # We use explicit deduplication IDs
  
  # Message retention: 4 days (default)
  message_retention_seconds = 345600
  
  # Visibility timeout: 30 seconds
  visibility_timeout_seconds = 30
  
  # Receive wait time for long polling (cost optimization)
  receive_wait_time_seconds = 10
  
  # Deduplication scope: per message group
  deduplication_scope   = "messageGroup"
  fifo_throughput_limit = "perMessageGroupId"

  tags = {
    Name        = "os-order-events-queue"
    Service     = "os-service"
    Type        = "output"
    Pattern     = "saga"
    Environment = var.environment
  }
}

# Dead Letter Queue for FIFO events
resource "aws_sqs_queue" "os_order_events_dlq_fifo" {
  name                  = "os-order-events-dlq.fifo"
  fifo_queue            = true
  message_retention_seconds = 1209600 # 14 days

  tags = {
    Name        = "os-order-events-dlq"
    Service     = "os-service"
    Type        = "dlq"
    Environment = var.environment
  }
}

# Redrive policy for FIFO queue
resource "aws_sqs_queue_redrive_policy" "os_order_events_redrive" {
  queue_url = aws_sqs_queue.os_order_events_fifo.id
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.os_order_events_dlq_fifo.arn
    maxReceiveCount     = 3
  })
}

# ==============================================================================
# STANDARD QUEUES - Input Events (OS Service consumes)
# ==============================================================================

# Quote Approved Queue
resource "aws_sqs_queue" "quote_approved" {
  name = "quote-approved-queue"
  
  message_retention_seconds  = 345600 # 4 days
  visibility_timeout_seconds = 30
  receive_wait_time_seconds  = 10

  tags = {
    Name        = "quote-approved-queue"
    Service     = "os-service"
    Type        = "input"
    Pattern     = "saga"
    Environment = var.environment
  }
}

# Execution Completed Queue
resource "aws_sqs_queue" "execution_completed" {
  name = "execution-completed-queue"
  
  message_retention_seconds  = 345600
  visibility_timeout_seconds = 30
  receive_wait_time_seconds  = 10

  tags = {
    Name        = "execution-completed-queue"
    Service     = "os-service"
    Type        = "input"
    Pattern     = "saga"
    Environment = var.environment
  }
}

# Payment Failed Queue (Compensation)
resource "aws_sqs_queue" "payment_failed" {
  name = "payment-failed-queue"
  
  message_retention_seconds  = 345600
  visibility_timeout_seconds = 30
  receive_wait_time_seconds  = 10

  tags = {
    Name        = "payment-failed-queue"
    Service     = "os-service"
    Type        = "compensation"
    Pattern     = "saga"
    Environment = var.environment
  }
}

# Resource Unavailable Queue (Compensation)
resource "aws_sqs_queue" "resource_unavailable" {
  name = "resource-unavailable-queue"
  
  message_retention_seconds  = 345600
  visibility_timeout_seconds = 30
  receive_wait_time_seconds  = 10

  tags = {
    Name        = "resource-unavailable-queue"
    Service     = "os-service"
    Type        = "compensation"
    Pattern     = "saga"
    Environment = var.environment
  }
}

# ==============================================================================
# DLQ for Standard Queues (shared)
# ==============================================================================
resource "aws_sqs_queue" "standard_dlq" {
  name                      = "os-service-standard-dlq"
  message_retention_seconds = 1209600 # 14 days

  tags = {
    Name        = "os-service-standard-dlq"
    Service     = "os-service"
    Type        = "dlq"
    Environment = var.environment
  }
}

# Redrive policies for standard queues
resource "aws_sqs_queue_redrive_policy" "quote_approved_redrive" {
  queue_url = aws_sqs_queue.quote_approved.id
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.standard_dlq.arn
    maxReceiveCount     = 3
  })
}

resource "aws_sqs_queue_redrive_policy" "execution_completed_redrive" {
  queue_url = aws_sqs_queue.execution_completed.id
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.standard_dlq.arn
    maxReceiveCount     = 3
  })
}

resource "aws_sqs_queue_redrive_policy" "payment_failed_redrive" {
  queue_url = aws_sqs_queue.payment_failed.id
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.standard_dlq.arn
    maxReceiveCount     = 3
  })
}

resource "aws_sqs_queue_redrive_policy" "resource_unavailable_redrive" {
  queue_url = aws_sqs_queue.resource_unavailable.id
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.standard_dlq.arn
    maxReceiveCount     = 3
  })
}

# ==============================================================================
# BILLING SERVICE - FIFO Queues (same pattern as OS Service)
# ==============================================================================
# Billing consumes from os-order-events-queue.fifo (already defined above).
# Billing publishes to billing-events.fifo.

# Billing Events FIFO Queue (Billing Service publishes)
resource "aws_sqs_queue" "billing_events_fifo" {
  name                        = "billing-events.fifo"
  fifo_queue                  = true
  content_based_deduplication  = true
  message_retention_seconds   = 345600  # 4 days
  visibility_timeout_seconds  = 300
  receive_wait_time_seconds   = 5

  deduplication_scope   = "messageGroup"
  fifo_throughput_limit = "perMessageGroupId"

  tags = {
    Name        = "billing-events"
    Service     = "billing-service"
    Type        = "output"
    Pattern     = "saga"
    Environment = var.environment
  }
}

# Dead Letter Queue for Billing Events
resource "aws_sqs_queue" "billing_events_dlq_fifo" {
  name                        = "billing-events-dlq.fifo"
  fifo_queue                  = true
  message_retention_seconds   = 1209600 # 14 days

  tags = {
    Name        = "billing-events-dlq"
    Service     = "billing-service"
    Type        = "dlq"
    Environment = var.environment
  }
}

# Redrive policy for Billing Events FIFO
resource "aws_sqs_queue_redrive_policy" "billing_events_redrive" {
  queue_url = aws_sqs_queue.billing_events_fifo.id
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.billing_events_dlq_fifo.arn
    maxReceiveCount     = 3
  })
}
