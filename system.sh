#!/bin/bash
#
# Post-installation script for Debian, openSUSE, and Arch-based systems.
#
# This script will:
# 1. Detect the operating system and install essential packages.
# 2. Install and enable Tailscale, firewalld, and fail2ban.
# 3. Configure firewall rules for Tailscale and a secure SSH jail for fail2ban.
# 4. Install and configure NvChad for Neovim.
# 5. Install and configure Oh My Zsh, Powerlevel10k, and Zsh plugins.
# 6. Configure the .zshrc file with themes, plugins, and aliases.
#
# To Use:
#   curl -fsSL <RAW_URL> | bash
#

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Helper Functions for Logging ---
info() {
    echo -e "\033[34m[INFO]\033[0m $1"
}

success() {
    echo -e "\033[32m[SUCCESS]\033[0m $1"
}

warn() {
    echo -e "\033[33m[WARN]\033[0m $1"
}

error() {
    echo -e "\033[31m[ERROR]\033[0m $1"
    exit 1
}

# --- OS Detection and Package Installation ---
detect_and_install_packages() {
    if [ -f /etc/os-release ]; then
        # Expose os-release vars to the script
        . /etc/os-release
    else
        error "Cannot detect the operating system. /etc/os-release not found."
    fi

    # Added fzf to the base package list
    local packages="zsh git htop rsync wget fish curl firewalld fail2ban neovim fzf"
    info "Detected OS: $ID. Installing packages..."

    case "$ID" in
        debian|ubuntu|pop)
            # Tailscale is installed via a separate script for Debian-based distros
            sudo apt-get update
            sudo apt-get install -y $packages
            ;;
        opensuse-tumbleweed|opensuse-leap|opensuse)
            # Tailscale is in the main openSUSE repos
            packages="$packages tailscale"
            sudo zypper refresh
            sudo zypper install -y $packages
            ;;
        arch)
            # Tailscale is in the Arch community repo
            packages="$packages tailscale"
            sudo pacman -Syu --noconfirm $packages
            ;;
        *)
            error "Unsupported operating system: $ID"
            ;;
    esac
    success "Base packages installed."
}

# --- Tailscale Installation ---
install_tailscale() {
    # Re-source /etc/os-release to ensure $ID is available
    . /etc/os-release
    info "Setting up Tailscale..."

    case "$ID" in
        debian|ubuntu|pop)
            info "Installing Tailscale via official script for Debian-based OS..."
            curl -fsSL https://tailscale.com/install.sh | sh
            ;;
        *)
            info "Tailscale was installed via package manager."
            ;;
    esac

    info "Enabling the Tailscale service..."
    # The correct service name is 'tailscaled', not 'tailscale'.
    sudo systemctl enable --now tailscaled
    success "Tailscale service is enabled."
}


# --- Firewall and Security Configuration ---
configure_security_services() {
    info "Configuring security services (firewalld & fail2ban)..."

    local jail_config_path="/etc/fail2ban/jail.d/sshd.local"
    info "Creating fail2ban sshd jail at $jail_config_path"
    sudo mkdir -p /etc/fail2ban/jail.d/
    sudo tee "$jail_config_path" > /dev/null <<EOT
[sshd]
enabled = true
backend = systemd
filter = sshd
maxretry = 2
findtime = 1d
bantime = 1y
EOT

    info "Enabling and starting firewalld and fail2ban services..."
    sudo systemctl enable --now firewalld
    sudo systemctl enable --now fail2ban

    info "Adding Tailscale interface to firewalld trusted zone..."
    # This command is idempotent and safer than change-interface
    sudo firewall-cmd --permanent --zone=trusted --add-interface=tailscale0
    sudo firewall-cmd --reload

    success "Security services configured and enabled."
}

# --- Neovim Configuration ---
install_neovim_config() {
    local nvim_config_dir="$HOME/.config/nvim"
    if [ -d "$nvim_config_dir" ]; then
        warn "Neovim configuration already exists at $nvim_config_dir. Skipping."
    else
        info "Installing NvChad starter configuration for Neovim..."
        git clone https://github.com/NvChad/starter "$nvim_config_dir"
        info "Running initial Neovim setup for NvChad (headless)..."
        nvim --headless "+Lazy! sync" +qa
        success "Neovim with NvChad is configured."
    fi
}

# --- Main Setup Logic ---
main() {
    detect_and_install_packages
    install_tailscale
    configure_security_services
    install_neovim_config

    # --- Zsh and Oh My Zsh Setup ---
    info "Starting Zsh and Oh My Zsh setup..."
    if [ -d "$HOME/.oh-my-zsh" ]; then
        warn "Oh My Zsh is already installed. Skipping."
    else
        info "Installing Oh My Zsh..."
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)" "" --unattended
        success "Oh My Zsh installed."
    fi

    local zsh_custom="$HOME/.oh-my-zsh/custom"
    if [ -d "$zsh_custom/themes/powerlevel10k" ]; then
        warn "Powerlevel10k theme is already installed. Skipping."
    else
        info "Installing Powerlevel10k theme..."
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$zsh_custom/themes/powerlevel10k"
        success "Powerlevel10k theme installed."
    fi

    if [ -f "$HOME/.p10k.zsh" ]; then
        warn "Powerlevel10k config file (.p10k.zsh) already exists. Skipping."
    else
        info "Downloading recommended Powerlevel10k configuration..."
        curl -fsSL -o "$HOME/.p10k.zsh" https://raw.githubusercontent.com/romkatv/dotfiles-public/master/.purepower
        success "Powerlevel10k configuration downloaded."
    fi

    info "Installing Zsh plugins..."
    local plugins_dir="$zsh_custom/plugins"
    # Added fzf-tab to the list of repos to clone
    local plugin_repos=(
        "https://github.com/zsh-users/zsh-autosuggestions"
        "https://github.com/zsh-users/zsh-history-substring-search"
        "https://github.com/zsh-users/zsh-completions"
        "https://github.com/zsh-users/zsh-syntax-highlighting.git"
        "https://github.com/Aloxaf/fzf-tab.git"
    )

    for repo in "${plugin_repos[@]}"; do
        local plugin_name=$(basename "$repo" .git)
        if [ -d "$plugins_dir/$plugin_name" ]; then
            warn "Plugin '$plugin_name' is already installed. Skipping."
        else
            info "Cloning $plugin_name..."
            git clone "$repo" "$plugins_dir/$plugin_name"
        fi
    done
    success "All Zsh plugins handled."

    info "Configuring .zshrc file..."
    local zshrc_file="$HOME/.zshrc"
    sed -i 's/^ZSH_THEME=".*"/ZSH_THEME="powerlevel10k\/powerlevel10k"/' "$zshrc_file"
    
    # Updated plugins_list to include sudo, fzf, and fzf-tab (at the end)
    local plugins_list="git zsh-completions zsh-autosuggestions history-substring-search zsh-syntax-highlighting thefuck extract docker sudo fzf fzf-tab"
    sed -i "s/^plugins=(.*/plugins=($plugins_list)/" "$zshrc_file"

    if ! grep -q 'source ~/.p10k.zsh' "$zshrc_file"; then
      echo -e "\n# To customize prompt, run \`p10k configure\` or edit ~/.p10k.zsh.\n[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh" >> "$zshrc_file"
    fi

    if ! grep -q "# --- Custom Aliases ---" "$zshrc_file"; then
        info "Adding custom aliases to .zshrc"
        cat <<EOT >> "$zshrc_file"

# --- Custom Aliases ---
alias vi='nvim'
alias sudo='sudo '
# alias dig='doggo'
# alias p='proxychains4'
# alias z='zellij attach || zellij'
EOT
    else
        sed -i "s/alias vi='vim'/alias vi='nvim'/" "$zshrc_file"
        warn "Custom aliases section already exists. Ensured 'vi' is aliased to 'nvim'."
    fi
    success ".zshrc configuration complete."

    # --- Final Instructions ---
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    BOLD='\033[1m'
    NC='\033[0m'

    echo
    echo -e "${YELLOW}-----------------------------------------------------${NC}"
    echo -e "            ${BOLD}🚀 Setup Complete! 🚀${NC}            "
    echo -e "${YELLOW}-----------------------------------------------------${NC}"
    echo
    echo -e "${BOLD}IMPORTANT NEXT STEPS:${NC}"
    echo
    echo -e "1. ${BOLD}Connect to your Tailscale network${NC} by running:"
    echo -e "   ${GREEN}sudo tailscale up${NC}"
    echo
    echo -e "2. ${BOLD}Change your default shell to Zsh${NC} with the command:"
    echo -e "   ${GREEN}chsh -s \$(which zsh)${NC}"
    echo
    echo -e "3. You must ${BOLD}LOG OUT and LOG BACK IN${NC} for all changes to take effect."
    echo
    echo -e "4. NvChad is installed. The next time you run ${GREEN}nvim${NC}, follow any on-screen instructions."
    echo
    echo -e "5. You can re-run the Zsh prompt wizard any time by typing: ${GREEN}p10k configure${NC}"
    echo
}

main
