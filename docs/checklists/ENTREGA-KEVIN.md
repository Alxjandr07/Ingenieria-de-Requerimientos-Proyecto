# Trazabilidad de la entrega — Parte de Kevin (K1–K7)

Rama: `Kevin` (basada en `main`). Fecha de cierre: 17-ago-2026.
Evidencia por commits contribuidos en la rama (ver `git log main..Kevin`).

## K1 — Análisis estadístico de k6 (Bloque C, RQ "rendimiento")

| Artefacto | Ruta |
|---|---|
| Scripts reproducibles | `scripts/perf/` + `scripts/perf-analysis.py`, `scripts/gen-figuras.py` |
| Análisis con estadística inferencial | `docs/mediciones/perf/ANALISIS-k6.md` |
| Datos crudos 3 corridas | `docs/mediciones/perf/k01..k03-run*.json` |
| Agregados | `docs/mediciones/perf/estadisticas.json/.csv` |
| Figuras (Okabe-Ito) | `docs/mediciones/perf/figuras/` |

Resultados: n=3 corridas, media de medias 23.01 ms, DT 12.44, EE 7.18,
IC95 [−7.88; 53.91], p95 máximo 173.13 ms (umbral ≤ 200 ms), error 0 %,
8930 checks OK / 0 fail. Cumple.

## K2 — SUS + ética (Bloque C, RQ "usabilidad")

| Artefacto | Ruta |
|---|---|
| Respuestas crudas | `docs/mediciones/sus/sus-raw.csv` y `P01..P10.json` |
| Análisis Brook et al. | `scripts/sus/` + `scripts/sus-analysis.py` |
| Resultados | `docs/mediciones/sus/ANALISIS-SUS.md`, `estadisticas-sus.json`, `figuras/` |
| Ética (AI + consentimientos) | `docs/etica/ai-disclosure.md`, `docs/etica/consentimientos/registro.md`, `ETHICS.md` |

Resultados: media 63.0, DT 13.88, EE 4.39, IC95 [53.07; 72.93],
Bangor: "bueno" (marginal 52–73); **no alcanza el umbral ≥ 70** → documentado
como observación en el capítulo 8.

## K3 — Auditoría calidad web + seguridad (Bloques A y F)

| Artefacto | Ruta |
|---|---|
| Scripts de auditoría | `scripts/lighthouse/run-lighthouse.sh`, `scripts/zap/run-zap.sh` |
| RESUMEN Lighthouse (corridas reales) | `docs/mediciones/lighthouse/RESUMEN.md` |
| RESUMEN ZAP | `docs/mediciones/sec/zap/RESUMEN.md` |

Lighthouse: 100 / 95 / 100 / 90 (umbrales 80/90/90/90) → cumple. ZAP: pendiente
de URL pública (dependencia A5). Umbrales y categorías en capítulo 8.

## K4 — Checklists + DATA-PROVENANCE + DATA-DICTIONARY

| Artefacto | Ruta |
|---|---|
| Checklists | `docs/checklists/ralph2021-empirical.md`, `prisma2020.md`, `fair.md` |
| Proveniencia | `docs/mediciones/DATA-PROVENANCE.md` |
| Diccionario de datos | `docs/mediciones/DATA-DICTIONARY.md` (10+ secciones) |

## K5 — Capítulos 8–12 + Referencias

| Artefacto | Ruta |
|---|---|
| Esqueleto compilable | `docs/informe-final/main-evaluacion.tex` |
| Evaluación | `docs/informe-final/capitulos/cap8-evaluacion.tex` |
| Discusión (RQ1–RQ4) | `docs/informe-final/capitulos/cap9-discusion.tex` |
| Amenazas a la validez | `docs/informe-final/capitulos/cap10-amenazas.tex` |
| Trabajo futuro | `docs/informe-final/capitulos/cap11-futuro.tex` |
| Conclusiones | `docs/informe-final/capitulos/cap12-conclusiones.tex` |
| Bibliografía verificada | `docs/informe-final/Referencias.bib` (39 entradas, 27 DOIs verificados vía Crossref) + `VERIFICACION-REFERENCIAS.md` |

## K6 — CITATION.cff + DOI dataset

| Artefacto | Ruta / valor |
|---|---|
| CITATION.cff v1.0.0 | `CITATION.cff` (ORCID reales de los 3) |
| DOI software (v1.0.0) | 10.5281/zenodo.22522109 |
| DOI dataset | 10.5281/zenodo.21973297 |
| Paquete de datos | `dataset/` (`README.md`, `MANIFEST.csv`, `zenodo.json`) |
| Script de empaquetado | `scripts/zenodo/package-dataset.py` |

## K7 — Video

| Artefacto | Ruta |
|---|---|
| Guion 5–7 min + checklist | `docs/video/GUION-video.md` |
| Enlace final | pendiente en `README.md` (grabar con Alejandro) |

## Estado global

- [x] K1, K2, K4, K5, K6
- [x] K3 (scripts + resúmenes; ZAP real pendiente de URL)
- [~] K7 (guion listo; grabación + enlace con Alejandro) → **PENDIENTE**
- [x] Dataset empaquetado y con DOI en Zenodo
- [ ] Verificación final del docente