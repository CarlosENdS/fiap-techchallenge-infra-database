# iam.tf - IAM Roles for OS Service (IRSA - IAM Roles for Service Accounts)
# Allows EKS pods to access AWS services (SQS, RDS) without explicit credentials

# ==============================================================================
# DATA SOURCES
# ==============================================================================

data "aws_caller_identity" "current" {}

data "aws_iam_openid_connect_provider" "eks" {
  url = data.terraform_remote_state.k8s.outputs.eks_cluster_oidc_issuer_url
}

# ==============================================================================
# IAM ROLE FOR OS-SERVICE (IRSA)
# ==============================================================================

# Trust policy for IRSA - allows EKS service account to assume role
data "aws_iam_policy_document" "os_service_assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.eks.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(data.terraform_remote_state.k8s.outputs.eks_cluster_oidc_issuer_url, "https://", "")}:sub"
      values   = ["system:serviceaccount:os-service:os-service-sa"]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(data.terraform_remote_state.k8s.outputs.eks_cluster_oidc_issuer_url, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "os_service_irsa" {
  name               = "os-service-irsa-role"
  assume_role_policy = data.aws_iam_policy_document.os_service_assume_role.json

  tags = {
    Name        = "os-service-irsa-role"
    Service     = "os-service"
    Environment = var.environment
  }
}

# ==============================================================================
# SQS POLICY - Allow OS Service to send/receive messages
# ==============================================================================

data "aws_iam_policy_document" "os_service_sqs" {
  # Allow sending messages to FIFO queue (output events)
  statement {
    sid    = "AllowSendToFifoQueue"
    effect = "Allow"
    actions = [
      "sqs:SendMessage",
      "sqs:GetQueueUrl",
      "sqs:GetQueueAttributes"
    ]
    resources = [
      aws_sqs_queue.os_order_events_fifo.arn
    ]
  }

  # Allow receiving messages from standard queues (input events)
  statement {
    sid    = "AllowReceiveFromStandardQueues"
    effect = "Allow"
    actions = [
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueUrl",
      "sqs:GetQueueAttributes",
      "sqs:ChangeMessageVisibility"
    ]
    resources = [
      aws_sqs_queue.quote_approved.arn,
      aws_sqs_queue.execution_completed.arn,
      aws_sqs_queue.payment_failed.arn,
      aws_sqs_queue.resource_unavailable.arn
    ]
  }

  # Allow listing queues (needed for Spring Cloud AWS auto-discovery)
  statement {
    sid    = "AllowListQueues"
    effect = "Allow"
    actions = [
      "sqs:ListQueues"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "os_service_sqs" {
  name        = "os-service-sqs-policy"
  description = "Allow OS Service to access SQS queues"
  policy      = data.aws_iam_policy_document.os_service_sqs.json

  tags = {
    Name        = "os-service-sqs-policy"
    Service     = "os-service"
    Environment = var.environment
  }
}

resource "aws_iam_role_policy_attachment" "os_service_sqs" {
  role       = aws_iam_role.os_service_irsa.name
  policy_arn = aws_iam_policy.os_service_sqs.arn
}

# ==============================================================================
# ECR POLICY - Allow pulling images
# ==============================================================================

data "aws_iam_policy_document" "os_service_ecr" {
  statement {
    sid    = "AllowECRPull"
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "os_service_ecr" {
  name        = "os-service-ecr-policy"
  description = "Allow OS Service to pull images from ECR"
  policy      = data.aws_iam_policy_document.os_service_ecr.json

  tags = {
    Name        = "os-service-ecr-policy"
    Service     = "os-service"
    Environment = var.environment
  }
}

resource "aws_iam_role_policy_attachment" "os_service_ecr" {
  role       = aws_iam_role.os_service_irsa.name
  policy_arn = aws_iam_policy.os_service_ecr.arn
}

# ==============================================================================
# GITHUB ACTIONS ROLE - For CD Pipeline
# ==============================================================================

data "aws_iam_policy_document" "github_actions_assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    principals {
      type        = "Federated"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      # Allow from your GitHub organization/repository
      values   = ["repo:fiap-soat-techchallenge/*:*"]
    }
  }
}

resource "aws_iam_role" "github_actions" {
  name               = "github-actions-deploy-role"
  assume_role_policy = data.aws_iam_policy_document.github_actions_assume_role.json

  tags = {
    Name        = "github-actions-deploy-role"
    Purpose     = "CD Pipeline"
    Environment = var.environment
  }
}

# Policy for GitHub Actions - ECR push and EKS deploy
data "aws_iam_policy_document" "github_actions_deploy" {
  # ECR permissions
  statement {
    sid    = "ECRAuth"
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "ECRPush"
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:PutImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload"
    ]
    resources = [data.terraform_remote_state.k8s.outputs.ecr_repository_arn]
  }

  # EKS permissions
  statement {
    sid    = "EKSDescribe"
    effect = "Allow"
    actions = [
      "eks:DescribeCluster",
      "eks:ListClusters"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "github_actions_deploy" {
  name        = "github-actions-deploy-policy"
  description = "Allow GitHub Actions to deploy to EKS via ECR"
  policy      = data.aws_iam_policy_document.github_actions_deploy.json

  tags = {
    Name        = "github-actions-deploy-policy"
    Purpose     = "CD Pipeline"
    Environment = var.environment
  }
}

resource "aws_iam_role_policy_attachment" "github_actions_deploy" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.github_actions_deploy.arn
}

# ==============================================================================
# IAM ROLE FOR BILLING-SERVICE (IRSA) - Same pattern as OS Service
# ==============================================================================

data "aws_iam_policy_document" "billing_service_assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.eks.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(data.terraform_remote_state.k8s.outputs.eks_cluster_oidc_issuer_url, "https://", "")}:sub"
      values   = ["system:serviceaccount:billing-service:billing-service-sa"]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(data.terraform_remote_state.k8s.outputs.eks_cluster_oidc_issuer_url, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "billing_service_irsa" {
  name               = "billing-service-irsa-role"
  assume_role_policy = data.aws_iam_policy_document.billing_service_assume_role.json

  tags = {
    Name        = "billing-service-irsa-role"
    Service     = "billing-service"
    Environment = var.environment
  }
}

# DynamoDB policy - Billing Service tables
data "aws_iam_policy_document" "billing_service_dynamodb" {
  statement {
    sid    = "AllowDynamoDBBudgets"
    effect = "Allow"
    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
      "dynamodb:DeleteItem",
      "dynamodb:Query",
      "dynamodb:BatchGetItem",
      "dynamodb:BatchWriteItem",
      "dynamodb:DescribeTable"
    ]
    resources = [
      aws_dynamodb_table.billing_budgets.arn,
      "${aws_dynamodb_table.billing_budgets.arn}/index/*"
    ]
  }

  statement {
    sid    = "AllowDynamoDBPayments"
    effect = "Allow"
    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
      "dynamodb:DeleteItem",
      "dynamodb:Query",
      "dynamodb:BatchGetItem",
      "dynamodb:BatchWriteItem",
      "dynamodb:DescribeTable"
    ]
    resources = [
      aws_dynamodb_table.billing_payments.arn,
      "${aws_dynamodb_table.billing_payments.arn}/index/*"
    ]
  }
}

resource "aws_iam_policy" "billing_service_dynamodb" {
  name        = "billing-service-dynamodb-policy"
  description = "Allow Billing Service to access DynamoDB tables"
  policy      = data.aws_iam_policy_document.billing_service_dynamodb.json

  tags = {
    Name        = "billing-service-dynamodb-policy"
    Service     = "billing-service"
    Environment = var.environment
  }
}

resource "aws_iam_role_policy_attachment" "billing_service_dynamodb" {
  role       = aws_iam_role.billing_service_irsa.name
  policy_arn = aws_iam_policy.billing_service_dynamodb.arn
}

# SQS policy - Billing consumes from os-order-events, publishes to billing-events
data "aws_iam_policy_document" "billing_service_sqs" {
  # Consume from OS output queue (Billing receives ORDER_CREATED)
  statement {
    sid    = "AllowReceiveFromOsEvents"
    effect = "Allow"
    actions = [
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueUrl",
      "sqs:GetQueueAttributes",
      "sqs:ChangeMessageVisibility"
    ]
    resources = [aws_sqs_queue.os_order_events_fifo.arn]
  }

  # Publish to Billing output queue
  statement {
    sid    = "AllowSendToBillingEvents"
    effect = "Allow"
    actions = [
      "sqs:SendMessage",
      "sqs:GetQueueUrl",
      "sqs:GetQueueAttributes"
    ]
    resources = [aws_sqs_queue.billing_events_fifo.arn]
  }

  statement {
    sid    = "AllowListQueues"
    effect = "Allow"
    actions = ["sqs:ListQueues"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "billing_service_sqs" {
  name        = "billing-service-sqs-policy"
  description = "Allow Billing Service to access SQS queues"
  policy      = data.aws_iam_policy_document.billing_service_sqs.json

  tags = {
    Name        = "billing-service-sqs-policy"
    Service     = "billing-service"
    Environment = var.environment
  }
}

resource "aws_iam_role_policy_attachment" "billing_service_sqs" {
  role       = aws_iam_role.billing_service_irsa.name
  policy_arn = aws_iam_policy.billing_service_sqs.arn
}

# ECR policy - Billing Service pull images
data "aws_iam_policy_document" "billing_service_ecr" {
  statement {
    sid    = "AllowECRPull"
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "billing_service_ecr" {
  name        = "billing-service-ecr-policy"
  description = "Allow Billing Service to pull images from ECR"
  policy      = data.aws_iam_policy_document.billing_service_ecr.json

  tags = {
    Name        = "billing-service-ecr-policy"
    Service     = "billing-service"
    Environment = var.environment
  }
}

resource "aws_iam_role_policy_attachment" "billing_service_ecr" {
  role       = aws_iam_role.billing_service_irsa.name
  policy_arn = aws_iam_policy.billing_service_ecr.arn
}
