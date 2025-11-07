# Quick Start: Firebase Emulator

## ✅ What's Already Done

1. ✅ `firebase.json` created with emulator configuration
2. ✅ `TimeFlowApp.swift` updated with emulator connection code (commented out)
3. ✅ Node.js installed (v24.1.0)

## 🚀 Quick Setup (3 Steps)

### Step 1: Install Firebase CLI

```bash
npm install -g firebase-tools
```

### Step 2: Start Emulator

```bash
cd /Users/johnuja/Desktop/Haven2.0
firebase emulators:start
```

**Keep this terminal open!** The emulator must be running.

### Step 3: Enable Emulator in App

1. Open `Haven2.0/TimeFlowApp.swift` in Xcode
2. Find lines 31-34 (commented out):
   ```swift
   /*
   Auth.auth().useEmulator(withHost: "localhost", port: 9099)
   print("DEBUG: Connected to Firebase Auth Emulator on localhost:9099")
   */
   ```
3. **Uncomment** those lines (remove `/*` and `*/`)

## 🧪 Test

1. Run the app in Xcode
2. Check console for: "DEBUG: Connected to Firebase Auth Emulator on localhost:9099"
3. Open http://localhost:4000 in browser to see Emulator UI
4. Test authentication flows

## 📝 Notes

- **Emulator must be running** before launching the app
- **OAuth providers** (Google/Apple) may not fully work with emulator
- **Email/Password and Guest** authentication will work perfectly
- **Easy reset**: Just restart the emulator to clear all data

## 🐛 Troubleshooting

**"Connection refused"**: Make sure emulator is running (`firebase emulators:start`)

**"Port already in use"**: Stop other services using ports 9099, 8080, or 4000

**"Firebase CLI not found"**: Run `npm install -g firebase-tools` first

