#!/bin/bash
set -euo pipefail

SRCDIR=$(pwd)
CHECK_OS=$(uname)

ensure_homebrew(){
	if ! command -v brew &> /dev/null; then
		echo "Installing Homebrew..."
		NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
		if [[ "$CHECK_OS" = "Darwin" ]]; then
			eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || /usr/local/bin/brew shellenv)"
		else
			eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
		fi
	fi
}

create_symlinks(){
	echo "creating symlinks"
	ln -sf "$SRCDIR/vimrc" "$HOME/.vimrc"
	ln -sf "$SRCDIR/tmux.conf" "$HOME/.tmux.conf"
	ln -sf "$SRCDIR/zshrc" "$HOME/.zshrc"
	# Ensure .config directory exists
	mkdir -p "$HOME/.config"
	# Remove existing nvim symlink to prevent recursive linking
	[ -L "$HOME/.config/nvim" ] && rm "$HOME/.config/nvim"
	ln -sf "$SRCDIR/config/nvim" "$HOME/.config/nvim"
	# macOS only configurations
	if [[ "$(uname)" = "Darwin" ]]; then
		mkdir -p "$HOME/.config/karabiner"
		ln -sf "$SRCDIR/config/karabiner/karabiner.json" "$HOME/.config/karabiner/karabiner.json"
		mkdir -p "$HOME/.gnupg"
		chmod 700 "$HOME/.gnupg"
		ln -sf "$SRCDIR/gnupg/gpg-agent.conf" "$HOME/.gnupg/gpg-agent.conf"
		ln -sf "$SRCDIR/gnupg/common.conf" "$HOME/.gnupg/common.conf"
	fi
	# Claude configuration
	mkdir -p "$HOME/.claude"
	# Remove existing symlinks only if they exist
	[ -e "$HOME/.claude/CLAUDE.md" ] && rm -f "$HOME/.claude/CLAUDE.md"
	[ -e "$HOME/.claude/commands" ] && rm -rf "$HOME/.claude/commands"
	[ -e "$HOME/.claude/hooks" ] && rm -rf "$HOME/.claude/hooks"
	[ -e "$HOME/.claude/agents" ] && rm -rf "$HOME/.claude/agents"
	[ -e "$HOME/.claude/skills" ] && rm -rf "$HOME/.claude/skills"
	[ -e "$HOME/.claude/settings.json" ] && rm -f "$HOME/.claude/settings.json"
	# Create symlinks for all Claude files
	ln -sf "$SRCDIR/claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
	ln -sf "$SRCDIR/claude/commands" "$HOME/.claude/commands"
	ln -sf "$SRCDIR/claude/hooks" "$HOME/.claude/hooks"
	ln -sf "$SRCDIR/claude/agents" "$HOME/.claude/agents"
	ln -sf "$SRCDIR/claude/skills" "$HOME/.claude/skills"
	ln -sf "$SRCDIR/claude/settings.json" "$HOME/.claude/settings.json"
}

set_zsh(){
	ensure_homebrew

	if [[ "$CHECK_OS" = "Darwin" ]]; then
		# macOS installation
		brew install zsh fzf ripgrep bat gh neovim tmux gnupg pinentry-mac
		brew install --cask font-meslo-lg-nerd-font
	else
		# Linux installation
		sudo apt update
		sudo apt install -y zsh build-essential curl neovim tmux

		# Install GitHub CLI on Linux
		type -p curl >/dev/null || (sudo apt update && sudo apt install curl -y)
		curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
		&& sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
		&& echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
		&& sudo apt update \
		&& sudo apt install gh -y

		brew install fzf ripgrep bat
	fi

	# Add zsh to /etc/shells if not present (fixes "non-standard shell" error)
	ZSH_PATH=$(command -v zsh)
	if ! grep -qx "$ZSH_PATH" /etc/shells; then
		echo "Adding $ZSH_PATH to /etc/shells"
		echo "$ZSH_PATH" | sudo tee -a /etc/shells
	fi
	chsh -s "$ZSH_PATH"

	# Install Oh My Zsh if not already installed
	if [ ! -d "$HOME/.oh-my-zsh" ]; then
		RUNZSH=no CHSH=no /bin/sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
	fi

	# Install plugins/themes if not already present
	ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
	[ ! -d "$ZSH_CUSTOM/themes/powerlevel10k" ] && git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$ZSH_CUSTOM/themes/powerlevel10k"
	[ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ] && git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
	[ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ] && git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
	[ ! -d "$ZSH_CUSTOM/plugins/zsh-completions" ] && git clone https://github.com/zsh-users/zsh-completions "$ZSH_CUSTOM/plugins/zsh-completions"
	/bin/sh -c "$(curl -fsSL https://astral.sh/uv/install.sh)"
	sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
		https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'

	# Configure brew autoupdate for daily automatic updates
	brew tap homebrew/autoupdate
	brew autoupdate delete 2>/dev/null || true
	brew autoupdate start 86400 --upgrade --cleanup
}

set_mac(){
	ensure_homebrew
	brew install --cask iterm2 rectangle karabiner-elements
	brew install terminal-notifier
	set_keyboard
}

set_keyboard(){
	# macOS only: Configure F18 as input source shortcut
	# NOTE: Adding input sources via defaults write is unreliable on modern macOS
	#       Add Korean (두벌식) manually: System Settings > Keyboard > Input Sources
	[[ "$(uname)" != "Darwin" ]] && return

	echo "Configuring keyboard shortcut..."

	# Set F18 (keycode 79) for "Select next source in Input menu" (hotkey ID 61)
	# Using PlistBuddy for correct types (defaults write creates strings instead of integers)
	# 8388608 (0x800000) is the fn key modifier required for F-keys on macOS
	local PLIST=~/Library/Preferences/com.apple.symbolichotkeys.plist
	/usr/libexec/PlistBuddy -c "Delete :AppleSymbolicHotKeys:61" "$PLIST" 2>/dev/null || true
	/usr/libexec/PlistBuddy -c "Add :AppleSymbolicHotKeys:61 dict" "$PLIST"
	/usr/libexec/PlistBuddy -c "Add :AppleSymbolicHotKeys:61:enabled bool true" "$PLIST"
	/usr/libexec/PlistBuddy -c "Add :AppleSymbolicHotKeys:61:value dict" "$PLIST"
	/usr/libexec/PlistBuddy -c "Add :AppleSymbolicHotKeys:61:value:type string standard" "$PLIST"
	/usr/libexec/PlistBuddy -c "Add :AppleSymbolicHotKeys:61:value:parameters array" "$PLIST"
	/usr/libexec/PlistBuddy -c "Add :AppleSymbolicHotKeys:61:value:parameters:0 integer 65535" "$PLIST"
	/usr/libexec/PlistBuddy -c "Add :AppleSymbolicHotKeys:61:value:parameters:1 integer 79" "$PLIST"
	/usr/libexec/PlistBuddy -c "Add :AppleSymbolicHotKeys:61:value:parameters:2 integer 8388608" "$PLIST"

	# Apply changes instantly
	killall cfprefsd 2>/dev/null
	/System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u

	echo "F18 shortcut configured for input source switching."
}

set_cloud(){
	ensure_homebrew
	if [[ "$CHECK_OS" = "Darwin" ]]; then
		# macOS installation
		brew install awscli opentofu
	else
		# Linux installation
		# AWS CLI
		curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
		unzip awscliv2.zip
		sudo ./aws/install
		rm -rf aws awscliv2.zip
		# OpenTofu 
		curl --proto '=https' --tlsv1.2 -fsSL https://get.opentofu.org/install-opentofu.sh -o install-opentofu.sh
		chmod +x install-opentofu.sh
		./install-opentofu.sh --install-method deb
		rm install-opentofu.sh
	fi
}

set_claude(){
	echo "Installing Claude Code..."
	curl -fsSL https://claude.ai/install.sh | bash
}

set_gpg(){
	# Configure GPG for git commit signing (shared key approach)
	# Usage:
	#   ./install.sh set_gpg              - configure git with existing key
	#   ./install.sh set_gpg export       - export private key to ./private.key
	#   ./install.sh set_gpg import FILE  - import key, trust, configure, delete file

	case "${1:-}" in
		export)
			KEY_ID=$(gpg --list-secret-keys --keyid-format=long 2>/dev/null | awk -F'/' '/^sec/{print $2}' | cut -d' ' -f1 | head -1)
			[ -z "$KEY_ID" ] && { echo "No key to export"; return 1; }
			gpg --export-secret-keys --armor "$KEY_ID" > private.key
			echo "Exported to ./private.key - transfer securely and delete"
			return 0
			;;
		import)
			[ -z "${2:-}" ] || [ ! -f "${2:-}" ] && { echo "Usage: set_gpg import FILE"; return 1; }
			gpg --import "$2"
			FINGERPRINT=$(gpg --list-secret-keys --with-colons 2>/dev/null | awk -F: '/^fpr/{print $10; exit}')
			echo "$FINGERPRINT:6:" | gpg --import-ownertrust
			rm -P "$2" 2>/dev/null || shred -u "$2" 2>/dev/null || rm "$2"
			echo "Key imported, trusted, file deleted"
			;;
	esac

	KEY_ID=$(gpg --list-secret-keys --keyid-format=long 2>/dev/null | awk -F'/' '/^sec/{print $2}' | cut -d' ' -f1 | head -1)

	if [ -z "$KEY_ID" ]; then
		echo "No GPG key found. Usage:"
		echo "  ./install.sh set_gpg import /path/to/private.key"
		return 1
	fi

	git config --global user.signingkey "$KEY_ID"
	git config --global commit.gpgsign true
	git config --global tag.gpgsign true
	[[ "$(uname)" = "Darwin" ]] && git config --global gpg.program /opt/homebrew/bin/gpg

	gpgconf --kill gpg-agent

	echo "Configured signing with key: $KEY_ID"
	echo "Upload to GitHub: gpg --armor --export $KEY_ID | gh gpg-key add -"
}

container(){
	ensure_homebrew
	if [[ "$(uname)" = "Darwin" ]]; then
		# macOS installation
		brew install podman podman-compose
		podman machine init
		podman machine start
	else
		# Linux installation
		sudo apt-get update
		sudo apt-get install -y podman
		# Enable podman socket for Docker compatibility
		systemctl --user enable --now podman.socket
		# Install podman-compose via pip on Linux
		pip3 install --user podman-compose
	fi
}

if [ $# = 0 ]; then
	set_zsh
	create_symlinks
	set_claude
	if [[ "$CHECK_OS" = "Darwin" ]]; then
		set_mac
	fi
else
	func=$1
	shift
	$func "$@"
fi

