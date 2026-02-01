-- ############################################################
-- DATA WAREHOUSE E-COMMERCE - SCRIPT MySQL 8.0
-- Diseño dimensional + índices + tablas resumen + vistas
-- ############################################################


CREATE DATABASE IF NOT EXISTS dw_ecommerce
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_unicode_ci;

USE dw_ecommerce;

-- ============================================================
-- 1. DIMENSIONES
-- ============================================================

-- -------------------------
-- DIM CUSTOMER
-- -------------------------
CREATE TABLE dim_customer (
    customer_id       INT AUTO_INCREMENT PRIMARY KEY,
    email             VARCHAR(255) NOT NULL,
    registration_date DATE NOT NULL,
    customer_segment  VARCHAR(50),
    total_orders      INT DEFAULT 0,
    lifetime_value    DECIMAL(12,2) DEFAULT 0.00,
    
    created_at        TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at        TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE UNIQUE INDEX idx_dim_customer_email
    ON dim_customer(email);


-- -------------------------
-- DIM PRODUCT
-- -------------------------
CREATE TABLE dim_product (
    product_id    INT AUTO_INCREMENT PRIMARY KEY,
    sku           VARCHAR(100) NOT NULL,
    product_name  VARCHAR(255) NOT NULL,
    category      VARCHAR(100),
    brand         VARCHAR(100),
    unit_cost     DECIMAL(12,2),
    current_price DECIMAL(12,2),
    
    created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE UNIQUE INDEX idx_dim_product_sku
    ON dim_product(sku);

CREATE INDEX idx_dim_product_category_brand
    ON dim_product(category, brand);


-- -------------------------
-- DIM TIME
-- -------------------------
CREATE TABLE dim_time (
    date_key     INT PRIMARY KEY,       -- YYYYMMDD
    full_date    DATE NOT NULL,
    year         INT NOT NULL,
    quarter      TINYINT NOT NULL,
    month        TINYINT NOT NULL,
    day_of_month TINYINT NOT NULL,
    day_of_week  TINYINT NOT NULL,      -- 1-7
    is_weekend   TINYINT(1) NOT NULL,   -- 0 / 1
    is_holiday   TINYINT(1) NOT NULL,   -- 0 / 1
    
    created_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE INDEX idx_dim_time_year_month
    ON dim_time(year, month);

CREATE INDEX idx_dim_time_full_date
    ON dim_time(full_date);


-- -------------------------
-- DIM LOCATION
-- -------------------------
CREATE TABLE dim_location (
    location_id INT AUTO_INCREMENT PRIMARY KEY,
    country     VARCHAR(100),
    region      VARCHAR(100),
    city        VARCHAR(100),
    postal_code VARCHAR(20),
    timezone    VARCHAR(50),
    
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE INDEX idx_dim_location_country_region_city
    ON dim_location(country, region, city);


-- ============================================================
-- 2. TABLA DE HECHOS PRINCIPAL
-- ============================================================

-- Para un DW grande, conviene particionar por año (derivado de dim_time)
-- Aquí incluimos un campo redundante year para facilitar particionado.
CREATE TABLE fact_orders (
    order_id       BIGINT PRIMARY KEY,
    
    customer_id    INT NOT NULL,
    product_id     INT NOT NULL,
    time_id        INT NOT NULL,        -- FK a dim_time(date_key)
    order_year     INT NOT NULL,        -- redundante para particionado
    location_id    INT,
    
    quantity_ordered INT NOT NULL,
    unit_price       DECIMAL(12,2) NOT NULL,
    discount_amount  DECIMAL(12,2) DEFAULT 0.00,
    tax_amount       DECIMAL(12,2) DEFAULT 0.00,
    shipping_cost    DECIMAL(12,2) DEFAULT 0.00,
    total_amount     DECIMAL(12,2) NOT NULL,
    
    profit_margin    DECIMAL(12,4),     -- margen relativo o absoluto según def.
    is_first_purchase TINYINT(1) DEFAULT 0,  -- 0/1
    order_channel     VARCHAR(20),      -- 'web', 'mobile', 'api', etc.
    payment_method    VARCHAR(50),
    
    created_at        TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at        TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_fact_orders_customer
        FOREIGN KEY (customer_id) REFERENCES dim_customer(customer_id),
    CONSTRAINT fk_fact_orders_product
        FOREIGN KEY (product_id) REFERENCES dim_product(product_id),
    CONSTRAINT fk_fact_orders_time
        FOREIGN KEY (time_id) REFERENCES dim_time(date_key),
    CONSTRAINT fk_fact_orders_location
        FOREIGN KEY (location_id) REFERENCES dim_location(location_id)
)
ENGINE=InnoDB;

/* Si el volumen de datos exige particionar, se puedes (para el script en MySQL):
• 	Quitar las claves foráneas
• 	Mantener los índices para acelerar los JOINs
• 	Validar integridad en el ETL

-- PARTITION BY RANGE (order_year) (
--    PARTITION p_2023 VALUES LESS THAN (2024),
--    PARTITION p_2024 VALUES LESS THAN (2025),
--    PARTITION p_max  VALUES LESS THAN MAXVALUE
-- );
*/

-- Índices para joins y análisis
CREATE INDEX idx_fact_orders_customer
    ON fact_orders(customer_id);

CREATE INDEX idx_fact_orders_product
    ON fact_orders(product_id);

CREATE INDEX idx_fact_orders_time
    ON fact_orders(time_id);

CREATE INDEX idx_fact_orders_location
    ON fact_orders(location_id);

-- Índice compuesto útil para análisis temporal + revenue
CREATE INDEX idx_fact_orders_time_amount
    ON fact_orders(time_id, total_amount);

-- Índice para análisis de clientes en el tiempo (cohortes, first purchase, etc.)
CREATE INDEX idx_fact_orders_customer_time
    ON fact_orders(customer_id, time_id);

-- Índice para análisis por canal
CREATE INDEX idx_fact_orders_channel
    ON fact_orders(order_channel);


-- ============================================================
-- 3. TABLAS RESUMEN (SIMULAN VISTAS MATERIALIZADAS)
-- ============================================================

-- ------------------------------------------
-- RESUMEN MENSUAL PARA DASHBOARDS EJECUTIVOS
-- ------------------------------------------
CREATE TABLE summary_monthly_sales (
    year            INT NOT NULL,
    month           TINYINT NOT NULL,
    monthly_revenue DECIMAL(14,2) NOT NULL,
    total_orders    INT NOT NULL,
    active_customers INT NOT NULL,
    avg_order_value DECIMAL(14,2) NOT NULL,
    
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    PRIMARY KEY (year, month)
) ENGINE=InnoDB;


-- ============================================================
-- 4. VISTAS ANALÍTICAS
-- ============================================================

-- --------------------------------------------------
-- PRODUCT PERFORMANCE (ANÁLISIS PRODUCTOS POPULARES)
-- --------------------------------------------------
CREATE OR REPLACE VIEW product_performance AS
SELECT
    dp.product_id,
    dp.product_name,
    dp.category,
    dp.brand,
    SUM(fo.quantity_ordered)         AS total_units_sold,
    SUM(fo.total_amount)            AS total_revenue,
    AVG(fo.unit_price)              AS avg_selling_price,
    COUNT(DISTINCT fo.customer_id)  AS unique_customers,
    ROW_NUMBER() OVER (
        PARTITION BY dp.category
        ORDER BY SUM(fo.total_amount) DESC
    ) AS category_rank
FROM fact_orders fo
JOIN dim_product dp ON fo.product_id = dp.product_id
JOIN dim_time dt    ON fo.time_id = dt.date_key
WHERE dt.year = 2024
GROUP BY
    dp.product_id,
    dp.product_name,
    dp.category,
    dp.brand;


-- -------------------------
-- EXECUTIVE DASHBOARD (USANDO TABLA RESUMEN)
-- -------------------------
-- Esta vista se monta sobre la tabla summary_monthly_sales,
-- que deberías poblar con un job ETL (diario o mensual).

CREATE OR REPLACE VIEW executive_dashboard AS
SELECT
    sms.year,
    sms.month,
    sms.monthly_revenue,
    sms.active_customers,
    sms.total_orders,
    sms.avg_order_value,
    (
        sms.monthly_revenue
        - LAG(sms.monthly_revenue) OVER (ORDER BY sms.year, sms.month)
    )
    /
    NULLIF(LAG(sms.monthly_revenue) OVER (ORDER BY sms.year, sms.month), 0)
        AS growth_rate
FROM summary_monthly_sales sms
ORDER BY sms.year, sms.month;


-- ============================================================
-- 5. EJEMPLO DE CARGA DE RESUMEN MENSUAL (JOB ETL)
-- ============================================================
-- Esto puede ser un procedimiento o job programado.
-- Aquí se muestra como referencia de cómo recalcular summary_monthly_sales.
-- Se puede ajustar el WHERE para cargas incrementales por rango de fechas.

-- DELETE FROM summary_monthly_sales WHERE year = 2024;
-- INSERT INTO summary_monthly_sales (year, month, monthly_revenue, total_orders, active_customers, avg_order_value)
-- SELECT
--     dt.year,
--     dt.month,
--     SUM(fo.total_amount)                       AS monthly_revenue,
--     COUNT(fo.order_id)                         AS total_orders,
--     COUNT(DISTINCT fo.customer_id)             AS active_customers,
--     AVG(fo.total_amount)                       AS avg_order_value
-- FROM fact_orders fo
-- JOIN dim_time dt ON fo.time_id = dt.date_key
-- WHERE dt.year = 2024
-- GROUP BY dt.year, dt.month;


-- ############################################################
-- FIN DEL SCRIPT
-- ############################################################

/* >>>>>>>>>>> VERIFICACION <<<<<<<<<<<<<<<<

1.- ¿Qué índices crearías para optimizar estas consultas? 
- Índices recomendados:
Para optimizar las consultas del data warehouse, se deben crear índices que aceleren
los JOIN entre la tabla de hechos y las dimensiones, además de soportar filtros y 
agregaciones frecuentes. 
Esto incluye índices en claves foráneas lógicas (customer_id, product_id, time_id, 
location_id), índices compuestos para análisis temporal (time_id, total_amount) y 
otros orientados a cohortes, canales y atributos de producto. 
Con esta estructura, las consultas analíticas, dashboards y cálculos de revenue 
operan con máxima eficiencia incluso con grandes volúmenes de datos.

2. ¿Cómo manejarías el crecimiento de datos históricos en este warehouse?
-Manejo del crecimiento histórico:
Para mantener el rendimiento a largo plazo se debe  mantener el data warehouse liviano y 
rápido , por lo que el warehouse debe separar datos recientes  y altamente consultados 
(caliente :hot storage) de datos antiguos y poco usados (frios :cold storage). 
 Esto se logra moviendo registros de más de 3–5 años a tablas históricas comprimidas
 y manteniendo en la capa caliente solo los últimos años de detalle junto con métricas
 agregadas por mes, categoría o producto. 
 Esta estrategia reduce costos, acelera consultas y permite que el sistema siga siendo
 escalable sin perder trazabilidad histórica.
 
 */