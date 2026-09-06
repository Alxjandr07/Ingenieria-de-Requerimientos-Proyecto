# SGROAS — Dataset de mediciones del estudio empírico

**Repositorio:** https://github.com/Alxjandr07/SGROAS-ProyectoAppWeb
**Fecha del estudio:** julio-agosto 2026 · **Versionado:** v1.0.0 (2026-08-17)
**Licencia del dataset:** [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/)
**DOI dataset:** [10.5281/zenodo.21973297](https://doi.org/10.5281/zenodo.21973297) (depósito SEPARADO en Zenodo)

Este paquete archiva los **datos crudos, agregados y figuras** generados por el
estudio empírico de evaluación de SGROAS (Sistema de Gestión de Recursos
Operativos, Administrativos y de Seguridad). Cada número del informe proviene de
un script reproducible; **no hay datos fabricados a mano** (ver
`DATA-PROVENANCE.md` incluido aquí).

## Contenido

| Carpeta | Variable / bloque | Métrica reportada |
|---|---|---|
| `perf/` | R1 · Rendimiento k6 | p95 < 200 ms, 0 % error, media de medias 23.01 ms (IC95 [−7.88; 53.91]) |
| `sus/` | R2 · Usabilidad SUS | media 63.0, DT 13.88, IC95 [53.07; 72.93], P01–P10 |
| `lighthouse/` | R3 · Calidad web | 100/95/100/90 (perf/acc/bp/seo) |
| `zap/` | A · Seguridad OWASP | baseline OWASP ZAP (pendiente URL pública) |
| `jacoco/` | B · Cobertura | 98.8 % instr / 85.4 % ramas / 99.7 % líneas |

## Estructura de archivos

```
dataset-sgroas/
├── README.md                 ← este archivo
├── MANIFEST.csv              ← checksums SHA-256 (ruta, bytes, hash)
├── MANIFEST.sha256           ← mismo checksum en formato `sha256sum -c`
├── DATA-PROVENANCE.md        ← origen de cada medición
├── DATA-DICTIONARY.md        ← definición de todas las variables
├── perf/                     ← 3 corridas k6 + análisis + figuras
├── sus/                      ← SUS P01–P10 + análisis + figura
├── lighthouse/               ← JSON de corridas LHCI + resúmenes
├── zap/                      ← resumen del baseline OWASP ZAP
└── jacoco/                   ← informe Jacoco (jacoco.xml + csv)
```

## Reuso

- Cite este depósito: **Castro Espinoza, K. M., Escudero Plaza, M. R., &
  Tejada Bajaña, L. A. (2026). SGROAS: Dataset de mediciones del estudio
  empírico (v1.0.0) [Data set]. Zenodo. https://doi.org/10.5281/zenodo.21973297**
- Los datos SUS corresponden a 10 participantes voluntarios con
  consentimiento informado (ver `docs/etica/` en el repositorio). No contiene
  datos personales identificables.
- Reproducibilidad: los scripts están en `scripts/` del repositorio.

## Integridad

La lista de checksums SHA-256 está en `MANIFEST.csv`. Verificación:

```sh
certutil -hashfile <archivo> SHA256            # Windows
sha256sum -c MANIFEST.sha256                   # Linux/macOS (archivo en formato sha256sum)
python -c "import csv,hashlib,pathlib; [print('  '+r, '=> OK' if h==hashlib.sha256(pathlib.Path(r).read_bytes()).hexdigest() else '=> FALLO') for r,b,h in list(csv.reader(open('MANIFEST.csv')))[1:]]"
```