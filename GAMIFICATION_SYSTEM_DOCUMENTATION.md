# Haven 2.0 Gamification System - Complete Documentation

## Table of Contents
1. [Overview](#overview)
2. [XP (Experience Points) System](#xp-experience-points-system)
3. [Time Crystals System](#time-crystals-system)
4. [Weekly Productivity Score](#weekly-productivity-score)
5. [Momentum System](#momentum-system)
6. [Level Progression](#level-progression)
7. [League System](#league-system)
8. [Treats (Mood Jar) System](#treats-mood-jar-system)
9. [Resets & Cycles](#resets--cycles)
10. [Complete Reward Breakdown](#complete-reward-breakdown)

---

## Overview

Haven 2.0 uses a comprehensive gamification system to motivate users and track their productivity journey. The system consists of:

- **XP (Experience Points)**: Earned through task completion, used for leveling up
- **Time Crystals**: Currency earned through tasks, spent on themes and premium features
- **Weekly Productivity Score**: Calculated weekly for leaderboard rankings
- **Momentum Days**: Tracks consecutive days of task completion
- **Levels**: Progression system based on cumulative XP (Level 1-50+)
- **Leagues**: Weekly competitive rankings (Bronze, Silver, Gold, Platinum, Diamond, Master)
- **Treats**: Rewards from mood jar completions

---

## XP (Experience Points) System

### What is XP?
XP (Experience Points) is the primary progression currency. Accumulating XP increases your level, which unlocks themes and provides a sense of achievement.

### How XP Works
- **Cumulative**: XP never resets - it accumulates over time
- **Level-Based**: XP determines your current level (Level 1-50+)
- **Permanent**: Once earned, XP is never lost

### XP Award Sources

#### 1. Task Completion (Base XP)
**Base XP per task: 10 points**

**Priority Multipliers:**
- **Urgent**: 1.5x = **15 XP**
- **High**: 1.3x = **13 XP**
- **Normal**: 1.0x = **10 XP**
- **Low**: 0.8x = **8 XP**

**Goal-Linked Bonus:**
- Tasks linked to goals: **+50% XP** (1.5x multiplier)
- Example: Normal priority task with goal = 10 × 1.5 = **15 XP**

**Momentum Bonus:**
- Applied to all XP earned (see Momentum System section for multipliers)

**Time-Based XP Bonus:**
- Additional XP based on task duration:
  - **< 30 minutes**: 15 × 0.7 = **10.5 XP** (rounded to 11)
  - **30 min - 1 hour**: 15 × 1.0 = **15 XP**
  - **1-3 hours**: 15 × 1.3 = **19.5 XP** (rounded to 20)
  - **3-6 hours**: 15 × 1.6 = **24 XP**
  - **6+ hours**: 15 × 2.0 = **30 XP**

**Total XP Formula:**
```
Base XP = 10
Priority Multiplier = (varies by priority)
Goal Bonus = 1.5x if linked to goal
Momentum Bonus = (varies by momentum days)
Time-Based Bonus = (varies by duration)

Total XP = (Base XP × Priority × Goal Bonus × Momentum Bonus) + Time-Based Bonus
```

#### 2. Active Task Timer (Immersive View)
- **2 XP per 30 seconds** while actively working on a task
- Only awarded during active timer (paused time doesn't count)
- Maximum potential: ~240 XP per hour of active work

#### 3. Mood Jar Completions (Treats)
- **150 XP** per mood jar completion (when jar reaches 15 marbles)

#### 4. Special Bonuses
- **First Task Bonus**: +20 XP (one-time per day)
- **Daily Task Bonus**: +50 XP for completing 5+ tasks in a day
- **Milestone Completion**: +200 XP
- **Goal Completion**: +500 XP

#### 5. Task Block Completion
- **Base XP**: 50 points
- **Time Multiplier**:
  - < 1 hour: 1.0x = **50 XP**
  - 1-3 hours: 1.5x = **75 XP**
  - 3-6 hours: 2.0x = **100 XP**
  - 6+ hours: 2.5x = **125 XP**
- **Task Count Multiplier**: +10% per additional task (capped at 2.0x)
  - Example: 3 tasks, 2 hours = 50 × 1.5 × 1.2 = **90 XP**

---

## Time Crystals System

### What are Time Crystals?
Time Crystals are the in-app currency used to purchase themes, unlock premium features, and customize your experience. They are earned through productivity and spent in the Theme Shop.

### How Time Crystals Work
- **Cumulative**: Crystals accumulate and never expire
- **Spendable**: Used to purchase themes and unlock premium features
- **Tracked**: Total crystals are displayed on profile and home screen

### Time Crystal Award Sources

#### 1. Task Completion (Base Crystals)
**Base crystals by priority:**
- **Urgent**: 15 crystals
- **High**: 10 crystals
- **Normal**: 5 crystals
- **Low**: 3 crystals

**Category Multipliers:**
- **Growth**: 1.5x
- **Self-Care**: 1.3x
- **Hobbies**: 1.2x
- **Other categories**: 1.0x

**Goal-Linked Bonuses:**
- Tasks linked to goals: **+50% crystals** (1.5x)
- Critical priority goals: **Additional +50%** (1.5x × 1.5x = 2.25x total)

**Time Bonuses:**
- **On-time completion**: +20% crystals
- **Early completion**: +10% crystals
- **Late completion**: No bonus

**Momentum Bonus:**
- Applied to all crystals earned (see Momentum System section)

**Time-Based Crystal Bonus:**
- Additional crystals based on task duration:
  - **< 30 minutes**: 7 × 0.7 = **4.9 crystals** (rounded to 5)
  - **30 min - 1 hour**: 7 × 1.0 = **7 crystals**
  - **1-3 hours**: 7 × 1.3 = **9.1 crystals** (rounded to 9)
  - **3-6 hours**: 7 × 1.6 = **11.2 crystals** (rounded to 11)
  - **6+ hours**: 7 × 2.0 = **14 crystals**

**Total Crystals Formula:**
```
Base Crystals = (varies by priority: 3-15)
Category Multiplier = (varies: 1.0x-1.5x)
Goal Bonus = 1.5x if linked to goal (2.25x if critical)
Time Bonus = 1.1x-1.2x (early/on-time) or 1.0x (late)
Momentum Bonus = (varies by momentum days)
Time-Based Bonus = (varies by duration)

Total Crystals = (Base × Category × Goal × Time × Momentum) + Time-Based Bonus
```

#### 2. Active Task Timer (Immersive View)
- **1 crystal per minute** while actively working on a task
- Only awarded during active timer (paused time doesn't count)
- Maximum potential: ~60 crystals per hour of active work

#### 3. Mood Jar Completions (Treats)
- **350 crystals** per mood jar completion (when jar reaches 15 marbles)

#### 4. Special Bonuses
- **First Task Bonus**: +5 crystals (one-time per day)
- **Milestone Completion**: +100 crystals
- **Goal Completion**: +200 crystals

#### 5. Task Block Completion
- **Base crystals**: 25
- **Time Multiplier**:
  - < 1 hour: 1.0x = **25 crystals**
  - 1-3 hours: 1.5x = **37.5 crystals** (rounded to 38)
  - 3-6 hours: 2.0x = **50 crystals**
  - 6+ hours: 2.5x = **62.5 crystals** (rounded to 63)
- **Task Count Multiplier**: +10% per additional task (capped at 2.0x)

### How Time Crystals Are Spent

#### Theme Shop Purchases
- Themes can be purchased with Time Crystals (prices vary by theme)
- Purchase deducts crystals from user's balance: `user.gamificationCurrency -= theme.currencyPrice`
- Once purchased, themes are permanently owned (stored in `ownedThemeIDs`)

#### Premium Features (Future)
- Time Crystals may be used to unlock premium features
- Currently, premium features are subscription-based, but crystal purchases may be added

---

## Weekly Productivity Score

### What is Weekly Productivity Score?
Weekly Productivity Score is a composite metric calculated weekly to determine leaderboard rankings. It measures overall productivity across multiple dimensions.

### How Weekly Score Works
- **Resets Weekly**: Every Monday at 12:00 AM, scores reset to 0
- **Competitive**: Used for leaderboard rankings and league placement
- **Multi-Dimensional**: Combines task completion, goal progress, consistency, and quality

### Weekly Score Calculation

The weekly score is calculated using a weighted formula:

```
Final Score = (Task Score × 40%) + (Goal Score × 30%) + (Consistency Score × 20%) + (Quality Score × 10%)
```

#### 1. Task Score (40% of total)
**Base score per task: 10 points**

**Priority Multipliers:**
- **Urgent**: 2.0x = **20 points**
- **High**: 1.5x = **15 points**
- **Normal**: 1.0x = **10 points**
- **Low**: 0.5x = **5 points**

**Goal-Linked Bonus:**
- Tasks linked to goals: **+30%** (1.3x multiplier)

**Daily Cap:**
- Maximum 200 points per day
- Weekly maximum: 1,400 points (7 days × 200)

#### 2. Goal Progress Score (30% of total)
**Milestone Progress Bonus:**
- **+50 points** per goal that made progress this week

**Goal Completion Bonus:**
- **+500 points** per goal completed this week

**Critical Priority Bonus:**
- Goals with critical priority: **+50%** to all goal-related scores

#### 3. Consistency Score (20% of total)
Based on unique days with completed tasks:
- **2-3 days**: 50 points
- **4-6 days**: 100 points
- **7 days** (every day): 200 points
- **< 2 days**: 0 points

#### 4. Quality Score (10% of total)
**On-Time Completions:**
- **+20 points** per task completed on-time

**Early Completions:**
- **+10 points** per task completed early

**Category Balance Bonus:**
- **+50 points** if tasks span 3+ different categories

### Weekly Score Reset
- **Reset Day**: Every Monday at 12:00 AM (start of week)
- **Reset Action**: `weeklyProductivityScore = 0`
- **Tracking**: `weeklyResetDate` stores the last reset date

---

## Momentum System

### What is Momentum?
Momentum tracks consecutive days of task completion, providing increasing bonuses to all rewards earned.

### How Momentum Works
- **Daily Tracking**: Momentum increases by 1 for each day with completed tasks
- **Graceful Degradation**: If no tasks completed, momentum decreases by 2 (minimum 0)
- **Bonus Multiplier**: Higher momentum = higher bonus to all XP and crystals earned

### Momentum Calculation

**Daily Update Logic:**
1. Check if tasks were completed today
2. If yes: `momentumDays += 1`
3. If no: `momentumDays = max(0, momentumDays - 2)`
4. Update `lastMomentumUpdate` to today's date

**Momentum Bonus Multipliers:**
- **0-1 days**: 1.0x (no bonus)
- **2-3 days**: 1.10x (+10% bonus)
- **4-6 days**: 1.20x (+20% bonus)
- **7-13 days**: 1.30x (+30% bonus)
- **14-29 days**: 1.40x (+40% bonus)
- **30+ days**: 1.50x (+50% bonus - maximum)

**Example:**
- User with 10 momentum days completes a normal priority task
- Base XP: 10
- Momentum bonus: 1.30x
- Final XP: 10 × 1.30 = **13 XP**

---

## Level Progression

### What are Levels?
Levels represent overall progression in the app, determined by cumulative XP earned.

### How Levels Work
- **Cumulative XP**: Levels are based on total XP accumulated (never resets)
- **Progression**: Level 1-50+ (designed for 6-18 month progression to Level 50)
- **Theme Unlocks**: Some themes unlock at specific levels
- **Permanent**: Levels never decrease

### Level Calculation

**XP Requirements (Tiered System):**

**Early Levels (1-10):**
- Formula: `150 × level^1.4`
- Examples:
  - Level 2: ~150 × 2^1.4 = ~**378 XP**
  - Level 5: ~150 × 5^1.4 = ~**1,118 XP**
  - Level 10: ~150 × 10^1.4 = ~**3,766 XP**

**Mid Levels (11-25):**
- Formula: `Base (3,766) + 250 × (level-10)^1.5`
- Examples:
  - Level 15: 3,766 + 250 × 5^1.5 = ~**6,560 XP**
  - Level 20: 3,766 + 250 × 10^1.5 = ~**11,673 XP**
  - Level 25: 3,766 + 250 × 15^1.5 = ~**18,479 XP**

**High Levels (26-50+):**
- Formula: `Mid Base (11,879) + 500 × (level-25)^1.7`
- Examples:
  - Level 30: 11,879 + 500 × 5^1.7 = ~**22,000 XP**
  - Level 40: 11,879 + 500 × 15^1.7 = ~**42,000 XP**
  - Level 50: 11,879 + 500 × 25^1.7 = ~**62,000 XP**

**Progression Targets:**
- **Super Active User** (6 months to Level 50): ~344 XP/day
- **Normal User** (18 months to Level 50): ~113 XP/day

### Level Up Process
1. User earns XP through task completion
2. System checks: `if newXP >= xpForLevel(currentLevel + 1)`
3. If true: Level increases, `nextLevelXP` is updated
4. Level-up animation and celebration shown
5. Themes unlocked at new level become available

### Theme Unlocks by Level
- Themes can be set to unlock at specific levels
- Unlock method: `Theme.unlockMethod == .level`
- Unlock requirement: `Theme.unlockLevel <= user.level`
- All themes are permanently owned once unlocked

---

## League System

### What are Leagues?
Leagues are weekly competitive rankings that group users based on their Weekly Productivity Score.

### How Leagues Work
- **Weekly Competition**: Leagues reset every Monday
- **Score-Based**: League placement determined by Weekly Productivity Score
- **Promotion/Demotion**: Top performers advance, bottom performers may be demoted
- **Cohort System**: Users are grouped into cohorts of ~30 people (similar to Duolingo)

### League Tiers

**League Thresholds (by Weekly Score):**
- **Bronze**: 0-99 points
- **Silver**: 100-499 points
- **Gold**: 500-999 points
- **Platinum**: 1,000-1,999 points
- **Diamond**: 2,000-4,999 points
- **Master**: 5,000+ points

### League Progression

**Promotion Rules:**
- **Top 10** in a league advance to the next tier
- Promotion happens at end of week (Sunday 11:59 PM)

**Demotion Rules:**
- **Bottom 7** in a league are demoted to previous tier
- Demotion happens at end of week

**Safe Zone:**
- Middle-ranked users (rank 11-23 in a 30-person cohort) stay in the same league

### League Reset
- **Weekly Reset**: Every Monday at 12:00 AM
- **Score Reset**: `weeklyProductivityScore = 0`
- **Cohort Assignment**: Users are placed into new cohorts based on when they complete their first task of the week
- **Ranking**: Users compete only within their cohort (~30 people)

### League Rewards (Future Implementation)
- **1st Place**: Badge, 100 crystals, notification
- **2nd Place**: Badge, 50 crystals, notification
- **3rd Place**: Badge, 25 crystals, notification
- Rewards distributed via Cloud Functions at week end

---

## Treats (Mood Jar) System

### What are Treats?
Treats are rewards earned by completing mood jar check-ins. Each mood type has its own jar that fills with marbles.

### How Treats Work
- **8 Mood Jars**: One jar per mood type (Happy, Calm, Energetic, Focused, Tired, Stressed, Anxious, Sad)
- **15 Marbles per Jar**: Each jar holds up to 15 marbles
- **Cash-In System**: When a jar reaches 15 marbles, user can "cash in" for rewards
- **Tracking**: `moodJarCompletions` tracks total number of jars cashed in

### Treat Rewards

**Per Jar Completion:**
- **350 Time Crystals**
- **150 XP**
- **+1 to `moodJarCompletions` counter**

**Example:**
- User completes 15 "Happy" mood check-ins
- Jar fills to 15/15
- User taps "Cash In"
- Receives: 350 crystals + 150 XP
- `moodJarCompletions` increases by 1
- Jar resets to 0/15

### Treat Tracking
- **Profile Display**: Total `moodJarCompletions` shown in "Your Journey" section
- **Firestore Sync**: Completions synced to cloud for persistence
- **Permanent**: Treat count never resets (cumulative total)

---

## Resets & Cycles

### Weekly Resets

**What Resets:**
- ✅ **Weekly Productivity Score**: Resets to 0 every Monday
- ✅ **Weekly Reset Date**: Updated to new week start
- ✅ **League Cohorts**: New cohorts formed each week

**What Doesn't Reset:**
- ❌ **XP**: Never resets (cumulative)
- ❌ **Time Crystals**: Never resets (cumulative)
- ❌ **Level**: Never decreases
- ❌ **Momentum Days**: Only decreases if no tasks completed (graceful degradation)
- ❌ **Mood Jar Completions**: Never resets (cumulative)

### Daily Resets

**What Resets:**
- ✅ **Daily Task Count**: Resets at midnight (for free tier limits)
- ✅ **First Task Bonus**: Available again each day

**What Doesn't Reset:**
- ❌ **XP**: Never resets
- ❌ **Time Crystals**: Never resets
- ❌ **Momentum**: Only changes based on task completion

### Momentum Degradation

**Daily Check:**
- If tasks completed today: `momentumDays += 1`
- If no tasks completed: `momentumDays = max(0, momentumDays - 2)`

**Example:**
- User has 10 momentum days
- No tasks completed today
- Next day: `momentumDays = max(0, 10 - 2) = 8`
- If no tasks for 5 days: `momentumDays = max(0, 10 - 10) = 0`

---

## Complete Reward Breakdown

### Task Completion Rewards

#### Example 1: Normal Priority Task, No Goal, 1 Hour Duration
- **Base Crystals**: 5
- **Base XP**: 10
- **Time-Based Crystals**: 7
- **Time-Based XP**: 15
- **Total**: **12 crystals, 25 XP**

#### Example 2: High Priority Task, Linked to Goal, On-Time, 2 Hours, 5 Momentum Days
- **Base Crystals**: 10
- **Category Multiplier**: 1.0x = 10
- **Goal Bonus**: 1.5x = 15
- **On-Time Bonus**: 1.2x = 18
- **Momentum Bonus** (5 days = 1.20x): 21.6
- **Time-Based Crystals**: 7 × 1.3 = 9.1
- **Total Crystals**: ~**31 crystals**

- **Base XP**: 10
- **Priority Multiplier**: 1.3x = 13
- **Goal Bonus**: 1.5x = 19.5
- **Momentum Bonus**: 1.20x = 23.4
- **Time-Based XP**: 15 × 1.3 = 19.5
- **Total XP**: ~**43 XP**

#### Example 3: Urgent Priority Task, Critical Goal, Early, 4 Hours, 20 Momentum Days
- **Base Crystals**: 15
- **Category Multiplier**: 1.0x = 15
- **Goal Bonus**: 1.5x = 22.5
- **Critical Goal Bonus**: 1.5x = 33.75
- **Early Bonus**: 1.1x = 37.125
- **Momentum Bonus** (20 days = 1.40x): 51.975
- **Time-Based Crystals**: 7 × 1.6 = 11.2
- **Total Crystals**: ~**63 crystals**

- **Base XP**: 10
- **Priority Multiplier**: 1.5x = 15
- **Goal Bonus**: 1.5x = 22.5
- **Momentum Bonus**: 1.40x = 31.5
- **Time-Based XP**: 15 × 1.6 = 24
- **Total XP**: ~**56 XP**

### Special Completion Rewards

| Action | Time Crystals | XP | Weekly Score |
|--------|--------------|-----|--------------|
| First Task of Day | +5 | +20 | - |
| Complete 5+ Tasks/Day | 0 | +50 | - |
| Milestone Completion | +100 | +200 | +50 |
| Goal Completion | +200 | +500 | +500 |
| Mood Jar Completion | +350 | +150 | - |

### Active Work Rewards (Immersive View)

**Per 30 Seconds:**
- **+2 XP**

**Per Minute:**
- **+1 Time Crystal**

**Maximum Per Hour:**
- **~240 XP**
- **~60 Time Crystals**

### Task Block Rewards

**Base Rewards:**
- **25 crystals, 50 XP**

**Multipliers:**
- Time-based: 1.0x-2.5x
- Task count: +10% per additional task (capped at 2.0x)

**Example: 3 Tasks, 2 Hours:**
- Base: 25 crystals, 50 XP
- Time multiplier: 1.5x = 37.5 crystals, 75 XP
- Task count multiplier: 1.2x = 45 crystals, 90 XP

---

## Summary

### Key Principles

1. **XP is Permanent**: Never resets, always accumulates
2. **Crystals are Permanent**: Never expire, accumulate over time
3. **Weekly Score Resets**: Competitive metric that resets every Monday
4. **Momentum Provides Bonuses**: Higher momentum = higher rewards
5. **Levels Unlock Themes**: Some themes require specific levels
6. **Leagues are Weekly**: Competitive rankings reset weekly
7. **Treats are Cumulative**: Mood jar completions never reset

### Progression Timeline

**To Reach Level 50:**
- **Super Active**: ~344 XP/day for 6 months
- **Normal**: ~113 XP/day for 18 months

**Typical Daily Earnings (Active User):**
- **5-10 tasks/day**: ~100-300 XP, ~50-150 crystals
- **With momentum bonus**: +20-50% more
- **With goal-linked tasks**: +50% more

### Best Practices for Users

1. **Complete tasks on-time** for time bonuses
2. **Link tasks to goals** for goal bonuses
3. **Maintain momentum** by completing tasks daily
4. **Focus on high-priority tasks** for higher base rewards
5. **Complete longer tasks** for time-based bonuses
6. **Check in with mood jar** regularly to earn treats
7. **Work actively** in immersive view for passive rewards

---

*Last Updated: January 2025*
*Documentation Version: 1.0*

