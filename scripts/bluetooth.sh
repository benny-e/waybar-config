#!/usr/bin/env bash
set -euo pipefail


LOCKFILE="${XDG_RUNTIME_DIR:-/tmp}/rofi-bt.lock"
exec 9>"$LOCKFILE"
flock -n 9 || exit 0

ROFI_THEME="${ROFI_THEME:-$HOME/.config/rofi/bluetooth.rasi}"
SCAN_SECONDS="${SCAN_SECONDS:-5}"
ROFI_PROMPT=" Bluetooth"

die() { printf 'Error: %s\n' "$*" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }

require_deps() {
  have rofi || die "rofi not found"
  have bluetoothctl || die "bluetoothctl not found"
  have notify-send || die "notify-send not found (libnotify)"
  have awk || die "awk not found"
  have timeout || die "timeout not found"
}

notify() {
  notify-send -a "Bluetooth" -u low "Bluetooth" "$1" 2>/dev/null || true
}


bt_powered() {
  timeout 2 bluetoothctl show 2>/dev/null | awk -F': ' '/Powered:/ {print tolower($2)}' | head -n1 || true
}

ensure_power_on() {
  [[ "$(bt_powered || true)" == "yes" ]] || timeout 3 bluetoothctl power on >/dev/null 2>&1 || true
}

toggle_power() {
  if [[ "$(bt_powered || true)" == "yes" ]]; then
    timeout 3 bluetoothctl power off >/dev/null 2>&1 || true
  else
    timeout 3 bluetoothctl power on  >/dev/null 2>&1 || true
  fi
}

main_menu() {
  printf "⏻ Bluetooth On/Off\n󰾰 Devices\n Scan for devices\n" | \
    rofi -dmenu -i -p "$ROFI_PROMPT" -theme "$ROFI_THEME" -hover-select
}

paired_devices() {
  timeout 4 bluetoothctl devices Paired 2>/dev/null | awk '
    /^Device[[:space:]]+[0-9A-Fa-f:]+[[:space:]]+/ {
      mac=$2
      name=""
      for (i=3; i<=NF; i++) name = name (i==3?"":" ") $i
      if (name != "") printf "%s\t%s\n", mac, name
    }'
}

scan_named_nearby() {
  ensure_power_on
  notify "Scanning for devices..."

  timeout 2 bluetoothctl scan on >/dev/null 2>&1 || true

  sleep "$SCAN_SECONDS"

  timeout 2 bluetoothctl scan off >/dev/null 2>&1 || true

  timeout 4 bluetoothctl devices 2>/dev/null | awk '/^Device /{print $2}' | while read -r mac; do
    name="$(timeout 2 bluetoothctl info "$mac" 2>/dev/null | awk -F': ' '/^Name:/ {print $2; exit}')"

    if [[ -z "${name:-}" || "$name" == "(random)" ]]; then
      suf="${mac: -5}"
      name="Unknown ($suf)"
    fi

    printf "%s\t%s\n" "$mac" "$name"
  done
}


to_display_menu() {
  awk -F'\t' '
    NF>=2 {
      mac=$1; name=$2
      count[name]++
      macs[name, count[name]]=mac
      names[name, count[name]]=name
    }
    END {
      for (n in count) {
        if (count[n] == 1) {
          printf "%s\t%s\n", names[n,1], macs[n,1]
        } else {
          for (i=1; i<=count[n]; i++) {
            m=macs[n,i]
            suf=substr(m, length(m)-4)
            printf "%s (%s)\t%s\n", names[n,i], suf, m
          }
        }
      }
    }'
}

choose_mac_from_menu() {
  local menu choice mac
  menu="$(cat)"
  [[ -n "$menu" ]] || return 1

  choice="$(printf "%s\n" "$menu" | cut -f1 | \
    rofi -dmenu -i -p "$ROFI_PROMPT" -theme "$ROFI_THEME" -hover-select)" 
  [[ -n "$choice" ]] || return 1

  mac="$(printf "%s\n" "$menu" | awk -F'\t' -v c="$choice" '$1==c {print $2; exit}')"
  [[ -n "$mac" ]] || return 1
  printf "%s\n" "$mac"
}

device_name_from_mac() {
  local mac="$1"
  timeout 2 bluetoothctl info "$mac" 2>/dev/null | awk -F': ' '/^Name:/ {print $2; exit}' || true
}

is_connected() {
  local mac="$1"

  if timeout 2 bluetoothctl devices Connected 2>/dev/null | awk '{print $2}' | grep -qxF "$mac"; then
    return 0
  fi

  timeout 2 bluetoothctl info "$mac" 2>/dev/null | awk -F': ' '
    /^Connected:/        {c=tolower($2)}
    /^ServicesResolved:/ {s=tolower($2)}
    END {
      if (c=="yes" || s=="yes") exit 0
      exit 1
    }'
}


pair_trust_connect() {
  local mac="$1"
  local name
  name="$(device_name_from_mac "$mac")"
    if [[ -z "${name:-}" ]]; then
    name="$mac"   
    fi

  ensure_power_on
  notify "Connecting..."

  timeout 6 bluetoothctl pair "$mac"    >/dev/null 2>&1 || true
  timeout 4 bluetoothctl trust "$mac"   >/dev/null 2>&1 || true
  timeout 6 bluetoothctl connect "$mac" >/dev/null 2>&1 || true

for _ in {1..6}; do
  if is_connected "$mac"; then
    name2="$(device_name_from_mac "$mac")"
    [[ -n "$name2" ]] && name="$name2"
    notify "Connected"
    return 0
  fi
  sleep 1
done

notify "Failed to connect"
return 1

}

paired_flow() {
  local lines menu mac
  lines="$(paired_devices || true)"
  [[ -n "$lines" ]] || { notify "No paired devices found"; return 0; }

  menu="$(printf "%s\n" "$lines" | to_display_menu)"
  mac="$(printf "%s\n" "$menu" | choose_mac_from_menu || true)"
  [[ -n "${mac:-}" ]] || return 0
  pair_trust_connect "$mac" || true
}

add_device_flow() {
  local lines menu mac
  lines="$(scan_named_nearby || true)"
  [[ -n "$lines" ]] || {
    notify "No named devices found." 
    return 0
  }

  menu="$(printf "%s\n" "$lines" | to_display_menu)"
  mac="$(printf "%s\n" "$menu" | choose_mac_from_menu || true)"
  [[ -n "${mac:-}" ]] || return 0
  pair_trust_connect "$mac" || true
}

main() {
  require_deps
  local sel
  sel="$(main_menu || true)"
  case "$sel" in
    "⏻ Bluetooth On/Off") toggle_power ;;
    "󰾰 Devices")          paired_flow ;;
    " Scan for devices")         add_device_flow ;;
    *) exit 0 ;;
  esac
}

main "$@"

