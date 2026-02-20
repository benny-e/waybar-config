#!/usr/bin/env bash
set -u
set -o pipefail

LAUNCHER_THEME="$HOME/.config/rofi/leftlauncher.rasi"
FOOTER_SCRIPT="$HOME/.config/scripts/power-footer"

PID_LAUNCHER="/run/user/$UID/rofi-launcher.pid"
PID_FOOTER="/run/user/$UID/rofi-footer.pid"
LOCKFILE="/run/user/$UID/rofi-launcher.lock"

kill_pair() {
  for p in "$PID_LAUNCHER" "$PID_FOOTER"; do
    if [[ -f "$p" ]]; then
      pid="$(cat "$p" 2>/dev/null || true)"
      [[ -n "${pid:-}" ]] && kill "$pid" 2>/dev/null || true
      rm -f "$p" 2>/dev/null || true
    fi
  done
}

exec 9>"$LOCKFILE"
if ! flock -n 9; then
  exit 0
fi

trap 'kill_pair' INT TERM

kill_pair

rofi -show drun \
  -theme "$LAUNCHER_THEME" \
  -hover-select \
  -pid "$PID_LAUNCHER" \
  -on-cancel "$HOME/.config/scripts/killrofis.sh" &
launcher_pid=$!

"$FOOTER_SCRIPT" &
footer_script_pid=$!

wait -n "$launcher_pid" "$footer_script_pid" 2>/dev/null || true
kill_pair

wait "$launcher_pid" 2>/dev/null || true
wait "$footer_script_pid" 2>/dev/null || true

