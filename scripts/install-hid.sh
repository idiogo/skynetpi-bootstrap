#!/bin/bash
#
# SkynetPi USB HID Gadget Installer
# Configures Pi as USB keyboard/mouse for KVM control
#
# Requirements:
# - Raspberry Pi 4/5 with USB-C port
# - USB-C cable to target device
#

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  SkynetPi USB HID Gadget Installer${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Check if running on Pi
if ! grep -q "Raspberry Pi" /proc/cpuinfo 2>/dev/null; then
    echo -e "${RED}Error: This script must run on a Raspberry Pi${NC}"
    exit 1
fi

CONFIG_FILE="/boot/firmware/config.txt"
if [ ! -f "$CONFIG_FILE" ]; then
    CONFIG_FILE="/boot/config.txt"
fi

echo -e "${YELLOW}Configuring USB gadget mode...${NC}"

# Add dtoverlay for USB gadget mode
if ! grep -q "dtoverlay=dwc2" "$CONFIG_FILE"; then
    echo "" | sudo tee -a "$CONFIG_FILE" > /dev/null
    echo "# USB HID Gadget for SkynetPi KVM" | sudo tee -a "$CONFIG_FILE" > /dev/null
    echo "dtoverlay=dwc2,dr_mode=peripheral" | sudo tee -a "$CONFIG_FILE" > /dev/null
    echo "Added dtoverlay=dwc2 to $CONFIG_FILE"
else
    echo "dtoverlay=dwc2 already configured"
fi

# Add dwc2 and libcomposite to modules
if ! grep -q "dwc2" /etc/modules; then
    echo "dwc2" | sudo tee -a /etc/modules > /dev/null
fi
if ! grep -q "libcomposite" /etc/modules; then
    echo "libcomposite" | sudo tee -a /etc/modules > /dev/null
fi

# Create HID gadget setup script
echo -e "${YELLOW}Creating HID gadget setup script...${NC}"
sudo tee /usr/local/bin/setup-hid-gadget.sh > /dev/null << 'SCRIPT'
#!/bin/bash
# Setup USB HID gadget (keyboard + mouse)

modprobe libcomposite

cd /sys/kernel/config/usb_gadget/
mkdir -p skynetpi
cd skynetpi

echo 0x1d6b > idVendor  # Linux Foundation
echo 0x0104 > idProduct # Multifunction Composite Gadget
echo 0x0100 > bcdDevice
echo 0x0200 > bcdUSB

mkdir -p strings/0x409
echo "fedcba9876543210" > strings/0x409/serialnumber
echo "SkynetPi" > strings/0x409/manufacturer
echo "SkynetPi KVM" > strings/0x409/product

mkdir -p configs/c.1/strings/0x409
echo "Config 1: HID" > configs/c.1/strings/0x409/configuration
echo 250 > configs/c.1/MaxPower

# Keyboard
mkdir -p functions/hid.keyboard
echo 1 > functions/hid.keyboard/protocol
echo 1 > functions/hid.keyboard/subclass
echo 8 > functions/hid.keyboard/report_length
echo -ne '\x05\x01\x09\x06\xa1\x01\x05\x07\x19\xe0\x29\xe7\x15\x00\x25\x01\x75\x01\x95\x08\x81\x02\x95\x01\x75\x08\x81\x03\x95\x05\x75\x01\x05\x08\x19\x01\x29\x05\x91\x02\x95\x01\x75\x03\x91\x03\x95\x06\x75\x08\x15\x00\x25\x65\x05\x07\x19\x00\x29\x65\x81\x00\xc0' > functions/hid.keyboard/report_desc
ln -sf functions/hid.keyboard configs/c.1/

# Mouse
mkdir -p functions/hid.mouse
echo 0 > functions/hid.mouse/protocol
echo 0 > functions/hid.mouse/subclass
echo 4 > functions/hid.mouse/report_length
echo -ne '\x05\x01\x09\x02\xa1\x01\x09\x01\xa1\x00\x05\x09\x19\x01\x29\x03\x15\x00\x25\x01\x95\x03\x75\x01\x81\x02\x95\x01\x75\x05\x81\x03\x05\x01\x09\x30\x09\x31\x15\x81\x25\x7f\x75\x08\x95\x02\x81\x06\xc0\xc0' > functions/hid.mouse/report_desc
ln -sf functions/hid.mouse configs/c.1/

# Enable gadget
ls /sys/class/udc > UDC

# Fix permissions
sleep 1
chmod 666 /dev/hidg0 /dev/hidg1 2>/dev/null || true

echo "HID gadget configured: /dev/hidg0 (keyboard), /dev/hidg1 (mouse)"
SCRIPT

sudo chmod +x /usr/local/bin/setup-hid-gadget.sh

# Create systemd service
echo -e "${YELLOW}Creating systemd service...${NC}"
sudo tee /etc/systemd/system/skynetpi-hid.service > /dev/null << 'SERVICE'
[Unit]
Description=SkynetPi USB HID Gadget
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/setup-hid-gadget.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
SERVICE

sudo systemctl daemon-reload
sudo systemctl enable skynetpi-hid.service

# Copy hid-control.py
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/hid-control.py" ]; then
    cp "$SCRIPT_DIR/hid-control.py" "$HOME/.openclaw/workspace/" 2>/dev/null || true
    chmod +x "$HOME/.openclaw/workspace/hid-control.py" 2>/dev/null || true
fi

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  USB HID Gadget installed!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${YELLOW}REBOOT REQUIRED${NC} to activate USB gadget mode."
echo ""
echo "After reboot:"
echo "  1. Connect Pi USB-C to target device"
echo "  2. Check status: cat /sys/class/udc/*/state"
echo "     (should show 'configured' when connected)"
echo "  3. Use hid-control.py to send keystrokes/mouse"
echo ""
read -p "Reboot now? [y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    sudo reboot
fi
