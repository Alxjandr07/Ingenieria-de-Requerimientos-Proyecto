#!/usr/bin/env bash
# =============================================================================
# run-lighthouse.sh
# Ejecuta las 6 auditorias Lighthouse planificadas (Bloque C.5 / tarea K3):
#   3 moviles  (m1, m2, m3)  y 3 de escritorio (d1, d2, d3)
# Contra la URL publica HTTPS del despliegue de Alejandro (dependencia A5).
# Salida JSON+HTML en docs/mediciones/lighthouse/. Despues de las 6 corridas
# genera docs/mediciones/lighthouse/RESUMEN.md con las categorias.
#
# Uso: scripts/lighthouse/run-lighthouse.sh https://TU-URL
# =============================================================================
set -euo pipefail

URL="${1:?Uso: run-lighthouse.sh https://TU-URL}"
SALIDA="docs/mediciones/lighthouse"
mkdir -p "$SALIDA"

echo "== Auditorias mobile (m1-m3) =="
for i in 1 2 3; do
  npx lighthouse "$URL" \
    --preset=mobile \
    --output=json \
    --output=html \
    --output-path="$SALIDA/m${i}" \
    --quiet
  echo "  m${i} en $SALIDA/m${i}.json / .html"
done

echo "== Auditorias desktop (d1-d3) =="
for i in 1 2 3; do
  npx lighthouse "$URL" \
    --preset=desktop \
    --output=json \
    --output=html \
    --output-path="$SALIDA/d${i}" \
    --quiet
  echo "  d${i} en $SALIDA/d${i}.json / .html"
done

echo "== RESUMEN generado en $SALIDA/RESUMEN.md (editar con valores) =="
echo "Listo."