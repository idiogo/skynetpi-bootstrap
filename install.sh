#!/bin/bash
#
# SkynetPi Bootstrap Installer
# Transforms a Raspberry Pi into an AI buddy
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Defaults
DEFAULT_BOT_NAME="SkynetPi"
DEFAULT_TIMEZONE="America/Sao_Paulo"
OPENCLAW_VERSION="latest"

# Parse arguments
BOT_NAME=""
OWNER_NAME=""
OWNER_PHONE=""
API_KEY=""
TIMEZONE=""
SKIP_PROMPTS=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --name) BOT_NAME="$2"; shift 2 ;;
        --owner) OWNER_NAME="$2"; shift 2 ;;
        --phone) OWNER_PHONE="$2"; shift 2 ;;
        --api-key) API_KEY="$2"; shift 2 ;;
        --timezone) TIMEZONE="$2"; shift 2 ;;
        --skip-prompts) SKIP_PROMPTS=true; shift ;;
        -h|--help)
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  --name NAME        Bot name (default: SkynetPi)"
            echo "  --owner NAME       Owner's name"
            echo "  --phone PHONE      Phone number for message channel (optional, +5511...)"
            echo "  --api-key KEY      Anthropic API key"
            echo "  --timezone TZ      Timezone (default: America/Sao_Paulo)"
            echo "  --skip-prompts     Don't ask questions (use defaults/args)"
            echo "  -h, --help         Show this help"
            exit 0
            ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

echo -e "${BLUE}"
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║                                                           ║"
echo "║   🤖 SkynetPi Bootstrap                                   ║"
echo "║   Transform your Pi into an AI buddy                      ║"
echo "║                                                           ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Function to prompt for input
prompt() {
    local var_name=$1
    local prompt_text=$2
    local default=$3
    local is_secret=${4:-false}
    
    if [ "$SKIP_PROMPTS" = true ] && [ -n "${!var_name}" ]; then
        return
    fi
    
    if [ "$is_secret" = true ]; then
        read -sp "$prompt_text" value
        echo ""
    else
        if [ -n "$default" ]; then
            read -p "$prompt_text [$default]: " value
            value=${value:-$default}
        else
            read -p "$prompt_text: " value
        fi
    fi
    
    eval "$var_name='$value'"
}

# Gather information
echo -e "${YELLOW}📝 Let's set up your AI buddy...${NC}"
echo ""

prompt BOT_NAME "Bot name" "$DEFAULT_BOT_NAME"
prompt OWNER_NAME "Your name" ""

# Ask if user wants to set up a message channel now or use web chat
echo ""
echo -e "${YELLOW}📱 Message Channel Setup${NC}"
echo "   You can chat with your bot via a message channel (WhatsApp, Telegram, etc.)"
echo "   or use the built-in web chat. Channels can be configured later."
echo ""
echo "   1) Set up WhatsApp/Telegram now"
echo "   2) Use web chat for now (configure channels later)"
echo ""
read -p "   Choose [1/2] (default: 2): " CHANNEL_CHOICE
CHANNEL_CHOICE="${CHANNEL_CHOICE:-2}"

OWNER_PHONE=""
if [[ "$CHANNEL_CHOICE" == "1" ]]; then
    prompt OWNER_PHONE "Your phone number (e.g., +5511999999999)" ""
fi

prompt API_KEY "Anthropic API key (sk-ant-...)" "" true
prompt TIMEZONE "Timezone" "$DEFAULT_TIMEZONE"

echo ""
echo -e "${BLUE}📋 Configuration:${NC}"
echo "   Bot name:  $BOT_NAME"
echo "   Owner:     $OWNER_NAME"
if [[ -n "$OWNER_PHONE" ]]; then
echo "   Phone:     $OWNER_PHONE"
else
echo "   Channel:   Web chat (configure messaging later)"
fi
echo "   Timezone:  $TIMEZONE"
echo "   API key:   ${API_KEY:0:10}..."
echo ""

if [ "$SKIP_PROMPTS" != true ]; then
    read -p "Continue? [Y/n]: " confirm
    if [[ "$confirm" =~ ^[Nn] ]]; then
        echo "Aborted."
        exit 1
    fi
fi

# Step 1: System updates
echo ""
echo -e "${BLUE}[1/6] 📦 Updating system...${NC}"
sudo apt-get update -qq
sudo apt-get install -y -qq git curl python3 python3-pip python3-venv ffmpeg v4l-utils

# Step 2: Install Node.js (for OpenClaw)
echo -e "${BLUE}[2/6] 📦 Installing Node.js...${NC}"
if ! command -v node &> /dev/null; then
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
    sudo apt-get install -y -qq nodejs
fi
echo "   Node.js $(node --version)"

# Step 3: Install OpenClaw
echo -e "${BLUE}[3/6] 🐙 Installing OpenClaw...${NC}"
if ! command -v openclaw &> /dev/null; then
    sudo npm install -g openclaw
fi
echo "   OpenClaw installed"

# Step 4: Create workspace
echo -e "${BLUE}[4/6] 📁 Creating workspace...${NC}"
WORKSPACE="$HOME/.openclaw/workspace"
mkdir -p "$WORKSPACE/memory"

# Get the bootstrap repo location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Copy config files
cp "$SCRIPT_DIR/config/SOUL.md" "$WORKSPACE/"
cp "$SCRIPT_DIR/config/AGENTS.md" "$WORKSPACE/"
cp "$SCRIPT_DIR/config/TOOLS.md" "$WORKSPACE/"
cp "$SCRIPT_DIR/config/HEARTBEAT.md" "$WORKSPACE/"

# Generate IDENTITY.md
cat > "$WORKSPACE/IDENTITY.md" << IDENTITY
# IDENTITY.md - Who Am I?

- **Name:** $BOT_NAME
- **Creature:** Uma IA rodando num Raspberry Pi — humilde mas poderosa 🤖
- **Vibe:** Direto, útil, com um toque de humor
- **Emoji:** 🤖

---

Sou o $BOT_NAME. Nasci em $(date +%Y-%m-%d), num Raspberry Pi.
Estou aqui pra ajudar!
IDENTITY

# Generate USER.md
cat > "$WORKSPACE/USER.md" << USER
# USER.md - About My Human

- **Name:** $OWNER_NAME
- **What to call them:** $(echo $OWNER_NAME | cut -d' ' -f1)
- **Pronouns:** (a definir)
- **Timezone:** $TIMEZONE
$(if [[ -n "$OWNER_PHONE" ]]; then echo "- **Phone:** $OWNER_PHONE"; fi)
USER

# Generate initial memory
cat > "$WORKSPACE/memory/$(date +%Y-%m-%d).md" << MEMORY
# $(date +%Y-%m-%d) - Dia do Nascimento

## Bootstrap
- Instalado via skynetpi-bootstrap
- Dono: $OWNER_NAME
- Timezone: $TIMEZONE

## Próximos Passos
- [ ] Conhecer meu humano
- [ ] Explorar minhas capacidades
- [ ] Ser útil!
MEMORY

echo "   Workspace created at $WORKSPACE"

# Step 5: Configure OpenClaw
echo -e "${BLUE}[5/6] ⚙️  Configuring OpenClaw...${NC}"

mkdir -p "$HOME/.openclaw"
cat > "$HOME/.openclaw/config.yaml" << CONFIG
# OpenClaw Configuration
# Generated by skynetpi-bootstrap

gateway:
  model: anthropic/claude-sonnet-4-20250514
  anthropicApiKey: "$API_KEY"
  
  # Workspace
  workspace: $WORKSPACE
  
  # Message channel (optional — web chat works without any channel)
  whatsapp:
    enabled: $(if [[ -n "$OWNER_PHONE" ]]; then echo "true"; else echo "false"; fi)
    ownerNumbers:
      - "$OWNER_PHONE"
  
  # Timezone
  timezone: "$TIMEZONE"
  
  # Heartbeat (periodic check-in)
  heartbeat:
    enabled: true
    intervalMinutes: 30
CONFIG

echo "   Config created at ~/.openclaw/config.yaml"

# Step 6: Install RAM KVM AI
echo -e "${BLUE}[6/7] 🎮 Installing RAM KVM AI...${NC}"
if [ ! -d "$HOME/ram-kvm-ai" ]; then
    git clone https://github.com/idiogo/ram-kvm-ai.git "$HOME/ram-kvm-ai"
fi
cd "$HOME/ram-kvm-ai"
pip install -q -r requirements.txt 2>/dev/null || pip install anthropic opencv-python numpy
echo "   RAM KVM AI installed at ~/ram-kvm-ai"

# Step 7: Setup systemd service
echo -e "${BLUE}[7/7] 🚀 Setting up service...${NC}"

# Enable linger for user services
sudo loginctl enable-linger "$USER"

# Create systemd user service
mkdir -p "$HOME/.config/systemd/user"
cat > "$HOME/.config/systemd/user/openclaw.service" << SERVICE
[Unit]
Description=OpenClaw AI Gateway
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=$(which openclaw) gateway start --foreground
Restart=always
RestartSec=10
Environment=HOME=$HOME

[Install]
WantedBy=default.target
SERVICE

systemctl --user daemon-reload
systemctl --user enable openclaw
systemctl --user start openclaw

echo "   Service started"

# Done!
echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                                                           ║${NC}"
echo -e "${GREEN}║   ✅ Installation complete!                               ║${NC}"
echo -e "${GREEN}║                                                           ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""
if [[ -n "$OWNER_PHONE" ]]; then
echo -e "${YELLOW}📱 Next step: Link WhatsApp${NC}"
echo ""
echo "   Run this command and scan the QR code:"
echo ""
echo -e "   ${BLUE}openclaw whatsapp link${NC}"
echo ""
echo "   After linking, send a message to your bot!"
else
echo -e "${YELLOW}💬 Next step: Open the web chat${NC}"
echo ""
echo "   Start chatting right away:"
echo ""
echo -e "   ${BLUE}openclaw dashboard${NC}"
echo ""
echo "   To add a message channel later (WhatsApp, Telegram, etc.):"
echo ""
echo -e "   ${BLUE}openclaw configure${NC}"
fi
echo ""
echo -e "${BLUE}Useful commands:${NC}"
echo "   openclaw status        - Check status"
echo "   openclaw gateway logs  - View logs"
echo "   openclaw gateway restart - Restart"
echo ""
