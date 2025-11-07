# Gamification System - Critical Fixes & XP Calculations

## ✅ COMPLETED CRITICAL FIXES

### 1. Remove Feature Unlocks ✅ DONE
**File:** `Haven2.0/Services/LevelService.swift` Lines 75-87
- **Removed:** All feature unlock code
- **Result:** ALL features (Goals, Journal, AI Insights, Analytics) now available to ALL users regardless of level
- **Status:** ✅ Implemented

### 2. Fix Theme Unlocks (Dynamic Query) ✅ DONE
**File:** `Haven2.0/Services/LevelService.swift` Lines 62-73
- **Before:** Hardcoded theme strings ("energetic", "calm", etc.)
- **After:** Dynamic query via `getUnlockedThemes(level:themes:)` helper function
- **Result:** Themes queried from Theme model based on `unlockLevel` property
- **Status:** ✅ Implemented

### 3. Fix XP Curve for 6-18 Month Progression ✅ DONE
**File:** `Haven2.0/Services/LevelService.swift` Lines 27-46
- **New Formula:** Tiered system
  - Levels 1-10: `150 × level^1.4`
  - Levels 11-25: `Base + 250 × (level-10)^1.5`
  - Levels 26-50: `Base + 500 × (level-25)^1.7`
- **Target:** Level 50 requires ~62,000 total cumulative XP
- **Daily Targets:**
  - Super Active (6 months): ~344 XP/day
  - Normal (18 months): ~113 XP/day
- **Status:** ✅ Implemented

### 4. Fix Level Up Screen Bug (Repeating Popup) ✅ DONE
**Files:**
- `Haven2.0/Views/HomeDashboardView.swift` Line 53, 473-486
- `Haven2.0/Views/HomeDashboardView.swift` Line 2047
- **Added:** `isShowingLevelUp` guard flag
- **Result:** Prevents multiple level-up popups from triggering
- **Status:** ✅ Implemented

### 5. Fix Journal Entry Animation Clash ✅ DONE
**File:** `Haven2.0/Views/HomeDashboardView.swift` (TaskCardView completion handler)
- **Before:** Journal prompt appeared immediately after task completion
- **After:** 3-second delay, only shows if reward/level-up animations complete
- **Status:** ✅ Implemented

### 6. Fix Momentum Icon Layout ✅ DONE
**File:** `Haven2.0/Views/HomeDashboardView.swift` Lines 781-792
- **Before:** Spacing 12, layout breaking
- **After:** Spacing 16, wrapper HStack with 8pt spacing for crystals and momentum
- **Status:** ✅ Implemented

### 7. Theme Shop Ordering ✅ DONE
**File:** `Haven2.0/Views/ProfileView.swift` Lines 289-334
- **Before:** Random theme order
- **After:** Grouped by type: Default → Level → Crystal → Mood → Achievement → IAP
- **Within groups:** Sorted appropriately (level by unlockLevel, crystal by price)
- **Status:** ✅ Implemented

---

## 🔴 TODO - High Priority

### 8. Settings Page Visual Hierarchy
**File:** `Haven2.0/Views/ProfileView.swift` Lines 101-106
- **Action:** Hide momentum bar behind icon, make popup on tap
- **Solution:** Convert MomentumView to Button with sheet popup
- **Status:** 🔴 NOT DONE

### 9. Time Crystals Icon
**File:** `Haven2.0/Views/Components/CrystalCounterView.swift` Line 26
- **Action:** Replace emoji with custom crystal icon/3D element
- **Solution:** Create custom Diamond shape or use better SF Symbol
- **Status:** 🔴 NOT DONE

### 10. Mood Jar Redesign (Individual Jars per Mood Type)
**File:** `Haven2.0/Views/MoodJarView.swift`
- **Action:** Replace single jar with 8-10 separate jars (one per mood type)
- **Requirements:**
  - Each jar holds 0-15 marbles of that mood type
  - "Cash In" button when jar reaches 15
  - Reward: 200-500 crystals + bonus XP
  - Jar resets to 0 after cash-in
- **Decision Needed:** Keep 8 moods or add 2 more (motivated, content)?
- **Status:** 🔴 NOT DONE

### 11. Smart Task Widget - "Add Reflection" Display
**File:** `Haven2.0/Views/Components/TaskCardView.swift`
- **Action:** When task completes, show "Add Reflection" container (only if goal-linked)
- **Solution:** Show centered reflection button after completion animation
- **Status:** 🔴 NOT DONE

### 12. Day Scroller Bug - Green Ring Not Updating
**File:** `Haven2.0/Views/Components/InfiniteDaySelector.swift`
- **Action:** Fix selectedDate binding to immediately update green ring
- **Status:** 🔴 NOT DONE

---

## XP Formula & Weekly Flow Analysis

### XP Curve (Updated)

**Formula:**
```swift
// Tiered system for 6-18 month progression to Level 50
Levels 1-10:  150 × level^1.4
Levels 11-25: Base + 250 × (level-10)^1.5  
Levels 26-50: Base + 500 × (level-25)^1.7

Level 50 Total XP: ~62,000 XP
```

**XP Progression by Level:**
- Level 1→2: 150 XP
- Level 5→6: 671 XP (total ~3,500 XP)
- Level 10→11: 1,581 XP (total ~11,000 XP)
- Level 25→26: 7,905 XP (total ~58,000 XP)
- Level 50: Requires ~62,000 total cumulative XP

**Daily Targets:**
- Super Active (6 months, ~180 days): ~344 XP/day
- Normal (18 months, ~547 days): ~113 XP/day
- Light Pace (75%): ~85 XP/day → Level 50 in ~16 months

### Typical Weekly Flow Example (3 Goals User)

**User Profile:**
- 3 goals: 1 short-term (1-2 weeks), 1 medium-term (1 month), 1 long-term (3 months)
- Mix of goal-linked and standalone tasks
- Consistent daily activity

**Week Breakdown:**

**Monday:**
- 5 tasks: 2 normal goal-linked, 1 urgent standalone, 1 high priority, 1 low priority
- Momentum: Day 5 (20% bonus)
- XP: 15 + 19.5 + 15 + 12.5 + 8 = 70 XP (×1.2 = 84 XP)
- Crystals: ~35
- Daily bonus: First task (+20 XP)

**Tuesday:**
- 4 tasks: 3 goal-linked (1 milestone), 1 normal standalone
- XP: 19.5 + 19.5 + 19.5 + 10 = 68 XP (×1.2 = 82 XP)
- Milestone bonus: +200 XP
- Crystals: ~50

**Wednesday:**
- 6 tasks: All goal-linked, mix of priorities
- Momentum: Day 7 (30% bonus)
- XP: 80 XP (×1.3 = 104 XP)
- 5+ task bonus: +50 XP
- Crystals: ~45

**Thursday:**
- 3 tasks: 2 goal-linked, 1 high priority
- XP: 60 XP (×1.3 = 78 XP)
- Crystals: ~30

**Friday:**
- 4 tasks: Goal completion day
- Goal completion bonus: +500 XP
- XP: 65 + 500 = 565 XP
- Crystals: ~60 + 200 = 260

**Saturday:**
- 2 tasks: Light day
- XP: 35 XP (×1.3 = 46 XP)
- Crystals: ~15

**Sunday:**
- 3 tasks: Planning/reflection
- XP: 45 XP (×1.3 = 59 XP)
- Crystals: ~20

**Weekly Totals:**
- Total XP: 84 + 282 + 154 + 78 + 565 + 46 + 59 = **~1,268 XP/week**
- Weekly crystal gain: **~455 crystals**
- Goal completions: 1 goal, 1 milestone
- Progress: ~4-5 levels for new users, ~1 level for established users

**Monthly Projection:**
- 4 weeks × 1,268 XP = **~5,072 XP/month**
- Super active (150%): ~7,608 XP/month → Level 50 in ~8 months ✓
- Normal pace: ~5,072 XP/month → Level 50 in ~12 months ✓
- Light pace (75%): ~3,804 XP/month → Level 50 in ~16 months ✓

**Goal Breakdown:**
- Short-term goal (1-2 weeks): ~200 XP when completed
- Medium-term goal (1 month): ~400 XP when completed  
- Long-term goal (3 months): ~600 XP when completed
- Milestone bonuses: +200 XP each
- Goal completion: +500 XP each

---

## Level Progression System Details

### How It Works

1. **XP is Permanent:** `currentXP` and `level` NEVER reset
2. **Weekly Reset:** Only `weeklyProductivityScore` resets (for leaderboards)
3. **Theme Unlocks:** 
   - Stored in `ownedThemeIDs` array (permanent)
   - Once unlocked, themes stay unlocked forever
   - No weekly reset affects themes
4. **Level Cap:** Level 50 is maximum (for now)

### Theme Unlock Logic

**Before (Hardcoded):**
```swift
switch newLevel {
    case 5: unlockedThemes.append("energetic")
    case 10: unlockedThemes.append("calm")
    // etc...
}
```

**After (Dynamic):**
```swift
// In ThemeShopView or level-up handler:
let unlockedThemes = LevelService.getUnlockedThemes(
    level: user.level,
    themes: allThemes
)
// Queries Theme model: unlockMethod == .level && unlockLevel <= user.level
```

### Feature Availability

**All features are available to ALL users:**
- Goals: ✅ Always available (removed Level 3 unlock)
- Journal: ✅ Always available (removed Level 7 unlock)
- AI Insights: ✅ Always available (removed Level 15 unlock)
- Advanced Analytics: ✅ Always available (removed Level 30 unlock)

---

## Mood Jar System Redesign Plan

### Current Implementation
- Single jar mixing all moods together
- Shows today's moods only

### Proposed Redesign
- **8 Individual Jars** (one per mood type: happy, sad, anxious, calm, energetic, tired, excited, frustrated)
- Each jar holds **0-15 marbles** of that specific mood type
- Visual representation: Glass jar with marbles filling from bottom
- **Cash In Feature:** When jar reaches 15 marbles:
  - Button appears: "Cash In" 
  - Reward: 200-500 crystals + 100-200 XP bonus
  - Jar resets to 0 after cash-in
  - Can cash in multiple jars in same day

### Questions to Decide
1. **Jar Count:** Keep 8 moods or add 2 more (motivated, content) = 10 total?
2. **Jar Reset:** After cash-in, does jar reset immediately or keep progress?
3. **Time Window:** Should jars track all-time moods or recent (last 30 days)?
4. **Reward Scaling:** Same reward for all jars, or different per mood type?

---

## Journal Entry Handling

### Current Behavior
- Journal entries stored with both `taskID` and `goalID`
- Entries persist even if task is disconnected from goal

### Recommendation
- **Keep entries as historical records** - Don't delete when task/goal disconnected
- Display logic:
  - Show entries by taskID (even if goalID is nil)
  - Show entries by goalID (even if task removed from goal)
  - Archive option: Soft delete if user wants to hide entries

### Disconnect Task from Goal
- **Status:** Not currently implemented
- **Need:** UI button to disconnect task from goal
- **Behavior:** Set `task.goalID = nil`, keep all journal entries and photos

---

## Next Steps Priority Order

1. ✅ Remove feature unlocks - DONE
2. ✅ Fix theme unlocks - DONE
3. ✅ Update XP curve - DONE
4. ✅ Fix level-up bug - DONE
5. ✅ Fix journal animation clash - DONE
6. ✅ Fix momentum layout - DONE
7. ✅ Theme shop ordering - DONE
8. 🔴 Settings momentum popup
9. 🔴 Crystal icon redesign
10. 🔴 Mood jar redesign
11. 🔴 Smart task widget reflection
12. 🔴 Day scroller bug fix

