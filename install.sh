#!/bin/bash

SRCDIR=$(pwd)

create_symlinks(){
	echo "creating symlinks"
	ln -sf "$SRCDIR/vimrc" "$HOME/.vimrc"
	ln -sf "$SRCDIR/tmux.conf" "$HOME/.tmux.conf"
	ln -sf "$SRCDIR/zshrc" "$HOME/.zshrc"
	ln -sf "$SRCDIR/config/nvim" "$HOME/.config/nvim"
}

set_zsh(){
	/bin/sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
	git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
	/bin/sh -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
	brew install fzf
	git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
	git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
	git clone https://github.com/zsh-users/zsh-completions ${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-completions
	brew install neovim
	brew install node
	npm install -g @githubnext/github-copilot-cli
	github-copilot-cli auth
}

set_mac(){
	brew install --cask rectangle
}

if [ $# = 0 ]; then
	create_symlinks
	set_zsh
	if [[ "$CHECK_OS" = "Darwin"* ]]; then
		set_mac
	fi
else
	$1
fi

