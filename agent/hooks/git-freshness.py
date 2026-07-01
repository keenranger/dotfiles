#!/usr/bin/env python3
"""Refresh git remotes and surface stale-base state to agent hooks."""

from __future__ import annotations

import hashlib
import json
import os
import re
import subprocess
import sys
import time
from pathlib import Path
from typing import Any


BASE_REF_CANDIDATES = ("origin/develop", "origin/main", "origin/master")
FETCH_MIN_INTERVAL_SECONDS = 60
FETCH_TIMEOUT_SECONDS = 45

MUTATING_SHELL_RE = re.compile(
    r"(^|[;&|]\s*)("
    r"git\s+(add|commit|push|tag|checkout\s+-b|switch\s+-c)|"
    r"gh\s+pr\s+create|"
    r"gh\s+release\s+create|"
    r"rm\s+-rf|"
    r"mv\s+|"
    r"cp\s+"
    r")\b"
)

EDIT_TOOL_NAMES = {
    "apply_patch",
    "Edit",
    "Write",
    "MultiEdit",
    "NotebookEdit",
}


def read_input() -> dict[str, Any]:
    raw = sys.stdin.read().strip()
    if not raw:
        return {}
    return json.loads(raw)


def run_git(
    cwd: str, *args: str, timeout: int = 10
) -> subprocess.CompletedProcess[str]:
    env = os.environ.copy()
    env["GIT_TERMINAL_PROMPT"] = "0"
    return subprocess.run(
        ["git", "-C", cwd, *args],
        capture_output=True,
        text=True,
        timeout=timeout,
        env=env,
        check=False,
    )


def git_stdout(cwd: str, *args: str, timeout: int = 10) -> str | None:
    result = run_git(cwd, *args, timeout=timeout)
    if result.returncode != 0:
        return None
    return result.stdout.strip()


def inside_worktree(cwd: str) -> bool:
    return git_stdout(cwd, "rev-parse", "--is-inside-work-tree") == "true"


def worktree_root(cwd: str) -> str:
    return git_stdout(cwd, "rev-parse", "--show-toplevel") or cwd


def cache_path(root: str) -> Path:
    cache_home = Path(os.environ.get("XDG_CACHE_HOME", Path.home() / ".cache"))
    digest = hashlib.sha256(root.encode("utf-8")).hexdigest()[:24]
    return cache_home / "agent-git-freshness" / f"{digest}.json"


def should_fetch(root: str) -> bool:
    if os.environ.get("AGENT_GIT_FRESHNESS_ALWAYS_FETCH") == "1":
        return True
    stamp = cache_path(root)
    try:
        data = json.loads(stamp.read_text(encoding="utf-8"))
    except Exception:
        return True
    return time.time() - float(data.get("fetched_at", 0)) >= FETCH_MIN_INTERVAL_SECONDS


def mark_fetched(root: str) -> None:
    stamp = cache_path(root)
    stamp.parent.mkdir(parents=True, exist_ok=True)
    stamp.write_text(
        json.dumps({"root": root, "fetched_at": time.time()}), encoding="utf-8"
    )


def fetch_remotes(root: str) -> str:
    if not should_fetch(root):
        return "skipped; refreshed less than 60 seconds ago"

    result = run_git(root, "fetch", "--all", "--prune", timeout=FETCH_TIMEOUT_SECONDS)
    if result.returncode == 0:
        mark_fetched(root)
        return "ran git fetch --all --prune"

    detail = (result.stderr or result.stdout).strip().splitlines()
    suffix = f": {detail[-1]}" if detail else ""
    return f"fetch failed{suffix}"


def resolve_base_ref(root: str) -> str | None:
    configured = [
        item.strip()
        for item in os.environ.get("AGENT_GIT_FRESHNESS_BASE_REFS", "").split(",")
        if item.strip()
    ]
    for ref in [*configured, *BASE_REF_CANDIDATES]:
        if git_stdout(root, "rev-parse", "--verify", "--quiet", f"{ref}^{{commit}}"):
            return ref
    return None


def current_branch(root: str) -> str | None:
    branch = git_stdout(root, "branch", "--show-current")
    return branch or None


def is_clean(root: str) -> bool:
    return git_stdout(root, "status", "--porcelain") == ""


def short_sha(root: str, ref: str = "HEAD") -> str:
    return git_stdout(root, "rev-parse", "--short", ref) or "unknown"


def fast_forward_base_branch(
    root: str, base_ref: str, branch: str | None, clean: bool
) -> str:
    base_branch = base_ref.removeprefix("origin/")
    if branch != base_branch:
        return "skipped; current checkout is not the integration branch"
    if not clean:
        return "skipped; working tree has local changes"

    before = short_sha(root)
    result = run_git(root, "merge", "--ff-only", base_ref, timeout=20)
    after = short_sha(root)
    if result.returncode == 0:
        if before == after:
            return f"already up to date with {base_ref}"
        return f"fast-forwarded {branch} from {before} to {after}"

    detail = (result.stderr or result.stdout).strip().splitlines()
    suffix = f": {detail[-1]}" if detail else ""
    return f"ff-only update failed{suffix}"


def ref_contains(root: str, ancestor: str, descendant: str) -> bool:
    result = run_git(root, "merge-base", "--is-ancestor", ancestor, descendant)
    return result.returncode == 0


def relation_to_base(root: str, base_ref: str) -> tuple[str, bool]:
    if ref_contains(root, base_ref, "HEAD"):
        return "contains latest integration ref", True
    if ref_contains(root, "HEAD", base_ref):
        return "behind latest integration ref", False
    return "does not contain latest integration ref", False


def build_context(root: str, event: str) -> tuple[str | None, bool]:
    fetch_status = fetch_remotes(root)
    base_ref = resolve_base_ref(root)
    branch = current_branch(root)
    clean = is_clean(root)

    if not base_ref:
        context = (
            "Git freshness check:\n"
            f"- Worktree: {root}\n"
            f"- Fetch: {fetch_status}\n"
            "- No origin/develop, origin/main, or origin/master ref was found.\n"
            "- Do not assume the checkout is based on a current integration branch."
        )
        return context, True

    pull_status = fast_forward_base_branch(root, base_ref, branch, clean)
    relation, is_fresh = relation_to_base(root, base_ref)
    branch_label = branch or "detached HEAD"

    context = (
        "Git freshness check:\n"
        f"- Worktree: {root}\n"
        f"- Fetch: {fetch_status}\n"
        f"- Safe fast-forward: {pull_status}\n"
        f"- Integration ref: {base_ref} @ {short_sha(root, base_ref)}\n"
        f"- Current checkout: {branch_label} @ {short_sha(root)}; {relation}\n"
        "- Before editing code that should target the current integration branch, "
        f"branch, merge, or rebase from {base_ref}. Do not rely on a stale local branch."
    )
    return context, is_fresh


def mutating_tool(input_data: dict[str, Any]) -> bool:
    tool_name = str(input_data.get("tool_name") or input_data.get("tool") or "")
    if tool_name in EDIT_TOOL_NAMES:
        return True

    tool_input = input_data.get("tool_input") or {}
    command = ""
    if isinstance(tool_input, dict):
        command = str(tool_input.get("command") or tool_input.get("cmd") or "")
    return bool(command and MUTATING_SHELL_RE.search(command))


def context_payload(event: str, context: str) -> dict[str, Any]:
    return {
        "hookSpecificOutput": {
            "hookEventName": event,
            "additionalContext": context,
        }
    }


def block_payload(reason: str) -> dict[str, str]:
    return {"decision": "block", "reason": reason}


def main() -> int:
    try:
        input_data = read_input()
    except Exception:
        return 0

    cwd = str(input_data.get("cwd") or os.getcwd())
    event = str(input_data.get("hook_event_name") or "")
    if not event and len(sys.argv) > 1:
        event = sys.argv[1]
    if not event:
        event = "UserPromptSubmit"

    try:
        if not inside_worktree(cwd):
            return 0

        root = worktree_root(cwd)
        context, is_fresh = build_context(root, event)

        if event == "PreToolUse":
            if not is_fresh and mutating_tool(input_data):
                print(
                    json.dumps(
                        block_payload(
                            f"{context}\n\nBlocked this mutating action because the checkout "
                            "does not contain the latest integration ref."
                        )
                    )
                )
            return 0

        if context:
            print(json.dumps(context_payload(event, context)))
    except Exception as exc:
        if event in {"SessionStart", "UserPromptSubmit"}:
            print(
                json.dumps(
                    context_payload(
                        event,
                        f"Git freshness hook failed: {exc}. Do not assume the checkout is current.",
                    )
                )
            )

    return 0


if __name__ == "__main__":
    sys.exit(main())
