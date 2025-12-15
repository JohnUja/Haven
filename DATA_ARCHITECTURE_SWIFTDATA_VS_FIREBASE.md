# Data Architecture: SwiftData vs Firebase

## Overview

Haven 2.0 uses a **hybrid architecture**:
- **SwiftData** (Local): Core features, instant access, offline-first
- **Firebase** (Cloud): Gamification, social features, cross-device sync

This document explains what data is stored where and why, to help with pricing logic implementation.

---

## 📱 SwiftData (Local Storage)

### What Uses SwiftData?

**All Core User Data (Local-First):**

| Data Type | Model | Why Local? |
|-----------|-------|------------|
| **Tasks** | `Task` | Instant access, works offline, no network latency |
| **Task Blocks** | `TaskBlock` | Grouping logic, no cloud needed |
| **Goals** | `Goal` | Personal goals, privacy-sensitive |
| **Milestones** | `GoalMilestone` | Part of goals |
| **Routines** | `DailyRoutine` | Template-based, generates tasks locally |
| **Reflections** | `JournalEntry` | Personal journaling, privacy-critical |
| **Mood Entries** | `MoodEntry` | Local-first, synced to Firebase for analytics |
| **User Profile** | `User` | Local copy, synced to Firebase for gamification |

### SwiftData Models

**Location**: `Haven2.0/Models/`

- `Task.swift` - All task data (title, times, category, priority, etc.)
- `TaskBlock.swift` - Task grouping blocks
- `Goal.swift` - User goals
- `GoalMilestone.swift` - Goal milestones
- `DailyRoutine.swift` - Routine templates
- `JournalEntry.swift` - Reflection entries with photos
- `MoodEntry.swift` - Mood tracking entries
- `User.swift` - User profile and gamification stats

### Why Local?

1. **Performance**: Zero latency, instant reads/writes
2. **Offline**: Works completely offline
3. **Privacy**: User data stays on device
4. **Cost**: No cloud storage costs per task/edit
5. **UX**: Native iOS feel (snappy, responsive)

### Access Pattern

```swift
// SwiftData queries
@Query private var tasks: [Task]
@Query private var goals: [Goal]
@Query private var routines: [DailyRoutine]

// Direct access via ModelContext
@Environment(\.modelContext) private var modelContext
modelContext.insert(task)
try? modelContext.save()
```

---

## ☁️ Firebase (Cloud Storage)

### What Uses Firebase?

**Only Cloud-Worthy Data:**

| Data Type | Firebase Collection | Why Cloud? |
|-----------|---------------------|------------|
| **Gamification Stats** | `users/{uid}` | Leaderboards, cross-device sync |
| **Mood Events** | `users/{uid}/moodEvents` | Analytics, mood-based features |
| **Leaderboards** | `leaderboards/global_by_week` | Global rankings, social features |
| **Themes** | `themes/{themeId}` | Public catalog, unlock tracking |
| **User Profile** | `users/{uid}` | Cross-device access, backup |
| **Reflection Photos** | `user_files/{uid}/reflections` | Optional cross-device sync |

### Firebase Services

**Location**: `Haven2.0/Services/`

1. **FirestoreService.swift**
   - Syncs gamification stats (`level`, `currentXP`, `crystals`, `momentumDays`)
   - Syncs mood events
   - Updates leaderboard scores
   - Theme unlock tracking

2. **FirebaseAuthService.swift**
   - User authentication (Email, Google Sign-In, Guest)
   - User session management
   - Guest mode detection

3. **FirebaseStorageService.swift**
   - Uploads reflection photos (optional)
   - Theme asset downloads (optional)

### Firebase Collections Structure

#### `users/{uid}` (Single Document)

```swift
{
  // Auth & Profile
  uid: String
  displayName: String
  email: String
  photoURL: String?
  createdAt: Timestamp
  timezone: String
  locale: String
  onboardingComplete: Boolean
  
  // Gamification Stats (SYNCED from SwiftData)
  level: Int
  currentXP: Int
  nextLevelXP: Int
  crystals: Int
  momentumDays: Int
  lastMomentumUpdate: Timestamp?
  weeklyProductivityScore: Int
  weeklyResetDate: Timestamp?
  
  // Themes & Unlocks
  ownedThemeIDs: Map<String, {
    unlockedAt: Timestamp,
    source: "level|crystals|mood|purchase"
  }>
  activeThemeID: String
  
  // Mood Summary (DENORMALIZED)
  moodJarSummary: Map<String, Int>
  moodJarCompletions: Int
  
  // Leaderboard Cache
  localLeaderboardScore: Int
  globalLeaderboardScore: Int
  lastLeaderboardUpdate: Timestamp?
  
  // Subscription (for pricing)
  subscriptionStatus: "guest" | "free" | "plus" | "pro" | "lifetime"
  subscriptionExpiresAt: Timestamp?
  trialStart: Timestamp?
  
  // Settings (Optional sync)
  settings: {
    use24HourFormat: Boolean,
    calendarSyncEnabled: Boolean,
    notificationsEnabled: Boolean
  }
  
  // Routine Metadata (Count only)
  activeRoutineCount: Int
  lastRoutineUpdate: Timestamp?
  
  lastActiveAt: Timestamp
}
```

#### `users/{uid}/moodEvents/{eventId}` (Subcollection)

```swift
{
  id: String
  moodType: String
  timestamp: Timestamp
  note: String?
  createdAt: Timestamp
}
```

#### `leaderboards/global_by_week/{YYYY-WW}` (Global Collection)

```swift
{
  week: String
  rankings: Array<{
    uid: String,
    displayName: String,
    score: Int,
    rank: Int
  }>
  updatedAt: Timestamp
}
```

#### `themes/{themeId}` (Global Collection, Public Read)

```swift
{
  id: String
  name: String
  description: String
  unlockMethod: "default" | "level" | "crystals" | "mood" | "purchase"
  unlockLevel: Int?
  crystalCost: Int?
  moodRequirement: Map<String, Int>?
  iapProductId: String?
  previewImageURL: String
  createdAt: Timestamp
}
```

### Why Cloud?

1. **Social Features**: Leaderboards, global rankings
2. **Cross-Device**: Sync gamification stats across devices
3. **Analytics**: Mood data aggregation, user behavior
4. **Backup**: Optional backup of critical data
5. **Themes**: Public catalog, unlock validation

### Sync Strategy

**Background Sync (Non-Blocking):**

```swift
// Local: Instant update
user.currentXP += 50
user.crystals += 20
try? modelContext.save()

// Background: Async sync (every 30s or on app background)
_Concurrency.Task.detached {
    try? await FirestoreService.shared.syncGamificationStats(
        uid: user.uid,
        level: user.level,
        currentXP: user.currentXP,
        crystals: user.crystals,
        momentumDays: user.momentumDays
    )
}
```

**Benefits:**
- ✅ Zero UI lag
- ✅ Works offline
- ✅ Syncs when online
- ✅ Minimal Firestore writes (batched)

---

## 🔄 Data Flow

### Task Creation Flow

```
User creates task
    ↓
SwiftData: modelContext.insert(task)
    ↓
SwiftData: modelContext.save() (instant)
    ↓
UI updates immediately (no wait)
    ↓
(No Firebase sync - tasks are local only)
```

### Task Completion Flow

```
User completes task
    ↓
SwiftData: task.isComplete = true
    ↓
SwiftData: modelContext.save() (instant)
    ↓
GamificationService: Calculate XP/crystals
    ↓
SwiftData: user.currentXP += xp (instant)
    ↓
UI updates immediately (no wait)
    ↓
Background: FirestoreService.syncGamificationStats() (async)
    ↓
Firebase: users/{uid} updated (background)
```

### Mood Entry Flow

```
User records mood
    ↓
SwiftData: MoodEntry created (instant)
    ↓
SwiftData: modelContext.save() (instant)
    ↓
UI updates immediately (no wait)
    ↓
Background: FirestoreService.syncMoodEvent() (async)
    ↓
Firebase: users/{uid}/moodEvents/{eventId} created
    ↓
Firebase: users/{uid}.moodJarSummary updated (via Cloud Function)
```

---

## 💰 Pricing Logic Implications

### What Data Determines Pricing?

**Firebase (Cloud) - Pricing Enforcement:**

| Feature | Data Source | Pricing Check |
|---------|------------|---------------|
| **Subscription Status** | `users/{uid}.subscriptionStatus` | Firebase (source of truth) |
| **Guest Mode** | `FirebaseAuthService.isGuest` | Firebase Auth |
| **Daily Task Limit** | SwiftData count + Firebase subscription | Both (local count, cloud status) |
| **Routine Limit** | SwiftData count + Firebase subscription | Both (local count, cloud status) |
| **Theme Unlocks** | `users/{uid}.ownedThemeIDs` | Firebase |
| **AI Insights Limit** | Firebase subscription + local count | Both |

### Pricing Tiers

**Guest Mode:**
- 1 task creation limit
- No Firebase sync
- Local data only

**Free Tier:**
- 3 tasks/blocks per day (SwiftData count)
- 1 active routine (SwiftData count)
- Firebase subscription status: `"free"`
- Gamification stats synced to Firebase

**Haven+ ($6.99/month):**
- Unlimited tasks (no SwiftData limit check)
- 5 active routines (SwiftData count, but limit increased)
- Firebase subscription status: `"plus"`
- All features unlocked

**Haven Pro ($9.99/month):**
- Everything in Haven+
- Firebase subscription status: `"pro"`
- Premium features unlocked

**Haven Forever ($120 one-time):**
- Everything in Haven Pro
- Firebase subscription status: `"lifetime"`
- Lifetime access

### Pricing Check Implementation

```swift
// Check subscription status (Firebase)
let subscriptionStatus = await FirestoreService.shared.getSubscriptionStatus(uid: user.uid)

// Check daily task limit (SwiftData)
let today = Calendar.current.startOfDay(for: Date())
let todayTasks = tasks.filter { Calendar.current.isDate($0.startTime, inSameDayAs: today) }
let todayBlocks = taskBlocks.filter { Calendar.current.isDate($0.createdDate, inSameDayAs: today) }
let dailyCount = todayTasks.count + todayBlocks.count

// Enforce limit
if subscriptionStatus == .free && dailyCount >= 3 {
    // Show paywall
    showPaywall = true
    return false
}

// Check routine limit (SwiftData)
let activeRoutines = routines.filter { $0.isActive }
if subscriptionStatus == .free && activeRoutines.count >= 1 {
    // Show paywall
    showPaywall = true
    return false
}
```

---

## 📊 Summary Table

| Feature | Storage | Access | Sync | Pricing Impact |
|---------|---------|--------|------|----------------|
| **Tasks** | SwiftData | Local | None | Count checked for free tier |
| **Task Blocks** | SwiftData | Local | None | Count checked for free tier |
| **Goals** | SwiftData | Local | None | No limit |
| **Routines** | SwiftData | Local | None | Count checked for free tier |
| **Reflections** | SwiftData | Local | Optional | No limit |
| **Mood Entries** | SwiftData + Firebase | Local + Cloud | Background | No limit |
| **Gamification Stats** | SwiftData + Firebase | Local + Cloud | Background | No limit |
| **User Profile** | SwiftData + Firebase | Local + Cloud | Background | Subscription status |
| **Leaderboards** | Firebase | Cloud | Read-only | No limit |
| **Themes** | Firebase | Cloud | Read-only | Unlock tracking |

---

## 🔍 Key Files for Pricing Logic

### Services
- `FirestoreService.swift` - Get subscription status, sync stats
- `FirebaseAuthService.swift` - Check guest mode
- `SubscriptionService.swift` - IAP purchase, subscription management

### Models
- `User.swift` (SwiftData) - Local user data
- `Task.swift` (SwiftData) - Task count for limits
- `DailyRoutine.swift` (SwiftData) - Routine count for limits

### Views
- `PaywallView.swift` - Subscription purchase UI
- `HomeDashboardView.swift` - Task creation limits
- `SettingsView.swift` - Subscription management

---

## 🎯 Recommendations for Pricing Implementation

1. **Source of Truth**: Firebase `users/{uid}.subscriptionStatus` is the authoritative source
2. **Local Checks**: Use SwiftData counts for daily limits (fast, no network)
3. **Cloud Validation**: Verify subscription status on app launch and periodically
4. **Offline Handling**: Allow local operations, validate subscription on next sync
5. **Guest Mode**: Check `FirebaseAuthService.isGuest` before any premium features

---

**Last Updated**: 2025-01-XX
**Status**: Current architecture as of latest audit

