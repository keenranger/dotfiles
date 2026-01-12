#!/usr/bin/env python3
"""Enforce uv pip over pip/pip3."""

import json
import re
import sys


def main():
    try:
        hook_input = json.load(sys.stdin)
    except Exception:
        return 0

    try:
        tool_input = hook_input.get("tool_input", {})
        command = tool_input.get("command", "")

        # Already using uv pip
        if "uv pip" in command:
            return 0

        # Match pip/pip3 as command
        pip_pattern = r"(?:^|[;&|]|\s+)(?:python\s+-m\s+)?(pip3?)(?:\s|$)"

        if re.search(pip_pattern, command):

            def replace_pip(match):
                prefix = match.group(0).split("pip")[0]
                suffix = match.group(0).split("pip")[-1].lstrip("3")
                return prefix + "uv pip" + suffix

            modified_command = re.sub(pip_pattern, replace_pip, command)

            response = {
                "decision": "block",
                "reason": f"Use 'uv pip' instead of 'pip'.\nSuggested: {modified_command}",
            }
            print(json.dumps(response))
    except Exception:
        pass

    return 0


if __name__ == "__main__":
    sys.exit(main())
