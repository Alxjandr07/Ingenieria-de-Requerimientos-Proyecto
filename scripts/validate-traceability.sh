#!/usr/bin/env bash
# =============================================================================
# validate-traceability.sh
# Valida la matriz de trazabilidad end-to-end (Bloque A.3.3 de la guia).
# - Verifica la estructura de columnas obligatorias de docs/trazabilidad/matriz.csv
# - Rechaza (exit != 0) si un requisito se agrega sin correspondencia en al menos
#   una historia de usuario, un caso de uso o una prueba automatizada.
# Uso: scripts/validate-traceability.sh
# =============================================================================
set -euo pipefail

MATRIZ="docs/trazabilidad/matriz.csv"

if [[ ! -f "$MATRIZ" ]]; then
    echo "ERROR: no existe $MATRIZ" >&2
    exit 1
fi

HEADER="id_requisito,tipo,prioridad_moscow,historia_usuario,caso_de_uso,modulo_codigo,endpoint_api,prueba_automatizada,tipo_acceso,evidencia_empirica,estado"

FIRST_LINE="$(head -n 1 "$MATRIZ" | tr -d '\r')"
if [[ "$FIRST_LINE" != "$HEADER" ]]; then
    echo "ERROR: cabecera de matriz.csv incorrecta." >&2
    echo "  Esperado: $HEADER" >&2
    echo "  Recibido: $FIRST_LINE" >&2
    exit 1
fi

ERRS=0
# Salta la cabecera
while IFS= read -r line; do
    line="$(echo "$line" | tr -d '\r')"
    [[ -z "$line" ]] && continue

    IFS=',' read -r id tipo prioridad historia caso modulo endpoint prueba tipo_acceso evidencia estado <<<"$line"

    if [[ -z "$id" || -z "$tipo" || -z "$prioridad" ]]; then
        echo "ERROR: fila sin id/tipo/prioridad: $line" >&2
        ERRS=$((ERRS+1))
        continue
    fi

    if [[ "$tipo" != "Funcional" && "$tipo" != "No funcional" ]]; then
        echo "ERROR: tipo invalido en $id ('$tipo'). Debe ser 'Funcional' o 'No funcional'." >&2
        exit 1
    fi

    if [[ "$tipo" == "Funcional" ]]; then
        if [[ -z "$historia" && -z "$caso" && -z "$prueba" ]]; then
            echo "ERROR: $id (Funcional) sin correspondencia en historia, caso de uso o prueba." >&2
            ERRS=$((ERRS+1))
        fi
    else
        if [[ -z "$prueba" && -z "$evidencia" ]]; then
            echo "ERROR: $id (No funcional) sin prueba automatizada ni evidencia empirica." >&2
            ERRS=$((ERRS+1))
        fi
    fi
done < <(tail -n +2 "$MATRIZ")

if [[ "$ERRS" -gt 0 ]]; then
    echo "ERROR: la matriz de trazabilidad tiene $ERRS requisito(s) sin trazabilidad minima." >&2
    exit 1
fi

echo "OK: matriz de trazabilidad valida ($(($(wc -l < "$MATRIZ") - 1)) requisitos)."
exit 0
