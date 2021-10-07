.DEFAULT_GOAL := install
SRCDIR := $(shell pwd)

copyfiles:
		@echo "copying files"
		@mv $(HOME)/.vimrc $(HOME)/.vimrc.bak
		@mv $(HOME)/.tmux.conf $(HOME)/.tmux.conf.bak
		@mv $(HOME)/.zshrc $(HOME)/.zshrc.bak

		@ln -s $(SRCDIR)/.vimrc $(HOME)/.vimrc
		@ln -s $(SRCDIR)/.tmux.conf $(HOME)/.tmux.conf
		@ln -s $(SRCDIR)/.zshrc $(HOME)/.zshrc 