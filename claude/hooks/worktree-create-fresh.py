#!/usr/bin/env python3
"""WorktreeCreate hook: base new Claude worktrees on the latest remote.

Claude's built-in "fresh" mode reuses the last-fetched origin/<default> ref
without fetching, so a new worktree can start from a stale commit. This hook
replaces worktree creation: it fetches, then branches from the freshest
integration branch (origin/develop -> origin/<default> -> origin/main), while
reproducing Claude's own path and branch naming so the result is an ordinary
managed worktree under .claude/worktrees/. Any failure falls back to HEAD, so
worktree creation can degrade to today's behaviour but never break.

Respects the `worktree.baseRef` setting: `head` keeps local HEAD as the base.
"""

import json
import os
import subprocess
import sys

FETCH_TIMEOUT = int(os.environ.get("CLAUDE_WORKTREE_FETCH_TIMEOUT", "15"))
GIT_TIMEOUT = 30


def git(root, args, timeout=GIT_TIMEOUT):
    env = dict(os.environ, GIT_TERMINAL_PROMPT="0")
    return subprocess.run(
        ["git", "-C", root, *args],
        capture_output=True,
        text=True,
        timeout=timeout,
        env=env,
    )


def git_out(root, args, timeout=GIT_TIMEOUT):
    try:
        result = git(root, args, timeout=timeout)
        if result.returncode == 0:
            return result.stdout.strip()
    except Exception:
        pass
    return ""


def git_ok(root, args, timeout=GIT_TIMEOUT):
    try:
        return git(root, args, timeout=timeout).returncode == 0
    except Exception:
        return False


def ref_exists(root, ref):
    try:
        return git(root, ["rev-parse", "--verify", "--quiet", f"{ref}^{{commit}}"]).returncode == 0
    except Exception:
        return False


def claude_branch(root, name):
    """Mirror Claude's worktree branch naming (Hbl in 2.1.195): reuse an existing
    branch of the same name, keep a name containing '/' as-is, else prefix
    'claude/'."""
    n = name[2:] if name.startswith("./") else name
    if "/" in n or git_ok(root, ["show-ref", "--verify", "--quiet", f"refs/heads/{n}"]):
        return n
    return f"claude/{n}"


def registered_worktree(root, wt_dir):
    target = os.path.abspath(wt_dir)
    for line in git_out(root, ["worktree", "list", "--porcelain"]).splitlines():
        if line.startswith("worktree ") and os.path.abspath(line[len("worktree "):]) == target:
            return True
    return False


def emit(path):
    # The WorktreeCreate hook contract wants a bare absolute path on stdout
    # (not a JSON hookSpecificOutput wrapper).
    print(os.path.abspath(path))


def base_ref_mode(root):
    """Best-effort read of worktree.baseRef ('fresh' default, or 'head').

    Mirrors the harness precedence (project-local > project > user); best-effort
    by design and does not resolve managed/enterprise settings.
    """
    candidates = [
        os.path.join(root, ".claude", "settings.local.json"),
        os.path.join(root, ".claude", "settings.json"),
        os.path.expanduser("~/.claude/settings.json"),
    ]
    for path in candidates:
        try:
            with open(path) as handle:
                worktree = json.load(handle).get("worktree")
            if isinstance(worktree, dict) and "baseRef" in worktree:
                return worktree["baseRef"]
        except Exception:
            continue
    return "fresh"


def pick_base(root):
    if base_ref_mode(root) == "head":
        return "HEAD"

    try:
        git(root, ["fetch", "origin"], timeout=FETCH_TIMEOUT)
    except Exception:
        pass  # offline or slow: fall through to whatever refs we already have

    default = ""
    sym = git_out(root, ["symbolic-ref", "--quiet", "--short", "refs/remotes/origin/HEAD"])
    if sym.startswith("origin/"):
        default = sym[len("origin/"):]

    for candidate in ["develop", default, "main", "master"]:
        if candidate and ref_exists(root, f"origin/{candidate}"):
            return f"origin/{candidate}"

    return "HEAD"


def resolve_root(start):
    common = git_out(start, ["rev-parse", "--path-format=absolute", "--git-common-dir"])
    if common:
        return os.path.dirname(common)
    return git_out(start, ["rev-parse", "--show-toplevel"])


def main():
    try:
        hook_input = json.load(sys.stdin)
    except Exception:
        return 0

    name = str(hook_input.get("name", "")).strip()
    if not name:
        return 0

    start = hook_input.get("cwd") or os.getcwd()
    root = resolve_root(start)
    if not root or not os.path.isdir(root):
        return 0

    # Mirrors Claude's internal worktree layout (verified against 2.1.195): dir
    # <root>/.claude/worktrees/<name with "/"->"+">, branch via claude_branch().
    # If Claude changes these conventions, `git worktree add` still succeeds at the
    # old path/branch (the HEAD fallback below won't catch it), so keep in sync.
    wt_dir = os.path.join(root, ".claude", "worktrees", name.replace("/", "+"))
    branch = claude_branch(root, name)

    if registered_worktree(root, wt_dir):
        emit(wt_dir)
        return 0

    try:
        os.makedirs(os.path.dirname(wt_dir), exist_ok=True)
    except Exception:
        pass

    base = pick_base(root)
    add = ["worktree", "add", "--no-track", "-B", branch, wt_dir]
    # Try the fresh base; on failure fall back to HEAD (add with no start-point)
    # so worktree creation degrades to today's behaviour rather than breaking.
    if git_ok(root, add + [base]) or (base != "HEAD" and git_ok(root, add)):
        emit(wt_dir)
        return 0

    # If a race or partial run already registered it, still hand back the path.
    if registered_worktree(root, wt_dir):
        emit(wt_dir)

    return 0


if __name__ == "__main__":
    sys.exit(main())
