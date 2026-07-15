#!/usr/bin/env python3
"""Genera glyph-registry.py: inventario completo de nombres de ícono y tipos
MIME del sistema con su glifo Nerd Font asignado.

Fuente de datos: Gio (base MIME del sistema) + /usr/share/mime/globs2.
Los hex ya documentados en GLIFOS.md están hardcodeados en KNOWN.

Regeneración segura: los `hex` no-None ya presentes en glyph-registry.py se
preservan, así que se puede re-ejecutar tras actualizar shared-mime-info sin
perder asignaciones hechas a mano en el registro.

Para crear los SVG a partir del registro: generate-glyph-svgs.py.
"""

import json
import re
from collections import defaultdict
from pathlib import Path

from gi.repository import Gio

HERE = Path(__file__).parent
OUT = HERE / "glyph-registry.py"
GLOBS2 = Path("/usr/share/mime/globs2")

# Hex y descripciones ya registrados (fuente: GLIFOS.md).
# name -> (hex | None, descripción, ejemplos | None)
PLACES = [
    ("folder", "f07b", "Carpeta genérica (la mayoría de la grilla)"),
    ("folder-open", "f07c", "Carpeta expandida (vista árbol)"),
    ("user-home", "f10b5", "Home (sidebar y grilla)"),
    ("user-desktop", "f01c4", "Escritorio"),
    ("folder-documents", "f0c82", "Documents"),
    ("folder-download", "f024d", "Downloads"),
    ("folder-music", "f1359", "Music"),
    ("folder-pictures", "f024f", "Pictures"),
    ("folder-videos", "f19fa", "Videos"),
    ("folder-publicshare", "f19ec", "Public"),
    ("folder-templates", "f12e3", "Templates"),
    ("drive-harddisk", "f02ca", "File System / discos (sidebar Devices)"),
    ("computer", "f01c5", "Equipo"),
    ("drive-removable-media", "f0553", "USB / removibles"),
    ("user-trash", "f06cc", "Papelera vacía"),
    ("user-trash-full", "f01b4", "Papelera con contenido"),
    ("folder-remote", "f08ac", "Ubicaciones de red"),
    ("network-workgroup", "f0dd4", "Red"),
]

EMBLEMS = [
    ("emblem-symbolic-link", "f0337", "Flecha de symlink (esquina del ícono)"),
]

# Genéricos de mimetypes: hex, descripción y ejemplos de GLIFOS.md.
GENERICS = {
    "text-x-generic": ("f15c", "Texto plano", ["txt", "csv", "py", "log"]),
    "application-x-generic": ("f15b", "Binarios de datos", ["json-ld", "cbor", "sqlite", "torrent"]),
    "image-x-generic": ("f1c5", "Imágenes", ["png", "jpg", "webp", "svg", "psd", "xcf"]),
    "x-office-document": ("f37c", "Documentos de oficina", ["docx", "doc", "odt", "rtf", "pdf", "epub", "md"]),
    "package-x-generic": ("f410", "Archivos comprimidos y paquetes", ["zip", "tar", "gz", "7z", "rar", "deb", "rpm"]),
    "audio-x-generic": ("f1c7", "Audio", ["mp3", "flac", "ogg", "wav", "m4a"]),
    "video-x-generic": ("f1c8", "Video", ["mp4", "mkv", "webm", "avi", "mov"]),
    "application-x-executable": ("f471", "Ejecutables", ["ELF", "exe", "AppImage", "ROMs"]),
    "text-x-script": (None, "Scripts y código", ["sh", "json", "js", "perl", "rb", "lua"]),
    "x-office-spreadsheet": ("f378", "Hojas de cálculo", ["xlsx", "xls", "ods", "numbers"]),
    "font-x-generic": ("e659", "Fuentes tipográficas", ["ttf", "otf", "woff", "woff2"]),
    "x-office-presentation": ("f37a", "Presentaciones", ["pptx", "ppt", "odp", "key"]),
    "text-html": ("e736", "HTML y feeds", ["html", "xhtml", "atom", "rss"]),
    "x-content-x-generic": ("f15c", "Contenido de medios removibles (popup de autorun)", None),
    "multipart-x-generic": ("f15c", "Partes de mail MIME", None),
    "inode-x-generic": ("f15c", "fifos, sockets, dispositivos de bloque", None),
    "media-optical": ("ede9", "Imágenes ISO / CD", None),
    "text-plain": ("f15c", "Configs de KDE", None),
    "application-x-addon": ("ed81", "Extensiones systemd (sysext/confext)", None),
    "application-xml": ("ed81", "kcfg/kxmlgui de KDE", None),
    "text-x-generic-template": ("eaf0", "Plantillas (theme de Office, twig)", None),
    "application-vnd.visio": (None, "Visio", None),
    "security-high": ("ed81", "Credencial systemd", None),
    "media-floppy": ("f0249", "Imagen de floppy", None),
    "folder": ("f07b", "inode/directory (ya cubierto en places)", None),
    "user-home": ("f10b5", "Ya cubierto en places", None),
    "emblem-symbolic-link": ("f0337", "Accesos directos .lnk/.url (ya cubierto en emblems)", None),
}

# Overrides exactos ya registrados: nombre exacto (MIME con / -> -) -> hex.
EXACT = {
    "application-pdf": "f0226",
    "text-markdown": "eeab",
    "application-epub+zip": "f02d",
    "text-csv": "eefc",
    "application-json": "e80b",
    "image-svg+xml": "f03e",
    "application-vnd.openxmlformats-officedocument.wordprocessingml.document": "e6a5",
    "application-vnd.ms-excel": "e6a6",
    "application-vnd.openxmlformats-officedocument.spreadsheetml.sheet": "f09f7",
    "application-x-shellscript": "e760",
    "text-x-python": "e606",
}


def load_existing_hex() -> dict[str, str]:
    """Lee los hex no-None del registro existente para no pisarlos al regenerar."""
    if not OUT.exists():
        return {}
    found = {}
    pattern = re.compile(r'\{ "name": "([^"]+)".*?"hex": "([^"]+)"')
    for line in OUT.read_text().splitlines():
        m = pattern.search(line)
        if m:
            found[m.group(1)] = m.group(2)
    return found


def load_extensions() -> dict[str, list[str]]:
    """mime type -> extensiones/patrones desde globs2 (orden por peso desc)."""
    exts: dict[str, list[str]] = defaultdict(list)
    if not GLOBS2.exists():
        return exts
    for line in GLOBS2.read_text().splitlines():
        if line.startswith("#") or not line.strip():
            continue
        parts = line.split(":")
        if len(parts) < 3:
            continue
        mime, pattern = parts[1], parts[2]
        ext = pattern[2:] if pattern.startswith("*.") else pattern
        if ext and ext not in exts[mime]:
            exts[mime].append(ext)
    return exts


def entry_line(name: str, description: str, examples: list[str] | None, hexcode: str | None) -> str:
    fields = [f'"name": {json.dumps(name)}', f'"description": {json.dumps(description, ensure_ascii=False)}']
    if examples:
        fields.append(f'"examples": {json.dumps(examples[:6])}')
    fields.append(f'"hex": {json.dumps(hexcode) if hexcode else "None"}')
    return "    { " + ", ".join(fields) + " },"


def main() -> None:
    existing = load_existing_hex()
    extensions = load_extensions()

    def hex_for(name: str, default: str | None) -> str | None:
        return existing.get(name) or default

    # Agrupar los tipos MIME registrados por su genérico de fallback.
    families: dict[str, list[str]] = defaultdict(list)
    for ct in Gio.content_types_get_registered():
        names = [n for n in Gio.content_type_get_icon(ct).get_names() if not n.endswith("-symbolic")]
        if names:
            families[names[-1]].append(ct)
    for cts in families.values():
        cts.sort()

    lines = [
        "# Registro de glifos Nerd Font para el tema de íconos Dark-Gothic-Red.",
        "# Generado por generate-glyph-registry.py — regenerar tras actualizar",
        '# shared-mime-info. Editar a mano SOLO el campo "hex" (se preserva al',
        "# regenerar). Ver GLIFOS.md para el mecanismo de resolución GTK.",
        "#",
        "# Campos por entrada:",
        '#   "name": nombre de ícono GTK o tipo MIME exacto (/ reemplazado por -)',
        '#   "description": qué es / qué cubre',
        '#   "examples": extensiones o formatos que cubre (solo si aplican)',
        '#   "hex": codepoint Nerd Font (ej. "f0226"); None = pendiente',
        "#",
        "# Para crear los SVG de las entradas con hex: generate-glyph-svgs.py.",
        "",
        "glyph_registry = {",
    ]

    lines.append("    # ── scalable/places/ — carpetas y lugares ──")
    lines.append('    "places": [')
    for name, hexcode, desc in PLACES:
        lines.append("    " + entry_line(name, desc, None, hex_for(name, hexcode)))
    lines.append("    ],")
    lines.append("")

    lines.append("    # ── scalable/emblems/ — insignias superpuestas ──")
    lines.append('    "emblems": [')
    for name, hexcode, desc in EMBLEMS:
        lines.append("    " + entry_line(name, desc, None, hex_for(name, hexcode)))
    lines.append("    ],")
    lines.append("")

    # Genéricos ordenados por cantidad de tipos que cubren (prioridad real).
    ordered_families = sorted(families, key=lambda f: -len(families[f]))

    lines.append("    # ── scalable/mimetypes/ — genéricos (fallback de familia) ──")
    lines.append("    # Ordenados por cantidad de tipos MIME que cubren.")
    lines.append('    "mimetype_generics": [')
    for family in ordered_families:
        hexcode, desc, examples = GENERICS.get(family, (None, "Genérico sin documentar en GLIFOS.md", None))
        desc = f"{desc} ({len(families[family])} tipos)"
        lines.append("    " + entry_line(family, desc, examples, hex_for(family, hexcode)))
    lines.append("    ],")
    lines.append("")

    lines.append("    # ── Tipos MIME exactos — nombre de override: tipo con / reemplazado por - ──")
    lines.append("    # Solo hace falta crear el SVG exacto para distinguir UN formato de su")
    lines.append("    # familia; el genérico ya cubre el resto. Agrupados por familia genérica.")
    lines.append('    "mimetypes": [')
    total = 0
    for family in ordered_families:
        lines.append(f"        # ── {family} ({len(families[family])} tipos) ──")
        for ct in families[family]:
            name = ct.replace("/", "-")
            desc = Gio.content_type_get_description(ct)
            lines.append("    " + entry_line(name, desc, extensions.get(ct), hex_for(name, EXACT.get(name))))
            total += 1
    lines.append("    ],")
    lines.append("}")
    lines.append("")

    OUT.write_text("\n".join(lines))
    print(f"{OUT.name}: {total} tipos MIME, {len(ordered_families)} genéricos, "
          f"{len(existing)} hex preservados del archivo anterior")


if __name__ == "__main__":
    main()
