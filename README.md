```markdown
# My Personal Linux Setup Scripts

This repository contains a collection of personal shell scripts designed to automate setup tasks.

## 🔧 Features of 'system.sh'

The main script ('system.sh') is an all-in-one utility that automates the following:

• **🖥️ Host Detection:** Automatically identifies if the host is running Debian, or
• **📦 Package Installation:** Installs a curated list of essential packages:
  - Shell: "zsh", "fish"
  - Development: "git", "vim", "nodejs"
  - Editor: "neovim"
• **🔐 Security Hardening:**
  - Installs and enables "ufw" (firewall)
  - Installs and enables "fail2ban"
  - Deploys "chkrootkit", "rkhunter" to protect SSH from brute-force attacks
• **🧹 SSH Hardening:** Hardens SSH configuration for enhanced security.
  - Installs the TailScale client using the recommended method for the detected
    package manager, including SSH daemon "service"
  - Configures "firewalld" to trust the "tailscale" interface.
• **🔧 Zsh & Shell Customization:**
  - Installs and configures "oh-my-zsh"
  - Installs the **PowerLevel10k** theme for a powerful and fast prompt.
  - Enables auto-completion and plugins like "zsh-autosuggestions" and "zsh-extract"
  - Changes default shell to zsh and creates useful aliases.
• **🔧 Neovim Configuration:**
  - Installs the **NvChad** configuration for a beautiful and feature-rich Neovim
    using the initial plugin type professionally.

## 🚀 Quick Start: One-liner Execution

To run these scripts, you can execute them directly from this GitHub repository. G

### Main System Setup

This is the primary script. It performs all actions listed in the features section

```
curl -fsSL https://raw.githubusercontent.com/wesllgp/system_setup/main/system.sh
```

**Super User Utility (Optional)**

This script grants the current user passwordless `sudo` privileges and locks the root account's password. Use with caution.

```
curl -fsSL https://raw.githubusercontent.com/wesllgp/system_setup/main/super_user
```

## 📄 Scripts Overview

• **system.sh:** The main, all-in-one script for setting up a full system. It can be run on a fresh install to configure everything from security to the shell environment. To view its code, see this repository.

• **super_user.sh:** An optional standalone utility for administrative convenience. It configures passwordless `sudo` and disables direct root login via password as a security measure. To use this, see the `super-user.sh` file.

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
```

