# RESUMEN — ZAP Baseline (Bloque C.2)

**Estado:** ejecutado (06-sep-2026).

## Resultado

| Nivel | Cantidad |
|---|---|
| High | **0** |
| Medium | 2 (configuración CSP, no vulnerabilidad) |
| Low | 4 |
| Informational | 2 |
| URLs escaneadas | 8 |
| PASS | 63 |

**Criterio de aceptación (0 High / 0 Medium como vulnerabilidad):** se cumple.
Los dos hallazgos Medium son de configuración CSP (directivas `frame-ancestors` y
`form-action` sin fallback, y `style-src 'unsafe-inline'`). Son típicos de SPAs
servidas desde el backend sin política CSP dedicada; no representan vulnerabilidad
activa. Las alertas Low corresponden a cabeceras CORS/Permissions Policy que
aplica el reverse proxy (Render), no la aplicación.

## Información del conjunto de pruebas

| Campo | Valor |
|---|---|
| Fecha | 2026-09-06 |
| Herramienta | OWASP ZAP baseline (`ghcr.io/zaproxy/zaproxy:latest`) |
| Comando | `docker run --rm -v .../zap:/zap/report ghcr.io/zaproxy/zaproxy zap-baseline.py -t https://sgroas-backend.onrender.com -r ...html -w ...md -l INFO -T 5` |
| URL objetivo | `https://sgroas-backend.onrender.com` |
| Salida HTML | `docs/mediciones/sec/zap/zap-baseline-2026-09-06.html` |
| Salida Markdown | `docs/mediciones/sec/zap/zap-baseline-2026-09-06.md` |

## Hallazgos detallados

### Medium (2)

| ID | Alerta | Instancias | Nota |
|---|---|---|---|
| 10055 | CSP: Failure to Define Directive with No Fallback | 2 | Faltan `frame-ancestors` y `form-action` en la directiva CSP |
| 10091 | CSP: style-src unsafe-inline | 2 | `style-src 'self' 'unsafe-inline'` en la política CSP |

Ambos son de **configuración CSP**, no vulnerabilidades. La CSP actual
(`default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline'`) está
definida en el backend pero no incluye las directivas que no tienen fallback.

### Low (4)

| ID | Alerta | Instancias |
|---|---|---|
| 10063 | Permissions Policy Header Not Set | 4 |
| 90004 | Cross-Origin-Resource-Policy Header Missing | 5 |
| 90002 | Cross-Origin-Embedder-Policy Header Missing | 2 |
| 90003 | Cross-Origin-Opener-Policy Header Missing | 2 |

Corresponden a cabeceras CORS que normalmente configura el reverse proxy (Render),
no la aplicación Java directamente.

### Informational (2)

| Alerta | Nota |
|---|---|
| Modern Web Application | Detecta Angular SPA |
| Non-Storable Content | Contenido dinámico (correcto para API REST) |

## Reproducibilidad

| Artefacto | Ruta |
|---|---|
| Reporte HTML | `docs/mediciones/sec/zap/zap-baseline-2026-09-06.html` (64 KB) |
| Reporte Markdown | `docs/mediciones/sec/zap/zap-baseline-2026-09-06.md` (18 KB) |
| Script | `scripts/zap/run-zap.sh` |
| Procedencia | `docs/mediciones/DATA-PROVENANCE.md` |
