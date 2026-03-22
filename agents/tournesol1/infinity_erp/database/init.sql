-- INFINITY ERP Database Schema
-- Foundation ERP pour PME

-- Extension pour UUID
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Table des utilisateurs avec système de rôles
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    role VARCHAR(50) NOT NULL CHECK (role IN ('admin', 'manager', 'employee', 'accountant')),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table des clients
CREATE TABLE clients (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_name VARCHAR(255) NOT NULL,
    contact_person VARCHAR(255),
    email VARCHAR(255),
    phone VARCHAR(50),
    address TEXT,
    city VARCHAR(100),
    postal_code VARCHAR(20),
    country VARCHAR(100) DEFAULT 'France',
    tax_number VARCHAR(50),
    is_active BOOLEAN DEFAULT TRUE,
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table des fournisseurs
CREATE TABLE suppliers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_name VARCHAR(255) NOT NULL,
    contact_person VARCHAR(255),
    email VARCHAR(255),
    phone VARCHAR(50),
    address TEXT,
    city VARCHAR(100),
    postal_code VARCHAR(20),
    country VARCHAR(100) DEFAULT 'France',
    tax_number VARCHAR(50),
    payment_terms INTEGER DEFAULT 30, -- jours
    is_active BOOLEAN DEFAULT TRUE,
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index pour optimiser les recherches
CREATE INDEX idx_clients_company_name ON clients(company_name);
CREATE INDEX idx_clients_email ON clients(email);
CREATE INDEX idx_suppliers_company_name ON suppliers(company_name);
CREATE INDEX idx_suppliers_email ON suppliers(email);
CREATE INDEX idx_users_email ON users(email);

-- Données de test
INSERT INTO users (email, password_hash, first_name, last_name, role) VALUES
('admin@infinity-erp.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/lewUYt2C9KUJ8qHvW', 'Admin', 'System', 'admin'),
('manager@infinity-erp.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/lewUYt2C9KUJ8qHvW', 'Manager', 'Test', 'manager'),
('employee@infinity-erp.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/lewUYt2C9KUJ8qHvW', 'Employee', 'Test', 'employee');