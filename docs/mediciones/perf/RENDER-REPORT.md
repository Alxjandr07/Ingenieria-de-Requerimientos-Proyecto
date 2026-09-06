# RENDER — Rendimiento de GET /api/conductores en el backend desplegado

## Metadatos de la corrida

| Campo | Valor |
|---|---|
| **Fecha** | 2026-09-06 |
| **Herramienta** | k6 v0.57.0 (`k6/script.js`, `k6/cold.js`) |
| **Configuracion** | 50 VUs, duracion 30 s (`k6/opts.js`), ramp-up implicito de la carga |
| **Endpoint** | `GET /api/conductores` (protegido con JWT) |
| **Destino** | `https://sgroas-backend.onrender.com` (Render free: 0,1 vCPU, sin solicitudes de carga constante) |
| **Archivos crudos** | `k04-run1.json` ... `k08-run1.json` (caliente) y `k04-cold.json` ... `k08-cold.json` (frio) |

> **Nota metodologica:** en el codigo actual (`ConductorService`) `GET /api/conductores` **no tiene
> `@Cacheable`**; los `@CacheEvict(value = "conductores")` de crear/actualizar/desactivar quedaron
> sin contraparte de escritura en cache. Por tanto cada peticion consulta PostgreSQL. Las muestras
> "frias" son el primer GET tras una pausa de ~90 s (1 VU, 1 iteracion): reflejan la latencia sin
> carga, no una expiracion de TTL de Redis.

## Resultados caliente (tiempo de respuesta en ms, por corrida)

| Corrida | Archivo | Reqs | avg | med | p90 | p95 | p99 | Errores |
|---|---|---|---|---|---|---|---|---|
| 1 | `k04-run1.json` | 227 | 6318,66 | 5893,36 | 10772,32 | 11437,53 | 12707,45 | 0 |
| 2 | `k05-run1.json` | 298 | 4399,61 | 3997,68 | 7130,14 | 8414,99 | 9766,87 | 0 |
| 3 | `k06-run1.json` | 336 | 3780,31 | 3681,82 | 5841,55 | 7089,08 | 8812,83 | 0 |
| 4 | `k07-run1.json` | 393 | 3090,17 | 2905,20 | 4778,12 | 5356,19 | 6577,54 | 0 |
| 5 | `k08-run1.json` | 489 | 2247,86 | 2099,48 | 3505,87 | 4276,15 | 4985,29 | 0 |

## Resultados frio (primer GET tras pausa, 1 VU)

| Corrida | Archivo | duracion (ms) |
|---|---|---|
| 1 | `k04-cold.json` | 156,52 |
| 2 | `k05-cold.json` | 179,21 |
| 3 | `k06-cold.json` | 207,89 |
| 4 | `k07-cold.json` | 519,45 |
| 5 | `k08-cold.json` | 224,42 |

## Estadistica agregada (muestras por corrida, n = 5)

| Metrica | Media | DT | IC 95 % (t, gl=4) |
|---|---|---|---|
| Caliente (avg por corrida) | 3967,32 ms | 1539,20 | [2056,46; 5878,19] |
| Frio (primer GET) | 257,50 ms | — | [156,52; 519,45] |

- **Total de peticiones HTTP calientes:** 1743 (227 + 298 + 336 + 393 + 489)
- **Verificaciones:** 100 % de `status es 200`; 0 fallidas. `http_req_failed` = 0,00 %
- **Frio:** 5/5 requests con status 200 en la primera peticion

## Contraste no parametrico (metodo de la guia, Bloque C)

`scripts/perf/nonparametric.py` (U de Mann-Whitney con aproximacion normal, d de Cliff):

| Estadistico | Valor |
|---|---|
| U (muestras independientes, frio vs caliente) | 0,0 |
| z | -2,61 |
| p (bilateral) | **0,009** |
| d de Cliff (frio vs caliente) | -1,00 -> **grande** |

> La implementacion de `nonparametric.py` tenia un bug de desempaquetado en `mann_whitney_u`
> (devolvia U negativa); corregido y verificado contra un calculo manual de rangos.

## Lectura

- El backend en Render free **no cumple** el umbral declarado `p95 < 200 ms`: el p95 caliente va de
  4,3 s a 11,4 s. No es una regresion del codigo: la serial de referencia K1 (local, 2026-07-29,
  commit `62bf8fa`) cumplia con p95 medio de 81 ms. La diferencia de orden de magnitud corresponde
  al throttling de CPU (0,1 vCPU) del plan gratuito y al almacenamiento local de Render.
- El primer request tras pausa (frio, sin carga) responde en ~257 ms promedio; la comparacion
  no parametrica es significativa (p = 0,009) pero debe leerse como **latencia sin carga vs latencia
  bajo 50 VUs**, no como efecto del cache (inexistente en este endpoint).
- **Recomendaciones:** (1) para cumplir el umbral desplegado, activar el cache de aplicacion en
  `ConductorService.listar` (wrapper `@Cacheable` como ya existe en `incidentes`, `rutas`,
  `asignaciones` y `vehiculos`), evaluando `CacheEvict` existente; y/o (2) plan no-gratuito en Render.
  La serie local K1 sigue siendo la referencia de rendimiento de la aplicacion sin throttling.