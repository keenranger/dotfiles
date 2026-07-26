#!/bin/bash
set -euo pipefail

repo_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
test_root=$(mktemp -d)
trap 'rm -rf "$test_root"' EXIT

source_home="$test_root/source/gnupg"
destination_home="$test_root/destination/gnupg"
backup_dir="$test_root/drive-backup"
passphrase=portable-test-passphrase

mkdir -p "$source_home" "$destination_home" "$backup_dir"
chmod 700 "$source_home" "$destination_home"

GNUPGHOME="$source_home" gpg --batch --pinentry-mode loopback --passphrase "$passphrase" \
	--quick-generate-key 'Portable Backup Test <portable-backup@example.invalid>' ed25519 sign 1d
GNUPGHOME="$source_home" gpgconf --kill gpg-agent
source_fingerprint=$(GNUPGHOME="$source_home" gpg --batch --with-colons --list-secret-keys |
	awk -F: '/^fpr/{print $10; exit}')

HOME="$test_root/source" GNUPGHOME="$source_home" GPG_BACKUP_PASSPHRASE="$passphrase" \
	"$repo_dir/install.sh" set_gpg backup "$backup_dir"
backup_file=$(find "$backup_dir" -maxdepth 1 -type f -name '*.tar.gz.gpg' -print -quit)

HOME="$test_root/destination" GNUPGHOME="$destination_home" GPG_BACKUP_PASSPHRASE="$passphrase" \
	"$repo_dir/install.sh" set_gpg restore "$backup_file"
destination_fingerprint=$(GNUPGHOME="$destination_home" gpg --batch --with-colons --list-secret-keys |
	awk -F: '/^fpr/{print $10; exit}')
[ "$source_fingerprint" = "$destination_fingerprint" ]
[ -f "$destination_home/openpgp-revocs.d/$source_fingerprint.rev" ]

printf 'portable-sign-test\n' |
	GNUPGHOME="$destination_home" gpg --batch --yes --pinentry-mode loopback \
		--passphrase "$passphrase" --armor --detach-sign \
		--output "$test_root/signature.asc"
[ -s "$test_root/signature.asc" ]

if HOME="$test_root/wrong-password" GNUPGHOME="$test_root/wrong-password/gnupg" \
	GPG_BACKUP_PASSPHRASE=wrong-passphrase \
	"$repo_dir/install.sh" set_gpg restore "$backup_file" >/dev/null 2>&1; then
	echo "Restore unexpectedly accepted the wrong passphrase" >&2
	exit 1
fi

tampered_backup="$backup_dir/tampered.tar.gz.gpg"
cp "$backup_file" "$tampered_backup"
cp "$backup_file.sha256" "$tampered_backup.sha256"
printf 'tampered' >> "$tampered_backup"
if HOME="$test_root/tampered" GNUPGHOME="$test_root/tampered/gnupg" \
	GPG_BACKUP_PASSPHRASE="$passphrase" \
	"$repo_dir/install.sh" set_gpg restore "$tampered_backup" >/dev/null 2>&1; then
	echo "Restore unexpectedly accepted a checksum mismatch" >&2
	exit 1
fi

GNUPGHOME="$source_home" gpg --batch --pinentry-mode loopback --passphrase different-passphrase \
	--quick-generate-key 'Different Passphrase Test <different-passphrase@example.invalid>' ed25519 sign 1d
GNUPGHOME="$source_home" gpgconf --kill gpg-agent
mixed_passphrase_backup_dir="$test_root/mixed-passphrase-backup"
if HOME="$test_root/source" GNUPGHOME="$source_home" GPG_BACKUP_PASSPHRASE="$passphrase" \
	"$repo_dir/install.sh" set_gpg backup "$mixed_passphrase_backup_dir" >/dev/null 2>&1; then
	echo "Backup unexpectedly accepted secret keys with different passphrases" >&2
	exit 1
fi

echo "Portable GPG backup and restore test passed"
