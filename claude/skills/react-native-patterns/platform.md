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
