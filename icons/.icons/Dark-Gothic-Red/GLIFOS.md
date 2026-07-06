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
| `folder.svg` | Carpeta genérica (la mayoría de la grilla) | |
| `folder-open.svg` | Carpeta expandida (vista árbol) | |
| `user-home.svg` | Home (sidebar y grilla) | |
| `user-desktop.svg` | Escritorio | |
| `folder-documents.svg` | Documents | |
| `folder-download.svg` | Downloads | |
| `folder-music.svg` | Music | |
| `folder-pictures.svg` | Pictures | |
| `folder-videos.svg` | Videos | |
| `folder-publicshare.svg` | Public | |
| `folder-templates.svg` | Templates | |
| `drive-harddisk.svg` | File System / discos (sidebar Devices) | |
| `computer.svg` | Equipo | |
| `drive-removable-media.svg` | USB / removibles | |
| `user-trash.svg` | Papelera vacía | |
| `user-trash-full.svg` | Papelera con contenido | |
| `folder-remote.svg` | Ubicaciones de red | |
| `network-workgroup.svg` | Red | |

## scalable/mimetypes/ — tipos de archivo

| Archivo a crear | Qué es | Glifo |
|---|---|---|
| `text-x-generic.svg` | Archivo de texto / genérico (fallback más usado) | |
| `text-x-script.svg` | Scripts de shell | |
| `application-x-executable.svg` | Ejecutables | |
| `image-x-generic.svg` | Imágenes | |
| `video-x-generic.svg` | Videos | |
| `audio-x-generic.svg` | Audio | |
| `package-x-generic.svg` | Archivos comprimidos (tar, zip) | |
| `application-pdf.svg` | PDF | |
| `text-html.svg` | HTML | |
| `font-x-generic.svg` | Fuentes | |

## scalable/mimetypes/ — documentos y ofimática

Thunar resuelve por tipo MIME con una lista de candidatos en orden: primero
el nombre exacto del MIME, después el genérico de familia. Como este tema se
consulta ANTES que PlaneDark con la lista completa, basta el genérico para
cubrir toda la familia; el exacto solo hace falta si se quiere distinguir un
formato puntual.

| Archivo a crear | Cubre | Glifo |
|---|---|---|
| `x-office-document.svg` | docx, doc, odt, rtf (y fallback de epub/md) | |
| `x-office-spreadsheet.svg` | xlsx, xls, ods | |
| `x-office-presentation.svg` | pptx, odp | |
| `text-markdown.svg` | md (opcional, si no cae en x-office-document) | |
| `application-epub+zip.svg` | epub (opcional, ídem) | |
| `text-csv.svg` | csv (opcional; su fallback es text-x-generic) | |

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

## scalable/emblems/ — insignias superpuestas

| Archivo a crear | Qué es | Glifo |
|---|---|---|
| `emblem-symbolic-link.svg` | Flecha azul de symlink (esquina del ícono) | |

## No necesitan reemplazo

Los íconos de la toolbar (flechas atrás/adelante/arriba, home, lupa) son
**symbolic** (`go-previous-symbolic`, etc.): GTK los recolorea solo con el
color de texto del CSS, así que ya siguen la paleta.
