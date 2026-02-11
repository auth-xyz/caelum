#!/bin/bash

theme="~/.config/rofi/config.rasi"

options=" Apps\n Home\n Files\n Pictures\n Downloads\n󰗼 Power Menu"

chosen=$(echo -e "$options" | rofi -dmenu -theme "$theme" -p "Home:")

case $chosen in
    " Apps") ~/scripts/appc.sh ;;
    " Home") dolphin ~ & ;;        # or nautilus ~, dolphin ~, etc.
    " Files") dolphin & ;;
    " Pictures") dolphin ~/Pictures & ;;
    " Downloads") dolphin ~/Downloads & ;;
    "󰗼 Power Menu") ~/scripts/power-menu.sh ;;
esac

