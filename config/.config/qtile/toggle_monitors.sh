#!/bin/bash

# Detectar monitores conectados
hdmi_conectado=$(xrandr | grep "HDMI3 connected" | wc -l)
vga_conectado=$(xrandr | grep "DP3 connected" | wc -l)

# Verificar si DP3 tiene resolución activa (está encendido)
vga_activo=$(xrandr | grep "DP3 connected" | grep -oP '\d+x\d+' | wc -l)

echo "HDMI3 conectado: $hdmi_conectado"
echo "VGA (DP3) conectado: $vga_conectado"
echo "VGA (DP3) activo: $vga_activo"

# Si ambos están conectados
if [ "$hdmi_conectado" -gt 0 ] && [ "$vga_conectado" -gt 0 ]; then
    # Toggle: si DP3 está activo, apagarlo; si está apagado, encenderlo
    if [ "$vga_activo" -gt 0 ]; then
        echo "Apagando DP3 - Solo HDMI3"
        xrandr --output HDMI3 --mode 1920x1080 --primary \
               --output DP3 --off
    else
        echo "Encendiendo DP3 - Dual monitor"
        xrandr --output HDMI3 --mode 1920x1080 --primary \
               --output DP3 --mode 1366x768 --left-of HDMI3
    fi
    
elif [ "$hdmi_conectado" -gt 0 ]; then
    echo "Solo HDMI3 disponible"
    xrandr --output HDMI3 --mode 1920x1080 --primary \
           --output DP3 --off
    
elif [ "$vga_conectado" -gt 0 ]; then
    echo "Solo DP3 (VGA) disponible"
    xrandr --output DP3 --mode 1366x768 --primary \
           --output HDMI3 --off
else
    echo "No hay monitores detectados"
fi

# Recargar Qtile
qtile cmd-obj -o cmd -f restart