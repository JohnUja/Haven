# Fetch Limits Implications Analysis

## HomeDashboardView.swift

### Current Limits:
- **Users**: 10 most recent
- **Routines**: 50 most recent

### Implications:

#### ✅ **Positive Implications**:
1. **Memory Efficiency**: Only loads 10 users instead of potentially hundreds/thousands
2. **Faster Queries**: SwiftData only fetches 10 records instead of scanning entire database
3. **Reduced Initial Load Time**: App starts faster
4. **Battery Life**: Less data processing = better battery efficiency

#### ⚠️ **Potential Issues**:
1. **Current User Not Found**: If current user is not in the top 10 most recent, `users.first` will return wrong user
   - **Risk**: HIGH - This could break the app if user account is older
   - **Solution**: Need to ensure current user is always included, or use a different query strategy

2. **Routines Missing**: If user has more than 50 routines, older routines won't be loaded
   - **Risk**: MEDIUM - User might not see all their routines
   - **Solution**: Filter by `userID` in predicate instead of just limiting

### **Recommended Fix**:
```swift
// Instead of just limiting, filter by current user
@Query(
    filter: #Predicate<User> { user in
        // We need current user, but can't use dynamic authService here
        // Better approach: Query all users but limit to reasonable number
    },
    fetchLimit: 10
) private var users: [User]

// OR: Remove limit and filter in ViewModel after getting current user ID
@Query(sortBy: [SortDescriptor(\User.createdAt, order: .reverse)]) 
private var users: [User]
// Then in ViewModel: filter to current user's routines
```

---

## LeaderboardView.swift

### Current Limits:
- **Users**: 100, sorted by level/XP (descending)
- **Tasks**: 500 most recent
- **Goals**: 200 most recent

### Implications:

#### ✅ **Positive Implications**:
1. **Leaderboard Performance**: Only loads top 100 users = fast leaderboard display
2. **Memory Efficient**: Doesn't load thousands of users
3. **Scalable**: App can handle millions of users, only shows top 100
4. **Sorted at Database Level**: Sorting by level/XP happens in SwiftData (faster than in-memory)

#### ⚠️ **Potential Issues**:
1. **Current User Not in Top 100**: If user's rank is > 100, they won't see themselves
   - **Risk**: MEDIUM - User experience issue
   - **Solution**: Always include current user even if not in top 100, or show "Your Rank: #150" separately

2. **Tasks/Goals for Productivity Score**: 500 tasks and 200 goals might not be enough for accurate productivity score calculation
   - **Risk**: LOW - Productivity score is likely calculated from recent activity anyway
   - **Solution**: If needed, can increase limits or filter by date range

### **Recommended Fix**:
```swift
// For leaderboard, current approach is good, but:
// 1. Always include current user in results (even if not top 100)
// 2. Show user's rank separately if not in top 100

// Tasks/Goals limits are probably fine for productivity score
// (most users won't have >500 recent tasks)
```

---

## Overall Assessment

### ✅ **Safe to Use**:
- **LeaderboardView**: Limits are appropriate for leaderboard functionality
- **FeedView**: Limits are appropriate for feed (showing recent activity)

### ⚠️ **Needs Attention**:
- **HomeDashboardView**: `users` limit of 10 is risky - might not include current user
  - **Recommendation**: Remove limit or ensure current user is always included
  - **Alternative**: Use `@Query` without limit, filter in ViewModel

---

## Recommended Changes

### HomeDashboardView.swift
```swift
// Option 1: Remove limit (users table is typically small anyway)
@Query(sortBy: [SortDescriptor(\User.createdAt, order: .reverse)]) 
private var users: [User]

// Option 2: Increase limit to ensure current user is included
@Query(sortBy: [SortDescriptor(\User.createdAt, order: .reverse)], fetchLimit: 100) 
private var users: [User]

// Routines: Filter by userID if possible, or increase limit
@Query(sortBy: [SortDescriptor(\DailyRoutine.createdAt, order: .reverse)], fetchLimit: 200) 
private var routines: [DailyRoutine]
```

### LeaderboardView.swift
```swift
// Current limits are good, but consider:
// 1. Always include current user in leaderboard (even if rank > 100)
// 2. Show "Your Rank" separately if not in top 100
```

