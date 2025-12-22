# Navigation Patterns

## Common Issues

### Stack Accumulation
Repeated navigation can accumulate stack:
- Repeated tracking sessions
- Back button behavior unexpected
- Memory grows with stack size

Fix: Reset stack or replace instead of push.

### Rapid Button Clicks
Multiple `router.push` calls from rapid clicks:
- Causes duplicate screens
- Race conditions in navigation

Fix: Debounce or disable button after first press.

### Router Methods

| Method | When to Use |
|--------|-------------|
| `push` | Add to stack, can go back |
| `replace` | Replace current, no back |
| `reset` | Clear stack, fresh start |

## Best Practices

### Preventing Double Navigation
```typescript
const [isNavigating, setIsNavigating] = useState(false);

const handlePress = () => {
  if (isNavigating) return;
  setIsNavigating(true);
  router.push('/destination');
};
```

### Deep Linking
- Handle OAuth callbacks
- App scheme registration
- Universal links (iOS) / App Links (Android)
