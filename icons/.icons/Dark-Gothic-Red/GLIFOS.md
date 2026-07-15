# Registro de íconos — Dark-Gothic-Red

GTK resuelve íconos por **nombre** (icon theme), no por CSS: cada override es
un SVG con ese nombre exacto. Usar `template-glyph.svg` como base — el "ícono"
es un glifo Nerd Font dentro de `<text>`, coloreado con la paleta de THEME.md.
Todo nombre NO presente acá cae a PlaneDark (herencia), así que se puede
migrar de a poco.

Después de agregar/cambiar un SVG: `thunar -q` y relanzar (GTK cachea íconos
por proceso). El tema se activa en `~/.config/gtk-3.0/settings.ini` →
`gtk-icon-theme-name=Dark-Gothic-Red` (afecta a todas las apps GTK, pero como
hereda PlaneDark solo cambia lo que se overridea).

## scalable/places/ — carpetas y lugares

| Archivo a crear | Qué es | Glifo |
|---|---|---|
| `folder.svg` | Carpeta genérica (la mayoría de la grilla) | f07b |
| `folder-open.svg` | Carpeta expandida (vista árbol) | f07c |
| `user-home.svg` | Home (sidebar y grilla) | f10b5 |
| `user-desktop.svg` | Escritorio | f01c4 |
| `folder-documents.svg` | Documents | f0c82 |
| `folder-download.svg` | Downloads | f024d |
| `folder-music.svg` | Music | f1359 |
| `folder-pictures.svg` | Pictures | f024f |
| `folder-videos.svg` | Videos | f19fa |
| `folder-publicshare.svg` | Public | f19ec |
| `folder-templates.svg` | Templates | f12e3 |
| `drive-harddisk.svg` | File System / discos (sidebar Devices) | f02ca |
| `computer.svg` | Equipo | 󰇅 |
| `drive-removable-media.svg` | USB / removibles | f0553 |
| `user-trash.svg` | Papelera vacía | f06cc |
| `user-trash-full.svg` | Papelera con contenido | f01b4 |
| `folder-remote.svg` | Ubicaciones de red | f08ac |
| `network-workgroup.svg` | Red | f0dd4 |

## scalable/mimetypes/ — LISTA COMPLETA de genéricos

Enumerada desde la base MIME del sistema (`Gio.content_types_get_registered()`,
981 tipos registrados): **cada tipo MIME cae en exactamente uno de estos
genéricos como fallback**. Crear todos los de la tabla "núcleo" cubre
cualquier archivo que aparezca en la grilla de Thunar; los "raros" casi nunca
se ven como archivos.

### Núcleo (lo que se ve a diario)

| Archivo a crear | Tipos que cubre | Ejemplos | Glifo |
|---|---|---|---|
| `text-x-generic.svg` | 183 | txt, csv*, python*, logs, la mayoría de texto plano | f15c |
| `application-x-generic.svg` | 176 | binarios de datos, json-ld, cbor, sqlite, torrents | f15b |
| `image-x-generic.svg` | 135 | png, jpg, webp, svg, raw de cámaras, psd, xcf | f1c5 |
| `x-office-document.svg` | 95 | docx, doc, odt, rtf, **pdf**, **epub**, **md** | f37c |
| `package-x-generic.svg` | 79 | zip, tar, gz, 7z, rar, deb, rpm | f410 |
| `audio-x-generic.svg` | 65 | mp3, flac, ogg, wav, m4a, playlists | f1c7 |
| `video-x-generic.svg` | 45 | mp4, mkv, webm, avi, mov | f1c8 |
| `application-x-executable.svg` | 44 | ELF, exe, AppImage, ROMs de consolas | f471 |
| `text-x-script.svg` | 30 | sh, json, javascript, perl, ruby, lua | |
| `x-office-spreadsheet.svg` | 28 | xlsx, xls, ods, numbers, lotus | f378 |
| `font-x-generic.svg` | 23 | ttf, otf, woff, woff2 | e659 |
| `x-office-presentation.svg` | 14 | pptx, ppt, odp, keynote | f37a |
| `text-html.svg` | 10 | html, xhtml, atom/rss | e736 |

\* csv y los lenguajes de programación tienen nombre exacto propio
(`text-csv`, `text-x-python`…) pero su fallback es `text-x-generic`.

### Raros (completan el 100% — crear solo si molestan)

| Archivo a crear | Tipos | Qué es | Glifo |
|---|---|---|---|
| `x-content-x-generic.svg` | 19 | Contenido de medios removibles (popup de autorun, no archivos) | f15c |
| `multipart-x-generic.svg` | 9 | Partes de mail MIME | f15c |
| `inode-x-generic.svg` | 6 | fifos, sockets, dispositivos de bloque | f15c |
| `media-optical.svg` | 4 | Imágenes ISO / CD | ede9 |
| `text-plain.svg` | 3 | Configs de KDE | f15c |
| `application-x-addon.svg` | 2 | Extensiones systemd (sysext/confext) | ed81 |
| `application-xml.svg` | 2 | kcfg/kxmlgui de KDE | ed81 |
| `text-x-generic-template.svg` | 2 | Plantillas (theme de Office, twig) | eaf0 |
| `application-vnd.visio.svg` | 1 | Visio | |
| `security-high.svg` | 1 | Credencial systemd | ed81 |
| `media-floppy.svg` | 1 | Imagen de floppy | f0249 |

Ya cubiertos en otras secciones: `folder` (inode/directory) y `user-home`
están en places/; `emblem-symbolic-link` (accesos directos .lnk/.url de
Windows) está en emblems/.

### Overrides exactos (opcional, para distinguir un formato puntual)

Como este tema se consulta ANTES que PlaneDark con la lista completa de
candidatos, el genérico ya cubre toda la familia. Un nombre exacto solo hace
falta para darle a UN formato su propio glifo. Regla: **nombre exacto = tipo
MIME con `/` reemplazado por `-`**. Verificados en este sistema:

| Archivo a crear | Formato | Fallback si no existe | Glifo |
|---|---|---|---|
| `application-pdf.svg` | pdf | x-office-document | f0226 |
| `text-markdown.svg` | md | x-office-document | eeab |
| `application-epub+zip.svg` | epub | x-office-document | f02d |
| `text-csv.svg` | csv | text-x-generic | eefc |
| `application-json.svg` | json | text-x-script | e80b |
| `image-svg+xml.svg` | svg | image-x-generic | f03e |
| `application-vnd.openxmlformats-officedocument.wordprocessingml.document.svg` | docx | x-office-document | e6a5 |
| `application-vnd.ms-excel.svg` | xls | x-office-spreadsheet | e6a6 |
| `application-vnd.openxmlformats-officedocument.spreadsheetml.sheet.svg` | xlsx | x-office-spreadsheet | f09f7 |
| `application-x-shellscript.svg` | sh | text-x-script | e760 |
| `text-x-python.svg` | py | text-x-generic | e606 |

## ¿Cómo descubrir el nombre para cualquier otro tipo?

Con un archivo real (no vacío) del tipo en cuestión:

```bash
gio info -a standard::icon archivo.ext
```

Imprime la lista de candidatos en orden de prioridad; crea el SVG con
cualquiera de esos nombres (el genérico cubre la familia completa, el exacto
solo ese formato). Si el archivo está vacío usa:

```bash
python3 -c "from gi.repository import Gio; \
ct,_ = Gio.content_type_guess('archivo.ext', None); \
print(ct, Gio.content_type_get_icon(ct).get_names())"
```

Para regenerar la lista completa de genéricos (p. ej. tras actualizar
shared-mime-info):

```bash
python3 -c "
from gi.repository import Gio
generic = {}
for ct in Gio.content_types_get_registered():
    names = [n for n in Gio.content_type_get_icon(ct).get_names()
             if not n.endswith('-symbolic')]
    if names:
        generic.setdefault(names[-1], []).append(ct)
for g in sorted(generic, key=lambda k: -len(generic[k])):
    print(f'{g}  ({len(generic[g])} tipos)')"
```

## scalable/emblems/ — insignias superpuestas

| Archivo a crear | Qué es | Glifo |
|---|---|---|
| `emblem-symbolic-link.svg` | Flecha azul de symlink (esquina del ícono) | f0337 |

## No necesitan reemplazo

Los íconos de la toolbar (flechas atrás/adelante/arriba, home, lupa) son
**symbolic** (`go-previous-symbolic`, etc.): GTK los recolorea solo con el
color de texto del CSS, así que ya siguen la paleta.
