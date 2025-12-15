# Leaderboard Theme-Aware Styling

## Summary

Updated leaderboard to use **theme-controlled colors** where appropriate, while keeping **static colors** for universal indicators (green/red for zones).

---

## Theme-Aware Elements (Dynamic)

### Colors:
- **Top 3 Badge**: `theme.accentColor` (adapts to theme)
- **Rank Badge (1st)**: `theme.accentColor`
- **Rank Badge (2nd)**: `theme.textSecondary`
- **Rank Badge (3rd)**: `theme.accentColor.opacity(0.8)`
- **Rank Badge (Others)**: `theme.textPrimary.opacity(0.6)`
- **Avatar Gradient (Current User)**: `theme.accentColor` gradient
- **Avatar Gradient (Others)**: `theme.textSecondary` opacity
- **Username Text**: `theme.textPrimary`
- **Level Text**: `theme.textSecondary`
- **Zone Indicator (Top 3)**: `theme.accentColor`
- **Zone Indicator (Stationary)**: `theme.textSecondary`
- **League Name**: `theme.textPrimary`
- **Time Remaining Icon**: `theme.accentColor`
- **Time Remaining Text**: `theme.textPrimary`
- **Time Remaining Background**: `theme.accentColor.opacity(0.25)`

### Fonts:
- **League Name**: `theme.headerFont`
- **Time Remaining**: `theme.bodyFont`
- **Username**: System font (consistent size)
- **Score**: System font (consistent size)

---

## Static Colors (Universal)

### Why Static?
These colors have universal meaning and should be consistent across all themes:

- **Green**: Advancement zone (universal positive indicator)
- **Red**: Demotion zone (universal danger indicator)
- **White/Black**: Text shadows (for readability on gradients)

### Static Elements:
- **Zone Indicator (Advancing)**: `.green` (static)
- **Zone Indicator (Demoted)**: `.red` (static)
- **Zone Badge (Advancing)**: `.green` (static)
- **Zone Badge (Demoted)**: `.red` (static)

---

## Zone Markers (Duolingo-Style)

### Visual Indicators:

1. **Zone Indicator Bar** (Left Edge - 4pt width):
   - Vertical bar on left side of each row
   - Color-coded by zone:
     - **Top 3**: Theme accent (dynamic)
     - **Advancing**: Green (static)
     - **Stationary**: Theme text secondary (dynamic)
     - **Demoted**: Red (static)

2. **Zone Badge** (For Current User Only):
   - Icon + text showing zone status
   - Positioned next to score
   - Theme-aware colors where appropriate

---

## Implementation Details

### Zone Indicator Bar:
```swift
@ViewBuilder
private func zoneIndicatorBar(position: LeaguePosition, theme: any AppTheme) -> some View {
    Rectangle()
        .fill(position.color(theme: theme))
        .frame(maxHeight: .infinity)
        .opacity(0.7)
}
```

### Theme-Aware Color Function:
```swift
func color(theme: any AppTheme) -> Color {
    switch self {
    case .top3: return theme.accentColor // Dynamic
    case .advancing: return .green // Static
    case .stationary: return theme.textSecondary // Dynamic
    case .demoted: return .red // Static
    }
}
```

---

## Rewards System (Future)

### Duolingo's System:
- **Top 3**: Gems (20, 10, 5 in Bronze; increases with league)
- **Weekly reset**: Awards given at end of week

### Our Future Implementation:
- **Top 3**: XP + Crystals (scaled by league)
- **Top 10**: Bonus XP
- **Top 25**: Standard XP
- **Bottom 5**: No bonus

**Status**: Not implemented yet (future version)

---

## Summary

✅ **Theme-Aware**: Top 3, rank badges, avatars, text colors, zone indicators (top 3, stationary)
✅ **Static**: Advancement zone (green), demotion zone (red)
✅ **Zone Markers**: Visual indicators on left edge + badges for current user
✅ **Future**: Rewards system (not implemented)

---

**Status**: ✅ Complete
**Date**: 2025-01-XX

