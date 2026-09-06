# ====================================================
# A01 - Control de acceso
# ====================================================
# Prueba 1: Sin autenticacion -> 401/403
echo "=== A01-01: Sin autenticacion a /api/conductores ==="
curl.exe -s -o A01-01-response.json -w "\nHTTP_CODE: %{http_code}\n" http://localhost:8080/api/conductores

echo ""
echo "=== A01-02: Con token valido a /api/conductores ==="
# Primero login
curl.exe -s http://localhost:8080/api/auth/login -X POST -H "Content-Type: application/json" -d "@$env:TEMP\login.json" > "$env:TEMP\login-response.json"
# Extraer token con PowerShell
$token = (Get-Content "$env:TEMP\login-response.json" -Raw | ConvertFrom-Json).accessToken
curl.exe -s -H "Authorization: Bearer $token" http://localhost:8080/api/conductores/1
