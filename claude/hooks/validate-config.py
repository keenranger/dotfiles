#!/usr/bin/env python3
"""Validate JSON and YAML config files before git commit."""

import json
import os
import subprocess
import sys
from pathlib import Path


def get_staged_files():
    """Get list of staged files."""
    result = subprocess.run(
        ["git", "diff", "--cached", "--name-only"],
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        return []
    return [f.strip() for f in result.stdout.strip().split("\n") if f.strip()]


def validate_json(filepath):
    """Validate JSON file. Returns (success, error_message)."""
    try:
        with open(filepath, encoding="utf-8") as f:
            json.load(f)
        return True, None
    except json.JSONDecodeError as e:
        return False, f"JSON error at line {e.lineno}: {e.msg}"
    except Exception as e:
        return False, str(e)


def validate_yaml(filepath):
    """Validate YAML file. Returns (success, error_message)."""
    try:
        import yaml

        with open(filepath, encoding="utf-8") as f:
            yaml.safe_load(f)
        return True, None
    except ImportError:
        return True, None  # Skip if pyyaml not available
    except yaml.YAMLError as e:
        return False, str(e)
    except Exception as e:
        return False, str(e)


def main():
    try:
        hook_input = json.load(sys.stdin)
    except Exception:
        return 0

    try:
        tool_input = hook_input.get("tool_input", {})
        command = tool_input.get("command", "")

        if "git commit" not in command:
            return 0

        staged_files = get_staged_files()
        errors = []

        for filepath in staged_files:
            if not Path(filepath).exists():
                continue

            if filepath.endswith(".json"):
                success, error = validate_json(filepath)
                if not success:
                    errors.append(f"{filepath}: {error}")

            elif filepath.endswith((".yaml", ".yml")):
                success, error = validate_yaml(filepath)
                if not success:
                    errors.append(f"{filepath}: {error}")

        if errors:
            cwd = os.getcwd()
            response = {
                "decision": "block",
                "reason": f"Config validation failed in {cwd}:\n" + "\n".join(errors),
            }
            print(json.dumps(response))

    except Exception:
        pass

    return 0


if __name__ == "__main__":
    sys.exit(main())
