# Arch Linux Dotfiles — Setup Reutilizable

Guía paso a paso para recrear mi entorno Arch Linux desde cero en cualquier máquina.
Arrancás con `archinstall` y terminás con mi escritorio Qtile + esquema de colores rosa/púrpura.

> **Diferencias entre máquinas**: solo drivers GPU y nombres de monitores. Todo lo demás es idéntico.

---

## Esquema de colores

| Componente     | Tema / Paleta                                            |
|----------------|----------------------------------------------------------|
| WM (Qtile)     | Paleta custom rosa: `#13000a` bg, `#bf6b99`/`#b33b72` accent |
| Prompt (bash)  | oh-my-posh `dark-gothic-red` (degradado rojo, trackeado en `config/.config/oh-my-posh/`) |
| Launcher (Rofi)| `rounded-pink-dark` (`#EC407A` accent)                   |
| Terminal       | Alacritty (opacidad 0.95)                                 |
| Editor (Neovim)| `yozakura` (`night_blue`, bg `#1a1a26`)                  |
| ls colors      | vivid genera paleta `dracula` para eza                    |
| Ranger         | `dracula`                                                |
| Iconos         | Papirus-icon-theme + Yaru-Pink custom                     |
| Wallpaper      | `/home/bubbles/Pictures/bg/1338905.jpeg` (fondo `#000000`)|
| Fuente         | UbuntuMono Nerd Font (Qtile, Alacritty, Rofi)            |

---

## 0. Punto de partida — archinstall

Ejecutá `archinstall` en el ISO de Arch. Configurá:

- **Perfil**: `minimal` (solo base, sin escritorio)
- **Kernel**: `linux` + `linux-headers`
- **Bootloader**: `grub` (UEFI)
- **Audio**: `pipewire`
- **Red**: `NetworkManager`
- **Usuarios**: tu usuario + sudo
- **Paquetes adicionales en archinstall**:
  ```
  git stow xorg-server xorg-xinit xorg-xrandr xorg-xsetroot
  lightdm lightdm-gtk-greeter qtile picom rofi alacritty
  ttf-dejavu-nerd noto-fonts-emoji papirus-icon-theme
  network-manager-applet
  ```

> Esto te deja con Xorg, Qtile, LightDM y lo mínimo para arrancar el WM. El resto de paquetes se instala en los pasos siguientes.

---

## 1. Sistema base (post-archinstall)

```bash
sudo pacman -Syu
sudo pacman -S --needed base-devel linux-headers linux-firmware \
  efibootmgr os-prober ntfs-3g fuse2 \
  acpi brightnessctl lshw powertop usbutils \
  dos2unix zip unzip unrar atool \
  nano vim sudo stow git git-filter-repo
```

---

## 2. Drivers GPU (elige según tu hardware)

**AMD** (Ideadpad Gaming):
```bash
sudo pacman -S vulkan-radeon xf86-video-amdgpu
```

**Intel** (ThinkCentre):
```bash
sudo pacman -S vulkan-intel xf86-video-intel
```

**NVIDIA**:
```bash
sudo pacman -S nvidia-open nvidia-utils linux-firmware-nvidia
```

---

## 3. Xorg completo

```bash
sudo pacman -S --needed \
  xorg-server xorg-server-devel xorg-server-xephyr \
  xorg-server-xnest xorg-server-xvfb \
  xorg-xinit xorg-xrandr xorg-xsetroot xorg-xset \
  xorg-xbacklight xorg-xdpyinfo xorg-xev xorg-xinput \
  xorg-xkill xorg-xprop xorg-xwayland xorg-xwd xorg-xwininfo \
  xorg-font-util xorg-fonts-100dpi xorg-fonts-75dpi xorg-fonts-misc \
  xorg-mkfontscale xorg-xcursorgen xorg-xlsfonts \
  xorg-iceauth xorg-sessreg xorg-smproxy \
  xorg-x11perf xorg-xcmsdb xorg-xdriinfo xorg-xgamma \
  xorg-xhost xorg-xkbevd xorg-xkbprint xorg-xkbutils \
  xorg-xlsatoms xorg-xlsclients xorg-xpr xorg-xrefresh \
  xorg-xvinfo xorg-xwud xsel xclip xdotool
```

---

## 4. Display Manager — LightDM

```bash
sudo pacman -S --needed lightdm lightdm-gtk-greeter \
  lightdm-gtk-greeter-settings lightdm-webkit2-greeter
```

---

## 5. Window Manager — Qtile

Qtile ya se instaló en archinstall. Paquetes que lo acompañan:

```bash
sudo pacman -S --needed \
  picom rofi alacritty dunst \
  feh nitrogen arandr \
  python-pyqt6 python-pyqt6-webengine \
  python-psutil python-xlib python-pip python-pipx \
  python-colorama python-colour python-requests
```

---

## 6. Audio

```bash
sudo pacman -S --needed pipewire pipewire-alsa pipewire-pulse wireplumber \
  alsa-plugins alsa-utils pamixer pavucontrol pulseaudio volumeicon
```

---

## 7. Red

```bash
sudo pacman -S --needed networkmanager network-manager-applet \
  dhcpcd nmap proxychains-ng systemd-resolvconf
```

---

## 8. Bluetooth

```bash
sudo pacman -S --needed bluez bluez-utils blueman
```

---

## 9. Fuentes

```bash
sudo pacman -S --needed ttf-dejavu-nerd noto-fonts-emoji
yay -S ttf-meslo-nerd-font-powerlevel10k ttf-ubuntu-mono-nerd
```

---

## 10. Iconos

```bash
sudo pacman -S papirus-icon-theme
# Yaru-Pink se incluye vía stow icons/ desde este repo
```

---

## 11. Apps de sistema

```bash
sudo pacman -S --needed \
  thunar tumbler ffmpegthumbnailer engrampa udiskie ueberzug \
  flameshot scrot xterm terminator \
  lxappearance notification-daemon xdg-desktop-portal \
  xdg-desktop-portal-gtk xdg-user-dirs \
  vlc w3m rclone spotify-launcher \
  libreoffice-fresh drawio-desktop \
  fastfetch chafa htop tree eza mediainfo poppler highlight \
  ranger atool zip unzip unrar
```

---

## 12. Dev tools

```bash
sudo pacman -S --needed \
  neovim docker cmake scons \
  jdk17-openjdk jdk21-openjdk maven \
  postgresql kafka trivy \
  pandoc-cli dpkg
```

---

## 13. Navegadores

```bash
sudo pacman -S --needed firefox
yay -S brave-bin google-chrome
```

---

## 14. yay + paquetes AUR

```bash
cd /tmp
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si

yay -S --needed \
  oh-my-posh vivid nvm pyenv \
  anydesk-bin debtap docker-desktop jetbrains-toolbox \
  pixelorama slack-desktop visual-studio-code-bin zoom
```

---

## 15. Periféricos Razer (opcional)

```bash
# Solo si usás teclado/mouse Razer
sudo pacman -S openrazer-daemon python-openrazer
yay -S polychromatic
```

---

## 16. Clonar dotfiles y stow

```bash
cd ~
git clone <url-de-tu-repo-dotfiles> dotfiles
cd dotfiles
git checkout <rama>    # ideapad-gaming o think-center

# Stowear módulos
stow shell
stow config
stow icons
# stow etc   # SOLO si es la misma máquina (fstab, hosts, wifi)
```

> `etc/` contiene fstab, hosts y conexiones WiFi personales. No stowear en otra máquina.

---

## 17. Shell — bash + oh-my-posh

Al stowear `shell/`, tu `.bashrc` ya tiene:

- Prompt **oh-my-posh** con tema propio `dark-gothic-red` (`~/.config/oh-my-posh/`)
- `shopt -s nocaseglob` → autocompletado case-insensitive
- `HISTCONTROL=ignoreboth` → no duplica comandos, ignora los que empiezan con espacio
- `HISTSIZE=10000` / `HISTFILESIZE=20000` → historial grande
- Aliases de **eza** con íconos (`ls`, `ll`, `la`, `tree`)
- `LS_COLORS` generado con **vivid** (paleta dracula)
- **pyenv** y **nvm** inicializados automáticamente
- Git bash completion
- `fastfetch` al abrir terminal (config en `~/.config/fastfetch/`)

---

## 18. Qtile — configuración de monitores

```bash
mkdir -p ~/.screenlayout

# Creá tu script de monitores según la salida de xrandr
# Ejemplo laptop + HDMI:
cat > ~/.screenlayout/monitors.sh << 'EOF'
#!/bin/bash
xrandr --output eDP-1 --auto --primary --output HDMI-1 --auto --right-of eDP-1
EOF
chmod +x ~/.screenlayout/monitors.sh
```

Editar `~/.config/qtile/toggle_monitors.sh` con los nombres reales de tus monitores (ejecutá `xrandr` para verlos).

Atajo en Qtile: `mod + shift + m` lanza el toggle.

---

## 19. Neovim — NvChad + Yozakura

Al abrir `nvim` por primera vez, lazy.nvim instala todo automáticamente.
Si algo falla: `:Lazy sync`.

Incluye:
- Tema `yozakura` (paleta `night_blue`, bg `#1a1a26`)
- LSP, autocompletado, formateo con conform.nvim
- Atajos personalizados en `mappings.lua`

---

## 20. Teclado — US (principal) + latam

Doble layout con **inglés US como principal** y español latinoamericano como secundario.

El `.xsession` lo configura automáticamente al iniciar Qtile:
```bash
setxkbmap -layout us,latam -option grp:win_space_toggle
```

- **`Win + Space`**: cambia entre US English y español latam
- **US English**: primer layout, el que usás para programar
- **Latam**: segundo layout, para tildes, eñes y signos en español

Para verificar que funciona:
```bash
setxkbmap -query            # muestra layout actual
setxkbmap -print            # muestra configuración completa
```

Si querés ver un indicador visual del layout actual, podés agregar un widget de teclado en la barra de Qtile.

---

## 21. Servicios systemd

```bash
sudo systemctl enable lightdm
sudo systemctl enable NetworkManager
sudo systemctl enable bluetooth
sudo systemctl enable docker
sudo systemctl enable systemd-resolved
sudo systemctl enable openrazer-daemon    # solo si usás Razer
```

---

## 22. Post-instalación — Checklist

- [ ] `sudo pacman -Syu` (actualizar todo)
- [ ] Drivers GPU correctos según hardware
- [ ] `xrandr` → editar `~/.screenlayout/monitors.sh` y `~/.config/qtile/toggle_monitors.sh`
- [ ] `stow shell && stow config && stow icons`
- [ ] `startx` o reiniciar LightDM → Qtile debería arrancar
- [ ] `nvim` y esperar que instale plugins
- [ ] `nitrogen ~/Pictures/bg` para wallpaper
- [ ] WiFi con `nmtui` o applet de NetworkManager
- [ ] Sincronizar navegadores (Brave, Chrome, Firefox)
- [ ] JetBrains Toolbox (`jetbrains-toolbox` desde AUR)

---

## Máquinas

| Rama               | Máquina         | GPU    | Monitores              |
|--------------------|-----------------|--------|------------------------|
| `think-center`     | ThinkCentre PC  | Intel  | HDMI3 + DP3 (VGA)      |
| `ideapad-gaming`   | Ideapad Gaming  | AMD    | Por definir (ver xrandr)|
