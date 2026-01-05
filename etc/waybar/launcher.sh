#! /bin/bash

pkill -x waybar
env GTK_THEME=Adwaita:dark waybar &
