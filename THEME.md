# Tema: Dark Gothic Red

Paleta y estilo visual usado en todo el setup (AwesomeWM + picom), portado
originalmente de qtile. Fuente única de verdad real: `config/.config/awesome/theme/init.lua`
— esto es solo un resumen rápido para no tener que abrirlo cada vez.

## Paleta de colores

| Clave  | Hex       | Uso                                              |
|--------|-----------|---------------------------------------------------|
| `w`    | `#ffffff` | Blanco puro (fills, ej. barra de volumen)          |
| `b`    | `#000000` | Negro puro (pill de power)                         |
| `l`    | `#f2eaea` | Texto principal (near-white)                       |
| `d`    | `#050001` | Fondo general (near-black)                         |
| `t`    | `#cf91b5` | Acento pastel (texto secundario/minimizado)        |
| `c_2`  | `#b70803` | Rojo brillante — urgente/highlight (secundario)     |
| `c_1`  | `#e81509` | Rojo brillante — urgente/highlight                 |
| `c1`   | `#7a1f20` | Rojo oscuro                                        |
| `c2`   | `#5c1717` | Rojo más oscuro (foco de ventana)                  |
| `c3`   | `#3f0f10` | Rojo profundo oscuro                               |
| `c4`   | `#300c0d` | Fondo de la mayoría de los pills de la barra        |
| `c5`   | `#20080a` | Rojo casi negro (bordes normales, barra de volumen) |

## Tipografía

- Fuente base: **UbuntuMono Nerd Font**
- Cuerpo: `12pt` normal / `10pt` bold
- Taglist: `14pt`
- Tasklist: `10pt` bold
- Flechas de esquina (conectan barra horizontal/vertical): `24pt`
- Menús (power menu, etc): `12pt` bold

## Bordes y geometría

- `useless_gap`: `8px` (separación entre ventanas)
- `border_width`: `4px`
- Bordes de ventana: normal = `c4`, activa = `c2`, marcada = `c5`
- Radio de esquina — barra: `6px` · clientes: `8px` · menús: `6px`
- Alto de la barra (wibar): `30px`, margen superior `10px`, margen lateral `15px`

## Sombras y blur (picom)

- Sombra: radius `15`, offset `(-15, -15)`, opacity `0.5`
- Corner-radius global: `10`
- Blur de fondo activado (incluye frame)
- Sin sombra/blur en: tooltips, dropdowns, popup menus (mantienen el look flat)

## Pills de la barra (fondo por grupo)

Todos usan `c4` salvo el de power:

- `icon_bg` (wifi + volumen compartido), `battery_bg`, `layoutname_bg`,
  `kblayout_bg`, `date_bg`, `time_bg` → `c4`
- `power_bg` → `b` (negro puro, se destaca del resto)

## Iconos

Nerd Font glyphs, definidos en `theme/icons.lua`. Categorías:

- **Flechas/separadores powerline**: hard/soft left-right (estilo qtile arrows.py)
- **Wifi**: 5 niveles de señal (`wifi_0`..`wifi_4`), + variante "sin internet" por nivel
- **Bluetooth**: off / on / connected (3 estados)
- **Volumen**: up/down (triángulos Unicode simples, no PUA — no dependen del Nerd Font)
- **Batería**: 10 niveles (10-100), + variantes charging, + crítico, + full-charged
- **Teclado**: glyph + layout abreviado a 2 letras (ej. "us", "la")
- **Reloj**: 12 glyphs, uno por hora (reloj analógico), + calendario
- **Tags/distro**: tag genérico + logo Arch

## Terminal

Toda la terminal usa esta misma paleta, trackeada en el repo:

- **Alacritty** (`config/.config/alacritty/alacritty.toml`): bloque `[colors]`
  completo — fondo `d`, texto `l`, rojos del tema en los ANSI + auxiliares
  desaturados (verde musgo, ámbar, azul grisáceo, magenta hacia `t`) para
  que el rojo domine sin perder legibilidad.
- **oh-my-posh** (`config/.config/oh-my-posh/dark-gothic-red.omp.json`):
  derivado de `velvet`, gradiente `d → c5 → c3 → c2 → c1`, separadores
  powerline en punta (``/``, no los curvos).
- **fastfetch** (`config/.config/fastfetch/config.jsonc`): reemplaza a
  neofetch con el mismo layout de árbol; logo por imagen vía chafa
  (colocar `logo.png` junto al config y activar el bloque comentado).

## Estilo de barra

Powerline: pills con separadores en flecha (`theme/arrows.lua`), sin bordes
redondeados agresivos — flat, no gothic-ornamentado. Cada pill de la barra
vertical se fuerza al mismo ancho (`wibar_height`) para que los íconos
centrados alineen en la misma línea vertical.

## Thunar (GTK3)

Thunar usa la paleta del tema vía CSS de usuario, sin tocar el resto de apps
GTK (que siguen en Yaru-Pink-dark; `settings.ini` queda local, sin trackear,
porque lxappearance lo reescribe y rompería el symlink):

- `config/.config/gtk-3.0/gtk.css` — loader, solo hace `@import`.
- `config/.config/gtk-3.0/dark-gothic-red-thunar.css` — todas las reglas
  scoped a `.thunar`; paleta declarada una vez como `@define-color dgr_*`.

| Superficie              | Color                                             |
|-------------------------|---------------------------------------------------|
| Fondo / texto           | `d` / `l`                                         |
| Selección (+sin foco)   | `c2` (`c3` en backdrop)                           |
| Hover                   | `c5`–`c3`                                         |
| Toolbar/pathbar/status  | `c4` con bordes `c5`                              |
| Acentos                 | `t` (texto secundario); `c_1` solo rubber-band,   |
|                         | drop target, borde de entry con foco              |

Limitaciones: menús contextuales, tooltips y diálogos son toplevels propios
sin la clase `.thunar` → conservan Yaru-Pink-dark. Recargar con `thunar -q`.

Los íconos NO son CSS: los resuelve el icon theme por nombre. Para eso existe
`icons/.icons/Dark-Gothic-Red/` (activo en `settings.ini`, hereda PlaneDark):
cada override es un SVG con un glifo Nerd Font adentro — ver
`GLIFOS.md` (registro de nombres pendientes) y `template-glyph.svg` ahí mismo.

En una máquina nueva donde `~/.config/gtk-3.0` no exista aún, usar
`stow --no-folding config` (o pre-crear el dir) para que GTK no escriba
`bookmarks` dentro del repo.
