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
NC="\033[0m"

print_header() {
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN} $1 ${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

print_status() { echo -e "${YELLOW}⏳ $1...${NC}"; }
print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }

# ===============================
# Banner
# ===============================
clear
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}$RYZEN_ASCII${NC}"
echo -e "${CYAN}       Cloudflared Installer by Ryzen VPS Management${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

# ===============================
# Root check
# ===============================
if [ "$EUID" -ne 0 ]; then
    print_error "Please run this script as root or with sudo"
    exit 1
fi

print_header "STARTING CLOUDFLARED INSTALLATION"

# Step 1: Create keyrings directory
print_status "Creating keyrings directory"
mkdir -p --mode=0755 /usr/share/keyrings
print_success "Keyrings directory created"

# Step 2: Add Cloudflare GPG key
print_status "Adding Cloudflare GPG key"
curl -fsSL https://pkg.cloudflare.com/cloudflare-main.gpg | tee /usr/share/keyrings/cloudflare-main.gpg >/dev/null
print_success "Cloudflare GPG key added"

# Step 3: Add Cloudflare repository
print_status "Adding Cloudflare repository"
echo 'deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] https://pkg.cloudflare.com/cloudflared any main' | tee /etc/apt/sources.list.d/cloudflared.list >/dev/null
print_success "Cloudflare repository added"

# Step 4: Update & install
print_status "Updating package list and installing cloudflared"
apt-get update -y >/dev/null
apt-get install -y cloudflared >/dev/null
print_success "Cloudflared installation completed"

# Step 5: Verify
print_status "Verifying Cloudflared installation"
if command -v cloudflared >/dev/null 2>&1; then
    print_success "Cloudflared installed successfully!"
else
    print_error "Cloudflared installation failed."
fi

print_header "INSTALLATION COMPLETE"
echo -e "${CYAN}Use command: ${GREEN}cloudflared${NC} to start using Cloudflared"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
