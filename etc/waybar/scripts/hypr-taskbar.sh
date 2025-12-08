#!/bin/sh
json=$(hyprctl clients -j)
out="["
idx=0
echo "$json" | jq -c '.[] | {addr:.address,class:.class,title:.title,workspace:.workspace.id}' | sort -t: -k4,4n |
while read -r w; do
    addr=$(echo "$w" | jq -r '.addr')
    title=$(echo "$w" | jq -r '.title')
    cls=$(echo "$w" | jq -r '.class')
    ws=$(echo "$w" | jq -r '.workspace')
    [ $idx -gt 0 ] && out="$out,"
    out="$out{\"text\":\"$title\",\"class\":\"$cls ws$ws\",\"address\":\"$addr\"}"
    idx=$((idx+1))
done
out="$out]"
printf "%s" "$out"

