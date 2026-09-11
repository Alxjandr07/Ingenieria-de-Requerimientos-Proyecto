#!/usr/bin/env python3
"""Generacion de figuras de rendimiento k6 (Bloque C / tarea K1).

Cada figura es 100% regenerable: los PNG de docs/mediciones/perf/figuras/
se producen ejecutando este script sobre las corridas archivadas. Usa la
paleta Okabe-Ito (accesible para daltonicos).

Uso: python scripts/gen-figuras.py
"""

from __future__ import annotations

import sys
from pathlib import Path

import matplotlib

matplotlib.use("Agg")

import matplotlib.pyplot as plt  # noqa: E402

sys.path.insert(0, str(Path(__file__).resolve().parent))

from perf.colors import FIGH, FIGW, GRIS_SUAVE, PALETA_PRINCIPAL  # noqa: E402
from perf.k6_loader import cargar_todas, medias_por_corrida  # noqa: E402
from perf.stats import ic95  # noqa: E402

RAIZ = Path(__file__).resolve().parents[1]
FIGURAS = RAIZ / "docs" / "mediciones" / "perf" / "figuras"

UMBRAL_P95_MS = 200

NIVELES = ["min", "p50", "p90", "p95", "p99", "max"]
ETIQUETAS = ["min", "p50", "p90", "p95", "p99", "max"]


def fig_percentiles(corridas) -> Path:
    """Perfil de percentiles por corrida."""
    fig, ax = plt.subplots(figsize=(FIGW, FIGH))
    for corrida, color in zip(corridas, PALETA_PRINCIPAL):
        valores = [
            corrida.duracion.min,
            corrida.duracion.p50,
            corrida.duracion.p90,
            corrida.duracion.p95,
            corrida.duracion.p99,
            corrida.duracion.max,
        ]
        ax.plot(NIVELES, valores, marker="o", color=color, label=corrida.nombre)
    ax.set_yscale("log")
    ax.set_ylabel("Latencia (ms, escala log)")
    ax.set_xlabel("Percentil")
    ax.set_title("Perfil de percentiles de http_req_duration por corrida")
    ax.grid(True, which="both", linestyle=":", alpha=0.5)
    ax.legend()
    ruta = FIGURAS / "fig-percentiles-corridas.png"
    fig.tight_layout()
    fig.savefig(ruta, dpi=150)
    plt.close(fig)
    return ruta


def fig_p95(corridas) -> Path:
    """p95 por corrida con linea del umbral."""
    nombres = [c.nombre for c in corridas]
    p95 = [c.duracion.p95 for c in corridas]
    fig, ax = plt.subplots(figsize=(FIGW, FIGH))
    barras = ax.bar(nombres, p95, color=PALETA_PRINCIPAL[: len(corridas)])
    ax.axhline(UMBRAL_P95_MS, color=GRIS_SUAVE, linestyle="--", linewidth=1.2,
               label=f"umbral p95 < {UMBRAL_P95_MS} ms")
    ax.bar_label(barras, fmt="%.1f", fontsize=8)
    ax.set_ylabel("p95 (ms)")
    ax.set_title("Percentil 95 de http_req_duration por corrida")
    ax.legend()
    ax.grid(True, axis="y", linestyle=":", alpha=0.5)
    ruta = FIGURAS / "fig-p95-por-corrida.png"
    fig.tight_layout()
    fig.savefig(ruta, dpi=150)
    plt.close(fig)
    return ruta


def fig_media_ic95(corridas) -> Path:
    """Medias por corrida, media global y banda IC 95%."""
    medias = medias_por_corrida(corridas)
    m, _s, _se, inf, sup = ic95(medias)
    nombres = [c.nombre for c in corridas]

    fig, ax = plt.subplots(figsize=(FIGW, FIGH))
    ax.bar(nombres, medias, color=PALETA_PRINCIPAL[: len(corridas)], alpha=0.85)
    ax.axhline(m, color="black", linestyle="-", linewidth=1.4, label=f"media global = {m:.2f} ms")
    ax.axhspan(inf, sup, color=PALETA_PRINCIPAL[0], alpha=0.15, label=f"IC 95% [{inf:.1f}; {sup:.1f}] ms")
    ax.set_ylabel("Media de http_req_duration (ms)")
    ax.set_title("Media por corrida y media global con IC 95%")
    ax.legend()
    ax.grid(True, axis="y", linestyle=":", alpha=0.5)
    ruta = FIGURAS / "fig-media-ic95.png"
    fig.tight_layout()
    fig.savefig(ruta, dpi=150)
    plt.close(fig)
    return ruta


def fig_error_rate(corridas) -> Path:
    """Tasa de error (http_req_failed) por corrida."""
    nombres = [c.nombre for c in corridas]
    errores = [c.error_rate for c in corridas]
    fig, ax = plt.subplots(figsize=(FIGW, FIGH))
    ax.bar(nombres, errores, color=PALETA_PRINCIPAL[: len(corridas)])
    ax.set_ylabel("Tasa de error (http_req_failed)")
    ax.set_title("Tasa de error por corrida (objetivo < 0.01)")
    ax.set_ylim(0, max(0.02, max(errores) * 1.5))
    ax.grid(True, axis="y", linestyle=":", alpha=0.5)
    ruta = FIGURAS / "fig-error-rate.png"
    fig.tight_layout()
    fig.savefig(ruta, dpi=150)
    plt.close(fig)
    return ruta


def main() -> int:
    corridas = cargar_todas()
    FIGURAS.mkdir(parents=True, exist_ok=True)
    generadas = [
        fig_percentiles(corridas),
        fig_p95(corridas),
        fig_media_ic95(corridas),
        fig_error_rate(corridas),
    ]
    for ruta in generadas:
        print("OK", ruta.name, ruta.stat().st_size, "bytes")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
