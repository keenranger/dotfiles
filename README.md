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
# Full personal-machine bootstrap (one administrator prompt)
./install.sh

# Bootstrap and restore a separate encrypted GPG credential backup
./install.sh bootstrap --gpg-backup /path/to/gpg-secret-keys-YYYYMMDDTHHMMSSZ.tar.gz.gpg

# Company Codex machine bootstrap without personal global Git identity
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

Both full-machine profiles validate administrator access once with `sudo -v`, keep that timestamp alive only while the bootstrap process runs, and use non-interactive `sudo -n` for later privileged steps. The personal profile runs in this order: shell and tooling, global Git identity, dotfile symlinks, optional GPG restore, Claude Code and macOS apps including ChatGPT, then a short list of remaining sign-in and macOS permission steps. The GPG backup passphrase remains a separate prompt. Existing individual setup commands remain available for interactive use.

If `/Applications/ChatGPT.app` already exists, the installer skips its Homebrew cask and continues installing the other apps independently.

When a dotfile destination already contains a real file, directory, or different symlink, the installer moves it into a dated directory under `~/.dotfiles-backups/` before creating the managed symlink. Re-running against an already-correct managed symlink leaves it unchanged.

`create_codex_symlinks` links managed shared skills individually into `~/.codex/skills` and copies managed pets into `~/.codex/pets` so Codex-installed runtime skills, non-managed symlinks, and non-managed pet directories remain in place.

`set_gpg backup` exports secret keys, public keys, owner trust, and revocation certificates in portable GnuPG formats, then encrypts the archive with AES256. Interactive backups ask for the existing GPG key passphrase twice and use that same passphrase to unlock every protected source key and encrypt the archive. All secret keys must share that passphrase; the backup fails instead of creating an incomplete archive when one does not. The recovery flow does not depend on a machine-local Keychain item. `GPG_BACKUP_PASSPHRASE` remains available for non-interactive automation.

`set_gpg restore` verifies the sibling `.sha256` file when present, decrypts the archive, and imports it into the current `GNUPGHOME`. It does not restore machine-specific GnuPG configuration or absolute symlinks. Backups created with the older `gnupg-home-v1` format remain supported.
