#!/usr/bin/env bash
set -euo pipefail

PID_LAUNCHER="/run/user/$UID/rofi-launcher.pid"
PID_FOOTER="/run/user/$UID/rofi-footer.pid"

kill_pidfile() {
  local f="$1"
  [[ -f "$f" ]] || return 0
  local pid
  pid="$(cat "$f" 2>/dev/null || true)"
  if [[ -n "${pid:-}" ]]; then
    kill "$pid" 2>/dev/null || true
  fi
  rm -f "$f" 2>/dev/null || true
}

kill_pidfile "$PID_LAUNCHER"
kill_pidfile "$PID_FOOTER"

pkill -u "$UID" -x rofi 2>/dev/null || true

