#!/bin/bash
# Network usage script for Waybar

CACHE_FILE="/tmp/network_cache"
INTERFACE="wlan0"  # Change to your interface (eth0, enp0s3, etc.)

# Function to format bytes
format_bytes() {
    local bytes=$1
    if [ $bytes -lt 1024 ]; then
        echo "${bytes}B"
    elif [ $bytes -lt 1048576 ]; then
        echo "$(awk "BEGIN {printf \"%.1f\", $bytes/1024}")K"
    else
        echo "$(awk "BEGIN {printf \"%.1f\", $bytes/1048576}")M"
    fi
}

# Get current stats
CURRENT_RX=$(cat /sys/class/net/$INTERFACE/statistics/rx_bytes 2>/dev/null || echo 0)
CURRENT_TX=$(cat /sys/class/net/$INTERFACE/statistics/tx_bytes 2>/dev/null || echo 0)
CURRENT_TIME=$(date +%s)

# Read previous stats
if [ -f "$CACHE_FILE" ]; then
    read PREV_RX PREV_TX PREV_TIME < "$CACHE_FILE"
else
    PREV_RX=$CURRENT_RX
    PREV_TX=$CURRENT_TX
    PREV_TIME=$CURRENT_TIME
fi

# Calculate rates
TIME_DIFF=$((CURRENT_TIME - PREV_TIME))
if [ $TIME_DIFF -gt 0 ]; then
    RX_RATE=$(( (CURRENT_RX - PREV_RX) / TIME_DIFF ))
    TX_RATE=$(( (CURRENT_TX - PREV_TX) / TIME_DIFF ))
else
    RX_RATE=0
    TX_RATE=0
fi

# Save current stats
echo "$CURRENT_RX $CURRENT_TX $CURRENT_TIME" > "$CACHE_FILE"

# Format output
RX_FORMATTED=$(format_bytes $RX_RATE)
TX_FORMATTED=$(format_bytes $TX_RATE)

# Output JSON for Waybar
echo "{\"text\": \" ${RX_FORMATTED}  ${TX_FORMATTED}\", \"tooltip\": \"Download: ${RX_FORMATTED}/s | Upload: ${TX_FORMATTED}/s\"}"
