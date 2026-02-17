#!/bin/bash
# For remote setup: run this on a new Pi via SSH
# Usage: ./setup-remote.sh <bot_name> <owner_name> <api_key> [owner_phone]

BOT_NAME=${1:-"SkynetPi"}
OWNER_NAME=${2:-""}
API_KEY=${3:-""}
OWNER_PHONE=${4:-""}

if [ -z "$OWNER_NAME" ] || [ -z "$API_KEY" ]; then
    echo "Usage: $0 <bot_name> <owner_name> <api_key> [owner_phone]"
    echo "Example: $0 'MyBot' 'John Doe' 'sk-ant-...' '+5511999999999'"
    echo "Phone is optional — you can use web chat and add a channel later."
    exit 1
fi

# Clone and run installer
cd /tmp
rm -rf skynetpi-bootstrap
git clone https://github.com/idiogo/skynetpi-bootstrap.git
cd skynetpi-bootstrap

PHONE_ARG=""
if [[ -n "$OWNER_PHONE" ]]; then
    PHONE_ARG="--phone $OWNER_PHONE"
fi

./install.sh --name "$BOT_NAME" --owner "$OWNER_NAME" $PHONE_ARG --api-key "$API_KEY" --skip-prompts

echo ""
if [[ -n "$OWNER_PHONE" ]]; then
    echo "🎉 Done! Now link WhatsApp: openclaw whatsapp link"
else
    echo "🎉 Done! Chat via web: openclaw dashboard (or add a channel later with openclaw configure)"
fi
