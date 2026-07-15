#!/usr/bin/env python3
"""Crea los SVG del tema a partir de template-glyph.svg para cada entrada de
glyph-registry.py que tenga hex asignado, siguiendo el mecanismo de GLIFOS.md:
un archivo por nombre exacto de ícono, en scalable/places|emblems|mimetypes/.

Por defecto NO sobrescribe SVG existentes (pueden tener color o tamaño
ajustados a mano); usar --force para regenerarlos. --dry-run muestra qué
haría sin escribir nada.
"""

import argparse
import re
from pathlib import Path

HERE = Path(__file__).parent
TEMPLATE = HERE / "template-glyph.svg"
REGISTRY = HERE / "glyph-registry.py"

# Sección del registro -> subdirectorio de scalable/.
SECTION_DIRS = {
    "places": "places",
    "emblems": "emblems",
    "mimetype_generics": "mimetypes",
    "mimetypes": "mimetypes",
}

GLYPH_ENTITY = re.compile(r"&#x[0-9a-fA-F]+;")
VALID_HEX = re.compile(r"[0-9a-fA-F]{1,6}")


def load_registry() -> dict:
    namespace: dict = {}
    exec(REGISTRY.read_text(), namespace)
    return namespace["glyph_registry"]


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--force", action="store_true", help="sobrescribir SVG existentes")
    parser.add_argument("--dry-run", action="store_true", help="mostrar acciones sin escribir")
    args = parser.parse_args()

    template = TEMPLATE.read_text()
    if not GLYPH_ENTITY.search(template):
        raise SystemExit(f"{TEMPLATE.name}: no se encontró la entidad &#x...; a reemplazar")

    created, skipped, invalid = 0, 0, []
    for section, entries in load_registry().items():
        outdir = HERE / "scalable" / SECTION_DIRS[section]
        outdir.mkdir(parents=True, exist_ok=True)
        for entry in entries:
            hexcode = entry.get("hex")
            if not hexcode:
                continue
            if not VALID_HEX.fullmatch(hexcode):
                invalid.append((entry["name"], hexcode))
                continue
            dest = outdir / f"{entry['name']}.svg"
            if dest.exists() and not args.force:
                skipped += 1
                continue
            action = "crearía" if args.dry_run else "creado"
            if not args.dry_run:
                dest.write_text(GLYPH_ENTITY.sub(f"&#x{hexcode};", template))
            print(f"{action}: {dest.relative_to(HERE)} (hex {hexcode})")
            created += 1

    print(f"\n{created} SVG {'a crear' if args.dry_run else 'creados'}, "
          f"{skipped} existentes sin tocar (usar --force para regenerar)")
    for name, hexcode in invalid:
        print(f"ADVERTENCIA: hex inválido en {name!r}: {hexcode!r} — ignorado")
    if not args.dry_run and created:
        print("Recordar: `thunar -q` y relanzar para refrescar el caché de íconos GTK.")


if __name__ == "__main__":
    main()
