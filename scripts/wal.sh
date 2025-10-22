#!/bin/bash
# Usage: ./wal.sh /path/to/image

CONF=~/.config/hypr/hyprpaper.conf

if [ -z "$1" ]; then
    echo "Usage: $0 /path/to/image"
    exit 1
fi

IMAGE=$(realpath "$1")

# --- Detect wallpaper theme (white/black) ---
brightness=$(magick "$IMAGE" -colorspace Gray -format "%[fx:mean]" info:)
theme=$(awk -v b="$brightness" 'BEGIN { print (b > 0.5 ? "light" : "dark") }')

if [ "$theme" = "light" ]; then
    WAL_FLAG="-l"
else
    WAL_FLAG=""
fi

# --- Set wallpaper dynamically ---
hyprctl hyprpaper preload "$IMAGE"
hyprctl hyprpaper wallpaper "HDMI-A-1,$IMAGE"
hyprctl hyprpaper wallpaper "eDP-1,$IMAGE"

sleep 1
hyprctl hyprpaper unload unused

# --- Update hyprpaper.conf ---
cat > "$CONF" <<EOF
preload = $IMAGE
wallpaper = HDMI-A-1,$IMAGE
wallpaper = eDP-1,$IMAGE
EOF

# --- Generate color scheme ---
wal -i "$IMAGE" $WAL_FLAG
python ~/scripts/walgen.py 

# --- Reload Hyprland ---
hyprctl reload
pywalfox update
pkill swaync; sleep 0.2; swaync & disown

clear

