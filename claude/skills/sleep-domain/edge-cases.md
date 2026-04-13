# Sleep Data Edge Cases

## Peculiarities

### TOO_MANY_DEFECTS_IN_SLEEP_STAGES
- Indicates unreliable stage classification
- May need special UI handling
- Consider whether to show partial data or error state

### Short Sessions
- Sessions under minimum duration may lack reliable metrics
- Handle gracefully in UI and calculations

### Missing Data Segments
- Gaps in audio recording
- Interrupted sessions
- Display interpolated or indicate missing

## Upload Error Handling (SDK 3.2.0+)

### uploadTrackingTerminated / ERR_UPLOAD_TRACKING_TERMINATED (23499)
- Unified error replacing 6 individual upload 4xx error codes
- Deprecated codes: uploadBadRequest, uploadUnauthorized, uploadForbidden, uploadNotFound, uploadTooLarge, uploadUnprocessable
- Common triggers: concurrent tracking on another device (same user_id), session exceeding 24 hours
- SDK automatically stops recording, releases resources, and closes session -- do NOT call stopTracking() manually
- uploadFailed and uploadServerError remain unchanged

## Platform-Specific Issues

### iOS
- Audio session conflicts with alarms
- System alarm + app alarm simultaneous trigger
- Background recording limitations

### Android
- Doze mode affects tracking
- App termination during sleep
- State persistence challenges

## Common Bugs

### Audio Session Conflicts
Multiple audio sources competing:
- Sleep tracking microphone
- Alarm sounds
- Media playback
- System notifications

### Session State
- Tracking state not persisting across app restart
- Multiple sessions started unintentionally
- Rapid button clicks causing duplicate actions
