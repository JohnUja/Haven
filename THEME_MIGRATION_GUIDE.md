# Theme Migration Guide

## Overview
This document tracks all places where hardcoded colors, corner radius values, and other styling should be replaced with theme-aware values.

## ✅ Completed Migrations

### Core Theme System
- ✅ AppTheme protocol enhanced with glassmorphism properties
- ✅ All themes (Purple, Light, Dark, Energetic, Calm) have glassmorphism properties
- ✅ AppStyleSheet with theme-aware text shadows
- ✅ ThemeHelpers.swift created with helper extensions

### Views Migrated
- ✅ HomeDashboardView - Uses themeManager
- ✅ SettingsView - Uses themeManager and AppStyleSheet
- ✅ FeedView - Uses themeManager and AppStyleSheet
- ✅ ProfileView - Popups use theme colors
- ✅ MomentumPageView - Replaced with popup using theme
- ✅ DynamicFocusBox - Uses theme colors and corner radius
- ✅ TaskCardView - Uses theme.cardCornerRadius

## 🔄 In Progress / Needs Migration

### High Priority - Hardcoded Colors
These views have hardcoded `Color.white`, `Color.black`, `Color.purple`, etc. that should use `theme.textPrimary`, `theme.glassBackground`, etc.:

1. **ProfileView.swift**
   - Line 1110-1116: Popup background (FIXED)
   - Other popups need checking

2. **TaskBlockCardView.swift**
   - Line 178-196: Card background (FIXED)
   - Uses theme.cardCornerRadius now

3. **HomeDashboardView.swift**
   - Line 2693-2700: Completion ring popup (FIXED)
   - TaskCardView cardBackground (FIXED)

4. **TimelineView.swift**
   - Line 953-960: Task cards use hardcoded cornerRadius: 8
   - Line 970: Color.black.opacity(0.6) should use theme.cardShadow

5. **Components/RecentItemCard.swift**
   - Line 104: Color.gray.opacity(0.3) should use theme.glassBackground
   - Line 107: theme.accentColor.opacity(0.2) - OK but could use theme.glassBorder

6. **Components/MomentumPopupView.swift**
   - Line 254-268: Uses hardcoded cornerRadius: 20, should use theme.cardCornerRadius
   - Uses .ultraThinMaterial instead of theme.glassBackground

7. **Views with hardcoded cornerRadius:**
   - Many views use `cornerRadius: 12` or `cornerRadius: 20` instead of `theme.cardCornerRadius`
   - Search pattern: `RoundedRectangle(cornerRadius: [0-9]+)`

### Medium Priority - Missing ThemeManager

Views that don't have `@Environment(ThemeManager.self) private var themeManager`:

1. **AddTaskView.swift** - Check if it has themeManager
2. **EditTaskView.swift** - Check if it has themeManager
3. **OnboardingView.swift** - Check if it has themeManager
4. **PaywallView.swift** - Check if it has themeManager
5. **GoalReflectionView.swift** - Check if it has themeManager
6. **MoodCheckInView.swift** - Check if it has themeManager
7. **DataVisualizationView.swift** - Check if it has themeManager
8. **LeaderboardView.swift** - Check if it has themeManager

### Low Priority - Text Colors

Views using hardcoded text colors:
- `Color.white` → `theme.textPrimary` (in dark mode) or `theme.textPrimary` (in light mode)
- `Color.black` → `theme.textPrimary` (in light mode)
- `Color.white.opacity(0.8)` → `theme.textPrimary.opacity(0.8)`

## 🔧 Migration Pattern

### Before:
```swift
RoundedRectangle(cornerRadius: 16)
    .fill(Color.black.opacity(0.9))
    .overlay(
        RoundedRectangle(cornerRadius: 16)
            .stroke(Color.white.opacity(0.3), lineWidth: 1)
    )
    .shadow(color: .black.opacity(0.5), radius: 8, x: 0, y: 4)
```

### After:
```swift
RoundedRectangle(cornerRadius: theme.cardCornerRadius)
    .fill(theme.glassBackground)
    .overlay(
        RoundedRectangle(cornerRadius: theme.cardCornerRadius)
            .stroke(theme.glassBorder, lineWidth: theme.cardBorderWidth)
    )
    .shadow(color: theme.cardShadow, radius: theme.shadowRadius, x: 0, y: 4)
```

### Or use helper:
```swift
.themedCardBackground(theme: themeManager.currentTheme)
```

## 📋 Quick Fix Checklist

For each view file:
- [ ] Add `@Environment(ThemeManager.self) private var themeManager` if missing
- [ ] Replace hardcoded `cornerRadius: 12/16/20` with `theme.cardCornerRadius`
- [ ] Replace `Color.white`/`Color.black` with `theme.textPrimary`
- [ ] Replace hardcoded card backgrounds with `theme.glassBackground`
- [ ] Replace hardcoded borders with `theme.glassBorder`
- [ ] Replace hardcoded shadows with `theme.cardShadow`
- [ ] Replace hardcoded border widths with `theme.cardBorderWidth`
- [ ] Replace hardcoded shadow radius with `theme.shadowRadius`

## 🎯 Priority Order

1. **Critical Views** (used most often):
   - HomeDashboardView ✅
   - ProfileView (partially done)
   - SettingsView ✅
   - FeedView ✅

2. **Component Views**:
   - TaskBlockCardView ✅
   - TaskCardView ✅
   - DynamicFocusBox ✅

3. **Secondary Views**:
   - TimelineView
   - GoalsView
   - RoutineManagerView

4. **Tertiary Views**:
   - OnboardingView
   - PaywallView
   - DataVisualizationView

