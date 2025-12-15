# Leaderboard Rewards & Zone Markers

## Duolingo's Reward System

### Yes, Duolingo Awards Gems Based on Position:

**Bronze League:**
- 1st place: 20 gems
- 2nd place: 10 gems
- 3rd place: 5 gems

**Higher Leagues (Silver, Gold, etc.):**
- Rewards increase with league tier
- Diamond League: 75, 60, 50 gems for top 3

### Our Implementation (Future Version)

**Recommendation**: Implement rewards in a future version, not now.

**Proposed Rewards:**
- **Top 3**: XP + Crystals (scaled by league tier)
- **Top 10**: Bonus XP (advancement reward)
- **Top 25**: Standard XP
- **Bottom 5**: No bonus (demotion zone)

**Implementation Notes:**
- Awards given at weekly reset
- Scale rewards by league (Bronze = lower, Diamond = higher)
- Show reward preview in top 3 award popup
- Store reward history in User model

---

## Zone Markers (Duolingo-Style)

### Visual Indicators Added:

1. **Zone Indicator Bar** (Left Edge):
   - Thin vertical bar (4pt width) on left side of each row
   - Color-coded by zone:
     - **Top 3** (Ranks 1-3): Theme accent color (gold/yellow)
     - **Advancing** (Ranks 4-10): Green
     - **Stationary** (Ranks 11-25): Theme text secondary (gray)
     - **Demoted** (Ranks 26-30): Red

2. **Zone Badge** (For Current User):
   - Shows zone status with icon + text
   - Only visible for current user
   - Positioned next to score
   - Icons:
     - 🏆 Top 3: `star.fill`
     - ⬆️ Advancing: `arrow.up.circle.fill`
     - ➡️ Stationary: `minus.circle.fill`
     - ⬇️ Demoted: `arrow.down.circle.fill`

### Zone Breakdown:

| Rank Range | Zone | Color | Action |
|------------|------|-------|--------|
| 1-3 | 🏆 Top 3 | Theme Accent | Get awards + advance |
| 4-10 | ⬆️ Advancing | Green | Advance to next league |
| 11-25 | ➡️ Stationary | Theme Gray | Stay in current league |
| 26-30 | ⬇️ Demoted | Red | Get demoted |

---

## Theme-Controlled Styling

### Static Colors (Consistent Across Themes):
- **Green**: Advancement zone (universal positive)
- **Red**: Demotion zone (universal danger)
- **White/Black**: Text shadows (for readability)

### Dynamic Colors (Theme-Aware):
- **Top 3 Badge**: `theme.accentColor` (adapts to theme)
- **Rank Badge**: `theme.accentColor` for 1st, `theme.textSecondary` for 2nd
- **Avatar Gradient**: `theme.accentColor` for current user
- **Text Colors**: `theme.textPrimary`, `theme.textSecondary`
- **Backgrounds**: `theme.glassBackground`, `theme.glassBorder`
- **Zone Indicator**: Top 3 uses `theme.accentColor`, Stationary uses `theme.textSecondary`

### Fonts (Theme-Aware):
- **League Name**: `theme.headerFont`
- **Time Remaining**: `theme.bodyFont`
- **Username**: System font (consistent size)
- **Score**: System font (consistent size)

---

## Implementation Status

### ✅ Completed:
- Zone indicator bars (left edge)
- Zone badges (for current user)
- Theme-aware colors for dynamic elements
- Static colors for universal indicators (green/red)

### 🔜 Future:
- XP/Crystal rewards based on position
- Reward history tracking
- League-specific reward scaling
- Reward preview in top 3 popup

---

## Code Examples

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

### Theme-Aware Colors:
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

**Status**: ✅ Zone markers implemented, theme-aware styling complete
**Future**: Rewards system (not implemented yet)

