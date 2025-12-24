#!/bin/bash

set -e

THEME_NAME="noon"
THEME_DIR="/usr/share/sddm/themes"
CONFIG_FILE="/etc/sddm.conf"
ORIGINAL_DIR="${1:-$(pwd)}"

# Run with pkexec if not root
if [ "$EUID" -ne 0 ]; then
    pkexec "$0" "$ORIGINAL_DIR"
    exit $?
fi

# Create symlink
echo "Creating symlink..."
mkdir -p "$THEME_DIR"
rm -rf "$THEME_DIR/$THEME_NAME"
ln -sf "$ORIGINAL_DIR" "$THEME_DIR/$THEME_NAME"

# Link colors config
echo "Linking theme config..."
ln -sf /tmp/sddm_colors.conf "$THEME_DIR/$THEME_NAME/theme.conf"

# Set default theme
echo "Setting default theme..."
cat > "$CONFIG_FILE" <<EOF
[Theme]
Current=$THEME_NAME
EOF

echo "Done! Restart SDDM: systemctl restart sddm"
