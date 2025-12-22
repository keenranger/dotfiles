# Authentication Patterns

## AWS Amplify / Cognito

### Email Extraction
Prefer `fetchAuthSession` over `fetchUserAttributes`:
- More reliable
- Doesn't require additional OAuth scopes

### OAuth Scopes
When using OAuth:
- Ensure profile scope is included if fetching user attributes
- Check scope configuration when auth fails silently

### Identity Pool
- Keep Identity Pool ID updated
- Separate IDs for different environments (test, prod)

### UserPoolClient
- Client ID changes require app updates
- Verify correct Client ID in configuration

## WebView Authentication

### Cookie-Based Auth
For WebView integration:
- Security controls required
- Handle cookie expiration
- Cross-domain considerations

### OAuth Callback URLs
- Register all callback URLs (app-test, production)
- Handle deep linking properly

## Google Sign-In

### Android Tablet Issue
Google Sign-In may fail silently on Android tablets:
- Specific handling needed
- Test on tablet form factors

## General Patterns

### Silent Failures
Auth failures often fail silently:
- Add explicit error logging
- Surface errors to user when appropriate
- Check OAuth configuration first
