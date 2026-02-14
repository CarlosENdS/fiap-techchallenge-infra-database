# Infra Database – Banco de Dados, Mensageria e IAM (Amazon RDS, SQS, IAM)

Este repositório é responsável pela **provisão e gerenciamento da infraestrutura de banco de dados, mensageria e IAM** da aplicação do Tech Challenge, utilizando **Amazon RDS (PostgreSQL)**, **Amazon SQS**, **IAM Roles (IRSA)** e **Terraform Cloud**, seguindo práticas de **cloud computing, infraestrutura como código (IaC), segurança e escalabilidade**.

O objetivo deste repositório é garantir **persistência de dados confiável, consistente e segura**, além de **comunicação assíncrona entre microserviços** e **autenticação segura via IRSA**, permitindo que a aplicação opere em nível corporativo, com separação clara de responsabilidades entre infraestrutura, aplicação e autenticação.

---

## 🎯 Objetivo do Repositório (Alinhado ao Tech Challenge)

Atender aos seguintes requisitos do desafio:

- Uso de **Banco de Dados Gerenciado**
- **Mensageria com Amazon SQS** para comunicação assíncrona (Saga Pattern)
- **IAM Roles for Service Accounts (IRSA)** para autenticação segura dos pods
- Infraestrutura provisionada via **Terraform**
- Deploy automatizado em **CI/CD**
- Segurança e isolamento de rede
- Documentação clara das decisões técnicas
- Separação da infraestrutura em repositório dedicado

---

## 📌 Escopo

### O que este repositório faz
- Provisiona um banco **PostgreSQL gerenciado via Amazon RDS** (cargarage + os_service_db)
- Provisiona **DynamoDB** para o **Billing Service** (tabelas budgets e payments)
- Cria recursos de rede necessários para o banco (subnets privadas e security groups)
- Configura backups automáticos e criptografia
- **Provisiona filas SQS para OS Service e Billing Service (Saga Pattern)**
- **Cria IAM Roles para IRSA (os-service e billing-service)**
- **Configura IAM Role para GitHub Actions (CD sem credenciais estáticas)**
- Gerencia variáveis e credenciais de forma segura
- Executa deploy automatizado via Terraform Cloud
- Disponibiliza outputs para integração com a aplicação

### O que este repositório não faz
- Não executa banco de dados em containers
- Não faz deploy da aplicação
- Não gerencia autenticação ou API Gateway
- Não implementa observabilidade (monitoramento é integrado em outro repositório)

---

## 🏗️ Arquitetura da Solução

- **Tipo**: Banco de dados relacional gerenciado
- **Engine**: PostgreSQL
- **Provedor de Nuvem**: AWS
- **Serviço**: Amazon RDS
- **Subnets**: Públicas (ambiente educacional)
- **Acesso**: Restrito a CIDRs internos da VPC
- **Persistência**: Gerenciada pela AWS
- **Backups**: Automáticos
- **Criptografia**: Em repouso

> ⚠️ **Observação**  
> O banco de dados é provisionado em subnets públicas para facilitar conectividade
> em ambiente educacional e evitar gastos com ferramentas da cloud. O acesso é restrito exclusivamente às redes internas
> da VPC, mantendo isolamento lógico. Em um ambiente produtivo, o banco seria
> alocado em subnets privadas.

---

## 🧠 Justificativa da Escolha do Banco de Dados

O PostgreSQL foi escolhido por atender aos requisitos funcionais e não funcionais
da aplicação, além de estar dentro do escopo de bancos conhecidos pelos integrantes do grupo(facilitando o aprendizado do curso):

- Forte suporte a **consistência transacional (ACID)**
- Integridade referencial e modelo relacional robusto
- Ampla adoção no mercado
- Compatibilidade com ORMs e ferramentas modernas
- Disponibilidade como serviço gerenciado na AWS

O uso do Amazon RDS reduz o esforço operacional, delegando à nuvem atividades como
backup, manutenção e recuperação.

---

## 🔐 Segurança

As seguintes práticas de segurança foram adotadas:

- Banco de dados gerenciado (Amazon RDS)
- Controle de acesso via Security Groups
- Liberação de acesso apenas para CIDRs internos
- Credenciais armazenadas fora do código
- Variáveis sensíveis protegidas no Terraform Cloud, exceto a senha do banco para facilitar as integrações por questão de estudo.
- Criptografia de dados em repouso

> ⚠️ **Nota de Arquitetura**  
> Apesar do uso de subnets públicas, o banco não é exposto à internet, pois o
> acesso é limitado às redes internas da VPC. Essa decisão foi adotada para
> simplificação em ambiente educacional.

---

## 🗄️ Inicialização de Dados (Seed)

Por fins de estudo, é liberado um script de inicialização dos dados para facilitar os testes.

```text
terraform/scripts/seed.sql
```

---

## 📨 Amazon SQS – Mensageria para Saga Pattern

Este repositório provisiona filas SQS para comunicação assíncrona entre microserviços, implementando o **Saga Pattern** para transações distribuídas.

### Filas Provisionadas

| Fila | Tipo | Propósito |
|------|------|-----------|
| `os-order-events-queue.fifo` | FIFO | Fila de saída do **os-service**. Também consumida pelo **billing-service** (ORDER_CREATED) |
| `quote-approved-queue` | Standard | Recebe notificação de orçamento aprovado pelo billing-service |
| `execution-completed-queue` | Standard | Recebe notificação de execução concluída pelo execution-service |
| `payment-failed-queue` | Standard | Compensação: notifica falha no pagamento |
| `billing-events.fifo` | FIFO | Fila de saída do **billing-service** (BudgetApproved, PaymentProcessed, etc.) |
| `resource-unavailable-queue` | Standard | Compensação: notifica indisponibilidade de recurso |

### Dead Letter Queues (DLQ)

Todas as filas possuem DLQ configurada com:
- **maxReceiveCount**: 3 tentativas antes de mover para DLQ
- **Retenção**: 14 dias

### Configuração de Otimização de Custos

```hcl
visibility_timeout_seconds = 30    # Timeout de processamento
message_retention_seconds  = 345600 # 4 dias (produção usa 14 dias)
delay_seconds             = 0
max_message_size          = 262144  # 256KB
receive_wait_time_seconds = 0
```

---

## 🔑 IAM Roles – IRSA e GitHub Actions

### IRSA (IAM Roles for Service Accounts)

O repositório configura **IRSA** para autenticação segura dos pods EKS aos serviços AWS, eliminando a necessidade de credenciais estáticas.

#### Role: `os-service-irsa-role`

Permite que pods do os-service acessem:

| Serviço | Permissões |
|---------|------------|
| SQS | SendMessage, ReceiveMessage, DeleteMessage, GetQueueAttributes, GetQueueUrl |
| ECR | GetAuthorizationToken, BatchCheckLayerAvailability, GetDownloadUrlForLayer, BatchGetImage |

**Configuração no Kubernetes:**

```yaml
# k8s/service-account.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: os-service-sa
  namespace: os-service
  annotations:
    eks.amazonaws.com/role-arn: "${OS_SERVICE_IRSA_ROLE_ARN}"
```

#### Role: `billing-service-irsa-role`

Permite que pods do **billing-service** acessem (mesmo padrão do os-service):

| Serviço | Permissões |
|---------|------------|
| DynamoDB | GetItem, PutItem, UpdateItem, DeleteItem, Query, BatchGetItem, BatchWriteItem (tabelas budgets e payments) |
| SQS | ReceiveMessage/DeleteMessage em `os-order-events-queue.fifo`; SendMessage em `billing-events.fifo`; GetQueueUrl, GetQueueAttributes |
| ECR | GetAuthorizationToken, BatchCheckLayerAvailability, GetDownloadUrlForLayer, BatchGetImage |

Arquivos Terraform do Billing: `dynamodb.tf` (tabelas), `sqs.tf` (fila billing-events.fifo + DLQ), `iam.tf` (role + policies), `outputs.tf` (billing_service_irsa_role_arn, billing_dynamodb_*_table_name, sqs_billing_events_queue_*, billing_service_k8s_config).

### GitHub Actions Deploy Role

Role para permitir que GitHub Actions faça push de imagens para ECR e deploy no EKS:

| Permissão | Descrição |
|-----------|-----------|
| ECR | Push de imagens Docker |
| EKS | Describe cluster (para kubectl) |

**Trust Policy:**
- Confia no GitHub OIDC Provider
- Restrito ao repositório: `CarlosENdS/fiap-techchallenge-microservice-os-service`

---

## 📤 Outputs

Após o deploy, são expostos outputs para integração com outros componentes da
arquitetura:

### Banco de Dados
- `db_endpoint` - Endpoint do RDS
- `db_port` - Porta de conexão
- `db_name` - Nome do banco
- `db_instance_identifier` - Identificador da instância

### SQS
- `sqs_os_order_events_queue_url` - URL da fila de eventos FIFO
- `sqs_quote_approved_queue_url` - URL da fila quote-approved
- `sqs_execution_completed_queue_url` - URL da fila execution-completed
- `sqs_payment_failed_queue_url` - URL da fila payment-failed
- `sqs_resource_unavailable_queue_url` - URL da fila resource-unavailable

### IAM
- `os_service_irsa_role_arn` - ARN da role IRSA para os-service
- `github_actions_deploy_role_arn` - ARN da role para GitHub Actions

### Kubernetes Secrets Helper
- `k8s_secrets_yaml` - YAML formatado para criar secrets no K8s

---

## 🚀 Deploy Automatizado com Terraform Cloud

Este repositório utiliza **Terraform Cloud** para executar o provisionamento da
infraestrutura de forma automatizada, garantindo padronização, auditabilidade
e integração com o fluxo de CI/CD.

### Fluxo de Deploy

```text
Merge na branch main
        ↓
Terraform Cloud (Plan)
        ↓
Terraform Cloud (Apply)
        ↓
Amazon RDS provisionado
```

### Configuração do Workspace

- **Tipo**: Version Control Workflow
- **Repositório**: GitHub
- **Diretório de trabalho**: `terraform/`
- **Execução**: Remota (Terraform Cloud)

---

### Variáveis Utilizadas

#### Terraform Variables - Terraform Cloud

- `aws_region`
- `environment`
- `project_name`

#### Environment Variables (sensíveis) - Terraform Cloud

- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
---

## 📤 Outputs

Após o deploy, são expostos outputs para integração com outros componentes da
arquitetura, como:

- Endpoint do banco
- Porta de conexão
- Nome do banco
- Identificador da instância

Esses outputs são consumidos pelo repositório da aplicação e pelas funções
serverless.

---

## 📚 Documentação Arquitetural

As decisões técnicas relacionadas a este repositório estão documentadas em /docs no repositório.
---

## 📎 Contexto do Projeto

Este repositório faz parte de uma solução maior composta por:

- Autenticação Serverless
- API Gateway
- Infraestrutura Kubernetes
- Aplicação principal em Kubernetes
- Monitoramento e observabilidade

## 🔗 Dependências e Premissas de Infraestrutura

Este repositório **depende da infraestrutura de rede previamente provisionada**
pelo repositório de **infraestrutura Kubernetes**, responsável pela criação da
VPC, subnets, tabelas de rotas e demais recursos de rede.

> **Premissa obrigatória**  
> As redes (VPC e subnets) devem estar criadas antes da execução deste repositório,
> pois o banco de dados RDS utiliza **subnets e CIDRs exportados como outputs**
> do repositório de infraestrutura Kubernetes.

A dependência é realizada por meio de **Remote State do Terraform**, garantindo
integração segura e desacoplada entre os repositórios.

---

## 🧩 Repositórios Relacionados ao Projeto

Este repositório faz parte de uma arquitetura maior, organizada em múltiplos
repositórios, cada um com responsabilidade bem definida:

- **Aplicação Principal (Kubernetes)**  
  https://github.com/CarlosENdS/fiap-techchallenge-cargarage

- **OS Service Microservice (Extraído do Monolito)**  
  https://github.com/CarlosENdS/fiap-techchallenge-microservice-os-service

- **Infraestrutura Kubernetes (EKS + Rede + OIDC)**  
  https://github.com/CarlosENdS/fiap-techchallenge-infra-kubernetes

- **Autenticação Serverless (Lambda)**  
  https://github.com/Leonardo-almd/lambda-cargarage-auth

Cada repositório possui pipeline de CI/CD próprio e integra-se aos demais por meio
de outputs e contratos bem definidos.
