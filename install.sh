#!/bin/bash

src=$(dirname "$(realpath "$0")")

link() {
    mkdir -p "$2"
    for f in "$1"/*; do
        ln -sf "$f" "$2/$(basename "$f")"
    done
}

echo "Linking dotfiles..."

link "$src/etc" ~/.config
link "$src/hypr" ~/.config/hypr
link "$src/scripts" ~/scripts
link "$src/wallpapers" ~/wallpapers

chmod +x ~/scripts/* ~/scripts/repeat

echo "installing scripts/caelum to /usr/local/bin/"
sudo ln -sf "$src/scripts/caelum" /usr/local/bin/

echo "Done."

