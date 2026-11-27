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
# Compatibility snapshots: clean main and verified owner copies through 2026-11-25. this legacy target still serves protected
# repository-local instructions. Review ALL changes against the active global
# policy before deliberately updating this digest; do not edit it as global policy.
legacy_digest = hashlib.sha256(Path("agent/AGENTS.md").read_bytes()).hexdigest()
assert legacy_digest in {"8921a2bc20a226194fbacadf22ef8ad53d44952f53e1635802c997193cb192c9", "5da2c628f6aa19df0d54f49bf061782e41a1fc4261c434a9e33c4d69ce280466", "4c7e66607126129e263713e9d117530449eb5bbd502863b1d6520fa5d86b20b9", "53ab982d36e99d935a5c3fa6e2dbece7bca84a986f9b15ac5970396fb28aae8d"}, "Legacy compatibility guidance changed; reconcile every section with agent/global/AGENTS.md"
assert Path("claude/CLAUDE.md").is_symlink()
assert Path("claude/CLAUDE.md").readlink() == Path("../agent/AGENTS.md")
protections = {
    "Code Discipline": [
        "User authorization persists across turns",
        "same ongoing task",
        "unless the user explicitly granted standing authorization",
        "publishing and destructive-action approval requirements",
        "runtime permission controls",
        "No feature flags or runtime switches",
        "Do not propose one unless the user asks",
        "same kind of misinterpretation twice",
        "pause affected changes",
        "immediately",
        "do not apply it without authorization",
        "never state or imply",
        "generation/edit tool has returned a real result",
        "do not substitute a description"
    ],
    "Scope and Context": [
        "material assumptions",
        "not consent",
        "independent authorized work",
        "pause dependent changes",
        "irreversible"
    ],
    "Agents": [
        "exact user-named model request",
        "owner acceptance",
        "no-delegation",
        "Claude Opus",
        "coordinator",
        "small reads",
        "delegation costs",
        "Opus reviews directly",
        "independence materially improves confidence",
        "Opus reads the code",
        "Codex supplies an independent adversarial pass",
        "serial-specific device lease",
        "before any mutable ADB",
        "release it",
        "pre-authorized",
        "third-party terms",
        "purchases, subscriptions",
        "unrelated permission grants",
        "timed interaction",
        "target-state UI/layout",
        "visually checked same-state",
        "reconnect/read-back",
        "every passed gate",
        "every missing physical or account-dependent gate",
        "device serial/model verified from the device",
        "worker that produced the evidence",
        "may work in parallel only",
        "read-only",
        "write scopes are explicitly disjoint",
        "Do not use `codex review --uncommitted`",
        "while the installed `review` skill auto-activates",
        "recursively launches more review processes"
    ],
    "Investigation Discipline": [
        "git log --all -S",
        "git rev-list --remotes | head -200"
    ],
    "Computer Use / GUI Automation": [
        "Automatic denial remains denial, never permission to switch executors",
        "must NOT drive GUI loops",
        "except the exceptions",
        "runtime controls",
        "executor\u0027s documented interactive approval entry point",
        "applicable grant",
        "After any automatic/explicit denial",
        "original executor",
        "never switch executors or reclassify",
        "request_access",
        "only if that executor provides it",
        "one verification screenshot",
        "user\u0027s explicit request",
        "Do not send an unapproved app through that path unless",
        "current documented contract provides an interactive approval surface",
        "applicable grant has been obtained"
    ],
    "Login authorization": [
        "standard `openid`, `email`, and `profile`",
        "Continue without duplicate consent",
        "broader OAuth scopes",
        "unrelated external writes",
        "secret storage",
        "company store-console work, including Google Play Console and App Store Connect",
        "rather than a personal account",
        "unrelated accounts",
        "verbatim owner authorization",
        "exact app/origin/account scope",
        "not direct user approval",
        "before a short-lived OAuth",
        "If a click is denied, stop that action",
        "original executor",
        "action-scoped approval/elicitation mechanism",
        "user\u0027s renewed verbatim authorization",
        "actual runtime grant",
        "a chat instruction or configuration edit is not a grant",
        "without restarting OAuth",
        "Do not change permission settings, allowlists or classifiers",
        "retry through another executor",
        "When sign-in requires switching accounts",
        "before asking the user",
        "observed MFA, unavailable credential, or runtime permission gate",
        "Before committing to a provider-dependent release step",
        "exact provider origins",
        "runtime permission denial",
        "transport failure",
        "When an observed access gate requires user action",
        "once",
        "single next action needed",
        "continue independent authorized work",
        "When the user explicitly asks Codex",
        "within actual runtime permissions",
        "existing Claude task",
        "company-login",
        "Google Play Console",
        "App Store Connect",
        "verified existing company account",
        "coordinator \"GO\" is not direct user approval",
        "Preserve that blocker across turns",
        "do not treat changing executors as a grant"
    ],
    "Store release automation": [
        "Reuse uploaded builds/version codes",
        "never reupload",
        "upload, review submission, approval and public availability distinct",
        "exact app/build",
        "unrelated work",
        "never switch to a CLI/API or another executor to bypass an explicitly denied action",
        "without duplicate consent",
        "actual provider capabilities and authentication",
        "if suitable authentication is unavailable",
        "existing authorized credential references",
        "create new credentials without authorization",
        "official provider APIs",
        "supported CLIs",
        "Verify current capabilities in official documentation",
        "Preserve the project\u0027s chosen build and upload pipeline",
        "Never extract server-held credentials",
        "API authentication does not override user authorization or runtime permissions",
        "Do not promise full automation until"
    ],
    "PR / Push discipline": [
        "local review -> ordinary PR",
        "PR-head review/required checks",
        "exact committed PR head deployed to TEST and runtime-verified",
        "authorized merge",
        "merged revision deployed to LIVE and verified",
        "skipping a named gate requires explicit user instruction",
        "Attach real before/after screenshots",
        "GitHub PR description",
        "GitHub-hosted attachments",
        "for the requested comparison",
        "Never commit validation screenshots",
        "NEVER `git push` or `gh pr create` without explicit user instruction",
        "Prep a PR means prepare, not publish",
        "within named scope/targets",
        "without asking again",
        "A request to push existing commits authorizes only those commits",
        "not PR creation or unrequested commits",
        "necessary commit/push",
        "Neither permits merge, release, force-push",
        "Check remote state",
        "do not authorize external writes, including `gh issue create`",
        "classifier acceptance is not user authorization",
        "Do not retry denied actions",
        "report the deadlock once",
        "explicit action-specific user authorization",
        "actual supported runtime grant",
        "Neither replaces the other",
        "Hook repetition grants no authority",
        "another executor",
        "Never deploy application changes from an uncommitted worktree.",
        "Never deploy directly from an unmerged feature branch to LIVE",
        "TEST deployment identity and verification",
        "PR, tested commit",
        "merge commit",
        "LIVE deployment identity",
        "source is preserved remotely"
    ],
    "Homebrew": [
        "private product tap",
        "<user>/homebrew-<product>",
        "Casks/<name>.rb",
        "Formula/<name>.rb"
    ],
    "SleepRoutine DB on this Mac": [
        "START TRANSACTION READ ONLY",
        "ROLLBACK",
        "live writes require explicit task-specific authorization",
        "avoid PII columns"
    ],
    "Mobile Build Resources": [
        "explicit approval for exact paths",
        "dirty state and active-use evidence",
        "source, signing material, secrets or datasets",
        "publishing gates",
        "Avoid repeating full builds across local, GitHub and EAS",
        "changed inputs, a failure or an unresolved verification gate",
        "A simulator-only target is still a native build",
        "explicitly requested",
        "hosted pipeline"
    ],
    "Mirakle on this Mac": [
        "Only the identified SleepHub app",
        "existing runtime credentials and unsigned-Debug/local-signing hooks",
        "Never send those credentials or certificate assumptions to other projects",
        "Signing keys stay on the Mac"
    ],
    "TypeScript": [
        "when a library exports a discriminated identifier-union with a sibling brand mapper",
        "UnitForIdentifier<T>",
        "as const satisfies readonly Generic[]",
        "const m = <T extends ...>(x: Generic<T>): Generic<T> => x"
    ],
    "Kotlin": [
        "IllegalArgumentException(\"Cannot round NaN value.\")",
        "NaN",
        "Infinity"
    ],
    "macOS": [
        "matching the source container",
        "closed `keenranger/healthdrop-skills` PR #2 for the cautionary tale",
        "naive workaround",
        "does NOT work",
        "Terminal (works)",
        "(returns empty)",
        "entitlement, not FDA"
    ],
    "Accessibility": [
        "people with disabilities can fully enjoy",
        "part of everyday design",
        "assistive technology",
        "feedback from people who rely on it"
    ]
}
platform_guards = [
    "ORCA_WORKTREE_ID",
    "serial-specific device lease",
    "isComposing",
    "and 0xff",
    "NaN",
    "maxSdkVersion",
    "SSH_AUTH_SOCK",
    "EAS Cloud",
    "mirakle-sleephub",
    "R8YL5098D7A",
    "aums-login",
    "Non-Orca Claude one-shot",
    "permission denial",
    "Never print credentials or place them in command-line arguments",
    "Large diffs",
    "when independence materially improves confidence",
    "subscriptions",
    "unrelated permission grants",
    "timed interaction",
    "target-state UI/layout capture",
    "visually checked same-state screenshot",
    "layout dump",
    "delayed screenshot",
    "worker that produced the evidence",
    "supervised Orca Claude browser executor",
    "actual capabilities/result",
    "targeted clean native-only build",
    "inspect free space",
    "defer if insufficient",
    "2번 태블릿",
    "transport ID",
    "GitHub-hosted attachments",
    "No feature flags",
    "git commit -S",
    "explicit user instruction",
    "exact committed PR head deployed to TEST and runtime-verified",
    "authorized merge",
    "LIVE"
]

def validate_policy(policy):
    for section, anchors in protections.items():
        match = re.search(r"^## " + re.escape(section) + r"\n(.*?)(?=^## |\Z)", policy, re.M | re.S)
        label = {
            "Login authorization": "login authorization",
            "Store release automation": "store release",
        }.get(section, section)
        assert match, "Missing " + label + " safeguard section"
        for anchor in anchors:
            assert anchor in match.group(1), "Missing " + label + " safeguard: " + anchor
    for anchor in platform_guards:
        assert anchor in policy, "Missing platform safeguard: " + anchor

validate_policy(text)
# Delete complete instruction lines, not only the expected words. Validation
# has no canonical digest gate, so repinning a hash cannot hide a lost clause.
omission_cases = set()
for section, anchors in protections.items():
    area = re.search(r"^## " + re.escape(section) + r"\n(.*?)(?=^## |\Z)", text, re.M | re.S).group(1)
    for anchor in anchors:
        matching_lines = [line for line in area.splitlines(True) if anchor in line]
        if len(matching_lines) == 1:
            omission_cases.add(matching_lines[0])
for line in omission_cases:
    try:
        validate_policy(text.replace(line, "", 1))
    except AssertionError:
        pass
    else:
        raise AssertionError("Missing policy instruction escaped semantic checks: " + line)
# Partial-condition mutations protect against a sentence surviving after its
# authority, scope or evidence qualifier has been weakened.
weakened_conditions = [
    ("to a CLI/API or another executor", "to another executor"),
    ("unless the user explicitly granted standing authorization", "unless standing authorization exists"),
    ("explicit approval for exact paths", "approval"),
    ("from an uncommitted worktree", "of uncommitted app files"),
    ("TEST deployment identity and verification", "TEST verification"),
    ("When sign-in requires switching accounts, ", ""),
    ("if suitable authentication is unavailable", "if credential references are absent"),
    ("Only the identified SleepHub app", "SleepHub apps"),
    ("every passed gate", "passed gates"),
    ("START TRANSACTION READ ONLY", "START TRANSACTION"),
    ("merged revision deployed to LIVE", "feature branch deployed to LIVE"),
    ("Neither replaces the other.", ""),
]
for before, after in weakened_conditions:
    assert before in text, "Stale omission fixture: " + before
    try:
        validate_policy(text.replace(before, after))
    except AssertionError:
        pass
    else:
        raise AssertionError("Weakened policy qualifier escaped checks: " + before)
workflow = Path(".github/workflows/enhance.yml").read_text()
assert "bash tests/global-instructions.sh" in workflow
assert "ln -sf \"$PWD/agent/global/AGENTS.md\" ~/.claude/CLAUDE.md" in workflow
assert not re.search(r"ln .*~/.claude/AGENTS.md", workflow)
installer = Path("install.sh").read_text()
assert "Warning: preserving $HOME/.claude/AGENTS.md" in installer
assert "$SRCDIR/agent/global/AGENTS.md" in installer
print("Single-source safeguards, legacy compatibility and active-consumer checks passed")
'
