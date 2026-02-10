#!/bin/bash
# SkynetPi Dashboard - Kiosk Mode Launcher

DASHBOARD_DIR="$(dirname "$(readlink -f "$0")")"

# Ensure log server is running (systemd service)
systemctl --user start skynetpi-logserver 2>/dev/null || true
DASHBOARD_URL="file://${DASHBOARD_DIR}/index.html"

# Wait for X server
while ! xset q &>/dev/null; do
  echo "Waiting for X server..."
  sleep 1
done

# Disable screen blanking
xset s off
xset -dpms
xset s noblank

# Hide cursor after 1 second of inactivity
unclutter -idle 1 &

# Start Chromium in kiosk mode
chromium \
  --password-store=basic \
  --kiosk \
  --noerrdialogs \
  --disable-infobars \
  --disable-session-crashed-bubble \
  --disable-restore-session-state \
  --no-first-run \
  --start-fullscreen \
  --window-size=480,320 \
  --window-position=0,0 \
  --disable-translate \
  --disable-features=TranslateUI \
  --disable-pinch \
  --overscroll-history-navigation=0 \
  --check-for-update-interval=31536000 \
  "${DASHBOARD_URL}"
