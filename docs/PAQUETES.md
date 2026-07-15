# Paquetes y utilidades del sistema

Todo lo que este escritorio necesita para funcionar, agrupado por función y con la razón de cada dependencia. Complementa a `docs/INSTALACION-ARCH.md` (sistema base) y a `docs/TEMAS.md` (personalización).

Las listas completas y actuales viven en la raíz del repo:

- **`sistema_oficial.txt`** — paquetes explícitos de repos oficiales (`pacman -Qqen`)
- **`paquetes_aur.txt`** — paquetes explícitos de AUR (`pacman -Qqem`)

## Restauración rápida (todo de una vez)

```bash
# Repos oficiales (requiere multilib habilitado, ver INSTALACION-ARCH.md)
sudo pacman -S --needed - < sistema_oficial.txt

# AUR (instalar yay primero, ver sección yay)
yay -S --needed - < paquetes_aur.txt
```

Para regenerar las listas en el futuro:

```bash
pacman -Qqen > sistema_oficial.txt
pacman -Qqem > paquetes_aur.txt
```

---

## yay (helper de AUR) — instalar primero

```bash
cd /tmp
git clone https://aur.archlinux.org/yay.git
cd yay && makepkg -si
```

---

## Escritorio: AwesomeWM y su ecosistema

El WM principal es **`awesome-git`** (AUR — la config usa APIs de la rama master de Awesome 4.3+, la versión de repos oficiales NO alcanza):

```bash
yay -S awesome-git
```

Acompañantes del WM:

| Paquete | Rol |
|---|---|
| `picom` | Compositor (sombras, blur, transparencia — config en `config/.config/picom.conf`) |
| `rofi` | Launcher (`Mod+d`) y powermenu (`config/.config/rofi/`) |
| `dunst` | Notificaciones (config temática en `config/.config/dunst/`) |
| `alacritty` | Terminal (la config de awesome lanza `alacritty`) |
| `feh` | Visor de imágenes / wallpaper de respaldo (el wallpaper lo pinta awesome directamente vía `theme.wallpaper`) |
| `qtile` | WM secundario, se conserva como sesión alternativa en LightDM |

```bash
sudo pacman -S --needed picom rofi dunst alacritty feh qtile
```

## Dependencias de los widgets de la barra de AwesomeWM

Cada widget de la barra depende de un binario externo. **Sin estos paquetes la barra pierde funciones**:

| Paquete | Widget / atajo que lo usa |
|---|---|
| `playerctl` | Widget de música (mediaplayer): play/pause, título vía MPRIS |
| `pamixer` | Widget/atajos de volumen (`XF86Audio*`) |
| `brightnessctl` | Atajos de brillo (`XF86MonBrightness*`) |
| `network-manager-applet` (`nm-applet`) | Applet de red en el systray |
| `volumeicon` | Icono de volumen en el systray (lo lanza `.xprofile`) |
| `flameshot` | Capturas de pantalla (`flameshot gui`) |
| `acpi` | Widget de batería |
| `lm_sensors` | Temperaturas (correr `sudo sensors-detect` una vez) |
| `blueman` + `bluez` | Bluetooth (applet + stack; habilitar `bluetooth.service`) |
| `xorg-setxkbmap` | Doble layout `us,latam` con `Win+Space` |
| `upower` | Información fina de batería (opcional, mejora el widget) |

```bash
sudo pacman -S --needed playerctl pamixer brightnessctl \
  network-manager-applet volumeicon flameshot acpi lm_sensors \
  blueman bluez bluez-utils xorg-setxkbmap
```

## Audio — PipeWire

```bash
sudo pacman -S --needed pipewire pipewire-alsa pipewire-pulse wireplumber \
  alsa-utils pavucontrol
```

Sin PulseAudio: `pipewire-pulse` lo reemplaza. `pamixer` y `pavucontrol` hablan con PipeWire por la capa pulse.

## Gestor de archivos — Thunar

```bash
sudo pacman -S --needed thunar tumbler ffmpegthumbnailer engrampa udiskie
```

- `tumbler` + `ffmpegthumbnailer`: miniaturas
- `engrampa`: archivos comprimidos desde el menú contextual
- `udiskie`: montaje automático de USB
- El tema visual de Thunar (CSS + iconos + xfconf) se despliega en `docs/TEMAS.md`

## Terminal y shell

| Paquete | Rol |
|---|---|
| `eza` | Reemplazo de `ls` con iconos (aliases en `.bashrc`) |
| `vivid` | Genera `LS_COLORS` |
| `fastfetch` | Banner al abrir la terminal (logo custom en `config/.config/fastfetch/`) |
| `ranger` | File manager TUI (colorscheme propio `dark_gothic_red`) |
| `oh-my-posh` (AUR) | Prompt (tema `dark-gothic-red` en `config/.config/oh-my-posh/`) |
| `htop` | Monitor (config trackeada) |

```bash
sudo pacman -S --needed eza vivid fastfetch ranger htop chafa highlight atool
yay -S oh-my-posh
```

## Fuentes

Las fuentes críticas del tema (**UbuntuMono Nerd Font**, JetBrainsMono Nerd Font, Monaspace, icons-in-terminal) **ya están trackeadas en este repo** (paquete stow `fonts/`) — se despliegan con `stow fonts` y no requieren paquete del sistema. Complementos de repos:

```bash
sudo pacman -S --needed ttf-dejavu-nerd noto-fonts-emoji
fc-cache -fv   # tras stowear fonts/
```

## Editor — Neovim

```bash
sudo pacman -S --needed neovim
# La config (NvChad + tema yozakura) está en config/.config/nvim
# Al primer arranque lazy.nvim instala todo; si falla: :Lazy sync
```

## Utilidades de pantalla y sesión

```bash
sudo pacman -S --needed autorandr arandr xdg-user-dirs xdg-desktop-portal xdg-desktop-portal-gtk
```

- `autorandr`: perfiles de monitores ya trackeados (`docked`, `laptop-only`, `mobile`)
- `xdg-user-dirs`: respeta `config/.config/user-dirs.dirs`

## Apps de uso diario

```bash
sudo pacman -S --needed firefox vlc libreoffice-fresh rclone spotify-launcher discord
yay -S --needed google-chrome brave-bin visual-studio-code-bin slack-desktop zoom
```

## Dev tools

```bash
sudo pacman -S --needed docker cmake jdk17-openjdk jdk21-openjdk maven \
  postgresql kafka github-cli nvm pyenv
yay -S --needed jetbrains-toolbox docker-desktop
```

## Periféricos Razer (opcional)

```bash
sudo pacman -S openrazer-daemon python-openrazer
yay -S polychromatic
sudo systemctl enable openrazer-daemon
```

Configs de `openrazer`/`polychromatic` en `~/.config` (no trackeadas — regenerables desde la GUI).

---

## Servicios systemd a habilitar

```bash
sudo systemctl enable lightdm NetworkManager bluetooth \
  systemd-resolved systemd-timesyncd
# Según uso:
sudo systemctl enable docker postgresql kafka sshd
```

> **No habilitar `dhcpcd`** (conflicto con NetworkManager, ver INSTALACION-ARCH.md).

---

## Checklist de dependencias de la config

- [ ] `awesome -k` → `OK` (sintaxis de la config)
- [ ] `playerctl status` responde con un reproductor abierto (widget música)
- [ ] `pamixer --get-volume` responde (widget volumen)
- [ ] `brightnessctl g` responde (atajos de brillo)
- [ ] `flameshot gui` abre el capturador
- [ ] `acpi -b` muestra la batería (widget batería)
- [ ] `rofi -show drun` abre el launcher con tema gothic (requiere `stow local`, ver TEMAS.md)
- [ ] `fc-list | grep -i "UbuntuMono Nerd"` encuentra la fuente del tema
