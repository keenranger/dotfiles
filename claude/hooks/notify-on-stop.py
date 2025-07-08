#!/usr/bin/env python3

import os
import sys
import subprocess
import json

def main():
    # Read JSON input from stdin
    try:
        hook_input = json.load(sys.stdin)
    except:
        return 0
    
    # Check if this is a Stop event
    if hook_input.get('hook_event_name') != 'Stop':
        return 0
    
    try:
        # Get context for notification
        cwd = os.getcwd()
        project_name = os.path.basename(cwd)
        
        # macOS notification using terminal-notifier
        if sys.platform == 'darwin':
            try:
                # Check if terminal-notifier is installed
                result = subprocess.run(['which', 'terminal-notifier'], capture_output=True)
                if result.returncode == 0:
                    # Use terminal-notifier
                    subprocess.run([
                        'terminal-notifier',
                        '-title', f'CC - {project_name}',
                        '-message', 'Task completed',
                        '-sound', 'Purr',
                        '-group', 'claude-code-hooks'
                    ], check=False)
                else:
                    # Fallback to osascript
                    subprocess.run([
                        'osascript', '-e',
                        f'display notification "Task completed" with title "CC - {project_name}" sound name "Purr"'
                    ], check=False)
            except:
                pass
        
        # Linux notification (requires notify-send)
        elif sys.platform.startswith('linux'):
            try:
                subprocess.run([
                    'notify-send', 
                    f'CC - {project_name}', 
                    'Task completed',
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