#!/bin/bash
#
# This script configures passwordless sudo for the user who executes it
# and locks the root account's password for enhanced security.
#
# WARNING: Granting passwordless sudo reduces a layer of security.
# Use it only in environments where you understand and accept the risk.
#
# USAGE: This script MUST be run with sudo.
# Example: curl -fsSL <RAW_URL> | sudo bash
#

# Exit immediately if a command fails
set -e

# --- Check if the script is run with sudo privileges ---
# The effective user ID must be 0 (root).
if [ "$(id -u)" -ne 0 ]; then
  echo "ERROR: This script must be run with sudo or as the root user." >&2
  echo "Please run like this: curl ... | sudo bash" >&2
  exit 1
fi

# --- Identify the user who invoked sudo ---
# $SUDO_USER is set by the `sudo` command and contains the name of the original user.
# This ensures we are targeting the correct user, not 'root'.
if [ -z "$SUDO_USER" ]; then
    echo "ERROR: This script is intended to be run with 'sudo' by a regular user." >&2
    exit 1
fi

USERNAME=$SUDO_USER
SUDOERS_FILE="/etc/sudoers.d/90-$USERNAME-nopasswd"

echo "-> Configuring passwordless sudo for user: '$USERNAME'"

# --- Check if the user configuration already exists ---
if [ -f "$SUDOERS_FILE" ]; then
    echo "-> WARNING: Sudoers file already exists for this user at '$SUDOERS_FILE'."
else
    # --- Create the sudoers file with the correct content ---
    # This line grants the user passwordless access for all commands.
    CONTENT="$USERNAME ALL=(ALL) NOPASSWD:ALL"
    
    echo "-> Creating new sudoers file..."
    echo "$CONTENT" > "$SUDOERS_FILE"
    
    # --- Set correct file permissions (CRITICAL) ---
    # The file must be read-only (0440) and owned by root to be secure and trusted by the system.
    echo "-> Setting file permissions to 0440 (read-only for root)."
    chmod 0440 "$SUDOERS_FILE"
fi

# --- Lock the root account password to prevent direct login ---
echo "-> Locking the root account password for security."
passwd -l root

echo
echo "✅ SUCCESS: User '$USERNAME' can now run sudo commands without a password."
echo "✅ SUCCESS: The root account password has been locked."
echo
