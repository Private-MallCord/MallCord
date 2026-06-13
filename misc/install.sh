#!/usr/bin/env bash
# ================================================
# Private MallCord Setup
# Usage: bash install.sh
# ================================================

REPO_URL="https://github.com/Sonnyasd/MallCord"
INSTALL_DIR="$HOME/PrivateMallCord"

echo
echo "================================================"
echo "         Private MallCord Setup"
echo "================================================"
echo

echo "What would you like to do?"
echo "[1] Install / Update"
echo "[2] Check for Updates"
echo "[3] Uninstall"
echo "[4] Exit"
echo
read -p "Choose an option [1-4]: " CHOICE

if [ "$CHOICE" = "4" ]; then
    exit 0
fi

if [ "$CHOICE" = "3" ]; then
    if [ ! -d "$INSTALL_DIR" ]; then
        echo "Private MallCord not found."
        exit 1
    fi
    echo "Closing Discord..."
    pkill -f Discord 2>/dev/null || true
    pkill -f discord 2>/dev/null || true

    cd "$INSTALL_DIR"
    echo "Removing from Discord..."
    node scripts/runInstaller.mjs -- --uninstall || echo "Warning: Uninject had some issues."

    echo
    read -p "Also delete the PrivateMallCord folder? [y/N]: " DEL
    if [[ $DEL =~ ^[Yy]$ ]]; then
        rm -rf "$INSTALL_DIR"
        echo "Folder deleted."
    fi
    echo "Private MallCord uninstalled. Restart Discord."
    exit 0
fi

if [ "$CHOICE" = "2" ]; then
    if [ ! -d "$INSTALL_DIR/.git" ]; then
        echo "Private MallCord is not installed yet."
        exit 1
    fi
    cd "$INSTALL_DIR"
    echo "Checking for updates..."
    git fetch origin main
    git log HEAD..origin/main --oneline
    echo
    read -p "Update now? [y/N]: " UPD
    if [[ $UPD =~ ^[Yy]$ ]]; then
        pkill -f Discord 2>/dev/null || true
        git reset --hard origin/main
        pnpm install --no-frozen-lockfile
        pnpm build
        node scripts/runInstaller.mjs -- --install
        echo "Update completed successfully!"
    fi
    exit 0
fi

# ===================== INSTALL / UPDATE =====================
if [ "$EUID" -eq 0 ]; then
    echo "Do not run as root!"
    exit 1
fi

echo "Closing Discord..."
pkill -f Discord 2>/dev/null || true
pkill -f discord 2>/dev/null || true

echo "Checking dependencies..."
command -v git >/dev/null || { echo "ERROR: git not found."; exit 1; }
command -v node >/dev/null || { echo "ERROR: Node.js not found. Install from https://nodejs.org"; exit 1; }

NODE_VER=$(node -e "console.log(parseInt(process.version.slice(1)))" 2>/dev/null)
if [ "$NODE_VER" -lt 18 ]; then
    echo "ERROR: Node.js v18+ required."
    exit 1
fi

if ! command -v pnpm >/dev/null; then
    echo "Installing pnpm..."
    npm install -g pnpm
fi

echo
echo "Cloning / Updating repository..."
if [ -d "$INSTALL_DIR/.git" ]; then
    cd "$INSTALL_DIR"
    git fetch origin main
    git reset --hard origin/main
    echo "[OK] Repository updated."
else
    if [ -d "$INSTALL_DIR" ]; then rm -rf "$INSTALL_DIR"; fi
    git clone "$REPO_URL" "$INSTALL_DIR"
    cd "$INSTALL_DIR"
    echo "[OK] Cloned."
fi

echo "Installing dependencies..."
pnpm install --no-frozen-lockfile

echo "Building..."
pnpm build

echo "Injecting into Discord..."
node scripts/runInstaller.mjs -- --install

echo
echo "================================================"
echo "   Private MallCord installed successfully!"
echo "   Start Discord to load it."
echo "================================================"

exit 0
