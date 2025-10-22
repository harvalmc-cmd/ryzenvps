#!/bin/bash
set -euo pipefail

# ===============================
# Ryzen VPS Management Branding
# ===============================
RYZEN_ASCII="
██████╗░██╗░░░██╗███████╗███████╗███╗░░██╗
██╔══██╗╚██╗░██╔╝╚════██║██╔════╝████╗░██║
██████╔╝░╚████╔╝░░░███╔═╝█████╗░░██╔██╗██║
██╔══██╗░░╚██╔╝░░██╔══╝░░██╔══╝░░██║╚████║
██║░░██║░░░██║░░░███████╗███████╗██║░╚███║
╚═╝░░╚═╝░░░╚═╝░░░╚══════╝╚══════╝╚═╝░░╚══╝
          VPS MANAGEMENT TOOL
"

# ===============================
# Colors
# ===============================
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
RED="\033[1;31m"
CYAN="\033[1;36m"
BLUE="\033[0;34m"
MAGENTA="\033[0;35m"
WHITE="\033[1;37m"
NC="\033[0m"

LOG_FILE="/var/log/ryzen_installer.log"

# ===============================
# Output functions
# ===============================
print_header() {
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN} $1 ${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

print_status() { echo -e "${YELLOW}⏳ $1...${NC}"; }
print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }
print_warning() { echo -e "${MAGENTA}⚠️  $1${NC}"; }

log_action() {
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

animate_progress() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    while kill -0 "$pid" 2>/dev/null; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# ===============================
# Welcome Animation
# ===============================
welcome_animation() {
    clear
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}$RYZEN_ASCII${NC}"
    echo -e "${CYAN}           Blueprint Installer v1.0${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    sleep 2
}

# ===============================
# Installation Functions
# ===============================
install_nobita() {
    print_header "FRESH INSTALLATION"
    if [ "$EUID" -ne 0 ]; then
        print_error "Please run this script as root"
        return 1
    fi

    read -rp "$(echo -e "${YELLOW}Do you want to continue with Fresh Install? (y/N): ${NC}")" confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        print_warning "Fresh installation canceled"
        return 1
    fi

    log_action "Starting fresh installation"

    # Example Step: Node.js 20.x
    print_header "INSTALLING NODE.JS 20.x"
    print_status "Installing dependencies"
    sudo apt-get install -y ca-certificates curl gnupg > /dev/null 2>&1 &
    animate_progress $!
    log_action "Node.js dependencies installed"

    print_status "Setting up Node.js repository"
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" | sudo tee /etc/apt/sources.list.d/nodesource.list >/dev/null

    print_status "Updating package lists"
    sudo apt-get update > /dev/null 2>&1 &
    animate_progress $!

    print_status "Installing Node.js"
    sudo apt-get install -y nodejs > /dev/null 2>&1 &
    animate_progress $!
    print_success "Node.js installed"

    # Log installation step
    log_action "Node.js installed successfully"

    # --- Additional steps: Yarn, Nobita Hosting release, etc ---
    # You can replicate previous steps here, just like your original script
}

reinstall_nobita() {
    print_header "REINSTALLING NOBITA HOSTING"
    read -rp "$(echo -e "${YELLOW}Are you sure you want to reinstall? (y/N): ${NC}")" confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        print_warning "Reinstallation canceled"
        return 1
    fi
    print_status "Reinstalling..."
    log_action "Reinstallation started"
    # Run your reinstallation commands here
    sleep 2
    print_success "Reinstallation completed"
    log_action "Reinstallation finished"
}

update_nobita() {
    print_header "UPDATING NOBITA HOSTING"
    read -rp "$(echo -e "${YELLOW}Proceed with update? (y/N): ${NC}")" confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        print_warning "Update canceled"
        return 1
    fi
    print_status "Updating..."
    log_action "Update started"
    # Run your update commands here
    sleep 2
    print_success "Update completed"
    log_action "Update finished"
}

# ===============================
# Menu System
# ===============================
show_menu() {
    clear
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}$RYZEN_ASCII${NC}"
    echo -e "${CYAN}           Blueprint Installer v1.0${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${WHITE}║                📋 MAIN MENU                   ║${NC}"
    echo -e "${WHITE}╠═══════════════════════════════════════════════╣${NC}"
    echo -e "${WHITE}║   ${GREEN}1)${NC} ${CYAN}Fresh Install${NC}                         ${WHITE}║${NC}"
    echo -e "${WHITE}║   ${GREEN}2)${NC} ${CYAN}Reinstall (Rerun Only)${NC}                ${WHITE}║${NC}"
    echo -e "${WHITE}║   ${GREEN}3)${NC} ${CYAN}Update Nobita Hosting${NC}                 ${WHITE}║${NC}"
    echo -e "${WHITE}║   ${GREEN}0)${NC} ${RED}Exit${NC}                               ${WHITE}║${NC}"
    echo -e "${WHITE}╚═══════════════════════════════════════════════╝${NC}"
    echo -e "${YELLOW}📝 Select an option [0-3]: ${NC}"
}

# ===============================
# Main Execution
# ===============================
welcome_animation

while true; do
    show_menu
    read -r choice

    case $choice in
        1) install_nobita ;;
        2) reinstall_nobita ;;
        3) update_nobita ;;
        0)
            echo -e "${GREEN}Exiting Blueprint Installer...${NC}"
            echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            echo -e "${CYAN}           Thank you for using Ryzen VPS Management!${NC}"
            echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            exit 0
            ;;
        *)
            print_error "Invalid option! Please choose between 0-3"
            sleep 2
            ;;
    esac

    echo -e ""
    read -rp "$(echo -e "${YELLOW}Press Enter to return to Main Menu...${NC}")"
done
