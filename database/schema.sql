-- Shared Database Schema for POC Applications
-- This schema will be used by all four applications: Gin, Fiber, Spring Boot, and Quarkus

-- Users table representing customer data
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL,
    last_contact_date TIMESTAMP
);

-- Interaction log table for tracking customer interactions
CREATE TABLE interaction_log (
    id SERIAL PRIMARY KEY,
    customer_id INT NOT NULL,
    note TEXT NOT NULL,
    type VARCHAR(50) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES users(id)
);

-- Index for better performance on customer_id lookups
CREATE INDEX idx_interaction_log_customer_id ON interaction_log(customer_id);

-- Index for better performance on user queries
CREATE INDEX idx_users_email ON users(email);
