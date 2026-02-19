-- ==============================================================================
-- EXECUTION SERVICE MICROSERVICE DATABASE SEED
-- Schema and initial data for the Execution Service microservice
-- ==============================================================================
-- This script is executed against the execution_service_db database
-- ==============================================================================

-- Execution Task Table (main entity)
CREATE TABLE IF NOT EXISTS execution_task (
    id BIGSERIAL PRIMARY KEY,
    service_order_id BIGINT NOT NULL,
    customer_id BIGINT,
    vehicle_id BIGINT,
    vehicle_license_plate VARCHAR(20),
    description TEXT,
    status VARCHAR(40) NOT NULL,
    assigned_technician VARCHAR(255),
    notes TEXT,
    failure_reason VARCHAR(500),
    priority INTEGER DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP,
    started_at TIMESTAMP,
    completed_at TIMESTAMP
);

-- ==============================================================================
-- INDEXES
-- ==============================================================================

CREATE INDEX IF NOT EXISTS idx_execution_task_service_order_id ON execution_task (service_order_id);
CREATE INDEX IF NOT EXISTS idx_execution_task_status ON execution_task (status);
CREATE INDEX IF NOT EXISTS idx_execution_task_assigned_technician ON execution_task (assigned_technician);

-- ==============================================================================
-- SEED DATA: Execution Tasks
-- ==============================================================================

INSERT INTO execution_task (
    id, service_order_id, customer_id, vehicle_id, vehicle_license_plate,
    description, status, assigned_technician, notes, failure_reason,
    priority, created_at, updated_at, started_at, completed_at
) VALUES
    (1, 1001, 1, 2001, 'ABC1D23',
     'Troca de pastilhas de freio dianteiras', 'COMPLETED', 'Carlos Mecânico',
     'Peças originais utilizadas', NULL,
     1, NOW() - INTERVAL '5 days', NOW() - INTERVAL '3 days',
     NOW() - INTERVAL '4 days', NOW() - INTERVAL '3 days'),
    (2, 1002, 2, 2002, 'BRA2E45',
     'Troca de óleo e filtro - revisão 10.000km', 'IN_PROGRESS', 'João Técnico',
     'Aguardando filtro de ar', NULL,
     2, NOW() - INTERVAL '2 days', NOW() - INTERVAL '1 day',
     NOW() - INTERVAL '1 day', NULL),
    (3, 1003, 3, 2003, 'XYZ9K88',
     'Diagnóstico elétrico - falha na partida', 'QUEUED', NULL,
     'Prioridade alta - cliente corporativo', NULL,
     1, NOW() - INTERVAL '1 day', NULL,
     NULL, NULL),
    (4, 1004, 4, 2004, 'QWE7R65',
     'Reparo no sistema de injeção eletrônica', 'FAILED', 'Pedro Eletricista',
     'Peça indisponível no estoque', 'Recurso indisponível: módulo de injeção fora de estoque',
     3, NOW() - INTERVAL '4 days', NOW() - INTERVAL '2 days',
     NOW() - INTERVAL '3 days', NOW() - INTERVAL '2 days')
ON CONFLICT (id) DO NOTHING;

-- ==============================================================================
-- SYNC SEQUENCES
-- ==============================================================================

SELECT setval('execution_task_id_seq', COALESCE((SELECT MAX(id) FROM execution_task), 0) + 1, false);
