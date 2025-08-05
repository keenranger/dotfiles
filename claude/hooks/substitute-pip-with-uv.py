#!/usr/bin/env python3

import os
import sys
import json
import re

def main():
    # Read JSON input from stdin
    try:
        hook_input = json.load(sys.stdin)
    except:
        return 0
    
    # Debug output to stderr
    print("[DEBUG] Hook substitute-pip-with-uv.py triggered", file=sys.stderr)
    print(f"[DEBUG] hook_event_name: {hook_input.get('hook_event_name')}", file=sys.stderr)
    print(f"[DEBUG] tool_name: {hook_input.get('tool_name')}", file=sys.stderr)
    
    # Check if this is a Bash tool call
    if hook_input.get('tool_name') != 'Bash':
        return 0
    
    try:
        # Get the tool input from hook data
        tool_input = hook_input.get('tool_input', {})
        command = tool_input.get('command', '')
        
        print(f"[DEBUG] Original command: {command}", file=sys.stderr)
        
        # Check if command already contains "uv pip" to avoid recursion
        if 'uv pip' in command:
            print("[DEBUG] Command already contains 'uv pip', allowing", file=sys.stderr)
            return 0
        
        # Check if the command contains pip or pip3 as a command
        # Match pip/pip3 as a command (at start or after common separators)
        pip_pattern = r'(?:^|[;&|]|\s+)(?:python\s+-m\s+)?(pip3?)(?:\s|$)'
        
        if re.search(pip_pattern, command):
            print("[DEBUG] pip/pip3 command detected", file=sys.stderr)
            
            # Substitute pip/pip3 with uv pip
            def replace_pip(match):
                prefix = match.group(0).split('pip')[0]
                suffix = match.group(0).split('pip')[-1].lstrip('3')
                return prefix + 'uv pip' + suffix
            
            modified_command = re.sub(pip_pattern, replace_pip, command)
            
            print(f"[DEBUG] Suggested command: {modified_command}", file=sys.stderr)
            
            # Block the command and suggest using uv pip
            response = {
                "decision": "block",
                "reason": f"Please use 'uv pip' instead of 'pip' or 'pip3' as per user preference.\nSuggested command: {modified_command}"
            }
            print(json.dumps(response))
            return 0
    
    except Exception as e:
        print(f"[DEBUG] Error in hook: {e}", file=sys.stderr)
    
    return 0

if __name__ == "__main__":
    sys.exit(main())