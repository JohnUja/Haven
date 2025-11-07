# Authentication Setup Guide

This guide explains how to set up Google Sign-In and Sign in with Apple for Haven 2.0.

## Overview

The app now supports:
- **Sign in with Apple** (native iOS - requires minimal setup)
- **Google Sign-In** (requires Google Cloud Console setup)

## Prerequisites

### 1. Sign in with Apple

Apple Sign-In is automatically available if:
- Your app has a valid App ID in Apple Developer Portal
- Sign in with Apple capability is enabled in Xcode

**Setup Steps:**
1. Open your project in Xcode
2. Select your target
3. Go to "Signing & Capabilities"
4. Click "+ Capability"
5. Add "Sign in with Apple"

### 2. Google Sign-In

**Setup Steps:**

#### Step 1: Create Google OAuth Credentials

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project (or select existing)
3. Enable Google+ API:
   - Go to "APIs & Services" > "Library"
   - Search for "Google Sign-In API"
   - Click "Enable"
4. Create OAuth 2.0 credentials:
   - Go to "APIs & Services" > "Credentials"
   - Click "Create Credentials" > "OAuth client ID"
   - Select "iOS" as application type
   - Enter your bundle ID (e.g., `com.haven2.timeflow`)
   - Download the configuration file

#### Step 2: Add Google Sign-In SDK

**Option A: Swift Package Manager (Recommended)**

1. In Xcode, go to File > Add Package Dependencies
2. Enter: `https://github.com/google/GoogleSignIn-iOS`
3. Select version 7.0.0 or latest
4. Add to your target

**Option B: CocoaPods**

Add to your `Podfile`:
```ruby
pod 'GoogleSignIn'
```

Then run:
```bash
pod install
```

#### Step 3: Configure Info.plist

Add your Google Client ID to `Info.plist`:

```xml
<key>GOOGLE_CLIENT_ID</key>
<string>YOUR_CLIENT_ID.apps.googleusercontent.com</string>
```

Or add it via Xcode:
1. Select `Info.plist` in Xcode
2. Right-click > "Add Row"
3. Key: `GOOGLE_CLIENT_ID`
4. Type: String
5. Value: Your Google Client ID

#### Step 4: Update URL Scheme

Add the reversed client ID as a URL scheme:

1. Select your target in Xcode
2. Go to "Info" tab
3. Expand "URL Types"
4. Click "+" to add new URL Type
5. Set "URL Schemes" to your reversed client ID (e.g., `com.googleusercontent.apps.YOUR_CLIENT_ID`)

Or add to `Info.plist`:
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>com.googleusercontent.apps.YOUR_CLIENT_ID</string>
        </array>
    </dict>
</array>
```

#### Step 5: Update AppDelegate (if using SceneDelegate)

If your app uses SceneDelegate, update `SceneDelegate.swift`:

```swift
import GoogleSignIn

func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    guard let url = URLContexts.first?.url else { return }
    GIDSignIn.sharedInstance.handle(url)
}
```

Or update `TimeFlowApp.swift`:

```swift
import SwiftUI
import GoogleSignIn

@main
struct TimeFlowApp: App {
    // ... existing code ...
    
    init() {
        // Configure Google Sign-In
        if let clientID = Bundle.main.object(forInfoDictionaryKey: "GOOGLE_CLIENT_ID") as? String {
            GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
    }
}
```

## App Flow Integration

The app now checks authentication status and shows the login screen if needed.

### Update TimeFlowApp.swift

```swift
@main
struct TimeFlowApp: App {
    @StateObject private var authService = AuthenticationService.shared
    // ... existing code ...
    
    var body: some Scene {
        WindowGroup {
            if authService.isAuthenticated {
                MainTabView()
                    .environment(themeManager)
                    .environmentObject(timeSettings)
                    .environmentObject(calendarManager)
            } else {
                AuthenticationView()
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
```

## Testing

### Apple Sign-In
- Works on simulator (iOS 13+)
- Works on device
- No additional configuration needed if capability is enabled

### Google Sign-In
- Requires device or simulator with Google account configured
- Test with a valid Google account
- Ensure Client ID is correctly configured in Info.plist

## Security Notes

1. **Never commit** your Google Client ID to version control
   - Use environment variables for CI/CD
   - Store in secure keychain for production

2. **Token Storage**
   - Apple Sign-In tokens are stored in Keychain
   - Google tokens are managed by GoogleSignIn SDK

3. **User Data**
   - User information is stored locally in SwiftData
   - No sensitive tokens are stored in User model

## Troubleshooting

### Google Sign-In Issues

**Error: "Google Client ID not configured"**
- Check Info.plist has `GOOGLE_CLIENT_ID` key
- Verify the Client ID is correct (no extra spaces)

**Error: "No root view controller found"**
- This usually means the app isn't fully initialized
- Ensure authentication view is shown after app launch

**Error: "Failed to get Google ID token"**
- Verify OAuth credentials are set up correctly
- Check bundle ID matches Google Cloud Console
- Ensure URL scheme is configured

### Apple Sign-In Issues

**Error: "Sign in with Apple not available"**
- Verify capability is enabled in Xcode
- Check App ID has Sign in with Apple enabled
- Ensure testing on device or simulator with iOS 13+

## Future Enhancements

- Email/Password authentication
- Biometric authentication (Face ID / Touch ID)
- Multi-account support
- Account linking (connect Apple + Google)
- Social profile images
- Sign out functionality


