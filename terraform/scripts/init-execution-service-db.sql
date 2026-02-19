-- ==============================================================================
-- DATABASE INITIALIZATION SCRIPT
-- Creates the execution_service_db database and execution_service_user
-- This script runs against the default 'cargarage' database
-- ==============================================================================

-- Create execution_service_user if not exists
DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'execution_service_user') THEN
    CREATE ROLE execution_service_user WITH LOGIN PASSWORD 'ExecutionService2024!';
  END IF;
END
$$;

-- Create execution_service_db if not exists
SELECT 'CREATE DATABASE execution_service_db OWNER execution_service_user'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'execution_service_db')\gexec

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE execution_service_db TO execution_service_user;
