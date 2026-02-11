#!/bin/bash

action="$1"

if playerctl -p spotify status &>/dev/null; then
    case "$action" in
        play-pause) playerctl -p spotify play-pause ;;
        next) playerctl -p spotify next ;;
        previous) playerctl -p spotify previous ;;
    esac

elif mpc status &>/dev/null; then
    case "$action" in
        play-pause) mpc toggle ;;
        next) mpc next ;;
        previous) mpc prev ;;
    esac
fi

