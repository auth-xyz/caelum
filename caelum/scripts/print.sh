#! /bin/bash 
grim -g "$(slurp)" -t png - | wl-copy -t image/png 
