#!/usr/bin/env bash

DIR="/opt/noon"
DOTS="$DIR/dots"

install_dots() {
    if [ ! -d "$DOTS" ]; then
        echo "Dotfiles not found"
        exit 1
    fi
    
    rsync -a "$DOTS"/ "$HOME"/
    echo "Installed in $HOME"
}

remove_dots() {
    read -p "Remove dotfiles? (y/N): " confirm
    
    if [[ "$confirm" != [yY] ]]; then
        echo "Cancelled"
        exit 0
    fi
    
    # Add your config directories here
    rm -rf "$HOME/.config/hypr" "$HOME/.config/waybar"
    echo "Removed"
}

case "${1:-install}" in
    install)
        install_dots
        ;;
    remove)
        remove_dots
        ;;
    *)
        echo "Usage: noon {install|remove}"
        exit 1
        ;;
esac
