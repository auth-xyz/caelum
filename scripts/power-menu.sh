#!/bin/bash

theme="~/.config/rofi/config.rasi"

options=" Lock\n Reboot\n Poweroff\n Suspend\n󰗼 Logout"

chosen=$(echo -e "$options" | rofi -dmenu -theme $theme -p "Power:")

case $chosen in
    " Lock") hyprctl dispatch exec "hyprlock" ;;
    " Reboot") systemctl reboot ;;
    " Poweroff") systemctl poweroff ;;
    " Suspend") systemctl suspend ;;
    "󰗼 Logout") hyprctl dispatch exit ;;
esac

