# Guion del video — SGROAS (5–7 min)

**Objetivo:** demostrar que el proyecto es reproducible desde un clon limpio
(`make all`) y presentar los reportes de medición del estudio empírico.
**Grabación:** OBS Studio / celular, 720p+, audio claro. **Publicación:**
YouTube "No listado"; colocar el enlace en el README (sección correspondiente).
**Participantes:** Kevin (guion) + Alejandro (ejecución `make all`, demo).

---

## min 0:00 – Portada / intro (≈20 s)
Textos en pantalla: *SGROAS — Sistema de Gestión de Recursos Operativos,
Administrativos y de Seguridad*. Integrantes y UTEQ. Objetivo del video:
"reproducibilidad y evidencia empírica".

## min 0:20 – Clon limpio (≈30 s)
```sh
git clone https://github.com/Alxjandr07/SGROAS-ProyectoAppWeb.git sgroas
cd sgroas
git checkout v1.0.0        # o la rama main con tag v1.0.0
```
Mostrar que partimos de un directorio vacío (carpeta limpia al inicio).

## min 0:50 – make all (≈60 s)
```sh
make all
```
Mostrar el inicio en vivo (npm install, sam build, docker compose up) y
**echo del código de salida 0** (`echo $?`). Si hace falta, acelerar con
edición, pero sin cortar el `exit code 0`.

## min 1:50 – Recorrido por reportes (≈3 min)
Abrir y narrar brevemente cada uno:

| Reporte | Qué mostrar | Número clave |
|---|---|---|
| `docs/mediciones/perf/ANALISIS-k6.md` | p95 < 200 ms, 0 % error | media de medias 23.01 ms, IC95 [−7.88; 53.91] |
| `docs/mediciones/perf/figuras/` | figuras Okabe-Ito | 4 PNG regenerables |
| `docs/mediciones/sus/ANALISIS-SUS.md` | SUS media/DT/IC95 | media 63.0, IC95 [53.07; 72.93] |
| `docs/mediciones/lighthouse/RESUMEN.md` | categorías | 100/95/100/90 |
| `docs/mediciones/sec/zap/RESUMEN.md` | baseline OWASP ZAP | alertas y severidades |
| `docs/mediciones/jacoco/` | cobertura | 98.8 % instr / 85.4 % ramas |

Cerrar con **disponibilidad de datos**: DOI software (v1.0.0)
`10.5281/zenodo.22522109`, DOI dataset `10.5281/zenodo.21973297`.

## min 4:50 – Cierre (≈10 s)
Repo, tag v1.0.0, CI verde, agradecimientos; animar a citar la publicación
(Zenodo) si se usa el dataset.

---

## Checklist de grabación
- [ ] Clon en carpeta limpia (nada precargado).
- [ ] `make all` corre completo y `echo $?` = 0.
- [ ] Se ven al menos 4 de los reportes de la tabla.
- [ ] `README.md` ya contiene el enlace del video + DOI dataset.
- [ ] Subido a YouTube (No listado), link pegado en README.
- [ ] Duración entre 5 y 7 minutos.