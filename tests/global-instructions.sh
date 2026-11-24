#!/bin/bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

python3 -c '
from pathlib import Path
import hashlib
import re

baseline = Path("agent/global/AGENTS.md")
text = baseline.read_text()
assert not re.search(r"(?m)^\s*@", text), "Global instructions must be self-contained"
assert "agent/reference/" not in text
# Compatibility snapshots: clean main and verified owner copies through 2026-11-24. this legacy target still serves protected
# repository-local instructions. Review ALL changes against the active global
# policy before deliberately updating this digest; do not edit it as global policy.
legacy_digest = hashlib.sha256(Path("agent/AGENTS.md").read_bytes()).hexdigest()
assert legacy_digest in {"8921a2bc20a226194fbacadf22ef8ad53d44952f53e1635802c997193cb192c9", "5da2c628f6aa19df0d54f49bf061782e41a1fc4261c434a9e33c4d69ce280466", "4c7e66607126129e263713e9d117530449eb5bbd502863b1d6520fa5d86b20b9"}, "Legacy compatibility guidance changed; reconcile every section with agent/global/AGENTS.md"
assert Path("claude/CLAUDE.md").is_symlink()
assert Path("claude/CLAUDE.md").readlink() == Path("../agent/AGENTS.md")
for required in ["ORCA_WORKTREE_ID", "serial-specific device lease", "isComposing",
                 "and 0xff", "NaN", "maxSdkVersion", "SSH_AUTH_SOCK",
                 "EAS Cloud", "mirakle-sleephub", "R8YL5098D7A", "aums-login",
                 "Non-Orca Claude one-shot", "permission denial",
                 "Never print credentials or place them in command-line arguments",
                 "Large diffs", "when independence materially improves confidence",
                 "subscriptions", "unrelated permission grants", "timed interaction",
                 "target-state UI/layout capture", "visually checked same-state screenshot",
                 "layout dump", "delayed screenshot", "worker that produced the evidence",
                 "supervised Orca Claude browser executor", "actual capabilities and result",
                 "targeted clean native-only build", "actual free space", "defer if insufficient",
                 "2번 태블릿", "transport ID", "GitHub-hosted attachments",
                 "No feature flags", "git commit -S", "explicit user instruction",
                 "exact committed PR head to TEST", "authorized merge", "LIVE"]:
    assert required in text, required
for required in ["company-login", "exact app/origin/account scope", "actual runtime grant",
                 "exact provider origins", "observed MFA, unavailable credential, or runtime permission gate",
                 "standard `openid`, `email`, and `profile`", "broader OAuth scopes",
                 "Google Play Console", "App Store Connect", "verified existing company account",
                 "a coordinator\u0027s \"GO\" is not direct user approval",
                 "action-scoped approval/elicitation mechanism", "secret storage",
                 "Do not change permission settings, allowlists or classifiers",
                 "Preserve that blocker across turns", "do not treat changing executors as a grant"]:
    assert required in text, "Missing login authorization safeguard: " + required
workflow = Path(".github/workflows/enhance.yml").read_text()
assert "bash tests/global-instructions.sh" in workflow
assert "ln -sf \"$PWD/agent/global/AGENTS.md\" ~/.claude/CLAUDE.md" in workflow
assert not re.search(r"ln .*~/.claude/AGENTS.md", workflow)
installer = Path("install.sh").read_text()
assert "Warning: preserving $HOME/.claude/AGENTS.md" in installer
assert "$SRCDIR/agent/global/AGENTS.md" in installer
print("Single-source safeguards, legacy compatibility and active-consumer checks passed")
'
