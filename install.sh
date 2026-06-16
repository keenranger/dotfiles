#!/bin/bash
set -euo pipefail

SRCDIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
CHECK_OS=$(uname)

COMMON_BREW_PACKAGES=(
	zsh
	fzf
	ripgrep
	bat
	gh
	neovim
	tmux
	gnupg
	fnm
	pnpm
)

LINUX_BASE_APT_PACKAGES=(
	build-essential
	curl
)

DARWIN_BREW_PACKAGES=(
	pinentry-mac
	lazygit
)

DARWIN_FONT_CASKS=(
	font-meslo-lg-nerd-font
	font-d2coding-nerd-font
)

DARWIN_APP_CASKS=(
	google-chrome
	codex-app
	ghostty
	rectangle
	karabiner-elements
	tailscale
	grandperspective
	rustdesk
)

DARWIN_CODEX_MACHINE_CASKS=(
	google-chrome
	codex-app
	ghostty
	rectangle
	grandperspective
	rustdesk
)

CLOUD_BREW_PACKAGES=(
	awscli
	opentofu
)

DARWIN_CONTAINER_BREW_PACKAGES=(
	podman
	podman-compose
)

brew_install(){
	[ "$#" -eq 0 ] && return 0
	brew install "$@"
}

brew_install_casks(){
	[ "$#" -eq 0 ] && return 0
	brew install --cask "$@"
}

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

replace_symlink(){
	local src=$1
	local dst=$2

	if [ -L "$dst" ] || [ -e "$dst" ]; then
		rm -rf "$dst"
	fi
	ln -s "$src" "$dst"
}

replace_symlink_if_source_exists(){
	local src=$1
	local dst=$2

	if [ -e "$src" ] || [ -L "$src" ]; then
		replace_symlink "$src" "$dst"
	elif [ -L "$dst" ]; then
		rm -f "$dst"
	fi
}

is_managed_skill_symlink(){
	local dst=$1
	local target
	target=$(readlink "$dst")

	case "$target" in
		"$SRCDIR/agent/skills"/*|"$SRCDIR/claude/skills"/*)
			return 0
			;;
		*)
			return 1
			;;
	esac
}

link_agent_skills(){
	local dst_dir=$1

	mkdir -p "$dst_dir"
	for src in "$SRCDIR"/agent/skills/*; do
		[ -e "$src" ] || [ -L "$src" ] || continue
		local name
		name=$(basename "$src")
		local rel="${src#"$SRCDIR"/}"
		if command -v git >/dev/null 2>&1 &&
			git -C "$SRCDIR" rev-parse --is-inside-work-tree >/dev/null 2>&1 &&
			git -C "$SRCDIR" check-ignore -q "$rel"; then
			continue
		fi
		local dst="$dst_dir/$name"

		if [ ! -e "$dst" ] && [ ! -L "$dst" ]; then
			replace_symlink "$src" "$dst"
		elif [ -L "$dst" ] && is_managed_skill_symlink "$dst"; then
			replace_symlink "$src" "$dst"
		elif [ -L "$dst" ]; then
			echo "Skipping existing non-managed skill symlink: $dst"
		elif [ -d "$dst" ] && diff -qr "$src" "$dst" >/dev/null 2>&1; then
			replace_symlink "$src" "$dst"
		else
			echo "Skipping existing non-symlink skill: $dst"
		fi
	done
}

create_shell_symlinks(){
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
}

create_claude_symlinks(){
	mkdir -p "$HOME/.claude"
	replace_symlink "$SRCDIR/agent/AGENTS.md" "$HOME/.claude/CLAUDE.md"
	replace_symlink "$SRCDIR/agent/AGENTS.md" "$HOME/.claude/AGENTS.md"
	replace_symlink "$SRCDIR/agent/skills" "$HOME/.claude/skills"
	replace_symlink_if_source_exists "$SRCDIR/claude/commands" "$HOME/.claude/commands"
	replace_symlink_if_source_exists "$SRCDIR/claude/hooks" "$HOME/.claude/hooks"
	replace_symlink_if_source_exists "$SRCDIR/claude/agents" "$HOME/.claude/agents"
	replace_symlink_if_source_exists "$SRCDIR/claude/settings.json" "$HOME/.claude/settings.json"
}

create_codex_symlinks(){
	mkdir -p "$HOME/.codex/skills"
	replace_symlink "$SRCDIR/agent/AGENTS.md" "$HOME/.codex/AGENTS.md"
	link_agent_skills "$HOME/.codex/skills"
}

create_symlinks(){
	echo "creating symlinks"
	create_shell_symlinks
	create_claude_symlinks
	create_codex_symlinks
}

set_zsh(){
	ensure_homebrew

	if [[ "$CHECK_OS" = "Darwin" ]]; then
		# macOS installation
		brew_install "${COMMON_BREW_PACKAGES[@]}" "${DARWIN_BREW_PACKAGES[@]}"
		brew_install_casks "${DARWIN_FONT_CASKS[@]}"
	else
		# Linux installation
		sudo apt update
		sudo apt install -y "${LINUX_BASE_APT_PACKAGES[@]}"
		brew_install "${COMMON_BREW_PACKAGES[@]}"
	fi

	# Setup fnm with Node LTS
	eval "$(fnm env)"
	fnm install --lts
	fnm default lts-latest

	# Add zsh to /etc/shells if not present (fixes "non-standard shell" error)
	ZSH_PATH=$(command -v zsh)
	if ! grep -qx "$ZSH_PATH" /etc/shells; then
		echo "Adding $ZSH_PATH to /etc/shells"
		echo "$ZSH_PATH" | sudo tee -a /etc/shells
	fi
	if [[ "$SHELL" != "$ZSH_PATH" ]]; then
		chsh -s "$ZSH_PATH"
	fi

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
	brew_install_casks "${DARWIN_APP_CASKS[@]}"
	brew_install terminal-notifier
	set_keyboard
}

set_codex_machine(){
	set_zsh
	create_symlinks
	set_claude
	if [[ "$CHECK_OS" = "Darwin" ]]; then
		brew_install_casks "${DARWIN_CODEX_MACHINE_CASKS[@]}"
		brew_install terminal-notifier
	fi
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
		brew_install "${CLOUD_BREW_PACKAGES[@]}"
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
	if command -v claude &> /dev/null; then
		echo "Claude Code already installed, skipping"
		return 0
	fi
	echo "Installing Claude Code..."
	curl -fsSL https://claude.ai/install.sh | bash
}

set_git(){
	git config --global user.name "Hankyeol Kyung"
	git config --global user.email "kghnkl0103@gmail.com"
	echo "Git configured: Hankyeol Kyung <kghnkl0103@gmail.com>"
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
		brew_install "${DARWIN_CONTAINER_BREW_PACKAGES[@]}"
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

usage(){
	cat <<'EOF'
Usage:
  ./install.sh                    Run the personal default profile
  ./install.sh codex_machine      Run the company Codex machine profile
  ./install.sh <command> [args]   Run one setup command

Commands:
  create_symlinks
  create_shell_symlinks
  create_claude_symlinks
  create_codex_symlinks
  set_zsh
  set_mac
  set_keyboard
  set_cloud
  set_claude
  set_git
  set_gpg [export|import FILE]
  set_codex_machine
  container
EOF
}

default_install(){
	set_zsh
	set_git
	create_symlinks
	set_claude
	if [[ "$CHECK_OS" = "Darwin" ]]; then
		set_mac
	fi
}

main(){
	if [ $# = 0 ]; then
		default_install
		return
	fi

	local command=$1
	shift
	case "$command" in
		default|install)
			default_install "$@"
			;;
		codex_machine|set_codex_machine)
			set_codex_machine "$@"
			;;
		create_symlinks|create_shell_symlinks|create_claude_symlinks|create_codex_symlinks|set_zsh|set_mac|set_keyboard|set_cloud|set_claude|set_git|set_gpg|container)
			"$command" "$@"
			;;
		help|-h|--help)
			usage
			;;
		*)
			echo "Unknown command: $command" >&2
			usage >&2
			return 1
			;;
	esac
}

main "$@"
