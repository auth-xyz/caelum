#!/bin/bash

# ~/.config/waybar/scripts/toggle-stats.sh

STATE_FILE="$HOME/.config/waybar/stats_state"

# Toggle state
if [[ -f "$STATE_FILE" ]]; then
    rm "$STATE_FILE"
else
    touch "$STATE_FILE"
fi

# Force waybar to update the module
pkill -RTMIN+8 waybar
