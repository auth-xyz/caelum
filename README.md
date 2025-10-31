<p align="center">
<a href="https://git.io/typing-svg">
<img src="https://readme-typing-svg.herokuapp.com?font=JetBrains+Mono&weight=800&pause=1000&color=000000&background=FFCD00&center=true&vCenter=true&width=380&lines=Caelum" alt="Typing SVG" />
</a>
<br/>
<img src="https://img.shields.io/badge/WM-HYPRLAND-FFCD00?style=for-the-badge&labelColor=000000&color=FFCD00"/>
<img src="https://img.shields.io/badge/BAR-WAYBAR-FFCD00?style=for-the-badge&labelColor=000000&color=FFCD00"/>
<img src="https://img.shields.io/badge/EDITOR-NEOVIM-FFCD00?style=for-the-badge&labelColor=000000&color=FFCD00"/>
<img src="https://img.shields.io/badge/THEMER-PYWAL-FFCD00?style=for-the-badge&labelColor=000000&color=FFCD00"/>
</p>

---

> [!WARNING]
> This repository is a **work in progress**.
> Some modules may change, be deprecated, or require additional dependencies.

---

## Overview

**Caelum** is a curated collection of configuration files designed for a cohesive, minimal, and adaptive Wayland environment using **Hyprland**.
It integrates dynamic theming through **pywal**, modular **Neovim** configuration, and a clean **Waybar** layout.

---

## Structure

```
.
├── etc/
│   ├── fuzzel/
│   ├── kitty/
│   ├── nvim/
│   ├── rofi/
│   ├── swaync/
│   ├── waybar/
│   └── wofi/
├── hypr/
├── scripts/
├── wallpapers/
└── showcase/
```

---

## Components

| Component                | Path                                 | Description                                  |
| ------------------------ | ------------------------------------ | -------------------------------------------- |
| **Hyprland**             | `hypr/`                              | Window manager configuration and rules       |
| **Waybar**               | `etc/waybar/`                        | Status bar configuration with system scripts |
| **Neovim**               | `etc/nvim/`                          | Lua-based modular setup using lazy.nvim      |
| **Rofi / Wofi / Fuzzel** | `etc/rofi`, `etc/wofi`, `etc/fuzzel` | App launchers and menus                      |
| **Kitty**                | `etc/kitty/`                         | Terminal configuration                       |
| **SwayNC**               | `etc/swaync/`                        | Notification styling                         |
| **Scripts**              | `scripts/`                           | Utility scripts for system and theming       |
| **Wallpapers**           | `wallpapers/`                        | Wallpaper collection used by pywal           |
| **Showcase**             | `showcase/`                          | Desktop previews                             |

---

## Gallery

| Desktop              | Menu                        | Power                        |
| -------------------- | --------------------------- | ---------------------------- |
| ![](showcase/01.png) | ![](showcase/home_menu.png) | ![](showcase/power_menu.png) |

---

## Installation

Clone and install:

```bash
git clone https://github.com/yourname/caelum.git ~/caelum
cd ~/caelum
./install.sh
```

This will:

* Symlink configs into `~/.config/`
* Link scripts into `~/.local/bin/`
* Copy wallpapers into `~/Pictures/wallpapers/`

---

## Requirements

* **Hyprland**
* **Waybar**
* **Neovim (>=0.9)**
* **pywal**
* **swaync**
* **Kitty**
* **Rofi / Wofi / Fuzzel**

Optional:

* `playerctl`
* `pamixer`
* `brightnessctl`
* `jq`

---

## License

Licensed under the **MIT License**.
You are free to use, modify, and redistribute this configuration.

