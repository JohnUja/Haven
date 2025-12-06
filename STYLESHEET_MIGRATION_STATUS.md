# Stylesheet Migration Status

## ✅ Completed Migrations

### Core Views
- ✅ **Sign-In Page** (`FirebaseAuthenticationView.swift`) - Solid black background, Montserrat fonts
- ✅ **Home Dashboard** (`HomeDashboardView.swift`) - Focus/Plan modes, stylesheet integrated
- ✅ **Dynamic Focus Box** (`DynamicFocusBox.swift`) - Priority colors, stylesheet fonts
- ✅ **Settings View** (`SettingsView.swift`) - Partially migrated
- ✅ **Profile View** (`ProfileView.swift`) - Migrated common patterns
- ✅ **Goals View** (`GoalsView.swift`) - Headers migrated
- ✅ **Feed View** (`FeedView.swift`) - Header migrated

## 🔄 In Progress

### Remaining Font Migrations
Many views still have hardcoded fonts that should use `AppStyleSheet`:

**Common Patterns to Replace:**
- `.font(.system(size: 12, weight: .regular, design: .rounded))` → `AppStyleSheet.font(for: .settingsText)`
- `.font(.system(size: 14, weight: .semibold, design: .rounded))` → `AppStyleSheet.font(for: .body)`
- `.font(.system(size: 16, weight: .regular, design: .rounded))` → `AppStyleSheet.font(for: .body)`
- `.font(.system(size: 24, weight: .bold, design: .rounded))` → `AppStyleSheet.font(for: .sectionHeader)`
- `.font(.system(size: 32, weight: .bold, design: .rounded))` → `AppStyleSheet.font(for: .pageHeader)`
- Gamified numbers (36pt bold) → `AppStyleSheet.font(for: .gamifiedNumber)` with `.appTextStyle(.gamifiedNumber, theme:)`

## 📋 Views Needing Migration

### High Priority
1. **ProfileView.swift** - Some remaining hardcoded fonts
2. **SettingsView.swift** - Complete remaining migrations
3. **AddTaskView.swift** - Check gradient background
4. **OnboardingView.swift** - Check gradient background
5. **GoalReflectionView.swift** - Check gradient background
6. **PaywallView.swift** - Already has gradient, verify fonts
7. **GoalsDetailView.swift** - Check gradient background
8. **LeaderboardView.swift** - Check gradient background

### Medium Priority
9. **RoutineManagerView.swift**
10. **RoutineSetupView.swift**
11. **EditBlockView.swift**
12. **DataVisualizationView.swift**
13. **ProfileEditView.swift**
14. **AddBlockView.swift**
15. **DeveloperModeView.swift**

### Component Views
16. **TimelineTimeIndicatorView.swift**
17. **ContinuousTimelineView.swift**
18. **DailySummaryPopUpView.swift**
19. **ImmersiveWorkingOnView.swift**
20. **UnifiedDraggableTimelineItem.swift**

## 🎨 Gradient Background Consistency

### Standard Gradient Pattern
All views should use:
```swift
ZStack {
    themeManager.currentTheme.primaryGradient
        .ignoresSafeArea()
    
    // Content here
}
```

Or for sheets/modals:
```swift
LinearGradient(
    colors: [
        Color.purple.opacity(0.8),
        Color.blue.opacity(0.6),
        Color.pink.opacity(0.4)
    ],
    startPoint: .topLeading,
    endPoint: .bottomTrailing
)
.ignoresSafeArea()
```

### Views to Check
- ✅ HomeDashboardView - Has gradient
- ✅ ProfileView - Has gradient
- ✅ SettingsView - Has gradient
- ✅ GoalsView - Has gradient
- ✅ FeedView - Has gradient
- ✅ PaywallView - Has gradient
- ✅ DataVisualizationView - Has gradient
- ✅ MoodCheckInView - Has gradient
- ✅ GoalReflectionView - Has gradient
- ⏳ AddTaskView - Needs verification
- ⏳ OnboardingView - Needs verification
- ⏳ Other views - Need verification

## 📝 Migration Checklist

For each view:
- [ ] Replace hardcoded fonts with `AppStyleSheet.font(for:)`
- [ ] Use `.appTextStyle()` for headers with shadows
- [ ] Ensure gradient background is applied
- [ ] Check text colors (should be white on gradient backgrounds)
- [ ] Verify shadows on headers/gamified numbers
- [ ] Test in different themes (Dark, Light, Purple)

## 🚀 Quick Migration Script

To find all hardcoded fonts:
```bash
grep -r "\.font(\.system(size:" Haven2.0/Views --include="*.swift"
```

To find views without gradient:
```bash
grep -r "Color\.white\.ignoresSafeArea\|ZStack.*Color\.white" Haven2.0/Views --include="*.swift"
```

