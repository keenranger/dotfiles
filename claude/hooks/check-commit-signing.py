#!/usr/bin/env python3

import os
import sys
import json

def main():
    # Debug output to stderr
    print("[DEBUG] Hook check-commit-signing.py triggered", file=sys.stderr)
    print(f"[DEBUG] CLAUDE_TOOL_NAME: {os.environ.get('CLAUDE_TOOL_NAME', 'NOT SET')}", file=sys.stderr)
    print(f"[DEBUG] CLAUDE_TOOL_INPUT: {os.environ.get('CLAUDE_TOOL_INPUT', 'NOT SET')}", file=sys.stderr)
    
    # Check if this is a Bash tool call
    if os.environ.get('CLAUDE_TOOL_NAME') != 'Bash':
        return 0
    
    try:
        # Parse the tool input JSON
        tool_input = json.loads(os.environ.get('CLAUDE_TOOL_INPUT', '{}'))
        command = tool_input.get('command', '')
        
        print(f"[DEBUG] Extracted command: {command}", file=sys.stderr)
        
        # Check if the command contains git commit
        if 'git commit' in command:
            print("[DEBUG] Git commit detected", file=sys.stderr)
            
            # Check if the command includes signing flags
            if '-S' not in command and '--gpg-sign' not in command:
                # Block the commit using JSON output
                response = {
                    "decision": "block",
                    "reason": "Git commits must be signed. Please add -S flag to your git commit command.\nExample: git commit -S -m \"Your commit message\""
                }
                print(json.dumps(response))
                return 0  # Exit 0 for JSON output
    
    except Exception as e:
        print(f"[DEBUG] Error in hook: {e}", file=sys.stderr)
    
    return 0

if __name__ == "__main__":
    sys.exit(main())