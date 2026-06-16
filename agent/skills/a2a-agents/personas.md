# Persona Design

## What is a Persona

A persona defines how an AI agent communicates:
- Voice and tone
- Knowledge domain
- Response style
- Personality traits

## Persona Examples

| Persona | Context | Style |
|---------|---------|-------|
| Aurora | General assistant | Professional, helpful |
| Posay | Skincare focus | Caring, expert |

## Persona Implementation

### Template Builder Pattern
Instead of duplicating prompts, use template builders:
- Base template with common structure
- Persona-specific variables
- Dynamic insertion of persona traits

### Chat History
Personas should maintain context:
- Include chat_history for memory
- Respect conversation flow
- Reference previous interactions naturally

### Quick Replies
Suggest contextual quick replies:
- Relevant follow-up actions
- Use `insert(0, ...)` to prioritize key options
- Keep options concise and actionable
