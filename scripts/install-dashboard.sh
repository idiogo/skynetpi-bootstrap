#!/bin/bash
#
# SkynetPi Dashboard Installer
# Installs the LCD status dashboard (optional module)
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
DASHBOARD_SRC="$PROJECT_DIR/dashboard"
DASHBOARD_DEST="$HOME/.openclaw/workspace/dashboard"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  SkynetPi Dashboard Installer${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Check if dashboard source exists
if [ ! -d "$DASHBOARD_SRC" ]; then
    echo "Error: Dashboard source not found at $DASHBOARD_SRC"
    exit 1
fi

# Install dependencies
echo -e "${YELLOW}Installing dependencies...${NC}"
sudo apt-get update -qq
sudo apt-get install -y -qq chromium unclutter xdotool

# Create destination directory
echo -e "${YELLOW}Copying dashboard files...${NC}"
mkdir -p "$DASHBOARD_DEST"
cp -r "$DASHBOARD_SRC"/* "$DASHBOARD_DEST/"
chmod +x "$DASHBOARD_DEST/start-dashboard.sh"

# Get OpenClaw token
OPENCLAW_CONFIG="$HOME/.openclaw/openclaw.json"
if [ -f "$OPENCLAW_CONFIG" ]; then
    TOKEN=$(grep -o '"token"[[:space:]]*:[[:space:]]*"[^"]*"' "$OPENCLAW_CONFIG" | head -1 | sed 's/.*"token"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
    if [ -n "$TOKEN" ]; then
        echo -e "${YELLOW}Configuring dashboard with OpenClaw token...${NC}"
        sed -i "s/const TOKEN = '[^']*'/const TOKEN = '$TOKEN'/" "$DASHBOARD_DEST/dashboard.js" 2>/dev/null || true
    fi
fi

# Install systemd service for log server
echo -e "${YELLOW}Installing log server service...${NC}"
mkdir -p "$HOME/.config/systemd/user"
cat > "$HOME/.config/systemd/user/skynetpi-logserver.service" << EOF
[Unit]
Description=SkynetPi Log Server
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/python3 $DASHBOARD_DEST/log-server.py
Restart=always
RestartSec=3

[Install]
WantedBy=default.target
EOF

systemctl --user daemon-reload
systemctl --user enable skynetpi-logserver
systemctl --user start skynetpi-logserver

# Create desktop shortcut
echo -e "${YELLOW}Creating desktop shortcut...${NC}"
mkdir -p "$HOME/Desktop"
cat > "$HOME/Desktop/SkynetPi Dashboard.desktop" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=SkynetPi Dashboard
Comment=OpenClaw Status Monitor
Exec=$DASHBOARD_DEST/start-dashboard.sh
Icon=utilities-system-monitor
Terminal=false
Categories=Utility;Monitor;
EOF
chmod +x "$HOME/Desktop/SkynetPi Dashboard.desktop"
gio set "$HOME/Desktop/SkynetPi Dashboard.desktop" metadata::trusted true 2>/dev/null || true

# Create autostart entry
echo -e "${YELLOW}Configuring autostart...${NC}"
mkdir -p "$HOME/.config/autostart"
cat > "$HOME/.config/autostart/skynetpi-dashboard.desktop" << EOF
[Desktop Entry]
Type=Application
Name=SkynetPi Dashboard
Exec=$DASHBOARD_DEST/start-dashboard.sh
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
EOF

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  Dashboard installed successfully!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "  • Desktop shortcut created"
echo "  • Auto-start configured"
echo "  • Log server running as systemd service"
echo ""
echo "  Click 'SkynetPi Dashboard' on Desktop to open"
echo ""
