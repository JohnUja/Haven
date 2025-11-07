# Next Phases Implementation Plan - Detailed

## ✅ Completed (Current Status)

### Phase 1: Firebase Authentication ✅
- [x] Firebase Auth integration
- [x] Apple Sign-In
- [x] Google Sign-In
- [x] Game Center Sign-In
- [x] Email/Password Sign-In
- [x] Guest Mode (Anonymous Auth)
- [x] Developer/Test Account System
- [x] User profile management
- [x] Sign out functionality

### Phase 2: Core UI & Features ✅
- [x] Infinite Day Selector with haptic feedback
- [x] Calendar integration (bidirectional sync)
- [x] Task management (create, edit, complete)
- [x] Task blocks
- [x] Goals system
- [x] Gamification system (XP, levels, crystals)
- [x] Level-up animations
- [x] Developer mode for testing

---

## 🚀 Next Phases (In Order)

### **Phase 5: Routines System** (Priority 1)

**Goal:** Implement daily recurring tasks (sleep, eat, job, brush teeth, etc.)

#### 5.1: Create DailyRoutine Model
**File:** `Haven2.0/Models/DailyRoutine.swift`

**Implementation:**
```swift
@Model
final class DailyRoutine {
    var id: String
    var userID: String
    var title: String
    var isActive: Bool
    var isDefault: Bool // For sleep/eat defaults
    var durationTypeRaw: String // "tillMonthEnd" or "days"
    var durationDays: Int?
    var startDate: Date
    var endDate: Date?
    var taskTemplatesJSON: Data // JSON-encoded [RoutineTaskTemplate]
    var notificationEnabled: Bool
    var createdAt: Date
    var updatedAt: Date
    var archivedAt: Date?
}
```

**Tasks:**
- [ ] Create `DailyRoutine.swift` model
- [ ] Create `RoutineTaskTemplate.swift` struct (Codable)
- [ ] Create `RoutineDurationType` enum
- [ ] Add computed properties for `taskTemplates` and `durationType`
- [ ] Add to SwiftData schema in `TimeFlowApp.swift`

**Estimated Time:** 1-2 hours

---

#### 5.2: Create RoutineService
**File:** `Haven2.0/Services/RoutineService.swift`

**Key Methods:**
```swift
class RoutineService {
    // Generate tasks from routine template (pre-generation)
    static func generateTasksFromRoutine(_ routine: DailyRoutine, in context: ModelContext) async
    
    // Create default routines (sleep, eat)
    static func createDefaultRoutines(userID: String, context: ModelContext) async -> [DailyRoutine]
    
    // Archive expired routines (after 30 days grace period)
    static func archiveExpiredRoutines(context: ModelContext) async
    
    // Check if routine needs task generation
    static func needsTaskGeneration(_ routine: DailyRoutine, for date: Date) -> Bool
}
```

**Tasks:**
- [ ] Create `RoutineService.swift`
- [ ] Implement `generateTasksFromRoutine()` - pre-generate all tasks upfront
- [ ] Implement `createDefaultRoutines()` - sleep (10 PM - 7 AM), eat (3 meals)
- [ ] Implement `archiveExpiredRoutines()` - mark expired routines as archived
- [ ] Add batch insert logic for performance
- [ ] Add date range calculation (till month end vs 30 days)

**Estimated Time:** 3-4 hours

---

#### 5.3: Create Routine Setup UI
**File:** `Haven2.0/Views/RoutineSetupView.swift`

**Features:**
- Pre-filled default routines (sleep, eat breakfast/lunch/dinner)
- Toggle defaults on/off
- Add custom routine items (job, brush teeth, etc.)
- Edit times/durations
- Duration selection: "Till End of Month" or "30 Days"
- Skip option

**UI Structure:**
```
┌─────────────────────────────┐
│  Set Up Your Daily Routine  │
├─────────────────────────────┤
│  Default Routines:          │
│  ☑ Sleep (10 PM - 7 AM)    │
│  ☑ Eat Breakfast (8 AM)    │
│  ☑ Eat Lunch (12 PM)       │
│  ☑ Eat Dinner (6 PM)       │
│                             │
│  [+ Add Custom Routine]     │
│                             │
│  Duration:                  │
│  ○ Till End of Month        │
│  ● 30 Days                  │
│                             │
│  [Skip] [Continue]         │
└─────────────────────────────┘
```

**Tasks:**
- [ ] Create `RoutineSetupView.swift`
- [ ] Create default routine templates
- [ ] Add toggle switches for defaults
- [ ] Add "Add Custom Routine" button
- [ ] Create `RoutineEditorView.swift` for editing individual routines
- [ ] Add duration picker (till month end vs days)
- [ ] Implement save logic (calls `RoutineService.generateTasksFromRoutine()`)
- [ ] Add skip functionality

**Estimated Time:** 4-5 hours

---

#### 5.4: Integrate Routines into Onboarding
**File:** `Haven2.0/Views/OnboardingView.swift`

**Flow:**
1. Welcome screen
2. Quick win (create first task)
3. Feature tour (optional, skippable)
4. **Routine Setup** ← New step
5. Theme selection
6. Mood jar introduction
7. Account prompt (guest only)

**Tasks:**
- [ ] Create `OnboardingView.swift` with multi-step flow
- [ ] Add routine setup as Step 3
- [ ] Integrate `RoutineSetupView` into onboarding
- [ ] Add progress indicator (Step 3 of 7)
- [ ] Add navigation (Next/Back buttons)
- [ ] Skip routine setup for guest mode
- [ ] Save onboarding completion status

**Estimated Time:** 3-4 hours

---

#### 5.5: Routine Management in Settings
**File:** `Haven2.0/Views/SettingsView.swift` or new `RoutineManagementView.swift`

**Features:**
- View all routines (active and archived)
- Edit routine templates
- Toggle routine active/inactive
- Delete routine (with confirmation)
- Create new routine
- Switch between multiple routines (premium feature - gate with subscription check)

**Tasks:**
- [ ] Create `RoutineManagementView.swift`
- [ ] Add routine list (active routines first)
- [ ] Add edit routine functionality
- [ ] Add delete routine (with confirmation)
- [ ] Add "Create New Routine" button
- [ ] Implement routine switcher (premium gating)
- [ ] Add to Settings → "Routines" section

**Estimated Time:** 3-4 hours

---

#### 5.6: Routine Task Display
**Files:** `Haven2.0/Views/HomeDashboardView.swift`, `Haven2.0/Views/TimelineView.swift`

**Features:**
- Display routine tasks in task list (with routine indicator)
- Show routine tasks on timeline
- Routine tasks are locked (cannot delete/move) - settings override only
- Visual distinction (different color/badge)

**Tasks:**
- [ ] Update `HomeDashboardView` to show routine tasks
- [ ] Add routine task indicator (badge/icon)
- [ ] Update `TimelineView` to display routine tasks
- [ ] Add lock icon for routine tasks
- [ ] Prevent deletion/moving of routine tasks (except via settings)
- [ ] Add routine task styling (different background color)

**Estimated Time:** 2-3 hours

---

**Phase 5 Total Estimated Time:** 16-22 hours

---

### **Phase 3: Guest Mode & Free Tier Limits** (Priority 2)

**Goal:** Enforce strict limits for guest and free tier users

#### 3.1: Guest Mode Limits (1 Task Only)
**Files:** `Haven2.0/Services/GuestModeService.swift`, `Haven2.0/Views/AddTaskView.swift`

**Implementation:**
- Guest can create only 1 task
- After 1st task, show login prompt
- Block timeline editing for guests
- Block goal creation for guests
- Block routine setup for guests

**Tasks:**
- [ ] Update `GuestModeService` to track task count
- [ ] Add check in `AddTaskView` before allowing task creation
- [ ] Create `GuestLoginPromptView.swift` (modal)
- [ ] Show prompt after 1st task creation
- [ ] Block timeline editing for guests
- [ ] Block goal creation for guests
- [ ] Block routine access for guests
- [ ] Add feature gates throughout app

**Estimated Time:** 2-3 hours

---

#### 3.2: Free Tier Limits (3 Tasks/Blocks Per Day)
**File:** `Haven2.0/Services/FreeTierService.swift` (new)

**Implementation:**
- Track daily task/block creation count
- Reset at midnight
- Show paywall after 3rd creation
- Combined limit (tasks + task blocks = 3 total)

**Tasks:**
- [ ] Create `FreeTierService.swift`
- [ ] Track daily creation count (UserDefaults or SwiftData)
- [ ] Add reset logic (midnight check)
- [ ] Add check in `AddTaskView` and task block creation
- [ ] Create `PaywallView.swift` with tier comparison
- [ ] Show paywall after 3rd creation
- [ ] Add "Upgrade" button in paywall
- [ ] Implement subscription check (for later IAP integration)

**Estimated Time:** 3-4 hours

---

#### 3.3: Paywall UI
**File:** `Haven2.0/Views/PaywallView.swift`

**Features:**
- Tier comparison table
- Feature highlights
- Pricing display
- "Upgrade" buttons (will connect to IAP later)
- "Maybe Later" option

**UI Structure:**
```
┌─────────────────────────────┐
│  Unlock Full Haven          │
├─────────────────────────────┤
│  Free          Haven+       │
│  3/day         Unlimited    │
│  1 routine    5 routines    │
│  3 AI/week    Unlimited AI  │
│                             │
│  [Upgrade to Haven+]        │
│  $6.99/month or $59.99/year │
│                             │
│  [Maybe Later]              │
└─────────────────────────────┘
```

**Tasks:**
- [ ] Create `PaywallView.swift`
- [ ] Design tier comparison UI
- [ ] Add feature highlights
- [ ] Add pricing display
- [ ] Add "Upgrade" buttons (placeholder for IAP)
- [ ] Add "Maybe Later" dismiss option
- [ ] Add animations/transitions

**Estimated Time:** 2-3 hours

---

**Phase 3 Total Estimated Time:** 7-10 hours

---

### **Phase 4: Cloud Sync (Storage)** (Priority 3)

**Goal:** Sync gamification stats, themes, and moods to Firebase

#### 4.1: Firestore Service
**File:** `Haven2.0/Services/FirestoreService.swift` (already exists, needs completion)

**Key Methods:**
```swift
class FirestoreService {
    // Create or update user document
    static func createOrUpdateUser(user: User, firebaseUID: String) async throws
    
    // Sync gamification stats (background)
    static func syncGamificationStats(user: User, firebaseUID: String) async throws
    
    // Sync theme unlocks
    static func syncThemeUnlocks(user: User, firebaseUID: String) async throws
    
    // Sync mood event
    static func syncMoodEvent(moodEntry: MoodEntry, firebaseUID: String) async throws
    
    // Update mood jar summary
    static func updateMoodJarSummary(user: User, firebaseUID: String) async throws
}
```

**Tasks:**
- [ ] Complete `FirestoreService.swift` implementation
- [ ] Add user document structure
- [ ] Implement `syncGamificationStats()` - background sync every 30s
- [ ] Implement `syncThemeUnlocks()` - on theme unlock
- [ ] Implement `syncMoodEvent()` - on mood check-in
- [ ] Add error handling and retry logic
- [ ] Add sync status tracking

**Estimated Time:** 3-4 hours

---

#### 4.2: Background Sync Manager
**File:** `Haven2.0/Services/SyncManager.swift` (new)

**Implementation:**
- Background sync every 30 seconds (when app is active)
- Sync on app background
- Sync on app foreground
- Queue sync operations
- Track sync status (synced/pending/error)

**Tasks:**
- [ ] Create `SyncManager.swift`
- [ ] Implement background timer (30s interval)
- [ ] Add app lifecycle observers (background/foreground)
- [ ] Implement sync queue
- [ ] Add sync status tracking
- [ ] Add "Sync Now" functionality
- [ ] Add sync status indicator in UI

**Estimated Time:** 2-3 hours

---

#### 4.3: Sync Status UI
**Files:** `Haven2.0/Views/ProfileView.swift`, `Haven2.0/Views/Components/SyncStatusView.swift`

**Features:**
- Sync status indicator (synced/pending/error)
- "Sync Now" button
- Last sync time display
- Error message display (if sync fails)

**Tasks:**
- [ ] Create `SyncStatusView.swift` component
- [ ] Add sync status indicator to ProfileView
- [ ] Add "Sync Now" button
- [ ] Display last sync time
- [ ] Show error messages if sync fails
- [ ] Add sync animation/loading state

**Estimated Time:** 1-2 hours

---

**Phase 4 Total Estimated Time:** 6-9 hours

---

### **Phase 6: Onboarding Flow** (Priority 4)

**Goal:** Create complete onboarding experience

#### 6.1: Onboarding View Structure
**File:** `Haven2.0/Views/OnboardingView.swift`

**Steps:**
1. **Welcome** - App introduction
2. **Quick Win** - Create first task
3. **Feature Tour** - Optional, skippable tour of main features
4. **Routine Setup** - Daily routines (sleep, eat, etc.)
5. **Theme Selection** - Choose initial theme
6. **Mood Jar Intro** - Explain mood tracking
7. **Account Prompt** - Sign up (guest only)

**Tasks:**
- [ ] Create `OnboardingView.swift` with multi-step structure
- [ ] Add step indicator (progress bar)
- [ ] Add navigation (Next/Back buttons)
- [ ] Add skip functionality for optional steps
- [ ] Create individual step views
- [ ] Add onboarding completion tracking
- [ ] Show onboarding only on first launch

**Estimated Time:** 4-5 hours

---

#### 6.2: Individual Onboarding Steps
**Files:** 
- `Haven2.0/Views/Onboarding/WelcomeStepView.swift`
- `Haven2.0/Views/Onboarding/QuickWinStepView.swift`
- `Haven2.0/Views/Onboarding/FeatureTourStepView.swift`
- `Haven2.0/Views/Onboarding/RoutineSetupStepView.swift` (uses RoutineSetupView)
- `Haven2.0/Views/Onboarding/ThemeSelectionStepView.swift`
- `Haven2.0/Views/Onboarding/MoodJarIntroStepView.swift`
- `Haven2.0/Views/Onboarding/AccountPromptStepView.swift`

**Tasks:**
- [ ] Create WelcomeStepView (app introduction)
- [ ] Create QuickWinStepView (create first task)
- [ ] Create FeatureTourStepView (interactive tour)
- [ ] Integrate RoutineSetupView into onboarding
- [ ] Create ThemeSelectionStepView (theme picker)
- [ ] Create MoodJarIntroStepView (mood tracking explanation)
- [ ] Create AccountPromptStepView (sign up prompt for guests)

**Estimated Time:** 5-6 hours

---

#### 6.3: Onboarding Completion Tracking
**File:** `Haven2.0/Services/OnboardingService.swift` (new)

**Implementation:**
- Track onboarding completion status
- Store in UserDefaults or SwiftData
- Check on app launch
- Show onboarding only if not completed

**Tasks:**
- [ ] Create `OnboardingService.swift`
- [ ] Add completion tracking
- [ ] Add check in `TimeFlowApp.swift` on launch
- [ ] Show onboarding only if not completed
- [ ] Add "Skip Onboarding" option (for testing)

**Estimated Time:** 1 hour

---

**Phase 6 Total Estimated Time:** 10-12 hours

---

## 📋 Implementation Order (Recommended)

### Week 1: Routines System
1. **Day 1-2:** Create DailyRoutine model and RoutineService
2. **Day 3-4:** Create RoutineSetupView and routine management UI
3. **Day 5:** Integrate routines into app (display, locking, etc.)

### Week 2: Limits & Paywall
1. **Day 1:** Guest mode limits (1 task)
2. **Day 2:** Free tier limits (3/day)
3. **Day 3:** Paywall UI

### Week 3: Cloud Sync
1. **Day 1-2:** Complete FirestoreService
2. **Day 3:** Background sync manager
3. **Day 4:** Sync status UI

### Week 4: Onboarding
1. **Day 1-2:** Onboarding view structure
2. **Day 3-4:** Individual step views
3. **Day 5:** Testing and polish

---

## 🎯 Success Criteria

### Phase 5 (Routines):
- ✅ Users can create daily routines with default templates (sleep, eat)
- ✅ Routine tasks are pre-generated and display instantly
- ✅ Routine tasks are locked (cannot delete/move)
- ✅ Multiple routines supported (premium feature)
- ✅ Routine archival works after expiration

### Phase 3 (Limits):
- ✅ Guest mode limited to 1 task
- ✅ Free tier limited to 3 tasks/blocks per day
- ✅ Paywall appears after limits reached
- ✅ Feature gates work correctly

### Phase 4 (Cloud Sync):
- ✅ Gamification stats sync in background
- ✅ Theme unlocks sync to Firestore
- ✅ Mood events sync to Firestore
- ✅ Sync status visible in UI
- ✅ Offline mode works (local first, sync later)

### Phase 6 (Onboarding):
- ✅ Onboarding shows on first launch only
- ✅ All steps functional
- ✅ Routine setup integrated
- ✅ Guest mode skips routine setup
- ✅ Onboarding completion tracked

---

## 📝 Notes

1. **Routines First:** Implement routines before cloud sync (Phase 5 before Phase 4) as requested
2. **Performance:** Pre-generation strategy prevents slow rendering
3. **Testing:** Use developer mode to test all features quickly
4. **Incremental:** Implement and test each phase before moving to next

---

**Total Estimated Time:** 39-53 hours (approximately 2-3 weeks of focused development)

**Status:** Ready to begin Phase 5 (Routines System)

