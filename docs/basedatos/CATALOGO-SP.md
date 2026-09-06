# Catalogo de Stored Procedures — SGROAS

## Resumen

| # | Nombre | Tipo | Descripcion | Invocacion JPA |
|---|--------|------|-------------|----------------|
| 1 | `sp_obtener_incidentes_por_rango` | PROCEDURE | Incidentes en rango de fechas con JOIN a 5 tablas | `@Procedure` en `IncidenteRepository` |
| 2 | `sp_incidentes_por_gravedad` | PROCEDURE | Conteo de incidentes agrupados por gravedad | `@Procedure` en `IncidenteRepository` |
| 3 | `sp_asignaciones_activas_por_conductor` | PROCEDURE | Asignaciones activas de un conductor especifico | `@Procedure` en `AsignacionRutaRepository` |
| 4 | `sp_vehiculos_en_mantenimiento` | PROCEDURE | Vehiculos en mantenimiento con total de incidentes | `@Procedure` en `VehiculoRepository` |
| 5 | `sp_reporte_rendimiento_rutas` | PROCEDURE | Reporte de rendimiento por ruta con metricas | `@Procedure` en `RutaRepository` |
| 6 | `fn_licencias_por_vencer` | PROCEDURE | Conductores con licencias por vencer | `@Procedure` en `ConductorRepository` |
| 7 | `fn_estadisticas_generales` | PROCEDURE | Estadisticas generales del sistema | `@Procedure` en `IncidenteRepository` |

> **Firma de invocacion (JPA 2.1+):** todos los procedimientos usan un parametro
> `INOUT cur refcursor` que transporta el result set. Se invocan EXCLUSIVAMENTE
> via `@NamedStoredProcedureQuery` (declarada en la entidad) + `@Procedure(name=...)`
> en el repositorio, con el cursor declarado como
> `@StoredProcedureParameter(mode = ParameterMode.REF_CURSOR, type = Class.class)`
> (prohibido SQL dinamico o `createNativeQuery` con concatenacion, ver ADR-006 y
> `scripts/audit-sql-dynamic.sh`). Requisito PostgreSQL/pgjdbc: la lectura del
> REFCURSOR debe ocurrir dentro de la misma transaccion JDBC, por lo que la capa
> de invocacion (`ReporteService`, tests) esta anotada con `@Transactional`.
> Instalados en BD por la migracion Flyway `V5__stored_procedures.sql`
> (sincronizada con `db/procs/*.sql`).

---

## 1. `sp_obtener_incidentes_por_rango`

**Archivo:** `db/procs/sp_obtener_incidentes_por_rango.sql`

Obtiene todos los incidentes en un rango de fechas, incluyendo informacion del conductor, vehiculo y ruta.

**JOINs:** `incidentes` → `asignacion_rutas` → `conductores` + `vehiculos` + `rutas`

**Parametros:**

| Parametro | Tipo | Descripcion |
|-----------|------|-------------|
| `p_fecha_desde` | TIMESTAMPTZ | Inicio del rango |
| `p_fecha_hasta` | TIMESTAMPTZ | Fin del rango |

**Columnas retornadas:** `incidente_id`, `tipo`, `gravedad`, `estado`, `descripcion`, `fecha_incidente`, `ubicacion`, `conductor_nombre`, `vehiculo_placa`, `ruta_codigo`

**Uso:** Reportes operativos, dashboards de seguridad.

---

## 2. `sp_incidentes_por_gravedad`

**Archivo:** `db/procs/sp_incidentes_por_gravedad.sql`

Agrupa y cuenta incidentes por nivel de gravedad, con filtro opcional por tipo.

**Agregaciones:** `COUNT(*)`, `GROUP BY`, `MAX(fecha_incidente)`

**Parametros:**

| Parametro | Tipo | Descripcion |
|-----------|------|-------------|
| `p_tipo` | VARCHAR (opcional) | Filtro por tipo de incidente |

**Columnas retornadas:** `gravedad`, `total_incidentes`, `ultimo_incidente`

**Uso:** Metricas de seguridad, analisis de tendencias.

---

## 3. `sp_asignaciones_activas_por_conductor`

**Archivo:** `db/procs/sp_asignaciones_activas_por_conductor.sql`

Devuelve las asignaciones activas de un conductor con datos del vehiculo y la ruta.

**JOINs:** `asignacion_rutas` → `conductores` → `vehiculos` → `rutas`

**Parametros:**

| Parametro | Tipo | Descripcion |
|-----------|------|-------------|
| `p_conductor_id` | BIGINT | ID del conductor |

**Columnas retornadas:** `asignacion_id`, `vehiculo_placa`, `vehiculo_marca`, `ruta_codigo`, `ruta_nombre`, `fecha_inicio`, `fecha_fin`

**Uso:** Consulta de ruta actual de un conductor, app movil.

---

## 4. `sp_vehiculos_en_mantenimiento`

**Archivo:** `db/procs/sp_vehiculos_en_mantenimiento.sql`

Lista vehiculos en mantenimiento con conteo de asignaciones e incidentes asociados.

**JOINs:** `vehiculos` → `asignacion_rutas` → `incidentes` (LEFT JOIN)

**Columnas retornadas:** `vehiculo_id`, `placa`, `marca`, `modelo`, `anio`, `total_asignaciones`, `total_incidentes`

**Uso:** Gestion de flota, reportes de mantenimiento.

---

## 5. `sp_reporte_rendimiento_rutas`

**Archivo:** `db/procs/sp_reporte_rendimiento_rutas.sql`

Reporte de rendimiento por ruta con desglose de incidentes por gravedad.

**Agregaciones:** `COUNT(DISTINCT)`, `CASE WHEN`, `AVG`

**Columnas retornadas:** `ruta_id`, `ruta_codigo`, `ruta_nombre`, `total_asignaciones`, `total_incidentes`, `incidentes_criticos`, `incidentes_altos`, `incidentes_medios`, `incidentes_bajos`, `promedio_distancia_km`

**Uso:** Toma de decisiones, planificacion de rutas.

---

## 6. `fn_licencias_por_vencer`

**Archivo:** `db/procs/fn_licencias_por_vencer.sql`

Retorna conductores cuya licencia vence dentro de un umbral de dias.

**Parametros:**

| Parametro | Tipo | Descripcion |
|-----------|------|-------------|
| `p_dias_umbral` | INTEGER | Dias para considerar "por vencer" (default 30 gestionado en la capa JPA: `@RequestParam(defaultValue="30")`) |

**Columnas retornadas:** `conductor_id`, `nombre_completo`, `cedula`, `numero_licencia`, `tipo_licencia`, `fecha_vencimiento`, `asignacion_activa`

**Uso:** Alertas preventivas, renovacion de licencias.

---

## 7. `fn_estadisticas_generales`

**Archivo:** `db/procs/fn_estadisticas_generales.sql`

Estadisticas resumidas del sistema, util para dashboards.

**Columnas retornadas:** `total_conductores`, `conductores_activos`, `total_vehiculos`, `vehiculos_activos`, `total_rutas`, `rutas_activas`, `total_asignaciones`, `asignaciones_activas`, `total_incidentes`, `incidentes_abiertos`

**Uso:** Dashboard principal, KPIs del sistema.

---

# Apendice B — Objetos ABD (esquema del millon de registros)

> Instalados sobre las tablas ABD (`programacion`, `incidente`, `unidad`,
> `conductor`, `auditoria`) mediante `db/abd/objetos_abd.sql`. Retornan
> `INOUT cur refcursor` igual que el resto y se invocan via JPA `@Procedure`.

| # | Nombre | Tipo | Descripcion | Tablas |
|---|--------|------|-------------|--------|
| B1 | `fn_abd_resumen_flota` | PROCEDURE | KPIs generales (conductores, unidades, rutas, programaciones, incidentes, auditoria) | todas |
| B2 | `sp_abd_incidentes_por_nivel` | PROCEDURE | Incidentes agrupados por nivel de riesgo | `incidente` |
| B3 | `sp_abd_programaciones_por_estado` | PROCEDURE | Programaciones por estado en un rango de fechas | `programacion` |
| B4 | `sp_abd_unidades_mantenimiento` | PROCEDURE | Unidades en mantenimiento con total de programaciones | `unidad`, `programacion` |
| B5 | `fn_abd_licencias_por_vencer` | PROCEDURE | Conductores con licencias por vencer en N dias | `conductor` |

**Indices creados:** `idx_abd_incidente_nivel_estado`, `idx_abd_incidente_fecha`,
`idx_abd_programacion_estado_fecha`, `idx_abd_programacion_unidad_fecha`,
`idx_abd_auditoria_accion_fecha`, `idx_abd_conductor_fecha_vencimiento`,
`idx_abd_unidad_estado`.

**Trigger de regla de negocio:** `trg_abd_incidente_alto` (funcion
`fn_alerta_incidente_alto()`) deriva automaticamente una fila en `alerta`
cuando se inserta/actualiza un incidente con `nivel_sugerido = 'ALTO'`
(verificado: INSERT de incidente 15002 genero alerta 5001).

**Roles y privilegios:** `abd_lectura` (solo SELECT), `abd_operador`
(SELECT/INSERT/UPDATE en programacion e incidente + lectura de catalogos),
`abd_auditor` (SELECT en todo + INSERT en auditoria).
