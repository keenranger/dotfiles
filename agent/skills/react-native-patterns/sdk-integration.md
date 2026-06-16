# SDK Integration Patterns

## Asleep SDK

### Common Issues

#### PromiseAlreadySettledException
In `AsleepModule.onFail`:
- Promise resolved multiple times
- Check callback handling

#### Session State
- Tracking state persistence
- Handling app restart during session
- Multiple session starts

### Audio Handling
- Microphone permissions
- Background recording
- Audio session category configuration

## RevenueCat

### Race Conditions
Subscription state race conditions:
- User state not ready
- Multiple initialization calls
- Handle async initialization properly

### Best Practices
- Initialize early in app lifecycle
- Handle offline state
- Cache subscription status

## Firebase

### Web Modular SDK
Migrate to v22+ modular API:
- Tree-shakeable imports
- Better bundle size
- New API patterns

## General SDK Patterns

### Initialization
- Initialize in app root
- Handle failures gracefully
- Retry logic for network-dependent SDKs

### Version Updates
- Monitor for breaking changes
- Test SDK updates thoroughly
- Keep upgrade notes

### Native Module Errors
- Check native side logs (Xcode, Android Studio)
- Bridge errors may hide root cause
- Platform-specific debugging needed
