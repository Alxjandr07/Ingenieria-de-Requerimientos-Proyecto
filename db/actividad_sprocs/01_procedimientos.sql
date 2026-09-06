-- ============================================================================
-- ACTIVIDAD: Procedimientos Almacenados - SGROAS
-- Esquema BACKEND: conductores, vehiculos, rutas, asignacion_rutas, incidentes
--
-- IMPORTANTE (PostgreSQL): los PROCEDURE invocados con CALL pueden controlar
-- la transaccion con COMMIT / ROLLBACK. NO se puede hacer COMMIT/ROLLBACK
-- dentro de un bloque EXCEPTION (eso genera error), por eso todo el control
-- transaccional (COMMIT al final y ROLLBACK dentro de cada validacion con IF)
-- se hace DIRECTAMENTE en el cuerpo del procedimiento.
--
-- Los procedimientos administran la transaccion INTERNAMENTE y se ejecutan:
--     CALL nombre_procedimiento(...);
-- ============================================================================

-- ============================================================================
-- PROCEDIMIENTO 1: sp_registrar_conductor
-- Objetivo  : Registrar un nuevo conductor validando que no exista otro con
--             la misma cedula o numero de licencia, y que el email sea valido.
-- Operacion : INSERT
-- Validaciones: cedula de 10 digitos, email con '@', unicidad (cedula/licencia)
-- Control   : ROLLBACK si falla validacion / COMMIT al finalizar OK
-- ============================================================================
CREATE OR REPLACE PROCEDURE sp_registrar_conductor(
    p_nombres          VARCHAR,
    p_apellidos        VARCHAR,
    p_cedula           VARCHAR,
    p_numero_licencia  VARCHAR,
    p_tipo_licencia    VARCHAR,
    p_fecha_vto_lic    DATE,
    p_telefono         VARCHAR,
    p_email            VARCHAR
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Validacion 1: cedula debe tener 10 digitos
    IF char_length(p_cedula) <> 10 THEN
        ROLLBACK;  -- Revertimos cualquier cambio previo
        RAISE EXCEPTION 'CEDULA_INVALIDA: La cedula debe tener 10 digitos';
    END IF;

    -- Validacion 2: email debe contener '@'
    IF p_email IS NOT NULL AND POSITION('@' IN p_email) = 0 THEN
        ROLLBACK;
        RAISE EXCEPTION 'EMAIL_INVALIDO: El correo debe contener @';
    END IF;

    -- Validacion 3: no debe existir cedula duplicada
    IF EXISTS (SELECT 1 FROM conductores WHERE cedula = p_cedula) THEN
        ROLLBACK;
        RAISE EXCEPTION 'CEDULA_DUPLICADA: Ya existe un conductor con la cedula %', p_cedula;
    END IF;

    -- Validacion 4: no debe existir numero de licencia duplicado
    IF EXISTS (SELECT 1 FROM conductores WHERE numero_licencia = p_numero_licencia) THEN
        ROLLBACK;
        RAISE EXCEPTION 'LICENCIA_DUPLICADA: Ya existe un conductor con la licencia %', p_numero_licencia;
    END IF;

    -- Insert del conductor
    INSERT INTO conductores
        (nombres, apellidos, cedula, numero_licencia, tipo_licencia,
         fecha_vencimiento_licencia, telefono, email, estado, activo)
    VALUES
        (p_nombres, p_apellidos, p_cedula, p_numero_licencia, p_tipo_licencia,
         p_fecha_vto_lic, p_telefono, p_email, 'ACTIVO', TRUE);

    COMMIT;  -- La operacion finalizo correctamente -> confirmamos
    RAISE NOTICE 'PROCEDIMIENTO OK: Conductor % % registrado correctamente.', p_nombres, p_apellidos;
END;
$$;

-- ============================================================================
-- PROCEDIMIENTO 2: sp_registrar_vehiculo
-- Objetivo  : Registrar un nuevo vehiculo validando placa unica, año y
--             capacidad de pasajeros.
-- Operacion : INSERT
-- Validaciones: placa unica, anio entre 1990-2030, capacidad >= 1
-- Control   : ROLLBACK si falla validacion / COMMIT al finalizar OK
-- ============================================================================
CREATE OR REPLACE PROCEDURE sp_registrar_vehiculo(
    p_placa              VARCHAR,
    p_marca              VARCHAR,
    p_modelo             VARCHAR,
    p_anio               INTEGER,
    p_capacidad          INTEGER,
    p_numero_motor       VARCHAR,
    p_numero_chasis      VARCHAR,
    p_color              VARCHAR
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Validacion 1: placa obligatoria y unica
    IF p_placa IS NULL OR length(trim(p_placa)) = 0 THEN
        ROLLBACK;
        RAISE EXCEPTION 'PLACA_INVALIDA: La placa es obligatoria';
    END IF;

    IF EXISTS (SELECT 1 FROM vehiculos WHERE placa = p_placa) THEN
        ROLLBACK;
        RAISE EXCEPTION 'PLACA_DUPLICADA: Ya existe un vehiculo con la placa %', p_placa;
    END IF;

    -- Validacion 2: anio valido
    IF p_anio < 1990 OR p_anio > 2030 THEN
        ROLLBACK;
        RAISE EXCEPTION 'ANIO_INVALIDO: El anio debe estar entre 1990 y 2030';
    END IF;

    -- Validacion 3: capacidad minima
    IF p_capacidad < 1 THEN
        ROLLBACK;
        RAISE EXCEPTION 'CAPACIDAD_INVALIDA: La capacidad debe ser al menos 1';
    END IF;

    INSERT INTO vehiculos
        (placa, marca, modelo, anio, capacidad_pasajeros,
         numero_motor, numero_chasis, color, estado, activo)
    VALUES
        (p_placa, p_marca, p_modelo, p_anio, p_capacidad,
         p_numero_motor, p_numero_chasis, p_color, 'ACTIVO', TRUE);

    COMMIT;  -- Operacion correcta -> COMMIT
    RAISE NOTICE 'PROCEDIMIENTO OK: Vehiculo % % registrado correctamente.', p_placa, p_modelo;
END;
$$;

-- ============================================================================
-- PROCEDIMIENTO 3: sp_asignar_ruta
-- Objetivo  : Asignar una ruta a un conductor y un vehiculo (control de
--             disponibilidad / inventario de flota). Valida que el conductor
--             este ACTIVO, el vehiculo este ACTIVO y que el conductor no tenga
--             ya una asignacion ACTIVA en el mismo periodo (concurrencia).
-- Operacion : INSERT en asignacion_rutas (valida en varias tablas)
-- Control   : ROLLBACK si falla validacion / COMMIT al finalizar OK
-- ============================================================================
CREATE OR REPLACE PROCEDURE sp_asignar_ruta(
    p_conductor_id     BIGINT,
    p_vehiculo_id      BIGINT,
    p_ruta_id          BIGINT,
    p_fecha_asignacion DATE,
    p_fecha_inicio     DATE
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_estado_conductor VARCHAR;
    v_estado_vehiculo  VARCHAR;
BEGIN
    -- Validacion 1: existe conductor y esta ACTIVO
    SELECT estado INTO v_estado_conductor
    FROM conductores WHERE id = p_conductor_id;

    IF NOT FOUND THEN
        ROLLBACK;
        RAISE EXCEPTION 'CONDUCTOR_NO_EXISTE: No existe conductor con id %', p_conductor_id;
    END IF;

    IF v_estado_conductor <> 'ACTIVO' THEN
        ROLLBACK;
        RAISE EXCEPTION 'CONDUCTOR_INACTIVO: El conductor no esta ACTIVO (estado: %)', v_estado_conductor;
    END IF;

    -- Validacion 2: existe vehiculo y esta ACTIVO
    SELECT estado INTO v_estado_vehiculo
    FROM vehiculos WHERE id = p_vehiculo_id;

    IF NOT FOUND THEN
        ROLLBACK;
        RAISE EXCEPTION 'VEHICULO_NO_EXISTE: No existe vehiculo con id %', p_vehiculo_id;
    END IF;

    IF v_estado_vehiculo <> 'ACTIVO' THEN
        ROLLBACK;
        RAISE EXCEPTION 'VEHICULO_NO_DISPONIBLE: El vehiculo no esta ACTIVO (estado: %)', v_estado_vehiculo;
    END IF;

    -- Validacion 3: concurrencia - el conductor no debe tener asignacion ACTIVA
    --               en el mismo periodo
    IF EXISTS (
        SELECT 1 FROM asignacion_rutas
        WHERE conductor_id = p_conductor_id
          AND estado = 'ACTIVA'
          AND activo = TRUE
          AND (fecha_fin IS NULL OR fecha_fin >= p_fecha_inicio)
    ) THEN
        ROLLBACK;
        RAISE EXCEPTION 'CONFLICTO_ASIGNACION: El conductor % ya tiene una asignacion ACTIVA en ese periodo',
            p_conductor_id;
    END IF;

    -- Insertar la asignacion
    INSERT INTO asignacion_rutas
        (conductor_id, vehiculo_id, ruta_id, fecha_asignacion,
         fecha_inicio, fecha_fin, estado, activo)
    VALUES
        (p_conductor_id, p_vehiculo_id, p_ruta_id, p_fecha_asignacion,
         p_fecha_inicio, NULL, 'ACTIVA', TRUE);

    COMMIT;  -- Operacion correcta -> COMMIT
    RAISE NOTICE 'PROCEDIMIENTO OK: Ruta asignada al conductor % (vehiculo %, ruta %)',
        p_conductor_id, p_vehiculo_id, p_ruta_id;
END;
$$;

-- ============================================================================
-- PROCEDIMIENTO 4: sp_reportar_incidente
-- Objetivo  : Reportar un incidente ligado a una asignacion. Ademas, si la
--             gravedad es ALTA o CRITICA, actualiza (multi-tabla) el vehiculo
--             asociado a la asignacion a EN_MANTENIMIENTO (regla de negocio).
-- Operacion : INSERT (incidentes) + UPDATE (vehiculos) -> transaccion multi-tabla
-- Control   : ROLLBACK si falla validacion / COMMIT al finalizar OK
-- ============================================================================
CREATE OR REPLACE PROCEDURE sp_reportar_incidente(
    p_asignacion_id  BIGINT,
    p_reportado_por  VARCHAR,
    p_tipo           VARCHAR,
    p_descripcion    TEXT,
    p_fecha          TIMESTAMPTZ,
    p_ubicacion      VARCHAR,
    p_gravedad       VARCHAR
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_vehiculo_id    BIGINT;
BEGIN
    -- Validacion 1: la asignacion debe existir
    IF NOT EXISTS (SELECT 1 FROM asignacion_rutas WHERE id = p_asignacion_id) THEN
        ROLLBACK;
        RAISE EXCEPTION 'ASIGNACION_NO_EXISTE: No existe asignacion con id %', p_asignacion_id;
    END IF;

    -- Validacion 2: gravedad valida (BAJA, MEDIA, ALTA, CRITICA)
    IF p_gravedad NOT IN ('BAJA','MEDIA','ALTA','CRITICA') THEN
        ROLLBACK;
        RAISE EXCEPTION 'GRAVEDAD_INVALIDA: Gravedad % no permitida', p_gravedad;
    END IF;

    -- Obtener el vehiculo de la asignacion (para poder ponerlo en mantenimiento)
    SELECT vehiculo_id INTO v_vehiculo_id
    FROM asignacion_rutas WHERE id = p_asignacion_id;

    -- Insert del incidente
    INSERT INTO incidentes
        (asignacion_id, reportado_por, tipo, descripcion,
         fecha_incidente, ubicacion, gravedad, estado, activo)
    VALUES
        (p_asignacion_id, p_reportado_por, p_tipo, p_descripcion,
         p_fecha, p_ubicacion, p_gravedad, 'REPORTADO', TRUE);

    -- Regla de negocio: gravedad ALTA/CRITICA -> vehiculo a mantenimiento
    IF p_gravedad IN ('ALTA','CRITICA') THEN
        UPDATE vehiculos SET estado = 'EN_MANTENIMIENTO' WHERE id = v_vehiculo_id;
        RAISE NOTICE 'Se movio el vehiculo % a EN_MANTENIMIENTO por gravedad %.',
            v_vehiculo_id, p_gravedad;
    END IF;

    COMMIT;  -- Operacion multi-tabla correcta -> COMMIT
    RAISE NOTICE 'PROCEDIMIENTO OK: Incidente % reportado (gravedad %)', p_tipo, p_gravedad;
END;
$$;

-- ============================================================================
-- PROCEDIMIENTO 5: sp_actualizar_estado_conductor
-- Objetivo  : Cambiar el estado de un conductor (ACTIVO/INACTIVO/SUSPENDIDO).
--             Valida que el conductor exista y que el estado sea permitido.
--             No permite SUSPENDIDO si el conductor tiene asignaciones ACTIVAS.
-- Operacion : UPDATE
-- Control   : ROLLBACK si falla validacion / COMMIT al finalizar OK
-- ============================================================================
CREATE OR REPLACE PROCEDURE sp_actualizar_estado_conductor(
    p_conductor_id BIGINT,
    p_nuevo_estado VARCHAR
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_estado_actual VARCHAR;
BEGIN
    -- Validacion 1: existe conductor
    SELECT estado INTO v_estado_actual
    FROM conductores WHERE id = p_conductor_id;

    IF NOT FOUND THEN
        ROLLBACK;
        RAISE EXCEPTION 'CONDUCTOR_NO_EXISTE: No existe conductor con id %', p_conductor_id;
    END IF;

    -- Validacion 2: estado permitido
    IF p_nuevo_estado NOT IN ('ACTIVO','INACTIVO','SUSPENDIDO') THEN
        ROLLBACK;
        RAISE EXCEPTION 'ESTADO_INVALIDO: Estado % no permitido para conductor', p_nuevo_estado;
    END IF;

    -- Validacion 3: no suspender con asignaciones ACTIVAS
    IF p_nuevo_estado = 'SUSPENDIDO' AND EXISTS (
        SELECT 1 FROM asignacion_rutas
        WHERE conductor_id = p_conductor_id AND estado = 'ACTIVA' AND activo = TRUE
    ) THEN
        ROLLBACK;
        RAISE EXCEPTION 'CONDUCTOR_CON_ASIGNACIONES: No se puede SUSPENDER un conductor con asignaciones ACTIVAS';
    END IF;

    -- Update del estado
    UPDATE conductores SET estado = p_nuevo_estado WHERE id = p_conductor_id;

    COMMIT;  -- Update correcto -> COMMIT
    RAISE NOTICE 'PROCEDIMIENTO OK: Conductor % cambio de estado % -> %',
        p_conductor_id, v_estado_actual, p_nuevo_estado;
END;
$$;

-- ============================================================================
-- PROCEDIMIENTO 6: sp_cambiar_estado_vehiculo
-- Objetivo  : Cambiar el estado de un vehiculo (ACTIVO/EN_MANTENIMIENTO/
--             FUERA_DE_SERVICIO). No permite sacar de circulacion (mant./fuera)
--             un vehiculo que este en una asignacion ACTIVA (control flota).
-- Operacion : UPDATE (control de inventario de flota)
-- Control   : ROLLBACK si falla validacion / COMMIT al finalizar OK
-- ============================================================================
CREATE OR REPLACE PROCEDURE sp_cambiar_estado_vehiculo(
    p_vehiculo_id BIGINT,
    p_nuevo_estado VARCHAR
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_estado_actual VARCHAR;
BEGIN
    -- Validacion 1: existe vehiculo
    SELECT estado INTO v_estado_actual
    FROM vehiculos WHERE id = p_vehiculo_id;

    IF NOT FOUND THEN
        ROLLBACK;
        RAISE EXCEPTION 'VEHICULO_NO_EXISTE: No existe vehiculo con id %', p_vehiculo_id;
    END IF;

    -- Validacion 2: estado permitido
    IF p_nuevo_estado NOT IN ('ACTIVO','EN_MANTENIMIENTO','FUERA_DE_SERVICIO') THEN
        ROLLBACK;
        RAISE EXCEPTION 'ESTADO_INVALIDO: Estado % no permitido para vehiculo', p_nuevo_estado;
    END IF;

    -- Validacion 3: no sacar de servicio un vehiculo con asignacion ACTIVA
    IF p_nuevo_estado IN ('EN_MANTENIMIENTO','FUERA_DE_SERVICIO') AND EXISTS (
        SELECT 1 FROM asignacion_rutas
        WHERE vehiculo_id = p_vehiculo_id AND estado = 'ACTIVA' AND activo = TRUE
    ) THEN
        ROLLBACK;
        RAISE EXCEPTION 'VEHICULO_EN_USO: No se puede retirar un vehiculo con asignaciones ACTIVAS';
    END IF;

    -- Update del estado
    UPDATE vehiculos SET estado = p_nuevo_estado WHERE id = p_vehiculo_id;

    COMMIT;  -- Update correcto -> COMMIT
    RAISE NOTICE 'PROCEDIMIENTO OK: Vehiculo % cambio de estado % -> %',
        p_vehiculo_id, v_estado_actual, p_nuevo_estado;
END;
$$;

-- ============================================================================
-- PROCEDIMIENTO 7: sp_cambiar_estado_incidente
-- Objetivo  : Avanzar el estado de un incidente respetando el flujo:
--             REPORTADO -> EN_INVESTIGACION -> RESUELTO -> CERRADO.
--             La transicion debe ser valida (estado consecutivo del flujo).
-- Operacion : UPDATE
-- Control   : ROLLBACK si la transicion es invalida / COMMIT si es valida
-- ============================================================================
CREATE OR REPLACE PROCEDURE sp_cambiar_estado_incidente(
    p_incidente_id BIGINT,
    p_nuevo_estado VARCHAR
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_estado_actual VARCHAR;
    v_orden_actual  INTEGER;
    v_orden_nuevo   INTEGER;
BEGIN
    -- Validacion 1: existe incidente
    SELECT estado INTO v_estado_actual
    FROM incidentes WHERE id = p_incidente_id;

    IF NOT FOUND THEN
        ROLLBACK;
        RAISE EXCEPTION 'INCIDENTE_NO_EXISTE: No existe incidente con id %', p_incidente_id;
    END IF;

    -- Validacion 2: estado nuevo permitido
    IF p_nuevo_estado NOT IN ('REPORTADO','EN_INVESTIGACION','RESUELTO','CERRADO') THEN
        ROLLBACK;
        RAISE EXCEPTION 'ESTADO_INVALIDO: Estado % no permitido para incidente', p_nuevo_estado;
    END IF;

    -- Orden del flujo
    v_orden_actual := CASE v_estado_actual
                        WHEN 'REPORTADO'          THEN 1
                        WHEN 'EN_INVESTIGACION'   THEN 2
                        WHEN 'RESUELTO'           THEN 3
                        WHEN 'CERRADO'            THEN 4
                      END;
    v_orden_nuevo := CASE p_nuevo_estado
                        WHEN 'REPORTADO'          THEN 1
                        WHEN 'EN_INVESTIGACION'   THEN 2
                        WHEN 'RESUELTO'           THEN 3
                        WHEN 'CERRADO'            THEN 4
                      END;

    -- Validacion 3: no se puede retroceder ni saltar pasos del flujo
    IF v_orden_nuevo <> v_orden_actual + 1 THEN
        ROLLBACK;
        RAISE EXCEPTION 'TRANSICION_INVALIDA: No se puede pasar de % a %',
            v_estado_actual, p_nuevo_estado;
    END IF;

    -- Update del estado
    UPDATE incidentes SET estado = p_nuevo_estado WHERE id = p_incidente_id;

    COMMIT;  -- Transicion correcta -> COMMIT
    RAISE NOTICE 'PROCEDIMIENTO OK: Incidente % cambio de estado % -> %',
        p_incidente_id, v_estado_actual, p_nuevo_estado;
END;
$$;

-- ============================================================================
-- PROCEDIMIENTO 8: sp_completar_asignacion
-- Objetivo  : Cerrar una asignacion ACTIVA poniendole fecha_fin y estado
--             COMPLETADA. Valida que la asignacion exista, este ACTIVA y que
--             la fecha_fin sea >= fecha_inicio.
-- Operacion : UPDATE (transaccion)
-- Control   : ROLLBACK si falla validacion / COMMIT al finalizar OK
-- ============================================================================
CREATE OR REPLACE PROCEDURE sp_completar_asignacion(
    p_asignacion_id BIGINT,
    p_fecha_fin     DATE
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_estado       VARCHAR;
    v_fecha_inicio DATE;
BEGIN
    -- Validacion 1: existe asignacion
    SELECT estado, fecha_inicio INTO v_estado, v_fecha_inicio
    FROM asignacion_rutas WHERE id = p_asignacion_id;

    IF NOT FOUND THEN
        ROLLBACK;
        RAISE EXCEPTION 'ASIGNACION_NO_EXISTE: No existe asignacion con id %', p_asignacion_id;
    END IF;

    -- Validacion 2: debe estar ACTIVA
    IF v_estado <> 'ACTIVA' THEN
        ROLLBACK;
        RAISE EXCEPTION 'ASIGNACION_NO_ACTIVA: La asignacion % no esta ACTIVA (estado: %)',
            p_asignacion_id, v_estado;
    END IF;

    -- Validacion 3: fecha_fin >= fecha_inicio
    IF p_fecha_fin < v_fecha_inicio THEN
        ROLLBACK;
        RAISE EXCEPTION 'FECHA_INVALIDA: fecha_fin (%) anterior a fecha_inicio (%)',
            p_fecha_fin, v_fecha_inicio;
    END IF;

    -- Update de la asignacion
    UPDATE asignacion_rutas
       SET estado = 'COMPLETADA', fecha_fin = p_fecha_fin
     WHERE id = p_asignacion_id;

    COMMIT;  -- Update correcto -> COMMIT
    RAISE NOTICE 'PROCEDIMIENTO OK: Asignacion % completada (fecha_fin %)',
        p_asignacion_id, p_fecha_fin;
END;
$$;

-- ============================================================================
-- PROCEDIMIENTO 9: sp_eliminar_conductor_logico
-- Objetivo  : Dar de baja (eliminacion logica, activo=FALSE) a un conductor.
--             Valida que exista, este ACTIVO y que no tenga asignaciones
--             ACTIVAS ni incidentes pendientes (no cerrados).
-- Operacion : UPDATE (eliminacion logica)
-- Control   : ROLLBACK si falla validacion / COMMIT al finalizar OK
-- ============================================================================
CREATE OR REPLACE PROCEDURE sp_eliminar_conductor_logico(
    p_conductor_id BIGINT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_activo BOOLEAN;
    v_con_asig_pendiente       BOOLEAN;
    v_con_incidente_pendiente  BOOLEAN;
BEGIN
    -- Validacion 1: existe conductor
    SELECT activo INTO v_activo FROM conductores WHERE id = p_conductor_id;

    IF NOT FOUND THEN
        ROLLBACK;
        RAISE EXCEPTION 'CONDUCTOR_NO_EXISTE: No existe conductor con id %', p_conductor_id;
    END IF;

    -- Validacion 2: no debe estar ya inactivo
    IF NOT v_activo THEN
        ROLLBACK;
        RAISE EXCEPTION 'CONDUCTOR_YA_INACTIVO: El conductor % ya esta dado de baja', p_conductor_id;
    END IF;

    -- Validacion 3: sin asignaciones ACTIVAS
    SELECT EXISTS (
        SELECT 1 FROM asignacion_rutas
        WHERE conductor_id = p_conductor_id AND estado = 'ACTIVA' AND activo = TRUE
    ) INTO v_con_asig_pendiente;

    IF v_con_asig_pendiente THEN
        ROLLBACK;
        RAISE EXCEPTION 'CONDUCTOR_CON_ASIGNACIONES: No se puede dar de baja con asignaciones ACTIVAS';
    END IF;

    -- Validacion 4: sin incidentes pendientes
    SELECT EXISTS (
        SELECT 1
        FROM incidentes i JOIN asignacion_rutas ar ON i.asignacion_id = ar.id
        WHERE ar.conductor_id = p_conductor_id
          AND i.estado IN ('REPORTADO','EN_INVESTIGACION')
          AND i.activo = TRUE
    ) INTO v_con_incidente_pendiente;

    IF v_con_incidente_pendiente THEN
        ROLLBACK;
        RAISE EXCEPTION 'CONDUCTOR_CON_INCIDENTES: No se puede dar de baja con incidentes pendientes';
    END IF;

    -- Baja logica del conductor
    UPDATE conductores SET activo = FALSE, estado = 'INACTIVO' WHERE id = p_conductor_id;

    COMMIT;  -- Baja correcta -> COMMIT
    RAISE NOTICE 'PROCEDIMIENTO OK: Conductor % dado de baja (activo=FALSE)', p_conductor_id;
END;
$$;

-- ============================================================================
-- PROCEDIMIENTO 10: sp_contar_conductores_por_estado
-- Objetivo  : Contar conductores activos agrupados por estado (reporte).
--             Valida el parametro de estado (si se pasa debe ser permitido).
--             Muestra los totales mediante NOTICE.
-- Operacion : SELECT (consulta con validacion de parametro)
-- Control   : ROLLBACK si el parametro es invalido / COMMIT si es valido
-- ============================================================================
CREATE OR REPLACE PROCEDURE sp_contar_conductores_por_estado(
    p_estado VARCHAR
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_total_activos      INTEGER;
    v_total_inactivos    INTEGER;
    v_total_suspendidos  INTEGER;
BEGIN
    -- Validacion: si se pasa un estado, debe ser permitido
    IF p_estado IS NOT NULL AND p_estado NOT IN ('ACTIVO','INACTIVO','SUSPENDIDO') THEN
        ROLLBACK;
        RAISE EXCEPTION 'ESTADO_INVALIDO: Estado % no permitido', p_estado;
    END IF;

    -- Consulta (reporte)
    SELECT COUNT(*) FILTER (WHERE estado='ACTIVO'),
           COUNT(*) FILTER (WHERE estado='INACTIVO'),
           COUNT(*) FILTER (WHERE estado='SUSPENDIDO')
      INTO v_total_activos, v_total_inactivos, v_total_suspendidos
    FROM conductores
    WHERE activo = TRUE
      AND (p_estado IS NULL OR estado = p_estado);

    COMMIT;  -- Consulta correcta -> COMMIT
    RAISE NOTICE 'PROCEDIMIENTO OK: Reporte (filtro %): ACTIVOS=%, INACTIVOS=%, SUSPENDIDOS=%',
        COALESCE(p_estado, 'TODOS'), v_total_activos, v_total_inactivos, v_total_suspendidos;
END;
$$;
