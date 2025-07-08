#!/usr/bin/env python3

import os
import sys
import json
import subprocess

def main():
    # Check if this is a Notification event
    if os.environ.get('CLAUDE_HOOK_EVENT') != 'Notification':
        return 0
    
    try:
        # Parse the tool input JSON
        tool_input = json.loads(os.environ.get('CLAUDE_TOOL_INPUT', '{}'))
        notification_type = tool_input.get('type', '')
        message = tool_input.get('message', '')
        
        # Get context for notification
        cwd = os.getcwd()
        project_name = os.path.basename(cwd)
        
        
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
                        # Use terminal-notifier with context
                        subprocess.run([
                            'terminal-notifier',
                            '-title', f'CC - {project_name}',
                            '-message', 'Awaiting your input',
                            '-sound', 'Glass',
                            '-group', 'claude-code-hooks'
                        ], check=False)
                    else:
                        # Fallback to osascript
                        subprocess.run([
                            'osascript', '-e',
                            f'display notification "Awaiting your input" with title "CC - {project_name}" sound name "Glass"'
                        ], check=False)
                except:
                    pass
            
            # Linux notification (requires notify-send)
            elif sys.platform.startswith('linux'):
                try:
                    subprocess.run([
                        'notify-send', 
                        f'CC - {project_name}', 
                        'Awaiting your input',
                        '--urgency=normal'
                    ], check=False)
                except:
                    pass
            
            # Terminal bell
            print('\a', end='', flush=True)
            
    
    except:
        pass
    
    return 0

if __name__ == "__main__":
    sys.exit(main())