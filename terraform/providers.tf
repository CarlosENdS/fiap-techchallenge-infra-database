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

# Provider definido para criação de recursos Kubernetes (para o DB Init Job)
data "aws_eks_cluster" "eks" {
  name = data.terraform_remote_state.k8s.outputs.eks_cluster_name
}

data "aws_eks_cluster_auth" "eks" {
  name = data.terraform_remote_state.k8s.outputs.eks_cluster_name
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.eks.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.eks.token
}