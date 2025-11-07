# Authentication Troubleshooting Guide

## Current Issues

1. **Apple Sign-In Error 1000** - This usually indicates:
   - Bundle ID mismatch between Xcode and Firebase
   - Sign in with Apple capability not enabled in Xcode
   - Missing URL scheme or configuration

2. **Google Sign-In Not Working** - Possible causes:
   - Google Sign-In not configured in Firebase Console
   - Client ID not properly set in app
   - URL scheme not configured correctly

3. **Game Center Not Working** - Possible causes:
   - Game Center capability not enabled
   - Game Center not enabled in Firebase Console
   - User not signed into Game Center on device

4. **Email Sign-Up/Sign-In Not Working** - Possible causes:
   - Email/Password provider not enabled in Firebase Console
   - Firebase configuration issue

## Verification Checklist

### ✅ Files to Check

1. **GoogleService-Info.plist**
   - Location: `Haven2.0/GoogleService-Info.plist`
   - Bundle ID: `com.jithaven.app` (should match Xcode project)
   - CLIENT_ID: `603837311377-5oibt7uancmodcgogrleoruhbd6ph6ce.apps.googleusercontent.com`
   - REVERSED_CLIENT_ID: `com.googleusercontent.apps.603837311377-5oibt7uancmodcgogrleoruhbd6ph6ce`

2. **Info.plist (URL Scheme)**
   - Location: `Haven2-0-Info.plist` or in Xcode project settings
   - URL Scheme: `com.googleusercontent.apps.603837311377-5oibt7uancmodcgogrleoruhbd6ph6ce`

3. **Xcode Project Settings**
   - Bundle Identifier: Should be `com.jithaven.app`
   - Sign in with Apple capability: Must be enabled
   - Game Center capability: Must be enabled (if using Game Center)

### ✅ Firebase Console Checklist

Go to Firebase Console → Authentication → Sign-in method:

- [ ] **Email/Password**: Enabled
- [ ] **Google**: Enabled (with correct client ID)
- [ ] **Apple**: Enabled
- [ ] **Game Center**: Enabled (if using)
- [ ] **Anonymous**: Enabled (for guest mode)

### ✅ Code Configuration

1. **Firebase Initialization** (`TimeFlowApp.swift`)
   - ✅ `FirebaseApp.configure()` is called
   - ✅ Google Sign-In is configured with CLIENT_ID from plist

2. **URL Handling** (`TimeFlowApp.swift`)
   - ✅ `.onOpenURL` handles Google Sign-In callbacks

3. **Button Implementation**
   - ✅ Apple: Using `SignInWithAppleButton` (official)
   - ✅ Google: Using `GIDSignInButton` (official)
   - ✅ Game Center: Custom button (official style)

## Common Fixes

### Fix 1: Apple Sign-In Error 1000

**Cause**: Bundle ID mismatch or capability not enabled

**Solution**:
1. Verify Bundle ID in Xcode matches Firebase:
   - Xcode: Product → Target → General → Bundle Identifier
   - Should be: `com.jithaven.app`
   - Firebase: Project Settings → Your Apps → iOS app → Bundle ID

2. Enable Sign in with Apple capability:
   - Xcode → Target → Signing & Capabilities
   - Click "+ Capability"
   - Add "Sign in with Apple"

3. Verify in Firebase Console:
   - Authentication → Sign-in method → Apple → Enabled

### Fix 2: Google Sign-In Not Working

**Cause**: Client ID not configured or URL scheme missing

**Solution**:
1. Verify `GoogleService-Info.plist` is in the project:
   - Check it's included in the target
   - Verify CLIENT_ID is correct

2. Verify URL scheme in Xcode:
   - Target → Info → URL Types
   - Should have: `com.googleusercontent.apps.603837311377-5oibt7uancmodcgogrleoruhbd6ph6ce`

3. Verify Google Sign-In is configured:
   - Check console logs for "Google Sign-In configured with client ID"
   - Verify in Firebase Console that Google is enabled

### Fix 3: Email Sign-Up Not Working

**Cause**: Email/Password provider not enabled

**Solution**:
1. Firebase Console → Authentication → Sign-in method
2. Enable "Email/Password"
3. Save changes
4. Try again

## Debugging Steps

1. **Check Console Logs**:
   - Look for "FirebaseAuthService: Starting [method] Sign-In flow..."
   - Look for error messages
   - Check for configuration warnings

2. **Verify Firebase is Configured**:
   - Should see: "Firebase already configured" or "Firebase configured"
   - If not, check `GoogleService-Info.plist` is in the project

3. **Test Each Method**:
   - Start with Guest (works)
   - Then try Email (simplest)
   - Then Google (requires URL scheme)
   - Then Apple (requires capability)
   - Then Game Center (requires Game Center setup)

## Next Steps

1. Verify all capabilities are enabled in Xcode
2. Check Firebase Console settings
3. Test on a physical device (some features don't work on simulator)
4. Check console logs for specific error messages
5. Verify Bundle ID matches everywhere

