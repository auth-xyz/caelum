#!/bin/bash

action="$1"

if playerctl -p ncspot status &>/dev/null; then
    # Control ncspot via playerctl
    case "$action" in
        play-pause) playerctl -p ncspot play-pause ;;
        next) playerctl -p ncspot next ;;
        previous) playerctl -p ncspot previous ;;
    esac
elif mpc status &>/dev/null; then
    # Control MPD via mpc
    case "$action" in
        play-pause) mpc toggle ;;
        next) mpc next ;;
        previous) mpc prev ;;
    esac
fi

