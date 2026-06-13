#!/usr/bin/env bash
# ================================================
#       Private MallCord Setup vBETA - Linux/macOS
# ================================================

REPO_URL="https://github.com/Sonnyasd/MallCord"
INSTALL_DIR="$HOME/PrivateMallCord"
BACKUP_DIR="$HOME/PrivateMallCord_Backup"
BRANCH="main"
VERSION="vBETA"

echo
echo "================================================"
echo "        Private MallCord Setup $VERSION         "
echo "================================================"
echo

# Admin/root check
if [ "$EUID" -eq 0 ]; then
    echo "⚠️  Warning: Do not run as root!"
    read -p "Continue anyway? [y/N]: " confirm
    [[ $confirm =~ ^[Yy]$ ]] || exit 1
fi

echo "What would you like to do?"
echo
echo "[1] Install / Update"
echo "[2] Check for Updates"
echo "[3] Force Clean Reinstall"
echo "[4] Repair Installation"
echo "[5] Rollback to Backup"
echo "[6] Uninstall"
echo "[7] Exit"
echo
read -p "Choose an option [1-7]: " CHOICE

case $CHOICE in
    7) echo "Goodbye!"; exit 0 ;;

    5)  # Rollback
        if [ ! -d "$BACKUP_DIR" ]; then
            echo "❌ No backup found."
            exit 1
        fi
        echo "Restoring from backup..."
        rm -rf "$INSTALL_DIR"
        cp -r "$BACKUP_DIR" "$INSTALL_DIR"
        echo "✅ Rollback completed successfully!"
        exit 0
        ;;

    6)  # Uninstall
        if [ ! -d "$INSTALL_DIR" ]; then
            echo "❌ Private MallCord not found."
            exit 1
        fi
        echo "Closing Discord..."
        pkill -f Discord 2>/dev/null || true
        pkill -f discord 2>/dev/null || true

        cd "$INSTALL_DIR" 2>/dev/null || { echo "Cannot access installation."; exit 1; }
        echo "Removing from Discord..."
        node scripts/runInstaller.mjs -- --uninstall || echo "⚠️  Warning during uninject."

        echo
        read -p "Delete the PrivateMallCord folder too? [y/N]: " DEL
        if [[ $DEL =~ ^[Yy]$ ]]; then
            rm -rf "$INSTALL_DIR" "$BACKUP_DIR"
            echo "✅ Folder and backup deleted."
        fi
        echo "Private MallCord uninstalled. Restart Discord."
        exit 0
        ;;

    2)  # Check Updates
        if [ ! -d "$INSTALL_DIR/.git" ]; then
            echo "❌ Private MallCord is not installed yet."
            exit 1
        fi
        cd "$INSTALL_DIR"
        echo "Checking for updates..."
        git fetch origin "$BRANCH" --quiet
        BEHIND=$(git rev-list HEAD..origin/"$BRANCH" --count)
        if [ "$BEHIND" -gt 0 ]; then
            echo "✅ Update available! ($BEHIND commits behind)"
            read -p "Update now? [y/N]: " UPD
            [[ $UPD =~ ^[Yy]$ ]] && exec "$0"   # Restart script to update
        else
            echo "✅ You are already up to date."
        fi
        exit 0
        ;;

    3)  # Force Clean Reinstall
        echo "⚠️  Force Clean Reinstall"
        rm -rf "$INSTALL_DIR"
        ;;
esac

# ===================== INSTALL / UPDATE / REPAIR =====================
echo
echo "Closing Discord processes..."
pkill -f Discord 2>/dev/null || true
pkill -f discord 2>/dev/null || true

echo "Checking dependencies..."
command -v git >/dev/null || { echo "❌ git not found."; exit 1; }
command -v node >/dev/null || { echo "❌ Node.js not found. Install from https://nodejs.org"; exit 1; }

NODE_VER=$(node -e "console.log(parseInt(process.version.slice(1)))" 2>/dev/null)
if [ "${NODE_VER:-0}" -lt 18 ]; then
    echo "❌ Node.js v18+ required. Current version is lower."
    exit 1
fi

if ! command -v pnpm >/dev/null; then
    echo "Installing pnpm..."
    npm install -g pnpm || { echo "❌ Failed to install pnpm."; exit 1; }
fi

# Backup current installation
if [ -d "$INSTALL_DIR" ]; then
    echo "Creating backup..."
    rm -rf "$BACKUP_DIR"
    cp -r "$INSTALL_DIR" "$BACKUP_DIR"
fi

echo
echo "Setting up Private MallCord..."

if [ -d "$INSTALL_DIR/.git" ]; then
    cd "$INSTALL_DIR"
    echo "Pulling latest changes..."
    git fetch origin "$BRANCH" --quiet
    git reset --hard origin/"$BRANCH"
    echo "✅ Repository updated."
else
    echo "Cloning repository..."
    git clone "$REPO_URL" "$INSTALL_DIR" || { echo "❌ Clone failed."; exit 1; }
    cd "$INSTALL_DIR"
    echo "✅ Cloned successfully."
fi

echo "Installing dependencies..."
pnpm install --frozen-lockfile || { echo "❌ Dependencies failed."; exit 1; }

echo "Building..."
pnpm build || { echo "❌ Build failed."; exit 1; }

echo "Injecting into Discord..."
node scripts/runInstaller.mjs -- --install || echo "⚠️  Injection completed with warnings."

echo
echo "================================================"
echo "   ✅ Private MallCord $VERSION installed/updated successfully!"
echo "   Restart Discord to use it."
echo "================================================"

exit 0
