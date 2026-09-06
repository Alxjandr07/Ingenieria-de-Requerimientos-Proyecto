-- ============================================================================
-- ACTIVIDAD: Pruebas de los 10 procedimientos - SGROAS
-- ADAPTADO A TU BASE DE DATOS REAL (IDs actualizados).
--
-- Puntos clave de tus datos:
--   • Conductor ACTIVO libre: 2, 3, 6, 7
--   • Conductor SUSPENDIDO: 5                       (para casos incorrectos)
--   • Conductor en uso (asign. activa): 4
--   • Vehiculo ACTIVO libre: 2
--   • Vehiculo en uso: 1 y 3 | EN_MANTENIMIENTO: 4 | FUERA_DE_SERVICIO: 5
--   • Rutas ACTIVAS: 1, 2, 3, 4
--   • Asignaciones ACTIVAS: id 1 (conductor 4, vehiculo 1) y id 2 (conductor 4, vehiculo 3)
--   • incidentes: VACIA  -> el P4 crea los incidentes que usa el P7
-- ============================================================================


-- ============================================================================
-- PROCEDIMIENTO 1: sp_registrar_conductor
-- ============================================================================
SELECT 'ANTES' AS momento, COUNT(*) AS total_conductores FROM conductores;

-- CASO CORRECTO (debe llegar a COMMIT)
CALL sp_registrar_conductor(
    'Prueba', 'Caso1',
    '1755555555',                -- cedula nueva (10 digitos)
    'LIC-TEST-001',              -- numero_licencia nueva
    'E', '2029-01-01',
    '0990000001', 'prueba1@sgroas.com'
);

-- Verificacion DESPUES del caso correcto (debe existir el registro)
SELECT 'DESPUES_OK' AS momento, id, cedula, estado
FROM conductores WHERE cedula = '1755555555';

-- CASO INCORRECTO 1: cedula duplicada (debe disparar ROLLBACK + error)
CALL sp_registrar_conductor(
    'Prueba', 'CasoIncorrecto',
    '1755555555',                -- cedula YA registrada
    'LIC-TEST-999',
    'E', '2029-01-01',
    '0990000002', 'prueba2@sgroas.com'
);

-- CASO INCORRECTO 2: cedula no tiene 10 digitos (debe disparar ROLLBACK + error)
CALL sp_registrar_conductor(
    'Prueba', 'CedoCorta',
    '123',                       -- cedula de 3 digitos -> invalida
    'LIC-TEST-888',
    'E', '2029-01-01',
    '0990000003', 'prueba3@sgroas.com'
);

-- Verificacion DESPUES del caso incorrecto (NO debe existir duplicado)
SELECT 'DESPUES_ERROR' AS momento, id, cedula
FROM conductores WHERE cedula = '1755555555';
-- (debe existir una sola fila con esa cedula: la del caso correcto)


-- ============================================================================
-- PROCEDIMIENTO 2: sp_registrar_vehiculo
-- ============================================================================
SELECT 'ANTES' AS momento, COUNT(*) AS total_vehiculos FROM vehiculos;

-- CASO CORRECTO (debe llegar a COMMIT)
CALL sp_registrar_vehiculo(
    'XYZ-9999', 'Test', 'TestBus', 2025, 30,
    'MOT-TEST-001', 'CHS-TEST-001', 'Negro'
);

SELECT 'DESPUES_OK' AS momento, id, placa, estado
FROM vehiculos WHERE placa = 'XYZ-9999';

-- CASO INCORRECTO 1: placa duplicada (ROLLBACK + error)
CALL sp_registrar_vehiculo(
    'ABC-1234', 'Test', 'Duplicado', 2025, 30,
    'MOT-TEST-002', 'CHS-TEST-002', 'Negro'   -- ABC-1234 ya existe (tu BD)
);

-- CASO INCORRECTO 2: anio fuera de rango (ROLLBACK + error)
CALL sp_registrar_vehiculo(
    'ZZZ-0000', 'Test', 'AnioMal', 1980, 30,
    'MOT-TEST-003', 'CHS-TEST-003', 'Negro'   -- 1980 < 1990 -> invalido
);

SELECT 'DESPUES_ERROR' AS momento, id, placa
FROM vehiculos WHERE placa IN ('ZZZ-0000','ABC-1234');


-- ============================================================================
-- PROCEDIMIENTO 3: sp_asignar_ruta
--   Correcto: conductor 2 (libre) + vehiculo 2 (libre) + ruta 1 (activa)
--   Incorrectos: concurrencia (mismo conductor 2 en mismo periodo) y
--                conductor 5 SUSPENDIDO
-- ============================================================================
-- CASO CORRECTO (COMMIT)
CALL sp_asignar_ruta(2, 2, 1, DATE '2026-09-15', DATE '2026-09-15');
SELECT 'DESPUES_OK' AS momento, id, conductor_id, vehiculo_id, ruta_id, estado
FROM asignacion_rutas WHERE fecha_asignacion = DATE '2026-09-15';

-- CASO INCORRECTO 1 (concurrencia): conductor 2 YA tiene asignacion ACTIVA el 2026-09-15
CALL sp_asignar_ruta(2, 3, 2, DATE '2026-09-15', DATE '2026-09-15');

-- CASO INCORRECTO 2: conductor 5 esta SUSPENDIDO
CALL sp_asignar_ruta(5, 2, 1, DATE '2026-09-16', DATE '2026-09-16');

-- CASO INCORRECTO 3: conductor inexistente
CALL sp_asignar_ruta(99999, 2, 1, DATE '2026-09-17', DATE '2026-09-17');


-- ============================================================================
-- PROCEDIMIENTO 4: sp_reportar_incidente
--   Usa la asignacion ACTIVA id 1 (conductor 4, vehiculo 1).
--   Esto CREA los incidentes que luego usa el P7.
-- ============================================================================
-- CASO CORRECTO 1: gravedad BAJA (solo INSERT)
CALL sp_reportar_incidente(
    1, 'Coordinador', 'QUEJA', 'Queja de prueba nivel bajo',
    NOW(), 'Terminal Norte', 'BAJA'
);

-- CASO CORRECTO 2: gravedad ALTA (INSERT + vehiculo 1 a EN_MANTENIMIENTO)
CALL sp_reportar_incidente(
    1, 'Coordinador', 'AVERIA_MECANICA', 'Falla grave que deja el vehiculo en taller',
    NOW(), 'Km 5', 'ALTA'
);

-- Verificar vehiculo 1 (debe quedar EN_MANTENIMIENTO por el caso ALTA)
SELECT 'VEHICULO1_ESTADO' AS momento, id, estado FROM vehiculos WHERE id = 1;

-- CASO INCORRECTO 1: gravedad invalida (ROLLBACK + error)
CALL sp_reportar_incidente(
    1, 'Coordinador', 'OTRO', 'Gravedad no permitida',
    NOW(), 'Terminal', 'EXTREMA'
);

-- CASO INCORRECTO 2: asignacion inexistente (ROLLBACK + error)
CALL sp_reportar_incidente(
    99999, 'Coordinador', 'OTRO', 'Asignacion inexistente',
    NOW(), 'Terminal', 'MEDIA'
);

-- Ver los incidentes creados (para conocer su id y usarlos en P7)
SELECT 'INCIDENTES_CREADOS' AS momento, id, tipo, gravedad, estado
FROM incidentes WHERE tipo IN ('QUEJA','AVERIA_MECANICA');


-- ============================================================================
-- PROCEDIMIENTO 5: sp_actualizar_estado_conductor
--   Correcto: conductor 6 a INACTIVO (sin asignaciones activas)
--   Incorrectos: estado invalido, conductor inexistente,
--                SUSPENDIDO con conductor 4 (tiene asignaciones activas)
-- ============================================================================
-- CASO CORRECTO (COMMIT)
CALL sp_actualizar_estado_conductor(6, 'INACTIVO');
SELECT 'DESPUES_OK' AS momento, id, estado FROM conductores WHERE id = 6;

-- CASO INCORRECTO 1: estado invalido (ROLLBACK + error)
CALL sp_actualizar_estado_conductor(6, 'VACACIONES');

-- CASO INCORRECTO 2: conductor inexistente (ROLLBACK + error)
CALL sp_actualizar_estado_conductor(99999, 'ACTIVO');

-- CASO INCORRECTO 3: SUSPENDIDO -> conductor 4 tiene asignaciones ACTIVAS
CALL sp_actualizar_estado_conductor(4, 'SUSPENDIDO');
SELECT 'POST_ERROR' AS momento, id, estado FROM conductores WHERE id = 4;


-- ============================================================================
-- PROCEDIMIENTO 6: sp_cambiar_estado_vehiculo
--   Correcto: vehiculo 5 (FUERA_DE_SERVICIO) -> ACTIVO
--   Incorrectos: estado invalido, y vehiculo 1 EN_USO (asignacion activa)
-- ============================================================================
-- CASO CORRECTO (COMMIT): vehiculo 5 pasa de FUERA_DE_SERVICIO a ACTIVO
CALL sp_cambiar_estado_vehiculo(5, 'ACTIVO');
SELECT 'DESPUES_OK' AS momento, id, estado FROM vehiculos WHERE id = 5;

-- CASO INCORRECTO 1: estado invalido (ROLLBACK + error)
CALL sp_cambiar_estado_vehiculo(5, 'REPARADO');

-- CASO INCORRECTO 2: vehiculo 1 en uso (asignacion ACTIVA) -> FUERA
CALL sp_cambiar_estado_vehiculo(1, 'FUERA_DE_SERVICIO');
SELECT 'POST_ERROR' AS momento, id, estado FROM vehiculos WHERE id = 1;


-- ============================================================================
-- PROCEDIMIENTO 7: sp_cambiar_estado_incidente
--   Usa el incidente creado por el P4 (tipo QUEJA, quedara REPORTADO).
--   El id suele ser 1 si la tabla estaba vacia; si tienes otro id,
--   ajusta el numero. Compruebalo con el SELECT anterior (INCIDENTES_CREADOS).
-- ============================================================================
-- CASO CORRECTO (COMMIT): REPORTADO -> EN_INVESTIGACION
CALL sp_cambiar_estado_incidente(1, 'EN_INVESTIGACION');
SELECT 'DESPUES_OK' AS momento, id, estado FROM incidentes WHERE id = 1;

-- CASO INCORRECTO 1: saltar de EN_INVESTIGACION a CERRADO (salto, ROLLBACK)
CALL sp_cambiar_estado_incidente(1, 'CERRADO');

-- CASO INCORRECTO 2: incidente inexistente (ROLLBACK + error)
CALL sp_cambiar_estado_incidente(99999, 'RESUELTO');
SELECT 'POST_ERROR' AS momento, id, estado FROM incidentes WHERE id = 1;


-- ============================================================================
-- PROCEDIMIENTO 8: sp_completar_asignacion
--   Incorrecto primero: fecha anterior al inicio (asignacion 1 sigue ACTIVA)
--   Correcto: completar la asignacion ACTIVA id 2 con fecha valida.
--   Incorrecto: asignacion ya no activa (la 2, despues de completarla).
-- ============================================================================
-- CASO INCORRECTO 1 (ROLLBACK + error): fecha anterior a fecha_inicio
--   (la asignacion 1 sigue ACTIVA con fecha_inicio 2026-08-01)
CALL sp_completar_asignacion(1, DATE '2020-01-01');
SELECT 'POST_ERROR_FECHA' AS momento, id, estado FROM asignacion_rutas WHERE id = 1;

-- CASO CORRECTO (COMMIT): completar la asignacion ACTIVA id 2
CALL sp_completar_asignacion(2, DATE '2026-09-30');
SELECT 'DESPUES_OK' AS momento, id, estado, fecha_fin
FROM asignacion_rutas WHERE id = 2;

-- CASO INCORRECTO 2 (ROLLBACK + error): asignacion 2 ya quedo COMPLETADA
CALL sp_completar_asignacion(2, DATE '2026-10-01');
SELECT 'POST_ERROR' AS momento, id, estado FROM asignacion_rutas WHERE id = 2;


-- ============================================================================
-- PROCEDIMIENTO 9: sp_eliminar_conductor_logico
--   Correcto: conductor 7 (activo, sin asignaciones ni incidentes)
--   Incorrectos: conductor 4 (con asignaciones activas), inexistente, ya inactivo
-- ============================================================================
-- CASO CORRECTO (COMMIT)
CALL sp_eliminar_conductor_logico(7);
SELECT 'DESPUES_OK' AS momento, id, estado, activo FROM conductores WHERE id = 7;

-- CASO INCORRECTO 1: conductor 4 tiene asignaciones activas (ROLLBACK + error)
CALL sp_eliminar_conductor_logico(4);

-- CASO INCORRECTO 2: conductor inexistente (ROLLBACK + error)
CALL sp_eliminar_conductor_logico(99999);

-- CASO INCORRECTO 3: conductor 7 ya esta inactivo (ROllBACK + error)
CALL sp_eliminar_conductor_logico(7);
SELECT 'POST_ERROR' AS momento, id, estado, activo FROM conductores WHERE id IN (4,7);


-- ============================================================================
-- PROCEDIMIENTO 10: sp_contar_conductores_por_estado
-- ============================================================================
-- CASO CORRECTO sin filtro
CALL sp_contar_conductores_por_estado(NULL);

-- CASO CORRECTO con filtro valido
CALL sp_contar_conductores_por_estado('ACTIVO');

-- CASO INCORRECTO: filtro invalido (ROLLBACK + error)
CALL sp_contar_conductores_por_estado('JUBILADO');
