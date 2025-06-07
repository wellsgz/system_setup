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

```
curl -fsSL https://raw.githubusercontent.com/wesllgp/system_setup/main/system.sh
```

**Super User Utility (Optional)**

This script grants the current user passwordless `sudo` privileges and locks the root account's password. Use with caution.

```
curl -fsSL https://raw.githubusercontent.com/wesllgp/system_setup/main/super_user
```

## 📄 Scripts Overview

- **system.sh:** The main, all-in-one script for setting up a full system. It can be run on a fresh install to configure everything from security to the shell environment. To view its code, see this repository.

- **super_user.sh:** An optional standalone utility for administrative convenience. It configures passwordless `sudo` and disables direct root login via password as a security measure. To use this, see the `super-user.sh` file.

## ⚠️ Security Notice

1. **Running Remote Scripts:** The `curl | bash` method is convenient but requires trust in the script's source. Since this is your own repository, but we do not recommend blindly executing what you are executing.

2. **Passwordless Sudo:** The `super_user.sh` script makes system administration more convenient at the cost of a layer of security. Anyone who gains access to your user account will have full root privileges without needing a password. Do not run this script on multi-user or production systems.

## ✅ Post-Installation Checklist

After the `system.sh` script finishes, you will need to perform a few manual steps:

1. **Connect to Tailscale:**

```
   sudo tailscale up
```

1. **Connect to Tailscale:**

```
   sudo tailscale up
```

2. **Change Default Shell:**

```
   chsh -s $(which zsh)
```

3. **Log Out & Log In:** You must log out of your session and log back in for the new shell and all group permissions to take effect.

4. **First Neovim Run:** The first time you run `:NvChad` may perform final setup steps.

5. **Customize Zsh Prompt (Optional):** To change the PowerLevel10k prompt style, run:

```
   p10k configure
```

## License

Licensed under the MIT License.

⭐ 🔗 👀 📋
