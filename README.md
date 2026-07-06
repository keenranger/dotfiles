# dotfiles

Personal dotfiles and shared agent configuration for local development machines.

## Layout

- `agent/AGENTS.md`: shared instructions for Codex, Claude Code, and similar coding agents.
- `agent/skills/`: shared workflow skills.
- `codex/pets/`: managed Codex pet packages.
- `claude/`: Claude Code-specific settings, hooks, and agents.
- `install.sh`: modular setup, symlink, and managed artifact installer.

## Common Commands

```bash
# Full personal-machine setup
./install.sh

# Company Codex machine setup without personal global Git identity
./install.sh codex_machine

# Refresh symlinks and managed Codex pet copies
./install.sh create_symlinks

# Refresh only Codex shared instructions, managed skill links, and managed pet copies
./install.sh create_codex_symlinks

# Refresh only Claude Code shared instructions, skills, hooks, agents, and settings
./install.sh create_claude_symlinks

# Write an encrypted GnuPG key-store backup to a private backup directory
./install.sh set_gpg backup /path/to/private/backup/dir

# Restore an encrypted GnuPG key-store backup
./install.sh set_gpg restore /path/to/gpg-secret-keys-YYYYMMDDTHHMMSSZ.tar.gz.gpg
```

`create_codex_symlinks` links managed shared skills individually into `~/.codex/skills` and copies managed pets into `~/.codex/pets` so Codex-installed runtime skills, non-managed symlinks, and non-managed pet directories remain in place.

`set_gpg backup` writes only a passphrase-encrypted archive to the target directory. It reads the archive encryption passphrase from `GPG_BACKUP_PASSPHRASE`, or on macOS from the `dotfiles.gpg-backup` generic Keychain item.
