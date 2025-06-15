#!/bin/bash

# Obtener el estado de HDMI-A-0 con xrandr y verificar si tiene una resolución activa
status=$(xrandr | grep "HDMI-A-0" | grep -o " connected" | wc -l)

# Verificar si el monitor HDMI-A-0 está activo
if [ "$status" -gt 0 ]; then
    # Verificar si está configurado con una resolución
    resolution=$(xrandr | grep "HDMI-A-0" | grep -oP '\d+x\d+' | wc -l)
    if [ "$resolution" -gt 0 ]; then
        # Si tiene resolución activa, lo desactivamos
        echo "Desactivando HDMI-A-0"
        xrandr --output eDP --auto --primary --output HDMI-A-0 --off
    else
        # Si no tiene resolución activa, lo dejamos
        echo "HDMI-A-0 está conectado pero sin señal, lo activamos"
        # Si no está conectado, lo activamos
        echo "Activando HDMI-A-0"
        xrandr --output eDP --auto --primary --output HDMI-A-0 --auto --right-of eDP
    fi
else
    # Si no está conectado, lo activamos
    echo "Activando HDMI-A-0"
    xrandr --output eDP --auto --primary --output HDMI-A-0 --auto --right-of eDP
fi

# Recargar Qtile para aplicar cambios
qtile cmd-obj -o cmd -f restart
