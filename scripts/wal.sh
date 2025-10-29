#!/bin/bash
# Usage: ./wal.sh /path/to/image

CONF=~/.config/hypr/hyprpaper.conf

if [ -z "$1" ]; then
    echo "Usage: $0 /path/to/image"
    exit 1
fi

IMAGE=$(realpath "$1")

# --- Detect wallpaper theme (light/dark) ---
brightness=$(magick "$IMAGE" -colorspace Gray -format "%[fx:mean]" info:)
theme=$(awk -v b="$brightness" 'BEGIN { print (b > 0.5 ? "light" : "dark") }')

if [ "$theme" = "light" ]; then
    WAL_FLAG="-l"
else
    WAL_FLAG=""
fi

# --- Wallpaper transition settings ---
TRANSITION="grow"
FPS=60
DURATION=1.2
BEZIER="0.4,0.2,0.2,1.0"

# --- Apply wallpaper to all monitors ---
mapfile -t MONITORS < <(hyprctl monitors -j | jq -r '.[].name')
for MON in "${MONITORS[@]}"; do
    swww img "$IMAGE" \
        --outputs "$MON" \
        --transition-type "$TRANSITION" \
        --transition-fps "$FPS" \
        --transition-duration "$DURATION" \
        --transition-bezier "$BEZIER"
done

# --- Generate color scheme ---
wal -i "$IMAGE" $WAL_FLAG
python ~/scripts/walgen.py 

# --- Reload and update system components ---
hyprctl reload
pywalfox update
pkill swaync; sleep 0.2; swaync & disown

#clear

