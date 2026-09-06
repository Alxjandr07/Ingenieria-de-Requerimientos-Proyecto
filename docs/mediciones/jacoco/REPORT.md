# Reporte de cobertura de código (JaCoCo)

## Resumen

> **Nota de reconciliación (06-sep-2026):** se actualiza el reporte con la medición del CI
> (GitHub Actions, run `34024539023`, commit `dea7940`), que incorpora la batería de pruebas de
> cobertura añadida en los commits `38235d9` y `dea7940` (controllers y servicios). Son **222
> pruebas JUnit 5, 0 fallos, 0 errores**.

| Métrica | Full bundle (con `abd`) | | | | Core (sin `abd`, sujeto a `jacoco:check`) | | | |
|---|---|---|---|---|---|---|---|---|
| | Cubierto | No cubierto | Total | Cobertura | Cubierto | No cubierto | Total | Cobertura |
| Instrucciones | 4826 | 2617 | 7443 | **64,8 %** | 4826 | 687 | 5513 | **87,5 %** |
| Ramas | 123 | 143 | 266 | **46,2 %** | 123 | 17 | 140 | **87,9 %** |
| Líneas | 966 | 354 | 1320 | **73,2 %** | 966 | 46 | 1012 | **95,5 %** |

> Cifras extraídas de `jacoco.csv` (artefacto `jacoco-report` del run `34024539023`).

## Umbral exigido (criterio P1, guía Entrega Final)

- Configuración vigente en `pom.xml` (plugin `jacoco-maven-plugin` 0.8.14): regla `BUNDLE` con
  `LINE COVEREDRATIO >= 0.70` y `BRANCH COVEREDRATIO >= 0.50`.
- El paquete `ec.edu.uteq.sgroas.abd.**` queda excluido del `jacoco:check`: su correctitud se
  verifica con los objetos de base de datos (migraciones, procedimientos almacenados, disparadores,
  RLS, índices) y con `StoredProcedureIntegrationTest`, no con cobertura de pruebas unitarias.
- La cobertura medida del núcleo (sin el paquete `abd`) es **87,5 % instrucciones / 87,9 % ramas / 95,5 % líneas**:
  supera ampliamente el umbral LINE 0,70 y BRANCH 0,50 (CI verde el 06 de septiembre de 2026,
  `All coverage checks have been met`).

## Evolución de la cobertura del núcleo

| Métrica | 28-ago-2026 (commit `66fa254`) | 06-sep-2026 (commit `dea7940`) |
|---|---|---|
| Instrucciones | 75,8 % | **87,5 %** |
| Ramas | 54,3 % | **87,9 %** |
| Líneas | 85,5 % | **95,5 %** |

> La tarea P1 (subir cobertura de ramas del núcleo ≥ 70 %) pasa de 54,3 % a 87,9 %.

## Desglose por paquete (instrucciones/ramas) — reconciliado con `jacoco.csv`

| Paquete | Instrucciones | Ramas | Líneas |
|---|---|---|---|
| `ec.edu.uteq.sgroas` (SgroasApplication) | 37,5 % | — | 33,3 % |
| `ec.edu.uteq.sgroas.abd.controller` | 0,0 % | 0,0 % | 0,0 % *excluido del check* |
| `ec.edu.uteq.sgroas.abd.dto` | 0,0 % | — | 0,0 % *excluido* |
| `ec.edu.uteq.sgroas.abd.service` | 0,0 % | 0,0 % | 0,0 % *excluido* |
| `ec.edu.uteq.sgroas.config` | 96,6 % | — | 93,9 % |
| `ec.edu.uteq.sgroas.controller` | 98,7 % | 86,4 % | 98,3 % |
| `ec.edu.uteq.sgroas.dto` | 100,0 % | — | 100,0 % |
| `ec.edu.uteq.sgroas.entity` | 100,0 % | — | 100,0 % |
| `ec.edu.uteq.sgroas.exception` | 88,2 % | — | 88,0 % |
| `ec.edu.uteq.sgroas.security` | 96,6 % | 83,3 % | 100,0 % |
| `ec.edu.uteq.sgroas.service` | 79,8 % | 90,2 % | 95,0 % |

## Contexto de la medición

- Fecha: 06 de septiembre de 2026
- Entorno: GitHub Actions (JDK 21 Temurin), Maven, JaCoCo 0.8.14; run `34024539023`, commit `dea7940`
- Comando: `./mvnw verify` (222 pruebas JUnit 5, 0 fallos, 0 errores; `All coverage checks have been met`)
- Pruebas unitarias locales (Mockito, sin Spring context): 203 tests, 0 fallos
- Las 3 clases con `@SpringBootTest` (`SecurityConfigTest`, `SgroasApplicationTests`,
  `StoredProcedureIntegrationTest`) corren solo en CI (contenerizador Postgres+Redis)
- Artefactos generados en este directorio: `index.html`, `jacoco.csv`, `jacoco.xml`,
  `jacoco-sessions.html` y el desglose por paquete