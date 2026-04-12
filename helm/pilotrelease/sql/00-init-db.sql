-- Minimal PostgreSQL initialization
-- Schema and data are managed by Flyway migrations in the Spring Boot app
-- This script only ensures the database and extensions are ready

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
