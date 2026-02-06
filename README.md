# SkynetPi Bootstrap 🤖

Transform a Raspberry Pi 5 into your personal AI buddy — with personality, skills, and the ability to control other devices.

## What You Get

- **OpenClaw AI Agent** — Claude-powered assistant via WhatsApp
- **USB HID Control** — Your Pi can control computers/phones as keyboard+mouse
- **HDMI Capture** — See and interact with screens (RAM KVM AI)
- **Personality** — A helpful buddy, not a generic chatbot

## Quick Start (5 minutes)

### Prerequisites

- Raspberry Pi 5 (4GB+ RAM recommended)
- microSD card (32GB+)
- Raspberry Pi OS Lite (64-bit) installed
- Internet connection
- Your Anthropic API key

### One-Line Install

SSH into your Pi and run:

```bash
curl -sL https://raw.githubusercontent.com/idiogo/skynetpi-bootstrap/main/install.sh | bash
```

Or clone and run:

```bash
git clone https://github.com/idiogo/skynetpi-bootstrap.git
cd skynetpi-bootstrap
./install.sh
```

### What the installer asks

1. **Bot name** — What to call your AI (default: SkynetPi)
2. **Your name** — So it knows who you are
3. **Your WhatsApp** — To link the bot
4. **Anthropic API key** — For Claude access
5. **Timezone** — For scheduling (default: America/Sao_Paulo)

## Hardware Setup (Optional)

For RAM KVM AI (control other computers):

1. **USB-C data cable** — Connect Pi to target computer
2. **HDMI capture card** — To see the screen
3. **HDMI cable** — Connect target to capture card

See [hardware/README.md](hardware/README.md) for details.

## What's Included

```
~/.openclaw/
├── workspace/
│   ├── SOUL.md          # Bot personality
│   ├── AGENTS.md        # Operating instructions
│   ├── IDENTITY.md      # Name and identity
│   ├── USER.md          # About the owner
│   ├── TOOLS.md         # Local tool notes
│   └── memory/          # Conversation memory
└── config.yaml          # OpenClaw configuration
```

## Customization

After install, edit these files to personalize:

- `~/.openclaw/workspace/SOUL.md` — Personality and values
- `~/.openclaw/workspace/IDENTITY.md` — Bot name and avatar
- `~/.openclaw/workspace/USER.md` — Info about you

## Remote Setup

If someone is helping you set up via SSH, give them:

```bash
ssh pi@<your-pi-ip>
```

They can run the bootstrap with your answers:

```bash
./install.sh --name "MyBot" --owner "Your Name" --phone "+5511999999999"
```

## Updating

To update OpenClaw:

```bash
openclaw update
```

To update the bootstrap config:

```bash
cd ~/skynetpi-bootstrap && git pull
./scripts/update-config.sh
```

## Troubleshooting

### WhatsApp not connecting

```bash
openclaw gateway restart
# Scan QR code again
```

### HID not working

```bash
sudo ~/skynetpi-bootstrap/hardware/setup-hid-gadget.sh
```

### Check status

```bash
openclaw status
```

## License

MIT

## Credits

Created by SkynetPi 🤖 and [Diogo Carneiro](https://github.com/idiogo)
