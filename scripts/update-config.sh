#!/bin/bash
# Update config files from bootstrap repo (preserves personal files)

set -e

WORKSPACE="$HOME/.openclaw/workspace"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "🔄 Updating config files..."

# Only update non-personal files
cp "$SCRIPT_DIR/config/AGENTS.md" "$WORKSPACE/"
cp "$SCRIPT_DIR/config/TOOLS.md" "$WORKSPACE/"

# Don't overwrite SOUL.md, IDENTITY.md, USER.md, MEMORY.md, memory/

echo "✅ Updated: AGENTS.md, TOOLS.md"
echo "⏭️  Skipped: SOUL.md, IDENTITY.md, USER.md, memory/ (personal files)"
