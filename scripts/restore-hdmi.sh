#!/bin/bash
#
# Restore HDMI Output
# Use this if you installed the TFT LCD by mistake
#
# WARNING: This will reboot the Pi!
#

echo "┌─────────────────────────────────────────┐"
echo "│  Restore HDMI Output                    │"
echo "└─────────────────────────────────────────┘"
echo ""
echo "This will disable the LCD and restore HDMI output."
echo "The Pi will reboot automatically."
echo ""

read -p "Continue? [y/N] " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
fi

if [ -d "$HOME/LCD-show" ]; then
    cd "$HOME/LCD-show"
    sudo ./LCD-hdmi
else
    echo "LCD-show not found. Trying manual restore..."
    sudo sed -i '/dtoverlay=tft35a/d' /boot/firmware/config.txt 2>/dev/null || \
    sudo sed -i '/dtoverlay=tft35a/d' /boot/config.txt 2>/dev/null
    echo "Config updated. Rebooting..."
    sudo reboot
fi
