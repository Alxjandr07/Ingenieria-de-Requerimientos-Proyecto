# Actividad - Procedimientos Almacenados en PostgreSQL (SGROAS)

Esta carpeta contiene los entregables de la práctica de procedimientos almacenados
sobre la base de datos del proyecto SGROAS (esquema backend: `conductores`,
`vehiculos`, `rutas`, `asignacion_rutas`, `incidentes`).

## Archivos

| Archivo | Descripción |
|---------|-------------|
| `01_procedimientos.sql` | Script con la creación de los 10 procedimientos almacenados (COMMIT/ROLLBACK internos). |
| `02_pruebas.sql` | Script con las pruebas: caso correcto e incorrecto para cada procedimiento, más consultas de verificación ANTES/DESPUÉS. |
| `../docs/informe/actividad_sprocs/INFORME_TECNICO.md` | Esqueleto del informe técnico (para convertirlo a PDF). |

## Cómo usar

### 1. Crear los procedimientos (en pgAdmin)

Abre pgAdmin, conéctate a tu base `sgroas_db`, abre el Query Tool y ejecuta el
contenido de `01_procedimientos.sql`. Verás 10 líneas `CREATE PROCEDURE`.

### 2. Ejecutar las pruebas

Ejecuta el contenido de `02_pruebas.sql`. **Importante:** antes de ejecutar las
pruebas, corre la sección `0) DIAGNOSTICO` que está al inicio del archivo para
ver los IDs reales de tu BD y ajusta las llamadas `CALL` que usan IDs fijos.

Los casos incorrectos lanzan un error (por ejemplo `CEDULA_DUPLICADA`,
`GRAVEDAD_INVALIDA`, etc.) — eso es lo esperado y demuestra el ROLLBACK.

### 3. Capturar evidencias para el informe

Por cada procedimiento captura (pantallazos en pgAdmin):
1. La **creación** del procedimiento (`CREATE PROCEDURE`).
2. La ejecución del **caso correcto** (mensaje `PROCEDIMIENTO OK` + COMMIT).
3. La ejecución del **caso incorrecto** (mensaje de error + ROLLBACK).
4. Las consultas **antes/después** mostrando los datos (para ver la diferencia).
5. Para concurrencia: dos `CALL` con el mismo conductor/vehículo en el mismo
   período (en `sp_asignar_ruta`) donde el segundo falla.

## Nota sobre PostgreSQL y las transacciones

En PostgreSQL, los procedimientos (`PROCEDURE`) invocados con `CALL` pueden
controlar la transacción con `COMMIT` y `ROLLBACK`. **No** se puede hacer
`COMMIT`/`ROLLBACK` dentro de un bloque `EXCEPTION` (genera error), por eso en
estos procedimientos:
- El `ROLLBACK` se ejecuta dentro de cada `IF` de validación fallida (cuerpo
  principal).
- El `COMMIT` se ejecuta al final del cuerpo, cuando la operación fue correcta.
- El error se informa al cliente con `RAISE EXCEPTION`.

Esto cumple el requisito de la rúbrica: "COMMIT cuando la operación finaliza
correctamente" y "ROLLBACK cuando una validación impide completar el proceso".
