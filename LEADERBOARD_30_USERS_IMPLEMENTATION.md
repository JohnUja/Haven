# Leaderboard: 30 Users Per Group Implementation

## Summary

Updated the leaderboard to match Duolingo's exact behavior:
- **30 users per league group** (not 10)
- **Top 10 advance** to next league
- **Top 3 get awards** (popup confirmation)
- **Fetch limit: 30** (exactly what's needed, safe if DB has more)

---

## Changes Made

### 1. Fetch Limit: 30 Users ✅
```swift
@Query(sortBy: [...], fetchLimit: 30) 
private var users: [User]
```

**Why 30?**
- Each league group contains exactly 30 users
- SwiftData safely stops at 30 even if DB has 1000+ users
- No errors, just returns first 30 matching the sort criteria

### 2. Display: All 30 Users ✅
Changed from `.prefix(10)` to `.prefix(30)`:
```swift
ForEach(Array(leaderboardEntries.prefix(30).enumerated()), id: \.element.id) { index, entry in
    // Show all 30 users
}
```

### 3. League Position Status ✅
Added `LeaguePosition` enum:
- **Top 3** (ranks 1-3): Get awards 🏆
- **Advancing** (ranks 4-10): Advance to next league ⬆️
- **Stationary** (ranks 11-25): Stay in current league ➡️
- **Demoted** (ranks 26-30): Get demoted ⬇️

### 4. Top 3 Award Popup ✅
- Shows when user reaches top 3
- Displays medal (🥇 Gold, 🥈 Silver, 🥉 Bronze)
- Theme-controlled styling
- "Awesome!" button to dismiss

### 5. Removed "Your Position" Section ✅
- No longer needed since all 30 users are shown
- User's position is visible in the main list

---

## How Fetch Limits Work (Your Question)

### If Database Has More Than Fetch Limit:

**Nothing breaks!** SwiftData simply:
1. Sorts the data (by your `SortDescriptor`)
2. Takes the first N records (where N = fetchLimit)
3. Stops fetching (doesn't load the rest into memory)
4. Returns exactly N records (or fewer if DB has less)

### Example:
- **Database**: 1,000 users
- **Fetch Limit**: 30
- **Sort**: By score (descending)
- **Result**: Returns top 30 users by score
- **Remaining 970**: Stay in database, not loaded

### Why This Is Safe:
- ✅ No errors thrown
- ✅ No crashes
- ✅ Memory efficient (only loads what you need)
- ✅ Fast (database stops after finding top 30)

### Best Practice for Leaderboards:
```swift
// Sort by score (descending) - CRITICAL!
@Query(
    sortBy: [SortDescriptor(\User.score, order: .reverse)],
    fetchLimit: 30  // Exactly what you need
)
```

This ensures you get the **top 30** users, not random 30.

---

## League Progression Logic

### Duolingo-Style Breakdown:

| Rank Range | Status | Action |
|------------|--------|--------|
| 1-3 | 🏆 Top 3 | Get awards + advance |
| 4-10 | ⬆️ Advancing | Advance to next league |
| 11-25 | ➡️ Stationary | Stay in current league |
| 26-30 | ⬇️ Demoted | Get demoted to lower league |

### Top 3 Awards:
- **Rank 1**: 🥇 Gold Medal
- **Rank 2**: 🥈 Silver Medal  
- **Rank 3**: 🥉 Bronze Medal

Popup shows:
- Medal emoji
- "Congratulations! You finished in X place!"
- Medal name (Gold/Silver/Bronze)
- User's score
- "Awesome!" button

---

## Performance Benefits

### Before (100 users):
- Fetched 100 users
- Displayed 10 users
- Wasted 90 users in memory

### After (30 users):
- Fetches 30 users (exactly what's needed)
- Displays all 30 users
- **70% memory reduction**
- Faster queries
- Better performance

---

## Future Enhancements

1. **League Filtering**: Currently shows all users, should filter by league
2. **Pagination**: If needed for scrolling through multiple groups
3. **Award Rewards**: Give actual XP/crystals for top 3
4. **Demotion Logic**: Handle demotion to lower league

---

**Status**: ✅ Implemented
**Date**: 2025-01-XX

