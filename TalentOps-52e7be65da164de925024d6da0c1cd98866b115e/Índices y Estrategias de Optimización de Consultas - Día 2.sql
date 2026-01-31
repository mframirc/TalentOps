# Crear tablas dimensionales
USE talentops1;


CREATE TABLE dim_tiempo (
    id INT AUTO_INCREMENT PRIMARY KEY,
    fecha DATE UNIQUE,
    año INT,
    mes INT,
    trimestre INT,
    dia_semana VARCHAR(10)
);

CREATE TABLE dim_cliente (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100),
    segmento VARCHAR(20),
    region VARCHAR(50)
);

CREATE TABLE hechos_ventas (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_tiempo INT,
    id_cliente INT,
    total_venta DECIMAL(10,2),
    cantidad INT,
    margen DECIMAL(5,2),
    FOREIGN KEY (id_tiempo) REFERENCES dim_tiempo(id),
    FOREIGN KEY (id_cliente) REFERENCES dim_cliente(id)
); 



# Poblar la dimensión tiempo (2023–2024), cliente y hechos_ventas
USE talentops1;
INSERT INTO dim_tiempo (`fecha`, `año`, `mes`, `trimestre`, `dia_semana`)
SELECT 
    fecha,
    YEAR(fecha),
    MONTH(fecha),
    QUARTER(fecha),
    DAYNAME(fecha)
FROM (
    SELECT DATE('2023-01-01') + INTERVAL seq DAY AS fecha
    FROM (
        SELECT @row := @row + 1 AS seq
        FROM information_schema.tables, (SELECT @row := -1) init
        LIMIT 730
    ) AS seqs
) AS fechas;
SELECT MIN(id), MAX(id) FROM dim_tiempo;
SELECT COUNT(*) FROM dim_cliente;
SELECT MIN(id), MAX(id) FROM dim_cliente;

INSERT INTO dim_cliente (nombre, segmento, region) VALUES
('Juan Pérez', 'Retail', 'Metropolitana'),
('María González', 'Retail', 'Valparaíso'),
('Pedro Ramírez', 'Pyme', 'Biobío'),
('Carolina Muñoz', 'Corporativo', 'Coquimbo'),
('Ricardo Soto', 'Retail', 'Antofagasta'),
('Daniela Vargas', 'Pyme', 'Maule'),
('Felipe Araya', 'Corporativo', 'Los Lagos'),
('Camila Torres', 'Retail', 'O’Higgins'),
('Andrés Silva', 'Pyme', 'Araucanía'),
('Paula Herrera', 'Retail', 'Metropolitana'),
('Jorge Morales', 'Corporativo', 'Valparaíso'),
('Natalia Rojas', 'Pyme', 'Atacama'),
('Cristian Fuentes', 'Retail', 'Ñuble'),
('Fernanda Díaz', 'Corporativo', 'Los Ríos'),
('Sebastián Reyes', 'Pyme', 'Magallanes'),
('Valentina Pino', 'Retail', 'Metropolitana'),
('Gonzalo Bravo', 'Corporativo', 'Tarapacá'),
('Isidora Campos', 'Pyme', 'Arica y Parinacota'),
('Tomás Vega', 'Retail', 'Biobío'),
('Francisca Palma', 'Corporativo', 'Coquimbo'),
('Héctor Navarro', 'Pyme', 'Los Lagos'),
('Marcela Ortiz', 'Retail', 'Valparaíso'),
('Rodrigo Cáceres', 'Corporativo', 'Metropolitana'),
('Pilar Sandoval', 'Pyme', 'O’Higgins'),
('Mauricio Leiva', 'Retail', 'Antofagasta'),
('Karla Espinoza', 'Corporativo', 'Maule'),
('Benjamín Carrasco', 'Pyme', 'Araucanía'),
('Alejandra Sáez', 'Retail', 'Los Ríos'),
('Diego Contreras', 'Corporativo', 'Metropolitana'),
('Lorena Figueroa', 'Pyme', 'Coquimbo');

USE talentops1;

INSERT INTO hechos_ventas (id_tiempo, id_cliente, total_venta, cantidad, margen)
SELECT
    t.id AS id_tiempo,
    c.id AS id_cliente,
    ROUND(RAND() * 150000 + 10000, 2) AS total_venta,
    FLOOR(RAND() * 10) + 1 AS cantidad,
    ROUND(RAND() * 0.35 + 0.05, 2) AS margen
FROM dim_tiempo t
JOIN dim_cliente c
ORDER BY RAND()
LIMIT 100;

# Análisis de consultas sin optimización
-- Consulta analítica típica SIN optimización
EXPLAIN ANALYZE
SELECT 
    dt.año,
    dt.trimestre,
    dc.segmento,
    COUNT(*) as num_ventas,
    SUM(hv.total_venta) as ventas_total,
    AVG(hv.margen) as margen_promedio
FROM hechos_ventas hv
JOIN dim_tiempo dt ON hv.id_tiempo = dt.id
JOIN dim_cliente dc ON hv.id_cliente = dc.id
WHERE dt.año = 2024
  AND dc.segmento IN ('Retail', 'Pyme', 'Corporativo') /*('VIP', 'Premium') */
  AND hv.total_venta > 100
GROUP BY dt.año, dt.trimestre, dc.segmento
ORDER BY dt.año, dt.trimestre, SUM(hv.total_venta) DESC;

#Implementación de índices estratégicos
-- Crear índices para optimizar la consulta analítica
CREATE INDEX idx_hechos_tiempo ON hechos_ventas(id_tiempo);
CREATE INDEX idx_hechos_cliente ON hechos_ventas(id_cliente);
CREATE INDEX idx_tiempo_año ON dim_tiempo(año);
CREATE INDEX idx_cliente_segmento ON dim_cliente(segmento);
CREATE INDEX idx_hechos_venta_total ON hechos_ventas(total_venta);

-- Índice compuesto para consulta específica
CREATE INDEX idx_hechos_analisis ON hechos_ventas(id_tiempo, id_cliente, total_venta);

-- Verificar que los índices existen
SELECT schemaname, tablename, indexname, indexdef
FROM pg_indexes
WHERE tablename IN ('hechos_ventas', 'dim_tiempo', 'dim_cliente')
ORDER BY tablename, indexname;

#Análisis de consulta optimizada
--- Re-ejecutar consulta CON optimización
EXPLAIN ANALYZE
SELECT 
    dt.año,
    dt.trimestre,
    dc.segmento,
    COUNT(*) as num_ventas,
    SUM(hv.total_venta) as ventas_total,
    AVG(hv.margen) as margen_promedio
FROM hechos_ventas hv
JOIN dim_tiempo dt ON hv.id_tiempo = dt.id
JOIN dim_cliente dc ON hv.id_cliente = dc.id
WHERE dt.año = 2024
  AND dc.segmento IN ('Retail', 'Pyme', 'Corporativo') /*('VIP', 'Premium')*/ 
  AND hv.total_venta > 100
GROUP BY dt.año, dt.trimestre, dc.segmento
ORDER BY dt.año, dt.trimestre, SUM(hv.total_venta) DESC;

#Implementación de particionamiento para escalabilidad
-- Renombrar tabla actual
RENAME TABLE hechos_ventas TO hechos_ventas_old;
USE talentops1;
-- Crear nueva tabla particionada con misma estructura lógica
CREATE TABLE hechos_ventas (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_tiempo INT NOT NULL,
    id_cliente INT NOT NULL,
    total_venta DECIMAL(10,2),
    cantidad INT,
    margen DECIMAL(5,2),
 --   FOREIGN KEY (id_tiempo) REFERENCES dim_tiempo(id),
 --   FOREIGN KEY (id_cliente) REFERENCES dim_cliente(id)
)
PARTITION BY RANGE (id_tiempo)
SUBPARTITION BY HASH (id_cliente)
SUBPARTITIONS 4 (
    PARTITION p2023m01 VALUES LESS THAN (32),
    PARTITION p2023m02 VALUES LESS THAN (60),
    PARTITION p2023m03 VALUES LESS THAN (91),
    PARTITION p2023m04 VALUES LESS THAN (121),
    PARTITION p2023m05 VALUES LESS THAN (152),
    PARTITION p2023m06 VALUES LESS THAN (182),
    PARTITION p2023m07 VALUES LESS THAN (213),
    PARTITION p2023m08 VALUES LESS THAN (244),
    PARTITION p2023m09 VALUES LESS THAN (274),
    PARTITION p2023m10 VALUES LESS THAN (305),
    PARTITION p2023m11 VALUES LESS THAN (335),
    PARTITION p2023m12 VALUES LESS THAN (366),
    PARTITION pmax VALUES LESS THAN MAXVALUE
);

-- Migrar datos desde la tabla antigua
INSERT INTO hechos_ventas (id, id_tiempo, id_cliente, total_venta, cantidad, margen)
SELECT id, id_tiempo, id_cliente, total_venta, cantidad, margen
FROM hechos_ventas_old;

# MySQL no permite usar claves foráneas en tablas que están particionadas. 
# segun manual y tampoco vistas materializadas
 RENAME TABLE hechos_ventas_old TO hechos_ventas;
 
 CREATE MATERIALIZED VIEW mv_ventas_mensuales AS
SELECT 
    dt.año,
    dt.mes,
    dc.segmento,
    COUNT(*) as num_ventas,
    SUM(hv.total_venta) as ventas_total,
    AVG(hv.margen) as margen_promedio
FROM hechos_ventas hv
JOIN dim_tiempo dt ON hv.id_tiempo = dt.id
JOIN dim_cliente dc ON hv.id_cliente = dc.id
GROUP BY dt.año, dt.mes, dc.segmento;

-- Índice en vista materializada
CREATE INDEX idx_mv_mensual ON mv_ventas_mensuales(año, mes, segmento);

/* >>>>>>>>>>>>>>>>  R E U M E N <<<<<<<<<<<<<<<<<<<<<<<<<<

Cómo los índices y el particionamiento aceleran consultas de minutos a 
milisegundos, Cuando una tabla crece a millones de filas, una consulta sin 
optimización obliga al motor a recorrer toda la tabla (full table scan). 
Ese recorrido puede tomar segundos o incluso minutos.
Los índices y el particionamiento cambian completamente ese escenario porque 
reducen drásticamente la cantidad de datos que el motor necesita leer.

Índices:
Un índice funciona como el índice de un libro: en lugar de revisar todas las
páginas, vas directo al punto exacto,Esto transforma una búsqueda de millones 
de filas en una búsqueda de decenas o cientos.
• 	Índices B-Tree
Ideales para columnas con búsquedas por igualdad o rango (fechas, IDs, montos).
Permiten saltar directamente al segmento de datos relevante.
• 	Índices compuestos
Útiles cuando las consultas filtran por más de una columna en un orden 
predecible (por ejemplo: año -> mes -> segmento), Evitan múltiples búsquedas 
separadas.
• 	Índices hash (o equivalentes en motores que los soportan)
Funcionan muy bien para búsquedas exactas (), No sirven para rangos, 
pero son extremadamente rápidos para igualdad.El efecto práctico:
- Sin índice: el motor revisa millones de filas.
- Con índice: revisa solo las filas que cumplen la condición, a veces menos 
del 0.1%.

Particionamiento
El particionamiento divide una tabla grande en “trozos” más pequeños, 
normalmente por fecha.
Cuando una consulta filtra por un rango temporal, el motor ignora todas las 
particiones que no corresponden.
Ejemplo:
Si tienes 24 particiones mensuales y consultas solo enero 2024, MySQL lee 1 
partición en vez de 24, Eso reduce el trabajo en un factor de 10x, 20x o más.
Además:
-  	Las particiones pequeñas caben mejor en memoria.
- 	Los índices dentro de cada partición son más pequeños y más rápidos.
- 	Las operaciones de mantenimiento (archivar, borrar, optimizar) afectan 
solo una partición, no toda la tabla.

Cuándo usar cada tipo de índice
- 	Índice en columna de fecha (B-Tree)
Cuando las consultas filtran por períodos: meses, años, trimestres,Es el índice
 más común en tablas de hechos.
• 	Índice en claves foráneas (id_cliente, id_producto)
Útil para joins frecuentes con dimensiones,Reduce el costo de unir tablas 
grandes.
• 	Índice compuesto (año, mes, segmento)
Ideal cuando la consulta siempre sigue ese orden lógico, Evita que el motor
combine varios índices menos eficientes.
• 	Índice en columnas muy selectivas (RUT, email, SKU)
Perfecto cuando cada valor identifica pocas filas,Acelera búsquedas puntuales.

Cómo todo esto se combina para lograr milisegundos
1. 	El particionamiento reduce el universo de búsqueda:de millones de filas a 
solo las del mes o año consultado.
2. 	El índice dentro de la partición encuentra rápidamente las filas relevantes,
de miles de filas a decenas.
3. 	El motor ejecuta agregaciones sobre un conjunto mínimo de datos,
sumas, promedios y conteos se vuelven instantáneos.

El resultado:
Una consulta que antes recorría toda la tabla ahora toca solo una fracción 
diminuta.
Ese cambio estructural es lo que transforma tiempos de minutos en milisegundos.
*/