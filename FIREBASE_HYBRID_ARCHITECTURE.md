# Firebase Hybrid Architecture for Haven 2.0

## Overview

**Hybrid Approach**: SwiftData for local data (tasks, routines, goals), Firebase for cloud sync (gamification stats, leaderboards, themes, moods). This keeps the app fast, offline-first, while enabling global features.

**Key Principle**: Local-first, cloud-backup. Tasks/routines are instant and offline. Gamification syncs in background. Leaderboards are read-only cloud queries.

---

## Data Architecture: Local vs Cloud

### 📱 SwiftData (Local - Primary Storage)

**All Core Features Stored Locally:**

- ✅ **Tasks** (`Task` model)
  - All task properties
  - Routine-generated tasks (`isRoutineTask: Bool`, `routineID: String?`)
  - Task blocks (`taskBlockID: String?`)
  - Goals linkage (`goalID: String?`)
  - Reflections (`JournalEntry` relationship)
  
- ✅ **Task Blocks** (`TaskBlock` model)
  - Local only, no cloud sync needed
  
- ✅ **Goals & Milestones** (`Goal`, `GoalMilestone` models)
  - Local only, instant access
  
- ✅ **Routines** (`DailyRoutine` model - NEW)
  - Routine templates (not individual task instances)
  - See "Routine Storage Format" section below
  
- ✅ **Reflection Entries** (`JournalEntry` model)
  - Photos cached locally
  - Text notes stored locally
  
- ✅ **Calendar Events** (EventKit integration)
  - Local calendar access only
  
- ✅ **UI State & Drafts**
  - UserDefaults, temporary data

**Why Local:**
- Instant reads/writes (zero latency)
- Works offline completely
- No network costs per edit
- Native iOS feel (snappy, responsive)

---

### ☁️ Firebase Firestore (Cloud - Background Sync)

**Only Cloud-Worthy Data:**

#### `users/{uid}` (Single Document)

```swift
{
  // Auth & Profile
  uid: String (Firebase Auth UID)
  displayName: String
  email: String
  photoURL: String? (Storage path)
  createdAt: Timestamp
  timezone: String
  locale: String
  onboardingComplete: Boolean
  
  // Gamification Stats (SYNCED from local)
  level: Int
  currentXP: Int
  nextLevelXP: Int
  crystals: Int
  momentumDays: Int
  lastMomentumUpdate: Timestamp?
  weeklyProductivityScore: Int
  weeklyResetDate: Timestamp?
  
  // Themes & Unlocks (SYNCED from local)
  ownedThemeIDs: Map<String, {
    unlockedAt: Timestamp,
    source: "level|crystals|mood|purchase"
  }>
  activeThemeID: String
  
  // Mood Summary (DENORMALIZED for leaderboards)
  moodJarSummary: Map<String, Int> // { "happy": 5, "sad": 2, ... }
  moodJarCompletions: Int
  
  // Leaderboard Cache
  localLeaderboardScore: Int
  globalLeaderboardScore: Int
  lastLeaderboardUpdate: Timestamp?
  
  // Subscription
  subscriptionStatus: "guest" | "free" | "plus" | "pro" | "lifetime"
  subscriptionExpiresAt: Timestamp?
  trialStart: Timestamp?
  
  // Settings (Optional sync for cross-device)
  settings: {
    use24HourFormat: Boolean,
    calendarSyncEnabled: Boolean,
    notificationsEnabled: Boolean
  }
  
  // Routine Metadata (Count only, not full templates)
  activeRoutineCount: Int (1 for free, 5 for premium)
  lastRoutineUpdate: Timestamp?
  
  lastActiveAt: Timestamp
}
```

#### `users/{uid}/moodEvents/{eventId}` (Subcollection)

```swift
{
  id: String
  moodType: String ("happy", "sad", "anxious", ...)
  timestamp: Timestamp
  note: String? (optional)
  createdAt: Timestamp
}
```

**Why Cloud:**
- Enables global leaderboards
- Aggregates mood data for analytics
- Lightweight (just events, not full tasks)

#### `leaderboards/global_by_week/{YYYY-WW}` (Global Collection)

```swift
{
  week: String ("2025-W01")
  rankings: Array<{
    uid: String,
    displayName: String,
    score: Int,
    rank: Int
  }>
  updatedAt: Timestamp
}
```

**Updated by Cloud Function** (not client writes)

#### `leaderboards/local/{locationId}` (Optional - Future)

For location-based leaderboards (requires location permission)

#### `themes/{themeId}` (Global Collection, Public Read)

```swift
{
  id: String
  name: String
  description: String
  unlockMethod: "default" | "level" | "crystals" | "mood" | "purchase"
  unlockLevel: Int? (if level-based)
  crystalCost: Int? (if crystal purchase)
  moodRequirement: Map<String, Int>? (if mood-based)
  iapProductId: String? (if purchase)
  previewImageURL: String (Storage path)
  createdAt: Timestamp
}
```

**Public read, admin write**

---

### 📦 Firebase Storage (Cloud - Media Only)

**Only Binary Assets:**

- `user_files/{uid}/reflections/{photoId}.jpg` - Reflection photos (optional sync)
- `themes/{themeId}/assets/` - Theme asset bundles (optional downloads)
- `user_files/{uid}/backups/{backupId}.json` - Manual backups (optional)

**Why Cloud:**
- Photos can be large
- Optional: Only if user wants cross-device access
- Can be downloaded on-demand, cached locally

---

## Sync Strategy

### Gamification Stats Sync (Background)

**Flow:**

1. User completes task locally → XP/crystals awarded **instantly** (no wait)
2. Local `User` model updated immediately
3. Background task syncs to Firestore `users/{uid}`:
   - Every 30 seconds if changed
   - Or on app background
   - Or manually via "Sync Now" button

**Code Pattern:**

```swift
// Local: Instant update
user.currentXP += 50
user.crystals += 20

// Background: Async sync
Task {
    try? await FirestoreService.shared.syncGamificationStats(
        uid: user.uid,
        level: user.level,
        xp: user.currentXP,
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

### Leaderboard Updates

**Flow:**

1. User earns productivity score locally
2. Every few minutes (or on app background):
   - Call Cloud Function: `updateLeaderboardScore(uid, scoreDelta)`
   - Cloud Function atomically increments leaderboard cache
3. Leaderboard view fetches from `leaderboards/global_by_week/{YYYY-WW}` (read-only)

**Benefits:**
- ✅ Leaderboard writes are server-validated (prevents cheating)
- ✅ Client only reads (fast, cheap)
- ✅ Updates every few minutes (real-time-ish)

---

### Mood Events Sync

**Flow:**

1. User records mood locally (`MoodEntry` in SwiftData)
2. Immediately sync to Firestore `users/{uid}/moodEvents/{eventId}`
3. Update denormalized `users/{uid}.moodJarSummary` (via Cloud Function)
4. Check thresholds for mood-based theme unlocks

**Benefits:**
- ✅ Mood data available for analytics
- ✅ Enables mood-based leaderboards
- ✅ Lightweight writes (just events)

---

### Theme Unlocks Sync

**Flow:**

1. User unlocks theme locally (via level, crystals, mood)
2. Add to local `user.ownedThemeIDs` array
3. Sync to Firestore `users/{uid}.ownedThemeIDs` (background)
4. Themes metadata fetched from `themes/{themeId}` (public read, cached)

**Benefits:**
- ✅ Cross-device theme access
- ✅ Server validates unlock conditions (prevents tampering)
- ✅ Theme assets cached locally after first download

---

## Routine Storage Format (Performance Optimized)

### Problem: Preventing Slow Rendering

**Challenge**: Routines generate daily tasks. Storing every single task instance would bloat SwiftData and cause slow queries.

**Solution**: Template-Based with Lazy Generation

---

### `DailyRoutine` Model (SwiftData)

```swift
@Model
final class DailyRoutine {
    var id: String
    var userID: String
    var title: String // e.g., "My Daily Essentials"
    var isActive: Bool
    var isDefault: Bool // Default routines (sleep, eat) vs user-added
    
    // Duration
    var durationType: RoutineDurationType // "tillMonthEnd" or "days"
    var durationDays: Int? // If "days", how many days (30, 60, etc.)
    var startDate: Date // First day routine was created
    var endDate: Date? // Calculated: startDate + duration
    
    // Task Templates (LIGHTWEIGHT - Not full Task objects)
    var taskTemplates: [RoutineTaskTemplate] // Array of simple structs
    
    // Metadata
    var notificationEnabled: Bool
    var createdAt: Date
    var updatedAt: Date
    
    // Archive tracking
    var archivedAt: Date? // After routine expires + 30 day grace
}

// Separate struct (not @Model) - stored as JSON in DailyRoutine
struct RoutineTaskTemplate: Codable {
    var title: String
    var description: String?
    var timeOfDay: String // "HH:mm" format (e.g., "08:00", "12:30")
    var durationMinutes: Int
    var priority: PriorityType
    var category: TaskCategory
    var hasDefaultNotifications: Bool // For sleep/eat defaults
}
```

**Why This Format:**

1. **Templates are Tiny**: Just metadata, not full `Task` objects
2. **Lazy Generation**: Tasks created on-demand (day before or morning of)
3. **Batched Creation**: Generate entire month at once, but in background
4. **Smart Queries**: Filter by `routineID` to find routine tasks quickly

---

### Task Generation Strategy

**Option 1: Pre-generate on Routine Creation** (Recommended)

```swift
// When routine created (till month end):
let calendar = Calendar.current
let startOfMonth = calendar.dateInterval(of: .month, for: startDate)!.start
let endOfMonth = calendar.dateInterval(of: .month, for: startDate)!.end

// Generate all tasks upfront (in background)
Task.detached(priority: .utility) {
    for date in datesBetween(startOfMonth, endOfMonth) {
        for template in routine.taskTemplates {
            let task = Task(
                userID: user.id,
                title: template.title,
                startTime: combineDateAndTime(date, template.timeOfDay),
                endTime: addMinutes(startTime, template.durationMinutes),
                priority: template.priority,
                category: template.category,
                isRoutineTask: true,
                routineID: routine.id,
                isLocked: true // Cannot delete/move
            )
            modelContext.insert(task)
        }
    }
    try? modelContext.save()
}
```

**Pros:**
- ✅ Tasks available immediately when scrolling days
- ✅ No generation lag when viewing timeline
- ✅ Can query `tasks.filter { $0.routineID == routine.id }` instantly

**Cons:**
- ⚠️ More disk space (but SwiftData is efficient)
- ⚠️ Need cleanup for expired routines

**Solution for Cons:**
- Archive old routine tasks after routine ends + 30 days
- Archive happens in background (doesn't block UI)

---

**Option 2: Lazy Generation (Alternative)**

```swift
// Generate tasks on-demand when viewing a day
func getTasksForDay(_ date: Date) -> [Task] {
    let existingTasks = tasks.filter { calendar.isDate($0.startTime, inSameDayAs: date) }
    
    // Check if routine tasks missing for this day
    let activeRoutines = routines.filter { $0.isActive && isDateInRoutineRange(date, $0) }
    
    for routine in activeRoutines {
        let routineTasksForDay = existingTasks.filter { $0.routineID == routine.id }
        if routineTasksForDay.isEmpty {
            // Generate now (lazy)
            generateTasksForRoutine(routine, for: date)
        }
    }
    
    return existingTasks
}
```

**Pros:**
- ✅ Minimal disk usage
- ✅ Only generates what's needed

**Cons:**
- ⚠️ First-time generation lag when viewing new day
- ⚠️ More complex query logic

**Recommendation: Option 1** (Pre-generate) for better UX.

---

### Routine Task Cleanup (Archival)

**After Routine Expires:**

1. Routine `endDate` passes
2. 30-day grace period: Keep tasks visible (user can review)
3. After grace: Mark routine tasks as `archived: true`
4. Archive routine template to `archivedRoutines` collection (keep for 3 months reference)
5. Delete old archived tasks after 3 months

**Code:**

```swift
func archiveExpiredRoutines() {
    let calendar = Calendar.current
    let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: Date())!
    
    let expiredRoutines = routines.filter { routine in
        if let endDate = routine.endDate {
            return endDate < thirtyDaysAgo && routine.archivedAt == nil
        }
        return false
    }
    
    for routine in expiredRoutines {
        // Mark routine as archived
        routine.archivedAt = Date()
        routine.isActive = false
        
        // Archive all tasks from this routine
        let routineTasks = tasks.filter { $0.routineID == routine.id }
        for task in routineTasks {
            task.archived = true
            task.archivedAt = Date()
        }
    }
    
    try? modelContext.save()
}
```

---

### Routine Duration Types

**"Till End of Month":**

- Calculate `endDate = startOfMonth(for: startDate) + 1 month - 1 day`
- Generate tasks for all days in that month
- On first of next month: Prompt user "Update routine for [Month]?"
  - Options: "Keep Same" → Regenerate for new month
  - Options: "Update" → Edit routine, then regenerate
  - Options: "Skip This Month" → No generation

**"30 Days" (or custom days):**

- Calculate `endDate = startDate + 30 days`
- Generate tasks for exactly 30 days
- After 30 days: Routine expires (can create new one or extend)

---

## Guest Mode (Stricter Limits)

### Guest Mode - "Preview Mode"

**Strict Limit: 1 Task Creation**

- ✅ Create **1 task** (then login required)
- ✅ View existing task (read-only)
- ❌ Cannot create task blocks
- ❌ Cannot use timeline (create/edit)
- ❌ Cannot create goals
- ❌ Routines skipped in onboarding
- ✅ View gamification stats (local only, not synced)
- ✅ View themes (read-only, cannot unlock/purchase)
- ❌ No mood jar
- ❌ No reflections
- ❌ No cloud sync

**Trigger After 1 Task:**

Modal popup:
```
"You've created your first task! 🎉

Create a free account to:
• Save your progress forever
• Create unlimited tasks
• Unlock timeline & routines
• Join leaderboards
• Sync across devices

[Sign Up Free] [Maybe Later]"
```

**Data Persistence:**

- Local data survives app restart (SwiftData)
- But **not synced** to cloud
- On login: Migrate local data to cloud (one-time)

---

### Logged-In Free Tier - "Haven Core"

**Daily Limit: 3 Tasks OR Task Blocks (Combined)**

- ✅ **3 tasks/task blocks per day** (combined limit, resets at midnight)
- ✅ After 3 items created → **Paywall prompt**
- ✅ Unlimited viewing/editing of existing tasks
- ✅ Unlimited completion of existing tasks
- ✅ Unlimited goals
- ✅ Timeline full access (view & edit existing)
- ✅ **1 active daily routine** (can create multiple, but only 1 active at a time)
- ✅ All gamification (XP, crystals, levels, themes via crystals/levels)
- ✅ Mood jar (full access)
- ✅ Reflection entries
- ✅ Leaderboards (view global, can participate)
- ✅ AI insights: **3 per week**
- ✅ Cloud sync: Gamification stats, moods, themes

**Paywall Triggers:**

1. **After 3 tasks/blocks created in a day:**
   ```
   "You've created 3 tasks today! 📊
   
   Upgrade to Haven+ for:
   • Unlimited daily tasks
   • Multiple routines
   • Unlimited AI insights
   • Premium themes
   
   [Upgrade to Haven+] [Continue with 3/day]"
   ```

2. **When trying to create 4th task:**
   - Show paywall modal (cannot dismiss without action)
   - Options: "Upgrade" | "Maybe Later" (dismisses, but task not created)

3. **When trying to create 2nd routine:**
   ```
   "Multiple routines are a premium feature!
   
   [Upgrade to Haven+] [Keep One Routine]"
   ```

---

## Subscription Tiers (Revised)

### Haven+ ($6.99/month or $59.99/year)

**Everything in Free, PLUS:**

- ✅ **Unlimited daily tasks/task blocks** (no 3/day limit)
- ✅ **Multiple daily routines** (up to 5 active routines)
- ✅ **Auto-routine updates** (monthly prompts to update)
- ✅ **Unlimited AI insights & recommendations**
- ✅ **Premium themes** (5 additional unlockable themes)
- ✅ **Advanced analytics dashboard**
- ✅ **Early access features**

---

### Haven Pro ($9.99/month or $79.99/year)

**Everything in Haven+, PLUS:**

- ✅ **Personalized AI model** (trained on user patterns)
- ✅ **Mood-to-theme sync** (themes adapt to mood patterns)
- ✅ **Unlimited cloud backups** (manual export/import)
- ✅ **Offline AI model download** (MLModelDownloader for offline recommendations)
- ✅ **Exclusive premium themes** (all premium themes)
- ✅ **Advanced leaderboard filters** (friends, location-based)
- ✅ **Priority support**

---

### Haven Forever ($120 one-time)

**Everything in Haven Pro, PLUS:**

- ✅ **Lifetime access** (no subscription renewal)
- ✅ **All future premium themes**
- ✅ **Lifetime feature updates**
- ✅ **Priority feature requests**

---

## Onboarding Flow (Revised)

### Step 0: Welcome Screen

- **NO MASCOT YET** (placeholder: "Haven" logo or abstract graphic)
- Value proposition: "Your personal productivity haven"
- Options:
  - **"Try as Guest"** (pre-selected, bold button)
  - **"Create Account"** (smaller, secondary button)

---

### Step 1: Quick Win (Guest or Logged-In)

- Show empty task list immediately
- Animated prompt: "Create your first task" (with arrow pointing to + button)
- After creation: **Crystal animation** + "You earned 10 crystals! 🎉"
- **If Guest**: After 1st task → Login prompt (see Guest Mode section)

---

### Step 2: Feature Tour (Skippable)

- 3-4 key screens with overlay highlights:
  1. **Home Dashboard** - "Manage your tasks here"
  2. **Timeline View** - "Visual schedule of your day"
  3. **Profile** - "Track progress, unlock themes"
- Each screen: "Tap anywhere to continue"
- **"Skip Tour"** button (top-right)

---

### Step 3: Routines Setup (Skippable, Only for Logged-In Users)

**If Guest**: Skip this step entirely (routines unavailable)

**If Logged-In:**

- Prompt: **"Set up your daily routine"**
- Explanation: "Routines are daily tasks you do every day (sleep, eat, work, etc.)"
- **Pre-filled default routines:**
  - **"Sleep"** (10:00 PM - 7:00 AM, 9 hours, with default notifications)
  - **"Eat Breakfast"** (8:00 AM, 30 min, default notifications)
  - **"Eat Lunch"** (12:00 PM, 30 min, default notifications)
  - **"Eat Dinner"** (6:00 PM, 45 min, default notifications)

- **User can:**
  - ✅ Toggle defaults on/off
  - ✅ Add custom routine items (job, brush teeth, exercise, etc.)
  - ✅ Edit times/durations
  - ✅ Skip routine setup (can add later)

- **Duration Selection:**
  - Options:
    - **"Till End of Month"** (recommended)
    - **"30 Days"** (or custom: 15, 45, 60 days)

- **After Setup:**
  - Generate routine tasks for selected duration (in background)
  - Show: "Your routine is ready! Tasks will appear each day."

---

### Step 4: Theme Selection

- Show theme preview carousel (default themes only)
- User picks initial theme
- Show: "Unlock more themes as you level up or earn crystals!"

---

### Step 5: Mood Jar Introduction (Quick)

- Demo: "Track your mood 3x daily"
- Show mood selection UI (8 mood types)
- Explain: "Fill jars to unlock mood themes"
- **Optional**: Let user record first mood entry

---

### Step 6: Account Prompt (If Guest)

- After completing 3-5 tasks OR 1 day of use:
- **Non-intrusive banner** (bottom of screen, dismissible):
  ```
  "Create account to save progress? 
  [Sign Up Free]"
  ```

---

## Routine Management in Settings

### Multiple Routines (Premium Feature)

**Free Tier:**

- Only 1 active routine
- Can create multiple routines, but only 1 active at a time
- Switching routines: Archive old, activate new

**Premium Tier (Haven+ & Pro):**

- Up to 5 active routines simultaneously
- Can switch between routines (all active, tasks generated from all)
- Routine switcher UI in Settings

**Settings UI:**

```
Daily Routines

[+ Create New Routine]

Active Routines (1/1 for Free, 1/5 for Premium):
─────────────────────────────
☑ My Daily Essentials
  Sleep • Eat Breakfast • Work • Exercise
  Active until: Nov 30, 2025
  [Edit] [Archive]

☐ Morning Workout
  (Archived - can reactivate)
  [Reactivate]

☐ Weekend Routine
  (Archived - can reactivate)
  [Reactivate]
```

**Routine Editor:**

- Edit task templates (title, time, duration, priority, category)
- Toggle routine active/inactive
- Change duration (extend or shorten)
- Archive routine (keeps tasks visible for 30 days, then archives)

---

## Feature Gating Implementation

### Guest Mode Checks

```swift
func canCreateTask() -> Bool {
    if isGuest {
        return createdTaskCount < 1
    }
    return true
}

func canCreateTaskBlock() -> Bool {
    return !isGuest
}

func canUseTimeline() -> Bool {
    return !isGuest
}
```

### Free Tier Daily Limit Checks

```swift
func canCreateTask() -> Bool {
    if subscriptionStatus == .free {
        let today = Calendar.current.startOfDay(for: Date())
        let todayTasks = tasks.filter { task in
            Calendar.current.isDate(task.startTime, inSameDayAs: today)
        }
        let todayBlocks = taskBlocks.filter { block in
            Calendar.current.isDate(block.createdDate, inSameDayAs: today)
        }
        return (todayTasks.count + todayBlocks.count) < 3
    }
    return true // Premium: unlimited
}
```

### Routine Limit Checks

```swift
func canCreateRoutine() -> Bool {
    if isGuest {
        return false
    }
    if subscriptionStatus == .free {
        let activeRoutines = routines.filter { $0.isActive }
        return activeRoutines.count < 1
    }
    // Premium: up to 5
    let activeRoutines = routines.filter { $0.isActive }
    return activeRoutines.count < 5
}
```

---

## Cloud Functions Required

1. **`updateLeaderboardScore(uid, scoreDelta)`**
   - Atomically updates `users/{uid}.globalLeaderboardScore`
   - Aggregates weekly leaderboard in `leaderboards/global_by_week/{YYYY-WW}`
   - Called periodically (every few minutes) or on app background

2. **`aggregateWeeklyLeaderboard()`** (Cron - Weekly)
   - Runs every Monday at 00:00 UTC
   - Computes global rankings from `users/{uid}.globalLeaderboardScore`
   - Writes to `leaderboards/global_by_week/{YYYY-WW}`
   - Resets `weeklyProductivityScore` for all users

3. **`syncGamificationStats(uid, stats)`**
   - Updates `users/{uid}` with latest XP, crystals, level, momentum
   - Called from client in background (batched writes)

4. **`grantThemeForMood(uid, themeId)`**
   - Verifies mood jar thresholds met
   - Grants theme unlock in `users/{uid}.ownedThemeIDs`

5. **`verifyPurchase(uid, receipt)`**
   - Validates IAP receipt with Apple
   - Updates `users/{uid}.subscriptionStatus`
   - Grants entitlements

6. **`checkTrialStatus(uid)`**
   - Verifies trial eligibility and expiration
   - Returns trial status to client

---

## Implementation Phases

### Phase 1: Hybrid Architecture Foundation (Week 1)

- [ ] Initialize Firebase (Auth, Firestore, Storage, Analytics)
- [ ] Create `FirebaseAuthService` (replace old OAuth)
- [ ] Create `FirestoreService` for gamification sync
- [ ] Update `User` model to sync stats to Firestore (background)
- [ ] Implement guest mode detection and limits
- [ ] Add feature gating checks throughout app

---

### Phase 2: Routine System (Week 2)

- [ ] Create `DailyRoutine` SwiftData model
- [ ] Create `RoutineTaskTemplate` struct
- [ ] Implement routine creation UI
- [ ] Implement task generation from templates (pre-generate strategy)
- [ ] Add routine duration logic ("till month end" vs "30 days")
- [ ] Implement routine archival (after grace period)
- [ ] Add routine switcher UI in Settings (premium gating)

---

### Phase 3: Guest Mode & Limits (Week 2-3)

- [ ] Implement 1-task limit for guests
- [ ] Add login prompt after 1st task
- [ ] Implement 3/day limit for free tier
- [ ] Add paywall triggers (after 3 tasks, 2nd routine attempt)
- [ ] Create `PaywallView` with tier comparison
- [ ] Implement guest → logged-in data migration

---

### Phase 4: Onboarding Flow (Week 3)

- [ ] Create `OnboardingView` with multi-step flow
- [ ] Implement Step 1: Quick Win (first task)
- [ ] Implement Step 2: Feature Tour (skippable)
- [ ] Implement Step 3: Routines Setup (with defaults: sleep, eat)
- [ ] Implement Step 4: Theme Selection
- [ ] Implement Step 5: Mood Jar Introduction
- [ ] Implement Step 6: Account Prompt (guest only)
- [ ] Add onboarding completion tracking

---

### Phase 5: Cloud Sync (Week 4)

- [ ] Implement background gamification sync (every 30s or on background)
- [ ] Implement mood events sync to Firestore
- [ ] Implement theme unlocks sync
- [ ] Implement leaderboard score updates (Cloud Function calls)
- [ ] Add "Sync Now" button in Settings
- [ ] Add sync status indicator (synced/pending/error)

---

### Phase 6: Leaderboards (Week 4-5)

- [ ] Create Cloud Function: `updateLeaderboardScore`
- [ ] Create Cloud Function: `aggregateWeeklyLeaderboard` (cron)
- [ ] Implement leaderboard fetch from Firestore
- [ ] Create `LeaderboardView` (read-only, cached)
- [ ] Add weekly reset countdown timer

---

### Phase 7: Subscription & IAP (Week 5)

- [ ] Create `SubscriptionService` (StoreKit 2)
- [ ] Implement IAP purchase flow
- [ ] Create Cloud Function: `verifyPurchase`
- [ ] Implement subscription status sync
- [ ] Add subscription management UI (Settings)
- [ ] Implement feature gating based on subscription

---

### Phase 8: Testing & Polish (Week 6)

- [ ] Test guest mode limits (1 task)
- [ ] Test free tier limits (3/day)
- [ ] Test routine generation (performance)
- [ ] Test routine archival
- [ ] Test cloud sync (background, offline scenarios)
- [ ] Test leaderboard updates
- [ ] Test subscription flow
- [ ] Performance optimization (routine task queries)
- [ ] Security rules review

---

## Key Files to Create/Modify

### New Services

- `Services/FirebaseAuthService.swift` - Firebase Auth wrapper
- `Services/FirestoreService.swift` - Firestore operations (gamification sync)
- `Services/RoutineService.swift` - Routine management, task generation
- `Services/SubscriptionService.swift` - IAP and subscription management
- `Services/GuestModeService.swift` - Guest mode limits and checks

### New Models

- `Models/DailyRoutine.swift` - Routine template model (SwiftData)
- `Models/RoutineTaskTemplate.swift` - Template struct (Codable)

### New Views

- `Views/OnboardingView.swift` - Multi-step onboarding
- `Views/RoutineSetupView.swift` - Routine creation UI
- `Views/RoutineEditorView.swift` - Edit routine templates
- `Views/PaywallView.swift` - Subscription purchase
- `Views/GuestModeBanner.swift` - Account creation prompts

### Modified Files

- `TimeFlowApp.swift` - Initialize Firebase, guest mode detection
- `Models/User.swift` - Add routine count, subscription status
- `Models/Task.swift` - Add `isRoutineTask`, `routineID` fields (already exists)
- `Views/HomeDashboardView.swift` - Add guest/free limit checks
- `Views/SettingsView.swift` - Add routine management UI

---

## Security Rules Highlights

### Firestore Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users: owner-only read/write
    match /users/{uid} {
      allow read, write: if request.auth != null && request.auth.uid == uid;
    }
    
    // Mood events: owner-only
    match /users/{uid}/moodEvents/{eventId} {
      allow read, write: if request.auth != null && request.auth.uid == uid;
    }
    
    // Leaderboards: public read, Cloud Function write-only
    match /leaderboards/{document=**} {
      allow read: if true;
      allow write: if false; // Only Cloud Functions can write
    }
    
    // Themes: public read, admin write
    match /themes/{themeId} {
      allow read: if true;
      allow write: if request.auth.token.admin == true;
    }
  }
}
```

### Storage Rules

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // User files: owner-only
    match /user_files/{uid}/{allPaths=**} {
      allow read, write: if request.auth != null && request.auth.uid == uid;
    }
    
    // Themes: public read
    match /themes/{themeId}/{allPaths=**} {
      allow read: if true;
      allow write: if request.auth.token.admin == true;
    }
  }
}
```

---

## Testing Strategy

1. **Guest Mode:**
   - Test 1-task limit
   - Test login prompt after 1st task
   - Test feature blocks (timeline, goals, routines)

2. **Free Tier:**
   - Test 3/day limit (tasks + blocks combined)
   - Test paywall triggers
   - Test 1-routine limit

3. **Routines:**
   - Test task generation (performance with 30+ days)
   - Test "till month end" vs "30 days" duration
   - Test routine archival after grace period
   - Test routine switcher (premium feature)

4. **Cloud Sync:**
   - Test background sync (gamification stats)
   - Test offline mode (local works, syncs on reconnect)
   - Test mood events sync
   - Test leaderboard updates

5. **Performance:**
   - Test routine task queries (filter by `routineID`)
   - Test task list rendering with 100+ routine tasks
   - Test SwiftData query performance

---

## Documentation

Create `FIREBASE_SETUP.md` with:
- Firebase project setup
- iOS app configuration
- Security rules deployment
- Cloud Functions deployment
- Testing with emulator

---

## Checklist Summary

### Immediate Priority

- [ ] Revise plan based on hybrid architecture
- [ ] Design `DailyRoutine` model (template-based, performance-optimized)
- [ ] Implement routine storage format (prevents slow rendering)
- [ ] Update guest mode limits (1 task only)
- [ ] Update free tier limits (3/day)
- [ ] Update onboarding flow (routines with defaults: sleep, eat)
- [ ] Remove "Havi" mascot references (placeholder until chosen)

### Next Steps

- [ ] Create Firebase project and initialize in app
- [ ] Implement `DailyRoutine` SwiftData model
- [ ] Implement routine task generation (pre-generate strategy)
- [ ] Implement guest mode checks
- [ ] Implement free tier daily limits
- [ ] Create onboarding flow with routine setup
- [ ] Implement cloud sync for gamification stats

---

**Status:** Ready for implementation. All architecture decisions finalized.

