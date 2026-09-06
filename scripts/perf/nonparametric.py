"""Contrastes no parametricos (Bloque C / K1).

La guia de la asignatura exige metodos no parametricos para contrastar las
condiciones cache caliente vs cache frio: U de Mann-Whitney (muestras
independientes) o Wilcoxon (pareadas), mas el d de Cliff como tamano del
efecto. Implementacion propia con aproximacion normal, sin dependencias.
"""

from __future__ import annotations

import math
from itertools import product
from statistics import NormalDist
from typing import List, Sequence, Tuple

_NORMAL = NormalDist()


def mann_whitney_u(x: Sequence[float], y: Sequence[float]) -> Tuple[float, float, float]:
    """U de Mann-Whitney bilateral con aproximacion normal.

    Devuelve (U, z, p). `x` y `y` deben ser muestras independientes.
    """
    muestras = [(v, 0) for v in x] + [(v, 1) for v in y]
    muestras.sort(key=lambda t: t[0])

    rangos: List[float] = [0.0] * len(muestras)
    i = 0
    while i < len(muestras):
        j = i
        while j < len(muestras) and muestras[j][0] == muestras[i][0]:
            j += 1
        rango_empate = (i + 1 + j) / 2.0
        for k in range(i, j):
            rangos[k] = rango_empate
        i = j

    n1, n2 = len(x), len(y)
    r1 = sum(r for r, (_, g) in zip(rangos, muestras) if g == 0)
    u = r1 - n1 * (n1 + 1) / 2.0
    u2 = n1 * n2 - u
    u = min(u, u2)

    mu_u = n1 * n2 / 2.0
    # Correccion por empates en la varianza.
    empates = {}
    for v in muestras:
        empates[v[0]] = empates.get(v[0], 0) + 1
    factor = sum(t ** 3 - t for t in empates.values())
    sigma_u = math.sqrt((n1 * n2 / 12.0) * ((n1 + n2 + 1) - factor / ((n1 + n2) * (n1 + n2 - 1))))

    z = (u - mu_u) / sigma_u if sigma_u else 0.0
    p = 2.0 * (1.0 - _NORMAL.cdf(abs(z)))
    return float(u), float(z), float(p)


def wilcoxon(x: Sequence[float], y: Sequence[float]) -> Tuple[float, float]:
    """Prueba de rangos con signo de Wilcoxon para muestras pareadas.

    Devuelve (W, p) bilateral.
    """
    diferencias = [a - b for a, b in zip(x, y) if a != b]
    if not diferencias:
        return 0.0, 1.0
    n = len(diferencias)
    orden = sorted(diferencias, key=abs)

    rangos: List[float] = [0.0] * n
    i = 0
    while i < n:
        j = i
        while j < n and abs(orden[j]) == abs(orden[i]):
            j += 1
        rango_empate = (i + 1 + j) / 2.0
        for k in range(i, j):
            rangos[k] = rango_empate
        i = j

    w_pos = sum(r for r, d in zip(rangos, orden) if d > 0)
    w_neg = sum(r for r, d in zip(rangos, orden) if d < 0)
    w = min(w_pos, w_neg)

    mu_w = n * (n + 1) / 4.0
    sigma_w = math.sqrt(n * (n + 1) * (2 * n + 1) / 24.0)
    z = (w - mu_w) / sigma_w if sigma_w else 0.0
    p = 2.0 * (1.0 - _NORMAL.cdf(abs(z)))
    return float(w), float(p)


def cliffs_delta(x: Sequence[float], y: Sequence[float]) -> float:
    """d de Cliff: (n_pares[x>y] - n_pares[x<y]) / (n_x * n_y)."""
    if not x or not y:
        return 0.0
    superior = sum(1 for a, b in product(x, y) if a > b)
    inferior = sum(1 for a, b in product(x, y) if a < b)
    return float((superior - inferior) / (len(x) * len(y)))


def interpretar_cliffs_delta(d: float) -> str:
    """Etiqueta de magnitud del efecto segun la escala de Cliff (1993)."""
    ad = abs(d)
    if ad < 0.147:
        return "despreciable"
    if ad < 0.33:
        return "pequeno"
    if ad < 0.474:
        return "mediano"
    return "grande"
