#!/usr/bin/env bash
# ZeroGravity — Linux setup
# Checks prerequisites, creates the zerogravity-ls system user for
# UID-scoped iptables isolation, and downloads the release binary.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Default LS install location
LS_INSTALL_DIR="/usr/local/lib/zerogravity"
LS_BINARY_NAME="language_server_linux_x64"
DEFAULT_LS_PATH="/usr/share/antigravity/resources/app/extensions/antigravity/bin/$LS_BINARY_NAME"

# ── 0. Dependency check ──
MISSING=()
for cmd in curl jq sudo iptables; do
    command -v "$cmd" &>/dev/null || MISSING+=("$cmd")
done
if [ ${#MISSING[@]} -gt 0 ]; then
    echo "✗ Missing dependencies: ${MISSING[*]}"
    echo "  Install them first, then re-run this script."
    exit 1
fi

# ── 1. Find or download the LS binary ──
LS_BINARY="${ZEROGRAVITY_LS_PATH:-}"

# Check user-specified path first
if [ -n "$LS_BINARY" ] && [ -f "$LS_BINARY" ]; then
    echo "→ Using LS binary from ZEROGRAVITY_LS_PATH: $LS_BINARY"

# Check if Antigravity is installed at the default path
elif [ -f "$DEFAULT_LS_PATH" ]; then
    LS_BINARY="$DEFAULT_LS_PATH"
    echo "→ Found Antigravity LS at default path: $LS_BINARY"

# Check if we previously extracted the LS binary
elif [ -f "$LS_INSTALL_DIR/$LS_BINARY_NAME" ]; then
    LS_BINARY="$LS_INSTALL_DIR/$LS_BINARY_NAME"
    echo "→ Found previously extracted LS binary: $LS_BINARY"

# Auto-download from Google's apt repo
else
    echo "→ Antigravity not installed. Downloading LS binary from Google's apt repo..."

    # Check for dpkg-deb
    if ! command -v dpkg-deb &>/dev/null; then
        echo "✗ dpkg-deb is required to extract the LS binary from the .deb package."
        echo "  Install dpkg (apt install dpkg) or install Antigravity manually."
        exit 1
    fi

    TMPDIR=$(mktemp -d)
    trap "rm -rf $TMPDIR" EXIT

    # Add Google's apt repo key and download the .deb
    echo "  Adding Google's Antigravity apt repo..."
    curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg \
        | gpg --dearmor > "$TMPDIR/antigravity-repo-key.gpg" 2>/dev/null

    # Create a temporary apt sources file
    echo "deb [signed-by=$TMPDIR/antigravity-repo-key.gpg] https://us-central1-apt.pkg.dev/projects/antigravity-auto-updater-dev/ antigravity-debian main" \
        > "$TMPDIR/antigravity.list"

    # Pin to known-good version to prevent breakage from Google updates
    ANTIGRAVITY_VERSION="1.16.5-1770081357"

    echo "  Downloading Antigravity .deb v${ANTIGRAVITY_VERSION} (this may take a minute)..."
    apt-get -o Dir::Etc::SourceList="$TMPDIR/antigravity.list" \
            -o Dir::Etc::SourceParts="/dev/null" \
            -o Dir::Cache="$TMPDIR/cache" \
            -o Dir::State="$TMPDIR/state" \
            update -qq 2>/dev/null

    mkdir -p "$TMPDIR/cache/archives" "$TMPDIR/state/lists/partial"
    apt-get -o Dir::Etc::SourceList="$TMPDIR/antigravity.list" \
            -o Dir::Etc::SourceParts="/dev/null" \
            -o Dir::Cache="$TMPDIR/cache" \
            -o Dir::State="$TMPDIR/state" \
            download -qq "antigravity=$ANTIGRAVITY_VERSION" 2>/dev/null \
        || (cd "$TMPDIR" && apt-get download "antigravity=$ANTIGRAVITY_VERSION" 2>/dev/null) \
        || { echo "✗ Failed to download Antigravity .deb"; exit 1; }

    DEB_FILE=$(find "$TMPDIR" -name 'antigravity_*.deb' -o -name 'antigravity*.deb' 2>/dev/null | head -1)
    if [ -z "$DEB_FILE" ]; then
        # Fallback: try downloading from current dir
        cd "$TMPDIR"
        apt-get download antigravity 2>/dev/null || { echo "✗ Failed to download Antigravity .deb"; exit 1; }
        DEB_FILE=$(find "$TMPDIR" -name 'antigravity*.deb' | head -1)
    fi

    echo "  Extracting LS binary..."
    dpkg-deb -x "$DEB_FILE" "$TMPDIR/extracted/"

    EXTRACTED_LS="$TMPDIR/extracted/usr/share/antigravity/resources/app/extensions/antigravity/bin/$LS_BINARY_NAME"
    if [ ! -f "$EXTRACTED_LS" ]; then
        echo "✗ LS binary not found in .deb package"
        exit 1
    fi

    # Install the extracted LS binary
    sudo mkdir -p "$LS_INSTALL_DIR"
    sudo cp "$EXTRACTED_LS" "$LS_INSTALL_DIR/$LS_BINARY_NAME"
    sudo chmod +x "$LS_INSTALL_DIR/$LS_BINARY_NAME"

    LS_BINARY="$LS_INSTALL_DIR/$LS_BINARY_NAME"
    echo "  ✓ LS binary installed to: $LS_BINARY"
fi

echo "  Using: $LS_BINARY"

# ── 2. System user for UID isolation ──
echo "→ Creating zerogravity-ls system user…"
if id -u zerogravity-ls &>/dev/null; then
    echo "  Already exists."
else
    sudo useradd --system --no-create-home --shell /usr/sbin/nologin zerogravity-ls
    echo "  Created."
fi

# ── 3. Sudoers rule (run commands as zerogravity-ls without password) ──
SUDOERS="/etc/sudoers.d/zerogravity"
echo "→ Installing sudoers rule…"
if [ -f "$SUDOERS" ]; then
    echo "  Already exists."
else
    echo "$USER ALL=(zerogravity-ls) NOPASSWD: ALL" | sudo tee "$SUDOERS" > /dev/null
    sudo chmod 0440 "$SUDOERS"
    echo "  Installed: $SUDOERS"
fi

# ── 4. Data directory permissions ──
echo "→ Setting up /tmp/zerogravity-standalone…"
sudo mkdir -p /tmp/zerogravity-standalone
sudo chmod 1777 /tmp/zerogravity-standalone

# ── 5. Config directory ──
echo "→ Setting up ~/.config/zerogravity…"
mkdir -p "$HOME/.config/zerogravity"

# ── 6. Set LS path if not default ──
if [ "$LS_BINARY" != "$DEFAULT_LS_PATH" ]; then
    echo "→ Writing LS path to config…"
    echo "export ZEROGRAVITY_LS_PATH=\"$LS_BINARY\"" > "$HOME/.config/zerogravity/env"
    echo "  Saved to ~/.config/zerogravity/env"
    echo "  Add 'source ~/.config/zerogravity/env' to your shell profile,"
    echo "  or set ZEROGRAVITY_LS_PATH=$LS_BINARY before running."
fi

# ── 7. Download prebuilt binary ──
echo "→ Downloading ZeroGravity binary from GitHub Releases…"
BIN_DIR="$HOME/.local/bin"
mkdir -p "$BIN_DIR"

GH_RELEASE_URL="https://github.com/NikkeTryHard/zerogravity/releases/latest/download"
curl -fsSL "$GH_RELEASE_URL/zerogravity-linux-x86_64" -o "$BIN_DIR/zerogravity"
curl -fsSL "$GH_RELEASE_URL/zg-linux-x86_64" -o "$BIN_DIR/zg"
chmod +x "$BIN_DIR/zerogravity" "$BIN_DIR/zg"

echo "  Installed to: $BIN_DIR/zerogravity"
echo "  Installed to: $BIN_DIR/zg"

# Make sure ~/.local/bin is in PATH
if ! echo "$PATH" | grep -q "$BIN_DIR"; then
    echo "  ⚠ $BIN_DIR is not in your PATH."
    echo "  Add this to your shell profile: export PATH=\"$BIN_DIR:\$PATH\""
fi

echo ""
echo "✓ Setup complete. Start with: zg start"
