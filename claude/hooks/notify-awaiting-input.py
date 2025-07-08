#!/usr/bin/env python3

import os
import sys
import json
import subprocess
from datetime import datetime

def main():
    # Check if this is a Notification event
    if os.environ.get('CLAUDE_HOOK_EVENT') != 'Notification':
        return 0
    
    try:
        # Parse the tool input JSON
        tool_input = json.loads(os.environ.get('CLAUDE_TOOL_INPUT', '{}'))
        notification_type = tool_input.get('type', '')
        message = tool_input.get('message', '')
        
        # Log ALL notifications for debugging
        log_path = os.path.expanduser('~/.claude/hooks-debug.log')
        with open(log_path, 'a') as f:
            timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
            f.write(f"[{timestamp}] Notification received - Type: '{notification_type}', Message: '{message}', Full input: {tool_input}\n")
        
        # Check if Claude is waiting for input or permission
        if (notification_type == 'awaiting_input' or 
            'waiting' in message.lower() or 
            'permission' in message.lower() or
            'input' in message.lower()):
            
            # macOS notification using terminal-notifier
            if sys.platform == 'darwin':
                try:
                    # Check if terminal-notifier is installed
                    result = subprocess.run(['which', 'terminal-notifier'], capture_output=True)
                    if result.returncode == 0:
                        # Use terminal-notifier
                        subprocess.run([
                            'terminal-notifier',
                            '-title', 'Claude Code',
                            '-message', 'Claude Code is awaiting your input',
                            '-sound', 'Glass',
                            '-group', 'claude-code-hooks'
                        ], check=False)
                        print(f"[DEBUG] Notification sent via terminal-notifier", file=sys.stderr)
                    else:
                        # Fallback to osascript
                        subprocess.run([
                            'osascript', '-e',
                            'display notification "Claude Code is awaiting your input" with title "Claude Code" sound name "Glass"'
                        ], check=False)
                        print(f"[DEBUG] Notification sent via osascript (terminal-notifier not found)", file=sys.stderr)
                except Exception as e:
                    print(f"[DEBUG] Failed to send notification: {e}", file=sys.stderr)
            
            # Linux notification (requires notify-send)
            elif sys.platform.startswith('linux'):
                try:
                    subprocess.run([
                        'notify-send', 'Claude Code', 
                        'Claude Code is awaiting your input',
                        '--urgency=normal'
                    ], check=False)
                except:
                    pass
            
            # Terminal bell
            print('\a', end='', flush=True)
            
            # Log the notification
            log_path = os.path.expanduser('~/.claude/hooks.log')
            with open(log_path, 'a') as f:
                timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
                f.write(f"[{timestamp}] Claude Code awaiting input: {message}\n")
    
    except Exception as e:
        print(f"[DEBUG] Error in notification hook: {e}", file=sys.stderr)
    
    return 0

if __name__ == "__main__":
    sys.exit(main())