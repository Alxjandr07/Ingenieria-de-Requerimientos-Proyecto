#!/usr/bin/env bash
# =============================================================================
# run-zap.sh
# Ejecuta el escaneo baseline de OWASP ZAP (Bloque C.2 / tarea K3) contra la
# URL publica HTTPS. Genera el reporte HTML en docs/mediciones/sec/zap/.
# Depende de la URL publica desplegada por Alejandro (dependencia A5/K3).
#
# Uso: scripts/zap/run-zap.sh https://TU-URL
# =============================================================================
set -euo pipefail

URL="${1:?Uso: run-zap.sh https://TU-URL}"
SALIDA="docs/mediciones/sec/zap"
mkdir -p "$SALIDA"

FECHA=$(date +%F)
REPORTE="$SALIDA/zap-baseline-$FECHA.html"

echo "== ZAP baseline contra $URL =="
docker run --rm -v "$(pwd)/$SALIDA:/zap/report" \
  ghcr.io/zaproxy/zaproxy \
  zap-baseline.py \
    -t "$URL" \
    -r "zap-baseline-$FECHA.html" \
    -w "/zap/report/zap-baseline-$FECHA.md" \
    -l INFO

echo "Reporte HTML: $REPORTE"
echo "Resumen: $SALIDA/zap-baseline-$FECHA.md"
echo "Listo. Registrar el resumen en $SALIDA/RESUMEN.md"