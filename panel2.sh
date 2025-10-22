#!/usr/bin/env bash
# Ryzen VPS Management - Pterodactyl Installer (v1.0)
# Author: Ryzen VPS Management
set -euo pipefail

# -----------------------
# Branding ASCII
# -----------------------
RYZEN_ASCII="
██████╗░██╗░░░██╗███████╗███████╗███╗░░██╗
██╔══██╗╚██╗░██╔╝╚════██║██╔════╝████╗░██║
██████╔╝░╚████╔╝░░░███╔═╝█████╗░░██╔██╗██║
██╔══██╗░░╚██╔╝░░██╔══╝░░██╔══╝░░██║╚████║
██║░░██║░░░██║░░░███████╗███████╗██║░╚███║
╚═╝░░╚═╝░░░╚═╝░░░╚══════╝╚══════╝╚═╝░░╚══╝
"

# -----------------------
# Colors & helpers
# -----------------------
CSI="\033["
RESET="${CSI}0m"
BOLD="${CSI}1m"
DIM="${CSI}2m"

GREEN="${CSI}32m"
RED="${CSI}31m"
YELLOW="${CSI}33m"
CYAN="${CSI}36m"
BLUE="${CSI}34m"
MAGENTA="${CSI}35m"

info()    { printf "${BOLD}${CYAN}➜ %s${RESET}\n" "$*"; }
success() { printf "${BOLD}${GREEN}✔ %s${RESET}\n" "$*"; }
warn()    { printf "${BOLD}${YELLOW}⚠ %s${RESET}\n" "$*"; }
error()   { printf "${BOLD}${RED}✖ %s${RESET}\n" "$*"; }

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

confirm_root() {
  if [[ $EUID -ne 0 ]]; then
    error "This script must be run as root. Use sudo."
    exit 1
  fi
}

# -----------------------
# Configurable variables
# -----------------------
PHP_VERSION="8.3"
PANEL_DIR="/var/www/pterodactyl"
DB_NAME="panel"
DB_USER="pterodactyl"
DEFAULT_DB_PASS="ChangeMe123!"
NGINX_CONF="/etc/nginx/sites-available/pterodactyl.conf"
CERT_DIR="/etc/certs/panel"

# -----------------------
# Banner & Prompt
# -----------------------
print_banner() {
  clear
  printf "${BOLD}${MAGENTA}%s\n${RESET}" "$RYZEN_ASCII"
  printf "${BOLD}${BLUE}  ⚡ Ryzen VPS Management - Pterodactyl Installer${RESET}\n"
  printf "  ${DIM}Automated installer • Version 1.0 • © 2025 Ryzen Hosting Solutions${RESET}\n\n"
}

prompt_domain_and_db() {
  read -rp "$(printf "${BOLD}${CYAN}[?] Enter your domain (e.g., panel.example.com): ${RESET}")" DOMAIN
  DOMAIN=${DOMAIN:-panel.example.com}
  read -rsp "$(printf "${BOLD}${CYAN}[?] Enter DB password for '${DB_USER}' (leave empty to use default): ${RESET}")" DB_PASS
  echo
  DB_PASS=${DB_PASS:-$DEFAULT_DB_PASS}
}

# -----------------------
# Main installation functions
# -----------------------
basic_requirements() {
  info "Updating apt cache and installing base packages..."
  apt update -y >/dev/null &
  spinner $!
  apt install -y curl apt-transport-https ca-certificates gnupg unzip git tar sudo lsb-release software-properties-common >/dev/null &
  spinner $!
  success "Base packages installed."
}

detect_os_and_repos() {
  info "Detecting OS..."
  OS="$(lsb_release -is | tr '[:upper:]' '[:lower:]')"
  CODENAME="$(lsb_release -cs)"
  success "Detected: ${OS^} (${CODENAME})"

  if [[ "$OS" == "ubuntu" ]]; then
    info "Adding PPA for PHP (ondrej/php) on Ubuntu..."
    LC_ALL=C.UTF-8 add-apt-repository -y ppa:ondrej/php >/dev/null &
    spinner $!
  elif [[ "$OS" == "debian" ]]; then
    info "Adding Sury PHP repo for Debian..."
    curl -fsSL https://packages.sury.org/php/apt.gpg | gpg --dearmor -o /usr/share/keyrings/sury-php.gpg
    echo "deb [signed-by=/usr/share/keyrings/sury-php.gpg] https://packages.sury.org/php/ ${CODENAME} main" > /etc/apt/sources.list.d/sury-php.list
  fi

  info "Adding Redis repo & key..."
  curl -fsSL https://packages.redis.io/gpg | gpg --dearmor -o /usr/share/keyrings/redis-archive-keyring.gpg
  echo "deb [signed-by=/usr/share/keyrings/redis-archive-keyring.gpg] https://packages.redis.io/deb ${CODENAME} main" > /etc/apt/sources.list.d/redis.list

  apt update -y >/dev/null &
  spinner $!
  success "Repositories configured."
}

install_stack() {
  info "Installing PHP ${PHP_VERSION}, MariaDB, Nginx, Redis and extensions..."
  apt install -y php${PHP_VERSION} php${PHP_VERSION}-cli php${PHP_VERSION}-fpm php${PHP_VERSION}-common php${PHP_VERSION}-mysql php${PHP_VERSION}-mbstring php${PHP_VERSION}-bcmath php${PHP_VERSION}-xml php${PHP_VERSION}-zip php${PHP_VERSION}-curl php${PHP_VERSION}-gd php${PHP_VERSION}-tokenizer php${PHP_VERSION}-ctype php${PHP_VERSION}-simplexml php${PHP_VERSION}-dom mariadb-server nginx redis-server >/dev/null &
  spinner $!
  success "Core stack installed."
}

install_composer() {
  if ! command -v composer >/dev/null 2>&1; then
    info "Installing Composer..."
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer >/dev/null &
    spinner $!
    success "Composer installed at /usr/local/bin/composer"
  else
    success "Composer already installed."
  fi
}

download_pterodactyl() {
  info "Creating panel directory and downloading Pterodactyl Panel..."
  mkdir -p "${PANEL_DIR}"
  cd "${PANEL_DIR}"
  curl -Lo panel.tar.gz "https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz"
  tar -xzvf panel.tar.gz >/dev/null
  chmod -R 755 storage/* bootstrap/cache/ || true
  success "Pterodactyl panel downloaded into ${PANEL_DIR}"
}

setup_mariadb() {
  info "Configuring MariaDB..."
  mariadb -e "CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\`;" >/dev/null 2>&1 || true
  mariadb -e "CREATE USER IF NOT EXISTS '${DB_USER}'@'127.0.0.1' IDENTIFIED BY '${DB_PASS}';" >/dev/null 2>&1 || true
  mariadb -e "GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_USER}'@'127.0.0.1' WITH GRANT OPTION;" >/dev/null 2>&1 || true
  mariadb -e "FLUSH PRIVILEGES;" >/dev/null 2>&1 || true
  success "Database '${DB_NAME}' and user '${DB_USER}' configured."
}

configure_env() {
  info "Creating .env file and applying configuration..."
  cd "${PANEL_DIR}"
  if [ ! -f ".env.example" ]; then
    curl -Lo .env.example https://raw.githubusercontent.com/pterodactyl/panel/develop/.env.example
  fi
  cp -f .env.example .env
  sed -i "s|APP_URL=.*|APP_URL=https://${DOMAIN}|g" .env
  sed -i "s|DB_DATABASE=.*|DB_DATABASE=${DB_NAME}|g" .env
  sed -i "s|DB_USERNAME=.*|DB_USERNAME=${DB_USER}|g" .env
  sed -i "s|DB_PASSWORD=.*|DB_PASSWORD=${DB_PASS}|g" .env
  if ! grep -q "^APP_ENVIRONMENT_ONLY=" .env; then
    echo "APP_ENVIRONMENT_ONLY=false" >> .env
  fi
  success ".env configured for ${DOMAIN}"
}

install_php_deps() {
  info "Installing PHP dependencies via Composer..."
  cd "${PANEL_DIR}"
  COMPOSER_ALLOW_SUPERUSER=1 composer install --no-dev --optimize-autoloader >/dev/null &
  spinner $!
  success "PHP dependencies installed."
}

generate_keys_and_migrate() {
  info "Generating application key..."
  cd "${PANEL_DIR}"
  php artisan key:generate --force >/dev/null
  success "Application key generated."

  info "Running migrations & seeders..."
  php artisan migrate --seed --force >/dev/null &
  spinner $!
  success "Database migrations & seeders finished."
}

permissions_and_cron() {
  info "Setting file permissions and cron jobs..."
  chown -R www-data:www-data "${PANEL_DIR}"/*
  apt install -y cron >/dev/null
  systemctl enable --now cron >/dev/null
  (crontab -l 2>/dev/null; echo "* * * * * php ${PANEL_DIR}/artisan schedule:run >> /dev/null 2>&1") | crontab -
  success "Permissions & cron configured."
}

# -----------------------
# Execution Flow
# -----------------------
confirm_root
print_banner
prompt_domain_and_db
basic_requirements
detect_os_and_repos
install_stack
install_composer
download_pterodactyl
setup_mariadb
configure_env
install_php_deps
generate_keys_and_migrate
permissions_and_cron

success "🎉 Ryzen VPS Management Installer completed!"
echo -e "${BOLD}${CYAN}🔗 Your panel URL: https://${DOMAIN}${RESET}"
echo -e "${BOLD}${CYAN}📂 Panel directory: ${PANEL_DIR}${RESET}"
echo -e "${BOLD}${CYAN}👤 Create admin with: php artisan p:user:make${RESET}"
