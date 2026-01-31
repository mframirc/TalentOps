
CREATE TABLE hechos_ventas (
    id_venta INT NOT NULL,
    id_tiempo INT,
    id_cliente INT,
    id_producto INT,
    id_canal INT,
    id_geografia INT,
    cantidad INT,
    precio_unitario DECIMAL(10,2),
    descuento_aplicado DECIMAL(10,2),
    costo_envio DECIMAL(10,2),
    impuestos DECIMAL(10,2),
    fecha_venta DATE NOT NULL,
    primera_compra BOOLEAN,
    compra_recurrente BOOLEAN,
    cliente_vip BOOLEAN,
    PRIMARY KEY (id_venta, fecha_venta)
)
PARTITION BY RANGE (YEAR(fecha_venta)) (
    PARTITION p2022 VALUES LESS THAN (2023),
    PARTITION p2023 VALUES LESS THAN (2024),
    PARTITION p2024 VALUES LESS THAN (2025),
    PARTITION pmax VALUES LESS THAN MAXVALUE
);

### Dimensiones principales

CREATE TABLE dim_tiempo (
    id INT PRIMARY KEY,
    fecha DATE UNIQUE,
    dia INT,
    mes INT,
    nombre_mes VARCHAR(20),
    trimestre INT,
    año INT,
    dia_semana VARCHAR(10),
    numero_semana INT,
    festivo BOOLEAN,
    temporada VARCHAR(20),
    fin_semana BOOLEAN,
    dia_habil BOOLEAN
);

CREATE TABLE dim_cliente (
    id INT PRIMARY KEY,
    id_cliente_natural INT,
    nombre VARCHAR(100),
    email VARCHAR(100),
    fecha_registro DATE,
    segmento_valor VARCHAR(20),
    segmento_comportamiento VARCHAR(30),
    edad INT,
    genero VARCHAR(10),
    ciudad VARCHAR(50),
    region VARCHAR(50),
    pais VARCHAR(50),
    frecuencia_compras_mensual DECIMAL(4,1),
    valor_promedio_compra DECIMAL(10,2),
    ultima_compra DATE,
    activo BOOLEAN
);

CREATE TABLE dim_producto (
    id INT PRIMARY KEY,
    sku VARCHAR(20),
    nombre VARCHAR(100),
    descripcion TEXT,
    id_categoria INT,
    id_marca INT,
    precio_lista DECIMAL(10,2),
    costo DECIMAL(10,2),
    margen DECIMAL(5,2),
    stock_actual INT,
    stock_minimo INT,
    disponible BOOLEAN,
    fecha_lanzamiento DATE,
    temporada VARCHAR(20)
);

CREATE TABLE dim_geografia (
    id INT PRIMARY KEY,
    codigo_postal VARCHAR(10),
    ciudad VARCHAR(50),
    provincia VARCHAR(50),
    region VARCHAR(50),
    pais VARCHAR(50),
    zona_horaria VARCHAR(10),
    densidad_poblacional VARCHAR(20)
);

CREATE TABLE dim_canal_adquisicion (
    id INT PRIMARY KEY,
    nombre_canal VARCHAR(50),
    tipo_canal VARCHAR(20),
    costo_adquisicion DECIMAL(8,2),
    roi_promedio DECIMAL(5,2),
    tasa_conversion DECIMAL(5,2),
    activo BOOLEAN
);

CREATE TABLE dim_categoria (
    id INT PRIMARY KEY,
    nombre VARCHAR(50),
    categoria_padre INT,
    nivel INT,
    descripcion TEXT
);

CREATE TABLE dim_marca (
    id INT PRIMARY KEY,
    nombre VARCHAR(50),
    pais_origen VARCHAR(50),
    segmento VARCHAR(20),
    reputacion DECIMAL(3,1)
);


## 4. Datos ficticios chilenos

### Clientes

INSERT INTO dim_cliente VALUES
(1, 1001, 'Camila Rojas', 'camila.rojas@gmail.com', '2023-03-15', 'Oro', 'VIP', 34, 'Femenino', 'Providencia', 'Región Metropolitana', 'Chile', 4.2, 45000, '2024-12-01', TRUE),
(2, 1002, 'Jorge González', 'jorge.gonzalez@yahoo.com', '2022-07-10', 'Plata', 'Recurrente', 41, 'Masculino', 'Viña del Mar', 'Valparaíso', 'Chile', 2.8, 32000, '2024-11-20', TRUE),
(3, 1003, 'Valentina Muñoz', 'valentina.munoz@outlook.com', '2024-01-05', 'Bronce', 'Nuevo', 27, 'Femenino', 'Temuco', 'Araucanía', 'Chile', 1.1, 18000, '2024-12-10', TRUE);


### Productos

INSERT INTO dim_producto VALUES
(1, 'CHL-001', 'Polera Algodón Hombre', 'Polera básica 100% algodón', 1, 1, 12990, 6500, 49.9, 120, 20, TRUE, '2023-09-01', 'Primavera'),
(2, 'CHL-002', 'Zapatilla Urbana Mujer', 'Zapatilla cómoda para uso diario', 2, 2, 39990, 21000, 47.5, 80, 15, TRUE, '2024-03-15', 'Otoño'),
(3, 'CHL-003', 'Chaqueta Impermeable', 'Chaqueta outdoor resistente al agua', 3, 3, 69990, 42000, 40.0, 45, 10, TRUE, '2022-05-20', 'Invierno');

### Tiempo

INSERT INTO dim_tiempo VALUES
(1, '2024-12-01', 1, 12, 'Diciembre', 4, 2024, 'Domingo', 48, FALSE, 'Verano', TRUE, FALSE),
(2, '2024-12-10', 10, 12, 'Diciembre', 4, 2024, 'Martes', 49, FALSE, 'Verano', FALSE, TRUE),
(3, '2024-09-18', 18, 9, 'Septiembre', 3, 2024, 'Miércoles', 38, TRUE, 'Primavera', FALSE, FALSE);


### Geografía

INSERT INTO dim_geografia VALUES
(1, '7500000', 'Providencia', 'Santiago', 'Región Metropolitana', 'Chile', 'CLT', 'Alta'),
(2, '2520000', 'Viña del Mar', 'Valparaíso', 'Valparaíso', 'Chile', 'CLT', 'Media'),
(3, '4780000', 'Temuco', 'Cautín', 'Araucanía', 'Chile', 'CLT', 'Media');


### Hechos

INSERT INTO hechos_ventas (id_venta, id_tiempo, id_cliente, id_producto, id_canal, id_geografia, cantidad, precio_unitario, descuento_aplicado, costo_envio, impuestos, fecha_venta, primera_compra, compra_recurrente, cliente_vip)
VALUES
(10001, 1, 1, 1, 1, 1, 2, 12990, 1000, 2500, 1500, '2024-12-01', FALSE, TRUE, TRUE),
(10002, 2, 2, 2, 2, 2, 1, 39990, 0, 3000, 2500, '2024-12-10', FALSE, TRUE, FALSE),
(10003, 3, 3, 3, 3, 3, 1, 69990, 5000, 4000, 3500, '2024-09-18', TRUE, FALSE, FALSE);

## 5. Consultas analíticas

### Ventas por región y categoría


SELECT 
  dg.region,
  dcat.nombre AS categoria,
  SUM(hv.total_neto) AS ventas_totales
FROM hechos_ventas hv
JOIN dim_geografia dg ON hv.id_geografia = dg.id
JOIN dim_producto dp ON hv.id_producto = dp.id
JOIN dim_categoria dcat ON dp.id_categoria = dcat.id
GROUP BY dg.region, dcat.nombre;

### Comparación de consultas: Normalizado vs Dimensional:
-- Consulta en esquema NORMALIZADO (complejo, lento)
SELECT 
    dc.nombre AS nombre_cliente,
    dp.nombre AS nombre_producto,
    dcat.nombre AS nombre_categoria,
    SUM(hv.cantidad * hv.precio_unitario) AS total_ventas,
    AVG(hv.cantidad * hv.precio_unitario) AS ticket_promedio
FROM hechos_ventas hv
JOIN dim_cliente dc ON hv.id_cliente = dc.id
JOIN dim_producto dp ON hv.id_producto = dp.id
JOIN dim_categoria dcat ON dp.id_categoria = dcat.id
WHERE hv.fecha_venta BETWEEN '2024-01-01' AND '2024-12-31'
GROUP BY 
    dc.nombre,
    dp.nombre,
    dcat.nombre
ORDER BY total_ventas DESC;

-- Consulta en esquema DIMENSIONAL (simple, rápido)
SELECT 
    dc.nombre as cliente,
    dp.nombre as producto,
    dcat.nombre as categoria,
    SUM(hv.total_neto) as total_ventas,
    AVG(hv.total_neto) as ticket_promedio
FROM hechos_ventas hv
JOIN dim_tiempo dt ON hv.id_tiempo = dt.id
JOIN dim_cliente dc ON hv.id_cliente = dc.id
JOIN dim_producto dp ON hv.id_producto = dp.id
JOIN dim_categoria dcat ON dp.id_categoria = dcat.id
WHERE dt.año = 2024
GROUP BY dc.nombre, dp.nombre, dcat.nombre
ORDER BY total_ventas DESC;

### Análisis de trade-offs y recomendaciones:
-- Ventajas del diseño dimensional:
-- 1. Consultas más simples y legibles
-- 2. Performance superior para agregaciones
-- 3. Optimizado para herramientas BI
-- 4. Fácil de entender para analistas de negocio

-- Desventajas:
-- 1. Mayor redundancia de datos
-- 2. Más complejo mantenimiento de dimensiones
-- 3. Menos flexible para cambios estructurales

-- Recomendaciones de implementación:

-- 1. Indices estratégicos para performance
CREATE INDEX idx_hechos_tiempo ON hechos_ventas(id_tiempo);
CREATE INDEX idx_hechos_cliente ON hechos_ventas(id_cliente);
CREATE INDEX idx_hechos_producto ON hechos_ventas(id_producto);
CREATE INDEX idx_dimensiones_compuestas ON hechos_ventas(id_tiempo, id_cliente, id_producto);




-- 2. Particionamiento por tiempo para datasets grandes
---CREATE TABLE hechos_ventas_y2024 PARTITION OF hechos_ventas
---    FOR VALUES FROM ('2024-01-01') TO ('2025-01-01');

-- 3. Vistas materializadas para consultas frecuentes
---CREATE MATERIALIZED VIEW mv_ventas_mensuales AS
---SELECT 
---    dt.año,
---    dt.mes,
---    SUM(hv.total_neto) as ventas_total,
---    COUNT(DISTINCT hv.id_cliente) as clientes_unicos,
---    AVG(hv.total_neto) as ticket_promedio
---FROM hechos_ventas hv
---JOIN dim_tiempo dt ON hv.id_tiempo = dt.id
---GROUP BY dt.año, dt.mes;

CREATE TABLE mv_ventas_mensuales AS
SELECT 
    dt.año,
    dt.mes,
    SUM(hv.total_neto) AS ventas_total,
    COUNT(DISTINCT hv.id_cliente) AS clientes_unicos,
    AVG(hv.total_neto) AS ticket_promedio
FROM hechos_ventas hv
JOIN dim_tiempo dt ON hv.id_tiempo = dt.id
GROUP BY dt.año, dt.mes;
TRUNCATE mv_ventas_mensuales;

INSERT INTO mv_ventas_mensuales
SELECT 
    dt.año,
    dt.mes,
    SUM(hv.total_neto),
    COUNT(DISTINCT hv.id_cliente),
    AVG(hv.total_neto)
FROM hechos_ventas hv
JOIN dim_tiempo dt ON hv.id_tiempo = dt.id
GROUP BY dt.año, dt.mes;

CREATE VIEW mv_ventas_mensuales AS
SELECT 
    dt.año,
    dt.mes,
    SUM(hv.total_neto) AS ventas_total,
    COUNT(DISTINCT hv.id_cliente) AS clientes_unicos,
    AVG(hv.total_neto) AS ticket_promedio
FROM hechos_ventas hv
JOIN dim_tiempo dt ON hv.id_tiempo = dt.id
GROUP BY dt.año, dt.mes;

-- 4. Constraints para integridad
ALTER TABLE hechos_ventas ADD CONSTRAINT ck_total_neto_positivo 
    CHECK (total_neto > 0);
ALTER TABLE dim_cliente ADD CONSTRAINT ck_segmento_valido 
    CHECK (segmento_valor IN ('Bronce', 'Plata', 'Oro', 'Platino'));
                   
/*  Diagrama Estrella
                 dim_cliente
                         |
                         |
dim_producto ---- hechos_ventas ---- dim_tiempo
                         |
                         |
                    dim_sucursal
•  	hechos_ventas es el centro del modelo (medidas: ventas, cantidad, descuentos, etc.).
• 	Las dimensiones entregan contexto para el análisis:
	• 	dim_producto -> categoría, marca, tipo
	• 	dim_cliente -> segmento, ubicación, demografía
	• 	dim_tiempo -> día, mes, trimestre, año
	• 	dim_sucursal -> región, formato, zona 

El diseño dimensional simplifica el análisis porque organiza los datos en una estructura 
intuitiva: una tabla de hechos central con métricas cuantitativas y múltiples dimensiones 
que entregan contexto. Esto reduce drásticamente la complejidad de las consultas, minimiza 
los joins y acelera agregaciones como SUM, COUNT o AVG sobre grandes volúmenes de datos.
Este esquema está optimizado para análisis (OLAP) porque privilegia la lectura masiva, 
la denormalización y la velocidad de consulta, permitiendo dashboards y reportes eficientes.
 No es adecuado para operaciones transaccionales (OLTP), donde se requieren escrituras 
 rápidas, integridad estricta y alta normalización.
 */
      