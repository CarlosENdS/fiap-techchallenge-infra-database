-- ==============================================================================
-- CARGARAGE MONOLITH DATABASE SEED
-- Schema and initial data for the main Car Garage application
-- ==============================================================================

-- Creation of the role table
CREATE TABLE IF NOT EXISTS role (
    id SERIAL PRIMARY KEY,
    name VARCHAR(20) NOT NULL UNIQUE
);

-- Creation of the user table
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    password VARCHAR(100) NOT NULL
);

-- User Association Table <-> Role
CREATE TABLE IF NOT EXISTS users_roles (
    user_id BIGINT NOT NULL,
    role_id BIGINT NOT NULL,
    PRIMARY KEY (user_id, role_id),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (role_id) REFERENCES role(id) ON DELETE CASCADE
);

-- Role insertion
INSERT INTO role (name) VALUES ('ADMIN') ON CONFLICT (name) DO NOTHING;
INSERT INTO role (name) VALUES ('USER') ON CONFLICT (name) DO NOTHING;

-- User insertion (password: 'admin' and 'user')
INSERT INTO "users" (username, password) VALUES ('admin', '$2a$12$KgQmSzxg71dk/t98qvJCguG3Q7lEfSlxTXfqit7ZSHHQAXGbhg8fW') ON CONFLICT (username) DO NOTHING;
INSERT INTO "users" (username, password) VALUES ('user', '$2a$12$Cr9p0CX2ZPLopSRhT0PxBulLR2LQzjknPeytaqimlgV9BGKckycDO') ON CONFLICT (username) DO NOTHING;

-- Users Association with Roles
INSERT INTO users_roles (user_id, role_id)
SELECT u.id, r.id FROM "users" u, role r WHERE u.username = 'admin' AND r.name = 'ADMIN' ON CONFLICT DO NOTHING;
INSERT INTO users_roles (user_id, role_id)
SELECT u.id, r.id FROM "users" u, role r WHERE u.username = 'user' AND r.name = 'USER' ON CONFLICT DO NOTHING;

CREATE TABLE IF NOT EXISTS service (
    id SERIAL PRIMARY KEY,
    "name" VARCHAR(100) NOT NULL,
    "description" VARCHAR NOT NULL,
    price NUMERIC(10,2) NOT NULL DEFAULT 0.00
);

INSERT INTO service (name, description, price) VALUES
('Oil Change', 'Engine oil and filter replacement', 120.00),
('Wheel Alignment', 'Suspension and steering alignment', 90.00),
('Wheel Balancing', 'Balancing of wheels', 80.00),
('Full Inspection', 'General inspection of all vehicle systems', 350.00),
('Brake Pad Replacement', 'Front brake pad replacement', 180.00),
('Brake Disc Replacement', 'Replacement of brake discs', 250.00),
('Tire Replacement', 'Tire replacement service', 60.00),
('A/C Recharge', 'Air conditioning system recharge and inspection', 150.00),
('Timing Belt Replacement', 'Replacement of timing belt', 400.00),
('Battery Replacement', 'Installation of new battery', 220.00),
('Air Filter Replacement', 'Replacement of air filter', 70.00),
('Fuel Filter Replacement', 'Replacement of fuel filter', 85.00),
('Cabin Filter Replacement', 'Replacement of cabin filter', 65.00),
('Suspension Repair', 'Repair or replacement of shocks and springs', 320.00),
('Clutch Repair', 'Replacement of clutch kit', 600.00),
('Electronic Diagnostics', 'Reading and analysis of fault codes', 110.00),
('Light Bulb Replacement', 'Replacement of external and internal bulbs', 40.00),
('Spark Plug Replacement', 'Replacement of spark plugs', 90.00),
('Radiator Repair', 'Cleaning and repair of radiator', 200.00),
('Brake Fluid Change', 'Replacement of brake fluid', 75.00);

CREATE TABLE IF NOT EXISTS resource (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description VARCHAR NOT NULL,
    quantity INT NOT NULL DEFAULT 0, 
    price NUMERIC(10,2) NOT NULL DEFAULT 0.00,
    type VARCHAR(20) NOT NULL 
);

INSERT INTO resource (name, description, quantity, price, type) VALUES
('Engine Oil', 'High-quality engine oil', 100, 30.00, 'SUPPLY'),
('Oil Filter', 'Durable oil filter', 100, 10.00, 'SUPPLY'),
('Brake Fluid', 'High boiling point brake fluid', 50, 10.00, 'SUPPLY'),
('A/C Refrigerant', 'Refrigerant for A/C systems', 50, 20.00, 'SUPPLY'),
('LED Bulbs', 'Energy-saving LED bulbs', 200, 5.00, 'SUPPLY'),
('Spark Plugs', 'Copper core spark plugs', 200, 3.00, 'SUPPLY'),
('Radiator Coolant', 'Premium radiator coolant', 60, 18.00, 'SUPPLY'),
('Grease', 'Multipurpose automotive grease', 80, 8.00, 'SUPPLY'),
('Brake Pads', 'Long-lasting brake pads', 50, 50.00, 'PIECE'),
('Brake Discs', 'Premium brake discs', 50, 100.00, 'PIECE'),
('Tires', 'All-season tires', 200, 60.00, 'PIECE'),
('Timing Belt', 'High-strength timing belt', 30, 70.00, 'PIECE'),
('Car Battery', 'Maintenance-free car battery', 40, 120.00, 'PIECE'),
('Air Filter', 'Efficient air filter', 100, 15.00, 'PIECE'),
('Fuel Filter', 'High-performance fuel filter', 100, 25.00, 'PIECE'),
('Cabin Filter', 'Activated carbon cabin filter', 100, 20.00, 'PIECE'),
('Shock Absorbers', 'Premium shock absorbers', 20, 80.00, 'PIECE'),
('Clutch Kit', 'Complete clutch kit', 10, 150.00, 'PIECE'),
('Diagnostic Scanner', 'Advanced diagnostic scanner', 15, 200.00, 'PIECE'),
('Radiator', 'Aluminum radiator', 10, 250.00, 'PIECE');

CREATE TABLE IF NOT EXISTS customers (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    cpf_cnpj VARCHAR(20) NOT NULL UNIQUE,
    street VARCHAR(100),
    number VARCHAR(20),
    complement VARCHAR(100),
    neighborhood VARCHAR(100),
    city VARCHAR(100),
    state VARCHAR(2),
    zip_code VARCHAR(10)
);

INSERT INTO customers (name, email, phone, cpf_cnpj, street, number, complement, neighborhood, city, state, zip_code) VALUES
('João Silva', 'joao.silva@email.com', '11999887766', '12345678900', 'Rua das Flores', '123', 'Apto 101', 'Jardim Primavera', 'São Paulo', 'SP', '01234-567'),
('Maria Oliveira', 'maria.oliveira@email.com', '11988776655', '98765432100', 'Avenida Paulista', '1000', 'Sala 50', 'Bela Vista', 'São Paulo', 'SP', '01310-100'),
('Pedro Santos', 'pedro.santos@email.com', '11977665544', '45678912300', 'Rua Augusta', '500', NULL, 'Consolação', 'São Paulo', 'SP', '01304-000'),
('Ana Costa', 'ana.costa@email.com', '11966554433', '78912345600', 'Rua Oscar Freire', '200', 'Casa 2', 'Jardins', 'São Paulo', 'SP', '01426-000'),
('Carlos Ferreira', 'carlos.ferreira@email.com', '11955443322', '32165498700', 'Alameda Santos', '800', 'Apto 1502', 'Cerqueira César', 'São Paulo', 'SP', '01418-100'),
('Empresa ABC Ltda', 'contato@empresaabc.com', '1133445566', '12345678000199', 'Avenida Brigadeiro Faria Lima', '3000', '15º andar', 'Itaim Bibi', 'São Paulo', 'SP', '04538-132'),
('Auto Peças XYZ', 'contato@autopecasxyz.com', '1144556677', '98765432000188', 'Avenida Rebouças', '1500', 'Loja 10', 'Pinheiros', 'São Paulo', 'SP', '05402-100');

CREATE TABLE IF NOT EXISTS vehicles (
    id SERIAL PRIMARY KEY,
    license_plate VARCHAR(10) NOT NULL UNIQUE,
    model VARCHAR(100) NOT NULL,
    brand VARCHAR(100) NOT NULL,
    year INT NOT NULL,
    customer_id INT NOT NULL,
    FOREIGN KEY (customer_id) REFERENCES customers(id)
);

INSERT INTO vehicles (license_plate, model, brand, year, customer_id) VALUES
('ABC-1234', 'Onix', 'Chevrolet', 2020, 1),
('DEF-5678', 'Civic', 'Honda', 2019, 1),
('GHI-9012', 'Corolla', 'Toyota', 2021, 2),
('JKL-3456', 'HB20', 'Hyundai', 2018, 3),
('MNO-7890', 'Compass', 'Jeep', 2022, 4),
('PQR-1357', 'Renegade', 'Jeep', 2020, 5),
('STU-2468', 'Gol', 'Volkswagen', 2017, 5),
('VWX-3690', 'Toro', 'Fiat', 2021, 6),
('YZA-4812', 'Hilux', 'Toyota', 2019, 6),
('BCD-5934', 'S10', 'Chevrolet', 2020, 7),
('EFG-6056', 'Strada', 'Fiat', 2018, 7);

CREATE TABLE IF NOT EXISTS work_order (
    id SERIAL PRIMARY KEY,
    customer_id INT NOT NULL,
    vehicle_id INT NOT NULL,
    description TEXT,
    status VARCHAR(20) NOT NULL,
    total_price NUMERIC(10,2) NOT NULL DEFAULT 0.00,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP,
    approved_at TIMESTAMP,
    finished_at TIMESTAMP,
    delivered_at TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES customers(id),
    FOREIGN KEY (vehicle_id) REFERENCES vehicles(id)
);

CREATE TABLE IF NOT EXISTS order_service (
    id SERIAL PRIMARY KEY,
    order_id INT NOT NULL,
    service_id INT NOT NULL,
    price NUMERIC(10,2) NOT NULL,
    quantity INT NOT NULL DEFAULT 1,
    FOREIGN KEY (order_id) REFERENCES work_order(id) ON DELETE CASCADE,
    FOREIGN KEY (service_id) REFERENCES service(id)
);

CREATE TABLE IF NOT EXISTS order_item (
    id SERIAL PRIMARY KEY,
    order_id INT NOT NULL,
    resource_id INT NOT NULL,
    price NUMERIC(10,2) NOT NULL,
    quantity INT NOT NULL DEFAULT 1,
    FOREIGN KEY (order_id) REFERENCES work_order(id) ON DELETE CASCADE,
    FOREIGN KEY (resource_id) REFERENCES resource(id)
);

INSERT INTO work_order (customer_id, vehicle_id, description, status, total_price, created_at, updated_at) VALUES
(1, 1, 'Revisão completa', 'RECEIVED', 350.00, CURRENT_TIMESTAMP - INTERVAL '7 days', CURRENT_TIMESTAMP - INTERVAL '7 days'),
(2, 3, 'Problema no freio', 'IN_DIAGNOSIS', 430.00, CURRENT_TIMESTAMP - INTERVAL '5 days', CURRENT_TIMESTAMP - INTERVAL '5 days'),
(3, 4, 'Troca de óleo e filtros', 'WAITING_APPROVAL', 205.00, CURRENT_TIMESTAMP - INTERVAL '4 days', CURRENT_TIMESTAMP - INTERVAL '3 days'),
(4, 5, 'Barulho na suspensão', 'IN_EXECUTION', 320.00, CURRENT_TIMESTAMP - INTERVAL '6 days', CURRENT_TIMESTAMP - INTERVAL '2 days'),
(5, 6, 'Manutenção preventiva', 'FINISHED', 550.00, CURRENT_TIMESTAMP - INTERVAL '10 days', CURRENT_TIMESTAMP - INTERVAL '1 day'),
(5, 7, 'Troca de bateria', 'DELIVERED', 340.00, CURRENT_TIMESTAMP - INTERVAL '15 days', CURRENT_TIMESTAMP - INTERVAL '12 days');

UPDATE work_order SET 
    approved_at = updated_at - INTERVAL '1 day'
WHERE status IN ('IN_EXECUTION', 'FINISHED', 'DELIVERED');

UPDATE work_order SET 
    finished_at = updated_at
WHERE status IN ('FINISHED', 'DELIVERED');

UPDATE work_order SET 
    delivered_at = updated_at
WHERE status = 'DELIVERED';

INSERT INTO order_service (order_id, service_id, price, quantity) VALUES
(1, 4, 350.00, 1), 
(2, 5, 180.00, 1), 
(2, 6, 250.00, 1), 
(3, 1, 120.00, 1), 
(3, 19, 75.00, 1), 
(4, 14, 320.00, 1), 
(5, 1, 120.00, 1), 
(5, 2, 90.00, 1), 
(5, 3, 80.00, 1), 
(5, 19, 75.00, 1), 
(5, 12, 65.00, 1), 
(5, 16, 40.00, 3), 
(6, 10, 220.00, 1), 
(6, 16, 40.00, 3); 

INSERT INTO order_item (order_id, resource_id, price, quantity) VALUES
(3, 1, 30.00, 1),
(3, 2, 10.00, 1), 
(5, 1, 30.00, 1), 
(5, 2, 10.00, 1), 
(5, 7, 18.00, 1),
(5, 15, 5.00, 3),
(6, 20, 120.00, 1);
