#!/bin/bash

if playerctl -p spotify status &>/dev/null; then
    a=$(playerctl -p spotify metadata artist)
    t=$(playerctl -p spotify metadata title)
    s=$(playerctl -p spotify status)
    [[ "$s" == "Playing" ]] && ic=" " || ic=" 󰏤"
    echo "$ic $a - $t"
elif mpc status &>/dev/null; then
    cur=$(mpc current)
    st=$(mpc status | sed -n '2p' | awk '{print $1}' | tr -d '[]')
    [[ "$st" == "playing" ]] && ic=" 󱍙" || ic=" 󰏤"
    [[ -n "$cur" ]] && echo "$ic $cur" || echo ""
else
    echo "󰝛 nothing"
fi

