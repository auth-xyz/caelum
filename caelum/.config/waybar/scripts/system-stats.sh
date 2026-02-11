#!/bin/bash
# ~/.config/waybar/scripts/system-stats.sh

# Icon definitions
ICON_CPU=""
ICON_MEM=""
ICON_AUDIO_HIGH=""
ICON_AUDIO_LOW=""
ICON_AUDIO_MUTED=""
ICON_BT_DISCONNECTED="󰂲"
ICON_BT_CONNECTED="󰂱"
ICON_BT_HEADPHONE="󰋋"
ICON_BT_KEYBOARD="󰌌"
ICON_BT_MOUSE="󰍽"
ICON_BT_GAMEPAD="󰊴"
ICON_BT_PHONE="󰄜"
ICON_BT_GENERIC="󰂯"

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
    AUDIO_ICON="$ICON_AUDIO_MUTED"
elif [[ $AUDIO_INFO -gt 50 ]]; then
    AUDIO_ICON="$ICON_AUDIO_HIGH"
else
    AUDIO_ICON="$ICON_AUDIO_LOW"
fi

# Get Bluetooth info
BT_DEV=$(bluetoothctl devices Connected | head -n1 | awk '{print $2}')
if [[ -n "$BT_DEV" ]]; then
    BT_INFO=$(bluetoothctl info "$BT_DEV" 2>/dev/null | grep -v '^\[CHG\]')
    BT_NAME=$(echo "$BT_INFO" | grep "Name:" | cut -d':' -f2- | sed 's/^ *//')
    BT_BATTERY=$(echo "$BT_INFO" | grep "Battery Percentage" | awk -F'[()]' '{print $2}')
    
    # Determine device type icon
    BT_ICON="$ICON_BT_GENERIC"
    echo "$BT_INFO" | grep -qi "Headset\|Headphone" && BT_ICON="$ICON_BT_HEADPHONE"
    echo "$BT_INFO" | grep -qi "Keyboard" && BT_ICON="$ICON_BT_KEYBOARD"
    echo "$BT_INFO" | grep -qi "Mouse" && BT_ICON="$ICON_BT_MOUSE"
    echo "$BT_INFO" | grep -qi "Gamepad\|Controller" && BT_ICON="$ICON_BT_GAMEPAD"
    echo "$BT_INFO" | grep -qi "Phone" && BT_ICON="$ICON_BT_PHONE"
    
    BT_CONNECTED=true
    BT_COLLAPSED_ICON="$ICON_BT_CONNECTED"
else
    BT_ICON="$ICON_BT_DISCONNECTED"
    BT_NAME="No device"
    BT_BATTERY=""
    BT_CONNECTED=false
    BT_COLLAPSED_ICON="$ICON_BT_DISCONNECTED"
fi

# Generate output based on state
if [[ "$EXPANDED" == "true" ]]; then
    if [[ "$BT_CONNECTED" == "true" && -n "$BT_BATTERY" ]]; then
        BT_TEXT="${BT_ICON} ${BT_BATTERY}%"
    elif [[ "$BT_CONNECTED" == "true" ]]; then
        BT_TEXT="${BT_ICON}"
    else
        BT_TEXT="${BT_ICON}"
    fi
    TEXT="$ICON_CPU ${CPU_USAGE}%  $ICON_MEM ${MEM_USAGE}%  ${AUDIO_ICON} ${AUDIO_INFO}%  ${BT_TEXT}"
    CLASS="expanded"
else
    TEXT="$ICON_CPU $ICON_MEM ${AUDIO_ICON} ${BT_COLLAPSED_ICON}"
    CLASS="collapsed"
fi

# Build tooltip
if [[ "$BT_CONNECTED" == "true" && -n "$BT_BATTERY" ]]; then
    TOOLTIP=" CPU: ${CPU_USAGE}% \n Memory: ${MEM_USAGE}% \n Audio: ${AUDIO_INFO}% \n ${BT_NAME}: ${BT_BATTERY}%"
elif [[ "$BT_CONNECTED" == "true" ]]; then
    TOOLTIP=" CPU: ${CPU_USAGE}% \n Memory: ${MEM_USAGE}% \n Audio: ${AUDIO_INFO}% \n ${BT_NAME}"
else
    TOOLTIP=" CPU: ${CPU_USAGE}% \n Memory: ${MEM_USAGE}% \n Audio: ${AUDIO_INFO}% \n Bluetooth: Disconnected"
fi

# Output JSON
echo "{\"text\": \"$TEXT\", \"class\": \"$CLASS\", \"tooltip\": \"$TOOLTIP\"}"
