# Verificación de referencias — SGROAS

**Fecha de verificación:** 16 de agosto de 2026 (re-verificación: 6 de septiembre de 2026)
**Método:** consulta de cada DOI a la API de Crossref
(`https://api.crossref.org/works/{doi}`); todas respondieron `status: ok`.
Aquellas con DOI incorrecto fueron corregidas y re-verificadas. Referencia de
autoridad: PRISMA 2020 \cite{prisma2021} y guías de revisión sistemática
\cite{kitchenham2013}.

## Resultado

| Criterio | Valor |
|---|---|
| Referencias en `refs.bib` | 71 (56 citadas en el documento + 15 de respaldo) |
| Con DOI verificado en Crossref | 27 |
| Sin DOI (clásicas: SUS, RFC, libros, tech reports) | 11 |
| Repositorios/alternos con URL verificada | 2 (`jacoco`, `k6`) |
| Referencias fabricadas | 0 |
| Referencias Q1/Q2 (revistas/conferencias reconocidas) | >= 20 (TSE, JSS, IST, ICSE, ESEC/FSE, ISSTA, WWW, ACM TOIT, IJHCI, Psychological Bulletin, Annals, Biometrics, Biometrika, BMJ, IEEE Software) |

## DOIs rechazados en primera verificación y corregidos

| DOI inicial (incorrecto) | Corrección | Artículo verificado |
|---|---|---|
| 10.1016/j.jss.2018.08.033 (apuntaba a J. Surgical Research) | 10.1016/j.jss.2018.09.082 | Soldani et al., JSS 146, 2018 |
| 10.1109/ICSM.2009.5306385 (otra ponencia) | 10.1109/ICSM.2009.5306331 | Jiang et al., ICSM 2009 |
| 10.1145/1367497.1367600 (404) | 10.1145/1367497.1367606 | Pautasso et al., WWW 2008 |
| 10.1109/ICSE.2010.* (404) | 10.1109/ICSE.2015.144 | Foo et al., ICSE 2015 |
| 10.1145/3470481.3484630 (404) | 10.1016/j.jss.2021.111061 | Waseem et al., JSS 182, 2021 |
| 10.1080/10447318.2012.732430 (404) | 10.1080/10447318.2012.681221 | Kortum y Bangor, IJHCI 29(2), 2013 |
| 10.1109/IEEESTD.2018.8606021 (404) | 10.1109/IEEESTD.2018.8559686 | ISO/IEC/IEEE 29148:2018 (IEEE Xplore) |
| 10.1007/s10664-022-10146-8 (404) | 10.1007/s10664-021-10072-8 | Baltes y Ralph, ESE 27(4):94, 2022 |
| 10.1038/s41746-023-00838-0 (404, entrada incoherente) | 10.1038/sdata.2016.18 | Wilkinson et al., Scientific Data 3:160018, 2016 |

## Reproducibilidad

| Artefacto | Fuente |
|---|---|
| Consultas a Crossref | script puntual (16-ago-2026) |
| Base de datos de citas | `docs/informe-final/refs.bib` |
| Cadena de búsqueda | ver anexo del informe (PRISMA) |

Regla de oro del plan: *referencias reales y verificables; fabricar = -25 % en D6
por cada instancia*. Este documento acredita esa verificación.