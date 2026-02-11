#!/usr/bin/env bash
set -e

stow --dir="$(pwd)" --target="$HOME" --restow caelum
