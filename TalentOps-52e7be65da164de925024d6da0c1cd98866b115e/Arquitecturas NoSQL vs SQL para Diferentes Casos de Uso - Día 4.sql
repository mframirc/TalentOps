-- =========================================================
-- ARQUITECTURA LÓGICA HÍBRIDA DENTRO DE MYSQL
-- Plataforma de streaming de video
-- =========================================================

-- ---------------------------------------------------------
-- 1. ESQUEMA TRANSACCIONAL (OLTP) - "command side"
-- ---------------------------------------------------------
CREATE DATABASE IF NOT EXISTS streaming_oltp;
USE streaming_oltp;

-- Usuarios maestros
CREATE TABLE usuarios (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    email           VARCHAR(255) NOT NULL UNIQUE,
    nombre          VARCHAR(150) NOT NULL,
    pais            VARCHAR(50),
    fecha_registro  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- Planes de suscripción
CREATE TABLE planes (
    id              INT AUTO_INCREMENT PRIMARY KEY,
    nombre          VARCHAR(100) NOT NULL,
    precio_mensual  DECIMAL(8,2) NOT NULL,
    calidad_max     VARCHAR(20),
    dispositivos_max INT,
    activo          TINYINT(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB;

-- Métodos de pago (catálogo)
CREATE TABLE metodos_pago (
    id          INT AUTO_INCREMENT PRIMARY KEY,
    nombre      VARCHAR(50) NOT NULL,
    proveedor   VARCHAR(50),
    activo      TINYINT(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB;

-- Pagos
CREATE TABLE pagos (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    usuario_id      BIGINT NOT NULL,
    metodo_pago_id  INT NOT NULL,
    monto           DECIMAL(10,2) NOT NULL,
    moneda          VARCHAR(10) NOT NULL DEFAULT '$',
    fecha_pago      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    estado          VARCHAR(20) NOT NULL, -- 'APROBADO', 'RECHAZADO', etc.
    referencia_ext  VARCHAR(255),
    CONSTRAINT fk_pagos_usuario
        FOREIGN KEY (usuario_id) REFERENCES usuarios(id),
    CONSTRAINT fk_pagos_metodo
        FOREIGN KEY (metodo_pago_id) REFERENCES metodos_pago(id)
) ENGINE=InnoDB;

-- Suscripciones
CREATE TABLE suscripciones (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    usuario_id      BIGINT NOT NULL,
    plan_id         INT NOT NULL,
    pago_id         BIGINT,
    fecha_inicio    DATE NOT NULL,
    fecha_fin       DATE,
    estado          VARCHAR(20) NOT NULL, -- 'ACTIVA', 'CANCELADA', 'PAUSADA'
    precio_mensual  DECIMAL(8,2) NOT NULL,
    metodo_pago     VARCHAR(50),
    creado_en       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    actualizado_en  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_suscripciones_usuario
        FOREIGN KEY (usuario_id) REFERENCES usuarios(id),
    CONSTRAINT fk_suscripciones_plan
        FOREIGN KEY (plan_id) REFERENCES planes(id),
    CONSTRAINT fk_suscripciones_pago
        FOREIGN KEY (pago_id) REFERENCES pagos(id)
) ENGINE=InnoDB;

-- Índices típicos para joins y consultas
CREATE INDEX idx_suscripciones_usuario ON suscripciones(usuario_id);
CREATE INDEX idx_suscripciones_plan ON suscripciones(plan_id);
CREATE INDEX idx_pagos_usuario_fecha ON pagos(usuario_id, fecha_pago);


-- ---------------------------------------------------------
-- 2. ESQUEMA ANALÍTICO / EVENTOS (time-series) - "query side"
--    Emulando Cassandra dentro de MySQL
-- ---------------------------------------------------------
CREATE DATABASE IF NOT EXISTS streaming_events;
USE streaming_events;

-- Tabla de eventos de reproducción (time-series)
-- Se puede combinar con particionamiento por fecha para volumen masivo

CREATE TABLE eventos_reproduccion (
    id                  BIGINT AUTO_INCREMENT PRIMARY KEY,
    usuario_id          BIGINT NOT NULL,
    contenido_id        BIGINT NOT NULL,
    ts_evento           DATETIME NOT NULL,
    duracion_reproducida INT NOT NULL,
    posicion_actual     INT NOT NULL,
    dispositivo         VARCHAR(50),
    calidad             VARCHAR(20),
    ip                  VARCHAR(45),
    region              VARCHAR(50),
    creado_en           DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_eventos_usuario_ts (usuario_id, ts_evento),
    INDEX idx_eventos_contenido_ts (contenido_id, ts_evento)
) ENGINE=InnoDB;

-- Ejemplo de particionamiento por rango de fecha (opcional)
-- MySQL exige que todas las columnas utilizadas en la expresión de 
-- particionamiento estén incluidas en la clave primaria de la tabla
 -- ALTER TABLE eventos_reproduccion
 -- PARTITION BY RANGE (YEAR(ts_evento)) (
 --    PARTITION p2024 VALUES LESS THAN (2025),
 --    PARTITION p2025 VALUES LESS THAN (2026),
 --    PARTITION pmax  VALUES LESS THAN MAXVALUE
 -- );

-- Tabla agregada para métricas de contenido (tipo "materialized view" manual)
CREATE TABLE contenido_metrics_diario (
    fecha           DATE NOT NULL,
    contenido_id    BIGINT NOT NULL,
    reproducciones  BIGINT NOT NULL,
    usuarios_unicos BIGINT NOT NULL,
    minutos_vistos  BIGINT NOT NULL,
    PRIMARY KEY (fecha, contenido_id)
) ENGINE=InnoDB;

-- Vista para consultas rápidas de métricas recientes
CREATE VIEW vw_contenido_metrics_ultimos_7_dias AS
SELECT
    contenido_id,
    SUM(reproducciones)  AS reproducciones_7d,
    SUM(usuarios_unicos) AS usuarios_unicos_7d,
    SUM(minutos_vistos)  AS minutos_vistos_7d
FROM contenido_metrics_diario
WHERE fecha >= (CURRENT_DATE - INTERVAL 7 DAY)
GROUP BY contenido_id;


-- ---------------------------------------------------------
-- 3. ESQUEMA DE RECOMENDACIONES / GRAFO SIMPLIFICADO
--    Emulando Neo4j con tablas relacionales
-- ---------------------------------------------------------
CREATE DATABASE IF NOT EXISTS streaming_graph;
USE streaming_graph;

-- Catálogo de contenido
CREATE TABLE contenido (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    titulo          VARCHAR(255) NOT NULL,
    tipo            VARCHAR(50), -- 'PELÍCULA', 'SERIE', etc.
    rating_promedio DECIMAL(3,2),
    temporadas      INT,
    creado_en       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- Géneros
CREATE TABLE generos (
    id          INT AUTO_INCREMENT PRIMARY KEY,
    nombre      VARCHAR(100) NOT NULL UNIQUE
) ENGINE=InnoDB;

-- Relación contenido-género (similar a DEL_GENERO)
CREATE TABLE contenido_generos (
    contenido_id    BIGINT NOT NULL,
    genero_id       INT NOT NULL,
    PRIMARY KEY (contenido_id, genero_id),
    CONSTRAINT fk_cg_contenido
        FOREIGN KEY (contenido_id) REFERENCES contenido(id),
    CONSTRAINT fk_cg_genero
        FOREIGN KEY (genero_id) REFERENCES generos(id)
) ENGINE=InnoDB;

-- Relación usuario-contenido (similar a VIO)
CREATE TABLE usuario_contenido (
    usuario_id      BIGINT NOT NULL,
    contenido_id    BIGINT NOT NULL,
    rating          INT,
    tiempo_completo TINYINT(1),
    ts_ultimo_visto DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (usuario_id, contenido_id),
    INDEX idx_uc_contenido (contenido_id),
    CONSTRAINT fk_uc_contenido
        FOREIGN KEY (contenido_id) REFERENCES contenido(id)
) ENGINE=InnoDB;

-- Tabla de recomendaciones calculadas (read model)
CREATE TABLE recomendaciones_usuario (
    usuario_id      BIGINT NOT NULL,
    contenido_id    BIGINT NOT NULL,
    score_afinidad  DECIMAL(5,4) NOT NULL,
    generado_en     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (usuario_id, contenido_id),
    INDEX idx_rec_usuario_score (usuario_id, score_afinidad DESC)
) ENGINE=InnoDB;

-- Ejemplo de query tipo "recomendaciones por afinidad de género"
-- (equivalente conceptual al MATCH de Neo4j)
-- Esta query podría alimentar la tabla recomendaciones_usuario

INSERT INTO recomendaciones_usuario (usuario_id, contenido_id, score_afinidad)
SELECT
    u1.usuario_id,
    c2.id AS contenido_id,
    COUNT(*) * 1.0 AS score_afinidad
FROM usuario_contenido u1
JOIN contenido_generos cg1 ON u1.contenido_id = cg1.contenido_id
JOIN contenido_generos cg2 ON cg1.genero_id = cg2.genero_id
JOIN contenido c2 ON cg2.contenido_id = c2.id
LEFT JOIN usuario_contenido u2
    ON u2.usuario_id = u1.usuario_id AND u2.contenido_id = c2.id
WHERE u1.usuario_id = ?          -- usuario objetivo
  AND u2.contenido_id IS NULL    -- aún no visto
GROUP BY u1.usuario_id, c2.id
ORDER BY score_afinidad DESC
LIMIT 50;



-- ---------------------------------------------------------
-- 4. ESQUEMA DE BÚSQUEDA / FULLTEXT (emulando Elasticsearch)
-- ---------------------------------------------------------
CREATE DATABASE IF NOT EXISTS streaming_search;
USE streaming_search;

-- Índice de contenido para búsqueda
CREATE TABLE contenido_search (
    id              BIGINT PRIMARY KEY,
    titulo          VARCHAR(255) NOT NULL,
    descripcion     TEXT,
    genero          VARCHAR(255), -- lista separada por comas
    actores         VARCHAR(255),
    rating_promedio DECIMAL(3,2),
    temporadas      INT,
    FULLTEXT INDEX ft_titulo_descripcion (titulo, descripcion),
    FULLTEXT INDEX ft_genero_actores (genero, actores)
) ENGINE=InnoDB;

-- Ejemplo de inserción (equivalente al PUT de Elasticsearch)
INSERT INTO contenido_search (
    id, titulo, descripcion, genero, actores, rating_promedio, temporadas
) VALUES (
    100,
    'Serie Drama Completa',
    'Serie de drama intenso...',
    'Drama,Suspenso',
    'Actor A,Actor B',
    4.5,
    3
);

-- Ejemplo de búsqueda (equivalente al GET /_search)
-- Búsqueda por texto + filtro de rating
ALTER TABLE contenido_search
ADD FULLTEXT INDEX ft_titulo_descripcion (titulo, descripcion);

ALTER TABLE contenido_search
ADD FULLTEXT INDEX ft_genero (genero);
SELECT
    id,
    titulo,
    rating_promedio,
    temporadas
FROM contenido_search
WHERE MATCH(titulo, descripcion) AGAINST ('+drama' IN BOOLEAN MODE)
  AND MATCH(genero) AGAINST ('+Drama +Suspenso' IN BOOLEAN MODE)
  AND rating_promedio >= 4.0
ORDER BY rating_promedio DESC;

SELECT *
FROM contenido_search
WHERE titulo LIKE '%drama%'
  AND genero LIKE '%Suspenso%';

-- ---------------------------------------------------------
-- 5. "CACHE" LÓGICA (emulando Redis) CON TABLA VOLÁTIL
-- ---------------------------------------------------------
CREATE DATABASE IF NOT EXISTS streaming_cache;
USE streaming_cache;

-- Tabla para cachear recomendaciones por usuario
CREATE TABLE cache_recomendaciones (
    usuario_id      BIGINT NOT NULL,
    contenido_id    BIGINT NOT NULL,
    score_afinidad  DECIMAL(5,4) NOT NULL,
    expiracion      DATETIME NOT NULL,
    PRIMARY KEY (usuario_id, contenido_id),
    INDEX idx_cache_usuario (usuario_id),
    INDEX idx_cache_expiracion (expiracion)
) ENGINE=InnoDB;

-- Limpieza periódica de cache (simulando TTL)
-- Podría ejecutarse con un EVENT de MySQL
/*
CREATE EVENT IF NOT EXISTS ev_purge_cache_recomendaciones
ON SCHEDULE EVERY 5 MINUTE
DO
    DELETE FROM cache_recomendaciones
    WHERE expiracion < NOW();
*/


-- ---------------------------------------------------------
-- 6. PATRÓN CQRS SIMPLIFICADO DENTRO DE MYSQL
--    Separación lógica de "command" y "query"
-- ---------------------------------------------------------
-- NOTA: Aquí la separación es lógica: distintos esquemas y tablas
--       para escritura normalizada (OLTP) y lectura optimizada (read models).

USE streaming_oltp;

-- Procedimiento para crear suscripción (lado comando)
DELIMITER $$

CREATE PROCEDURE sp_create_subscription (
    IN p_usuario_id BIGINT,
    IN p_plan_id INT,
    IN p_metodo_pago_id INT,
    IN p_monto DECIMAL(10,2),
    IN p_moneda VARCHAR(10)
)
BEGIN
    DECLARE v_precio_mensual DECIMAL(8,2);
    DECLARE v_estado_pago VARCHAR(20);
    DECLARE v_pago_id BIGINT;

    -- Validar usuario
    IF NOT EXISTS (SELECT 1 FROM usuarios WHERE id = p_usuario_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Usuario no existe';
    END IF;

    -- Validar plan
    IF NOT EXISTS (SELECT 1 FROM planes WHERE id = p_plan_id AND activo = 1) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Plan no disponible';
    END IF;

    -- Obtener precio del plan
    SELECT precio_mensual INTO v_precio_mensual
    FROM planes
    WHERE id = p_plan_id;

    -- Simular procesamiento de pago (aquí siempre aprobado)
    SET v_estado_pago = 'APROBADO';

    INSERT INTO pagos (usuario_id, metodo_pago_id, monto, moneda, estado)
    VALUES (p_usuario_id, p_metodo_pago_id, p_monto, p_moneda, v_estado_pago);

    SET v_pago_id = LAST_INSERT_ID();

    -- Crear suscripción
    INSERT INTO suscripciones (
        usuario_id, plan_id, pago_id, fecha_inicio, estado, precio_mensual, metodo_pago
    ) VALUES (
        p_usuario_id, p_plan_id, v_pago_id, CURRENT_DATE, 'ACTIVA', v_precio_mensual,
        (SELECT nombre FROM metodos_pago WHERE id = p_metodo_pago_id)
    );

    -- Aquí se podría "publicar evento" a otros esquemas mediante inserciones
    -- en tablas de eventos o colas internas.
    -- Ejemplo: insertar en tabla de eventos para read models.
    INSERT INTO streaming_events.eventos_reproduccion (
        usuario_id, contenido_id, ts_evento, duracion_reproducida, posicion_actual,
        dispositivo, calidad, ip, region
    ) VALUES (
        p_usuario_id, 0, NOW(), 0, 0, 'SUSCRIPCION', 'N/A', '0.0.0.0', 'GLOBAL'
    );
END$$

DELIMITER ;

-- Ejemplo de uso:
CALL sp_create_subscription(123, 1, 1, 1500.00, '$');


-- ---------------------------------------------------------
-- 7. CONSULTA DE RECOMENDACIONES (lado query)
-- ---------------------------------------------------------
USE streaming_graph;

-- Vista para obtener recomendaciones desde read model
CREATE OR REPLACE VIEW vw_recomendaciones_usuario AS
SELECT
    r.usuario_id,
    r.contenido_id,
    c.titulo,
    r.score_afinidad,
    r.generado_en
FROM recomendaciones_usuario r
JOIN contenido c ON c.id = r.contenido_id;

-- Ejemplo de consulta:
SELECT * FROM vw_recomendaciones_usuario WHERE usuario_id = 123 ORDER BY score_afinidad DESC LIMIT 20;

/* >>>>>>>>>>>> Verificación<<<<<<<<<<<<<: 
¿por qué elegir esta arquitectura híbrida (lógica) sobre SQL puro o NoSQL puro?

Una arquitectura híbrida se elige porque ningún tipo de base de datos resuelve bien 
todos los problemas. SQL es excelente para transacciones críticas, mientras que los
modelos orientados a eventos, búsqueda o recomendaciones funcionan mejor con 
estructuras más flexibles.
Frente a SQL puro, el híbrido permite separar cargas muy distintas: transacciones, 
eventos masivos, lecturas rápidas y búsquedas. Esto evita que un solo esquema se 
vuelva lento y difícil de escalar.
Frente a NoSQL puro, el híbrido mantiene la consistencia fuerte que necesitan pagos,
planes y reporting financiero, donde SQL sigue siendo la herramienta más confiable.
El costo es mayor complejidad, más modelos, más sincronización y más coordinación. 
Se controla con buena documentación, procesos claros, colas de eventos y modelos 
de lectura que se regeneran fácilmente sin afectar el núcleo del negocio.
*/