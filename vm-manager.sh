#!/bin/bash
set -euo pipefail

# RyzenVPS VM Manager
RED='\e[31m'
GREEN='\e[32m'
YELLOW='\e[33m'
BLUE='\e[34m'
PURPLE='\e[35m'
CYAN='\e[36m'
RESET='\e[0m'

show_vm_header() {
    clear
    echo -e "${PURPLE}"
    cat << "EOF"
╔════════════════════════════════════════╗
║           RyzenVPS VM Manager          ║
╚════════════════════════════════════════╝
EOF
    echo -e "${RESET}"
}

create_docker_vps() {
    show_vm_header
    echo -e "${CYAN}Creating RyzenVPS Docker Container...${RESET}"
    
    # OS Selection
    echo -e "${YELLOW}Select OS:${RESET}"
    echo "1) Ubuntu 22.04"
    echo "2) Ubuntu 24.04"
    echo "3) Debian 11"
    echo "4) Debian 12"
    
    read -p "Enter choice (1-4): " os_choice
    case $os_choice in
        1) OS_IMAGE="ubuntu:22.04"; OS_NAME="Ubuntu 22.04" ;;
        2) OS_IMAGE="ubuntu:24.04"; OS_NAME="Ubuntu 24.04" ;;
        3) OS_IMAGE="debian:11"; OS_NAME="Debian 11" ;;
        4) OS_IMAGE="debian:12"; OS_NAME="Debian 12" ;;
        *) echo -e "${RED}Invalid choice${RESET}"; return 1 ;;
    esac
    
    read -p "Enter VPS name: " VPS_NAME
    read -p "Enter SSH port [2222]: " SSH_PORT
    SSH_PORT=${SSH_PORT:-2222}
    
    read -p "Enter username [ryzen]: " USERNAME
    USERNAME=${USERNAME:-ryzen}
    
    read -s -p "Enter password [ryzen123]: " PASSWORD
    PASSWORD=${PASSWORD:-ryzen123}
    echo
    
    read -p "Memory limit [2G]: " MEMORY
    MEMORY=${MEMORY:-2G}
    
    echo -e "${YELLOW}Creating VPS '$VPS_NAME' ($OS_NAME)...${RESET}"
    
    # Create Docker container
    sudo docker run -d \
        --name "$VPS_NAME" \
        --restart unless-stopped \
        -p "$SSH_PORT":22 \
        -p "80$SSH_PORT":80 \
        -p "443$SSH_PORT":443 \
        --memory "$MEMORY" \
        "$OS_IMAGE" \
        sleep infinity
        
    # Setup container
    sudo docker exec "$VPS_NAME" bash -c "
        apt update && apt install -y openssh-server sudo curl wget
        useradd -m -s /bin/bash $USERNAME
        echo '$USERNAME:$PASSWORD' | chpasswd
        echo 'root:$PASSWORD' | chpasswd  
        sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
        sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
        mkdir -p /run/sshd
        /usr/sbin/sshd
    "
    
    echo -e "${GREEN}✅ VPS '$VPS_NAME' created successfully!${RESET}"
    echo -e "${BLUE}📦 SSH Access: ssh $USERNAME@localhost -p $SSH_PORT${RESET}"
    echo -e "${BLUE}🔑 Password: $PASSWORD${RESET}"
    echo -e "${YELLOW}💡 Run this inside VPS to install Pterodactyl:${RESET}"
    echo -e "${CYAN}bash <(curl -s https://raw.githubusercontent.com/harvalmc-cmd/ryzenvps/main/pterodactyl.sh)${RESET}"
}

list_vps() {
    show_vm_header
    echo -e "${CYAN}Current RyzenVPS Containers:${RESET}"
    sudo docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
}

start_vps() {
    show_vm_header
    list_vps
    echo ""
    read -p "Enter VPS name to start: " VPS_NAME
    sudo docker start "$VPS_NAME"
    echo -e "${GREEN}✅ VPS '$VPS_NAME' started!${RESET}"
}

stop_vps() {
    show_vm_header
    list_vps
    echo ""
    read -p "Enter VPS name to stop: " VPS_NAME
    sudo docker stop "$VPS_NAME"
    echo -e "${YELLOW}⚠ VPS '$VPS_NAME' stopped!${RESET}"
}

vm_menu() {
    while true; do
        show_vm_header
        echo -e "${CYAN}VM Management Menu:${RESET}"
        echo "1) Create a new VPS"
        echo "2) Start a VPS"
        echo "3) Stop a VPS"
        echo "4) List all VPS"
        echo "5) Access VPS Shell"
        echo "0) Exit"
        echo ""
        echo -ne "${YELLOW}Enter your choice (0-5): ${RESET}"
        read choice

        case $choice in
            1) create_docker_vps ;;
            2) start_vps ;;
            3) stop_vps ;;
            4) list_vps ;;
            5) 
                list_vps
                echo ""
                read -p "Enter VPS name to access: " VPS_NAME
                sudo docker exec -it "$VPS_NAME" bash
                ;;
            0)
                echo -e "${GREEN}Returning to main menu...${RESET}"
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

# Start VM Manager
vm_menu
