# Plan Revision Summary - Hybrid Architecture

## Key Changes Made

### 1. **Hybrid Architecture (NOT Full Migration)**

**Before:** Migrate everything to Firebase Firestore  
**After:** Keep SwiftData for local data, sync only gamification stats to Firebase

**Local (SwiftData):**
- ✅ Tasks (all task data)
- ✅ Task Blocks
- ✅ Goals & Milestones
- ✅ Daily Routines (NEW - template-based)
- ✅ Reflection Entries
- ✅ Calendar Events (EventKit)

**Cloud (Firebase - Background Sync):**
- ✅ Gamification stats (XP, crystals, level, momentum) - `users/{uid}`
- ✅ Mood events (for leaderboards) - `users/{uid}/moodEvents`
- ✅ Theme unlocks (for cross-device) - `users/{uid}.ownedThemeIDs`
- ✅ Leaderboards (read-only) - `leaderboards/global_by_week`
- ✅ Themes metadata (public read) - `themes/{themeId}`

---

### 2. **Guest Mode (MUCH Stricter)**

**Before:** 15 tasks/day, 3 task blocks, 2 goals  
**After:** **1 task only**, then login required

**New Guest Limits:**
- ❌ Only 1 task creation allowed
- ❌ Cannot create task blocks
- ❌ Cannot use timeline (create/edit)
- ❌ Cannot create goals
- ❌ Routines skipped in onboarding
- ✅ View gamification stats (local only, not synced)
- ✅ View themes (read-only)

**Trigger After 1 Task:**
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

---

### 3. **Free Tier (Stricter Daily Limits)**

**Before:** Unlimited tasks, unlimited goals  
**After:** **3 tasks OR task blocks per day** (combined limit)

**New Free Tier Limits:**
- ✅ **3 tasks/task blocks per day** (combined, resets at midnight)
- ✅ After 3 items → **Paywall prompt**
- ✅ **1 active daily routine** (can create multiple, but only 1 active)
- ✅ AI insights: **3 per week**
- ✅ Everything else unlimited (viewing, editing, completion, goals)

**Paywall Triggers:**
1. After 3 tasks/blocks created in a day
2. When trying to create 4th task
3. When trying to create 2nd routine
4. When Attempting to view more AI Insights
---

### 4. **Routine Definition (CORRECTED)**

**Before:** Routine = Monthly task blocks  
**After:** **Routine = Daily recurring tasks** (sleep, eat, brush teeth, job, etc.)

**New Routine Concept:**
- **Routine = Daily recurring tasks** you do every day
- **NOT task blocks** (those are separate)
- Default routines: **sleep, eat** (with default notifications)
- User can customize: add job, brush teeth, exercise, etc.
- Runs daily (not monthly)
- User choice: **"till end of month"** OR **"30 days"** when starting

**Storage Format:**
- Template-based (not individual task instances)
- See `ROUTINE_STORAGE_FORMAT.md` for details
- Pre-generation strategy (prevents slow rendering)

---

### 5. **Onboarding Flow (Revised)**

**Step 3: Routines Setup (Revised)**

**Before:** Generic routine templates  
**After:** Daily routine setup with **defaults: sleep, eat**

**New Routine Setup:**
- Pre-filled default routines:
  - **"Sleep"** (10:00 PM - 7:00 AM, 9 hours, with default notifications)
  - **"Eat Breakfast"** (8:00 AM, 30 min, default notifications)
  - **"Eat Lunch"** (12:00 PM, 30 min, default notifications)
  - **"Eat Dinner"** (6:00 PM, 45 min, default notifications)
- User can:
  - ✅ Toggle defaults on/off
  - ✅ Add custom items (job, brush teeth, etc.)
  - ✅ Edit times/durations
  - ✅ Skip setup (can add later)
- Duration selection:
  - **"Till End of Month"** (recommended)
  - **"30 Days"** (or custom: 15, 45, 60 days)

**Also:**
- **NO MASCOT YET** (placeholder until chosen)
- Guest mode skips routine setup entirely

---

### 6. **Routine Storage Format (Performance Optimized)**

**Problem:** How to store routines without slow rendering

**Solution:** Template-based with pre-generation

**Storage Format:**
- `DailyRoutine` SwiftData model stores templates (not tasks)
- `RoutineTaskTemplate` struct (JSON-encoded array)
- Tasks generated from templates upfront (pre-generation)
- Batch insert for performance
- SwiftData indexes for fast queries

**See `ROUTINE_STORAGE_FORMAT.md` for full details.**

---

### 7. **Subscription Tiers (Revised)**

**Haven+ ($6.99/month or $59.99/year)**
- Everything in Free
- ✅ Unlimited daily tasks/task blocks
- ✅ **Multiple daily routines** (up to 5 active)
- ✅ Auto-routine updates
- ✅ Unlimited AI insights
- ✅ Premium themes (5 additional)
- ✅ Advanced analytics

**Haven Pro ($9.99/month or $79.99/year)**
- Everything in Haven+
- ✅ Personalized AI model
- ✅ Mood-to-theme sync
- ✅ Unlimited cloud backups
- ✅ Offline AI model
- ✅ All premium themes
- ✅ Advanced leaderboard filters

**Haven Forever ($99.99 one-time)**
- Lifetime access to all Pro features

---

### 8. **Sync Strategy (Background Only)**

**Gamification Stats Sync:**
- Local: Award XP/crystals **instantly** (no wait)
- Background: Sync to Firestore every 30s or on app background
- **Never blocks UI**

**Mood Events Sync:**
- Immediate sync to Firestore (lightweight writes)

**Theme Unlocks Sync:**
- Background sync to Firestore (for cross-device)

**Leaderboard Updates:**
- Periodic calls to Cloud Function (every few minutes)
- Cloud Function atomically updates leaderboard cache
- Leaderboard view reads from Firestore (read-only, cached)

---

## New Files Created

1. **`FIREBASE_HYBRID_ARCHITECTURE.md`**
   - Complete hybrid architecture plan
   - Local vs Cloud data separation
   - Sync strategies
   - Feature gating implementation
   - Security rules

2. **`ROUTINE_STORAGE_FORMAT.md`**
   - Routine storage format details
   - Pre-generation strategy
   - Performance optimization
   - Query filtering strategies
   - Archival logic

3. **`PLAN_REVISION_SUMMARY.md`** (this file)
   - Summary of all changes

---

## Implementation Checklist

### Immediate Priority

- [ ] Review `FIREBASE_HYBRID_ARCHITECTURE.md`
- [ ] Review `ROUTINE_STORAGE_FORMAT.md`
- [ ] Design `DailyRoutine` SwiftData model (template-based)
- [ ] Implement routine storage format (prevents slow rendering)
- [ ] Update guest mode limits (1 task only)
- [ ] Update free tier limits (3/day)
- [ ] Update onboarding flow (routines with defaults: sleep, eat)
- [ ] Remove "Havi" mascot references (placeholder until chosen)

### Next Steps

- [ ] Create Firebase project and initialize in app
- [ ] Implement `DailyRoutine` SwiftData model
- [ ] Implement routine task generation (pre-generation strategy)
- [ ] Implement guest mode checks
- [ ] Implement free tier daily limits
- [ ] Create onboarding flow with routine setup
- [ ] Implement cloud sync for gamification stats (background)

---

## Key Takeaways

1. **Hybrid Architecture**: SwiftData for local (tasks, routines, goals), Firebase for cloud (gamification, leaderboards, themes)

2. **Stricter Limits**: Guest = 1 task only, Free = 3/day, Premium = unlimited

3. **Routine = Daily Tasks**: Sleep, eat, job, brush teeth, etc. (NOT task blocks)

4. **Template-Based Storage**: Routines store templates, generate tasks upfront (prevents slow rendering)

5. **Background Sync**: Gamification stats sync in background, never blocks UI

6. **No Mascot Yet**: Placeholder until chosen

---

**Status:** All revisions complete. Ready for implementation.

**Next:** Review both new documents and begin implementation.

