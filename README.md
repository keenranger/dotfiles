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

# Write an encrypted, portable GnuPG backup to a private backup directory
./install.sh set_gpg backup /path/to/private/backup/dir

# Restore the backup on any machine with GnuPG installed
./install.sh set_gpg restore /path/to/gpg-secret-keys-YYYYMMDDTHHMMSSZ.tar.gz.gpg
```

`create_codex_symlinks` links managed shared skills individually into `~/.codex/skills` and copies managed pets into `~/.codex/pets` so Codex-installed runtime skills, non-managed symlinks, and non-managed pet directories remain in place.

`set_gpg backup` exports secret keys, public keys, owner trust, and revocation certificates in portable GnuPG formats, then encrypts the archive with AES256. Interactive backups ask for the existing GPG key passphrase twice and use that same passphrase to unlock every protected source key and encrypt the archive. All secret keys must share that passphrase; the backup fails instead of creating an incomplete archive when one does not. The recovery flow does not depend on a machine-local Keychain item. `GPG_BACKUP_PASSPHRASE` remains available for non-interactive automation.

`set_gpg restore` verifies the sibling `.sha256` file when present, decrypts the archive, and imports it into the current `GNUPGHOME`. It does not restore machine-specific GnuPG configuration or absolute symlinks. Backups created with the older `gnupg-home-v1` format remain supported.
