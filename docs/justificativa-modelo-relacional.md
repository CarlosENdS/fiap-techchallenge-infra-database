# Justificativa da Escolha do Banco de Dados e do Modelo Relacional

Foi adotado o **PostgreSQL como banco de dados relacional**, executando como serviço
gerenciado via **Amazon RDS**, por oferecer **consistência transacional**, ampla
adoção no mercado e facilidade de integração com aplicações, APIs e funções
serverless.

O modelo relacional foi escolhido para representar de forma clara e explícita
as relações entre as entidades centrais do domínio (clientes, unidades e ordens
de serviço), facilitando o **entendimento do negócio pelo grupo**, a **manutenção
do sistema** e a **evolução da arquitetura**.

A modelagem segue princípios de normalização, com chaves primárias e estrangeiras
bem definidas, garantindo **integridade referencial**, evitando redundância de
dados e permitindo consultas eficientes para métricas e relatórios.

Essa abordagem atende aos requisitos de **consistência**, **facilidade de
integração** e **organização do conhecimento**, conforme exigido pelo Tech
Challenge.
