# Messaging Platform Integrations

## Slack Integration

### Features
- Direct message handling
- Mention responses
- Home tab customization
- Daily cron workflows

### OAuth Distribution
For distributing bot to workspaces:
- Implement OAuth flow
- Handle token storage
- Scope management

### User Tagging
When mentioning users:
- Use proper Slack user ID format
- Style appropriately for Slack rendering

### Slack Home
- Can be Korean or English based on audience
- Update dynamically based on user context

## Kakao Integration

### Architecture
- Lambda-based handlers
- SAM deployment
- Integrated deploy with Slack

### Event Handling
- DM events
- Scope-aware responses

## Cross-Platform Patterns

### Unified Chatbot Structure
```
chatbot/
├── bot.py          # Core bot logic
├── cron.py         # Scheduled tasks
├── persona.py      # Persona definitions
└── integrations/
    ├── slack/
    └── kakao/
```

### Deployment
- SAM for Lambda deployment
- Separate configs per platform
- Shared agent-a dependency
