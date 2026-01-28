-- This script runs automatically in the ecommerce_db database
-- No need to create the database, it's already created by POSTGRES_DB env var

-- Create products table (if not created by SQLAlchemy)
CREATE TABLE IF NOT EXISTS products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    price DECIMAL(10, 2) NOT NULL,
    stock INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create orders table (if not created by SQLAlchemy)
CREATE TABLE IF NOT EXISTS orders (
    id SERIAL PRIMARY KEY,
    customer_name VARCHAR(255) NOT NULL,
    customer_email VARCHAR(255) NOT NULL,
    total_amount DECIMAL(10, 2) NOT NULL,
    status VARCHAR(50) DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create order_items table (if not created by SQLAlchemy)
CREATE TABLE IF NOT EXISTS order_items (
    id SERIAL PRIMARY KEY,
    order_id INTEGER NOT NULL,
    product_id INTEGER NOT NULL,
    product_name VARCHAR(255) NOT NULL,
    quantity INTEGER NOT NULL,
    price DECIMAL(10, 2) NOT NULL,
    FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE
);

-- Insert some sample products
INSERT INTO products (name, description, price, stock) VALUES
    ('Laptop HP', 'Ordinateur portable haute performance', 899.99, 10),
    ('Souris Logitech', 'Souris sans fil ergonomique', 29.99, 50),
    ('Clavier Mécanique', 'Clavier gaming RGB', 79.99, 30),
    ('Écran 24"', 'Moniteur Full HD IPS', 199.99, 15),
    ('Webcam HD', 'Caméra 1080p avec micro', 49.99, 25)
ON CONFLICT DO NOTHING;
