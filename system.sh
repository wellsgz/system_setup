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

# --- Check if a package is installed (cross-distro) ---
is_installed() {
    local pkg="$1"
    case "$ID" in
        debian|ubuntu|pop)
            dpkg -s "$pkg" &>/dev/null
            ;;
        opensuse-tumbleweed|opensuse-leap|opensuse)
            rpm -q "$pkg" &>/dev/null
            ;;
        arch)
            pacman -Qi "$pkg" &>/dev/null
            ;;
        *)
            return 1
            ;;
    esac
}

# --- Filter out already installed packages ---
filter_installed_packages() {
    local -a to_install=()
    for pkg in "$@"; do
        if ! is_installed "$pkg"; then
            to_install+=("$pkg")
        else
            # Output to stderr so it doesn't mix with the package list
            echo -e "\033[34m[INFO]\033[0m Package '$pkg' is already installed. Skipping." >&2
        fi
    done
    echo "${to_install[@]}"
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
    local -a packages=(zsh git htop rsync wget fish curl firewalld fail2ban neovim fzf)
    info "Detected OS: $ID. Checking for packages to install..."

    # Filter out already installed packages
    local -a to_install
    read -ra to_install <<< "$(filter_installed_packages "${packages[@]}")"

    if [ ${#to_install[@]} -eq 0 ]; then
        success "All base packages are already installed."
        return
    fi

    info "Installing packages: ${to_install[*]}"

    case "$ID" in
        debian|ubuntu|pop)
            # Tailscale is installed via a separate script for Debian-based distros
            sudo apt-get update
            sudo apt-get install -y "${to_install[@]}"
            ;;
        opensuse-tumbleweed|opensuse-leap|opensuse)
            # Tailscale is in the main openSUSE repos
            if ! is_installed tailscale; then
                to_install+=(tailscale)
            fi
            sudo zypper refresh
            sudo zypper install -y "${to_install[@]}"
            ;;
        arch)
            # Tailscale is in the Arch community repo
            if ! is_installed tailscale; then
                to_install+=(tailscale)
            fi
            sudo pacman -Syu --noconfirm "${to_install[@]}"
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

# --- Docker Installation ---
install_docker() {
    . /etc/os-release
    info "Checking Docker installation..."

    if command -v docker &>/dev/null; then
        success "Docker is already installed. Skipping."
    else
        info "Installing Docker..."
        case "$ID" in
            debian|ubuntu|pop)
                # Install using official Docker repository
                sudo apt-get update
                sudo apt-get install -y ca-certificates curl gnupg
                sudo install -m 0755 -d /etc/apt/keyrings
                curl -fsSL "https://download.docker.com/linux/$ID/gpg" | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
                sudo chmod a+r /etc/apt/keyrings/docker.gpg
                echo \
                    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$ID \
                    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
                    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
                sudo apt-get update
                sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
                ;;
            opensuse-tumbleweed|opensuse-leap|opensuse)
                sudo zypper install -y docker docker-compose
                ;;
            arch)
                sudo pacman -S --noconfirm docker docker-compose
                ;;
            *)
                warn "Docker installation not supported for $ID. Skipping."
                return
                ;;
        esac
        success "Docker installed."
    fi

    # Enable Docker service
    info "Enabling Docker service..."
    sudo systemctl enable --now docker

    # Add current user to docker group
    if ! groups "$USER" | grep -q docker; then
        info "Adding user '$USER' to docker group..."
        sudo usermod -aG docker "$USER"
        success "User added to docker group. Log out and back in to apply."
    else
        info "User '$USER' is already in docker group."
    fi
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
    # Wait for firewalld to be fully active before configuring
    sudo systemctl is-active --quiet firewalld || sleep 2
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
    install_docker
    install_neovim_config

    # --- Zsh and Oh My Zsh Setup ---
    info "Starting Zsh and Oh My Zsh setup..."
    if [ -d "$HOME/.oh-my-zsh" ]; then
        warn "Oh My Zsh is already installed. Skipping."
    else
        info "Installing Oh My Zsh..."
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
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
        "https://github.com/zsh-users/zsh-syntax-highlighting"
        "https://github.com/Aloxaf/fzf-tab"
    )

    for repo in "${plugin_repos[@]}"; do
        local plugin_name
        plugin_name=$(basename "$repo" .git)
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
    if [ ! -f "$zshrc_file" ]; then
        warn ".zshrc file not found. Creating a basic one..."
        touch "$zshrc_file"
    fi
    sed -i 's/^ZSH_THEME=".*"/ZSH_THEME="powerlevel10k\/powerlevel10k"/' "$zshrc_file"
    
    # Updated plugins_list (removed thefuck as it's not available on all distros)
    local plugins_list="git zsh-completions zsh-autosuggestions history-substring-search zsh-syntax-highlighting extract docker sudo fzf fzf-tab"
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

    # --- Change default shell to Zsh ---
    local current_shell
    current_shell=$(getent passwd "$USER" | cut -d: -f7)
    local zsh_path
    zsh_path=$(which zsh)
    if [ "$current_shell" = "$zsh_path" ]; then
        info "Default shell is already Zsh."
    else
        info "Changing default shell to Zsh..."
        sudo chsh -s "$zsh_path" "$USER"
        success "Default shell changed to Zsh."
    fi

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
    echo -e "2. You must ${BOLD}LOG OUT and LOG BACK IN${NC} for all changes to take effect."
    echo
    echo -e "3. NvChad is installed. The next time you run ${GREEN}nvim${NC}, follow any on-screen instructions."
    echo
    echo -e "4. You can re-run the Zsh prompt wizard any time by typing: ${GREEN}p10k configure${NC}"
    echo
}

main
