#!/bin/bash
set -euo pipefail

# -----------------------
# Ryzen Branding ASCII
# -----------------------
RYZEN_ASCII="
██████╗░██╗░░░██╗███████╗███████╗███╗░░██╗
██╔══██╗╚██╗░██╔╝╚════██║██╔════╝████╗░██║
██████╔╝░╚████╔╝░░░███╔═╝█████╗░░██╔██╗██║
██╔══██╗░░╚██╔╝░░██╔══╝░░██╔══╝░░██║╚████║
██║░░██║░░░██║░░░███████╗███████╗██║░╚███║
╚═╝░░╚═╝░░░╚═╝░░░╚══════╝╚══════╝╚═╝░░╚══╝
            VPS MANAGEMENT TOOL
"

# -----------------------
# Colors & helpers
# -----------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

print_header() {
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN} $1 ${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

print_status() { echo -e "${YELLOW}⏳ $1...${NC}"; }
print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }

spinner() {
    local pid=$1
    local delay=0.08
    local spinstr='|/-\'
    while kill -0 "$pid" 2>/dev/null; do
        for i in $(seq 0 3); do
            printf " [%c]" "${spinstr:i:1}"
            sleep $delay
            printf "\b\b\b"
        done
    done
    printf "    \b\b\b\b"
}

check_success() {
    if [ $? -eq 0 ]; then
        print_success "$1"
    else
        print_error "$2"
        exit 1
    fi
}

# -----------------------
# Banner
# -----------------------
clear
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}$RYZEN_ASCII${NC}"
echo -e "${CYAN}        Wings Installer by Ryzen VPS Management${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

# -----------------------
# Root check
# -----------------------
if [ "$EUID" -ne 0 ]; then
    print_error "Please run this script as root or with sudo"
    exit 1
fi

print_header "STARTING WINGS INSTALLATION"

# -----------------------
# Docker Install
# -----------------------
print_header "INSTALLING DOCKER"
print_status "Installing Docker"
curl -sSL https://get.docker.com/ | CHANNEL=stable bash > /dev/null 2>&1 &
spinner $!
check_success "Docker installed" "Failed to install Docker"

print_status "Starting Docker service"
systemctl enable --now docker > /dev/null 2>&1
check_success "Docker service started" "Failed to start Docker"

# -----------------------
# Update GRUB
# -----------------------
print_header "UPDATING SYSTEM CONFIGURATION"
GRUB_FILE="/etc/default/grub"
if [ -f "$GRUB_FILE" ]; then
    print_status "Updating GRUB configuration"
    sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT="swapaccount=1"/' $GRUB_FILE
    update-grub > /dev/null 2>&1
    check_success "GRUB updated" "Failed to update GRUB"
else
    print_status "GRUB configuration file not found, skipping"
fi

# -----------------------
# Wings Install
# -----------------------
print_header "INSTALLING WINGS"
print_status "Creating directory"
mkdir -p /etc/pterodactyl
check_success "Directory created" "Failed to create directory"

print_status "Detecting architecture"
ARCH=$(uname -m)
if [ "$ARCH" == "x86_64" ]; then ARCH="amd64"; else ARCH="arm64"; fi
print_success "Detected $ARCH architecture"

print_status "Downloading Wings"
curl -L -o /usr/local/bin/wings "https://github.com/pterodactyl/wings/releases/latest/download/wings_linux_$ARCH" > /dev/null 2>&1 &
spinner $!
check_success "Wings downloaded" "Failed to download Wings"

print_status "Setting permissions"
chmod u+x /usr/local/bin/wings
check_success "Permissions set" "Failed to set permissions"

# -----------------------
# Wings Service
# -----------------------
print_header "CONFIGURING WINGS SERVICE"
WINGS_SERVICE="/etc/systemd/system/wings.service"
tee $WINGS_SERVICE > /dev/null <<EOF
[Unit]
Description=Pterodactyl Wings Daemon
After=docker.service
Requires=docker.service
PartOf=docker.service

[Service]
User=root
WorkingDirectory=/etc/pterodactyl
LimitNOFILE=4096
PIDFile=/var/run/wings/daemon.pid
ExecStart=/usr/local/bin/wings
Restart=on-failure
StartLimitInterval=180
StartLimitBurst=30
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF

print_status "Reloading systemd"
systemctl daemon-reload > /dev/null 2>&1
check_success "Daemon reloaded" "Failed to reload systemd"

print_status "Enabling Wings service"
systemctl enable wings > /dev/null 2>&1
check_success "Wings enabled" "Failed to enable Wings"

# -----------------------
# SSL Certificate
# -----------------------
print_header "GENERATING SSL CERTIFICATE"
mkdir -p /etc/certs/wing
cd /etc/certs/wing
openssl req -new -newkey rsa:4096 -days 3650 -nodes -x509 \
-subj "/C=NA/ST=NA/L=NA/O=NA/CN=Generic SSL Certificate" \
-keyout privkey.pem -out fullchain.pem > /dev/null 2>&1
check_success "SSL generated" "Failed to generate SSL"

# -----------------------
# Helper command
# -----------------------
print_header "CREATING HELPER COMMAND"
tee /usr/local/bin/wing > /dev/null <<'EOF'
#!/bin/bash
echo -e "\033[1;33mℹ️  Wings Helper Command\033[0m"
echo -e "\033[1;36mStart Wings: \033[1;32msudo systemctl start wings\033[0m"
echo -e "\033[1;36mStatus: \033[1;32msudo systemctl status wings\033[0m"
echo -e "\033[1;36mLogs: \033[1;32msudo journalctl -u wings -f\033[0m"
EOF
chmod +x /usr/local/bin/wing
check_success "Helper command created" "Failed to create helper command"

# -----------------------
# Optional Auto-config
# -----------------------
print_header "AUTO-CONFIGURATION (Optional)"
read -p "$(echo -e "${YELLOW}Do you want to auto-configure Wings now? (y/N): ${NC}")" AUTO_CONFIG
if [[ "$AUTO_CONFIG" =~ ^[Yy]$ ]]; then
    print_header "AUTO-CONFIGURING WINGS"
    read -p "Enter UUID: " UUID
    read -p "Enter Token ID: " TOKEN_ID
    read -p "Enter Token: " TOKEN
    read -p "Enter Panel URL: " REMOTE

    mkdir -p /etc/pterodactyl
    tee /etc/pterodactyl/config.yml > /dev/null <<CFG
debug: false
uuid: ${UUID}
token_id: ${TOKEN_ID}
token: ${TOKEN}
api:
  host: 0.0.0.0
  port: 8080
  ssl:
    enabled: true
    cert: /etc/certs/wing/fullchain.pem
    key: /etc/certs/wing/privkey.pem
  upload_limit: 100
system:
  data: /var/lib/pterodactyl/volumes
  sftp:
    bind_port: 2022
allowed_mounts: []
remote: '${REMOTE}'
CFG

    systemctl start wings
    print_success "Wings auto-configured & started"
else
    print_status "Auto-configuration skipped. You can configure manually later."
fi

# -----------------------
# Complete
# -----------------------
print_header "INSTALLATION COMPLETE"
echo -e "${GREEN}🎉 Wings installed successfully!${NC}"
echo -e "Use helper command: ${GREEN}wing${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
