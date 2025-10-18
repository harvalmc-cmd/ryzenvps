#!/bin/bash
set -euo pipefail

# RyzenVPS Colors
RED='\e[31m'
GREEN='\e[32m'
YELLOW='\e[33m'
BLUE='\e[34m'
PURPLE='\e[35m'
CYAN='\e[36m'
RESET='\e[0m'

show_ryzen_logo() {
    clear
    echo -e "${PURPLE}"
    cat << "EOF"
██████╗░██╗░░░██╗███████╗███████╗███╗░░██╗
██╔══██╗╚██╗░██╔╝╚════██║██╔════╝████╗░██║
██████╔╝░╚████╔╝░░░███╔═╝█████╗░░██╔██╗██║
██╔══██╗░░╚██╔╝░░██╔══╝░░██╔══╝░░██║╚████║
██║░░██║░░░██║░░░███████╗███████╗██║░╚███║
╚═╝░░╚═╝░░░╚═╝░░░╚══════╝╚══════╝╚═╝░░╚══╝
EOF
    echo -e "${RESET}"
    echo -e "${CYAN}           Ultimate VPS Solution${RESET}"
    echo -e "${YELLOW}           Powered by RyzenVPS${RESET}"
    echo ""
}

check_dependencies() {
    echo -e "${YELLOW}Checking system dependencies...${RESET}"
    
    # Check for Docker (fallback for IDX)
    if command -v docker &>/dev/null; then
        echo -e "${GREEN}✓ Docker available${RESET}"
        return 0
    else
        echo -e "${YELLOW}⚠ Docker not found - installing...${RESET}"
        sudo apt update && sudo apt install -y docker.io
        sudo systemctl start docker
        sudo usermod -aG docker $USER
        return 0
    fi
}

main_menu() {
    while true; do
        show_ryzen_logo
        echo -e "${YELLOW}╔════════════════════════════════════════╗${RESET}"
        echo -e "${YELLOW}║           RyzenVPS Main Menu           ║${RESET}"
        echo -e "${YELLOW}╚════════════════════════════════════════╝${RESET}"
        echo ""
        echo -e "${GREEN}1) GitHub Codespaces VPS${RESET}"
        echo -e "${BLUE}2) Google IDX Real VPS${RESET}"
        echo -e "${RED}3) Exit${RESET}"
        echo ""
        echo -ne "${YELLOW}Enter your choice (1-3): ${RESET}"
        read choice

        case $choice in
            1|2)
                echo -e "${GREEN}Starting RyzenVPS VM Manager...${RESET}"
                sleep 2
                # Download and run VM manager
                curl -fsSL https://raw.githubusercontent.com/harvalmc-cmd/ryzenvps/main/vm-manager.sh | bash
                ;;
            3)
                echo -e "${RED}Thank you for using RyzenVPS!${RESET}"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid choice! Please select 1-3.${RESET}"
                sleep 2
                ;;
        esac
    done
}

# Check if we're in IDX and setup environment
if [[ -n "$GOOGLE_CLOUD_PROJECT" ]] || [[ -f /.dockerenv ]]; then
    echo -e "${BLUE}Google IDX Environment Detected${RESET}"
    # Create IDX configuration if needed
    if [ ! -d ".idx" ]; then
        mkdir -p .idx
        cat > .idx/dev.nix << 'EOF'
{ pkgs, ... }: {
  channel = "stable-24.05";
  packages = with pkgs; [
    docker docker-compose curl wget git unzip
    php82 mysql80 nginx redis
  ];
  idx.extensions = ["ms-vscode.vscode-node-azure-pack"];
}
EOF
    fi
fi

# Start RyzenVPS
check_dependencies
main_menu
