bin="~/Projects/Fun/planet"
laptop="eDP-1"

if pgrep -f "$bin" > /dev/null; then
  echo "[stop]"
  pkill -f "$bin"
  brightnessctl set 100%+
else
  echo "[start]"
  brightnessctl set 100%-
  hyprctl dispatch exec kitty "$bin --center"
  sleep 0.2
  hyprctl dispatch fullscreen active
fi
