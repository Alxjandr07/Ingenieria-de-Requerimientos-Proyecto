#!/bin/bash
# A05 - Malconfiguracion de seguridad
# Verifica cabeceras HTTP de seguridad

echo "=== A05: Malconfiguracion de seguridad ==="

echo "--- Cabeceras de seguridad ---"
curl -s -I http://localhost:8080/api/conductores | grep -E "(Strict-Transport-Security|X-Frame-Options|X-Content-Type-Options|Content-Security-Policy)"

echo ""
echo "--- Resultados esperados: ---"
echo "Strict-Transport-Security: max-age=31536000; includeSubDomains"
echo "X-Frame-Options: DENY"
echo "X-Content-Type-Options: nosniff"
echo "Content-Security-Policy: default-src 'self'"
