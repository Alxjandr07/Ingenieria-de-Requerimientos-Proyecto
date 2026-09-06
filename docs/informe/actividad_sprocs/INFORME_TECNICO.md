# INFORME TÉCNICO
## Procedimientos Almacenados en PostgreSQL - SGROAS

---

## 1. Portada

- **Institución:** [Nombre de la institución]
- **Carrera / Materia:** Administración de Bases de Datos
- **Curso:** [Curso / Paralelo]
- **Estudiante:** [Nombre del estudiante]
- **Docente:** [Nombre del docente]
- **Fecha:** [Fecha de entrega]
- **Proyecto:** SGROAS (Sistema de Gestión de Rutas y Operaciones de Autobuses)

---

## 2. Introducción

> *(Redactar 1–2 párrafos)*
> Esta práctica tiene como objetivo demostrar el uso de procedimientos almacenados en PostgreSQL aplicados a la base de datos del proyecto SGROAS. Se implementan 10 procedimientos que resuelven operaciones de negocio reales (registro de conductores y vehículos, asignación de rutas, reporte de incidentes, control de flota, entre otros), gestionando la transacción internamente mediante COMMIT y ROLLBACK, incorporando validaciones con estructuras IF y manejo de errores. El propósito es comprender que una operación de negocio puede involucrar varias instrucciones SQL que deben ejecutarse de forma segura, garantizando la consistencia de los datos.

---

## 3. Desarrollo de los 10 Procedimientos

> *(Por cada procedimiento completar los siguientes campos. Al final de cada uno se indica la evidencia a capturar en pgAdmin.)*

---

### Procedimiento 1: `sp_registrar_conductor`

- **Objetivo:** Registrar un nuevo conductor validando que la cédula tenga 10 dígitos, el correo sea válido y que no existan cédulas ni licencias duplicadas.
- **Funcionamiento:** El procedimiento verifica secuencialmente cada validación con `IF`; si alguna falla ejecuta `ROLLBACK` y lanza un error con `RAISE EXCEPTION`. Si todas las validaciones pasan, inserta el conductor y ejecuta `COMMIT`.
- **Código:**

```sql
CREATE OR REPLACE PROCEDURE sp_registrar_conductor(
    p_nombres          VARCHAR, p_apellidos        VARCHAR,
    p_cedula           VARCHAR, p_numero_licencia  VARCHAR,
    p_tipo_licencia    VARCHAR, p_fecha_vto_lic    DATE,
    p_telefono         VARCHAR, p_email            VARCHAR
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF char_length(p_cedula) <> 10 THEN
        ROLLBACK;
        RAISE EXCEPTION 'CEDULA_INVALIDA: La cedula debe tener 10 digitos';
    END IF;
    IF p_email IS NOT NULL AND POSITION('@' IN p_email) = 0 THEN
        ROLLBACK;
        RAISE EXCEPTION 'EMAIL_INVALIDO: El correo debe contener @';
    END IF;
    IF EXISTS (SELECT 1 FROM conductores WHERE cedula = p_cedula) THEN
        ROLLBACK;
        RAISE EXCEPTION 'CEDULA_DUPLICADA: Ya existe un conductor con la cedula %', p_cedula;
    END IF;
    IF EXISTS (SELECT 1 FROM conductores WHERE numero_licencia = p_numero_licencia) THEN
        ROLLBACK;
        RAISE EXCEPTION 'LICENCIA_DUPLICADA: Ya existe un conductor con la licencia %', p_numero_licencia;
    END IF;
    INSERT INTO conductores (nombres, apellidos, cedula, numero_licencia, tipo_licencia,
                             fecha_vencimiento_licencia, telefono, email, estado, activo)
    VALUES (p_nombres, p_apellidos, p_cedula, p_numero_licencia, p_tipo_licencia,
            p_fecha_vto_lic, p_telefono, p_email, 'ACTIVO', TRUE);
    COMMIT;
    RAISE NOTICE 'PROCEDIMIENTO OK: Conductor % % registrado.', p_nombres, p_apellidos;
END;
$$;
```

- **Evidencia de ejecución (caso correcto → COMMIT):**
  - Captura de la creación del procedimiento.
  - Captura de `CALL sp_registrar_conductor(...)` con datos válidos (mensaje de éxito).
  - Captura del SELECT de verificación mostrando el registro creado.

- **Explicación del caso correcto:** Se ejecuta con una cédula nueva de 10 dígitos y un correo válido; todas las validaciones pasan, se inserta el conductor y se confirma con `COMMIT`.
- **Evidencia de ejecución (caso incorrecto → ROLLBACK):**
  - Captura de `CALL sp_registrar_conductor(...)` con cédula duplicada (muestra error).
  - Captura de `CALL sp_registrar_conductor(...)` con cédula corta (muestra error).
  - Captura del SELECT de verificación mostrando que NO se creó el duplicado.

- **Explicación del caso incorrecto:** Se intenta registrar un conductor con una cédula ya existente; la validación `IF EXISTS` detecta el duplicado, ejecuta `ROLLBACK` (no se inserta nada) y lanza el error.

---

### Procedimiento 2: `sp_registrar_vehiculo`

- **Objetivo:** Registrar un nuevo vehículo validando que la placa sea única y obligatoria, el año entre 1990–2030 y la capacidad mínima de 1 pasajero.
- **Funcionamiento:** Valida placa (única y no vacía), año y capacidad con `IF`; si falla hace `ROLLBACK`, si pasa inserta y hace `COMMIT`.
- **Código:**

```sql
CREATE OR REPLACE PROCEDURE sp_registrar_vehiculo(
    p_placa VARCHAR, p_marca VARCHAR, p_modelo VARCHAR,
    p_anio INTEGER, p_capacidad INTEGER,
    p_numero_motor VARCHAR, p_numero_chasis VARCHAR, p_color VARCHAR
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_placa IS NULL OR length(trim(p_placa)) = 0 THEN
        ROLLBACK;
        RAISE EXCEPTION 'PLACA_INVALIDA: La placa es obligatoria';
    END IF;
    IF EXISTS (SELECT 1 FROM vehiculos WHERE placa = p_placa) THEN
        ROLLBACK;
        RAISE EXCEPTION 'PLACA_DUPLICADA: Ya existe un vehiculo con la placa %', p_placa;
    END IF;
    IF p_anio < 1990 OR p_anio > 2030 THEN
        ROLLBACK;
        RAISE EXCEPTION 'ANIO_INVALIDO: El anio debe estar entre 1990 y 2030';
    END IF;
    IF p_capacidad < 1 THEN
        ROLLBACK;
        RAISE EXCEPTION 'CAPACIDAD_INVALIDA: La capacidad debe ser al menos 1';
    END IF;
    INSERT INTO vehiculos (placa, marca, modelo, anio, capacidad_pasajeros,
                           numero_motor, numero_chasis, color, estado, activo)
    VALUES (p_placa, p_marca, p_modelo, p_anio, p_capacidad,
            p_numero_motor, p_numero_chasis, p_color, 'ACTIVO', TRUE);
    COMMIT;
    RAISE NOTICE 'PROCEDIMIENTO OK: Vehiculo % % registrado.', p_placa, p_modelo;
END;
$$;
```

- **Caso correcto:** placa nueva (ej. `XYZ-9999`), año 2025, capacidad 30 → COMMIT. Evidencia: captura de CALL y SELECT de verificación.
- **Caso incorrecto:** placa duplicada (`ABC-1234`) y año fuera de rango (`1980`) → ROLLBACK. Evidencia: captura del error y SELECT mostrando que no se registró.

---

### Procedimiento 3: `sp_asignar_ruta`

- **Objetivo:** Asignar una ruta a un conductor y un vehículo (control de disponibilidad/inventario de flota), validando que el conductor y el vehículo estén ACTIVOS y que el conductor no tenga otra asignación ACTIVA en el mismo período (control de concurrencia).
- **Funcionamiento:** Valida existencia y estado del conductor y del vehículo; valida concurrencia de asignaciones; si todo pasa inserta en `asignacion_rutas` y hace `COMMIT`.
- **Código:**

```sql
CREATE OR REPLACE PROCEDURE sp_asignar_ruta(
    p_conductor_id BIGINT, p_vehiculo_id BIGINT, p_ruta_id BIGINT,
    p_fecha_asignacion DATE, p_fecha_inicio DATE
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_estado_conductor VARCHAR;
    v_estado_vehiculo  VARCHAR;
BEGIN
    SELECT estado INTO v_estado_conductor FROM conductores WHERE id = p_conductor_id;
    IF NOT FOUND THEN
        ROLLBACK; RAISE EXCEPTION 'CONDUCTOR_NO_EXISTE: no existe conductor %', p_conductor_id;
    END IF;
    IF v_estado_conductor <> 'ACTIVO' THEN
        ROLLBACK; RAISE EXCEPTION 'CONDUCTOR_INACTIVO: estado %', v_estado_conductor;
    END IF;

    SELECT estado INTO v_estado_vehiculo FROM vehiculos WHERE id = p_vehiculo_id;
    IF NOT FOUND THEN
        ROLLBACK; RAISE EXCEPTION 'VEHICULO_NO_EXISTE: no existe vehiculo %', p_vehiculo_id;
    END IF;
    IF v_estado_vehiculo <> 'ACTIVO' THEN
        ROLLBACK; RAISE EXCEPTION 'VEHICULO_NO_DISPONIBLE: estado %', v_estado_vehiculo;
    END IF;

    IF EXISTS (SELECT 1 FROM asignacion_rutas
               WHERE conductor_id = p_conductor_id AND estado = 'ACTIVA' AND activo = TRUE
                 AND (fecha_fin IS NULL OR fecha_fin >= p_fecha_inicio)) THEN
        ROLLBACK; RAISE EXCEPTION 'CONFLICTO_ASIGNACION: conductor % ya tiene asignacion ACTIVA', p_conductor_id;
    END IF;

    INSERT INTO asignacion_rutas (conductor_id, vehiculo_id, ruta_id, fecha_asignacion,
                                  fecha_inicio, fecha_fin, estado, activo)
    VALUES (p_conductor_id, p_vehiculo_id, p_ruta_id, p_fecha_asignacion,
            p_fecha_inicio, NULL, 'ACTIVA', TRUE);
    COMMIT;
    RAISE NOTICE 'PROCEDIMIENTO OK: ruta asignada a conductor %', p_conductor_id;
END;
$$;
```

- **Caso correcto:** asignar ruta a un conductor y vehículo ACTIVOS sin conflictos → COMMIT.
- **Caso incorrecto:** conductor SUSPENDIDO, o conductor con asignación ACTIVA en el período (concurrencia) → ROLLBACK.
- **Nota de concurrencia:** la validación de concurrencia evita asignar dos rutas al mismo conductor en el mismo período; se puede demostrar llamando dos veces seguidas al procedimiento con el mismo conductor y período.

---

### Procedimiento 4: `sp_reportar_incidente`

- **Objetivo:** Reportar un incidente ligado a una asignación y, si la gravedad es ALTA o CRÍTICA, actualizar el vehículo asociado a `EN_MANTENIMIENTO` (transacción multi-tabla).
- **Funcionamiento:** Valida la existencia de la asignación y la gravedad; inserta el incidente; si la gravedad es alta/crítica actualiza el vehículo; hace `COMMIT`.
- **Código:**

```sql
CREATE OR REPLACE PROCEDURE sp_reportar_incidente(
    p_asignacion_id BIGINT, p_reportado_por VARCHAR, p_tipo VARCHAR,
    p_descripcion TEXT, p_fecha TIMESTAMPTZ, p_ubicacion VARCHAR, p_gravedad VARCHAR
)
LANGUAGE plpgsql
AS $$
DECLARE v_vehiculo_id BIGINT;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM asignacion_rutas WHERE id = p_asignacion_id) THEN
        ROLLBACK; RAISE EXCEPTION 'ASIGNACION_NO_EXISTE: asignacion %', p_asignacion_id;
    END IF;
    IF p_gravedad NOT IN ('BAJA','MEDIA','ALTA','CRITICA') THEN
        ROLLBACK; RAISE EXCEPTION 'GRAVEDAD_INVALIDA: %', p_gravedad;
    END IF;

    SELECT vehiculo_id INTO v_vehiculo_id FROM asignacion_rutas WHERE id = p_asignacion_id;

    INSERT INTO incidentes (asignacion_id, reportado_por, tipo, descripcion,
                            fecha_incidente, ubicacion, gravedad, estado, activo)
    VALUES (p_asignacion_id, p_reportado_por, p_tipo, p_descripcion,
            p_fecha, p_ubicacion, p_gravedad, 'REPORTADO', TRUE);

    IF p_gravedad IN ('ALTA','CRITICA') THEN
        UPDATE vehiculos SET estado = 'EN_MANTENIMIENTO' WHERE id = v_vehiculo_id;
    END IF;
    COMMIT;
    RAISE NOTICE 'PROCEDIMIENTO OK: incidente % reportado', p_tipo;
END;
$$;
```

- **Caso correcto:** reporte con gravedad BAJA (solo INSERT) y otro con gravedad ALTA (INSERT + UPDATE). Verificar en SELECT que el vehículo quedó en mantenimiento → COMMIT.
- **Caso incorrecto:** gravedad no permitida (`EXTREMA`) o asignación inexistente → ROLLBACK (no se inserta y no se cambia el vehículo).

---

### Procedimiento 5: `sp_actualizar_estado_conductor`

- **Objetivo:** Cambiar el estado de un conductor (ACTIVO/INACTIVO/SUSPENDIDO) validando que no se suspenda un conductor con asignaciones activas.
- **Funcionamiento:** Valida existencia, estado permitido y la regla de negocio de suspensiones; actualiza y hace `COMMIT`.
- **Código:**

```sql
CREATE OR REPLACE PROCEDURE sp_actualizar_estado_conductor(p_conductor_id BIGINT, p_nuevo_estado VARCHAR)
LANGUAGE plpgsql
AS $$
DECLARE v_estado_actual VARCHAR;
BEGIN
    SELECT estado INTO v_estado_actual FROM conductores WHERE id = p_conductor_id;
    IF NOT FOUND THEN ROLLBACK; RAISE EXCEPTION 'CONDUCTOR_NO_EXISTE: %', p_conductor_id; END IF;
    IF p_nuevo_estado NOT IN ('ACTIVO','INACTIVO','SUSPENDIDO') THEN
        ROLLBACK; RAISE EXCEPTION 'ESTADO_INVALIDO: %', p_nuevo_estado; END IF;
    IF p_nuevo_estado = 'SUSPENDIDO' AND EXISTS (
        SELECT 1 FROM asignacion_rutas
        WHERE conductor_id = p_conductor_id AND estado='ACTIVA' AND activo=TRUE) THEN
        ROLLBACK; RAISE EXCEPTION 'CONDUCTOR_CON_ASIGNACIONES'; END IF;
    UPDATE conductores SET estado = p_nuevo_estado WHERE id = p_conductor_id;
    COMMIT;
    RAISE NOTICE 'PROCEDIMIENTO OK: conductor % % -> %', p_conductor_id, v_estado_actual, p_nuevo_estado;
END;
$$;
```

- **Caso correcto:** cambiar a INACTIVO un conductor sin asignaciones → COMMIT.
- **Caso incorrecto:** estado inválido, conductor inexistente, o SUSPENDIDO con asignaciones activas → ROLLBACK.

---

### Procedimiento 6: `sp_cambiar_estado_vehiculo`

- **Objetivo:** Cambiar el estado de un vehículo (ACTIVO/EN_MANTENIMIENTO/FUERA_DE_SERVICIO) validando que no se retire un vehículo con asignaciones activas (control de inventario de flota).
- **Funcionamiento:** Valida existencia, estado permitido y la regla de disponibilidad; actualiza y hace `COMMIT`.
- **Código:**

```sql
CREATE OR REPLACE PROCEDURE sp_cambiar_estado_vehiculo(p_vehiculo_id BIGINT, p_nuevo_estado VARCHAR)
LANGUAGE plpgsql
AS $$
DECLARE v_estado_actual VARCHAR;
BEGIN
    SELECT estado INTO v_estado_actual FROM vehiculos WHERE id = p_vehiculo_id;
    IF NOT FOUND THEN ROLLBACK; RAISE EXCEPTION 'VEHICULO_NO_EXISTE: %', p_vehiculo_id; END IF;
    IF p_nuevo_estado NOT IN ('ACTIVO','EN_MANTENIMIENTO','FUERA_DE_SERVICIO') THEN
        ROLLBACK; RAISE EXCEPTION 'ESTADO_INVALIDO: %', p_nuevo_estado; END IF;
    IF p_nuevo_estado IN ('EN_MANTENIMIENTO','FUERA_DE_SERVICIO') AND EXISTS (
        SELECT 1 FROM asignacion_rutas
        WHERE vehiculo_id = p_vehiculo_id AND estado='ACTIVA' AND activo=TRUE) THEN
        ROLLBACK; RAISE EXCEPTION 'VEHICULO_EN_USO'; END IF;
    UPDATE vehiculos SET estado = p_nuevo_estado WHERE id = p_vehiculo_id;
    COMMIT;
    RAISE NOTICE 'PROCEDIMIENTO OK: vehiculo % % -> %', p_vehiculo_id, v_estado_actual, p_nuevo_estado;
END;
$$;
```

- **Caso correcto:** pasar a FUERA_DE_SERVICIO un vehículo sin asignaciones → COMMIT.
- **Caso incorrecto:** estado inválido o vehículo en uso → ROLLBACK.

---

### Procedimiento 7: `sp_cambiar_estado_incidente`

- **Objetivo:** Avanzar el estado de un incidente respetando el flujo REPORTADO → EN_INVESTIGACION → RESUELTO → CERRADO, rechazando retrocesos y saltos.
- **Funcionamiento:** Valida existencia, estado permitido y el orden del flujo (estado nuevo debe ser el consecutivo); actualiza y hace `COMMIT`.
- **Código:**

```sql
CREATE OR REPLACE PROCEDURE sp_cambiar_estado_incidente(p_incidente_id BIGINT, p_nuevo_estado VARCHAR)
LANGUAGE plpgsql
AS $$
DECLARE v_estado_actual VARCHAR; v_orden_actual INTEGER; v_orden_nuevo INTEGER;
BEGIN
    SELECT estado INTO v_estado_actual FROM incidentes WHERE id = p_incidente_id;
    IF NOT FOUND THEN ROLLBACK; RAISE EXCEPTION 'INCIDENTE_NO_EXISTE: %', p_incidente_id; END IF;
    IF p_nuevo_estado NOT IN ('REPORTADO','EN_INVESTIGACION','RESUELTO','CERRADO') THEN
        ROLLBACK; RAISE EXCEPTION 'ESTADO_INVALIDO: %', p_nuevo_estado; END IF;
    v_orden_actual := CASE v_estado_actual WHEN 'REPORTADO' THEN 1 WHEN 'EN_INVESTIGACION' THEN 2
                       WHEN 'RESUELTO' THEN 3 WHEN 'CERRADO' THEN 4 END;
    v_orden_nuevo := CASE p_nuevo_estado WHEN 'REPORTADO' THEN 1 WHEN 'EN_INVESTIGACION' THEN 2
                      WHEN 'RESUELTO' THEN 3 WHEN 'CERRADO' THEN 4 END;
    IF v_orden_nuevo <> v_orden_actual + 1 THEN
        ROLLBACK; RAISE EXCEPTION 'TRANSICION_INVALIDA: % -> %', v_estado_actual, p_nuevo_estado; END IF;
    UPDATE incidentes SET estado = p_nuevo_estado WHERE id = p_incidente_id;
    COMMIT;
    RAISE NOTICE 'PROCEDIMIENTO OK: incidente % % -> %', p_incidente_id, v_estado_actual, p_nuevo_estado;
END;
$$;
```

- **Caso correcto:** REPORTADO → EN_INVESTIGACION → RESUELTO → CERRADO de forma consecutiva → COMMIT.
- **Caso incorrecto:** intentar pasar de REPORTADO a CERRADO (salto) o retroceder → ROLLBACK.

---

### Procedimiento 8: `sp_completar_asignacion`

- **Objetivo:** Cerrar una asignación ACTIVA asignándole fecha_fin y estado COMPLETADA, validando que la fecha_fin sea posterior o igual a la fecha_inicio.
- **Funcionamiento:** Valida existencia, que esté ACTIVA y las fechas; actualiza y hace `COMMIT`.
- **Código:**

```sql
CREATE OR REPLACE PROCEDURE sp_completar_asignacion(p_asignacion_id BIGINT, p_fecha_fin DATE)
LANGUAGE plpgsql
AS $$
DECLARE v_estado VARCHAR; v_fecha_inicio DATE;
BEGIN
    SELECT estado, fecha_inicio INTO v_estado, v_fecha_inicio
    FROM asignacion_rutas WHERE id = p_asignacion_id;
    IF NOT FOUND THEN ROLLBACK; RAISE EXCEPTION 'ASIGNACION_NO_EXISTE: %', p_asignacion_id; END IF;
    IF v_estado <> 'ACTIVA' THEN ROLLBACK; RAISE EXCEPTION 'ASIGNACION_NO_ACTIVA: %', v_estado; END IF;
    IF p_fecha_fin < v_fecha_inicio THEN
        ROLLBACK; RAISE EXCEPTION 'FECHA_INVALIDA: % < %', p_fecha_fin, v_fecha_inicio; END IF;
    UPDATE asignacion_rutas SET estado='COMPLETADA', fecha_fin=p_fecha_fin WHERE id=p_asignacion_id;
    COMMIT;
    RAISE NOTICE 'PROCEDIMIENTO OK: asignacion % completada', p_asignacion_id;
END;
$$;
```

- **Caso correcto:** completar una asignación ACTIVA con una fecha_fin válida → COMMIT.
- **Caso incorrecto:** fecha_fin anterior a fecha_inicio, o asignación ya no ACTIVA → ROLLBACK.

---

### Procedimiento 9: `sp_eliminar_conductor_logico`

- **Objetivo:** Dar de baja (eliminación lógica, activo=FALSE) a un conductor validando que no tenga asignaciones ACTIVAS ni incidentes pendientes.
- **Funcionamiento:** Valida existencia, que esté activo, que no tenga asignaciones activas ni incidentes pendientes; hace la baja lógica y `COMMIT`.
- **Código:**

```sql
CREATE OR REPLACE PROCEDURE sp_eliminar_conductor_logico(p_conductor_id BIGINT)
LANGUAGE plpgsql
AS $$
DECLARE v_activo BOOLEAN; v_asig BOOLEAN; v_incid BOOLEAN;
BEGIN
    SELECT activo INTO v_activo FROM conductores WHERE id = p_conductor_id;
    IF NOT FOUND THEN ROLLBACK; RAISE EXCEPTION 'CONDUCTOR_NO_EXISTE: %', p_conductor_id; END IF;
    IF NOT v_activo THEN ROLLBACK; RAISE EXCEPTION 'CONDUCTOR_YA_INACTIVO: %', p_conductor_id; END IF;
    SELECT EXISTS (SELECT 1 FROM asignacion_rutas
                   WHERE conductor_id=p_conductor_id AND estado='ACTIVA' AND activo=TRUE) INTO v_asig;
    IF v_asig THEN ROLLBACK; RAISE EXCEPTION 'CONDUCTOR_CON_ASIGNACIONES'; END IF;
    SELECT EXISTS (SELECT 1 FROM incidentes i
                   JOIN asignacion_rutas ar ON i.asignacion_id = ar.id
                   WHERE ar.conductor_id=p_conductor_id
                     AND i.estado IN ('REPORTADO','EN_INVESTIGACION') AND i.activo=TRUE) INTO v_incid;
    IF v_incid THEN ROLLBACK; RAISE EXCEPTION 'CONDUCTOR_CON_INCIDENTES'; END IF;
    UPDATE conductores SET activo=FALSE, estado='INACTIVO' WHERE id=p_conductor_id;
    COMMIT;
    RAISE NOTICE 'PROCEDIMIENTO OK: conductor % dado de baja', p_conductor_id;
END;
$$;
```

- **Caso correcto:** dar de baja un conductor sin asignaciones/incidentes pendientes → COMMIT (verificar activo=FALSE).
- **Caso incorrecto:** conductor con asignaciones activas o con incidentes pendientes, o conductor ya inactivo / inexistente → ROLLBACK.

---

### Procedimiento 10: `sp_contar_conductores_por_estado`

- **Objetivo:** Contar conductores activos agrupados por estado (reporte), validando el parámetro de estado recibido.
- **Funcionamiento:** Valida que el estado (si se pasa) sea permitido; ejecuta el SELECT de conteo agregado y hace `COMMIT`.
- **Código:**

```sql
CREATE OR REPLACE PROCEDURE sp_contar_conductores_por_estado(p_estado VARCHAR)
LANGUAGE plpgsql
AS $$
DECLARE v_activos INTEGER; v_inactivos INTEGER; v_suspendidos INTEGER;
BEGIN
    IF p_estado IS NOT NULL AND p_estado NOT IN ('ACTIVO','INACTIVO','SUSPENDIDO') THEN
        ROLLBACK; RAISE EXCEPTION 'ESTADO_INVALIDO: %', p_estado; END IF;
    SELECT COUNT(*) FILTER (WHERE estado='ACTIVO'),
           COUNT(*) FILTER (WHERE estado='INACTIVO'),
           COUNT(*) FILTER (WHERE estado='SUSPENDIDO')
      INTO v_activos, v_inactivos, v_suspendidos
    FROM conductores WHERE activo=TRUE AND (p_estado IS NULL OR estado=p_estado);
    COMMIT;
    RAISE NOTICE 'Reporte: ACTIVOS=%, INACTIVOS=%, SUSPENDIDOS=%', v_activos, v_inactivos, v_suspendidos;
END;
$$;
```

- **Caso correcto:** `CALL sp_contar_conductores_por_estado(NULL)` y `CALL sp_contar_conductores_por_estado('ACTIVO')` → COMMIT.
- **Caso incorrecto:** `CALL sp_contar_conductores_por_estado('JUBILADO')` → ROLLBACK.

---

## 4. Tabla Resumen de Control Transaccional

| # | Procedimiento | Operación | Validación con `IF` | COMMIT | ROLLBACK |
|---|---------------|-----------|---------------------|--------|----------|
| 1 | sp_registrar_conductor | INSERT | cédula 10 díg, email, duplicados | ✔ | ✔ |
| 2 | sp_registrar_vehiculo | INSERT | placa, año, capacidad | ✔ | ✔ |
| 3 | sp_asignar_ruta | INSERT | conductor/vehículo activos, concurrencia | ✔ | ✔ |
| 4 | sp_reportar_incidente | INSERT+UPDATE | asignación, gravedad | ✔ | ✔ |
| 5 | sp_actualizar_estado_conductor | UPDATE | estado, sin asignaciones | ✔ | ✔ |
| 6 | sp_cambiar_estado_vehiculo | UPDATE | estado, disponibilidad | ✔ | ✔ |
| 7 | sp_cambiar_estado_incidente | UPDATE | flujo de estados | ✔ | ✔ |
| 8 | sp_completar_asignacion | UPDATE | estado, fechas | ✔ | ✔ |
| 9 | sp_eliminar_conductor_logico | UPDATE | sin asig/incidentes | ✔ | ✔ |
| 10 | sp_contar_conductores_por_estado | SELECT | estado válido | ✔ | ✔ |

---

## 5. Conclusión

> *(Redactar al menos 2–3 párrafos. Ideas sugeridas:)*
> - La actividad permitió aplicar procedimientos almacenados en PostgreSQL sobre la base de datos real de SGROAS.
> - Se comprendió que una operación de negocio puede involucrar varias instrucciones SQL y que el control transaccional (COMMIT/ROLLBACK) garantiza la consistencia de datos: cuando todas las validaciones son correctas la operación se confirma, y ante una validación fallida o error se revierte todo.
> - Las validaciones con `IF` y el manejo de errores con `RAISE EXCEPTION` permiten controlar escenarios de negocio y evitar datos inconsistentes (duplicados, conductores suspendidos con asignaciones, vehículos retirados en uso, etc.).
> - La concurrencia y el control de disponibilidad (asignación de rutas, flota) son aspectos clave a cuidar en sistemas de transporte.
> - *(Conclusión personal del estudiante sobre lo aprendido.)*

---

## 6. Anexos

- Script de creación: `01_procedimientos.sql`
- Script de pruebas: `02_pruebas.sql`
- Capturas de evidencia (creación, caso correcto, caso incorrecto, datos antes/después).

---

*Fin del informe.*
