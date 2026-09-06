#!/bin/bash
# A02 - Fallo criptografico
# Verifica que el servidor use TLSv1.3 con cifrado AEAD

echo "=== A02: Fallo criptografico ==="
echo "--- Verificando TLSv1.3 y suite AEAD ---"
curl -v https://localhost:8443/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"test123"}' 2>&1 | grep -E "(TLS|SSL|cipher|handshake)"

echo ""
echo "--- Resultado esperado: TLSv1.3 con cifrado AEAD (ej: TLS_AES_256_GCM_SHA384) ---"
