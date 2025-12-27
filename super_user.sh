#!/bin/bash
#
# Cloud VM User Setup Script
#
# This script handles two scenarios:
# 1. Running as root: Creates a new user with SSH keys and passwordless sudo
# 2. Running as non-root with sudo: Confirms setup is complete and exits
#
# USAGE:
#   As root:     curl -fsSL <RAW_URL> | bash
#   With sudo:   curl -fsSL <RAW_URL> | bash
#

set -e

# --- Helper Functions ---
info() {
    echo -e "\033[34m[INFO]\033[0m $1"
}

success() {
    echo -e "\033[32m[SUCCESS]\033[0m $1"
}

error() {
    echo -e "\033[31m[ERROR]\033[0m $1" >&2
    exit 1
}

# --- Main Logic ---

# Case 1: Running as non-root user
if [ "$(id -u)" -ne 0 ]; then
    # Check if user has passwordless sudo
    if sudo -n true 2>/dev/null; then
        success "User '$(whoami)' already has passwordless sudo. Nothing to do."
        echo
        echo "You can now run the system setup script:"
        echo "  curl -fsSL https://raw.githubusercontent.com/wellsgz/system_setup/main/system.sh | bash"
        echo
        exit 0
    else
        error "This script must be run as root, or by a user with passwordless sudo."
    fi
fi

# Case 2: Running as root - create a new user
info "Running as root. Setting up a new sudo user..."
echo

# Prompt for username
read -rp "Enter username to create: " USERNAME

# Validate username
if [ -z "$USERNAME" ]; then
    error "Username cannot be empty."
fi

if id "$USERNAME" &>/dev/null; then
    error "User '$USERNAME' already exists."
fi

# Create user with home directory and bash shell
info "Creating user '$USERNAME' with home directory..."
useradd -m -s /bin/bash "$USERNAME"
success "User '$USERNAME' created."

# Copy SSH authorized_keys from root
if [ -f /root/.ssh/authorized_keys ]; then
    info "Copying SSH authorized_keys from root..."
    mkdir -p "/home/$USERNAME/.ssh"
    cp /root/.ssh/authorized_keys "/home/$USERNAME/.ssh/"
    chown -R "$USERNAME:$USERNAME" "/home/$USERNAME/.ssh"
    chmod 700 "/home/$USERNAME/.ssh"
    chmod 600 "/home/$USERNAME/.ssh/authorized_keys"
    success "SSH keys copied."
else
    echo -e "\033[33m[WARN]\033[0m No /root/.ssh/authorized_keys found. Skipping SSH key copy."
fi

# Configure passwordless sudo
SUDOERS_FILE="/etc/sudoers.d/90-$USERNAME-nopasswd"
info "Configuring passwordless sudo..."
echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" > "$SUDOERS_FILE"
chmod 0440 "$SUDOERS_FILE"
success "Passwordless sudo configured."

# Lock root password
info "Locking root account password..."
passwd -l root
success "Root password locked."

# Final instructions
echo
echo -e "\033[33m-----------------------------------------------------\033[0m"
echo -e "            \033[1m✅ User Setup Complete!\033[0m"
echo -e "\033[33m-----------------------------------------------------\033[0m"
echo
echo -e "\033[1mNEXT STEPS:\033[0m"
echo
echo -e "1. SSH into this server as '\033[32m$USERNAME\033[0m':"
echo -e "   ssh $USERNAME@<server-ip>"
echo
echo -e "2. Run the system setup script:"
echo -e "   \033[32mcurl -fsSL https://raw.githubusercontent.com/wellsgz/system_setup/main/system.sh | bash\033[0m"
echo
