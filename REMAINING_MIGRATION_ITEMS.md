# Remaining Migration Items

## ✅ Completed (Settings, Feed, Homepage)

### SettingsView.swift ✅
- All cards now use `theme.glassBackground`, `theme.glassBorder`, `theme.cardCornerRadius`
- Icon circles use `theme.iconCircleSize` and `theme.iconBackgroundOpacity`
- Text colors use `theme.textPrimary` with `theme.textSecondaryOpacity` / `theme.textTertiaryOpacity`
- Padding uses `theme.cardPadding` and `theme.cardVerticalPadding`
- Spacing uses `theme.itemSpacing` and `theme.sectionSpacing`
- Stroke widths use `theme.selectedStrokeWidth` and `theme.cardBorderWidth`

### FeedView.swift ✅
- Card background uses `theme.glassBackground` instead of `.ultraThinMaterial`
- Icon circles use theme properties
- Text colors use theme opacity levels
- Popup cards use theme colors
- Comment input uses theme colors

### HomeDashboardView.swift ✅
- Summary card uses theme colors
- Filter chips use theme colors and spacing
- Agenda task cards use `theme.smallCornerRadius` and theme colors
- Section headers use theme text colors
- All padding/spacing uses theme values

## 🔄 Still Needs Migration

### Components (Medium Priority)

1. **Components/MomentumPopupView.swift**
   - Line 254: `cornerRadius: 20` → `theme.cardCornerRadius`
   - Uses `.ultraThinMaterial` → `theme.glassBackground`

2. **Components/RecentItemCard.swift**
   - Line 104: `Color.gray.opacity(0.3)` → `theme.glassBackground`
   - Line 107: Could use `theme.glassBorder`

3. **Components/DailySummaryView.swift**
   - Check for hardcoded colors and corner radius

4. **Components/LevelUpView.swift**
   - Check for hardcoded values

5. **Components/RewardAnimationView.swift**
   - Check for hardcoded values

### Other Views (Lower Priority)

6. **GoalsView.swift**
   - Check for hardcoded colors

7. **RoutineManagerView.swift**
   - Check for hardcoded values

8. **AddTaskView.swift**
   - Check for hardcoded values

9. **OnboardingView.swift**
   - Check for hardcoded values

10. **PaywallView.swift**
    - Check for hardcoded values

## 📊 Summary

**Total Views Checked:** 3 critical views (Settings, Feed, Homepage)
**Status:** ✅ All 3 critical views now use centralized theme system

**Remaining:** ~10 component/other views still need migration (lower priority)

## 🎯 Next Steps

1. Test Settings, Feed, and Homepage in different themes
2. Verify consistency across all three views
3. Migrate remaining components when needed
4. All new code should use theme properties from the start

