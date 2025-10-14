#!/bin/bash

cfg="$HOME/.config"
KPath="$cfg/kitty"
FPath="$cfg/fuzzel"
WPath="$cfg/waybar"
SPath="$cfg/swaync"
HPath="$cfg/hypr"

Packages="nerd-fonts kitty zsh zed zoxide hyprland hyprsunset hyprlock hyprpaper hypridle"

opt="$1"

# Ensure ~/.config exists
mkdir -p "$cfg"

phase1() {
  case "$opt" in
    --y)
      echo "[*] Overwriting existing configs..."
      ln -sfn "$(pwd)/etc/"* "$cfg/"
      ;;
    --n)
      echo "[*] Backing up existing configs before linking..."
      backup_dir="$cfg/backup_$(date +%Y%m%d_%H%M%S)"
      mkdir -p "$backup_dir"
      for d in ./etc/*; do
        name=$(basename "$d")
        if [ -e "$cfg/$name" ]; then
          mv "$cfg/$name" "$backup_dir/"
        fi
        ln -s "$(pwd)/$d" "$cfg/"
      done
      echo "[*] Backup saved to $backup_dir"
      ;;
    *)
      echo "Usage: $0 [--y | --n]"
      echo "  --y  overwrite existing configs"
      echo "  --n  backup existing configs before linking"
      ;;
  esac
}

phase2() {
  # Update system
  echo "[*] Updating system..."
  sudo pacman -Syu --noconfirm

  # Install base packages
  echo "[*] Installing main packages..."
  sudo pacman -S --needed --noconfirm $Packages base-devel git

  # Check for yay
  if ! command -v yay &>/dev/null; then
    echo "[*] Installing yay (AUR helper)..."
    tmpdir=$(mktemp -d)
    git clone https://aur.archlinux.org/yay.git "$tmpdir"
    (cd "$tmpdir" && makepkg -si --noconfirm)
    rm -rf "$tmpdir"
  fi

  # Install AUR packages if listed
  if [ -f ./aur.txt ]; then
    echo "[*] Installing AUR packages from aur.txt..."
    yay -S --needed --noconfirm $(cat ./aur.txt)
  fi

  echo "[✓] All packages installed successfully."
}

phase3() {
  # patching up 
  cp -r ./scripts ./wallpapers ~/ 
  fc-cache -fv
  echo "[✓] all done!"
}
