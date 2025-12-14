-- DIMENSIÓN CLIENTES
CREATE TABLE dim_clientes (
    customer_id INTEGER PRIMARY KEY,
    customer_name VARCHAR(255) NOT NULL
);

-- DIMENSIÓN PRODUCTOS
CREATE TABLE dim_productos (
    product_id INTEGER PRIMARY KEY,
    product_name VARCHAR(255) NOT NULL,
    category VARCHAR(100) NOT NULL
);

-- TABLA DE HECHOS PEDIDOS
CREATE TABLE fact_pedidos (
    order_id INTEGER PRIMARY KEY,
    customer_id INTEGER,
    product_id INTEGER,
    order_date DATE,
    quantity INTEGER,
    unit_price DECIMAL(10,2),
    total_price DECIMAL(10,2),
    payment_method VARCHAR(50),
    country VARCHAR(100),
    city VARCHAR(100),
    status VARCHAR(50),
    update_time TIMESTAMP,
    
    FOREIGN KEY (customer_id) REFERENCES dim_clientes(customer_id),
    FOREIGN KEY (product_id) REFERENCES dim_productos(product_id)
);