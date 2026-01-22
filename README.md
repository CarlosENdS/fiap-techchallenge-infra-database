# Infra Database – Banco de Dados Gerenciado (Amazon RDS)

Este repositório é responsável pela **provisão e gerenciamento da infraestrutura de banco de dados gerenciado** da aplicação do Tech Challenge, utilizando **Amazon RDS (PostgreSQL)** e **Terraform Cloud**, seguindo práticas de **cloud computing, infraestrutura como código (IaC), segurança e escalabilidade**.

O objetivo deste repositório é garantir **persistência de dados confiável, consistente e segura**, permitindo que a aplicação opere em nível corporativo, com separação clara de responsabilidades entre infraestrutura, aplicação e autenticação.

---

## 🎯 Objetivo do Repositório (Alinhado ao Tech Challenge)

Atender aos seguintes requisitos do desafio:

- Uso de **Banco de Dados Gerenciado**
- Infraestrutura provisionada via **Terraform**
- Deploy automatizado em **CI/CD**
- Segurança e isolamento de rede
- Documentação clara das decisões técnicas
- Separação da infraestrutura em repositório dedicado

---

## 📌 Escopo

### O que este repositório faz
- Provisiona um banco **PostgreSQL gerenciado via Amazon RDS**
- Cria recursos de rede necessários para o banco (subnets privadas e security groups)
- Configura backups automáticos e criptografia
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

- **Infraestrutura Kubernetes (EKS + Rede)**  
  https://github.com/CarlosENdS/fiap-techchallenge-infra-kubernetes

- **Autenticação Serverless (Lambda)**  
  https://github.com/Leonardo-almd/lambda-cargarage-auth

Cada repositório possui pipeline de CI/CD próprio e integra-se aos demais por meio
de outputs e contratos bem definidos.
