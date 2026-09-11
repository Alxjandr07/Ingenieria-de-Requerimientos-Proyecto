.PHONY: up down test bench bench-render audit jacoco versions docs pdf all clean

PYTHON ?= $(shell command -v python3 2>/dev/null || command -v python 2>/dev/null)

# =============================================================================
# SGROAS — Makefile
# =============================================================================
# Uso: make up    -> levantar el sistema completo
#      make down  -> detener contenedores
#      make test  -> ejecutar pruebas
#      make bench -> benchmarks k6 locales K1-K3 (serie local, n=3)
#      make bench-render -> benchmarks k6 Render K4-K8 (serie publica, n=5, requiere JWT)
#      make audit -> auditoria SQL estatico + trazabilidad
#      make jacoco-> regenerar reporte de cobertura
#      make versions -> generar docs/entorno/versions.txt
#      make pdf   -> compilar el informe (docs/informe-final/main.tex, 95 pag.)
#      make docs  -> generar artefactos de documentacion
#      make all   -> pipeline completo (R1: reproduccion end-to-end)
#      make clean -> limpieza total
# =============================================================================

up:
	docker compose up --build -d
	@echo "Esperando a que el backend esté listo..."
	@sleep 15
	@echo "Sistema disponible en http://localhost:8080"

down:
	docker compose down -v

test:
	./mvnw test
	@echo "Reporte JaCoCo generado en docs/mediciones/jacoco/"

bench:
	@echo "Ejecutando benchmarks k6 locales K1-K3 (3 corridas) contra el stack local (make up)..."
	k6 run -e BASE_URL=http://localhost:8080 k6/script.js --summary-export docs/mediciones/perf/k01-run1.json
	k6 run -e BASE_URL=http://localhost:8080 k6/script.js --summary-export docs/mediciones/perf/k02-run2.json
	k6 run -e BASE_URL=http://localhost:8080 k6/script.js --summary-export docs/mediciones/perf/k03-run3.json
	@echo "Benchmarks completos. Resultados en docs/mediciones/perf/"
	@echo "Serie Render K4-K8 (5 corridas calientes + 5 frias) ya archivada; ver 'make bench-render'."

bench-render:
	@echo "Serie Render K4-K8 contra https://sgroas-backend.onrender.com (requiere JWT, 30s entre corridas)..."
	@echo "Ejemplo (no se ejecuta en 'make all' para no saturar Render Free):"
	@echo "k6 run -e BASE_URL=https://sgroas-backend.onrender.com k6/script.js --summary-export docs/mediciones/perf/k04-run1.json"
	@echo "Ver docs/mediciones/perf/ANALISIS-k6.md (n=5) y RENDER-REPORT.md."

audit:
	@echo "Auditoria: SQL dinamico prohibido..."
	scripts/audit-sql-dynamic.sh
	@echo "Auditoria: trazabilidad end-to-end..."
	scripts/validate-traceability.sh
	@echo "Auditorias completas (exit 0 = OK)."

jacoco:
	./mvnw clean verify
	@echo "Reporte JaCoCo regenerado en docs/mediciones/jacoco/"

versions:
	mkdir -p docs/entorno
	$(PYTHON) scripts/gen-versions.py > docs/entorno/versions.txt
	@echo "Versiones registradas en docs/entorno/versions.txt"

pdf:
	@echo "Compilando informe LaTeX (docs/informe-final/main.tex)..."
	cd docs/informe-final && pdflatex -interaction=nonstopmode main.tex
	cd docs/informe-final && biber main
	cd docs/informe-final && pdflatex -interaction=nonstopmode main.tex
	cd docs/informe-final && pdflatex -interaction=nonstopmode main.tex
	@echo "PDF generado en docs/informe-final/main.pdf (95 paginas)."

docs: versions
	$(PYTHON) scripts/gen-figuras.py
	@echo "Artefactos de documentacion generados."

all: up test bench audit jacoco docs pdf
	@echo "=========================================="
	@echo "PIPELINE COMPLETO (make all) FINALIZADO OK"
	@echo "=========================================="

clean:
	docker compose down -v --rmi all
	@echo "Limpieza completada."
