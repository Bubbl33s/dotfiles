#!/usr/bin/env python3
"""Custom rofi script-mode launcher: shows installed apps with a Nerd Font
glyph (from app-icons.map) instead of rofi's native image-based icons.

Protocol: https://github.com/davatorium/rofi/blob/next/doc/rofi-script.5.markdown
"""

import os
import re
import shlex
import subprocess
import sys
from pathlib import Path
from xml.sax.saxutils import escape

MAP_FILE = Path.home() / ".config" / "rofi" / "app-icons.map"
DESKTOP_DIRS = [
    Path.home() / ".local/share/applications",
    Path("/usr/share/applications"),
    Path("/var/lib/flatpak/exports/share/applications"),
]
FIELD_CODE_RE = re.compile(r"%[fFuUick]")

# Vertical nudge for the glyph relative to the app name's baseline, in Pango
# `rise` units (1/1024 pt). Negative moves the glyph DOWN, positive moves it
# UP. Tune this by hand: change the number, save, then reopen the launcher.
ICON_RISE = "-1024"


def normalize(s):
    return re.sub(r"[\s\-_.]", "", s.lower())


def load_icon_map():
    entries = []  # (normalized_key, glyph, normalized_class_override)
    default_glyph = ""
    if not MAP_FILE.exists():
        return entries, default_glyph
    for line in MAP_FILE.read_text().splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        parts = line.split("|")
        key = parts[0].strip()
        glyph = parts[1].strip() if len(parts) > 1 else ""
        override = parts[2].strip() if len(parts) > 2 else ""
        if key == "default":
            default_glyph = glyph
            continue
        entries.append((normalize(key), glyph, normalize(override) if override else None))
    entries.sort(key=lambda e: len(e[0]), reverse=True)
    return entries, default_glyph


def glyph_for_name(name, entries, default_glyph):
    norm_name = normalize(name)
    for key, glyph, _override in entries:
        if key in norm_name:
            return glyph or default_glyph
    return default_glyph


def parse_desktop_file(path):
    fields = {}
    in_entry_group = False
    for line in path.read_text(errors="ignore").splitlines():
        if line.startswith("["):
            in_entry_group = line.strip() == "[Desktop Entry]"
            continue
        if not in_entry_group or "=" not in line:
            continue
        k, _, v = line.partition("=")
        fields.setdefault(k.strip(), v.strip())
    return fields


def collect_apps():
    seen_ids = set()
    apps = {}  # display name -> fields
    for d in DESKTOP_DIRS:
        if not d.is_dir():
            continue
        for f in sorted(d.glob("*.desktop")):
            if f.name in seen_ids:
                continue
            seen_ids.add(f.name)
            fields = parse_desktop_file(f)
            if fields.get("NoDisplay") == "true" or fields.get("Hidden") == "true":
                continue
            if "Exec" not in fields or "Name" not in fields:
                continue
            if fields.get("Type", "Application") != "Application":
                continue
            apps[fields["Name"]] = fields
    return apps


def build_exec_command(fields):
    exec_line = FIELD_CODE_RE.sub("", fields["Exec"]).strip()
    if fields.get("Terminal") == "true":
        term = os.environ.get("TERMINAL", "alacritty")
        return [term, "-e", "sh", "-c", exec_line]
    return shlex.split(exec_line)


def main():
    entries, default_glyph = load_icon_map()
    apps = collect_apps()

    selected = sys.argv[1] if len(sys.argv) > 1 else None
    if selected:
        fields = apps.get(selected)
        if fields:
            cmd = build_exec_command(fields)
            subprocess.Popen(
                cmd,
                start_new_session=True,
                stdin=subprocess.DEVNULL,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )
        return

    # markup-rows lets each row's `display` value use Pango markup (needed
    # for the glyph's rise nudge below) while the row's plain text -- the
    # app name -- stays what filtering matches and what comes back on
    # selection, instead of re-parsing a "glyph  name" string by hand.
    print("\0markup-rows\x1ftrue")
    for name in sorted(apps, key=str.lower):
        glyph = glyph_for_name(name, entries, default_glyph)
        display = f'<span rise="{ICON_RISE}">{escape(glyph)}</span>  {escape(name)}'
        print(f"{name}\0display\x1f{display}")


if __name__ == "__main__":
    main()
