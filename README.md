# dotfiles

Personal dotfiles and shared agent configuration for local development machines.

## Layout

- `agent/AGENTS.md`: shared instructions for Codex, Claude Code, and similar coding agents.
- `agent/skills/`: shared workflow skills.
- `codex/pets/`: managed Codex pet packages.
- `claude/`: Claude Code-specific settings, hooks, and agents.
- `config/starship.toml`: shared Starship prompt configuration.
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

The full install profiles install both standalone agent CLIs. Run `./install.sh set_claude` or `./install.sh set_codex` to install only Claude Code or Codex CLI.

## Agent runtime boundaries

`agent/AGENTS.md` and `agent/skills/` contain the portable cross-harness routing policy. `claude/settings.json` contains the intentional Claude Code baseline and is linked into `~/.claude`; Claude Code and Orca may append machine-local UI, hook, and status-line state to that linked file. Preserve those live additions when reconciling checkouts, but do not commit Orca `agent-hooks` commands, `statusLine`, or machine-specific UI state.

Codex model selection, reasoning effort, MCP servers, connectors, approvals, sessions, and plugin caches remain host-local under `~/.codex`. Shared policy refers to the configured Codex default instead of pinning a model name that the repository does not control.

## Shell prompt and navigation

`set_zsh` installs [Starship](https://starship.rs/) and [zoxide](https://github.com/ajeetdsouza/zoxide). The tracked Starship configuration is linked to `~/.config/starship.toml` during `create_symlinks`.

- `z <query>` jumps to the highest-ranked matching directory.
- `zi <query>` selects a matching directory interactively with fzf.

`set_gpg backup` exports secret keys, public keys, owner trust, and revocation certificates in portable GnuPG formats, then encrypts the archive with AES256. Interactive backups ask for the existing GPG key passphrase twice and use that same passphrase to unlock every protected source key and encrypt the archive. All secret keys must share that passphrase; the backup fails instead of creating an incomplete archive when one does not. The recovery flow does not depend on a machine-local Keychain item. `GPG_BACKUP_PASSPHRASE` remains available for non-interactive automation.

`set_gpg restore` verifies the sibling `.sha256` file when present, decrypts the archive, and imports it into the current `GNUPGHOME`. It does not restore machine-specific GnuPG configuration or absolute symlinks. Backups created with the older `gnupg-home-v1` format remain supported.
