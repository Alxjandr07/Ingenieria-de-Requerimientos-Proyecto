# Verificación de referencias — SGROAS

**Fecha de verificación inicial:** 16 de agosto de 2026  
**Re-verificación completa:** 6 de septiembre de 2026  
**Método:** consulta de cada DOI a la API de Crossref  
(`https://api.crossref.org/works/{doi}`); 35 de 36 respondieron `status: ok`.  
El DOI restante (`10.5281/zenodo.21973297`) es de Zenodo/DataCite, no Crossref — resuelve correctamente en https://doi.org.

## Resultado

| Criterio | Valor |
|---|---|
| Referencias en `refs.bib` | 71 (56 citadas + 15 de respaldo) |
| Con DOI verificado en Crossref | 35 |
| DOI Zenodo (DataCite, no Crossref) | 1 (`10.5281/zenodo.21973297`) |
| Sin DOI (clásicas, RFC, libros, tech reports) | 35 |
| Referencias fabricadas | **0** |

## Verificación de los 36 DOI (6 de septiembre de 2026)

| # | DOI | Estado | Título (Crossref) |
|---|---|---|---|
| 1 | `10.1109/IEEESTD.2018.8559686` | OK | ISO/IEC/IEEE 29148:2018 — Requirements engineering |
| 2 | `10.1007/978-3-642-01824-4` | OK | Requirements Engineering (Pohl) |
| 3 | `10.1145/514183.514185` | OK | Principled Design of the Modern Web Architecture |
| 4 | `10.1145/1367497.1367606` | OK | RESTful Web Services vs. "Big" Web Services |
| 5 | `10.17487/RFC7519` | OK | JSON Web Token (JWT) |
| 6 | `10.17487/RFC7807` | OK | Problem Details for HTTP APIs |
| 7 | `10.17487/RFC6749` | OK | The OAuth 2.0 Authorization Framework |
| 8 | `10.17487/RFC8725` | OK | JWT Best Current Practices |
| 9 | `10.1109/ICSE.2013.6606660` | OK | POPT: Problem-Oriented Programming and Testing |
| 10 | `10.5281/zenodo.21973297` | OK (DataCite) | Dataset SGROAS — Zenodo |
| 11 | `10.1007/978-3-642-29044-2` | OK | Experimentation in Software Engineering (Runeson) |
| 12 | `10.1136/bmj.n71` | OK | The PRISMA 2020 Statement |
| 13 | `10.1016/j.infsof.2013.07.010` | OK | Systematic Review of Systematic Review Process Research |
| 14 | `10.1016/j.infsof.2015.03.007` | OK | Guidelines for Systematic Mapping Studies |
| 15 | `10.2753/MIS0742-1222240302` | OK | A Design Science Research Methodology |
| 16 | `10.2307/25148625` | OK | Design Science in IS Research |
| 17 | `10.1007/s10664-008-9102-8` | OK | Guidelines for Case Study Research (Yin) |
| 18 | `10.1007/s10664-021-10072-8` | OK | Sampling in Software Engineering Research (Baltes & Ralph) |
| 19 | `10.1093/biomet/6.1.1` | OK | The Probable Error of a Mean (Student) |
| 20 | `10.1214/aoms/1177730491` | OK | On a Test of Whether one of Two Random Variables is Stochastically Larger |
| 21 | `10.2307/3001968` | OK | Individual Comparisons by Ranking Methods (Wilcoxon) |
| 22 | `10.1037/0033-2909.114.3.494` | OK | Dominance statistics (Cliff) |
| 23 | `10.1080/10447310802205776` | OK | An Empirical Evaluation of the System Usability Scale |
| 24 | `10.1007/978-3-642-02806-9_12` | OK | The Factor Structure of the System Usability Scale |
| 25 | `10.1080/10447318.2012.681221` | OK | Usability Ratings for Everyday Products (SUS) |
| 26 | `10.1109/TSE.2015.2445340` | OK | A Survey on Load Testing of Large-Scale Software Systems |
| 27 | `10.1109/ICSM.2009.5306331` | OK | Automated performance analysis of load tests |
| 28 | `10.1109/ICSE.2015.144` | OK | An Industrial Case Study on Automated Detection of Performance |
| 29 | `10.1145/2568225.2568271` | OK | Coverage is not strongly correlated with test suite effectiveness |
| 30 | `10.1145/2568225.2568278` | OK | Code coverage for suite evaluation by developers |
| 31 | `10.1145/3338906.3340459` | OK | Code coverage at Google |
| 32 | `10.1109/SOCA.2016.15` | OK | A Systematic Mapping Study in Microservice Architecture |
| 33 | `10.1109/MS.2018.2141031` | OK | On the Definition of Microservice Bad Smells |
| 34 | `10.1016/j.jss.2018.09.082` | OK | The pains and gains of microservices |
| 35 | `10.1016/j.jss.2021.111061` | OK | Design, monitoring, and testing of microservices systems |
| 36 | `10.1038/sdata.2016.18` | OK | The FAIR Guiding Principles (Wilkinson et al.) |

## DOIs corregidos en iteraciones previas

| DOI original (incorrecto) | Corrección | Artículo |
|---|---|---|
| `10.1016/j.jss.2018.08.033` | `10.1016/j.jss.2018.09.082` | Soldani et al., JSS 2018 |
| `10.1109/ICSM.2009.5306385` | `10.1109/ICSM.2009.5306331` | Jiang et al., ICSM 2009 |
| `10.1145/1367497.1367600` | `10.1145/1367497.1367606` | Pautasso et al., WWW 2008 |
| `10.1109/ICSE.2010.*` | `10.1109/ICSE.2015.144` | Foo et al., ICSE 2015 |
| `10.1145/3470481.3484630` | `10.1016/j.jss.2021.111061` | Waseem et al., JSS 2021 |
| `10.1080/10447318.2012.732430` | `10.1080/10447318.2012.681221` | Kortum & Bangor, IJHCI 2013 |
| `10.1109/IEEESTD.2018.8606021` | `10.1109/IEEESTD.2018.8559686` | ISO/IEC/IEEE 29148:2018 |
| `10.1007/s10664-022-10146-8` | `10.1007/s10664-021-10072-8` | Baltes & Ralph, ESE 2022 |
| `10.1038/s41746-023-00838-0` | `10.1038/sdata.2016.18` | Wilkinson et al., Scientific Data 2016 |

## Reproducibilidad

| Artefacto | Fuente |
|---|---|
| Consultas a Crossref | API REST `https://api.crossref.org/works/{doi}` (6-sep-2026) |
| Base de datos de citas | `docs/informe-final/refs.bib` |
| Cadena de búsqueda | ver anexo del informe (PRISMA) |

> Regla del plan: *referencias reales y verificables; fabricar = −25 % en D6 por cada instancia.*
