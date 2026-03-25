# Storage Mechanism Analysis: Current vs Previous

## 🔍 Current Storage System

### **SwiftData (NOT Core Data)**

**We are using:** SwiftData (Apple's modern data persistence framework)
**We are NOT using:** Core Data (older framework)

### Current Configuration

**Location:** `TimeFlowApp.swift` → `createModelContainer()`

```swift
// PRIMARY: Persistent disk storage
let modelConfiguration = ModelConfiguration(schema: schema)
let container = try ModelContainer(for: schema, configurations: [modelConfiguration])

// FALLBACK 1: Delete old DB and retry
// FALLBACK 2: In-memory only (if disk fails)
let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
```

**Storage Location:**
- **Disk:** `URL.applicationSupportDirectory.appending(path: "default.store")`
- **Format:** SQLite database (SwiftData uses SQLite under the hood)
- **Persistence:** ✅ **PERSISTENT** (data survives app restarts)

### What's Stored Locally (SwiftData)

| Model | Storage | Why Local? |
|-------|---------|------------|
| `Task` | SwiftData (SQLite) | Instant access, offline-first |
| `TaskBlock` | SwiftData (SQLite) | Grouping logic, no cloud needed |
| `Goal` | SwiftData (SQLite) | Personal goals, privacy |
| `GoalMilestone` | SwiftData (SQLite) | Part of goals |
| `DailyRoutine` | SwiftData (SQLite) | Template-based |
| `MoodEntry` | SwiftData (SQLite) | Local-first, synced to Firebase |
| `User` | SwiftData (SQLite) | Local copy, synced to Firebase |
| `Theme` | SwiftData (SQLite) | Theme definitions |
| `GoalReflection` | SwiftData (SQLite) | Personal reflections |

### What's Stored in Firestore (Cloud)

| Data Type | Collection | Why Cloud? |
|-----------|------------|------------|
| **Gamification Stats** | `users/{uid}` | Leaderboards, cross-device sync |
| **Mood Events** | `users/{uid}/moodEvents` | Analytics, mood-based features |
| **Leaderboards** | `leaderboards/global_by_week` | Global rankings |
| **Theme Unlocks** | `users/{uid}` | Cross-device theme sync |
| **User Profile** | `users/{uid}` | Cross-device access |

---

## 📊 Storage Comparison: Before vs Now

### **BEFORE (Previous Implementation)**

**Status:** Unknown - Need to check git history or previous documentation

**Possible Previous States:**
1. **In-Memory Only** (`isStoredInMemoryOnly: true`)
   - ❌ Data lost on app close
   - ⚠️ Could cause crashes if data expected to persist
   
2. **Core Data** (if migrated from older version)
   - Different framework
   - Different storage format
   - Migration issues possible

3. **Different SwiftData Configuration**
   - Different schema
   - Different storage location
   - Migration conflicts

### **NOW (Current Implementation)**

**Status:** ✅ **Persistent Disk Storage**

**Configuration:**
- ✅ SwiftData with persistent SQLite database
- ✅ Data stored in `Application Support/default.store`
- ✅ Fallback to in-memory only if disk storage fails
- ✅ Automatic migration handling (deletes old DB if migration fails)

**Storage Format:**
- **Primary:** SQLite database file
- **Location:** `~/Library/Application Support/[App]/default.store`
- **Persistence:** ✅ Data survives app restarts, device reboots

---

## 🔄 Data Flow: Local ↔ Cloud

### Local → Cloud (Sync)

**What Syncs:**
1. **Gamification Stats** (via `FirestoreService.syncGamificationStats`)
   - Level, XP, crystals, momentum days
   - Weekly productivity score
   - Synced every 30 seconds + on app background

2. **Mood Events** (via `FirestoreService.syncMoodEvent`)
   - Mood entries synced to Firebase for analytics

3. **Theme Unlocks** (via `FirestoreService.syncThemeUnlocks`)
   - Owned themes synced to Firebase

### Cloud → Local (Read-Only)

**What's Read from Cloud:**
1. **Leaderboards** - Global rankings (read-only queries)
2. **Theme Catalog** - Public theme definitions
3. **User Profile** - Cross-device profile data

---

## ⚠️ Potential Issues

### Issue 1: Storage Format Changes

**If storage format changed:**
- Old data might not be readable
- Migration might fail
- Current code deletes old DB and starts fresh (line 94-95)

### Issue 2: In-Memory Fallback

**If disk storage fails:**
- Falls back to in-memory only
- Data lost on app close
- Could cause crashes if code expects persistent data

### Issue 3: Core Data vs SwiftData

**If migrated from Core Data:**
- Different storage format
- Different query syntax
- Migration needed

---

## 🔍 How to Check Previous Storage

### Check Git History

```bash
git log --all --oneline --grep="storage\|Storage\|SwiftData\|CoreData\|isStoredInMemoryOnly"
git log --all -p -- TimeFlowApp.swift | grep -A 10 -B 10 "isStoredInMemoryOnly\|ModelConfiguration"
```

### Check Current Storage Status

```bash
# Check if database file exists
ls -la ~/Library/Application\ Support/[App]/default.store

# Check file size (if exists)
du -h ~/Library/Application\ Support/[App]/default.store
```

### Check for Core Data

```bash
# Search for Core Data imports
grep -r "import CoreData" Haven2.0/
grep -r "NSPersistentContainer" Haven2.0/
grep -r "NSManagedObjectContext" Haven2.0/
```

---

## ✅ Recommendations

1. **Verify Current Storage:**
   - Check if `default.store` file exists
   - Verify it's not in-memory only
   - Check file size (should grow with data)

2. **Check Previous Implementation:**
   - Review git history for storage changes
   - Check if Core Data was used before
   - Verify if `isStoredInMemoryOnly` was true before

3. **Monitor Storage:**
   - Add logging to verify persistent storage
   - Check if data survives app restarts
   - Verify migration handling

---

## 📝 Summary

**Current System:**
- ✅ **SwiftData** (not Core Data)
- ✅ **Persistent disk storage** (SQLite)
- ✅ **Hybrid architecture** (Local SwiftData + Cloud Firestore)
- ✅ **Automatic migration** (deletes old DB if migration fails)

**Data Storage:**
- **Local (SwiftData):** Tasks, Goals, Routines, Moods, User profile
- **Cloud (Firestore):** Gamification stats, Leaderboards, Mood analytics, Theme unlocks

**Potential Issue:**
- If storage format changed, old data might be lost
- Migration might fail and start fresh
- Need to verify previous storage mechanism

