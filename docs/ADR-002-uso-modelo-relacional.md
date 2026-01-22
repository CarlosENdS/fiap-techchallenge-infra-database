# ADR-002 – Adoção de Modelo Relacional Normalizado

## Status
Aceito

## Data de aceite
2026-01-01

## Contexto
A aplicação do Tech Challenge possui entidades fortemente relacionadas, como
usuários, clientes, veículos, ordens de serviço, serviços e recursos. Essas
entidades exigem consistência, integridade e clareza no relacionamento dos dados.

Era necessário definir um modelo de persistência que fosse fácil de entender
pelo grupo, simples de integrar com a aplicação e adequado ao domínio do
problema.

## Decisão
Adotar um **modelo de banco de dados relacional normalizado**, utilizando
PostgreSQL, com chaves primárias e estrangeiras explícitas para representar os
relacionamentos entre as entidades.

## Alternativas Consideradas
- **Modelo NoSQL (documentos)**  
  Rejeitado por dificultar a representação de relacionamentos complexos.
- **Modelo relacional desnormalizado**  
  Rejeitado por aumentar redundância e risco de inconsistência.
- **Modelo híbrido**  
  Rejeitado por aumentar complexidade para um projeto acadêmico.

## Justificativa
- Facilita o entendimento do modelo por todos os integrantes do grupo
- Garante integridade referencial
- Evita duplicação de dados
- Facilita consultas, relatórios e métricas
- Integra-se facilmente com APIs e ORMs

## Consequências
- Maior número de tabelas
- Consultas mais estruturadas
- Evolução do modelo exige planejamento
