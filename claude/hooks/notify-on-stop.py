#!/usr/bin/env python3
"""Notify when Claude task completes."""

import json
import sys

from notify_utils import get_project_name, send_notification


def main():
    try:
        json.load(sys.stdin)  # Consume stdin, content not needed
    except Exception:
        return 0

    try:
        title = f"CC - {get_project_name()}"
        send_notification(title, "Task completed", sound="Purr")
    except Exception:
        pass

    return 0


if __name__ == "__main__":
    sys.exit(main())
