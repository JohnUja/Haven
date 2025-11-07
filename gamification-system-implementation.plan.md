# Gamification System Implementation Plan

## Overview

Implement full gamification system with balanced rewards, mood tracking, leaderboards, and progression unlocks. Address bonus balance concerns and integrate mood jar system.

## ✅ COMPLETED PHASES

### Phase 1: Data Models & Core Services ✅
- User model updated with gamification fields
- MoodEntry model created
- GamificationService with reward calculations
- LevelService for level progression
- MoodJarService for mood tracking
- Theme model enhanced with unlock methods

### Phase 2: Balanced Reward Calculations ✅
- Time Crystal calculation (original higher values restored)
- XP calculation with momentum bonuses
- Productivity Score calculation
- All bonus systems implemented

### Phase 3: Mood Jar System ✅ (REDESIGNED)
- **REDESIGN:** Individual jars per mood type (8 jars, 15 marbles each)
- MoodJarView with separate jars
- MoodCheckInView for mood selection
- Cash-in system (350 crystals + 150 XP when jar reaches 15)

### Phase 4: Crystal & XP System Implementation ✅
- CrystalCounterView with animated counter and custom diamond icon
- RewardAnimationView for pop-up notifications
- XP progress display
- Integrated into task completion handlers

### Phase 5: Level Progression System ✅ (FIXED)
- **CRITICAL FIX:** Removed all feature unlocks - ALL features available to ALL users
- **FIXED:** XP curve updated for 6-18 month progression to Level 50
- **FIXED:** Dynamic theme unlocks via Theme model query (no hardcoded strings)
- LevelUpView with celebration animations
- Theme unlocks are permanent (stored in ownedThemeIDs array)

### Phase 6: Momentum System ✅
- Momentum tracking with graceful degradation
- MomentumView and CompactMomentumView components
- MomentumPopupView (settings popup) ✅ NEW

### Phase 7: Weekly Leaderboard System ✅
- LeaderboardService with productivity score calculation
- LeaderboardView with top 10 display
- Weekly reset countdown timer

### Phase 8: Theme Shop Implementation ✅ (ENHANCED)
- ThemeShopView with grouped themes by type
- Proper ordering: Default → Level → Crystal → Mood → Achievement → IAP
- Dynamic unlock checking

### Phase 9: UI Integration & Polish ✅ (PARTIAL)
- HomeDashboardView: Crystal counter, momentum indicator, XP progress ✅
- ProfileView: Level display, momentum popup, weekly score ✅
- Reward animations integrated ✅
- Level-up animations integrated ✅

## 🔴 REMAINING TODO

### Phase 10: Smart Task Widget - "Add Reflection" Display
**File:** `Haven2.0/Views/Components/TaskCardView.swift`
**Status:** 🔴 NOT DONE
**Implementation:**
- When task completes and is goal-linked, show "Add Reflection" container
- Display centered reflection button after completion animation
- Replace immediate journal sheet popup with in-card button

### Phase 11: Day Scroller Bug Fix
**File:** `Haven2.0/Views/Components/InfiniteDaySelector.swift`
**Status:** 🔴 NOT DONE
**Issue:** Green ring doesn't update immediately when clicking next day
**Fix:** Update selectedDate binding to trigger immediate UI update

### Phase 12: Calendar System Enhancement
**File:** `Haven2.0/Views/HomeDashboardView.swift`
**Status:** 🔴 DECISION NEEDED
**Option:** Add full month calendar view behind "NOV 2025" button
**Impact:** Minimal file size (~5-10KB)

## CRITICAL FIXES COMPLETED

### ✅ Remove Feature Unlocks
**Status:** COMPLETE
- Removed all feature unlock code from LevelService
- All features (Goals, Journal, AI Insights, Analytics) now available to ALL users

### ✅ Fix Theme Unlocks (Dynamic Query)
**Status:** COMPLETE
- Added `getUnlockedThemes()` helper function
- Themes queried dynamically from Theme model
- Auto-unlock themes when level reached

### ✅ Fix XP Curve for 6-18 Month Progression
**Status:** COMPLETE
- **New Formula:** Tiered system
  - Levels 1-10: `150 × level^1.4`
  - Levels 11-25: `Base + 250 × (level-10)^1.5`
  - Levels 26-50: `Base + 500 × (level-25)^1.7`
- **Level 50:** Requires ~62,000 total cumulative XP
- **Daily Targets:** Super active (344 XP/day), Normal (113 XP/day)

### ✅ Fix Level Up Screen Bug
**Status:** COMPLETE
- Added `isShowingLevelUp` guard flag
- Prevents multiple level-up popups

### ✅ Fix Journal Entry Animation Clash
**Status:** COMPLETE
- Journal prompt delayed 3 seconds after task completion
- Only shows if reward/level-up animations are done

### ✅ Fix Momentum Icon Layout
**Status:** COMPLETE
- Increased spacing from 12 to 16
- Added wrapper HStack with 8pt spacing

### ✅ Settings Momentum Popup
**Status:** COMPLETE
- Momentum bar hidden behind button in ProfileView
- MomentumPopupView shows full details on tap

### ✅ Crystal Icon Redesign
**Status:** COMPLETE
- Custom Diamond shape created
- Replaced emoji with 3D diamond icon
- Gradient fill with sparkle overlay

### ✅ Theme Shop Ordering
**Status:** COMPLETE
- Themes grouped by type
- Proper ordering: Default → Level → Crystal → Mood → Achievement → IAP
- Sorted within groups appropriately

### ✅ Mood Jar Redesign
**Status:** COMPLETE
- Individual jars per mood type (8 jars)
- Each jar holds 0-15 marbles
- Cash-in system (350 crystals + 150 XP when full)
- Jar resets after cash-in

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

## Level Progression System Details

### How It Works

1. **XP is Permanent:** `currentXP` and `level` NEVER reset
2. **Weekly Reset:** Only `weeklyProductivityScore` resets (for leaderboards)
3. **Theme Unlocks:** 
   - Stored in `ownedThemeIDs` array (permanent)
   - Once unlocked, themes stay unlocked forever
   - No weekly reset affects themes
4. **Level Cap:** Level 50 is maximum (for now)
5. **NO Feature Unlocks:** All features available to all users

### Theme Unlock Logic

**Dynamic Query:**
```swift
// In ThemeShopView or level-up handler:
let unlockedThemes = LevelService.getUnlockedThemes(
    level: user.level,
    themes: allThemes
)
// Queries Theme model: unlockMethod == .level && unlockLevel <= user.level
```

Themes are automatically unlocked when user reaches required level and stored permanently.

## Mood Jar System Redesign

### Implementation
- **8 Individual Jars** (one per mood type)
- Each jar holds **0-15 marbles** of that specific mood type
- Visual: Glass jar containers with marbles filling from bottom
- **Cash In Feature:** 
  - Button appears when jar reaches 15 marbles
  - Reward: 350 crystals + 150 XP
  - Jar resets to 0 after cash-in
  - Can cash in multiple jars in same day

### Mood Types
Currently 8 moods: happy, sad, anxious, calm, energetic, tired, excited, frustrated

**Optional Addition:** Could add 2 more (motivated, content) = 10 total

## Implementation Notes

### Journal Entry Handling
- Entries stored with both `taskID` and `goalID`
- Entries persist even if task disconnected from goal (historical records)
- When task disconnected: Set `task.goalID = nil`, keep all journal entries and photos

### Level Progression
- Level 50 should take 6-18 months based on activity level
- XP curve designed to balance progression
- Themes unlocked permanently once level reached
- All features always available (no level gates)

## Testing Considerations

- Test reward calculations with various task combinations
- Verify weekly reset logic (only productivity score, not XP/level)
- Test mood jar time windows
- Verify theme unlock conditions (dynamic query)
- Test leaderboard scoring accuracy
- Validate privacy settings
- Test momentum degradation logic
- **NEW:** Verify XP curve progression matches 6-18 month target
- **NEW:** Test level-up popup doesn't repeat
- **NEW:** Test journal prompt doesn't clash with animations
- **NEW:** Test mood jar cash-in system
- **NEW:** Test theme shop grouping and ordering

