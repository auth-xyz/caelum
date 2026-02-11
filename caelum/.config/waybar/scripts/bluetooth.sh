#!/bin/bash
dev=$(bluetoothctl devices Connected | head -n1 | awk '{print $2}')
[ -z "$dev" ] && echo "󰂲" && exit
info=$(bluetoothctl info "$dev" 2>/dev/null | grep -v '^\[CHG\]')
battery=$(echo "$info" | grep "Battery Percentage" | awk -F'[()]' '{print $2}')
icon="󰂯"
echo "$info" | grep -qi "Headset\|Headphone" && icon="󰋋"
echo "$info" | grep -qi "Keyboard" && icon="󰌌"
echo "$info" | grep -qi "Mouse" && icon="󰍽"
echo "$info" | grep -qi "Gamepad\|Controller" && icon="󰊴"
echo "$info" | grep -qi "Phone" && icon="󰄜"
[ -n "$battery" ] && printf "%s %s%%\n" "$icon" "$battery" || echo "$icon"
