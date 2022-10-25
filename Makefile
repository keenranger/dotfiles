.DEFAULT_GOAL := install
SRCDIR := $(shell pwd)

copyfiles:
		@echo "copying files"
		@ln -s $(SRCDIR)/vimrc $(HOME)/.vimrc
		@ln -s $(SRCDIR)/tmux.conf $(HOME)/.tmux.conf
		@ln -s $(SRCDIR)/zshrc $(HOME)/.zshrc
		@ln -s $(SRCDIR)/config/nvim $(HOME)/.config/nvim
shell:
		@/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
		@brew install fzf
mac: