# BACKUP.md — Copias de seguridad de SGROAS (produccion)

**Version:** v1.0.0 · **Fecha:** 2026-08-17

## 1. Politica

| Parametro | Valor |
|---|---|
| Frecuencia | **Diaria** (02:00 UTC) |
| Retencion | **30 dias** (se purgan backups > 30 dias) |
| Contenido | dump completo de PostgreSQL (`pg_dump --format=custom`) |
| Prueba de restauracion | **documentada** en la seccion 4 (se ejecuta al menos 1 vez al mes o tras cambios de esquema) |
| Responsable | Alejandro (operador de despliegue) |

## 2. Procedimiento automatico

Script: `scripts/backup-prod.sh` (usa `PGHOST/PGPORT/PGUSER/PGPASSWORD/PGDATABASE`
o un `DATABASE_URL` de Render).

```bash
# manual / cron
scripts/backup-prod.sh                # crea backups/sgroas-prod-YYYY-MM-DD.sql.gz
scripts/backup-prod.sh --retention 30 # borra backups con > 30 dias de antiguedad
```

Cron local (Windows Server) o scheduler equivalente:
```
0 2 * * *  scripts/backup-prod.sh && scripts/backup-prod.sh --retention 30
```

Salida esperada (una linea por ejecucion, para log):
```
OK backup=sgroas-prod-2026-08-17.sql.gz bytes=12345678 sha256=abcd...
```

## 3. Verificacion de integridad (diaria)

```bash
# comprobar que el dump es legible sin restaurar
gunzip -t backups/sgroas-prod-YYYY-MM-DD.sql.gz
# registrar sha256
Get-FileHash backups/sgroas-prod-YYYY-MM-DD.sql.gz -Algorithm SHA256
```

## 4. Prueba de restauracion documentada

**Ultima prueba:** pendiente de registro en la primera restauracion real
(se completara esta tabla en el RUNBOOK tras el despliegue).

| Fecha | Backups usados | Destino de prueba | Resultado |
|---|---|---|---|
| 2026-08-28 | `backups/sgroas-2026-08-28.sql.dump` | contenedor local `sgroas-postgres` (sgroas_db) | dump integrity OK (`pg_restore --list`, 228 TOC, custom/gzip 17.25 MB) |

Pasos:
1. Crear BD temporal en Render (o local `sgroas_restore_test`).
2. `gunzip -c backups/sgroas-prod-2026-08-17.sql.gz | psql "$URL_PRUEBA"`.
3. Comparar conteos contra la BD productiva:
   `SELECT (SELECT count(*) FROM conductores), ...`.
   Los 5 conteos de `fn_estadisticas_generales` deben coincidir.
4. Arrancar backend contra la BD de prueba con una variable
   `SPRING_DATASOURCE_URL` apuntando a ella y comprobar:
   `curl /actuator/health` → `db: UP` (Flyway valida las migraciones).
5. Documentar el resultado en la tabla de arriba.

## 5. Restauracion de emergencia

Ver `docs/despliegue/RUNBOOK.md` seccion 4 (drop schema + re-import).
RTO objetivo: < 30 minutos con el backup mas reciente.