#!/bin/bash
# For remote setup: run this on a new Pi via SSH
# Usage: ./setup-remote.sh <bot_name> <owner_name> <owner_phone> <api_key>

BOT_NAME=${1:-"SkynetPi"}
OWNER_NAME=${2:-""}
OWNER_PHONE=${3:-""}
API_KEY=${4:-""}

if [ -z "$OWNER_NAME" ] || [ -z "$OWNER_PHONE" ] || [ -z "$API_KEY" ]; then
    echo "Usage: $0 <bot_name> <owner_name> <owner_phone> <api_key>"
    echo "Example: $0 'MyBot' 'John Doe' '+5511999999999' 'sk-ant-...'"
    exit 1
fi

# Clone and run installer
cd /tmp
rm -rf skynetpi-bootstrap
git clone https://github.com/idiogo/skynetpi-bootstrap.git
cd skynetpi-bootstrap

./install.sh --name "$BOT_NAME" --owner "$OWNER_NAME" --phone "$OWNER_PHONE" --api-key "$API_KEY" --skip-prompts

echo ""
echo "🎉 Done! Now run: openclaw whatsapp link"
