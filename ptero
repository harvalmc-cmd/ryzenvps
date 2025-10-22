#!/bin/bash
set -e

# ✅ Auto re-run script with sudo if not root
if [ "$EUID" -ne 0 ]; then
   echo -e "\033[1;31m[!] This script requires root privileges... Re-running with sudo!\033[0m"
   sudo bash "$0" "$@"
   exit
fi

# Colors
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; MAGENTA='\033[0;35m'
WHITE='\033[1;37m'; BOLD='\033[1m'; NC='\033[0m'

# ---------- Header & Branding ----------
print_header_rule() { echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"; }

big_header() {
    local title="$1"
    echo -e "${CYAN}"
    case "$title" in
        "MAIN MENU" | "WELCOME" | "SYSTEM INFORMATION")
cat <<'EOF'
██████╗░██╗░░░██╗███████╗███████╗███╗░░██╗
██╔══██╗╚██╗░██╔╝╚════██║██╔════╝████╗░██║
██████╔╝░╚████╔╝░░░███╔═╝█████╗░░██╔██╗██║
██╔══██╗░░╚██╔╝░░██╔══╝░░██╔══╝░░██║╚████║
██║░░██║░░░██║░░░███████╗███████╗██║░╚███║
╚═╝░░╚═╝░░░╚═╝░░░╚══════╝╚══════╝╚═╝░░╚══╝
EOF
            ;;
        *) echo -e "${BOLD}${title}${NC}" ;;
    esac
    echo -e "${NC}"
}

# ---------- Status Functions ----------
print_status() { echo -e "${YELLOW}⏳ $1...${NC}"; }
print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_error()  { echo -e "${RED}❌ $1${NC}"; }

# ---------- Curl Check ----------
check_curl() {
    if ! command -v curl &>/dev/null; then
        print_error "curl not installed — installing..."
        apt-get update -y && apt-get install -y curl || {
            print_error "curl installation failed"; exit 1;
        }
        print_success "curl installed"
    fi
}

# ---------- Run Remote Scripts (root-safe) ----------
run_remote_script() {
    local url=$1
    local name=$(basename "$url")

    print_header_rule
    big_header "WELCOME"
    print_status "Downloading & running: $name"

    check_curl
    temp_script=$(mktemp)

    if curl -fsSL "$url" -o "$temp_script"; then
        chmod +x "$temp_script"
        sudo bash "$temp_script"  # ✅ Always run as root
        print_success "$name executed"
    else
        print_error "Failed to download $url"
    fi

    rm -f "$temp_script"
    read -p "Press Enter to continue..." -n 1
}

# ---------- System Information ----------
system_info() {
    print_header_rule
    big_header "SYSTEM INFORMATION"
    print_header_rule

    echo -e "${WHITE} Hostname: ${NC}$(hostname)"
    echo -e "${WHITE} User:     ${NC}$(whoami)"
    echo -e "${WHITE} System:   ${NC}$(uname -srm)"
    echo -e "${WHITE} Uptime:   ${NC}$(uptime -p)"
    echo -e "${WHITE} Memory:   ${NC}$(free -h | awk '/Mem/ {print $3"/"$2}')"
    echo -e "${WHITE} Disk:     ${NC}$(df -h / | awk 'NR==2 {print $3"/"$2" ("$5")"}')"

    read -p "Press Enter to continue..." -n 1
}

# ---------- Menu ----------
show_menu() {
    clear
    print_header_rule
    echo -e "${CYAN}         🚀 RyzenVPS Manager${NC}"
    print_header_rule
    big_header "MAIN MENU"
    print_header_rule

    echo -e " 1) Panel Install"
    echo -e " 2) Wings Install"
    echo -e " 3) Panel Update"
    echo -e " 4) Uninstall Tools"
    echo -e " 5) Blueprint Setup"
    echo -e " 6) Cloudflare Setup"
    echo -e " 7) Change Theme"
    echo -e " 8) System Info"
    echo -e " 9) Install + Enable Tailscale"
    echo -e " 0) Exit"
}

# ---------- Welcome ----------
echo -e "${CYAN}Starting RyzenVPS Manager...${NC}"
sleep 1

# ---------- Main Loop ----------
while true; do
    show_menu
    read -r choice

    case $choice in
        1) run_remote_script "https://raw.githubusercontent.com/harvalmc-cmd/ryzenvps/main/panel2.sh" ;;
        2) run_remote_script "https://raw.githubusercontent.com/harvalmc-cmd/ryzenvps/main/wing2.sh" ;;
        3) run_remote_script "https://raw.githubusercontent.com/harvalmc-cmd/ryzenvps/main/update2.sh" ;;
        4) run_remote_script "https://raw.githubusercontent.com/harvalmc-cmd/ryzenvps/main/uninstall2.sh" ;;
        5) run_remote_script "https://raw.githubusercontent.com/harvalmc-cmd/ryzenvps/main/Blueprint2.sh" ;;
        6) run_remote_script "https://raw.githubusercontent.com/harvalmc-cmd/ryzenvps/main/cloudflare.sh" ;;
        7) run_remote_script "https://raw.githubusercontent.com/harvalmc-cmd/ryzenvps/main/th2.sh" ;;
        8) system_info ;;
        9)
            print_status "Installing Tailscale..."
            curl -fsSL https://tailscale.com/install.sh | sh
            systemctl enable --now tailscaled
            tailscale up || print_error "Tailscale setup failed"
            ;;
        0) echo -e "${GREEN}Exiting RyzenVPS Manager...${NC}"; exit 0 ;;
        *) print_error "Invalid option!" ;;
    esac
done
