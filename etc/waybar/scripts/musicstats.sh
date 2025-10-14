#!/bin/bash

CACHE_DIR="$HOME/.cache"
COVER_RAW="$CACHE_DIR/music_cover_raw"
COVER="$CACHE_DIR/music_cover.png"
MUSIC_DIR="$HOME/.torrent/Music"


get_cover_ncspot() {
    url=$(playerctl -p ncspot metadata mpris:artUrl 2>/dev/null)
    if [[ -n "$url" ]]; then
        ext="${url##*.}"
        tmp="$CACHE_DIR/music_cover_dl.$ext"
        curl -sL "$url" -o "$tmp"
        if [[ -s "$tmp" ]]; then
            convert "$tmp" -resize 300x300 -blur 0x8 "$COVER"
            touch "$COVER"
        fi
    fi
}

get_cover_mpd() {
    file=$(mpc --format "%file%" current)
    dir="$MUSIC_DIR/$(dirname "$file")"

    for img in cover.jpg cover.png folder.jpg folder.png; do
        if [[ -f "$dir/$img" ]]; then
            convert "$dir/$img" -resize 300x300 -blur 0x8 "$COVER"
            touch "$COVER"
            return
        fi
    done
}

if playerctl -p ncspot status &>/dev/null; then
    # ncspot handling
    artist=$(playerctl -p ncspot metadata artist)
    title=$(playerctl -p ncspot metadata title)
    status=$(playerctl -p ncspot status)

    get_cover_ncspot

    if [[ "$status" == "Playing" ]]; then
        icon=" "
    else
        icon=" 󰏤"
    fi
    echo "$icon $artist - $title"

elif mpc status &>/dev/null; then
    # MPD handling
    current=$(mpc current)
    status=$(mpc status | sed -n '2p' | awk '{print $1}' | tr -d '[]')

    get_cover_mpd

    if [[ "$status" == "playing" ]]; then
        icon=" 󱍙"
    else
        icon=" 󰏤"
    fi

    if [[ -n "$current" ]]; then
        echo "$icon $current"
    else
        echo ""
    fi
else
    echo ""
fi

