# ~/.config/rofi/powermenu.sh
#!/bin/bash

chosen=$(echo -e "⏻ Shutdown\n Reboot\n Suspend\n Lock\n Logout" | rofi -dmenu -i -p "Power")

case "$chosen" in
"⏻ Shutdown") systemctl poweroff ;;
" Reboot") systemctl reboot ;;
" Suspend") systemctl suspend ;;
" Lock") i3lock ;; # or betterlockscreen, etc.
" Logout") qtile cmd-obj -o cmd -f shutdown ;;
esac
