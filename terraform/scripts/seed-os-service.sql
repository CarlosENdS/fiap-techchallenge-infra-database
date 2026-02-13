-- ==============================================================================
-- OS SERVICE MICROSERVICE DATABASE SEED
-- Schema and initial data for the Order Service microservice
-- ==============================================================================
-- This script is executed against the os_service_db database
-- ==============================================================================

-- Service Order Table (main entity)
CREATE TABLE IF NOT EXISTS service_order (
	id BIGSERIAL PRIMARY KEY,
	customer_id BIGINT NOT NULL,
	customer_name VARCHAR(255),
	vehicle_id BIGINT NOT NULL,
	vehicle_license_plate VARCHAR(20),
	vehicle_model VARCHAR(255),
	vehicle_brand VARCHAR(255),
	description TEXT,
	status VARCHAR(40) NOT NULL,
	total_price NUMERIC(10, 2),
	created_at TIMESTAMP NOT NULL,
	updated_at TIMESTAMP,
	approved_at TIMESTAMP,
	finished_at TIMESTAMP,
	delivered_at TIMESTAMP
);

-- Service Order Items (services included in the order)
CREATE TABLE IF NOT EXISTS service_order_item (
	id BIGSERIAL PRIMARY KEY,
	order_id BIGINT NOT NULL,
	service_id BIGINT NOT NULL,
	service_name VARCHAR(255),
	service_description TEXT,
	quantity INTEGER NOT NULL,
	price NUMERIC(10, 2),
	total_price NUMERIC(10, 2),
	CONSTRAINT fk_service_order_item_order
		FOREIGN KEY (order_id)
		REFERENCES service_order (id)
		ON DELETE CASCADE
);

-- Service Order Resources (parts/supplies used in the order)
CREATE TABLE IF NOT EXISTS service_order_resource (
	id BIGSERIAL PRIMARY KEY,
	order_id BIGINT NOT NULL,
	resource_id BIGINT NOT NULL,
	resource_name VARCHAR(255),
	resource_description TEXT,
	resource_type VARCHAR(100),
	quantity INTEGER NOT NULL,
	price NUMERIC(10, 2),
	total_price NUMERIC(10, 2),
	CONSTRAINT fk_service_order_resource_order
		FOREIGN KEY (order_id)
		REFERENCES service_order (id)
		ON DELETE CASCADE
);

-- ==============================================================================
-- INDEXES
-- ==============================================================================

CREATE INDEX IF NOT EXISTS idx_service_order_customer_id ON service_order (customer_id);
CREATE INDEX IF NOT EXISTS idx_service_order_vehicle_id ON service_order (vehicle_id);
CREATE INDEX IF NOT EXISTS idx_service_order_status ON service_order (status);
CREATE INDEX IF NOT EXISTS idx_service_order_item_order_id ON service_order_item (order_id);
CREATE INDEX IF NOT EXISTS idx_service_order_resource_order_id ON service_order_resource (order_id);

-- ==============================================================================
-- SEED DATA: Service Orders
-- ==============================================================================

INSERT INTO service_order (
	id, customer_id, customer_name, vehicle_id, vehicle_license_plate, vehicle_model,
	vehicle_brand, description, status, total_price,
	created_at, updated_at, approved_at, finished_at, delivered_at
) VALUES
	(1, 1001, 'Carlos Santos', 2001, 'ABC1D23', 'Civic', 'Honda',
	 'Barulho ao frear e vibração no volante', 'WAITING_APPROVAL', 890.00,
	 NOW() - INTERVAL '3 days', NOW() - INTERVAL '2 days', NULL, NULL, NULL),
	(2, 1002, 'Ana Oliveira', 2002, 'BRA2E45', 'Onix', 'Chevrolet',
	 'Troca de óleo e revisão de 10.000km', 'IN_EXECUTION', 420.00,
	 NOW() - INTERVAL '2 days', NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day', NULL, NULL),
	(3, 1003, 'Marcos Lima', 2003, 'XYZ9K88', 'Corolla', 'Toyota',
	 'Falha na partida e bateria descarregando', 'FINISHED', 560.00,
	 NOW() - INTERVAL '5 days', NOW() - INTERVAL '1 day', NOW() - INTERVAL '3 days', NOW() - INTERVAL '6 hours', NULL),
	(4, 1004, 'Beatriz Souza', 2004, 'QWE7R65', 'HB20', 'Hyundai',
	 'Luz de injeção acesa', 'CANCELLED', 0.00,
	 NOW() - INTERVAL '4 days', NOW() - INTERVAL '3 days', NULL, NULL, NULL)
ON CONFLICT (id) DO NOTHING;

-- ==============================================================================
-- SEED DATA: Service Order Items (services)
-- ==============================================================================

INSERT INTO service_order_item (
	id, order_id, service_id, service_name, service_description, quantity, price, total_price
) VALUES
	(1, 1, 301, 'Diagnóstico de freios', 'Inspeção completa do sistema de freios', 1, 120.00, 120.00),
	(2, 1, 302, 'Troca de pastilhas', 'Substituição das pastilhas dianteiras', 1, 220.00, 220.00),
	(3, 2, 303, 'Troca de óleo', 'Troca de óleo e filtro', 1, 180.00, 180.00),
	(4, 2, 304, 'Revisão periódica', 'Checklist geral de 10.000 km', 1, 140.00, 140.00),
	(5, 3, 305, 'Diagnóstico elétrico', 'Teste de alternador e circuito de carga', 1, 210.00, 210.00)
ON CONFLICT (id) DO NOTHING;

-- ==============================================================================
-- SEED DATA: Service Order Resources (parts/supplies)
-- ==============================================================================

INSERT INTO service_order_resource (
	id, order_id, resource_id, resource_name, resource_description, resource_type, quantity, price, total_price
) VALUES
	(1, 1, 401, 'Pastilha de freio dianteira', 'Jogo com 4 pastilhas', 'PART', 1, 320.00, 320.00),
	(2, 1, 402, 'Fluido de freio DOT 4', 'Fluido sintético 500ml', 'SUPPLY', 1, 70.00, 70.00),
	(3, 2, 403, 'Óleo 5W30', 'Lubrificante sintético 1L', 'SUPPLY', 4, 25.00, 100.00),
	(4, 3, 404, 'Bateria 60Ah', 'Bateria automotiva selada', 'PART', 1, 350.00, 350.00)
ON CONFLICT (id) DO NOTHING;

-- ==============================================================================
-- SYNC SEQUENCES
-- ==============================================================================

SELECT setval('service_order_id_seq', COALESCE((SELECT MAX(id) FROM service_order), 0) + 1, false);
SELECT setval('service_order_item_id_seq', COALESCE((SELECT MAX(id) FROM service_order_item), 0) + 1, false);
SELECT setval('service_order_resource_id_seq', COALESCE((SELECT MAX(id) FROM service_order_resource), 0) + 1, false);
