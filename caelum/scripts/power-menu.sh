#!/bin/bash

theme="~/.config/rofi/config.rasi"

options=" Lock\n Reboot\n Poweroff\n Suspend\n󰗼 Logout"

chosen=$(echo -e "$options" | rofi -dmenu \
    -theme "$theme" \
    -no-config \
    -theme-str '
        window {
            width: 690px;
            height: 70px;
            anchor: center;
            location: center;
            children: [listview];
        }
        listview {
            flow: horizontal;
            columns: 5;
            lines: 1;
            spacing: 10px;
            scrollbar: false;
            border: 0;
            cycle: false;
        }
        element {
            padding: 8px 12px;
            orientation: horizontal;
        }
    ' \
    -p "Power:")

case $chosen in
    " Lock") hyprctl dispatch exec "hyprlock" ;;
    " Reboot") systemctl reboot ;;
    " Poweroff") systemctl poweroff ;;
    " Suspend") systemctl suspend ;;
    "󰗼 Logout") hyprctl dispatch exit ;;
esac

