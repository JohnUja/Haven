# Cloud vs Local Storage & Paywall Strategy - Haven 2.0

## Executive Summary

**Current Architecture:** Hybrid approach - Local-first (SwiftData) for core features, Cloud (Firebase) for gamification and social features.

**Paywall Status:** UI implemented, IAP integration pending. Three tiers: Free, Haven+, Haven Pro, Haven Forever.

---

## 1. Timeline: Cloud vs Local?

### **Recommendation: LOCAL ONLY**

**Why Local:**
- ✅ **Performance**: Instant rendering, zero latency
- ✅ **Offline-First**: Works completely offline
- ✅ **Privacy**: User data stays on device
- ✅ **Cost**: No cloud storage costs per task/timeline item
- ✅ **User Experience**: Native iOS feel (snappy, responsive)

**What Should Be Local:**
- All tasks and task blocks
- Timeline state and positions
- Task scheduling and recurrence
- Task-to-goal linking
- Task-to-block grouping
- Drag-and-drop positions
- Calendar integration (EventKit)

**What Could Be Cloud (Premium Feature):**
- **Backup & Sync** (Premium): Optional cloud backup of tasks for device migration
- **Cross-Device Sync** (Premium): Sync tasks across iPhone/iPad/Mac (if multi-platform)
- **Timeline Analytics** (Premium): Cloud-based analytics on task patterns

**Implementation:**
```swift
// Timeline stays local
@Query private var tasks: [Task]  // SwiftData (local)
@Query private var taskBlocks: [TaskBlock]  // SwiftData (local)

// Optional cloud backup (premium)
if isPremium {
    TaskBackupService.shared.syncToCloud(tasks: tasks)
}
```

---

## 2. Feature Classification: Cloud vs Local

### **LOCAL ONLY (Free & Premium)**

| Feature | Storage | Reason |
|---------|---------|--------|
| **Tasks** | Local (SwiftData) | Core feature, needs instant access |
| **Task Blocks** | Local (SwiftData) | Grouping logic, no cloud needed |
| **Goals** | Local (SwiftData) | Personal goals, privacy-sensitive |
| **Milestones** | Local (SwiftData) | Part of goals |
| **Reflections** | Local (SwiftData) | Personal journaling, privacy-critical |
| **Routines** | Local (SwiftData) | Daily patterns, local-first |
| **Timeline State** | Local (Memory/UserDefaults) | UI state, no persistence needed |
| **Calendar Events** | Local (EventKit) | System calendar, read-only |
| **Task Positions** | Local (SwiftData) | Drag-and-drop state |
| **Task Colors** | Local (SwiftData) | Customization, personal preference |

### **CLOUD ONLY (Gamification & Social)**

| Feature | Storage | Reason |
|---------|---------|--------|
| **User Profile** | Cloud (Firestore) | Cross-device, social features |
| **Gamification Stats** | Cloud (Firestore) | XP, crystals, momentum, weekly score |
| **Leaderboards** | Cloud (Firestore) | Global rankings, real-time updates |
| **Feed Posts** | Cloud (Firestore) | Social sharing, community |
| **Mood Entries** | Cloud (Firestore) | Analytics, pattern recognition |
| **Theme Ownership** | Cloud (Firestore) | Cross-device theme access |
| **Subscription Status** | Cloud (Firestore) | IAP verification, cross-device |

### **HYBRID (Local + Cloud Backup - Premium)**

| Feature | Primary | Backup | Premium Feature |
|---------|---------|--------|-----------------|
| **Tasks Backup** | Local | Cloud | ✅ Premium only |
| **Goals Backup** | Local | Cloud | ✅ Premium only |
| **Reflections Backup** | Local | Cloud | ✅ Premium only |
| **Routines Backup** | Local | Cloud | ✅ Premium only |

---

## 3. Paywall Strategy

### **Current Implementation Status**

**✅ Completed:**
- `PaywallView.swift` - Full UI with tier comparison
- `SubscriptionService.swift` - Tier checking logic
- Paywall triggers (task limit, routine limit, AI limit)
- Feature gating logic

**⏳ Pending:**
- StoreKit 2 integration (IAP)
- Subscription status sync to Firebase
- Subscription management UI
- Receipt validation
- Subscription renewal handling

### **Pricing Tiers**

#### **Free Tier**
**Price:** $0

**Limits:**
- Daily Tasks/Blocks: **3 per day**
- Active Routines: **1 routine**
- AI Insights: **3 per week**
- Premium Themes: **None** (default theme only)
- Cloud Backup: **❌**
- Cross-Device Sync: **❌**

**Best For:** Casual users, trying out the app

---

#### **Haven+ (Recommended)**
**Price:**
- Monthly: **$6.99/month**
- Yearly: **$59.99/year** (Save 28% = $4.99/month)

**Limits:**
- Daily Tasks/Blocks: **Unlimited**
- Active Routines: **Up to 5 routines**
- AI Insights: **Unlimited**
- Premium Themes: **5 premium themes included**
- Cloud Backup: **❌** (Local only)
- Cross-Device Sync: **❌**

**Best For:** Power users who want unlimited tasks and routines

---

#### **Haven Pro (Best Value)**
**Price:**
- Monthly: **$9.99/month**
- Yearly: **$79.99/year** (Save 33% = $6.66/month)

**Limits:**
- Daily Tasks/Blocks: **Unlimited**
- Active Routines: **Up to 5 routines**
- AI Insights: **Unlimited**
- Premium Themes: **All premium themes**
- Cloud Backup: **✅ Unlimited**
- Cross-Device Sync: **✅** (if multi-platform)
- Personalized AI: **✅**
- Mood-to-Theme Sync: **✅**
- Offline AI Model: **✅**

**Best For:** Users who want full experience with AI and cloud features

---

#### **Haven Forever (One-Time)**
**Price:** **$120 one-time payment**

**Includes:**
- Everything in Haven Pro
- **Lifetime access** (no renewal)
- **All future themes**
- **Lifetime updates**
- **Priority support**

**Break-Even:** ~12 months vs Haven Pro yearly

**Best For:** Long-term committed users

---

## 4. What Features Should Be Behind Paywall?

### **FREE FEATURES (Always Available)**

✅ **Core Task Management**
- Create up to 3 tasks/day
- Basic task properties (title, time, priority, category)
- Task completion
- Basic timeline view
- One routine

✅ **Basic Gamification**
- XP earning (limited)
- Time Crystals (limited earning)
- Basic momentum tracking
- Default theme

✅ **Basic Goals**
- Create goals
- Link tasks to goals
- Track progress
- Basic milestones

✅ **Mood Check-In**
- 3 check-ins per day
- All mood options
- Basic rewards

✅ **Reflections**
- Create reflections on goals
- All reflection features

---

### **PREMIUM FEATURES (Haven+ & Above)**

🔒 **Unlimited Tasks**
- Remove 3/day limit
- Unlimited task blocks
- Unlimited recurring tasks

🔒 **Multiple Routines**
- Up to 5 active routines
- Routine templates
- Routine switching

🔒 **Unlimited AI Insights**
- Remove 3/week limit
- Advanced AI recommendations
- Pattern analysis

🔒 **Premium Themes**
- 5 themes (Haven+)
- All themes (Haven Pro)
- Theme customization

---

### **PRO FEATURES (Haven Pro & Forever Only)**

🔒 **Cloud Backup & Sync**
- Automatic cloud backup
- Cross-device sync
- Backup history
- Restore from backup

🔒 **Personalized AI**
- AI learns your patterns
- Custom recommendations
- Predictive task suggestions
- Smart scheduling

🔒 **Mood-to-Theme Sync**
- Automatic theme changes based on mood
- Mood-based color schemes
- Dynamic UI adaptation

🔒 **Offline AI Model**
- AI works without internet
- On-device processing
- Privacy-focused AI

🔒 **Advanced Analytics**
- Detailed productivity reports
- Pattern recognition
- Trend analysis
- Export data

---

## 5. Paywall Triggers

### **When Paywall Appears:**

1. **Task Limit Reached**
   - User tries to create 4th task/block
   - Message: "You've reached the free limit of 3 tasks per day. Upgrade for unlimited tasks!"

2. **Routine Limit Reached**
   - User tries to create 2nd routine
   - Message: "Multiple routines are a premium feature. Upgrade to create up to 5 active routines!"

3. **AI Limit Reached**
   - User tries to use 4th AI insight
   - Message: "You've used all 3 AI insights this week. Upgrade for unlimited AI insights!"

4. **Premium Theme Access**
   - User tries to unlock premium theme
   - Message: "This theme requires Haven+ or higher"

5. **Cloud Backup Access**
   - User tries to enable cloud backup
   - Message: "Cloud backup is a Haven Pro feature"

6. **Manual Upgrade**
   - User taps "Upgrade Plan" in Profile
   - Shows full paywall with all tiers

---

## 6. Implementation Details

### **Subscription Status Storage**

**Firebase Firestore:**
```swift
users/{uid} {
    subscriptionStatus: "free" | "plus" | "pro" | "lifetime"
    subscriptionExpiresAt: Timestamp?
    subscriptionProductId: String?
    subscriptionReceipt: String?
}
```

**Local (UserDefaults):**
```swift
// Cache for offline checking
UserDefaults.standard.set(subscriptionStatus, forKey: "subscriptionStatus")
```

### **Feature Gating**

```swift
class SubscriptionService {
    func canCreateTask(tier: SubscriptionTier) -> Bool {
        switch tier {
        case .free:
            let todayTasks = getTodayTaskCount()
            return todayTasks < 3
        case .plus, .pro, .lifetime:
            return true // Unlimited
        }
    }
    
    func canCreateRoutine(tier: SubscriptionTier) -> Bool {
        switch tier {
        case .free:
            return getActiveRoutineCount() < 1
        case .plus, .pro, .lifetime:
            return getActiveRoutineCount() < 5
        }
    }
    
    func hasCloudBackup(tier: SubscriptionTier) -> Bool {
        return tier == .pro || tier == .lifetime
    }
}
```

### **Paywall Display Logic**

```swift
// In AddTaskView
if !SubscriptionService.shared.canCreateTask(tier: userTier) {
    showingPaywall = true
    paywallTrigger = .taskLimit
}

// In PaywallView
switch triggerReason {
case .taskLimit:
    highlightFeature("Unlimited Tasks")
case .routineLimit:
    highlightFeature("Multiple Routines")
case .aiLimit:
    highlightFeature("Unlimited AI")
}
```

---

## 7. Cloud Backup Implementation (Premium)

### **Architecture**

**Local First:**
- All tasks stored in SwiftData (local)
- User works offline, changes saved locally

**Cloud Backup (Premium):**
- Background sync to Firebase
- Encrypted backup
- Version history
- Restore capability

**Implementation:**
```swift
class TaskBackupService {
    // Premium feature check
    func canBackup() -> Bool {
        return SubscriptionService.shared.hasCloudBackup(tier: userTier)
    }
    
    // Sync tasks to cloud
    func syncToCloud(tasks: [Task]) async throws {
        guard canBackup() else {
            throw BackupError.premiumRequired
        }
        
        // Encrypt and upload
        let encrypted = encryptTasks(tasks)
        try await FirestoreService.shared.backupTasks(encrypted)
    }
    
    // Restore from cloud
    func restoreFromCloud() async throws -> [Task] {
        guard canBackup() else {
            throw BackupError.premiumRequired
        }
        
        let encrypted = try await FirestoreService.shared.getBackup()
        return decryptTasks(encrypted)
    }
}
```

---

## 8. Recommendations Summary

### **Timeline: LOCAL ONLY ✅**
- Keep timeline completely local
- No cloud sync needed
- Optional cloud backup for premium users (for device migration)

### **Core Features: LOCAL ✅**
- Tasks, Goals, Reflections, Routines → All local
- Privacy-focused
- Instant performance

### **Gamification: CLOUD ✅**
- XP, Crystals, Momentum → Cloud
- Leaderboards → Cloud
- Feed → Cloud

### **Premium Features:**
- **Haven+**: Unlimited tasks, multiple routines, premium themes
- **Haven Pro**: Everything + Cloud backup, AI features
- **Haven Forever**: Lifetime access

### **Paywall Triggers:**
- Task limit (3/day)
- Routine limit (1 routine)
- AI limit (3/week)
- Premium theme access
- Cloud backup access

---

## 9. Next Steps

1. **Complete IAP Integration**
   - StoreKit 2 setup
   - Product IDs configuration
   - Receipt validation
   - Subscription status sync

2. **Implement Cloud Backup (Premium)**
   - Task encryption
   - Firebase backup service
   - Restore functionality
   - Version history

3. **Add Feature Gating**
   - Check subscription status before premium features
   - Show paywall when limits reached
   - Disable premium features for free users

4. **Testing**
   - Test paywall triggers
   - Test subscription flow
   - Test feature gating
   - Test cloud backup/restore

---

*Last Updated: 2025-01-XX*
*Version: Haven 2.0*

