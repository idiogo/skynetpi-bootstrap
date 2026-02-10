#!/bin/bash
#
# SkynetPi TFT LCD Installer
# Installs drivers for 3.5" MHS35 LCD display (optional module)
#
# WARNING: This will disable HDMI output!
# To restore HDMI later: cd ~/LCD-show && sudo ./LCD-hdmi
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  SkynetPi TFT LCD Installer (MHS35 3.5\")${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${YELLOW}WARNING: This will DISABLE HDMI output!${NC}"
echo -e "${YELLOW}The Pi will reboot automatically after installation.${NC}"
echo ""
echo "To restore HDMI later:"
echo "  cd ~/LCD-show && sudo ./LCD-hdmi"
echo ""

# Confirm
read -p "Continue? [y/N] " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
fi

# Clone LCD-show repository
echo -e "${YELLOW}Downloading LCD drivers...${NC}"
cd "$HOME"
sudo rm -rf LCD-show
git clone https://github.com/goodtft/LCD-show.git
chmod -R 755 LCD-show

# Run installer (will reboot)
echo -e "${YELLOW}Installing MHS35 drivers...${NC}"
echo -e "${RED}System will reboot now!${NC}"
cd LCD-show
sudo ./MHS35-show
