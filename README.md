# Arch Linux Dotfiles — Dark Gothic Red

Repo para replicar mi entorno completo de Arch Linux: **AwesomeWM + tema Dark Gothic Red** sobre X11, con LightDM (greeter webkit2), Thunar, Ranger, Neovim y theming propio de punta a punta (GRUB → greeter → escritorio → terminal).

> ⚠️ Este repo contiene conexiones WiFi con contraseñas en `etc/`. **Mantener privado.**

## Guías

| Guía | Contenido |
|---|---|
| [`docs/INSTALACION-ARCH.md`](docs/INSTALACION-ARCH.md) | Instalación de Arch desde el USB booteable, específica de este equipo (UEFI, dual boot Windows, GPU híbrida AMD+NVIDIA, red, X11, LightDM) |
| [`docs/PAQUETES.md`](docs/PAQUETES.md) | Todos los paquetes por función y de qué widget/config son dependencia, con restauración desde las listas |
| [`docs/TEMAS.md`](docs/TEMAS.md) | Despliegue y reconciliación de todos los temas personalizados (stow + copias a nivel sistema) |
| [`THEME.md`](THEME.md) | Sistema de diseño Dark Gothic Red: paleta, tipografía, geometría |

## Estructura (paquetes stow)

| Paquete | Destino | Contenido |
|---|---|---|
| `shell/` | `~/` | `.bashrc`, `.xprofile`, `.gtkrc-2.0`, `.bash_profile`, `.profile`, `.xinitrc`, oh-my-bash |
| `config/` | `~/.config/` | awesome, alacritty, rofi, dunst, picom, ranger, nvim, gtk-2/3, Thunar, xfce4/xfconf, fastfetch, oh-my-posh, autorandr, htop, volumeicon, fontconfig, mimeapps, qtile (legacy) |
| `icons/` | `~/.icons/` | **Dark-Gothic-Red** (tema de iconos propio + generadores), Yaru-Pink, PlaneDark |
| `themes/` | `~/.themes/` | Yaru-Pink / -dark / -light (temas GTK, no existen en repos) |
| `local/` | `~/.local/share/` | Temas de rofi (imports requeridos por `theme-gothic.rasi`) |
| `fonts/` | `~/.fonts`, `~/.local/share/fonts` | UbuntuMono Nerd Font, JetBrainsMono Nerd Font, Monaspace, icons-in-terminal |
| `wallpapers/` | `~/Pictures/bg/` | Wallpapers (awesome carga el fondo desde acá) |
| `etc/` | — (referencia) | fstab, hosts, `default/grub`, lightdm confs, WiFi. **No stowear en otra máquina** |
| `grub/` | — (copia manual) | Tema GRUB dark-gothic-red (ver TEMAS.md) |
| `lightdm/` | — (copia manual) | Tema greeter webkit2 dark-gothic-red (ver TEMAS.md) |

## Réplica rápida (máquina ya instalada)

```bash
git clone git@github.com:Bubbl33s/dotfiles.git ~/dotfiles
cd ~/dotfiles

# 1. Paquetes (ver docs/PAQUETES.md)
sudo pacman -S --needed - < sistema_oficial.txt
yay -S --needed - < paquetes_aur.txt

# 2. Desplegar configs
stow shell
stow --no-folding config
stow icons themes local fonts wallpapers
fc-cache -fv

# 3. Temas a nivel sistema (GRUB + LightDM): seguir docs/TEMAS.md
```

## Esquema de colores actual

| Componente | Tema |
|---|---|
| WM (AwesomeWM) | Dark Gothic Red — fuente de verdad en `config/.config/awesome/theme/init.lua` |
| GTK / Thunar | Yaru-Pink-dark + CSS propio `dark-gothic-red-thunar.css` |
| Iconos | Dark-Gothic-Red (propio) / Papirus (rofi) / PlaneDark (gtk2) |
| GRUB / LightDM | dark-gothic-red (propios) |
| Prompt | oh-my-posh `dark-gothic-red` |
| Rofi | `theme-gothic` (import `rounded-common.rasi`) |
| Ranger | `dark_gothic_red` |
| Neovim | `yozakura` (NvChad) |
| Fuente | UbuntuMono Nerd Font |

## Teclado

Doble layout **US (principal) + latam**, toggle con `Win+Space` (lo configura `.xprofile` vía `setxkbmap -layout us,latam -option grp:win_space_toggle`).

## Máquinas

| Rama | Máquina | GPU |
|---|---|---|
| `main` | Ideapad Gaming (actual) | AMD iGPU + RTX 3050 |
| `think-center` | ThinkCentre PC | Intel |

Las listas de paquetes se regeneran con `pacman -Qqen > sistema_oficial.txt` y `pacman -Qqem > paquetes_aur.txt`.
