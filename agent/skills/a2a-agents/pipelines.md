# Insight Pipelines

## Stage Insight Pipeline

Generates personalized sleep insights from sleep data.

### V2 Structure
5-category structure:
- Distinct insight categories
- Supports widget transformation
- AI summary generation

### Pipeline Flow
1. Receive sleep session data
2. Extract relevant metrics
3. Apply insight generation logic
4. Transform to widget format (if needed)
5. Return structured response

### Prompt Templates
Use template builders instead of hardcoded prompts:
- Reduces duplication
- Easier maintenance
- Consistent structure across categories

## Wakeup Pipeline

Generates morning messages with context.

### Components
- Timezone information
- Previous night's sleep data
- User preferences
- Persona-appropriate messaging

### Message Generation
- Include relevant sleep summary
- Personalized recommendations
- Quick reply options

## Event Handling

### Event Types
- Direct messages
- Mentions
- Scheduled triggers (cron)

### Event Payload
Support event payload for extensibility:
- Type identification
- Context data
- Future feature hooks
