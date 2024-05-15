#!/bin/bash

SCRIPT=$(realpath "$0")
DIR=$(dirname "$SCRIPT")

export NVIM_APPNAME=vimtest
ln -s "$(realpath "$DIR/lua/vim-tmux-navigator")" "$HOME/.config/$NVIM_APPNAME"
nvim -c "vnew | new" "$@"
rm "$HOME/.config/$NVIM_APPNAME"
