#!/bin/bash
# A07 - Fallo de identificacion y autenticacion
# Verifica rate limiting: tras 6 intentos fallidos, el 7o se bloquea con 429.
# Registro de salida reproducido en A07-rate-limit.txt.

URL="http://localhost:8080/api/auth/login"
OUT="docs/mediciones/sec/A07-rate-limit.txt"

echo "# A07 - Autenticacion (Rate Limiting: 6 intentos fallidos -> 429)" > "$OUT"
echo "# Fecha: $(date '+%Y-%m-%d %H:%M:%S')" >> "$OUT"

for i in $(seq 1 7); do
  RESP=$(curl -s -w '|HTTP_CODE:%{http_code}' -X POST "$URL" \
    -H "Content-Type: application/json" \
    -d '{"email":"admin@sgroas.com","password":"wrongpass"}')
  echo "Intento $i: $RESP" | tee -a "$OUT"
done