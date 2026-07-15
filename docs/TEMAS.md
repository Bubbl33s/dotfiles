# Reconciliación de temas personalizados — Dark Gothic Red

Cómo desplegar TODA la personalización visual de este repo en una máquina nueva, y cómo está conectada cada pieza. La paleta y las decisiones de diseño están documentadas en `THEME.md`; esta guía cubre el **despliegue**.

Hay dos categorías:

1. **Nivel usuario** — se despliega con `stow` (symlinks al repo, se actualiza solo con `git pull`)
2. **Nivel sistema** — requiere copia manual como root (GRUB, LightDM); si se edita el tema en el repo hay que **re-copiar**

---

## 1. Despliegue con stow (nivel usuario)

```bash
cd ~/dotfiles
stow shell        # .bashrc, .xprofile, .gtkrc-2.0, .bash_profile, .profile, .xinitrc
stow --no-folding config   # todo ~/.config (--no-folding evita que GTK/apps escriban dentro del repo)
stow icons        # ~/.icons: Dark-Gothic-Red, Yaru-Pink, PlaneDark
stow themes       # ~/.themes: Yaru-Pink, Yaru-Pink-dark, Yaru-Pink-light (GTK)
stow local        # ~/.local/share/rofi/themes (imports de rofi)
stow fonts        # ~/.fonts y ~/.local/share/fonts (Nerd Fonts del tema)
stow wallpapers   # ~/Pictures/bg
fc-cache -fv      # regenerar cache de fuentes
```

> Si stow reporta conflictos es porque ya existe un archivo real en el destino:
> revisarlo, respaldarlo y borrarlo antes de re-stowear. Nunca pisar a ciegas.

> `etc/` NO se stowea en otra máquina: contiene fstab, hosts y **conexiones WiFi
> con contraseñas** de este equipo. Es copia de referencia. Por lo mismo, este
> repo debe permanecer **privado**.

---

## 2. La cadena GTK (Thunar y apps GTK)

Piezas y quién manda:

| Archivo (repo) | Qué controla |
|---|---|
| `config/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml` | **Fuente autoritativa** del tema si corre `xfsettingsd`: tema GTK, iconos, fuente, cursor |
| `config/.config/gtk-3.0/settings.ini` | Fallback GTK3 sin xfsettingsd: `Yaru-Pink-dark` + iconos `Dark-Gothic-Red` + fuente Cantarell |
| `shell/.gtkrc-2.0` | Apps GTK2: `Yaru-Pink-dark` + iconos `PlaneDark` |
| `config/.config/gtk-3.0/gtk.css` | Loader de CSS de usuario: importa `dark-gothic-red-thunar.css` |
| `config/.config/gtk-3.0/dark-gothic-red-thunar.css` | Skin Dark Gothic Red de Thunar (scoped solo a Thunar) |
| `config/.config/Thunar/uca.xml` + `accels.scm` | Acciones custom y atajos de Thunar |
| `config/.config/xfce4/.../thunar.xml` | Preferencias de vista de Thunar |

Requisitos: `stow themes` (provee Yaru-Pink-dark en `~/.themes`), `stow icons` (Dark-Gothic-Red y PlaneDark en `~/.icons`) y `papirus-icon-theme` (paquete, lo usa rofi).

**Verificar**: abrir Thunar → toolbar/sidebar oscuros con acentos rojos e iconos Dark-Gothic-Red. Si sale GTK por defecto: ¿existe `~/.themes/Yaru-Pink-dark`? ¿`gsettings`/xsettings pisando la config? (`xfsettingsd` debe estar corriendo o no, pero consistente con qué archivo esperás que mande).

---

## 3. Iconos Dark-Gothic-Red (mimetypes)

Tema de iconos propio en `icons/.icons/Dark-Gothic-Red/`:

- `GLIFOS.md` — registro de glifos hechos y pendientes
- `glyph-registry.py` + `generate-glyph-svgs.py` / `generate-glyph-registry.py` — generadores: los SVG de mimetypes se generan desde el registry (editar el registry, no los SVG a mano)
- Tras agregar iconos: `gtk-update-icon-cache ~/.icons/Dark-Gothic-Red` (si hay cache) y reiniciar Thunar (`thunar -q`)

---

## 4. AwesomeWM (barra, bordes, wallpaper)

- Fuente de verdad del tema: `config/.config/awesome/theme/init.lua` (paleta, fuente UbuntuMono Nerd Font, geometría de la barra vertical)
- El wallpaper lo pinta awesome: `theme.wallpaper = "/home/bubbles/Pictures/bg/1329229.png"` — **ruta absoluta**: si el usuario no es `bubbles`, editar esa línea
- Los wallpapers se despliegan con `stow wallpapers` (la config legacy de nitrogen también está trackeada pero nitrogen ya no se usa)
- Recargar: `Mod+Ctrl+r`; validar sintaxis: `awesome -k`

## 5. Rofi

Cadena de imports: `config.rasi` → `theme-gothic.rasi` → `@import "rounded-common.rasi"` que resuelve en `~/.local/share/rofi/themes/` → **requiere `stow local`**. Iconos: Papirus (paquete).

**Verificar**: `rofi -show drun` abre con el tema gothic. Si abre con el tema por defecto o da error de import, falta `stow local`.

## 6. Ranger, terminal y prompt

| Pieza | Repo | Activación |
|---|---|---|
| Ranger colorscheme `dark_gothic_red` | `config/.config/ranger/colorschemes/` | `rc.conf` ya lo setea |
| Alacritty (colores + opacidad) | `config/.config/alacritty/` | directo |
| oh-my-posh tema `dark-gothic-red` | `config/.config/oh-my-posh/` | lo carga `.bashrc` |
| fastfetch (logo custom) | `config/.config/fastfetch/` | lo lanza `.bashrc` |
| Dunst (notificaciones temáticas) | `config/.config/dunst/` | reiniciar dunst |
| Picom (sombras/blur) | `config/.config/picom.conf` | reiniciar picom |
| Neovim `yozakura` | `config/.config/nvim/` | primer arranque instala plugins |

## 7. GRUB (nivel sistema — copia manual)

El tema vive en `grub/dark-gothic-red/` (background, fuentes `.pf2`, `theme.txt`):

```bash
sudo mkdir -p /boot/grub/themes
sudo cp -r ~/dotfiles/grub/dark-gothic-red /boot/grub/themes/

# En /etc/default/grub (copia de referencia completa: etc/default/grub):
#   GRUB_THEME="/boot/grub/themes/dark-gothic-red/theme.txt"
sudo grub-mkconfig -o /boot/grub/grub.cfg
```

**Verificar**: al reiniciar, GRUB muestra fondo gótico y tipografía propia (las `.pf2` del tema).

## 8. LightDM + greeter webkit2 (nivel sistema — copia manual)

Tema del greeter en `lightdm/dark-gothic-red/` (usa `background.png` — sincronizado con el desplegado):

```bash
sudo pacman -S --needed lightdm lightdm-webkit2-greeter
sudo mkdir -p /usr/share/lightdm-webkit/themes
sudo cp -r ~/dotfiles/lightdm/dark-gothic-red /usr/share/lightdm-webkit/themes/

# 1) /etc/lightdm/lightdm.conf  (copia de referencia: etc/lightdm/lightdm.conf)
#      greeter-session = lightdm-webkit2-greeter
# 2) /etc/lightdm/lightdm-webkit2-greeter.conf  (referencia: etc/lightdm-webkit2-greeter.conf)
#      webkit_theme = dark-gothic-red
sudo cp ~/dotfiles/etc/lightdm/lightdm.conf /etc/lightdm/lightdm.conf
sudo cp ~/dotfiles/etc/lightdm-webkit2-greeter.conf /etc/lightdm/lightdm-webkit2-greeter.conf
```

**Verificar** sin reiniciar: `lightdm --test-mode --debug` en una TTY, o directamente `sudo systemctl restart lightdm` (cierra la sesión). Debe aparecer el greeter gótico con avatar y fondo PNG.

> **Regla de sincronización**: el tema desplegado en `/usr/share/lightdm-webkit/themes/`
> y `/boot/grub/themes/` NO se actualiza solo. Tras editar el tema en el repo,
> repetir la copia. Si se edita en el sistema directamente, traer los cambios de
> vuelta al repo antes de commitear otra cosa (así se detectó y corrigió un drift
> de `background.jpeg` vs `background.png` en julio 2026).

---

## Checklist completo de replicación de temas

- [ ] `stow shell config icons themes local fonts wallpapers` sin conflictos
- [ ] `fc-list | grep -i "UbuntuMono Nerd"` → fuente del tema disponible
- [ ] Thunar con skin Dark Gothic Red e iconos custom
- [ ] `rofi -show drun` con tema gothic
- [ ] Barra vertical de awesome con glifos correctos (fuente Nerd)
- [ ] Ranger con colorscheme rojo (`ranger`)
- [ ] Prompt oh-my-posh degradado rojo al abrir terminal
- [ ] GRUB con tema al reiniciar
- [ ] Greeter LightDM gótico
- [ ] Wallpaper cargado por awesome (si el usuario ≠ `bubbles`, editar `theme/init.lua`)
