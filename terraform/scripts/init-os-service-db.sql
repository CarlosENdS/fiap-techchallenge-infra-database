-- ==============================================================================
-- DATABASE INITIALIZATION SCRIPT
-- Creates the os_service_db database and os_service_user
-- This script runs against the default 'cargarage' database
-- ==============================================================================

-- Create os_service user if not exists
DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'os_service_user') THEN
    CREATE ROLE os_service_user WITH LOGIN PASSWORD 'OsService2024!';
  END IF;
END
$$;

-- Create os_service_db if not exists
-- PostgreSQL doesn't support IF NOT EXISTS for CREATE DATABASE, so we use a workaround
SELECT 'CREATE DATABASE os_service_db OWNER os_service_user'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'os_service_db')\gexec

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE os_service_db TO os_service_user;
