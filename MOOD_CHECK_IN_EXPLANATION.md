# Mood Check-In System - Complete Explanation

## Overview
The Mood Check-In system allows users to track their emotional state throughout the day using a two-step selection process: **Mood Intensity** (5 levels) → **Specific Emotion** (36 sub-moods across 6 core moods).

---

## System Architecture

### 1. **Core Components**

#### **MoodEntry Model** (`MoodEntry.swift`)
- **Purpose**: Stores individual mood check-in records
- **Key Properties**:
  - `coreMood`: One of 6 main mood categories (Happy, Sad, Anxious, Calm, Energetic, Tired)
  - `subMood`: Specific emotion within that category (36 total, 6 per core mood)
  - `checkInTime`: Time period (Morning, Afternoon, Night)
  - `timestamp`: When the check-in occurred
  - `notes`: Optional user notes
  - `userID`: Links to the user who created it

#### **MoodJarService** (`MoodJarService.swift`)
- **Purpose**: Business logic for mood tracking, validation, and rewards
- **Key Functions**:
  - `canCheckIn()`: Validates if user can check in at current time
  - `currentCheckInPeriod()`: Determines which time window user is in
  - `hasCheckedInToday()`: Checks if user already checked in for a period
  - `hasMaxCheckInsToday()`: Enforces 3 check-ins per day maximum
  - `calculateMoodRewards()`: Awards Time Crystals and XP based on patterns

---

## 2. **Time-Based Check-In Windows**

### **Check-In Periods** (`CheckInTime` enum)
The system divides the day into 3 time windows:

| Period | Time Window | Hours |
|--------|-------------|-------|
| **Morning** | 5:00 AM - 11:59 AM | 5:00 - 11:59 |
| **Afternoon** | 12:00 PM - 4:59 PM | 12:00 - 16:59 |
| **Night** | 5:00 PM - 11:59 PM | 17:00 - 23:59 |

### **Validation Rules**
1. **Within Window**: User can check in if current time falls within a period window
2. **Outside Window**: User can still check in if:
   - They haven't checked in at all today (minimum 1 check-in per day)
   - They haven't exceeded the 3 check-ins per day limit
3. **One Check-In Per Period**: Users can only check in once per time period per day
4. **Maximum 3 Per Day**: Hard limit of 3 check-ins per day total

---

## 3. **Mood Selection Process**

### **Step 1: Mood Intensity Selection**
User selects from 5 circular intensity buttons:

```
Very Negative (↓↓) → Negative (↓) → Neutral (-) → Positive (↑) → Very Positive (↑↑)
```

**Purpose**: Quickly narrows down the emotional range before selecting specific emotions.

### **Step 2: Emotion Grid Filtering**
Based on intensity selection, the system filters available emotions:

| Intensity | Available Core Moods | Example Emotions |
|-----------|-------------------|------------------|
| Very Negative | Sad, Anxious, Tired | Despairful, Fearful, Exhausted |
| Negative | Sad, Anxious, Tired | Lonely, Worried, Drained |
| Neutral | Calm, Tired | Balanced, Sleepy |
| Positive | Happy, Calm, Energetic | Content, Peaceful, Motivated |
| Very Positive | Happy, Energetic | Excited, Inspired |

### **Step 3: Specific Emotion Selection**
User selects from a 2-column grid of emotion words (filtered by intensity):
- Each emotion belongs to one of 6 core moods
- Visual feedback: Selected emotion gets colored border matching its core mood color

### **Step 4: Optional Notes**
User can add additional thoughts/context (optional text field).

### **Step 5: Save**
Creates a `MoodEntry` and saves to SwiftData, then triggers callback.

---

## 4. **Core Moods & Sub-Moods**

### **6 Core Moods** (Mood Jars)
Each core mood has 6 specific sub-moods (emotions):

#### **Happy** (Yellow) 🟡
- Happy, Excited, Proud, Grateful, Content, Optimistic

#### **Sad** (Blue) 🔵
- Sad, Lonely, Disappointed, Grieved, Melancholic, Despairful

#### **Anxious** (Orange) 🟠
- Anxious, Nervous, Worried, Stressed, Overwhelmed, Fearful

#### **Calm** (Green) 🟢
- Calm, Peaceful, Relaxed, Balanced, Serene, Centered

#### **Energetic** (Purple) 🟣
- Energetic, Motivated, Enthusiastic, Active, Vibrant, Inspired

#### **Tired** (Indigo) 🔵
- Tired, Exhausted, Drained, Weary, Fatigued, Sleepy

**Total**: 36 unique emotions (6 core moods × 6 sub-moods each)

---

## 5. **Rewards & Gamification**

### **Mood Rewards** (calculated by `MoodJarService.calculateMoodRewards()`)

#### **7-Day Completion**
- **Requirement**: 7 unique days of check-ins in the last 7 days
- **Reward**: 200 Time Crystals + 100 XP

#### **Mood Collection**
- **Requirement**: 10+ entries of a specific mood type
- **Reward**: 300 Time Crystals + 150 XP

#### **Balanced Week**
- **Requirement**: 14+ entries with 50%+ positive/neutral moods
- **Reward**: 250 Time Crystals + 125 XP + Theme Unlock ("balanced")

#### **Improving Trend**
- **Requirement**: 5+ days showing improving mood pattern
- **Reward**: 150 Time Crystals + 75 XP

#### **Perfect Week**
- **Requirement**: 21 check-ins in 7 days (3 per day)
- **Reward**: 500 Time Crystals + 250 XP + Special Theme Unlock

---

## 6. **Data Flow**

### **Check-In Flow**
```
User Opens Mood Check-In
    ↓
MoodJarService.canCheckIn() → Validates time window
    ↓
MoodCheckInView displays intensity selectors
    ↓
User selects intensity → Filters available emotions
    ↓
User selects specific emotion
    ↓
User adds optional notes
    ↓
Save button creates MoodEntry
    ↓
MoodEntry saved to SwiftData
    ↓
MoodEntry added to user.moodHistory array
    ↓
MoodJarService.calculateMoodRewards() → Awards crystals/XP
    ↓
Callback triggered (onMoodSelected)
```

### **Data Storage**
- **Local**: SwiftData (`MoodEntry` model)
- **Cloud**: Firebase Firestore (synced via `FirestoreService`)
- **User Model**: `user.moodHistory` array contains all entries

---

## 7. **UI Components**

### **MoodCheckInView** (Main View)
- Displays current check-in period indicator
- Shows 5 circular intensity buttons
- Dynamic emotion grid (filtered by intensity)
- Optional notes text editor
- Save button (disabled until both intensity and emotion selected)

### **MoodJarView** (Container View)
- Shows mood history timeline
- Displays mood jars (6 core moods) with completion counts
- "Cash In Jar" button to claim rewards
- Check-in button that opens `MoodCheckInView`

---

## 8. **Integration Points**

### **Onboarding**
- New users can set wake time and bed time during onboarding
- These times can influence check-in period suggestions

### **Profile View**
- "Treats" counter shows `user.moodJarCompletions` (rewards claimed)
- Links to mood history and statistics

### **Gamification**
- Mood check-ins contribute to:
  - Time Crystals (currency)
  - XP (experience points)
  - Theme unlocks (special themes require mood patterns)
  - Weekly Score (consistency bonus)

---

## 9. **Example Usage**

### **Scenario: Morning Check-In**
1. User opens app at 8:00 AM
2. System detects "Morning" period (5 AM - 11:59 AM)
3. User selects "Positive" intensity
4. Grid shows: Happy, Calm, Energetic emotions
5. User selects "Grateful" (Happy sub-mood)
6. User adds note: "Feeling thankful for good sleep"
7. Saves → Creates MoodEntry with:
   - `coreMood`: `.happy`
   - `subMood`: `.grateful`
   - `checkInTime`: `.morning`
   - `timestamp`: 8:00 AM today
   - `notes`: "Feeling thankful for good sleep"

### **Scenario: Afternoon Check-In**
1. User opens app at 2:00 PM
2. System detects "Afternoon" period (12 PM - 4:59 PM)
3. User selects "Neutral" intensity
4. Grid shows: Calm, Tired emotions
5. User selects "Balanced" (Calm sub-mood)
6. Saves → Creates second MoodEntry for today

### **Scenario: Night Check-In**
1. User opens app at 9:00 PM
2. System detects "Night" period (5 PM - 11:59 PM)
3. User selects "Very Positive" intensity
4. Grid shows: Happy, Energetic emotions
5. User selects "Inspired" (Energetic sub-mood)
6. Saves → Creates third MoodEntry (max for today)

---

## 10. **Future Enhancements**

### **Onboarding Integration**
- `WakeTimeSelectionView`: User sets wake time
- `BedTimeSelectionView`: User sets bed time
- `DynamicMoodScrollerView`: Initial mood selection with swipeable cards
- These can customize check-in period windows per user

### **Analytics**
- Mood trends over time
- Pattern recognition (e.g., "You're usually happier on weekends")
- Correlation with task completion rates

### **Notifications**
- Reminders to check in during each period
- Celebration when completing a week of check-ins

---

## Summary

The Mood Check-In system is a **time-aware, two-step emotional tracking system** that:
1. Divides the day into 3 check-in windows
2. Uses intensity filtering to guide emotion selection
3. Tracks 36 specific emotions across 6 core moods
4. Awards rewards based on consistency and patterns
5. Integrates with gamification (crystals, XP, themes)
6. Stores data locally and syncs to cloud

This creates a comprehensive emotional wellness tracking system that encourages daily reflection while providing gamified rewards for consistency.

