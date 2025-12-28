# data.tf

# Busca o estado remoto do repositório de Kubernetes
data "terraform_remote_state" "k8s" {
  backend = "remote"

  config = {
    organization = "fiap-soat-techchallenge"
    workspaces = {
      name = "fiap-techchallenge-infra-kubernetes" # Nome do workspace que você criou no TFC
    }
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}