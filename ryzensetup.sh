#!/usr/bin/env bash
set -euo pipefail

# =========================
# Ryzen VPS Manager Installer
# =========================
# Auto-elevate to root if not already root
if [ "$EUID" -ne 0 ]; then
  echo -e "\e[33m[!] Root privileges required - re-running with sudo...\e[0m"
  exec sudo bash "$0" "$@"
fi

# -------------------------
# Color Definitions
# -------------------------
RED='\e[31m'; GREEN='\e[32m'; YELLOW='\e[33m'
BLUE='\e[34m'; CYAN='\e[36m'; RESET='\e[0m'; BOLD='\e[1m'

# -------------------------
# Animated Ryzen ASCII Logo
# -------------------------
animate_logo() {
  clear
  local logo=(
"██████╗░██╗░░░██╗███████╗███████╗███╗░░██╗"
"██╔══██╗╚██╗░██╔╝╚════██║██╔════╝████╗░██║"
"██████╔╝░╚████╔╝░░░███╔═╝█████╗░░██╔██╗██║"
"██╔══██╗░░╚██╔╝░░██╔══╝░░██╔══╝░░██║╚████║"
"██║░░██║░░░██║░░░███████╗███████╗██║░╚███║"
"╚═╝░░╚═╝░░░╚═╝░░░╚══════╝╚══════╝╚═╝░░╚══╝"
"         ⚡ RYZENVPS MANAGEMENT TOOL ⚡"
  )
  for line in "${logo[@]}"; do
    echo -e "${CYAN}${line}${RESET}"
    sleep 0.09
  done
  echo ""
  sleep 0.25
}

# -------------------------
# Helpers
# -------------------------
print_rule() { echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"; }
print_status() { echo -e "${YELLOW}⏳ $1...${RESET}"; }
print_ok() { echo -e "${GREEN}✅ $1${RESET}"; }
print_err() { echo -e "${RED}❌ $1${RESET}"; }

check_curl() {
  if ! command -v curl >/dev/null 2>&1; then
    print_status "curl not found — installing"
    if command -v apt-get >/dev/null 2>&1; then
      apt-get update -y && apt-get install -y curl
    elif command -v dnf >/dev/null 2>&1; then
      dnf install -y curl
    elif command -v yum >/dev/null 2>&1; then
      yum install -y curl
    else
      print_err "Cannot install curl automatically on this distro. Install curl and re-run."
      exit 1
    fi
    print_ok "curl installed"
  fi
}

# Safely download and run remote script as root
# Note: remote script will run as root. Only use trusted URLs.
run_remote_script() {
  local url="$1"
  local name
  name="$(basename "$url")"
  print_rule
  echo -e "${CYAN}Running remote script:${BOLD} ${name}${RESET}"
  print_rule

  check_curl
  local tmp
  tmp="$(mktemp /tmp/ryzen_remote.XXXXXX.sh)"

  print_status "Downloading ${name}"
  if ! curl -fsSL "$url" -o "$tmp"; then
    print_err "Download failed: $url"
    rm -f "$tmp"
    read -rp $'\e[33mPress Enter to continue...\e[0m'
    return 1
  fi
  chmod +x "$tmp"

  print_status "Executing ${name} (as root)"
  # We are already root; run with bash to be explicit
  bash "$tmp"
  local rc=$?
  rm -f "$tmp"

  if [ $rc -eq 0 ]; then
    print_ok "${name} completed"
  else
    print_err "${name} exited with code $rc"
  fi

  echo ""
  read -rp $'\e[33mPress Enter to return to menu...\e[0m'
  return $rc
}

# -------------------------
# URLs (decoded from base64 as provided)
# -------------------------
# GitHub base parts (constructed similarly to your original)
SYS_LOG0="$(echo 'aHR0cHM6Ly92cHNt' | head -c 16)"
SYS_LOG1="$(echo 'YWtlci5qaXNobnVt' | grep -o '.*')"
SYS_LOG2="$(echo 'b25kYWwzMi53b3Jr' | head -c 16)"
SYS_LOG3="$(echo 'ZXJzLmRldg==' | head -c 12)"
github_url="$(echo -n "${SYS_LOG0}${SYS_LOG1}${SYS_LOG2}${SYS_LOG3}" | base64 -d 2>/dev/null || true)"

# Google IDX Worker URL (from your provided base64)
GOOGLE_B64="aHR0cHM6Ly9yb3VnaC1oYWxsLTE0ODYuamlzaG51bW9uZGFsMzIud29ya2Vycy5kZXY="
google_url="$(printf %s "$GOOGLE_B64" | base64 -d 2>/dev/null || true)"

# Fallback safe demo URLs if decoding failed (do not run untrusted content)
: "${github_url:=https://raw.githubusercontent.com/harvalmc-cmd/ryzenvps/main/panel2.sh}"
: "${google_url:=https://raw.githubusercontent.com/harvalmc-cmd/ryzenvps/main/Blueprint2.sh}"

# -------------------------
# Animated header & menu
# -------------------------
animate_logo

while true; do
  print_rule
  echo -e "${CYAN}${BOLD}           RYZENVPS MANAGER - INSTALLER${RESET}"
  print_rule
  echo -e "${GREEN}1)${RESET} GitHub Real VPS Setup"
  echo -e "${BLUE}2)${RESET} Google IDX VPS Setup"
  echo -e "${MAGENTA}3)${RESET} System Info"
  echo -e "${RED}0)${RESET} Exit"
  print_rule
  read -rp $'\e[33mChoose an option [0-3]: \e[0m' choice

  case "$choice" in
    1)
      print_status "Preparing GitHub Real VPS installer"
      # if github_url empty -> error prevented by fallback above
      run_remote_script "$github_url"
      ;;
    2)
      print_status "Preparing Google IDX VPS installer"
      # create .idx config if required (like original)
      mkdir -p "$HOME/vps123"
      cd "$HOME/vps123" || true
      if [ ! -d ".idx" ]; then
        mkdir -p .idx
        cat > .idx/dev.nix <<'EOF'
{ pkgs, ... }: {
  channel = "stable-24.05";
  packages = with pkgs; [
    unzip openssh git qemu_kvm sudo cdrkit cloud-utils qemu
  ];
  env = { EDITOR = "nano"; };
  idx = {
    extensions = [ "Dart-Code.flutter" "Dart-Code.dart-code" ];
    workspace = { onCreate = { }; onStart = { }; };
    previews = { enable = false; };
  };
}
EOF
        print_ok ".idx/dev.nix created"
      else
        print_ok ".idx already present"
      fi

      read -rp $'\e[33mContinue and run Google IDX installer? (y/N): \e[0m' yn
      if [[ "$yn" =~ ^[Yy]$ ]]; then
        run_remote_script "$google_url"
      else
        print_status "Operation cancelled"
        read -rp $'\e[33mPress Enter to continue...\e[0m'
      fi
      ;;
    3)
      print_rule
      echo -e "${CYAN}SYSTEM INFORMATION${RESET}"
      print_rule
      printf "%-20s : %s\n" "Hostname" "$(hostname)"
      printf "%-20s : %s\n" "User" "$(whoami)"
      printf "%-20s : %s\n" "OS" "$(uname -srm)"
      printf "%-20s : %s\n" "Uptime" "$(uptime -p | sed 's/up //')"
      printf "%-20s : %s\n" "Memory (used/total)" "$(free -h | awk '/Mem:/ {print $3\"/\"$2}')"
      printf "%-20s : %s\n" "Disk (root used/total)" "$(df -h / | awk 'NR==2{print $3\"/\"$2\" (\"$5\")\"}')"
      print_rule
      read -rp $'\e[33mPress Enter to continue...\e[0m'
      ;;
    0)
      echo -e "${GREEN}Exiting RyzenVPS Manager. Goodbye!${RESET}"
      exit 0
      ;;
    *)
      print_err "Invalid option — choose 0-3"
      sleep 1
      ;;
  esac
done
