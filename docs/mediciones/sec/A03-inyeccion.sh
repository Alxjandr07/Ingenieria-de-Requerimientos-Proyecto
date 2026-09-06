#!/bin/bash
# A03 - Inyeccion SQL
# Verifica que el sistema rechace intentos de inyeccion con 422 ProblemDetails

echo "=== A03: Inyeccion SQL ==="

echo "--- Intento de inyeccion en campo email ---"
curl -s -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"'"'"' OR '"'"'1'"'"'='"'"'1","password":"test"}' | python -m json.tool 2>/dev/null || echo ""

echo ""
echo "--- Intento de inyeccion en campo nombres (crear conductor) ---"
curl -s --include -X POST http://localhost:8080/api/conductores \
  -H "Content-Type: application/json" \
  -d '{"nombres":"'; DROP TABLE conductores; --","apellidos":"Test","cedula":"9999999999","numeroLicencia":"LIC-INJECT","tipoLicencia":"B1","fechaVencimientoLicencia":"2027-01-01","estado":"ACTIVO"}'

echo ""
echo "--- Resultado esperado: 422 Unprocessable Entity con ProblemDetails ---"
