#!/bin/bash
#
# Post-installation script for Debian, openSUSE, and Arch-based systems.
#
# This script will:
# 1. Detect the operating system.
# 2. Install essential packages (zsh, git, htop, etc.).
# 3. Install Oh My Zsh non-interactively.
# 4. Install the Powerlevel10k theme and its recommended configuration.
# 5. Install several popular Zsh plugins.
# 6. Configure the .zshrc file with the new theme, plugins, and aliases.
#
# To Use:
#   1. Host this file on GitHub (or save it locally).
#   2. Run with: curl -fsSL <RAW_URL> | bash
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
    local os_id
    if [ -f /etc/os-release ]; then
        # Read the ID field from the os-release file
        os_id=$(grep -oP '^ID=\K\w+' /etc/os-release)
    else
        error "Cannot detect the operating system. /etc/os-release not found."
    fi

    local packages="zsh git htop rsync wget fish curl"
    info "Detected OS: $os_id. Installing packages: $packages"

    case "$os_id" in
        debian|ubuntu|pop)
            sudo apt-get update
            sudo apt-get install -y $packages
            ;;
        opensuse-tumbleweed|opensuse-leap|opensuse)
            sudo zypper refresh
            sudo zypper install -y $packages
            ;;
        arch)
            sudo pacman -Syu --noconfirm $packages
            ;;
        *)
            error "Unsupported operating system: $os_id"
            ;;
    esac
    success "Packages installed."
}


# --- Main Setup Logic ---
main() {
    detect_and_install_packages

    # --- Install Oh My Zsh ---
    if [ -d "$HOME/.oh-my-zsh" ]; then
        warn "Oh My Zsh is already installed. Skipping."
    else
        info "Installing Oh My Zsh..."
        # Use --unattended to install without interaction
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)" "" --unattended
        success "Oh My Zsh installed."
    fi

    # Define the custom path for themes and plugins
    local zsh_custom="$HOME/.oh-my-zsh/custom"

    # --- Install Powerlevel10k Theme ---
    if [ -d "$zsh_custom/themes/powerlevel10k" ]; then
        warn "Powerlevel10k theme is already installed. Skipping."
    else
        info "Installing Powerlevel10k theme..."
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$zsh_custom/themes/powerlevel10k"
        success "Powerlevel10k theme installed."
    fi

    # --- Install Powerlevel10k Configuration ---
    if [ -f "$HOME/.p10k.zsh" ]; then
        warn "Powerlevel10k config file (.p10k.zsh) already exists. Skipping."
    else
        info "Downloading recommended Powerlevel10k configuration..."
        curl -fsSL -o "$HOME/.p10k.zsh" https://raw.githubusercontent.com/romkatv/dotfiles-public/master/.purepower
        success "Powerlevel10k configuration downloaded."
    fi


    # --- Install Zsh Plugins ---
    info "Installing Zsh plugins..."
    local plugins_dir="$zsh_custom/plugins"
    # An array of plugin repositories to install
    local plugin_repos=(
        "https://github.com/zsh-users/zsh-autosuggestions"
        "https://github.com/zsh-users/zsh-history-substring-search"
        "https://github.com/zsh-users/zsh-completions"
        "https://github.com/zsh-users/zsh-syntax-highlighting.git"
    )

    for repo in "${plugin_repos[@]}"; do
        # Extract the plugin name from the repo URL to create the directory name
        local plugin_name=$(basename "$repo" .git)
        if [ -d "$plugins_dir/$plugin_name" ]; then
            warn "Plugin '$plugin_name' is already installed. Skipping."
        else
            info "Cloning $plugin_name..."
            git clone "$repo" "$plugins_dir/$plugin_name"
        fi
    done
    success "All plugins handled."

    # --- Configure .zshrc ---
    info "Configuring .zshrc file..."
    local zshrc_file="$HOME/.zshrc"

    # Set the theme to Powerlevel10k
    sed -i 's/^ZSH_THEME=".*"/ZSH_THEME="powerlevel10k\/powerlevel10k"/' "$zshrc_file"

    # Set the plugins list
    local plugins_list="git zsh-completions zsh-autosuggestions history-substring-search zsh-syntax-highlighting thefuck extract docker"
    sed -i "s/^plugins=(.*/plugins=($plugins_list)/" "$zshrc_file"

    # Add Powerlevel10k's initialization script source if not present
    if ! grep -q 'source ~/.p10k.zsh' "$zshrc_file"; then
      echo -e "\n# To customize prompt, run \`p10k configure\` or edit ~/.p10k.zsh.\n[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh" >> "$zshrc_file"
    fi

    # Add aliases if they aren't already in the file
    if ! grep -q "# --- Custom Aliases ---" "$zshrc_file"; then
        info "Adding custom aliases to .zshrc"
        cat <<EOT >> "$zshrc_file"

# --- Custom Aliases ---
alias vi='vim'
alias sudo='sudo '
# alias dig='doggo'
# alias p='proxychains4'
# alias z='zellij attach || zellij'
EOT
    else
        warn "Custom aliases section already found in .zshrc. Skipping."
    fi

    success ".zshrc configuration complete."

    # --- Final Instructions (Refined Output) ---
    
    # Define colors and styles for a cleaner output
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    BOLD='\033[1m'
    NC='\033[0m' # No Color

    echo
    echo -e "${YELLOW}-----------------------------------------------------${NC}"
    echo -e "            ${BOLD}🚀 Setup Complete! 🚀${NC}            "
    echo -e "${YELLOW}-----------------------------------------------------${NC}"
    echo
    echo -e "${BOLD}IMPORTANT NEXT STEPS:${NC}"
    echo
    echo -e "1. Change your default shell to Zsh with the command:"
    # Note: We escape the '$' in \$(which zsh) so it gets printed literally for the user to copy.
    echo -e "   ${GREEN}chsh -s \$(which zsh)${NC}"
    echo
    echo -e "2. You must ${BOLD}LOG OUT and LOG BACK IN${NC} for the change to take effect."
    echo
    echo -e "3. The first time you launch the new terminal, Powerlevel10k may ask"
    echo -e "   to install a font. It is ${BOLD}highly recommended${NC} you say 'yes'."
    echo
    echo -e "4. You can re-run the prompt configuration wizard any time by typing:"
    echo -e "   ${GREEN}p10k configure${NC}"
    echo
}

# Run the main function of the script
main
