#!/usr/bin/env bash
set -euo pipefail

FOOTER_THEME="$HOME/.config/rofi/power-footer.rasi"

#menu options
choices=$(
  printf "  \n󰍃\n  \n  \n"
)

sel="$(echo -e "$choices" | rofi -dmenu \
  -theme "$FOOTER_THEME" \
  -no-custom -i \
  -pid "/run/user/$UID/rofi-footer.pid" \
  -kb-cancel "Escape" \
  -kb-quit "" \
  -on-cancel "~/.config/scripts/killrofis.sh" \
  -hover-select 
)"

case "$sel" in
  "  ")  hyprlock ;;
  "󰍃")  hyprctl dispatch exit ;;      
  "  ")  systemctl reboot ;;
  "  ")  systemctl poweroff ;;
  *) exit 0 ;;
esac


