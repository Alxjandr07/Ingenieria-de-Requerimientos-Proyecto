# Guion de Defensa — Administración de Bases de Datos (ABD)

**Materia:** ABD · **Sistema:** SGROAS · **Estado:** listo para defender
**Datos base verificados en BD:** 1,058,397 registros · PostgreSQL 18.4 · contenedor `sgroas-postgres`

---

## 0. Lo primero que dices (apertura de 30 segundos)

> "El sistema SGROAS corre sobre una base de datos PostgreSQL 18. Para cumplir el
> requisito de mínimo un millón de registros, cargué el generador de datos masivos
> con una escala de 1.5 millones, y la base quedó con 1,058,397 registros
> distribuidos en 12 tablas. Además implementé stored procedures, cursores,
> triggers, roles con privilegios y un plan de respaldo, todo sobre esas tablas
> con datos reales."

---

## 1. STORED PROCEDURES + CURSOres

### Qué decir (concepto)
> "Un stored procedure es un bloque de instrucciones SQL que vive en el servidor.
> En vez de mandar la consulta desde la app cada vez, guardo la lógica pesada
> (JOINs + agregaciones) como un procedimiento PL/pgSQL. Se reutiliza, corre cerca
> de los datos y se invoca desde Java con JPA `@Procedure`."

### Cursores
> "Los procedimientos retornan sus resultados mediante un cursor de PostgreSQL
> (`REFCURSOR`, parámetro `INOUT`). El cursor apunta a las filas del resultado y
> permite recorrerlas sin devolver todo de golpe."

### Los 5 procedimientos (sobre las tablas del millón)

| Procedimiento | Descripción |
|---|---|
| `fn_abd_resumen_flota` | KPIs generales: conductores, unidades, rutas, programaciones, incidentes, auditoría |
| `sp_abd_incidentes_por_nivel` | Incidentes agrupados por nivel de riesgo |
| `sp_abd_programaciones_por_estado` | Programaciones por estado en un rango de fechas |
| `sp_abd_unidades_mantenimiento` | Unidades en mantenimiento con total de programaciones |
| `fn_abd_licencias_por_vencer` | Conductores con licencia por vencer en N días |

### Demo (ejecutar en vivo, datos reales)
```sql
BEGIN;
CALL fn_abd_resumen_flota('cur1');
FETCH ALL FROM cur1;
COMMIT;
```
Resultado real obtenido:
```
total_conductores=60006 | total_unidades=3006 | unidades_activas=2854 |
total_rutas=326 | total_programaciones=750000 | total_incidentes=15000 |
total_auditoria=150000
```

---

## 2. TRIGGERS — regla de negocio automática

### Qué decir (concepto)
> "Un trigger es un disparador automático: se ejecuta solo cuando ocurre un
> INSERT/UPDATE/DELETE sobre una tabla, sin intervención del código."

### El trigger ABD
> "Implementé `trg_abd_incidente_alto`, que dispara la función
> `fn_alerta_incidente_alto()`. La **regla de negocio** es: cuando se registra un
> incidente con riesgo ALTO, la base crea automáticamente una alerta."

### Demo (ejecutar en vivo)
```sql
-- 1. ver alertas actuales
SELECT COUNT(*) FROM alerta;              -- 5001

-- 2. insertar incidente nivel ALTO
INSERT INTO incidente (tipo, descripcion, nivel_sugerido, fecha_incidente,
                       evidencia, estado, id_unidad)
VALUES ('Choque', 'PRUEBA TRIGGER', 'ALTO', NOW(), NULL, 'Reportado',
        (SELECT MAX(id_unidad) FROM unidad))
RETURNING id_incidente;                   -- quedó 15002

-- 3. la alerta apareció sola
SELECT id_alerta, descripcion, id_incidente
FROM alerta WHERE descripcion LIKE 'Alerta automatica%'
ORDER BY id_alerta DESC LIMIT 1;          -- alerta 5001 -> incidente 15002
```
Resultado real obtenido: **la alerta se generó sola** (sin ningún INSERT manual).

---

## 3. OPTIMIZACIÓN — EXPLAIN ANALYZE e índices

### Qué decir (concepto)
> "Para optimizar el acceso a más de un millón de filas creé índices sobre las
> columnas que se filtran y agrupan, y lo demuestro comparando el plan de
> ejecución de una misma consulta con y sin índice."

### Índices creados
`idx_abd_incidente_nivel_estado`, `idx_abd_incidente_fecha`,
`idx_abd_programacion_estado_fecha`, `idx_abd_programacion_unidad_fecha`,
`idx_abd_auditoria_accion_fecha`, `idx_abd_conductor_fecha_vencimiento`,
`idx_abd_unidad_estado`.

### Demo (resultados reales medidos)

Consulta: contar programaciones de los últimos 30 días sobre 750,000 filas.

| Métrica | CON índice (Index Only Scan) | SIN índice (Seq Scan) |
|---|---|---|
| **Tiempo ejecución** | **7.4 ms** | **51.7 ms** |
| **Buffers leídos** | **83** | **7,732** |

> "El índice hizo la consulta **aprox. 7 veces más rápida** y leyó **~90 veces
> menos buffers**. Además usa *Index Only Scan*, lo que significa que resuelve
> desde el índice sin tocar la tabla."

Comandos:
```sql
-- CON índice
EXPLAIN (ANALYZE, TIMING OFF)
SELECT COUNT(*) FROM programacion
WHERE fecha BETWEEN CURRENT_DATE - 30 AND CURRENT_DATE;

-- SIN índice (deshabilitando el index scan para el comparativo)
SET enable_indexscan = off;
SET enable_bitmapscan = off;
EXPLAIN (ANALYZE, TIMING OFF) SELECT COUNT(*) FROM programacion
WHERE fecha BETWEEN CURRENT_DATE - 30 AND CURRENT_DATE;
```

---

## 4. ROLES Y PRIVILEGIOS (seguridad de acceso)

### Qué decir
> "Creé tres perfiles con privilegios diferenciados sobre el esquema ABD, para
> aplicar el principio de menor privilegio: nadie tiene más acceso del que necesita."

| Rol | Privilegios |
|---|---|
| `abd_lectura` | SOLO SELECT (consultas y reportes) |
| `abd_operador` | SELECT en catálogos + SELECT/INSERT/UPDATE en `programacion` e `incidente` |
| `abd_auditor` | SELECT en todo + INSERT en `auditoria` |

### Demo
```sql
SELECT rolname FROM pg_roles WHERE rolname LIKE 'abd_%';
-- abd_auditor | abd_lectura | abd_operador

-- Ver privilegios de un rol
\dp programacion
```

---

## 5. RESPALDO (backup)

### Qué decir
> "La política de respaldo (`docs/despliegue/BACKUP.md`) es diaria con retención
> de 30 días usando `pg_dump` en formato custom. Ya generé y verifiqué el primer
> respaldo real."

### Evidencia
- **Archivo:** `backups/sgroas-2026-08-28.sql.dump`
- **Tamaño:** 17.25 MB · **Formato:** custom + compresión gzip (PostgreSQL 18.4)
- **Integridad verificada:** `pg_restore --list` lee el dump sin errores (228 entradas TOC)

### Comandos de referencia
```bash
# crear respaldo (dentro del contenedor, o en host con pg_dump)
docker exec sgroas-postgres pg_dump -U postgres -d sgroas_db --format=custom --file=/tmp/backup.dump
docker cp sgroas-postgres:/tmp/backup.dump ./backups/sgroas-DATE.sql.dump

# verificar integridad
docker exec sgroas-postgres pg_restore --list /tmp/verify.dump
```

---

## 6. Posibles preguntas del profesor (y respuestas)

**¿El millón de registros es real o generado?**
> "Es un generador de datos masivos (`db/data/generar_datos_masivos.sql`) que
> respeta las claves foráneas e inserta datos coherentes. Los conteos reales en BD
> son 750,000 programaciones, 150,000 auditorías, 60,006 conductores, 15,000
> incidentes. Es el procedimiento estándar para poblar bases de prueba a escala."

**¿Por qué hay tablas en singular y otras en plural?**
> "Conviven dos modelos: el esquema funcional del backend (usuarios, conductores,
> vehiculos, rutas, incidentes) y la réplica del modelo ABD (usuario, conductor,
> unidad, ruta, programacion, incidente, alerta, auditoria). El millón de registros,
> los stored procedures ABD, el trigger, los roles y el respaldo están sobre el
> modelo ABD."

**¿Cuáles son las ventajas de un stored procedure frente a consultarnos directo?**
> "Reutilización, mantenimiento centralizado, mejor rendimiento (el plan se
> reutiliza) y seguridad (no se exponen las tablas: solo se llama al procedimiento)."

**¿Qué índice usaste y por qué?**
> "Sobre `programacion.estado+fecha` para los reportes por fecha/estado, y sobre
> `incidente.nivel_sugerido+estado` para las métricas de seguridad. Los índices
> compuestos atacan las agrupaciones y filtros que usan las consultas analíticas."

---

## Cheat-sheet de comandos rápidos (para el día de la defensa)

```bash
# Conteos (total del sistema)
docker exec sgroas-postgres psql -U postgres -d sgroas_db -c \
"SELECT (SELECT count(*) FROM programacion) AS prog, (SELECT count(*) FROM auditoria) AS aud, (SELECT count(*) FROM incidente) AS inc, (SELECT count(*) FROM conductor) AS cond;"

# Probar SP con cursor
docker exec sgroas-postgres psql -U postgres -d sgroas_db -c "BEGIN; CALL fn_abd_resumen_flota('c'); FETCH ALL FROM c; COMMIT;"

# Probar trigger
docker exec sgroas-postgres psql -U postgres -d sgroas_db -c "SELECT COUNT(*) FROM alerta;"

# Ver objetos creados
docker exec sgroas-postgres psql -U postgres -d sgroas_db -c "SELECT proname FROM pg_proc WHERE proname LIKE 'sp_abd%' OR proname LIKE 'fn_abd%';"
docker exec sgroas-postgres psql -U postgres -d sgroas_db -c "SELECT tgname FROM pg_trigger WHERE NOT tgisinternal AND tgname='trg_abd_incidente_alto';"
```
