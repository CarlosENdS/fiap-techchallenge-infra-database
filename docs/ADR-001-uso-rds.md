# ADR-001 – Uso de Banco de Dados Gerenciado (Amazon RDS)

## Status
Aceito

## Data de aceite
2026-01-01

## Contexto
Gerenciar banco de dados manualmente aumenta a complexidade e o risco operacional.

## Decisão
Utilizar **Amazon RDS** como serviço gerenciado para execução do PostgreSQL.

## Justificativa
- Backup automático
- Manutenção gerenciada
- Redução de esforço operacional

## Consequências
- Menor controle sobre infraestrutura física
- Maior foco no desenvolvimento
