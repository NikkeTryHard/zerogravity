#!/usr/bin/env bash
# ZeroGravity — macOS setup
# Checks prerequisites, sets up config directories, and downloads the release binary.
# No UID isolation on macOS — runs in headless/HTTPS_PROXY mode only.
set -euo pipefail

CONFIG_DIR="$HOME/Library/Application Support/zerogravity"

# ── 1. Config directory ──
echo "→ Setting up config directory…"
mkdir -p "$CONFIG_DIR"

# ── 2. Data directory ──
echo "→ Setting up /tmp/zerogravity-standalone…"
mkdir -p /tmp/zerogravity-standalone

# ── 3. Prerequisite check: Antigravity must be installed ──
LS_BINARY="${ZEROGRAVITY_LS_PATH:-}"
if [ -z "$LS_BINARY" ]; then
    # Check both /Applications and ~/Applications
    for base in "/Applications/Antigravity.app" "$HOME/Applications/Antigravity.app"; do
        candidate="$base/Contents/Resources/app/extensions/antigravity/bin/language_server_darwin_arm64"
        if [ -f "$candidate" ]; then
            LS_BINARY="$candidate"
            break
        fi
    done
fi
echo "→ Checking for Antigravity installation…"
if [ -z "$LS_BINARY" ] || [ ! -f "$LS_BINARY" ]; then
    echo ""
    echo "✗ Antigravity is not installed (or the LS binary is missing)."
    echo "  ZeroGravity requires a working Antigravity installation."
    echo "  The Language Server binary is bundled with the Antigravity app"
    echo "  and cannot be downloaded separately."
    echo ""
    echo "  Expected in: /Applications/Antigravity.app or ~/Applications/Antigravity.app"
    echo ""
    echo "  Install Antigravity first, then re-run this script."
    echo "  Alternatively, set ZEROGRAVITY_LS_PATH to a custom LS binary location."
    exit 1
fi
echo "  Found: $LS_BINARY"

# ── 4. Download prebuilt binary ──
echo "→ Downloading ZeroGravity binary from GitHub Releases…"
BIN_DIR="$HOME/.local/bin"
mkdir -p "$BIN_DIR"

GH_RELEASE_URL="https://github.com/NikkeTryHard/zerogravity/releases/latest/download"
curl -fsSL "$GH_RELEASE_URL/zerogravity-linux-x86_64" -o "$BIN_DIR/zerogravity"
curl -fsSL "$GH_RELEASE_URL/zg-linux-x86_64" -o "$BIN_DIR/zg"
chmod +x "$BIN_DIR/zerogravity" "$BIN_DIR/zg"

echo "  Installed to: $BIN_DIR/zerogravity"
echo "  Installed to: $BIN_DIR/zg"

if ! echo "$PATH" | grep -q "$BIN_DIR"; then
    echo "  ⚠ $BIN_DIR is not in your PATH."
    echo "  Add this to your shell profile: export PATH=\"$BIN_DIR:\$PATH\""
fi

echo ""
echo "✓ Setup complete. Start with: zg start"
