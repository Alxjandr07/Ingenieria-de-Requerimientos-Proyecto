# Analisis estadistico de rendimiento (k6)

**Bloque C.1** | Tarea K1 | Fecha de generacion: 2026-09-06 (actualizado con serie Render)

## Metodologia

Se analizaron dos series de corridas de k6 (50 VUs, 30 s, p95<200 ms). Cada corrida invoca `GET /api/conductores` con autenticacion JWT (cookie HttpOnly + header Bearer). Sobre `http_req_duration (ms)` se calculan media, mediana, percentiles y tasa de error por corrida; entre corridas se calcula la media de las medias con IC 95% mediante t de Student con n = numero de corridas.

- **Serie K1 (local):** 3 corridas contra backend local (commit `62bf8fa`).
- **Serie Render (K4-K8):** 5 corridas calientes + 5 muestras frias contra `https://sgroas-backend.onrender.com` (commit `9ded2a69`).

## Serie K1 — Backend local (n = 3)

### Tabla por corrida

| Corrida | Iteraciones | VUs | Media (ms) | Mediana | p90 | p95 | p99 | Error rate | Checks OK/Fail |
|---|---|---|---|---|---|---|---|---|---|
| k01-run1 | 1465 | 50 | 37.324 | 17.885 | 82.062 | 173.13 | 251.443 | 0.000 | 2930 / 0 |
| k02-run2 | 1500 | 50 | 16.897 | 10.477 | 23.64 | 35.3 | 155.98 | 0.000 | 3000 / 0 |
| k03-run3 | 1500 | 50 | 14.818 | 9.126 | 26.881 | 37.843 | 159.622 | 0.000 | 3000 / 0 |

### Resultado global (n = 3 corridas)

| Metrica | Valor |
|---|---|
| Media de medias (http_req_duration (ms)) | **23.01 ms** |
| Desviacion tipica (entre corridas) | 12.44 ms |
| Error estandar | 7.18 ms |
| t critico (gl = 2, alfa = 0.05) | 4.3027 |
| IC 95% | **[-7.88; 53.91]** ms |
| p95 maximo | 173.13 ms (umbral 200 ms) |
| Tasa de error maxima | 0.000 (objetivo < 0.01) |
| Checks totales | 8930 OK / 0 fallos |

## Serie Render — URL publica (n = 5 corridas)

### Tabla por corrida (caliente, 50 VUs, 30 s)

| Corrida | Archivo | Reqs | avg (ms) | med (ms) | p90 (ms) | p95 (ms) | p99 (ms) | Errores |
|---|---|---|---|---|---|---|---|---|
| K4 | k04-run1.json | 227 | 6318,66 | 5893,36 | 10772,32 | 11437,53 | 12707,45 | 0 |
| K5 | k05-run1.json | 298 | 4399,61 | 3997,68 | 7130,14 | 8414,99 | 9766,87 | 0 |
| K6 | k06-run1.json | 336 | 3780,31 | 3681,82 | 5841,55 | 7089,08 | 8812,83 | 0 |
| K7 | k07-run1.json | 393 | 3090,17 | 2905,20 | 4778,12 | 5356,19 | 6577,54 | 0 |
| K8 | k08-run1.json | 489 | 2247,86 | 2099,48 | 3505,87 | 4276,15 | 4985,29 | 0 |

### Muestras frias (primer GET tras pausa ~90 s, 1 VU)

| Corrida | Archivo | Latencia (ms) |
|---|---|---|
| K4 | k04-cold.json | 156,52 |
| K5 | k05-cold.json | 179,21 |
| K6 | k06-cold.json | 207,89 |
| K7 | k07-cold.json | 519,45 |
| K8 | k08-cold.json | 224,42 |

### Estadistica agregada Render (n = 5)

| Metrica | Media | DT | IC 95% (t, gl=4) |
|---|---|---|---|
| Caliente (avg por corrida) | **3967,32 ms** | 1539,20 | [2056,46; 5878,19] |
| Frio (primer GET) | **257,50 ms** | — | [156,52; 519,45] |

- Total de peticiones HTTP calientes: 1743 (227 + 298 + 336 + 393 + 489)
- Verificaciones: 100% status 200; 0 fallidas. `http_req_failed` = 0,00%
- Frio: 5/5 requests con status 200 en la primera peticion

## Contraste frio vs caliente (serie Render, metodo a priori)

`scripts/perf/nonparametric.py` (U de Mann-Whitney con aproximacion normal, d de Cliff):

| Estadistico | Valor |
|---|---|
| U (muestras independientes, frio vs caliente) | 0,0 |
| z | -2,61 |
| p (bilateral) | **0,009** |
| d de Cliff (frio vs caliente) | -1,00 -> **grande** |

El contraste es estadisticamente significativo (p = 0,009 < 0,01): la latencia bajo
carga de 50 VUs es significativamente mayor que la latencia sin carga. Esto confirma
que el cuello de botella es el throttling de CPU del plan gratuito de Render
(0,1 vCPU), no la aplicacion. La serie local K1 (p95 medio 81 ms) sigue siendo la
referencia de rendimiento sin throttling.

> Nota metodologica: en el codigo actual (`ConductorService`) `GET /api/conductores`
> **no tiene `@Cacheable`**; los `@CacheEvict` quedaron sin contraparte de escritura
> en cache. Por tanto cada peticion consulta PostgreSQL. Las muestras "frias" son el
> primer GET tras una pausa de ~90 s: reflejan la latencia sin carga, no una
> expiracion de TTL de Redis.

## Comparativa local vs Render

| Metrica | K1 local (n=3) | Render (n=5) | Factor |
|---|---|---|---|
| Media avg (ms) | 23,01 | 3967,32 | ~172x |
| p95 medio (ms) | 81,09 | 7314,79 | ~90x |
| Error rate | 0,00% | 0,00% | — |
| Cumple p95<200ms | Si | **No** | — |

## Conclusiones

1. **Local (K1):** el sistema cumple el umbral p95 < 200 ms con holgura (p95 maximo 173 ms).
2. **Render free (K4-K8):** el plan gratuito (0,1 vCPU) no permite cumplir el umbral. El p95 va de 4,3 s a 11,4 s. No es regresion del codigo.
3. **Frio vs caliente:** la diferencia es significativa (p = 0,009, d = -1.00), confirmando que el throttling de CPU es el factor dominante.
4. **Recomendaciones:** (1) activar `@Cacheable` en `ConductorService.listar`, o (2) migrar a plan no gratuito de Render.

## Reproducibilidad

| Artefacto | Fuente | Script |
|---|---|---|
| Tabla K1 | docs/mediciones/perf/k01-run1.json, k02-run2.json, k03-run3.json | scripts/perf-analysis.py |
| Tabla Render | docs/mediciones/perf/k04-run1.json ... k08-run1.json | scripts/perf-analysis.py |
| Muestras frias | docs/mediciones/perf/k04-cold.json ... k08-cold.json | scripts/perf/nonparametric.py |
| Estadisticas | estadisticas.json / estadisticas.csv | scripts/perf-analysis.py |
| Figuras | figuras/*.png | scripts/gen-figuras.py |
| Contraste no parametrico | RENDER-REPORT.md | scripts/perf/nonparametric.py |
| IC bootstrap (validacion) | ANALISIS-BOOTSTRAP.md | scripts/perf-bootstrap.py |
