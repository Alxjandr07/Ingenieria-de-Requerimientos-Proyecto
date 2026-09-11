# SGROAS - Sistema de Gestión de Recursos Operativos, Administrativos y de Seguridad

[![CI](https://github.com/Alxjandr07/SGROAS-ProyectoAppWeb/actions/workflows/ci.yml/badge.svg)](https://github.com/Alxjandr07/SGROAS-ProyectoAppWeb/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Java](https://img.shields.io/badge/Java-21-blue)](https://adoptium.net/)
[![Spring Boot](https://img.shields.io/badge/Spring%20Boot-3.5-green)](https://spring.io/projects/spring-boot)
[![Angular](https://img.shields.io/badge/Angular-17-red)](https://angular.io/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-18-336791)](https://www.postgresql.org/)
[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.22522109.svg)](https://doi.org/10.5281/zenodo.22522109)

> **Grupo D** — Universidad Técnica Estatal de Quevedo (UTEQ) — FCC — Carrera de Ingeniería de Software
> Aplicaciones Web — Quinto Nivel — Periodo 2026-2027

## Integrantes

| Integrante | Rol |
|---|---|
| Kevin Moisés Castro Espinoza | Desarrollador Backend |
| María del Rosario Escudero Plaza | Desarrolladora Frontend / Documentación |
| Luis Alejandro Tejada Bajaña | Desarrollador Backend / Infraestructura |

## Arranque rápido

```bash
# Clonar
git clone https://github.com/Alxjandr07/SGROAS-ProyectoAppWeb.git
cd SGROAS-ProyectoAppWeb

# Copiar variables de entorno
cp .env.example .env

# Levantar todo
make up

# Ejecutar pruebas
make test

# Benchmarks
make bench

# Auditoría de seguridad
make audit

# Artefactos docs (versions + figuras k6)
make docs

# Compilar el informe (genera docs/informe-final/main.pdf, 95 páginas)
make pdf

# Pipeline completo end-to-end (up, test, bench K1-K3, audit, jacoco, docs, pdf)
make all

# Detener (no se ejecuta dentro de make all, correr manual)
make down
```

Sistema disponible en `https://sgroas-backend.onrender.com` (Render Free, datos de muestra `V1..V9`; `>1M` reproducible en local con `psql -f db/data/generar_datos_masivos.sql`) — desarrollo local: `http://localhost:8080`.

## Compilación del informe técnico

El informe se compila desde el directorio `docs/informe-final/` (95 páginas),
con `pdflatex` + `biber` (4 invocaciones: tres pasadas de `pdflatex` y una de `biber`):

```bash
cd docs/informe-final
pdflatex -interaction=nonstopmode main.tex
biber main
pdflatex -interaction=nonstopmode main.tex
pdflatex -interaction=nonstopmode main.tex
```

También se puede compilar desde la raíz del repositorio con `make pdf`.

### Credenciales por defecto

| Usuario | Rol | Contraseña |
|---|---|---|
| admin@sgroas.com | ADMIN | admin123 |
| coordinador@sgroas.com | COORDINADOR | coord123 |
| seguridad@sgroas.com | SEGURIDAD | segur123 |

> Cada usuario tiene su contraseña propia (no se comparte). Los hashes se
> generan con `BCryptPasswordEncoder` (strength 10) en `V2__seed.sql`.

## Comprobación de funcionalidades (Bases de Datos Avanzadas - ABD)

El repositorio incluye los elementos ABD requeridos y las instrucciones para
reproducirlos y comprobarlos:

| Requisito ABD | Dónde está | Cómo comprobar |
|---|---|---|
| BD con **+1M de registros** | `db/data/generar_datos_masivos.sql` + `docs/basedatos/CARGA-MASIVA-ABD.md` | `SELECT (SELECT count(*) FROM programacion) + ...` (> 1.000.000 de hechos) |
| **Usuarios, roles y privilegios** | `db/seguridad/seguridades_bd_sgroas.sql` + `docs/basedatos/SEGURIDAD-ABD.md` | Roles `usr_admin_coop`, `usr_coordinador`, `usr_seguridad_vial` con RLS |
| **Respaldos y recuperación** | `scripts/backup-prod.sh` + `docs/despliegue/BACKUP.md` + `docs/despliegue/RUNBOOK.md` | Ejecutar `bash scripts/backup-prod.sh` y restaurar con `pg_restore` |
| **Optimización de consultas** | `V11`/`V13` índices + `docs/basedatos/INDICES-ABD.md` | `EXPLAIN (ANALYZE, BUFFERS)` muestra `Index Scan` en vez de `Seq Scan` |
| **Auditoría de BD** | `V12` triggers + `docs/basedatos/AUDITORIA-ABD.md` | Insertar/actualizar y ver la fila nueva en `auditoria` |
| **Elementos programables** | `V5`, `V12`, `V13` + `docs/basedatos/ELEMENTOS-PROGRAMABLES.md` | Funciones, cursores explícitos y procedimientos con validación (comandos incluidos) |

## Informe final (Entrega Final v1.0.0)

Documento académico completo — **96 páginas** con anexos y capturas CI/Render: [`docs/informe-final.pdf`](docs/informe-final.pdf) · Fuente LaTeX: [`docs/informe-final/main.tex`](docs/informe-final/main.tex) + `refs.bib` · Wrapper para Listing 1 p.17: [`docs/informe-final.tex`](docs/informe-final.tex).

### Compilación del informe

```bash
# Opción A: desde docs/ (wrapper, Listing 1 p.17)
cd docs
pdflatex informe-final && biber informe-final && pdflatex informe-final && pdflatex informe-final

# Opción B: desde docs/informe-final/ (directo)
cd docs/informe-final
pdflatex main && biber main && pdflatex main && pdflatex main
```

Requiere MiKTeX o TeX Live con `babel-spanish`, `biblatex` + `biber`, `listings`, `csquotes`, `float`.

## Estructura del repositorio

```
.
├── backend/          # Spring Boot 3.5 / Java 21
├── frontend/         # Angular 17+
├── db/               # Schema, seed, stored procedures
├── docs/             # Documentación completa
├── k6/               # Benchmarks de rendimiento
├── scripts/          # Utilidades de validación
└── .github/          # CI/CD
```

## Licencia

Distribuido bajo licencia MIT. Ver [LICENSE](LICENSE).

## Citación

```bibtex
@software{sgroas_2026,
  author = {Castro Espinoza, Kevin Moisés and Escudero Plaza, María del Rosario and Tejada Bajaña, Luis Alejandro},
  title = {SGROAS: Sistema de Gestión de Recursos Operativos, Administrativos y de Seguridad},
  month = jul,
  year = 2026,
  publisher = {Zenodo},
  doi = {10.5281/zenodo.22522109},
  url = {https://github.com/Alxjandr07/SGROAS-ProyectoAppWeb}
}
```

> Versión publicada: tag `v1.0.0` (commit `9ded2a69f1da35d09b6dfedb9d62e61e5c9ae48a`).

## Dataset del estudio empírico

Los datos de mediciones (rendimiento k6, susabilidad SUS, calidad web
Lighthouse, seguridad OWASP ZAP y cobertura JaCoCo) están publicados como
dataset de acceso abierto en Zenodo:

- **Dataset:** [10.5281/zenodo.21973297](https://doi.org/10.5281/zenodo.21973297)
  ([CC BY 4.0](https://creativecommons.org/licenses/by/4.0/))
- Empaquetado reproducible: `scripts/zenodo/package-dataset.py`
- Descripción y checksums: [`dataset/`](dataset/)

## Imagen Docker (GHCR)

Imagen del sistema (backend JDK 21 + frontend Angular) publicada en GitHub
Container Registry por el workflow `release-docker.yml` (reproducible en el CI):

```bash
docker pull ghcr.io/alxjandr07/sgroas:v1.0.0
```

- Etiqueta: `ghcr.io/alxjandr07/sgroas:v1.0.0`
- Digest (manifest list, amd64):
  `sha256:ea284abed7f6dcb16ef6859e8e5a57cdc1958ed30336e31f04a966a379b18f92`
- Para levantar el sistema completo (backend + PostgreSQL + Redis) usar
  `docker compose up --build -d`.


