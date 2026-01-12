#!/usr/bin/env python3
"""Shared notification utilities for Claude Code hooks."""

import os
import subprocess
import sys


def send_notification(title: str, message: str, sound: str = "Glass") -> None:
    """Send a cross-platform desktop notification with terminal bell."""
    if sys.platform == "darwin":
        _notify_macos(title, message, sound)
    elif sys.platform.startswith("linux"):
        _notify_linux(title, message)

    # Terminal bell
    print("\a", end="", flush=True)


def _notify_macos(title: str, message: str, sound: str) -> None:
    """Send notification on macOS using terminal-notifier or osascript fallback."""
    try:
        result = subprocess.run(["which", "terminal-notifier"], capture_output=True)
        if result.returncode == 0:
            subprocess.run(
                [
                    "terminal-notifier",
                    "-title", title,
                    "-message", message,
                    "-sound", sound,
                    "-group", "claude-code-hooks",
                ],
                check=False,
            )
        else:
            subprocess.run(
                [
                    "osascript", "-e",
                    f'display notification "{message}" with title "{title}" sound name "{sound}"',
                ],
                check=False,
            )
    except Exception:
        pass


def _notify_linux(title: str, message: str) -> None:
    """Send notification on Linux using notify-send."""
    try:
        subprocess.run(
            ["notify-send", title, message, "--urgency=normal"],
            check=False,
        )
    except Exception:
        pass


def get_project_name() -> str:
    """Get project name from current working directory."""
    return os.path.basename(os.getcwd())
