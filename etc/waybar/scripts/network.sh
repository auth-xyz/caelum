#!/usr/bin/env bash
# network-fuzzel - small network picker using nmcli + fuzzel
# put in ~/bin and chmod +x

FUZZEL="fuzzel --dmenu --width 40 --lines 12 --prompt 'Network: '"
PASSFZ="fuzzel --dmenu --prompt 'Password: ' --password --prompt-only --cache /dev/null"

# need nmcli available
command -v nmcli >/dev/null || { echo "nmcli not found"; exit 1; }

# Build menu: active connection, saved connections, scan results, toggles
active="$(nmcli -t -f DEVICE,TYPE,STATE,CONNECTION device status \
  | grep -E 'wifi|ethernet' \
  | awk -F: '$3=="connected" {print $1" (active) — "$4}')"

saved="$(nmcli -t -f NAME,TYPE connection show | sed 's/:/ — /')"

# wifi scan (SSIDs; use --rescan yes to force)
wifi_list="$(nmcli -t -f SSID,SECURITY device wifi list \
  | sed '/^$/d' \
  | awk -F: '!/^--/ { ss=$1; sec=$2; if (ss=="") ss="<hidden>"; print ss" — "sec }')"

menu=""
menu+="Status: $(nmcli -t -f GENERAL.STATE device show | head -n1)\n"
[ -n "$active" ] && menu+="$active\n"
[ -n "$saved" ] && menu+="Saved:\n$saved\n"
[ -n "$wifi_list" ] && menu+="Wi-Fi:\n$wifi_list\n"
menu+="\nToggle Wi-Fi\ndevice up:$(nmcli -t -f DEVICE,STATE device status \
  | awk -F: '/wifi/ {print $1"::"$2}')\nShow IP\nQuit"

# Show menu, pick one line (strip trailing/leading whitespace)
choice=$(printf "%b" "$menu" | $FUZZEL) || exit 0
choice="${choice//$'\r'/}"   # normalize

# Helpers
trim() { echo "$1" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'; }

if [[ "$choice" == "Quit" ]]; then
  exit 0
fi

if [[ "$choice" == "Show IP" ]]; then
  # show IPs of active devices in a small fuzzel window
  ips=$(nmcli -t -f DEVICE,IP4.ADDRESS device show \
    | awk -F: '/IP4.ADDRESS/ {print $1" — "$2}')
  printf "%s\n" "$ips" | fuzzel --width 50 --lines 8 --prompt "IP: " --prompt-only
  exit 0
fi

if [[ "$choice" == Toggle* || "$choice" == device\ up:* ]]; then
  # toggle wifi on/off
  state=$(nmcli radio wifi)
  if [[ "$state" == "enabled" ]]; then
    nmcli radio wifi off
    notify-send "Wi-Fi disabled"
  else
    nmcli radio wifi on
    notify-send "Wi-Fi enabled"
  fi
  exit 0
fi

# If user picked a saved connection (match by NAME exactly)
if printf "%s\n" "$saved" | grep -F -- "$choice" >/dev/null 2>&1; then
  name=$(printf "%s\n" "$choice" | sed 's/ — .*//')
  nmcli connection up "$name" && notify-send "Activated $name" || notify-send "Failed to activate $name"
  exit 0
fi

# If they picked a Wi-Fi SSID line like "MyNet — WPA2"
if echo "$choice" | grep " — " >/dev/null 2>&1; then
  ssid=$(echo "$choice" | sed 's/ — .*//')
  # try to connect without password first (maybe open)
  if nmcli device wifi connect "$ssid" >/dev/null 2>&1; then
    notify-send "Connected to $ssid"
    exit 0
  fi
  # ask for password via fuzzel password mode
  pass=$(printf "" | $PASSFZ)
  if [ -n "$pass" ]; then
    if nmcli device wifi connect "$ssid" password "$pass" >/dev/null 2>&1; then
      notify-send "Connected to $ssid"
    else
      notify-send "Failed to connect to $ssid"
    fi
  else
    notify-send "Cancelled"
  fi
  exit 0
fi

# fallback: try to activate by exact name
nmcli connection up "$choice" >/dev/null 2>&1 && notify-send "Activated $choice" || notify-send "No action for: $choice"
exit 0

