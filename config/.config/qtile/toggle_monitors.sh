#!/bin/bash

PRIMARY="eDP"
EXTERNAL="HDMI-A-0"

# Detectar monitores conectados
primary_conectado=$(xrandr | grep "$PRIMARY connected" | wc -l)
externo_conectado=$(xrandr | grep "$EXTERNAL connected" | wc -l)

# Verificar si el externo tiene resolución activa (está encendido)
externo_activo=$(xrandr | grep -A1 "$EXTERNAL connected" | grep -c '\*')

echo "$PRIMARY conectado: $primary_conectado"
echo "$EXTERNAL conectado: $externo_conectado"
echo "$EXTERNAL activo: $externo_activo"

# Si ambos están conectados
if [ "$primary_conectado" -gt 0 ] && [ "$externo_conectado" -gt 0 ]; then
    # Toggle: si el externo está activo, apagarlo; si está apagado, encenderlo
    if [ "$externo_activo" -gt 0 ]; then
        echo "Apagando $EXTERNAL - Solo $PRIMARY"
        xrandr --output "$PRIMARY" --auto --primary \
               --output "$EXTERNAL" --off
    else
        echo "Encendiendo $EXTERNAL - Dual monitor"
        xrandr --output "$PRIMARY" --auto --primary \
               --output "$EXTERNAL" --auto --left-of "$PRIMARY"
    fi

elif [ "$primary_conectado" -gt 0 ]; then
    echo "Solo $PRIMARY disponible"
    xrandr --output "$PRIMARY" --auto --primary \
           --output "$EXTERNAL" --off

elif [ "$externo_conectado" -gt 0 ]; then
    echo "Solo $EXTERNAL disponible"
    xrandr --output "$EXTERNAL" --auto --primary \
           --output "$PRIMARY" --off
else
    echo "No hay monitores detectados"
fi

# Recargar Awesome
echo 'awesome.restart()' | awesome-client