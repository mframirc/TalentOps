USE talentops1;
-- Estrategias de particionamiento para diferentes componentes

-- 1. Eventos de usuario (streaming + histórico)
-- Kafka topics particionados por tipo de evento
CREATE TABLE eventos_usuario (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    timestamp DATETIME NOT NULL,
    user_id BIGINT NOT NULL,
    event_type VARCHAR(50) NOT NULL,
    session_id VARCHAR(100),
    properties JSON,  -- JSON permitido sin participar en la partición

    -- Columna generada para particionar por fecha
    ts_days INT AS (TO_DAYS(timestamp)) STORED,

    PRIMARY KEY (id, ts_days),
    KEY idx_timestamp (timestamp),
    KEY idx_user (user_id)
)
PARTITION BY RANGE (ts_days) (
    PARTITION p202501 VALUES LESS THAN (TO_DAYS('2025-02-01')),
    PARTITION p202502 VALUES LESS THAN (TO_DAYS('2025-03-01')),
    PARTITION p202503 VALUES LESS THAN (TO_DAYS('2025-04-01')),
    PARTITION pmax VALUES LESS THAN MAXVALUE
);

-- 2. Órdenes de compra (transaccional + analítico)
USE talentops1;
CREATE TABLE ordenes (
    order_id BIGINT NOT NULL,
    user_id BIGINT NOT NULL,
    order_date DATETIME NOT NULL,
    total_amount DECIMAL(10,2) NOT NULL,
    status VARCHAR(20) NOT NULL,

    -- Columna generada para particionamiento mensual
    order_yyyymm INT AS (YEAR(order_date) * 100 + MONTH(order_date)) STORED,

    PRIMARY KEY (order_id, order_yyyymm),
    KEY idx_user (user_id),
    KEY idx_status (status)
)
PARTITION BY RANGE (order_yyyymm) (
    PARTITION p202501 VALUES LESS THAN (202502),
    PARTITION p202502 VALUES LESS THAN (202503),
    PARTITION p202503 VALUES LESS THAN (202504),
    PARTITION pmax VALUES LESS THAN MAXVALUE
);

-- 3. Datos de productos (relacional + búsqueda)
-- Elasticsearch para búsqueda, PostgreSQL para datos maestros
USE talentops1;
CREATE TABLE productos (
    product_id BIGINT NOT NULL AUTO_INCREMENT,
    category_id INT NOT NULL,
    name VARCHAR(200) NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    stock_quantity INT NOT NULL,

    PRIMARY KEY (product_id),

    -- Índice compuesto para filtros por categoría + precio
    INDEX idx_category_price (category_id, price),

    -- Full-text search en MySQL
    FULLTEXT INDEX idx_name_fts (name),

    -- Índice normal para stock (MySQL no soporta índices parciales)
    INDEX idx_stock (stock_quantity)
) ENGINE=InnoDB;

-- 4. Métricas agregadas (data warehouse columnar)
-- ClickHouse para analytics de alto rendimiento
USE talentops1;
CREATE TABLE metricas_diarias (
    fecha DATE NOT NULL,
    categoria VARCHAR(50) NOT NULL,
    region VARCHAR(50) NOT NULL,
    ventas_total DECIMAL(10,2),
    ordenes_total INT,
    clientes_unicos INT,
    conversion_rate DECIMAL(5,4),

    -- Columna generada para particionamiento mensual
    fecha_yyyymm INT AS (YEAR(fecha) * 100 + MONTH(fecha)) STORED,

    PRIMARY KEY (fecha, categoria, region, fecha_yyyymm)
)
PARTITION BY RANGE (fecha_yyyymm) (
    PARTITION p202501 VALUES LESS THAN (202502),
    PARTITION p202502 VALUES LESS THAN (202503),
    PARTITION pmax VALUES LESS THAN MAXVALUE
);