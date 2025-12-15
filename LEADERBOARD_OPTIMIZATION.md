# Leaderboard Fetch Limit Optimization

## Issue
The leaderboard was fetching 100 users from SwiftData, but:
- Only displays **10 users** at a time (`.prefix(10)`)
- Uses **league grouping** (Duolingo-style: Bronze, Silver, Gold, etc.)
- Should only show users in the **same league** as the current user

## Solution

### Before:
- **Fetch Limit**: 100 users
- **Display**: Top 10 globally (not filtered by league)
- **Problem**: Fetching 10x more data than needed

### After:
- **Fetch Limit**: 50 users (reduced from 100)
- **Display**: Top 10 from the **current user's league** only
- **Benefit**: 
  - 50% reduction in data fetched
  - Proper league grouping (Duolingo-style)
  - Better performance

## Implementation

1. **Reduced Fetch Limit**: Changed from 100 to 50 users
   - Still provides buffer for league filtering
   - Ensures we have enough users even in smaller leagues

2. **Added League Filtering**: 
   - Filter `leaderboardEntries` to only include users in the same league
   - Re-rank after filtering so ranks are 1-10 within the league
   - Matches Duolingo's behavior where you compete within your league

## League System

Leagues are determined by score:
- **Bronze**: 0-99 points
- **Silver**: 100-499 points
- **Gold**: 500-999 points
- **Platinum**: 1000-1999 points
- **Diamond**: 2000-4999 points
- **Master**: 5000+ points

**Top 10 in each league advance to the next league** (similar to Duolingo).

## Performance Impact

- **Memory**: 50% reduction (50 users vs 100)
- **Query Speed**: Faster SwiftData query (fewer records)
- **UI Rendering**: Same (still only 10 displayed)
- **User Experience**: Better (proper league grouping)

## Future Optimization

If leagues get very large, we could further optimize:
- Fetch only 30 users (top 10 + buffer)
- Use Firebase for global leaderboards (already planned)
- Cache league-filtered results

---

**Status**: ✅ Implemented
**Date**: 2025-01-XX

