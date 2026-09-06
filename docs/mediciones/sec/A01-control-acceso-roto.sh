#!/bin/bash
# A01 - Control de acceso roto
# Verifica que un usuario A no pueda acceder al recurso de B
# Debe responder 403 Forbidden

echo "=== A01: Control de acceso roto ==="

# 1. Login como usuario SEGURIDAD
echo "--- Login como SEGURIDAD ---"
curl -s -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"seguridad@sgroas.com","password":"seg123"}' \
  -c /tmp/cookies-seg.txt

echo ""

# 2. Intentar acceder a endpoint de ADMIN (crear conductor)
echo "--- Intentar crear conductor (deberia ser 403) ---"
curl -s --include -X POST http://localhost:8080/api/conductores \
  -H "Content-Type: application/json" \
  -b /tmp/cookies-seg.txt \
  -d '{"nombres":"Test","apellidos":"Test","cedula":"1234567890","numeroLicencia":"LIC123","tipoLicencia":"B1","fechaVencimientoLicencia":"2027-01-01","estado":"ACTIVO"}'

echo ""
echo "--- Resultado esperado: 403 Forbidden ---"
