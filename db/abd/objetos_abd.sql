-- ============================================================================
-- objetos_abd.sql
-- Objetos de base de datos para el esquema ABD (tablas del millon de registros).
-- Complementa la migracion Flyway V6__replica_abd_sgroas.sql agregando:
--   1. Indices de optimizacion para las consultas analiticas.
--   2. Stored procedures con cursores (REFCURSOR) sobre las tablas ABD.
--   3. Trigger que deriva alertas automaticamente desde incidentes de nivel ALTO.
--   4. Roles y privilegios (GRANT) diferenciados.
-- Uso:
--   docker exec -i sgroas-postgres psql -U postgres -d sgroas_db -f - < db/abd/objetos_abd.sql
-- ============================================================================

BEGIN;

-- ============================================================================
-- 1) INDICES DE OPTIMIZACION (complementan los de V6 / generador)
--    Apoyan las consultas de los stored procedures y el EXPLAIN ANALYZE.
-- ============================================================================
CREATE INDEX IF NOT EXISTS idx_abd_incidente_nivel_estado
    ON incidente (nivel_sugerido, estado);

CREATE INDEX IF NOT EXISTS idx_abd_incidente_fecha
    ON incidente (fecha_incidente);

CREATE INDEX IF NOT EXISTS idx_abd_programacion_estado_fecha
    ON programacion (estado, fecha);

CREATE INDEX IF NOT EXISTS idx_abd_programacion_unidad_fecha
    ON programacion (id_unidad, fecha);

CREATE INDEX IF NOT EXISTS idx_abd_auditoria_accion_fecha
    ON auditoria (accion, fecha_hora);

CREATE INDEX IF NOT EXISTS idx_abd_conductor_fecha_vencimiento
    ON conductor (fecha_vencimiento);

CREATE INDEX IF NOT EXISTS idx_abd_unidad_estado
    ON unidad (estado);

-- ============================================================================
-- 2) STORED PROCEDURES / FUNCIONES con cursores (REFCURSOR)
--    Se invocan via JPA @Procedure igual que en CATALOGO-SP.md.
-- ============================================================================

-- ------------------------------------------------------------
-- sp_abd_incidentes_por_nivel
-- Conteo de incidentes agrupado por nivel de riesgo sugerido.
-- Invocacion JPA: @Procedure(name = "IncidenteAbd.incidentesPorNivel")
-- ------------------------------------------------------------
CREATE OR REPLACE PROCEDURE sp_abd_incidentes_por_nivel(
    INOUT cur refcursor
)
    LANGUAGE plpgsql
AS $$
BEGIN
    OPEN cur FOR
    SELECT nivel_sugerido,
           COUNT(*)::BIGINT AS total,
           MAX(fecha_incidente) AS ultimo
    FROM incidente
    GROUP BY nivel_sugerido
    ORDER BY total DESC;
END;
$$;

-- ------------------------------------------------------------
-- sp_abd_programaciones_por_estado
-- Resumen de programaciones por estado en un rango de fechas.
-- Invocacion JPA: @Procedure(name = "ProgramacionAbd.programacionesPorEstado")
-- ------------------------------------------------------------
CREATE OR REPLACE PROCEDURE sp_abd_programaciones_por_estado(
    p_fecha_desde DATE,
    p_fecha_hasta DATE,
    INOUT cur refcursor
)
    LANGUAGE plpgsql
AS $$
BEGIN
    OPEN cur FOR
    SELECT estado,
           COUNT(*)::BIGINT AS total
    FROM programacion
    WHERE fecha BETWEEN p_fecha_desde AND p_fecha_hasta
    GROUP BY estado
    ORDER BY total DESC;
END;
$$;

-- ------------------------------------------------------------
-- sp_abd_unidades_mantenimiento
-- Unidades en mantenimiento (estado) con su ultima fecha de uso.
-- Invocacion JPA: @Procedure(name = "UnidadAbd.unidadesMantenimiento")
-- ------------------------------------------------------------
CREATE OR REPLACE PROCEDURE sp_abd_unidades_mantenimiento(
    INOUT cur refcursor
)
    LANGUAGE plpgsql
AS $$
BEGIN
    OPEN cur FOR
    SELECT u.id_unidad,
           u.placa,
           u.modelo,
           u.capacidad,
           COUNT(p.id_programacion)::BIGINT AS total_programaciones
    FROM unidad u
             LEFT JOIN programacion p ON p.id_unidad = u.id_unidad
    WHERE u.estado = 'En Mantenimiento'
    GROUP BY u.id_unidad, u.placa, u.modelo, u.capacidad
    ORDER BY u.placa;
END;
$$;

-- ------------------------------------------------------------
-- fn_abd_licencias_por_vencer
-- Conductores (esquema ABD) cuya licencia vence en los proximos N dias.
-- Invocacion JPA: @Procedure(name = "ConductorAbd.licenciasPorVencer")
-- ------------------------------------------------------------
CREATE OR REPLACE PROCEDURE fn_abd_licencias_por_vencer(
    p_dias_umbral INTEGER,
    INOUT cur refcursor
)
    LANGUAGE plpgsql
AS $$
BEGIN
    OPEN cur FOR
    SELECT c.id_conductor,
           c.nombres,
           c.cedula::VARCHAR,
           c.licencia::VARCHAR,
           c.fecha_vencimiento
    FROM conductor c
    WHERE c.fecha_vencimiento BETWEEN CURRENT_DATE
          AND (CURRENT_DATE + p_dias_umbral)
    ORDER BY c.fecha_vencimiento;
END;
$$;

-- ------------------------------------------------------------
-- fn_abd_resumen_flota
-- KPIs generales del esquema ABD (equivalente a fn_estadisticas_generales
-- pero sobre las tablas del millon de registros).
-- Invocacion JPA: @Procedure(name = "ResumenAbd.resumenFlota")
-- ------------------------------------------------------------
CREATE OR REPLACE PROCEDURE fn_abd_resumen_flota(
    INOUT cur refcursor
)
    LANGUAGE plpgsql
AS $$
BEGIN
    OPEN cur FOR
    SELECT
        (SELECT COUNT(*) FROM conductor)::BIGINT            AS total_conductores,
        (SELECT COUNT(*) FROM unidad)::BIGINT               AS total_unidades,
        (SELECT COUNT(*) FROM unidad WHERE estado = 'Activo')::BIGINT AS unidades_activas,
        (SELECT COUNT(*) FROM ruta)::BIGINT                 AS total_rutas,
        (SELECT COUNT(*) FROM programacion)::BIGINT         AS total_programaciones,
        (SELECT COUNT(*) FROM programacion WHERE estado = 'Programado')::BIGINT AS programaciones_programadas,
        (SELECT COUNT(*) FROM incidente)::BIGINT            AS total_incidentes,
        (SELECT COUNT(*) FROM incidente WHERE estado = 'Abierto')::BIGINT AS incidentes_abiertos,
        (SELECT COUNT(*) FROM auditoria)::BIGINT            AS total_auditoria;
END;
$$;

-- ============================================================================
-- 3) TRIGGER: derivacion automatica de alertas desde incidentes nivel ALTO
--    Al insertar/actualizar un incidente con nivel_sugerido = 'ALTO' se crea
--    automaticamente una fila en alerta (regla de negocio).
-- ============================================================================
CREATE OR REPLACE FUNCTION fn_alerta_incidente_alto()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.nivel_sugerido = 'ALTO' THEN
        INSERT INTO alerta (nivel_riesgo, descripcion, fecha, id_incidente)
        VALUES ('ALTO',
                'Alerta automatica por incidente ' || NEW.id_incidente || ': ' || NEW.tipo,
                NEW.fecha_incidente,
                NEW.id_incidente);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_abd_incidente_alto ON incidente;
CREATE TRIGGER trg_abd_incidente_alto
    AFTER INSERT OR UPDATE ON incidente
    FOR EACH ROW
    EXECUTE FUNCTION fn_alerta_incidente_alto();

-- ============================================================================
-- 4) ROLES y PRIVILEGIOS (GRANT) sobre el esquema ABD
--    Tres perfiles con privilegios diferenciados.
-- ============================================================================
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'abd_lectura') THEN
        CREATE ROLE abd_lectura;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'abd_operador') THEN
        CREATE ROLE abd_operador;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'abd_auditor') THEN
        CREATE ROLE abd_auditor;
    END IF;
END $$;

-- Perfil de SOLO LECTURA (consultas y reportes)
GRANT CONNECT ON DATABASE sgroas_db TO abd_lectura;
GRANT USAGE ON SCHEMA public TO abd_lectura;
GRANT SELECT ON provincia, ciudad, terminal, rol, usuario, conductor,
    unidad, ruta, programacion, incidente, alerta, auditoria
    TO abd_lectura;

-- Perfil OPERADOR (mantiene programaciones e incidentes, pero solo lee catalogos)
GRANT CONNECT ON DATABASE sgroas_db TO abd_operador;
GRANT USAGE ON SCHEMA public TO abd_operador;
GRANT SELECT ON provincia, ciudad, terminal, rol, conductor, unidad, ruta TO abd_operador;
GRANT SELECT, INSERT, UPDATE ON programacion, incidente TO abd_operador;
GRANT USAGE, SELECT ON SEQUENCE programacion_id_programacion_seq, incidente_id_incidente_seq TO abd_operador;

-- Perfil AUDITOR (solo lectura en todo + acceso a la tabla de auditoria)
GRANT CONNECT ON DATABASE sgroas_db TO abd_auditor;
GRANT USAGE ON SCHEMA public TO abd_auditor;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO abd_auditor;
GRANT SELECT, INSERT ON auditoria TO abd_auditor;

COMMIT;

-- ============================================================================
-- Verificacion rapida (correr manualmente despues de aplicar el script):
--   SELECT proname FROM pg_proc p
--     JOIN pg_namespace n ON n.oid = p.pronamespace
--    WHERE n.nspname = 'public' AND p.prokind IN ('p','f')
--      AND proname LIKE 'sp_abd%' OR proname LIKE 'fn_abd%';
--   SELECT tgname FROM pg_trigger WHERE NOT tgisinternal AND tgname = 'trg_abd_incidente_alto';
--   SELECT rolname FROM pg_roles WHERE rolname LIKE 'abd_%';
-- ============================================================================
