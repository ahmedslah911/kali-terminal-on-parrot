#!/bin/bash
# حذفنا 'set -e' مؤقتاً لنتمكن من التعامل مع الأخطاء يدوياً وعرضها
# ولكن سنعتمد على التحقق من حالة كل أمر

# === Colors & Style Definitions ===
RED='\033[1;31m'
GREEN='\033[1;32m'
BLUE='\033[1;34m'
CYAN='\033[1;36m'
YELLOW='\033[1;33m'
WHITE='\033[1;37m'
RESET='\033[0m'

# === Banner Function ===
print_banner() {
    clear
    echo -e "${RED}"
    cat << "EOF"
  _____                  _    _                    _   ____        _       _     
 | ____|_ __   __ _     / \  | |__  _ __ ___   ___  __| | / ___|  __ _| | __ _| |__  
 |  _| | '_ \ / _` |   / _ \ | '_ \| '_ ` _ \ / _ \/ _` | \___ \ / _` | |/ _` | '_ \ 
 | |___| | | | (_| |  / ___ \| | | | | | | | |  __/ (_| |  ___) | (_| | | (_| | | | |
 |_____|_| |_|\__, | /_/   \_\_| |_|_| |_| |_|\___|\__,_| |____/ \__,_|_|\__,_|_| |_|
              |___/                                                                      
EOF
    echo -e "${RESET}"
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${CYAN}║${WHITE}                     By Eng. Ahmed Salah                              ${CYAN}║${RESET}"
    echo -e "${CYAN}║${YELLOW}    Instructor & Specialist in Cyber Security & Ethical Hacker        ${CYAN}║${RESET}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════════╝${RESET}"
    echo -e ""
    echo -e "${GREEN}[+] Starting Detailed Transformation...${RESET}"
    echo -e "${BLUE}------------------------------------------------------------------------${RESET}"
}

print_banner

# === Root check ===
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}[-][Error] This script must run with sudo!${RESET}"
  exit 1
fi

# === Auto-detect User ===
REAL_USER="${SUDO_USER:-$(logname)}"
USER_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)
ROOT_HOME="/root"
ZSH_PATH=$(which zsh || echo "/usr/bin/zsh")

echo -e "${YELLOW}[*] Debug Information:${RESET}"
echo -e "    - Real User: $REAL_USER"
echo -e "    - User Home: $USER_HOME"
echo -e "    - Zsh Path:  $ZSH_PATH"
echo ""

# === System Update ===
echo -e "${BLUE}[1/5] Updating package lists...${RESET}"
if apt update; then
    echo -e "${GREEN}[✔] Update successful${RESET}"
else
    echo -e "${RED}[✘] Update failed! Check your internet connection.${RESET}"
fi

# === Install Packages ===
echo -e "${BLUE}[2/5] Installing core packages (zsh, git, curl, powerline)...${RESET}"
apt install -y zsh git curl command-not-found fonts-powerline

# === Configuration Function ===
install_zsh_setup() {
  local TARGET_USER=$1
  local TARGET_HOME=$2

  echo -e "${CYAN}[*] Setting up Zsh for: ${WHITE}$TARGET_USER${RESET}"

  # Backup
  [ -f "$TARGET_HOME/.zshrc" ] && cp "$TARGET_HOME/.zshrc" "$TARGET_HOME/.zshrc.old"

  # Install Oh-My-Zsh
  if [ ! -d "$TARGET_HOME/.oh-my-zsh" ]; then
    echo -e "    - Downloading Oh-My-Zsh..."
    if [ "$TARGET_USER" = "root" ]; then
       sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    else
       sudo -u "$TARGET_USER" env HOME="$TARGET_HOME" sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    fi
  else
    echo -e "    - Oh-My-Zsh already exists, skipping download."
  fi

  # Plugins
  local PLUGINS_DIR="$TARGET_HOME/.oh-my-zsh/custom/plugins"
  mkdir -p "$PLUGINS_DIR"
  
  echo -e "    - Checking Plugins..."
  [ ! -d "$PLUGINS_DIR/zsh-autosuggestions" ] && git clone https://github.com/zsh-users/zsh-autosuggestions "$PLUGINS_DIR/zsh-autosuggestions"
  [ ! -d "$PLUGINS_DIR/zsh-syntax-highlighting" ] && git clone https://github.com/zsh-users/zsh-syntax-highlighting "$PLUGINS_DIR/zsh-syntax-highlighting"

  # Finalizing .zshrc
  echo -e "    - Writing configuration to $TARGET_HOME/.zshrc..."
  cat > "$TARGET_HOME/.zshrc" <<EOF
# Configuration by Eng. Ahmed Salah
export ZSH="$TARGET_HOME/.oh-my-zsh"
ZSH_THEME=""
plugins=(git sudo zsh-autosuggestions zsh-syntax-highlighting command-not-found)

# KALI STYLE PROMPT
setopt prompt_subst
PROMPT='%F{%(#.red.blue)}┌──%F{white}(%F{red}%n㉿%m%F{white})-[%F{white}%~%F{white}]
%F{%(#.red.blue)}└─%F{%(#.red.blue)}%#%f '

source \$ZSH/oh-my-zsh.sh

if [ -f /etc/zsh_command_not_found ]; then
    source /etc/zsh_command_not_found
fi
EOF

  chown -R "$TARGET_USER:$TARGET_USER" "$TARGET_HOME/.oh-my-zsh" "$TARGET_HOME/.zshrc" 2>/dev/null || true
}

# === Execution ===
echo -e "${BLUE}[3/5] Configuring User profile...${RESET}"
install_zsh_setup "$REAL_USER" "$USER_HOME"

echo -e "${BLUE}[4/5] Configuring Root profile...${RESET}"
install_zsh_setup "root" "$ROOT_HOME"

echo -e "${BLUE}[5/5] Finalizing Shell change...${RESET}"
chsh -s "$ZSH_PATH" "$REAL_USER"
chsh -s "$ZSH_PATH" root

echo -e "\n${GREEN}══════════════════════════════════════════════════════════════════════${RESET}"
echo -e "${YELLOW}   [!] IMPORTANT: To see the new Kali style, you MUST:${RESET}"
echo -e "${WHITE}   1. Type 'zsh' now to test.${RESET}"
echo -e "${WHITE}   2. Or Log out and Log back in to make it permanent.${RESET}"
echo -e "${GREEN}══════════════════════════════════════════════════════════════════════${RESET}"
