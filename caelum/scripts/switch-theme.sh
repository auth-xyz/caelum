#!/bin/sh

set -eu

theme="${1:-}"

case "$theme" in
  modern|brutalist)
    ;;
  *)
    printf 'usage: %s <modern|brutalist>\n' "$0" >&2
    exit 1
    ;;
esac

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
QS_DIR="$ROOT/.config/quickshell"
HYPR_DIR="$ROOT/.config/hypr"
THEME_DIR="$ROOT/.config/theme"

cp "$QS_DIR/themes/$theme/shell.qml" "$QS_DIR/shell.qml"
cp "$QS_DIR/themes/$theme/Colors.qml" "$QS_DIR/Colors.qml"
cp "$HYPR_DIR/themes/$theme/colors.conf" "$HYPR_DIR/colors.conf"
cp "$HYPR_DIR/themes/$theme/styles.conf" "$HYPR_DIR/conf/styles.conf"

mkdir -p "$THEME_DIR"
printf '%s\n' "$theme" > "$THEME_DIR/current"

hyprctl reload >/dev/null 2>&1 || true
pkill -x quickshell >/dev/null 2>&1 || true
nohup quickshell >/dev/null 2>&1 &

printf 'applied theme: %s\n' "$theme"
