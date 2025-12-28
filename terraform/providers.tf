terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  cloud {
    organization = "fiap-soat-techchallenge"
    workspaces {
      name = "fiap-techchallenge-infra-database" # Novo workspace
    }
  }
}

provider "aws" {
  region = var.aws_region 

  default_tags {
    tags = {
      Project     = "CarGarage"
      Environment = var.environment
      ManagedBy   = "Terraform"
      Team        = "FIAP-TechChallenge"
      Repository  = "fiap-techchallenge-cargarage"
    }
  }
}