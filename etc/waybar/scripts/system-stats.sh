#!/bin/bash

# ~/.config/waybar/scripts/system-stats.sh

STATE_FILE="$HOME/.config/waybar/stats_state"

# Check if expanded state file exists
if [[ -f "$STATE_FILE" ]]; then
    EXPANDED=true
else
    EXPANDED=false
fi

# Get system stats
CPU_USAGE=$(awk '/^%Cpu/ {print int($2)}' <(top -bn1))
MEM_USAGE=$(free | awk '/^Mem:/ {printf "%.0f", $3/$2 * 100.0}')

# Get audio info
AUDIO_INFO=$(pactl get-sink-volume @DEFAULT_SINK@ | head -n1 | awk '{print $5}' | sed 's/%//')
AUDIO_MUTED=$(pactl get-sink-mute @DEFAULT_SINK@ | grep -q "yes" && echo "muted" || echo "unmuted")

# Set audio icon based on mute status and volume
if [[ "$AUDIO_MUTED" == "muted" ]]; then
    AUDIO_ICON=""
elif [[ $AUDIO_INFO -gt 50 ]]; then
    AUDIO_ICON=""
else
    AUDIO_ICON=""
fi

# Generate output based on state
if [[ "$EXPANDED" == "true" ]]; then
    TEXT=" ${CPU_USAGE}%   ${MEM_USAGE}%  ${AUDIO_ICON} ${AUDIO_INFO}%"
    CLASS="expanded"
else
    TEXT="  "
    CLASS="collapsed"
fi

# Output JSON
echo "{\"text\": \"$TEXT\", \"class\": \"$CLASS\", \"tooltip\": \"CPU: ${CPU_USAGE}% | Memory: ${MEM_USAGE}% | Audio: ${AUDIO_INFO}%\"}"
