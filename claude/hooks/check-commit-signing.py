#!/usr/bin/env python3
"""Enforce GPG signing on git commits."""

import json
import sys


def main():
    try:
        hook_input = json.load(sys.stdin)
    except Exception:
        return 0

    try:
        tool_input = hook_input.get("tool_input", {})
        command = tool_input.get("command", "")

        if "git commit" in command:
            if "-S" not in command and "--gpg-sign" not in command:
                response = {
                    "decision": "block",
                    "reason": 'Git commits must be signed. Add -S flag.\nExample: git commit -S -m "message"',
                }
                print(json.dumps(response))
    except Exception:
        pass

    return 0


if __name__ == "__main__":
    sys.exit(main())
