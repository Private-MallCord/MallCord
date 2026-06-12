#!/usr/bin/env bash
# ============================================================================
#  Private MallCord Setup (Bash Edition)
# ============================================================================

set -euo pipefail

# Global Settings
REPO_URL="https://github.com/Sonnyasd/MallCord.git"
INSTALL_DIR="$HOME/MallCord"
BACKUP_DIR="$HOME/MallCord_Backup"
LOG_FILE="$HOME/mallcord_install.log"

# Define ANSI Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'

# Logging setup
echo "$(date) -- Script started --" > "$LOG_FILE"

# Helper functions
step() { echo -e "${CYAN}  =>${NC} $*"; }
ok()   { echo -e "${GREEN}  [OK]${NC} $*"; }
warn() { echo -e "${YELLOW}  [!]${NC} $*"; }
fail() { echo -e "${RED}  [ERROR]${NC} $*"; echo "$(date) -- ERROR: $*" >> "$LOG_FILE"; }
die()  { fail "$*"; echo -e "\n  Check detailed log at: $LOG_FILE\n"; exit 1; }

# Enforce non-root execution
[[ "$(id -u)" -ne 0 ]] || { echo -e "${RED}  [ERROR] Do not run this script as root / sudo.${NC}"; exit 1; }

# ============================================================================
#  SUBROUTINES / FUNCTIONS
# ============================================================================

check_dependencies() {
    step "Checking system environment..."

    # GIT CHECK & AUTO INSTALL
    if ! command -v git >/dev/null 2>&1; then
        warn "Git was not found on your system. Attempting automatic installation..."
        if command -v apt-get >/dev/null 2>&1; then sudo apt-get update && sudo apt-get install -y git >> "$LOG_FILE" 2>&1;
        elif command -v brew >/dev/null 2>&1; then brew install git >> "$LOG_FILE" 2>&1;
        elif command -v pacman >/dev/null 2>&1; then sudo pacman -Sy --noconfirm git >> "$LOG_FILE" 2>&1;
        elif command -v dnf >/dev/null 2>&1; then sudo dnf install -y git >> "$LOG_FILE" 2>&1;
        else die "Package manager not found. Please install Git manually."; fi
    fi
    ok "Git detected: $(git --version | awk '{print $3}')"

    # NODE.JS CHECK
    if ! command -v node >/dev/null 2>&1; then
        die "Node.js was not found! Please install LTS version from: https://nodejs.org"
    fi

    # NODE.JS VERSION CONTROL (v18+)
    NODE_MAJOR=$(node -e "console.log(parseInt(process.version.slice(1)))")
    if [[ "$NODE_MAJOR" -lt 18 ]]; then
        die "Node.js v18+ is required. Your version: $(node --version). Please update it."
    else
        ok "Node.js detected: $(node --version)"
    fi

    # PNPM CHECK & AUTO INSTALL
    if ! command -v pnpm >/dev/null 2>&1; then
        warn "pnpm package manager not found. Installing globally via npm..."
        npm install -g pnpm >> "$LOG_FILE" 2>&1 || die "Failed to install pnpm."
        NPM_BIN="$(npm config get prefix)/bin"
        export PATH="$NPM_BIN:$PATH"
        command -v pnpm >/dev/null 2>&1 || die "pnpm installed but not in PATH. Please restart terminal."
    fi
    ok "pnpm detected: v$(pnpm --version)"
    echo
}

kill_discord() {
    step "Scanning and safely terminating Discord clients..."
    local discord_found=0

    # Cross-platform process killer (Linux / macOS)
    for client in discord discord-ptb discord-canary discord-development Discord DiscordPTB DiscordCanary DiscordDevelopment; do
        if pkill -f "$client" >> "$LOG_FILE" 2>&1; then
            discord_found=1
        fi
    done

    if [[ "$discord_found" -eq 1 ]]; then
        ok "Discord clients terminated."
    else
        echo -e "  ${NC}[INFO] No active Discord clients were running."
    fi
    echo
}

create_backup_silent() {
    if [[ -d "$INSTALL_DIR" ]]; then
        rm -rf "$BACKUP_DIR"
        cp -R "$INSTALL_DIR" "$BACKUP_DIR"
    fi
}

create_backup() {
    if [[ ! -d "$INSTALL_DIR" ]]; then
        fail "Nothing to backup, MallCord folder does not exist."
        return
    fi
    rm -rf "$BACKUP_DIR"
    cp -R "$INSTALL_DIR" "$BACKUP_DIR"
    ok "Backup created at: $BACKUP_DIR"
}

restore_backup() {
    if [[ ! -d "$BACKUP_DIR" ]]; then
        fail "No previous backup found!"
        return
    fi
    step "Restoring backup..."
    rm -rf "$INSTALL_DIR"
    cp -R "$BACKUP_DIR" "$INSTALL_DIR"
    ok "Previous state successfully restored!"
}

# ============================================================================
#  MAIN MENU & FLOWS
# ============================================================================

clear
echo -e "\n  ${MAGENTA}${BOLD}Private MallCord Setup${NC}"
echo -e "  -------------------------------------------------------"
echo
echo -e "  ${CYAN}[1]${NC} Install / Update MallCord (Recommended)"
echo -e "  ${CYAN}[2]${NC} Completely Uninstall MallCord"
echo -e "  ${CYAN}[3]${NC} Check and Terminate Discord Clients"
echo -e "  ${CYAN}[4]${NC} Manually Check and Fix Dependencies"
echo -e "  ${CYAN}[5]${NC} Create Backup / Rollback"
echo -e "  ${CYAN}[6]${NC} Exit"
echo
echo -n "  Choose an option: "
read -r MENU_CHOICE
echo

case "$MENU_CHOICE" in
    1)
        clear
        echo -e "${MAGENTA}=== MallCord Installation and Update Process ===${NC}\n"
        check_dependencies
        kill_discord

        # Git Operations
        step "Downloading and updating source code (GitHub)..."
        if [[ -d "$INSTALL_DIR/.git" ]]; then
            echo -e "      MallCord found at $INSTALL_DIR."
            create_backup_silent
            git -C "$INSTALL_DIR" fetch origin main >> "$LOG_FILE" 2>&1 || die "git fetch failed."
            git -C "$INSTALL_DIR" reset --hard origin/main >> "$LOG_FILE" 2>&1 || die "git reset failed."
            ok "Local repository successfully synchronized."
        elif [[ -d "$INSTALL_DIR" ]]; then
            warn "The folder exists but is not a Git repository."
            echo -n "  Can I delete the existing folder for a clean reinstallation? [y/N]: "
            read -r ans
            if [[ "$ans" =~ ^[Yy]$ ]]; then
                rm -rf "$INSTALL_DIR"
                git clone "$REPO_URL" "$INSTALL_DIR" >> "$LOG_FILE" 2>&1 || die "Cloning failed."
            else
                die "Installation cannot proceed."
            fi
        else
            git clone "$REPO_URL" "$INSTALL_DIR" >> "$LOG_FILE" 2>&1 || die "Cloning failed."
            ok "Cloning completed successfully."
        fi
        echo

        # Build and Inject
        cd "$INSTALL_DIR"
        step "Installing dependencies (pnpm install)..."
        pnpm install --no-frozen-lockfile >> "$LOG_FILE" 2>&1 || die "pnpm install failed."

        step "Building MallCord source code..."
        pnpm build >> "$LOG_FILE" 2>&1 || die "Build process failed."
        ok "Successfully built."

        step "Injecting into Discord clients..."
        pnpm inject >> "$LOG_FILE" 2>&1 || die "Injection failed. Make sure Discord is installed."
        ok "MallCord successfully injected into Discord!"

        echo -e "\n${GREEN}${BOLD}  ======================================================="
        echo -e "     THE OPERATION COMPLETED SUCCESSFULLY!"
        echo -e "     You can now start Discord."
        echo -e "  =======================================================${NC}\n"
        ;;

    2)
        clear
        echo -e "${MAGENTA}=== MallCord Uninstallation Process ===${NC}\n"
        kill_discord
        if [[ ! -d "$INSTALL_DIR" ]]; then
            die "MallCord installation not found at $INSTALL_DIR."
        fi
        cd "$INSTALL_DIR"
        step "Removing MallCord from Discord clients (uninject)..."
        pnpm uninject >> "$LOG_FILE" 2>&1 || warn "Uninject reported an error. It might have already been removed."
        ok "Successfully removed from Discord."
        echo
        echo -n "  Would you like to delete the entire source code folder too ($INSTALL_DIR)? [y/N]: "
        read -r DEL_CHOICE
        if [[ "$DEL_CHOICE" =~ ^[Yy]$ ]]; then
            rm -rf "$INSTALL_DIR"
            ok "MallCord folder completely deleted."
        else
            ok "Folder left untouched."
        fi
        ;;

    3)
        clear
        echo -e "${MAGENTA}=== Analyzing Discord Clients ===${NC}\n"
        kill_discord
        ok "Discord process management completed."
        ;;

    4)
        clear
        echo -e "${MAGENTA}=== Detailed Dependency Check ===${NC}\n"
        check_dependencies
        ok "All environment variables and software are correct!"
        ;;

    5)
        clear
        echo -e "${MAGENTA}=== Backup and Restore ===${NC}\n"
        echo -e "  [1] Backup current MallCord folder"
        echo -e "  [2] Restore last backup (Rollback)"
        echo -e "  [3] Back to Main Menu"
        echo
        echo -n "  Choose an option: "
        read -r BK_CHOICE
        case "$BK_CHOICE" in
            1) create_backup ;;
            2) restore_backup ;;
            *) exit 0 ;;
        esac
        ;;

    *)
        echo -e "${CYAN}Thank you for using Private MallCord Setup! Have a great day!${NC}"
        exit 0
        ;;
esac
