# Instalación de Arch Linux — Ideapad Gaming (réplica exacta)

Guía de instalación manual desde el USB booteable para replicar este equipo:
**Lenovo Ideapad Gaming — Ryzen 5 5600H (iGPU Radeon) + RTX 3050 Mobile — UEFI — dual boot con Windows en disco separado.**

Todos los valores (particiones, locale, hooks, servicios) fueron verificados contra el sistema real.

---

## 1. Preparar el USB

Descargar la ISO oficial de <https://archlinux.org/download/> y grabarla:

```bash
# Identificar el USB (¡cuidado con elegir el disco equivocado!)
lsblk
sudo dd if=archlinux-x86_64.iso of=/dev/sdX bs=4M status=progress oflag=sync
```

Arrancar desde el USB (F12 en el Ideapad para el boot menu). El equipo es **UEFI**: verificar que el USB arranque en modo UEFI, no legacy.

---

## 2. Consola del instalador

```bash
# El teclado físico es US
loadkeys us

# Confirmar modo UEFI (debe listar archivos; si está vacío, reiniciar en modo UEFI)
ls /sys/firmware/efi/efivars
```

---

## 3. Red en el instalador

Hardware de red de este equipo: Ethernet Realtek RTL8111/8168 y Wi-Fi MediaTek MT7921 (ambos soportados por el kernel de la ISO).

**Por cable**: funciona solo, verificar con `ping archlinux.org`.

**Wi-Fi** con `iwctl`:

```bash
iwctl
[iwd]# device list
[iwd]# station wlan0 scan
[iwd]# station wlan0 get-networks
[iwd]# station wlan0 connect "NombreDeTuRed"
[iwd]# exit
ping archlinux.org
```

Sincronizar el reloj:

```bash
timedatectl set-ntp true
```

---

## 4. Particionado

> **⚠️ CRÍTICO**: este equipo tiene DOS discos NVMe. Windows vive completo en el
> segundo disco (`nvme1n1`: SYSTEM_DRV, WindowsSSD, WINRE_DRV). **No tocarlo.**
> Arch se instala solo en `nvme0n1`. Identificar cuál es cuál con `lsblk -f`
> antes de formatear nada.

Esquema real de `nvme0n1` (GPT):

| Partición | Tipo | Tamaño | Uso |
|---|---|---|---|
| `nvme0n1p1` | ext4 | ~20 GB | `/` (raíz) |
| `nvme0n1p2` | FAT32 (ESP) | ~512 MB | `/boot` |
| `nvme0n1p3` | swap | ~4.7 GB | swap |
| `nvme0n1p6` | ext4 | resto | `/mnt/data` (datos) |

> Nota: 20 GB de raíz quedó justo en este equipo (75 % de uso). Si reinstalás o
> replicás en otra máquina, dale 40–60 GB a `/`.

Crear las particiones con `cfdisk /dev/nvme0n1` (tipo GPT): EFI System para la ESP, Linux swap para la swap, Linux filesystem para el resto.

Formatear y montar:

```bash
mkfs.ext4 /dev/nvme0n1p1
mkfs.fat -F32 /dev/nvme0n1p2
mkswap /dev/nvme0n1p3
mkfs.ext4 /dev/nvme0n1p6      # partición de datos (opcional)

mount /dev/nvme0n1p1 /mnt
mount --mkdir /dev/nvme0n1p2 /mnt/boot
swapon /dev/nvme0n1p3
mount --mkdir /dev/nvme0n1p6 /mnt/mnt/data
```

---

## 5. Instalación base (pacstrap)

```bash
pacstrap -K /mnt base linux linux-firmware amd-ucode \
  networkmanager grub efibootmgr os-prober ntfs-3g \
  base-devel linux-headers git stow sudo nano vim
```

> **`amd-ucode` es obligatorio** en este CPU (Ryzen). En la instalación original
> se omitió por error y el sistema corre sin microcode: esta guía lo corrige.
> El hook `microcode` de mkinitcpio lo integra automáticamente al initramfs.

Generar el fstab:

```bash
genfstab -U /mnt >> /mnt/etc/fstab
# Revisar que las UUID y puntos de montaje tengan sentido
cat /mnt/etc/fstab
```

La copia de referencia del fstab real de este equipo está en `etc/fstab` de este repo (las UUID serán distintas en un disco nuevo — usar siempre las que genere `genfstab`).

---

## 6. Configuración dentro del chroot

```bash
arch-chroot /mnt
```

### Zona horaria y reloj

```bash
ln -sf /usr/share/zoneinfo/America/Lima /etc/localtime
hwclock --systohc
```

### Locale

```bash
# Descomentar en /etc/locale.gen:
#   en_US.UTF-8 UTF-8
sed -i 's/^#en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen
locale-gen
echo 'LANG=en_US.UTF-8' > /etc/locale.conf
```

### Consola y teclado

Valores reales de `/etc/vconsole.conf` de este equipo:

```bash
cat > /etc/vconsole.conf << 'EOF'
KEYMAP=us
XKBLAYOUT=us,latam
EOF
```

(El doble layout `us,latam` con `Win+Space` en X11 lo configura `.xprofile`/`setxkbmap`, ver README.)

### Hostname

```bash
echo 'arch-ideapad-gaming' > /etc/hostname
```

### mkinitcpio

Hooks reales de este sistema (basados en systemd) en `/etc/mkinitcpio.conf`:

```
HOOKS=(base systemd autodetect microcode modconf kms keyboard sd-vconsole block filesystems fsck)
```

```bash
mkinitcpio -P
```

### Contraseña de root y usuario

```bash
passwd

useradd -m -G wheel bubbles
passwd bubbles

# Habilitar sudo para el grupo wheel
EDITOR=nano visudo   # descomentar: %wheel ALL=(ALL:ALL) ALL
```

---

## 7. GRUB (UEFI + dual boot con Windows)

```bash
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
```

Editar `/etc/default/grub` (copia de referencia completa en `etc/default/grub` de este repo). Valores clave del sistema real:

```
GRUB_TIMEOUT=10
GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 quiet"
GRUB_DISABLE_OS_PROBER=false        # detecta el Windows del segundo disco
GRUB_THEME="/boot/grub/themes/dark-gothic-red/theme.txt"   # ver docs/TEMAS.md
```

> El tema `dark-gothic-red` se instala DESPUÉS, al desplegar los dotfiles
> (ver `docs/TEMAS.md`). En esta primera pasada podés dejar `GRUB_THEME`
> comentado y activarlo luego.

```bash
grub-mkconfig -o /boot/grub/grub.cfg
```

Si `os-prober` no detecta Windows en el primer intento, repetir `grub-mkconfig` después del primer arranque (a veces necesita que las particiones NTFS estén visibles).

---

## 8. Red y servicios base

```bash
systemctl enable NetworkManager
systemctl enable systemd-resolved
systemctl enable systemd-timesyncd
```

> **⚠️ No habilitar `dhcpcd`**. En el sistema original quedó habilitado junto a
> NetworkManager y son redundantes/conflictivos: NetworkManager ya gestiona DHCP.

---

## 9. Reiniciar

```bash
exit
umount -R /mnt
reboot
```

Retirar el USB. Debe aparecer GRUB con Arch y Windows.

---

## 10. Post-arranque: multilib y sistema gráfico

Primer login como tu usuario. Conectar red: `nmtui` o `nmcli device wifi connect "Red" password "..."`.

### Habilitar multilib (requerido por lib32-mesa / lib32-nvidia-utils)

Descomentar en `/etc/pacman.conf`:

```
[multilib]
Include = /etc/pacman.d/mirrorlist
```

```bash
sudo pacman -Syu
```

### Drivers GPU (híbrida AMD + NVIDIA de este equipo)

```bash
sudo pacman -S --needed mesa lib32-mesa xf86-video-amdgpu vulkan-radeon \
  nvidia-open nvidia-utils lib32-nvidia-utils linux-firmware-nvidia
```

La iGPU AMD (Cezanne) maneja el escritorio; la RTX 3050 queda disponible para offload (`prime-run` requiere `nvidia-prime` si se quiere usar).

### Xorg + LightDM

```bash
sudo pacman -S --needed xorg-server xorg-xinit xorg-xrandr xorg-xsetroot \
  xorg-setxkbmap lightdm lightdm-webkit2-greeter
sudo systemctl enable lightdm
```

El greeter webkit2 y su tema se configuran en `docs/TEMAS.md`.

### Resto de paquetes

Continuar con **`docs/PAQUETES.md`** para instalar el stack completo del escritorio (AwesomeWM, widgets, audio, apps) y después **`docs/TEMAS.md`** para desplegar toda la personalización.

---

## Verificación final de esta etapa

- [ ] `ls /sys/firmware/efi` → existe (UEFI activo)
- [ ] `grep microcode /proc/cpuinfo | head -1` y `dmesg | grep microcode` → microcode AMD cargado
- [ ] GRUB muestra Arch **y** Windows Boot Manager
- [ ] `timedatectl` → zona `America/Lima`, NTP activo
- [ ] `nmcli general status` → conectado
- [ ] `systemctl is-enabled dhcpcd` → `disabled` o no instalado
- [ ] `localectl` → `LANG=en_US.UTF-8`, keymap `us`
