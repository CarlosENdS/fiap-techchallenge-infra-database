# RFC-002 – Escolha do Banco de Dados

## Status
Aprovado

## Data de aceite
2026-01-01

## Contexto
A aplicação possui entidades relacionadas, como clientes, veículos, ordens de
serviço e itens associados, exigindo consistência e integridade dos dados.

## Proposta
Utilizar **PostgreSQL como banco de dados relacional**, executando como serviço
gerenciado via Amazon RDS.

## Justificativa
- Suporte a transações ACID
- Modelo relacional adequado ao domínio
- Facilidade de aprendizado para o grupo
- Ampla adoção no mercado

## Impactos
- Uso de modelo relacional normalizado
- Facilidade de integração com a aplicação
