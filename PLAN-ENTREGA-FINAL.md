# PLAN DE TRABAJO — ENTREGA FINAL SGROAS v1.0.0
**Cierre: lunes 17 de agosto de 2026 · Docente: Dr. Gleiston Cicerón Guerrero Ulloa, Ph.D.**
**Bot del plan: `PLAN-ENTREGA-FINAL.md` (commitearlo junto con el primer avance de hoy)**

---

## 0. DIAGNÓSTICO REAL DEL REPO (inventario del 16-ago-2026)

### 0.1 Lo que YA existe (no rehacer, verificar/mejorar)
| Artefacto | Ruta | Estado |
|---|---|---|
| Backend Spring Boot 3.5.15 / Java 21 / jjwt 0.12.6 / springdoc 2.8.6 | `src/` + `pom.xml` | Funcional: 6 controladores, 9 servicios, 6 entidades, 6 repos, auth JWT cookie |
| 7 SPs/funciones SQL (5 sp_ + 2 fn_) | `db/procs/` | Existen, NO invocados desde Java (falta `@Procedure`) |
| Catálogo de SPs | `docs/basedatos/CATALOGO-SP.md` | Existe |
| Migraciones Flyway | `src/main/resources/db/migration/V1..V4` | Existen |
| k6 script + opts (50 VUs/30s, p95<200ms) | `k6/` | Existen |
| 3 corridas k6 archivadas | `docs/mediciones/perf/k0{1,2,3}.json` | Existen (run1: 0% error, 2930 checks OK) |
| Evidencia OWASP 6 controles | `docs/mediciones/sec/` | Existe (A01, A02, A03, A05, A07, A09) |
| Reporte JaCoCo (HTML+CSV+XML) | `docs/mediciones/jacoco/` | Existe pero **14.69% líneas / 10.53% ramas** (objetivo 70%) |
| Matriz de trazabilidad, 20 REQ implementados | `docs/trazabilidad/matriz.csv` | Existe (**falta columna `tipo_acceso`**) |
| 6 ADRs formato Nygard | `docs/adr/adr-001..adr-006` | **adr-006 es "api-rest-dtos", NO "acceso a datos CRUD/SP"** — rehacer; falta adr-007 |
| 3 DSL Structurizr C4 L1-L3 (sin PNG) | `docs/arquitectura/` | Existen |
| CHANGELOG.md, CITATION.cff (**DOI real 10.5281/zenodo.21698129**), CONTRIBUTORS.md, LICENSE MIT, VERSIONING.md, .env.example | raíz | Existen |
| Colección Postman 20 peticiones | `docs/postman/coleccion.json` | Existe (objetivo: >= 25) |
| Frontend **Angular 20 REAL (login + interceptor cookie)** | rama `feature/frontend-maria` (3 commits) | **NO mergeado a main — MERGEAR URGENTE (tarea A0)** |
| ETHICS.md + plantilla consentimiento | `docs/etica/` | Existen |
| DATA-DICTIONARY.md | `docs/mediciones/` | Existe |
| CHANGELOG-REQ.md | `docs/requisitos/` | Existe |
| CI GitHub Actions | `.github/workflows/ci.yml` | Existe (probablemente ROJO hoy: umbral JaCoCo 20% > 14.69%) |

### 0.2 Lo que FALTA (todo lo demás — priorizado en partes 1-3)
`OBSERVACIONES.md` vacío · SRS (no existe en ningún formato) · informe académico LaTeX (no existe) · `make all` (no existe en Makefile) · frontend en main · `@Procedure` en Java · cobertura 70% · lighthouse (carpeta vacía) · ZAP (nada) · despliegue público (nada) · DEPLOYMENT/RUNBOOK/BACKUP.md · ADR-006/acceso datos + ADR-007 · spotbugs/find-sec-bugs · `scripts/audit-sql-dynamic.sh` y `validate-traceability.sh` · historias/ · casos-de-uso/ · elicitacion/ · docs/checklists/ · docs/entorno/versions.txt · DATA-PROVENANCE.md · SUS (carpeta vacía) · ORCID reales (1 placeholder falso) · tag v1.0.0 · DOI dataset Zenodo separado · notebooks ejecutados · PNGs C4 · video · slides.

### 0.3 Herramientas en la PC de Alejandro
Docker 29.5.3 ✔ · k6 0.57 ✔ · Node 24 + npm 11 ✔ · Python 3.14 ✔ · JDK 21 ✔ · git 2.54 ✔ · **pdflatex/tectonic NO instalados** → compilar el informe en **Overleaf** (recomendado) o instalar MiKTeX.

---

## 1. ESTRATEGIA: PRIORIZAR POR PESO DE RÚBRICA

Tiempo real disponible: ~36 horas (16-17 ago). Orden de prioridad (peso):

| # | Criterio | Peso | Quién | Cómo se gana |
|---|---|---|---|---|
| 1 | **R1** reproducción `make all` | 8% | Alejandro | Makefile con target `all` + prueba desde clon limpio |
| 2 | **D0R** SRS + ingeniería de requisitos | 8% | María | SRS-v1.0.0.tex ISO 29148 + **firma docente** + historias/casos de uso |
| 3 | **P1** producto (SPs @Procedure, SQL estático, CI verde) | 7% | Alejandro | `@Procedure` en 7 repos, script audit SQL, 3 corridas CI verdes |
| 4 | **P3** cobertura 70% | 7% | Alejandro | Batería MockMvc + unitarios (14.69% → 70%) |
| 5 | **D3** resultados/evaluación (datos crudos + estadística) | 7% | Kevin | Análisis k6/SUS/lighthouse/ZAP con IC 95% |
| 6 | **P0** observaciones ≥70% cerradas | 5% | Alejandro | OBSERVACIONES.md completo, cada OBS→commit |
| 7 | **P5** despliegue público HTTPS | 5% | Alejandro | Railway/Render/Fly + health UP + runbook |
| 8 | **D1/D2/D4/D5/D6** documento | 19% | María+Kevin | Informe LaTeX 35-60 pág con Amenazas a la validez y refs reales |
| 9 | **P2/P4 + R2/R3/R4** | 20% | todos | Lighthouse, ZAP, DOI, PAQUETE FAIR (si queda tiempo) |

**Decisión estratégica:** sin `make all` → R1=0; sin SRS firmado → D0R máx 50%; con SQL concatenado → P1=0 y P3 insuficiente. **Esas 3 cosas son innegociables y se hacen HOY en paralelo.**

---

## 2. REGLAS DE ORO TRANSVERSALES (leer TODO el equipo antes de empezar)

1. **CERO SQL dinámico/concatenado** en Java: prohibido `createNativeQuery(... + ...)`, `EXECUTE IMMEDIATE`, `sp_executesql`. Solo `@Procedure` / `@NamedStoredProcedureQuery` / `@Query` con constantes / repositorios Spring Data. Violación = P1 0% automático.
2. **`make all` debe funcionar desde clonación limpia** → probarlo HOY en `C:\Users\alxja\AppData\Local\Temp\opencode\sgroas-test` (git clone + make all + código 0).
3. **SRS con firma del docente**: pedir firma HOY mismo (foto/escaneo/electrónica) — correo a gguerrero@uteq.edu.ec. Sin firma, D0R máx 50%.
4. **URL pública** levantada HOY y viva toda la semana + 30 días; certificado válido (sin advertencias).
5. **CI verde**: 3 corridas consecutivas exitosas ANTES del cierre; última semana sin rojas.
6. **Referencias reales**: cada ref. verificable (DOI/URL); fabricar = -25% en D6 por instancia.
7. **Tag v1.0.0** = commit final de la portada; conservar v0.7.1 y v0.9.0-rc intactos. Commits posteriores al corte de portada se ignoran (no penaliza, pero la portada debe tener el hash exacto del tag).
8. **Observaciones ≥70% cerradas** → OBSERVACIONES.md con OBS-XX, fuente (1A/1B/3), criterio, texto, decisión, commit.
9. Cada avance = **commit + push** el mismo día, mensaje descriptivo referenciando `OBS-XX`/bloque.
10. ORCID reales de los 3 (orcid.org, tarea K7) — hoy mismo, es gratis y toma 5 min.

---

## 3. PARTE 1 — ALEJANDRO (backend, DevOps, CI, despliegue, reproducibilidad)

**Eje: Bloques 0, A.1 (parcial), A.2, A.4, D + cierre (tag/Zenodo/GHCR).**

### A0. URGENTE — Merge del frontend de María (10 min)
```powershell
git checkout main; git pull
git merge origin/feature/frontend-maria --no-ff -m "feat(frontend): integra Angular 20 (login+interceptor) de María en main"
git push
```
Verificar que exista `frontend/angular.json` en main. El README debe reflejar el frontend real (URL pública /api y /app).

### A1. BLOQUE 0 — OBSERVACIONES.md completo (P0, 5%) — HOY
1. Recuperar los **reportes/retroalimentación de Entregas 1A, 1B y 3** (SGA, comentarios de GitHub del docente, correos). Si no se encuentran, reconstruir la lista desde los commits: cada corrección hecha en v0.7.x/v0.9.x (auth JWT, códigos de error, Docker digests, k6 seed, CI, documentos) es en sí una observación resuelta con su commit real.
2. Escribir `docs/observaciones/OBSERVACIONES.md` con TODAS las OBS-XX: columna | OBS-XX | fuente (1A/1B/3) | criterio rubrica | texto íntegro | decisión | commit(s) hash corto |.
3. Cada OBS con commit = **cerrada**. Meta: >= 70% cerradas (ideal 100%). Anexo A del informe usa esta tabla (María la cita).
4. Commit: `docs(obs): registra N observaciones 1A/1B/3 cerradas con commits (P0)`.

### A2. Acceso híbrido a datos — @Procedure (P1, 7%) — HOY
1. Anotar `@NamedStoredProcedureQuery` en las entidades y métodos `@Procedure` en los repositorios para **los 7 SPs/funciones de `db/procs/`** (mínimo 6):
   - `sp_incidentes_por_gravedad` → `IncidenteRepository`
   - `sp_obtener_incidentes_por_rango` → `IncidenteRepository`
   - `sp_asignaciones_activas_por_conductor` → `AsignacionRutaRepository`
   - `sp_vehiculos_en_mantenimiento` → `VehiculoRepository`
   - `sp_reporte_rendimiento_rutas` → `RutaRepository`
   - `fn_licencias_por_vencer` → `ConductorRepository`
   - `fn_estadisticas_generales` → `IncidenteRepository` (o repositorio nuevo `DashboardRepository`)
2. Exponer 1-2 endpoints de prueba (p. ej. `GET /api/reportes/rendimiento-rutas`) que invoquen los SPs vía `@Procedure` y test de integración que lo verifique.
3. **NUNCA** `createNativeQuery` con concatenación.
4. Commit: `feat(db): invoca 7 SPs via @Procedure/@NamedStoredProcedureQuery (OBS-XX, P1)`.

### A2bis. Auditoría SQL estática (script + CI, P1/P3)
1. Crear `scripts/audit-sql-dynamic.sh`: grep en `db/procs/*.sql` y `src/main/java` de `EXECUTE IMMEDIATE|sp_executesql|createNativeQuery\s*\([^)]*\+` → exit 1 con listado. (Funciona en Git Bash; para CI usar sh.)
2. Crear `scripts/validate-traceability.sh`: valida que `matriz.csv` tenga las columnas requeridas (REQ_ID, estado, tipo_acceso, test de verificación) y que `docs/trazabilidad/` exista.
3. `pom.xml`: añadir **spotbugs-maven-plugin + find-sec-bugs** con regla `SQL_NONCONSTANT_STRING_PASSED_TO_EXECUTE` (fail on violation). Guardar reporte en `docs/mediciones/sec/static-analysis/`.
4. Completar Makefile:
```makefile
all: up test bench audit jacoco docs
```
con `audit: ./scripts/audit-sql-dynamic.sh && ./scripts/validate-traceability.sh` (corrige la ruta rota actual) y `docs: python scripts/gen-versions.py > docs/entorno/versions.txt`.
5. Commit: `ci(sec): agrega spotbugs/find-sec-bugs, audit-sql-dynamic.sh y make all (R1, P1)`.

### A3. Cobertura JaCoCo 14.69% → 70% (P3, 7%) — HOY (tarea más pesada)
Estrategia (60-80 tests nuevos):
- **Integración MockMvc** (`@SpringBootTest` + `MockMvc`): 1 clase por controlador (6) cubriendo éxito + 401/403/404/422. Cubre controladores + servicios + filtros JWT.
- **Unitarios de servicios** (ya hay 2; completar los 9): AuthService, ConductorService, VehiculoService, RutaService, IncidenteService, AsignacionRutaService, TokenService, JwtService.
- **Domain/entidades**: tests de enums y validaciones.
- Subir umbral en pom a `LINE>=0.70, BRANCH>=0.70` **solo si el reporte lo verifica**; si queda en 60-69, subir al valor real y documentar desviación en el informe (Kevin). El reporte HTML+XML con fecha ISO 8601 se copia a `docs/mediciones/jacoco/2026-08-17/`.
- Comando: `./mvnw clean verify` local, luego en CI.
- Commit: `test: sube cobertura JaCoCo a X% lines/Y% branches (P3)`.

### A4. CI 3 corridas verdes (P1) — HOY tarde
1. Arreglar `ci.yml`: umbral JaCoCo coherente, servicios Postgres/Redis (ya existen), subir artefactos; añadir job **spotbugs** (A2bis) y opcional **LHCI + ZAP** (depende de despliegue, A5).
2. `git push` hasta lograr **3 corridas exitosas consecutivas** (disparar con pushes menores si hace falta). Capturar pantallazos para anexo del informe (Kevin).
3. Badge de CI ya está en README; verificar que apunte a la rama main.

### A5. Despliegue público HTTPS (P5, 5%) — HOY tarde
1. Subir repo a **Railway** (recomendado: `npx @railway/cli` con postgres/redis/backend) **o** Render: `render.yaml` con servicio web (backend) + PostgreSQL + Redis. Sin costo: free tier con sleep (despertar antes de la defensa).
2. HTTPS automático (Railway/Render dan cert válido). Comprobar `https://<url>/actuator/health` → `{"status":"UP"}` con componentes **db, redis** UP.
3. Desplegar también el **frontend Angular** (Railway static / Render static): login real contra la API. Registros en `.env.example` (sin valores sensibles).
4. Documentación: `docs/despliegue/DEPLOYMENT.md` (proveedor, topología, variables, pasos de reproducción), `RUNBOOK.md` (arranque/apagado, rotación de secretos JWT/BD, rotación de contenedores, restauración), `BACKUP.md` (frecuencia diaria, retención 30 días, prueba de restauración documentada). `docker-compose.yml` con digests sha256 ya tienen.
5. **ADR-007** despliegue (plantilla Nygard) + corregir numeración: reescribir `docs/adr/adr-006-api-rest-dtos.md` → renombrar a `adr-005b-api-rest-dtos.md` y crear `adr-006-acceso-datos-sp.md` + `adr-007-despliegue.md` (ver qué ocupa adr-005 antes de renombrar).
6. Usuario demo: `admin@sgroas.com / admin123` (ya en seed) y publicar credenciales demo en README.
7. Commit: `feat(deploy): despliega en <proveedor>, health UP, DEPLOYMENT/RUNBOOK/BACKUP + adr-006/007 (P5)`.

### A6. Imagen GHCR + CI/CD despliegue (opcional si sobra tiempo, R2/R3) ✔ HECHO (06/09/2026)
```powershell
docker build -t ghcr.io/alxjandr07/sgroas:v1.0.0 .
docker push ghcr.io/alxjandr07/sgroas:v1.0.0
docker inspect --format='{{index .RepoDigests 0}}' ghcr.io/alxjandr07/sgroas:v1.0.0
```
- Imagen publicada: `ghcr.io/alxjandr07/sgroas:v1.0.0` vía workflow `.github/workflows/release-docker.yml` (CI: run 34055975557 success).
- Digest (manifest list amd64): `sha256:ea284abed7f6dcb16ef6859e8e5a57cdc1958ed30336e31f04a966a379b18f92`.
- Digest pegado en README (sección "Imagen Docker"). Falta verificar visibilidad pública de la imagen en https://github.com/users/Alxjandr07/packages (por defecto privada; requiere PAT con `write:packages` o UI web).

### A7. `make all` desde clonación limpia (R1, 8%) ✔ HECHO (06/09/2026)
1. Ejecutado en `C:\Users\alxja\AppData\Local\Temp\opencode\sgroas-a7` (clon de `main` @ 6097476) con `make all SHELL=/usr/bin/bash` bajo **JDK 21** (JAVA_HOME Adoptium; el sistema tenía JDK 26 que rompe SpotBugs 4.8.6 con "class file major version 70").
```powershell
git clone https://github.com/Alxjandr07/SGROAS-ProyectoAppWeb.git sgroas-test
cd sgroas-test; make all; echo $LASTEXITCODE   # debe ser 0
```
2. **Resultado: exit 0 — "PIPELINE COMPLETO (make all) FINALIZADO OK"** con 222 tests, 0 fallos; k6 3 corridas locales (`-e BASE_URL=http://localhost:8080`); audit OK; JaCoCo report; `versions.txt` regenerado (2026-09-06T15:33:30); PDF `docs/informe-final/main.pdf` generado (MiKTeX 25.12).
3. Cambios derivados: `k6/script.js` y `k6/cold.js` usan `__ENV.BASE_URL` (default Render para series K4..K8; `make bench` fija localhost) — Makefile `bench` actualizado.
4. Notebooks ejecutados visibles en `scripts/*.ipynb` (los hace Kevin con datos de A5).

### A8. CIERRE (DOMINGO NOCHE / LUNES MAÑANA, ver sección 7) ✔ PARCIALMENTE HECHO (06/09/2026)
Tag v1.0.0 + GitHub Release + Zenodo release v1.0.0 (DOI software actualizado: v1.0.0 = **10.5281/zenodo.22522109**; el depósito de v0.9.0-rc es 10.5281/zenodo.21698129) + portada con hash real (Commit: `9ded2a69`) + video `make all` (con Kevin).
- Pendiente con compañeros: portada/informe PDF con el hash final, referencias DOI en el PDF, video.

**Entregables de Alejandro:** OBSERVACIONES.md completo, SPs vía @Procedure + endpoints, scripts de auditoría, pytest/MockMvc con cobertura >=70%, CI 3 verdes, despliegue público + 3 docs de despliegue, ADR-006/007, Makefile `all`, tag v1.0.0, GHCR, Zenodo software, video.

---

## 4. PARTE 2 — MARÍA (requisitos + documento académico núcleo)

**Eje: Bloques A.3, B.1-B.6bis (Cap. 1, 2, 4), portada/informes + frontend.**

### M1. SRS v1.0.0 con firma (D0R, 8%) — URGENTE HOY
1. Buscar si existió SRS anterior (preguntar a compañeros/correos; el CHANGELOG lo menciona pero no está en el repo) → si existe, migrar a `docs/requisitos/historico/`.
2. Crear `docs/requisitos/SRS-v1.0.0.tex` conforme **ISO/IEC/IEEE 29148:2018**: alcance, stakeholders, 20 REQ de `matriz.csv` en notación MoSCoW (Must: los 20 son "Implementado"), cada uno con ID/C-N identificable.
3. Compilar a PDF (Overleaf o MiKTeX) y conseguir **firma del docente HOY** (correo con PDF + espacio de firma; aceptar foto/electrónica). Guardar en `docs/requisitos/SRS-v1.0.0.pdf` + `historico/` versión anterior si aplica.
4. Commit: `docs(req): SRS v1.0.0 ISO 29148 firmado por director (D0R)`.

### M2. Ingeniería de requisitos completa (D0R)
1. `docs/requisitos/historias/` — 8 historias mínimo formato **Connextra** (`Como <rol>, quiero <acción> para <valor>`), con criterios **INVEST** y escenarios **Gherkin** (`Feature/Scenario/Given/When/Then`), trazadas a las REQ de la matriz.
2. `docs/requisitos/casos-de-uso/` — 4-6 casos de uso plantilla **Cockburn** niveles 1-4 (login, gestión conductores, asignación rutas, registro incidentes, reportes...), trazados a endpoints + tests de integración.
3. `docs/requisitos/elicitacion/` — evidencia: actas de reuniones/sesiones con la cooperativa, encuesta, entrevista (aunque sea 1 documento con fecha y participantes).
4. `docs/checklists/incose2023-req.md` — checklist **C1-C9** individuales y **C10-C15** de conjunto, 1 fila por REQ.
5. Actualizar `CHANGELOG-REQ.md`: total, tipos, % verificado, tasa de estabilidad.
6. `matriz.csv`: añadir columna **`tipo_acceso`** = `CRUD-ORM` o `SP` por requisito (los reportes/estadísticas → SP; el resto → CRUD-ORM) + columna de verificación.
7. Commit: `docs(req): historias Connextra+INVEST+Gherkin, casos de uso Cockburn, checklist INCOSE, matriz con tipo_acceso (D0R)`.

### M3. Informe académico — estructura (B, 19%) — HOY noche
1. Crear `docs/informe-final/` con: `main.tex`, `refs.bib` (se llena con Kevin), `capitulos/cap1-introduccion.tex` ... `cap12-conclusiones.tex`, `portada.tex`.
2. **Compilar en Overleaf** (no hay LaTeX local): pin documentclass `article`/`report` 11pt, spanish, gráficos con datos de `docs/mediciones/`. Anexar PDF resultante en `docs/informe-final.pdf`.
3. Portada (B.1): título, integrantes + afiliación UTEQ, **ORCID reales de los 3** (los consigue Kevin con A8), docente-director, fecha 17-ago-2026, **tag v1.0.0 + hash** (rellenar al final con A8), **DOI software** 10.5281/zenodo.21698129.
4. Resumen estructurado ES+EN 200-250 palabras c/u (Contexto/Objetivo/Métodos/Resultados/Conclusiones) + 5-8 palabras clave con >=3 del ACM CCS 2012 o IEEE Thesaurus. Índices general/de figuras/tablas/listados + lista de siglas.
5. Redactar: **Cap.1 Introducción** (contexto cuantificado, RxQ1-RQ4, objetivo general +_3-5 específicos, contribuciones numeradas), **Cap.2 Marco teórico** (ISO 29148, INCOSE v4, C4, ISO 25010, REST, JWT RFC 7519, OWASP Top 10, patrones de acceso a datos), **Cap.4 Ingeniería de requisitos** (stakeholders, elicitación con evidencia, MoSCoW con sintaxis 29148, validación, gestión de cambios, métricas). + **B.15 declaraciones** + **Anexo A** (tabla obs con % resuelto, usa A1) y Anexo C (capturas CI, de Kevin).
6. Extensión objetivo: ~25-30 págs propias; en total 35-60 sumando Cap.3 (Kevin/María), Cap.5-7 (María+Alejandro), Cap.8-12 (Kevin).

### M4. Frontend (si queda tiempo, P2)
- Verificar build: `cd frontend; npm install; ng build` (Angular 20, ya tiene login funcional). Añadir vistas de listado (conductores/vehículos) consumiendo la API pública de A5 con cookie HttpOnly. Desplegar estático (A5.3).

**Entregables de María:** SRS-v1.0.0.pdf firmado, historias Gherkin, casos de uso Cockburn, elicitación, INCOSE, CHANGELOG-REQ, matriz v2, `docs/informe-final/main.tex` + cap. 1/2/4/declaraciones + portada, PDF del informe compilado.

---

## 5. PARTE 3 — KEVIN (evidencia empírica, estadística, datos, ética, checklists)

**Eje: Bloques C, E, F, G + capítulos 8-12 + refs + SUS + paquete Zenodo dataset.**

### K1. Estadística y scripts de análisis (C) — HOY
1. `scripts/perf-analysis.py` (o notebook `perf-analysis.ipynb` ejecutado): lee `docs/mediciones/perf/k0{1,2,3}.json`, calcula de `http_req_duration`: **media, DT, IC 95%**, p95, error rate por corrida; contraste **cache caliente vs frío** con **Wilcoxon/Mann-Whitney + Cliff delta** (los datos k6 de 50 VUs con warmup permiten discriminar). Si no hay 2 condiciones reales, documentar el plan del análisis a priori y el resultado descriptivo.
2. `scripts/sus-analysis.py`: scoring de Brooke por participante (10 SUS), media/DT/IC95, nivel F (>=70 aceptable), gráfica barras con **paleta Okabe-Ito/viridis** (`usuario <-> SUS`).
3. `scripts/gen-figuras.py`: gráficas reproducibles (lighthouse por perfil, jacoco por paquete, k6 percentiles) — **ningún número/gráfico manual**; cada figura con caption que referencia script+commit.
4. Guardar análisis y figuras en `docs/mediciones/` + salidas ejecutadas de notebooks en `scripts/`.
5. Commit: `docs(analisis): estadistica k6/sus con IC 95% y scripts reproducibles (C, R1)`.

### K2. Lighthouse y ZAP (P2/P4) — depende de A5 (URL pública)
```powershell
npx lighthouse https://<URL> --preset=mobile --output=json --output=html --output-path=docs/mediciones/lighthouse/mobile-1
# repetir 2x mobile y 3x desktop --preset=desktop
docker run --rm ghcr.io/zaproxy/zaproxy zap-baseline.py -t https://<URL> -r docs/mediciones/sec/zap/zap-baseline-2026-08-17.html
```
Umbrales a reportar: Performance >=80, Accessibility >=90, Best Practices >=90, SEO >=90. Guardar reportes + summary en markdown `docs/mediciones/lighthouse/RESUMEN.md` y `docs/mediciones/sec/zap/RESUMEN.md`.

### K3. SUS con 10 participantes + ética (P2/D2?/G) — HOY noche
1. Encuesta en línea (Google Forms con los **10 ítems del SUS de Brooke**, escala 1-5) a compañeros/docente: 10 respuestas hoy (equipo+pares; códigos **P01-P10**, sin nombres en datos crudos).
2. Consentimiento informado: usar `docs/etica/consentimientos/plantilla.md`, firmados **fuera del repo público** (carpeta local/correo); en `docs/etica/ETHICS.md` declarar ubicación y códigos. Completar `ai-disclosure.md` (uso de IA generativa: fase, propósito, revisión por el equipo).
3. Resultados en `docs/mediciones/sus/sus-P01..P10.json` + análisis K1.

### K4. Bloques E y F — checklists y paquete de datos — HOY noche
1. `docs/checklists/ralph2021-benchmark.md` + `ralph2021-empirical.md` (según tipo de estudio) + `docs/checklists/prisma2020.md` + `docs/checklists/fair.md` — checklist completados.
2. `docs/mediciones/DATA-PROVENANCE.md`: por cada tabla/figura del informe → archivo crudo + script + **commit hash** que la generó.
3. Verificar/completar `DATA-DICTIONARY.md` (todas las variables de k6/SUS/lighthouse).
4. `docs/entorno/versions.txt` lo genera el `make docs` de Alejandro (A2bis/A7); comentarlo en DATA-PROVENANCE.

### K5. Capítulos 8-12 del informe + refs.bib (D3/D4/D5/D6) — hoy noche/lunes
1. **Cap.8 Evaluación empírica**: por bloque (rendimiento, seguridad, usabilidad, cobertura, calidad web) con RQ asociada, métrica, datos crudos, descriptiva + IC 95%.
2. **Cap.9 Discusión** (respuesta a cada RQ, comparación con trabajos relacionados), **Cap.10 Amenazas a la validez OBLIGATORIO** (constructo, interna, externa, conclusión — con mitigación cada una; D5=0% si falta), **Cap.11 Trabajo futuro**, **Cap.12 Conclusiones**.
3. **refs.bib**: >=30 referencias **distintas y verificadas**, >=20 Q1/Q2 (IEICE? no: ACM/IEEE: ICSE, FSE, ASE, MSR, EASE, ESEM, TSE, TOSEM...) — verificar cada DOI con una búsqueda; estilo **IEEE** unificado. Cap.3 Trabajos relacionados (SLR estilo Kitchenham/Charters + PRISMA 2020) puede tomar K5 si hay tiempo (o María si sobra).
4. Anexos: cadena de búsqueda, protocolo SUS, capturas CI (3 verdes, de A4), checklist Ralph et al.
5. Commit: `docs(informe): caps 8-12, amenazas a la validez, refs.bib con DOIs verificados (D3-D6)`.

### K6. CITATION.cff + DOI dataset (R3/R4) — lunes mañana
1. Los 3 se registran en **orcid.org** (hoy, 5 min) → ORCID reales en `CITATION.cff` (v1.0.0, `date-released 2026-08-17`, DOI software real).
2. Crear dataset zip de `docs/mediciones/` (crudos: perf json, sus json, lighthouse, zap, jacoco xml) → **subir a Zenodo como depósito separado** → DOI dataset + licencia **CC BY 4.0** → incluir en README y CITATION.cff.
3. Commit: `docs(zenodo): DOI dataset 10.5281/zenodo.XXXXX, ORCID reales, CITATION.cff v1.0.0 (R3/R4)`.

### K7. Video `make all` (R1) — coproducción con Alejandro
Grabar 5-7 min (OBS Studio/celular): clon limpio → `make all` → código 0 → recorrido rápido de reportes. Subir a YouTube (no listado) y enlazar en README.

**Entregables de Kevin:** análisis estadístico con scripts, RESÚMENES lighthouse/ZAP, SUS 10 participantes, checklists completos, DATA-PROVENANCE, capítulos 8-12, refs.bib verificadas, CITATION.cff v1.0.0, DOI dataset, video.

---

## 6. DEPENDENCIAS ENTRE PARTES

| Dependencia | De | A | Qué necesita |
|---|---|---|---|
| URL pública estable | **A5 (Alejandro)** | K2 (lighthouse/zap), M4 (frontend) | URL + credenciales demo para automatizar |
| OBSERVACIONES.md (textos OBS) | **A1 (Alejandro)** | M1/M3 anexo A | Mismo día (A1 antes de que María llene el anexo) |
| Cobertura final | **A3 (Alejandro)** | K5 Cap.8, Anexo C | Número final + capturas CI |
| URL + datos análisis | A5/A4 | K1/K5 | JSON k6 ya existen; lighthouse/zap necesitan URL |
| ORCID de los 3 | K6 + todos | Portada (M3), CITATION.cff | Registro HOY (los 3) |
| Tag v1.0.0 + hash + DOI | **A8 (Alejandro)** | Portada (M3) | Rellenar portada con el hash final ANTES del último push |
| `make all` final 0 | A7 + todos los scripts | R1, video (K7) | Última verificación lunes mañana |
| PDF informe | M3 (María) + K5 + aportes A | `make docs` (A7) | Compilar lunes; última versión antes del tag |

**Orden lógico:** HOY: A0+A1+A2+A3 (Ale) ∥ M1+M2 (María) ∥ K1+K3 (Kevin) → NOCHER: A4+A5, M3 bosquejo, K4/K5 → LUNES MAÑANA: A7 prueba limpia, K2 con URL, portada+tag (A8+M3), video, push final.

---

## 7. RIEGOS TRANSVERSALES (checklist de no-desastre, revisar a las 22:00 y 07:00)

- [ ] `make all` = 0 desde clon limpio (R1) — probar ANTES del lunes
- [ ] Ningún `createNativeQuery`/concatenación/EXECUTE IMMEDIATE en el repo (grep final) — P1
- [ ] SRS firmado por el docente (D0R) — correo enviado HOY
- [ ] URL pública UP + cert válido + `/actuator/health` UP con db/redis (P5) — probar desde otro dispositivo
- [ ] CI: 3 corridas verdes consecutivas, sin rojas 7 días previos (P1)
- [ ] Observaciones >=70% cerradas con commits (P0)
- [ ] Referencias todas verificables (D6)
- [ ] Amenazas a la validez en el informe (D5)
- [ ] Tags v0.7.1 y v0.9.0-rc intactos; tag v1.0.0 al final (P1-P4)
- [ ] **Frontend en main** (A0) — ¡no olvidar!
- [ ] Cobertura >=70% reportada con fecha ISO (P3); si no llega, documentar
- [ ] DOI software resolviendo al tag v1.0.0 (R3)

---

## 8. ORDEN EXACTO DE CIERRE (lunes 17, ~09:00-11:00)

```powershell
# 1. Todo mergeado y verde en main
git checkout main; git pull
# 2. Última prueba R1
#    (en sgroas-test) make all  → código 0
# 3. Portada con el hash REAL: obtener hash del commit final y editar portada (María)
git log --oneline -1
# 4. Tag final
git tag -a v1.0.0 -m "SGROAS v1.0.0 - Entrega Final PFC (semana 17)"
git push origin v1.0.0
# 5. GitHub Release v1.0.0 + Zenodo release del DOI software (Alejandro)
# 6. README: URL pública, credenciales demo, digest ghcr (si aplica), video, badges verdes
git add -A; git commit -m "chore: cierre entrega final v1.0.0"; git push
# 7. Copia final: docs/informe-final.pdf, SRS-v1.0.0.pdf al repo (antes de #4 si el tag debe incluirlos)
```
**OJO:** el hash del tag debe estar en la portada → portada se actualiza ANTES del `git tag`. Si sale un push después del tag, el PDF del informe conserva el hash tag v1.0.0 (los commits posteriores al corte se ignoran, no penaliza).

## 9. COMMITS SUGERIDOS (mínimos del día, uno por avance real)
1. `feat(frontend): merge rama feature/frontend-maria a main (Angular 20)` — Alejandro
2. `docs(obs): registra OBS-XX de entregas 1A/1B/3 con commits de resolución (P0)` — Alejandro
3. `feat(db): invoca 7 SPs vía @Procedure + endpoint /api/reportes (P1)` — Alejandro
4. `ci(sec): spotbugs+find-sec-bugs, audit-sql-dynamic.sh, make all (R1)` — Alejandro
5. `test: cobertura JaCoCo >=70% (P3)` — Alejandro
6. `docs(req): SRS v1.0.0 ISO 29148 firmado (D0R)` — María
7. `docs(req): historias Gherkin + casos de uso Cockburn + INCOSE + matriz tipo_acceso (D0R)` — María
8. `docs(informe): estructura LaTeX + caps 1/2/4 + portada (B)` — María
9. `docs(analisis): k6/SUS con IC 95%, gen-figuras.py (C)` — Kevin
10. `docs(checklists): ralph2021, prisma2020, fair + DATA-PROVENANCE (E/F)` — Kevin
11. `docs(informe): caps 8-12 + refs.bib verificadas (D3-D6)` — Kevin
12. `feat(deploy): URL pública HTTPS + DEPLOYMENT/RUNBOOK/BACKUP + adr-006/007 (P5)` — Alejandro
13. `docs(zenodo): DOI dataset + ORCID reales + CITATION.cff v1.0.0 (R3/R4)` — Kevin
14. `chore: tag v1.0.0 + cierre entrega final` — Alejandro

---

*Generado el 16-ago-2026 con inventario real del repo (29 commits en main, tags v0.7.1/v0.9.0-rc intactos). Prioridad: D0R+R1 (16%) → P1/P3/P5/P0 (24%) → documento (19%) → resto (20%).*