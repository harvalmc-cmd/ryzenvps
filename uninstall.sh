#!/bin/bash
set -euo pipefail

# ===============================
# Colors for output
# ===============================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

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

# Animated progress function
animate_progress() {
    local pid=$1
    local message=$2
    local delay=0.1
    local spinstr='|/-\'
    print_status "$message"
    while kill -0 "$pid" 2>/dev/null; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# ===============================
# Confirm action
# ===============================
confirm_action() {
    local message="$1"
    echo -e "${YELLOW}$message${NC}"
    read -p "$(echo -e "${YELLOW}Are you sure? (y/N): ${NC}")" -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]]
}

# ===============================
# Uninstall Functions
# ===============================
cleanup_nginx() {
    print_status "Cleaning Nginx configurations for Pterodactyl"
    for conf in /etc/nginx/sites-enabled/pterodactyl.conf /etc/nginx/sites-available/pterodactyl.conf /etc/nginx/conf.d/pterodactyl.conf; do
        if [[ -f "$conf" ]]; then
            sudo rm -f "$conf"
            print_success "Removed $conf"
        fi
    done
    if command -v nginx >/dev/null 2>&1; then
        sudo systemctl restart nginx
        print_success "Nginx reloaded"
    fi
}

uninstall_panel() {
    print_header "UNINSTALLING PTERODACTYL PANEL"
    if ! confirm_action "This will remove the Pterodactyl Panel and all its data."; then return; fi

    print_status "Stopping panel service"
    sudo systemctl stop pteroq.service 2>/dev/null || true
    sudo systemctl disable pteroq.service 2>/dev/null || true
    sudo rm -f /etc/systemd/system/pteroq.service
    sudo systemctl daemon-reload
    print_success "Panel service stopped and disabled"

    print_status "Removing Panel cronjob"
    sudo crontab -l | grep -v 'php /var/www/pterodactyl/artisan schedule:run' | sudo crontab - 2>/dev/null || true
    print_success "Cronjob removed"

    print_status "Removing Panel files"
    sudo rm -rf /var/www/pterodactyl
    print_success "Panel files removed"

    print_status "Dropping Panel database and user"
    sudo mysql -u root -e "DROP DATABASE IF EXISTS panel;" 2>/dev/null || true
    sudo mysql -u root -e "DROP USER IF EXISTS 'pterodactyl'@'127.0.0.1';" 2>/dev/null || true
    sudo mysql -u root -e "FLUSH PRIVILEGES;" 2>/dev/null || true
    print_success "Database and user removed"

    cleanup_nginx
    print_success "Panel uninstalled successfully!"
}

uninstall_wings() {
    print_header "UNINSTALLING PTERODACTYL WINGS"
    if ! confirm_action "This will remove Wings and all its data."; then return; fi

    print_status "Stopping Wings service"
    sudo systemctl stop wings.service 2>/dev/null || true
    sudo systemctl disable wings.service 2>/dev/null || true
    sudo rm -f /etc/systemd/system/wings.service
    sudo systemctl daemon-reload
    print_success "Wings service stopped and disabled"

    print_status "Removing Wings files"
    sudo rm -rf /etc/pterodactyl /var/lib/pterodactyl /var/log/pterodactyl
    sudo rm -f /usr/local/bin/wings /usr/local/bin/wing
    print_success "Wings files removed"

    print_success "Wings uninstalled successfully!"
}

uninstall_both() {
    print_header "UNINSTALLING BOTH PANEL AND WINGS"
    if ! confirm_action "This will remove both Pterodactyl Panel and Wings completely."; then return; fi

    uninstall_panel
    uninstall_wings
    print_success "Panel and Wings uninstalled together successfully!"
}

# ===============================
# Menu
# ===============================
show_menu() {
    clear
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}            🗑️ PTERODACTYL UNINSTALLER            ${NC}"
    echo -e "${CYAN}                 by Nobita-hosting               ${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e ""
    echo -e "${YELLOW}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║                📋 MENU OPTIONS                ║${NC}"
    echo -e "${YELLOW}╠═══════════════════════════════════════════════╣${NC}"
    echo -e "${YELLOW}║   ${GREEN}1)${NC} ${CYAN}Uninstall Panel Only${NC}                  ${YELLOW}║${NC}"
    echo -e "${YELLOW}║   ${GREEN}2)${NC} ${CYAN}Uninstall Wings Only${NC}                  ${YELLOW}║${NC}"
    echo -e "${YELLOW}║   ${GREEN}3)${NC} ${CYAN}Uninstall Panel + Wings${NC}               ${YELLOW}║${NC}"
    echo -e "${YELLOW}║   ${GREEN}0)${NC} ${RED}Exit Uninstaller${NC}                     ${YELLOW}║${NC}"
    echo -e "${YELLOW}╚═══════════════════════════════════════════════╝${NC}"
    echo -e ""
    echo -e "${MAGENTA}⚠️  Warning: These actions cannot be undone!${NC}"
    echo -e ""
}

# ===============================
# Main loop
# ===============================
while true; do
    show_menu
    read -p "$(echo -e "${YELLOW}Choose an option [0-3]: ${NC}")" choice

    case $choice in
        1) uninstall_panel ;;
        2) uninstall_wings ;;
        3) uninstall_both ;;
        0) 
            echo -e "${GREEN}Exiting uninstaller...${NC}"
            exit 0 ;;
        *) 
            print_error "Invalid option! Please choose 0-3"
            sleep 2 ;;
    esac

    echo -e ""
    read -p "$(echo -e "${YELLOW}Press Enter to return to menu...${NC}")" -n 1
done
