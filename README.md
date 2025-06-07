# My Personal Linux Setup Scripts

This repository contains a collection of personal shell scripts designed to automate the setup and configuration of my preferred development environment on fresh Linux installations. The goal is to create a consistent, secure, and productive environment with a single command.

---

## 🚀 Features of `system.sh`

The main script (`system.sh`) is an all-in-one utility that automates the following:

-   **🖥️ OS Detection:** Automatically identifies if the host is running Debian, Ubuntu, Arch Linux, or openSUSE.
-   **📦 Package Installation:** Installs a curated list of essential packages:
    -   Shells: `zsh`, `fish`
    -   Tools: `git`, `htop`, `rsync`, `wget`, `curl`
    -   Editor: `neovim`
-   **🛡️ Security Hardening:**
    -   Installs and enables `firewalld`.
    -   Installs and enables `fail2ban`.
    -   Deploys a custom `fail2ban` jail to protect SSH from brute-force attacks.
-   **🌐 Networking with Tailscale:**
    -   Installs the Tailscale client using the recommended method for the detected OS.
    -   Enables the `tailscaled` service.
    -   Configures `firewalld` to trust the `tailscale0` interface.
-   **🐚 Zsh & Shell Customization:**
    -   Installs **Oh My Zsh**.
    -   Installs the **Powerlevel10k** theme for a powerful and fast prompt.
    -   Installs essential Zsh plugins like `zsh-autosuggestions` and `zsh-syntax-highlighting`.
    -   Configures `.zshrc` with useful aliases and settings.
-   **✍️ Neovim Configuration:**
    -   Installs the **NvChad** configuration for a beautiful and feature-rich Neovim experience out of the box.
    -   Runs the initial plugin sync non-interactively.

---

## ⚡ Quick Start: One-Liner Execution

To run these scripts, you can execute them directly from this GitHub repository. Open a terminal on the target machine and use the appropriate command.

### Main System Setup

This is the primary script. It performs all actions listed in the features section.

```bash
curl -fsSL [https://raw.githubusercontent.com/wellsgz/system_setup/main/system.sh](https://raw.githubusercontent.com/wellsgz/system_setup/main/system.sh) | bash
