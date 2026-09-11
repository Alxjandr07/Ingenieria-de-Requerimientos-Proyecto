"""Genera docs/entorno/versions.txt con las versiones de las herramientas."""
import platform
import shutil
import subprocess
from datetime import datetime


def run(cmd):
    try:
        out = subprocess.run(cmd, capture_output=True, text=True, timeout=30, shell=True)
        return out.stdout.strip().splitlines()[0] if out.stdout.strip() else "N/A"
    except Exception:
        return "N/A"


lines = []
lines.append("# SGROAS - Versiones del entorno de ejecucion")
lines.append(f"# Generado: {datetime.now().isoformat(timespec='seconds')}")
lines.append("")
lines.append(f"Sistema operativo: {platform.system()} {platform.release()} ({platform.version()})")
lines.append(f"Arquitectura: {platform.machine()}")
lines.append("")

tools = [
    ("Docker", ["docker", "--version"]),
    ("Docker Compose", ["docker", "compose", "version", "--short"]),
    ("Java (JDK)", ["java", "-version"]),
    ("Maven (mvnw)", ["cmd", "/c", "mvnw.cmd", "-version"]),
    ("Node.js", ["node", "--version"]),
    ("npm", ["npm", "--version"]),
    ("Angular CLI", ["cmd", "/c", "npx", "ng", "version"]),
    ("Python", ["python", "--version"]),
    ("k6", ["k6", "version"]),
    ("Git", ["git", "--version"]),
]

for name, cmd in tools:
    lines.append(f"{name}: {run(cmd)}")

print("\n".join(lines))
