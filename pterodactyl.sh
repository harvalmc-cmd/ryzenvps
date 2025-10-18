#!/bin/bash
set -euo pipefail

# RyzenVPS Pterodactyl Installer
RED='\e[31m'
GREEN='\e[32m'
YELLOW='\e[33m'
BLUE='\e[34m'
PURPLE='\e[35m'
CYAN='\e[36m'
RESET='\e[0m'

show_ptero_header() {
    clear
    echo -e "${PURPLE}"
    cat << "EOF"
╔════════════════════════════════════════╗
║        RyzenVPS Pterodactyl Menu       ║
╚════════════════════════════════════════╝
EOF
    echo -e "${RESET}"
}

install_panel() {
    show_ptero_header
    echo -e "${CYAN}Installing Pterodactyl Panel...${RESET}"
    
    read -p "Enter admin email: " ADMIN_EMAIL
    read -p "Enter panel domain [panel.ryzenvps.com]: " PANEL_DOMAIN
    PANEL_DOMAIN=${PANEL_DOMAIN:-panel.ryzenvps.com}
    
    echo -e "${YELLOW}Step 1: Installing dependencies...${RESET}"
    apt update
    apt install -y curl wget git unzip tar nginx mysql-server \
        php8.1 php8.1-{cli,common,gd,mysql,mbstring,bcmath,xml,fpm,curl,zip} \
        redis-server php-redis composer
    
    echo -e "${YELLOW}Step 2: Configuring database...${RESET}"
    systemctl start mysql
    mysql -e "CREATE DATABASE pterodactyl;"
    mysql -e "CREATE USER 'pterodactyl'@'127.0.0.1' IDENTIFIED BY 'ryzen123';"
    mysql -e "GRANT ALL PRIVILEGES ON pterodactyl.* TO 'pterodactyl'@'127.0.0.1';"
    mysql -e "FLUSH PRIVILEGES;"
    
    echo -e "${YELLOW}Step 3: Downloading panel...${RESET}"
    cd /var/www
    git clone https://github.com/pterodactyl/panel.git pterodactyl
    cd pterodactyl
    
    composer install --no-dev --optimize-autoloader
    
    echo -e "${YELLOW}Step 4: Configuring panel...${RESET}"
    php artisan p:environment:setup \
        --author="$ADMIN_EMAIL" \
        --url="http://$PANEL_DOMAIN" \
        --timezone=UTC \
        --cache=redis \
        --session=redis \
        --queue=redis
    
    php artisan p:environment:database \
        --host=127.0.0.1 \
        --port=3306 \
        --database=pterodactyl \
        --username=pterodactyl \
        --password=ryzen123
    
    php artisan key:generate --force
    php artisan migrate --seed --force
    
    echo -e "${YELLOW}Step 5: Creating admin user...${RESET}"
    php artisan p:user:make \
        --email="$ADMIN_EMAIL" \
        --username=admin \
        --name=Admin \
        --password=ryzenadmin123 \
        --admin=1
    
    echo -e "${YELLOW}Step 6: Setting up web server...${RESET}"
    chown -R www-data:www-data /var/www/pterodactyl/*
    systemctl enable nginx php8.1-fpm
    systemctl restart nginx php8.1-fpm
    
    echo -e "${GREEN}✅ Pterodactyl Panel installed successfully!${RESET}"
    echo -e "${BLUE}🌐 Panel URL: http://$(curl -s ifconfig.me)${RESET}"
    echo -e "${BLUE}📧 Admin: $ADMIN_EMAIL${RESET}"
    echo -e "${BLUE}🔑 Password: ryzenadmin123${RESET}"
}

install_wings() {
    show_ptero_header
    echo -e "${CYAN}Installing Wings Daemon...${RESET}"
    
    read -p "Enter panel URL: " PANEL_URL
    read -p "Enter application token: " APP_TOKEN
    
    curl -L -o /usr/local/bin/wings https://github.com/pterodactyl/wings/releases/latest/download/wings_linux_x86_64
    chmod +x /usr/local/bin/wings
    mkdir -p /etc/pterodactyl
    
    wings configure --panel-url "$PANEL_URL" --token "$APP_TOKEN" --node 1
    
    cat > /etc/systemd/system/wings.service << EOF
[Unit]
Description=Pterodactyl Wings Daemon
After=docker.service

[Service]
User=root
WorkingDirectory=/etc/pterodactyl
ExecStart=/usr/local/bin/wings
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

    systemctl enable wings
    systemctl start wings
    
    echo -e "${GREEN}✅ Wings installed successfully!${RESET}"
}

ptero_menu() {
    while true; do
        show_ptero_header
        echo -e "${CYAN}Pterodactyl Installation Menu:${RESET}"
        echo "1) Panel Installation"
        echo "2) Wings Installation"
        echo "3) System Information"
        echo "0) Exit"
        echo ""
        echo -ne "${YELLOW}Enter your choice (0-3): ${RESET}"
        read choice

        case $choice in
            1) install_panel ;;
            2) install_wings ;;
            3)
                echo -e "${CYAN}System Info:${RESET}"
                echo "IP: $(curl -s ifconfig.me)"
                echo "OS: $(lsb_release -d | cut -f2)"
                echo "RAM: $(free -h | grep Mem | awk '{print $2}')"
                ;;
            0)
                echo -e "${GREEN}Thank you for using RyzenVPS!${RESET}"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid choice!${RESET}"
                sleep 2
                ;;
        esac
        echo ""
        read -p "Press Enter to continue..."
    done
}

# Check if running inside a container/VPS
if [[ -f /.dockerenv ]] || grep -q docker /proc/1/cgroup 2>/dev/null; then
    ptero_menu
else
    echo -e "${RED}❌ This script must be run inside a VPS!${RESET}"
    echo -e "${YELLOW}Create a VPS first using the main RyzenVPS setup.${RESET}"
    exit 1
fi
