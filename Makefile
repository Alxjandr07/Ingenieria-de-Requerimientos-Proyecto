.PHONY: up down test bench audit jacoco versions docs pdf all clean

PYTHON ?= $(shell command -v python3 2>/dev/null || command -v python 2>/dev/null)

# =============================================================================
# SGROAS — Makefile
# =============================================================================
# Uso: make up    -> levantar el sistema completo
#      make down  -> detener contenedores
#      make test  -> ejecutar pruebas
#      make bench -> ejecutar benchmarks k6
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
	@echo "Ejecutando benchmarks k6 (3 corridas)..."
	k6 run k6/script.js --summary-export docs/mediciones/perf/k01-run1.json
	k6 run k6/script.js --summary-export docs/mediciones/perf/k02-run2.json
	k6 run k6/script.js --summary-export docs/mediciones/perf/k03-run3.json
	@echo "Benchmarks completos. Resultados en docs/mediciones/perf/"

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
	@echo "Artefactos de documentacion generados."

all: up test bench audit jacoco versions pdf
	@echo "=========================================="
	@echo "PIPELINE COMPLETO (make all) FINALIZADO OK"
	@echo "=========================================="

clean:
	docker compose down -v --rmi all
	@echo "Limpieza completada."
