# Firebase Emulator Setup Guide

## Overview
Testing with Firebase Emulator Suite allows you to test authentication locally without affecting production Firebase. This helps isolate API issues and configuration problems.

## Prerequisites

1. **Node.js** (v14 or higher)
   ```bash
   node --version
   ```

2. **Firebase CLI**
   ```bash
   npm install -g firebase-tools
   firebase --version
   ```

3. **Login to Firebase** (optional for local testing)
   ```bash
   firebase login
   ```

## Setup Steps

### 1. Initialize Firebase Emulator (if not already done)

```bash
cd /Users/johnuja/Desktop/Haven2.0
firebase init emulators
```

When prompted:
- Select **Authentication** emulator
- Select **Firestore** emulator (optional, for future use)
- Choose a port (default 9099 for Auth is fine)
- Say yes to downloading emulators

**OR** if `firebase.json` already exists (we just created it), skip this step.

### 2. Configure `firebase.json`

✅ **Already created** - `firebase.json` is configured with:
- Auth emulator on port 9099
- Firestore emulator on port 8080
- Emulator UI on port 4000

### 3. Update iOS App to Connect to Emulator

✅ **Already updated** - `TimeFlowApp.swift` has been modified to connect to emulator in DEBUG mode.

**To enable emulator connection:**
1. Open `Haven2.0/TimeFlowApp.swift`
2. Find the commented section in `init()`:
   ```swift
   /*
   Auth.auth().useEmulator(withHost: "localhost", port: 9099)
   print("DEBUG: Connected to Firebase Auth Emulator on localhost:9099")
   */
   ```
3. **Uncomment those lines** to enable emulator connection

### 4. Start Emulator

```bash
cd /Users/johnuja/Desktop/Haven2.0
firebase emulators:start
```

This will start:
- ✅ Authentication emulator on port 9099
- ✅ Firestore emulator on port 8080
- ✅ Emulator UI on port 4000 (http://localhost:4000)

**Note:** The emulator must be running before launching the iOS app.

## Testing Workflow

### Step 1: Start Emulator
```bash
cd /Users/johnuja/Desktop/Haven2.0
firebase emulators:start
```

You should see:
```
✔  All emulators ready! It is now safe to connect.
✔  Emulator UI started at http://localhost:4000
```

### Step 2: Enable Emulator in App Code

1. Open `Haven2.0/TimeFlowApp.swift`
2. Uncomment the emulator connection lines:
   ```swift
   Auth.auth().useEmulator(withHost: "localhost", port: 9099)
   print("DEBUG: Connected to Firebase Auth Emulator on localhost:9099")
   ```

### Step 3: Run iOS App

1. Build and run the app in Xcode
2. Check console logs for: "DEBUG: Connected to Firebase Auth Emulator on localhost:9099"
3. Test authentication flows:
   - Guest sign-in
   - Email sign-up/sign-in
   - Apple Sign-In (if you can test it)
   - Google Sign-In (if you can test it)

### Step 4: Monitor Emulator UI

1. Open http://localhost:4000 in your browser
2. Go to **Authentication** tab
3. See all users created through the emulator
4. Test creating users manually
5. Check logs for authentication events

## Benefits of Using Emulator

1. **No API Key Issues**: Emulator works without production Firebase config
2. **Test API Changes**: Test different Firebase SDK versions
3. **Isolated Testing**: No impact on production data
4. **Easy Reset**: Clear all data by restarting emulator
5. **Better Debugging**: See all auth events in Emulator UI

## Troubleshooting

### Issue: "Connection refused" error
**Solution**: Make sure emulator is running before launching app:
```bash
firebase emulators:start
```

### Issue: App still connects to production Firebase
**Solution**: Make sure you uncommented the emulator connection lines in `TimeFlowApp.swift`

### Issue: Emulator UI not accessible
**Solution**: Check if port 4000 is already in use:
```bash
lsof -i :4000
```

### Issue: Can't test OAuth providers (Google/Apple)
**Solution**: 
- OAuth providers may not work with emulator (they require real credentials)
- Focus on testing Email/Password and Guest authentication
- Use emulator to test credential creation logic

## Testing Apple Sign-In API

The emulator is perfect for testing if the Apple Sign-In credential creation API works:

1. Start emulator
2. Enable emulator connection in app
3. Try Apple Sign-In
4. Check console logs for specific API errors
5. The emulator will show if the credential is created correctly

## Next Steps

1. ✅ Start emulator: `firebase emulators:start`
2. ✅ Uncomment emulator connection in `TimeFlowApp.swift`
3. ✅ Run app and test authentication
4. ✅ Check Emulator UI at http://localhost:4000
5. ✅ Test Apple Sign-In credential creation with emulator

