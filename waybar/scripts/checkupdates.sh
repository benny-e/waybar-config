#!/usr/bin/env bash

# Pacman updates
repo=$(checkupdates 2>/dev/null | wc -l)

# AUR updates
if command -v yay >/dev/null 2>&1; then
    aur=$(yay -Qua 2>/dev/null | wc -l)
else
    aur=0
fi

# Flatpak updates
if command -v flatpak >/dev/null 2>&1; then
    flatpak_updates=$(flatpak remote-ls --updates 2>/dev/null | wc -l)
else
    flatpak_updates=0
fi

# Total for severity (pacman + aur only)
total=$((repo + aur))

if [ "$total" -lt 30 ]; then
    echo ""
    exit
fi

class="low"

if [ "$total" -ge 150 ]; then
    class="high"
elif [ "$total" -ge 80 ]; then
    class="medium"
fi

echo "{\"text\":\"󰚰\",\"tooltip\":\"Pacman: $repo\nAUR: $aur\nFlatpak: $flatpak_updates\",\"class\":\"$class\"}"
