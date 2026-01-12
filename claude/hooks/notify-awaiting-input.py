#!/usr/bin/env python3
"""Notify when Claude is awaiting user input."""

import json
import sys

from notify_utils import get_project_name, send_notification


def main():
    try:
        hook_input = json.load(sys.stdin)
    except Exception:
        return 0

    try:
        message = hook_input.get("message", "")

        if any(
            keyword in message.lower()
            for keyword in ("waiting", "permission", "input", "awaiting")
        ):
            title = f"CC - {get_project_name()}"
            send_notification(title, "Awaiting your input", sound="Glass")
    except Exception:
        pass

    return 0


if __name__ == "__main__":
    sys.exit(main())
