.DEFAULT_GOAL := install
SRCDIR := $(shell pwd)

copyfiles:
		@echo "copying files"
		
		@ln -s -b $(SRCDIR)/vimrc $(HOME)/.vimrc
		@ln -s -b $(SRCDIR)/tmux.conf $(HOME)/.tmux.conf
		@ln -s -b $(SRCDIR)/:zshrc $(HOME)/.zshrc
		@ln -s -b $(SRCDIR)/nvim/ $(HOME)/.config/nvim/
