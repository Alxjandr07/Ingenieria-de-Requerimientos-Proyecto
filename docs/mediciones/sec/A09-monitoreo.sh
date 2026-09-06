#!/bin/bash
# A09 - Fallo de registro y monitoreo
# Verifica que los logs contengan entradas de login exitoso y fallido

echo "=== A09: Registro y monitoreo ==="

echo "--- Login exitoso ---"
curl -s -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@sgroas.com","password":"admin123"}' > /dev/null

echo "--- Login fallido ---"
curl -s -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@sgroas.com","password":"wrongpass"}' > /dev/null

echo ""
echo "--- Revisando logs del contenedor backend ---"
docker logs sgroas-backend 2>&1 | grep -E "(login|auth|Login|Auth)" | tail -10

echo ""
echo "--- Verificar que cada entrada contenga: timestamp, IP, email ---"
