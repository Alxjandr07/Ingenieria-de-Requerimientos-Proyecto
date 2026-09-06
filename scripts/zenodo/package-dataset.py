#!/usr/bin/env python3
"""Empaqueta docs/mediciones como dataset para depósito en Zenodo (K6).

Genera:
  - dataset/MANIFEST.csv  (sha256 de cada archivo del dataset)
  - dist/sgroas-dataset-v1.0.0.zip (subir como depósito SEPARADO en Zenodo)
Reuso: actualizar VERSION al hacer release y, tras el depósito, rellenar
el DOI dataset en dataset/README.md y en CITATION.cff.
"""
from __future__ import annotations

import csv
import hashlib
import os
import shutil
import sys
import zipfile
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
VERSION = "v1.0.0"
DIST = REPO / "dist"
ZIP_NAME = f"sgroas-dataset-{VERSION}.zip"
# carpetas y archivos raíz que forman el dataset
MEDICIONES = REPO / "docs" / "mediciones"
ROOT_FILES = ["DATA-PROVENANCE.md", "DATA-DICTIONARY.md"]
# Mapeo: nombre en dataset -> ruta relativa dentro de docs/mediciones/
FOLDER_MAP = {
    "perf": "perf",
    "sus": "sus",
    "lighthouse": "lighthouse",
    "jacoco": "jacoco",
    "zap": "sec/zap",
}


def sha256(p: Path) -> str:
    h = hashlib.sha256()
    with p.open("rb") as fh:
        for chunk in iter(lambda: fh.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def archivos_seleccionados() -> list[tuple[Path, str]]:
    """Retorna (ruta_absoluta, ruta_relativa_en_dataset) por cada archivo."""
    out: list[tuple[Path, str]] = []
    for f in ROOT_FILES:
        p = MEDICIONES / f
        if p.exists():
            out.append((p, f))
    for ds_name, rel_path in FOLDER_MAP.items():
        src = MEDICIONES / rel_path
        if src.is_dir():
            for root, _, files in os.walk(src):
                for name in files:
                    full = Path(root) / name
                    rel_in_ds = f"{ds_name}/{full.relative_to(src).as_posix()}"
                    out.append((full, rel_in_ds))
    return out


def materializar(files: list[tuple[Path, str]]) -> list[tuple[Path, str]]:
    """Copia cada archivo seleccionado a dataset/ con su ruta relativa.

    El MANIFEST solo es verificable si las rutas que lista existen en el
    repositorio; sin esto el dataset queda vacio (rutas muertas del ZIP).
    """
    ds = REPO / "dataset"
    copiados: list[tuple[Path, str]] = []
    for full, rel in files:
        dest = ds / rel
        dest.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(full, dest)
        copiados.append((dest, rel))
    return copiados


def main() -> int:
    files = sorted(archivos_seleccionados())
    if not files:
        print("ERROR: no se encontraron archivos en docs/mediciones")
        return 1

    # 1) Los datos reales viven en docs/mediciones; materializalos en dataset/
    materializados = materializar(files)

    # 2) MANIFEST con checksums SHA-256 de los archivos ya en el repo
    manifest = REPO / "dataset" / "MANIFEST.csv"
    rows = []
    for full, rel in materializados:
        rows.append((rel, os.path.getsize(full), sha256(full)))
    with manifest.open("w", newline="\n", encoding="utf-8") as fh:
        w = csv.writer(fh, lineterminator="\n")
        w.writerow(["ruta", "bytes", "sha256"])
        w.writerows(rows)
    print(f"MANIFEST: {len(rows)} archivos -> {manifest}")

    # 2b) MANIFEST.sha256 en formato estandar de sha256sum (<hash>  <ruta>)
    sha_manifest = REPO / "dataset" / "MANIFEST.sha256"
    with sha_manifest.open("w", newline="\n", encoding="utf-8") as fh:
        for rel, size, digest in rows:
            fh.write(f"{digest}  {rel}\n")
    print(f"MANIFEST.sha256: {len(rows)} archivos -> {sha_manifest}")

    # 3) ZIP para subir a Zenodo (mismo contenido que dataset/ del repo)
    DIST.mkdir(exist_ok=True)
    zip_path = DIST / ZIP_NAME
    with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as z:
        for extra in ["README.md", "MANIFEST.csv", "MANIFEST.sha256", "zenodo.json"]:
            z.write(REPO / "dataset" / extra, f"dataset/{extra}")
        for full, rel in materializados:
            z.write(full, f"dataset/{rel}")
    print(f"ZIP: {zip_path} ({os.path.getsize(zip_path)/1e6:.1f} MB)")
    return 0


if __name__ == "__main__":
    sys.exit(main())