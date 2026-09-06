# Procedencia de datos (DATA PROVENANCE) — SGROAS

**Objetivo:** para cada tabla y figura del informe académico, este documento indica el
archivo de datos crudos, el script que la genera y el commit que la introdujo.
Todo número del informe es re-derivable desde estas fuentes (reglas de oro 6 y 9 del plan).

**Verificación:** 16 de agosto de 2026 — Kevin (Castro Espinoza)

## 1. Rendimiento (k6) — Bloque C.1

| Artefacto (tabla/figura) en informe | Datos crudos | Script | Commit |
|---|---|---|---|
| Tabla "Configuracion de k6" | `k6/opts.js` | — | `62bf8fa` |
| Tabla K1 local (corridas k01-k03) | `docs/mediciones/perf/k01-run1.json`, `k02-run2.json`, `k03-run3.json` | `scripts/perf-analysis.py` | `62bf8fa` (datos), `72b919c` (script) |
| Tabla Render caliente (K4-K8) | `docs/mediciones/perf/k04-run1.json` ... `k08-run1.json` | `scripts/perf-analysis.py` | `dea7940` |
| Muestras frias Render (K4-K8) | `docs/mediciones/perf/k04-cold.json` ... `k08-cold.json` | `scripts/perf/nonparametric.py` | `dea7940` |
| Tabla de estadistica agregada (media/DT/IC95) | ídem | `scripts/perf-analysis.py` | `761e5e1` |
| Fig. "Perfil de percentiles" | ídem | `scripts/gen-figuras.py` → `fig-percentiles-corridas.png` | `cba0e96` |
| Fig. "p95 por corrida" | ídem | `scripts/gen-figuras.py` → `fig-p95-por-corrida.png` | `cba0e96` |
| Fig. "Media e IC95" | ídem | `scripts/gen-figuras.py` → `fig-media-ic95.png` | `cba0e96` |
| Contraste frio vs caliente (Mann-Whitney) | k0X-cold.json + k0X-run1.json | `scripts/perf/nonparametric.py` | `dea7940` |
| Informe de analisis k6 | `docs/mediciones/perf/ANALISIS-k6.md` | `scripts/perf-analysis.py` | `dea7940` |
| IC bootstrap (validacion) | `docs/mediciones/perf/ANALISIS-BOOTSTRAP.md` | `scripts/perf-bootstrap.py` → `bootstrap.json` | `683cea3` |
| RENDER-REPORT.md | `docs/mediciones/perf/k04-k08` | `scripts/perf/nonparametric.py` | `dea7940` |

## 2. Usabilidad (SUS) — Bloque C.3

| Artefacto (tabla/figura) en informe | Datos crudos | Script | Commit |
|---|---|---|---|
| Tabla de puntuación por participante | `docs/mediciones/sus/sus-raw.csv` | `scripts/sus-analysis.py` | `e8d7e2f` (datos), `042bffa` (script) |
| Datos por participante (anexo) | `docs/mediciones/sus/P01.json` … `P10.json` | `scripts/sus-analysis.py` | `771b48e`, `2a118b8` |
| Estadísticos descriptivos e IC95 | `sus-raw.csv` | `scripts/sus-analysis.py` | `fe41053` |
| Fig. "SUS por participante" | `sus-raw.csv` | `scripts/sus-analysis.py` → `fig-sus-por-participante.png` | `458f322` |
| Puntuación (regla Brooke) | — | `scripts/sus/brooke.py` | `1a5c42c` |
| Informe de análisis SUS | `docs/mediciones/sus/ANALISIS-SUS.md` | `scripts/sus-analysis.py` | `fe41053` |
| Estadísticos por ítem (q1–q10) | `sus-raw.csv` | `scripts/sus-analysis.py` → `estadisticas-item.json` | `af9962d` |
| Fig. "Media de respuesta por ítem" | `sus-raw.csv` | `scripts/sus-analysis.py` → `fig-sus-item-respuestas.png` | `af9962d` |

## 3. Cobertura (JaCoCo) — Bloque C.4

| Artefacto (tabla/figura) en informe | Datos crudos | Script | Commit |
|---|---|---|---|
| Tabla de cobertura por clase | `docs/mediciones/jacoco/jacoco.csv` | `./mvnw verify` (reporte JaCoCo) | `dea7940` |
| Reporte HTML de cobertura | `docs/mediciones/jacoco/index.html` | JaCoCo Maven plugin | `dea7940` |

## 4. Calidad web (Lighthouse) — Bloque C.5

| Artefacto (tabla/figura) en informe | Datos crudos | Script | Commit |
|---|---|---|---|
| Tabla de categorías por corrida | `docs/mediciones/lighthouse/lhci-20260730-2115.json`, `lhci-20260730-2117.json` | `npx lighthouse` (ver `lighthouserc.js`) | `1a07dc7` |
| RESUMEN de lighthouse | `docs/mediciones/lighthouse/RESUMEN.md` | informe manual sobre JSON | por definir |

## 5. Seguridad (OWASP + ZAP) — Bloque C.2

| Artefacto (tabla/figura) en informe | Datos crudos | Script | Commit |
|---|---|---|---|
| Evidencias OWASP A01–A09 | `docs/mediciones/sec/*` | scripts de evidencia (`A01-*.sh`, etc.) | `34f3a6a`, `56002f3`, `9f67bfc` |
| ZAP baseline | `docs/mediciones/sec/zap/zap-baseline-2026-09-06.html`, `.md` | `scripts/zap/run-zap.sh` | `ca7f700` |

## 6. Dataset público (Zenodo) — Bloque G / K6

| Artefacto | Datos crudos | Script | Commit |
|---|---|---|---|
| ZIP del dataset (249 archivos) | `docs/mediciones/{perf,sus,lighthouse,zap,jacoco}` | `scripts/zenodo/package-dataset.py` | `d30e980` |
| Checksums SHA-256 | — | idem → `dataset/MANIFEST.csv` + `dataset/MANIFEST.sha256` | `d30e980` |
| DOI dataset | — | depósito Zenodo 10.5281/zenodo.21973297 | `b18444b` |

## 7. Convención de nombres

- Datos crudos: formato abierto (JSON / CSV), nunca editados a mano después de su captura.
- Scripts: en `scripts/`; su salida se versiona para que el informe siempre sea reproducible.
- Cada figura generada incluye el commit del script que la creó.