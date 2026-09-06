# Análisis estático — SpotBugs + FindSecBugs

**Fecha:** 2026-09-06  
**Herramienta:** `spotbugs-maven-plugin:4.8.6.6` + `findsecbugs-plugin:1.12.0` (JDK 21, Docker `maven:3.9-eclipse-temurin-21`)  
**Filtro:** `scripts/spotbugs-include.xml`  
**Comando:** `mvn spotbugs:spotbugs`  
**Salida:** `docs/mediciones/sec/static-analysis/spotbugsXml.xml` (62 KB, BugCollection completa con classpath y Hallazgos)

## Resultado

- **Bugs encontrados:** **0** (0 BugInstance en el XML)
- **Hallazgos altos (High):** 0
- **Hallazgos medios/bajos:** 0
- **Estado:** **PASA** — no hay concatenación de entrada de usuario en JPQL/HQL/SQL nativo ni en `@Procedure`/`@NamedStoredProcedureQuery`.

## Evidencia complementaria

- `scripts/audit-sql-dynamic.sh` ejecutado en CI: **0 violaciones**
  - Revisa `db/procs/*.sql` contra `EXECUTE IMMEDIATE`, `sp_executesql` y concatenación `||`/`+` en SQL dinámico
  - Revisa `src/main/java/**.java` contra `createNativeQuery("..." +` y `+ " SELECT`/`FROM`/`WHERE`
  - Resultado: sin hallazgos

## Artefactos

- `spotbugsXml.xml` — salida real de SpotBugs 4.8.6 (62 KB, con `BugCollection`, classpath, analysisTimestamp)
- Este `REPORT.md` — resumen humano para el criterio P3/A.2.3

> Reproducir: `docker run --rm -v "$(pwd):/app" -w /app maven:3.9-eclipse-temurin-21 mvn spotbugs:spotbugs` genera `target/spotbugsXml.xml`.
