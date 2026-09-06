#!/usr/bin/env bash
# =============================================================================
# backup-prod.sh
# Backup diario de la BD de produccion de SGROAS (pg_dump custom, gzip).
# Politica: frecuencia diaria, retencion 30 dias, prueba de restauracion
# documentada en docs/despliegue/BACKUP.md.
#
# Uso:
#   scripts/backup-prod.sh                # backup del dia + retencion 30
#   scripts/backup-prod.sh --retention 30 # purga backups > 30 dias
#
# Variables de entorno (o DATABASE_URL estilo Render):
#   PGHOST, PGPORT, PGUSER, PGPASSWORD, PGDATABASE
# =============================================================================
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DIR="$ROOT/backups"
mkdir -p "$DIR"

STAMP="$(date +%Y-%m-%d)"
GZ="$DIR/sgroas-prod-$STAMP.sql.gz"
RETENTION_DAYS="${1:-30}"
if [[ "${1:-}" == "--retention" ]]; then RETENTION_DAYS="${2:-30}"; fi

if [[ -n "${DATABASE_URL:-}" ]]; then
    # form: postgres://user:pass@host:port/db
    DB_URL_ARGS=( "$DATABASE_URL" )
else
    DB_URL_ARGS=(
        "-h" "${PGHOST:?PGHOST requerida}"
        "-p" "${PGPORT:-5432}"
        "-U" "${PGUSER:?PGUSER requerida}"
        "-d" "${PGDATABASE:?PGDATABASE requerida}"
    )
    export PGPASSWORD="${PGPASSWORD:?PGPASSWORD requerida}"
fi

if [[ -f "$GZ" ]]; then
    echo "SKIP backup=$GZ ya existe"
else
    pg_dump "${DB_URL_ARGS[@]}" --format=custom --no-owner --no-privileges \
        | gzip > "$GZ"
    echo "OK backup=$GZ bytes=$(stat -c%s "$GZ")"
fi

# Retencion
cutoff="$(date -d "-${RETENTION_DAYS} days" +%Y-%m-%d)"
for f in "$DIR"/sgroas-prod-*.sql.gz; do
    [[ -e "$f" ]] || continue
    d="$(basename "$f" | sed -E 's/sgroas-prod-([0-9-]+)\.sql\.gz/\1/')"
    if [[ "$d" < "$cutoff" ]]; then
        rm -f "$f"
        echo "PURGE=$f"
    fi
done

echo "DONE retention=${RETENTION_DAYS}d files=$(ls "$DIR" | wc -l)"