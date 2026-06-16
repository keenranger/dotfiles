# Platform-Specific Patterns

## iOS

### Audio Sessions
- Conflicts between recording and playback
- System alarms interrupt audio sessions
- Background audio permissions required

### HealthKit
- Requires explicit permissions
- Data conversion to app format needed
- Privacy-sensitive API

### Widgets
- Excessive disk writes can cause termination (17GB issue)
- Monitor widget storage usage
- Implement cleanup strategies

### Memory
- Memory leaks cause crashes after extended use
- Profile memory in long-running features (tracking ~6hrs)

## Android

### Doze Mode
- Affects background tracking
- State may not persist
- Test with doze mode enabled

### App Termination
- System may kill app during sleep
- State restoration needed
- Persistent storage for critical state

### Form Factors
- Test on tablets (auth issues)
- Different screen sizes affect UI

## Cross-Platform

### AppState lifecycle
`AppState.addEventListener("change", ...)` does NOT fire an initial `"active"` event when the listener mounts -- it only fires on actual transitions. Any foreground-tied behavior (analytics sessions, refresh-on-foreground, sync triggers) must be manually invoked once at registration time, or it will be skipped on every cold start.

```ts
AppState.addEventListener("change", (s) => {
  if (s === "active") this.onForeground();
  else if (s === "background") this.onBackground();
});
this.onForeground(); // seed: AppState doesn't fire initial "active"
```

Make `onForeground`/`onBackground` handlers idempotent: a duplicate active or background event must be a no-op (compare to last-known state, or guard on the resource being managed).

### Environment Variables
Use `import.meta.env` for Vite compatibility, not `process.env`.

### Feature Detection
Platform-specific code paths:
```typescript
Platform.OS === 'ios' ? iosImpl() : androidImpl()
```

### Testing Matrix
- iOS Phone
- iOS Tablet
- Android Phone
- Android Tablet
- Different OS versions
