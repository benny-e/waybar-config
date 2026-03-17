#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.config"
BACKUP_SUFFIX="$(date +%Y%m%d-%H%M%S)"

PACKAGES=(
  waybar
  rofi
  networkmanager
  bluez
  bluez-utils
  blueman
  pipewire
  pipewire-pulse
  wireplumber
  playerctl
  pacman-contrib
  brightnessctl
  ttf-jetbrains-mono
  ttf-jetbrains-mono-nerd
)

backup_if_exists() {
  local target="$1"

  if [[ -e "$target" ]]; then
    echo "[*] Backing up $target -> ${target}.bak-${BACKUP_SUFFIX}"
    mv "$target" "${target}.bak-${BACKUP_SUFFIX}"
  fi
}

copy_config_dir() {
  local source_dir="$1"
  local target_dir="$2"

  if [[ ! -d "$source_dir" ]]; then
    echo "[!] Missing source directory: $source_dir"
    exit 1
  fi

  echo "[*] Copying $(basename "$source_dir") -> $target_dir"
  cp -r "$source_dir" "$target_dir"
}

echo "[*] Checking for pacman..."
if ! command -v pacman >/dev/null 2>&1; then
  echo "[!] This install script is intended for Arch-based systems."
  exit 1
fi

echo "[*] Refreshing package databases..."
sudo pacman -Syy

echo "[*] Installing dependencies..."
sudo pacman -S --needed --noconfirm "${PACKAGES[@]}"

echo "[*] Enabling services..."
sudo systemctl enable NetworkManager
sudo systemctl enable bluetooth

mkdir -p "$CONFIG_DIR"

backup_if_exists "$CONFIG_DIR/waybar"
backup_if_exists "$CONFIG_DIR/rofi"

copy_config_dir "$SCRIPT_DIR/waybar" "$CONFIG_DIR"
copy_config_dir "$SCRIPT_DIR/rofi" "$CONFIG_DIR"

echo "[✓] Installation complete."
echo
echo "Config installed to:"
echo "  $CONFIG_DIR/waybar"
echo "  $CONFIG_DIR/rofi"
