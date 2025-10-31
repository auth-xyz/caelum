#!/usr/bin/env bash
#
# Wofi wallpaper chooser — tuned layout
#

DIR="$HOME/wallpapers"
CACHE="$HOME/.cache/wal-thumbs"
WAL="$HOME/scripts/wal.sh"

mkdir -p "$CACHE"
shopt -s nullglob nocaseglob
files=("$DIR"/*.{jpg,jpeg,png,bmp,webp,gif})

if [[ ${#files[@]} -eq 0 ]]; then
    notify-send "No wallpapers found in $DIR"
    exit 1
fi

for img in "${files[@]}"; do
    thumb="$CACHE/$(basename "${img%.*}").jpg"
    if [[ ! -f "$thumb" || "$thumb" -ot "$img" ]]; then
        convert "$img" -resize 600x400\> -gravity center -extent 600x400 "$thumb" 2>/dev/null
    fi
done

menu=""
for img in "${files[@]}"; do
    thumb="$CACHE/$(basename "${img%.*}").jpg"
    menu+="img:$thumb\n"
done

choice=$(echo -e "$menu" | \
    wofi --show dmenu \
         --prompt " " \
         --allow-images \
         --columns=5 \
         --width=600 \
         --height=200 \
         --hide-scroll \
         --no-actions \
         --allow-markup)

[[ -z "$choice" ]] && exit 0

# Extract filename from choice
file=$(basename "${choice#img:}")
selected="$DIR/${file%.*}".*

# Apply wallpaper
for img in "${files[@]}"; do
    [[ "$(basename "$img")" == "$file" || "$(basename "${img%.*}")" == "${file%.*}" ]] && exec "$WAL" "$img"
done

