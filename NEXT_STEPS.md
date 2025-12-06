# Next Steps - Haven 2.0 Development Roadmap

## 📊 Current Status Summary

### ✅ **COMPLETED PHASES:**

#### **Phase 1: Foundation** ✅
- ✅ Light/Dark themes restricted to black/white/grey only
- ✅ All shadows removed (except theme-aware InfiniteDaySelector)
- ✅ Font system standardized (system default, semi-bold headers, regular body)
- ✅ Settings pages fixed (glassmorphism + theme-aware icons)
- ✅ Home page layout restructured (Focus/Plan tabs)

#### **Phase 2: View-Specific Fixes** ✅
- ✅ Timeline View (theme colors for date header, time labels, filter buttons)
- ✅ Feed View (segmented control glassmorphism, empty state, title colors)
- ✅ Goals View (text contrast, card backgrounds, progress rings)
- ✅ Plan View (filter system with up/down arrows, summary card, task cards)

#### **Phase 3: Feature Implementation** ✅ (Mostly Complete)
- ✅ Smart Context Aggregator (Category Sprint, Critical Focus, Upcoming Block, Next Action, Free Time)
- ✅ Long press menu (Start Focus Mode, Push 15m, Mark Complete, Break Down)
- ✅ Pagination (2 pages: Active Context + Next Major Block Preview)
- ✅ Preview Mode (from Agenda taps with "Start Now" button)
- ⚠️ Immersive View Mode (exists but needs verification)
- ⚠️ Date Scroller integration (needs verification)

---

## 🎯 **IMMEDIATE NEXT STEPS:**

### **1. Complete Phase 3 Remaining Items**
- [ ] **Verify Immersive View Mode Integration**
  - Check if `ImmersiveWorkingOnView` properly uses theme controllers
  - Ensure theme-aware colors throughout immersive mode
  - Test long press → immersive mode flow

- [ ] **Verify Date Scroller Integration**
  - Check `InfiniteDaySelector` in Timeline and Homepage
  - Ensure theme-aware shadows work correctly
  - Verify date picker functionality in Plan view

### **2. Phase 4: Theme Shop Integration**
- [ ] **Add Black/White/Purple as Default Themes**
  - Ensure all three themes are available in Theme Shop
  - Set Purple as default theme
  - Make Light and Dark themes unlockable/purchasable
  - Update Theme Shop UI to show these themes

- [ ] **Theme Shop UI Updates**
  - Use glassmorphism for theme preview cards
  - Theme-aware colors for shop interface
  - Proper unlock/purchase flow

### **3. MVVM Architecture Refactor** (High Priority)
- [ ] **Refactor HomeDashboardView**
  - Create `HomeDashboardViewModel.swift` (all logic, @Query, @State)
  - Create `DataStubs.swift` (shared model definitions)
  - Simplify `HomeDashboardView.swift` (UI only, bindings to ViewModel)
  - Move all business logic to ViewModel

- [ ] **Identify Other Views for MVVM**
  - TimelineView (complex drag/drop logic)
  - GoalsView (goal management logic)
  - FeedView (filtering/sorting logic)
  - ProfileView (user data management)

### **4. Location Bundle Feature** (Future Enhancement)
- [ ] **Add Location Field to Task Model**
  - Add `location: String?` property to Task
  - Update Task creation/editing UI
  - Implement location-based grouping in Smart Context Aggregator

### **5. AI Break Down Feature** (Future Enhancement)
- [ ] **Integrate AI Service**
  - Connect to AI service for task breakdown
  - Implement "Break Down" functionality in Dynamic Box
  - Create subtasks from parent task

---

## 🔧 **TECHNICAL DEBT & IMPROVEMENTS:**

### **Code Quality:**
- [ ] Remove all hardcoded colors (verify no remaining instances)
- [ ] Remove all hardcoded fonts (verify system fonts everywhere)
- [ ] Remove all hardcoded spacing values (use theme properties)
- [ ] Add missing day selector shadow properties to Energetic/Calm themes

### **Testing:**
- [ ] Test theme switching across all views
- [ ] Verify glassmorphism consistency
- [ ] Test Dynamic Box Smart Context Aggregator rules
- [ ] Test Preview Mode flow (Agenda → Dynamic Box → Start Now)
- [ ] Test long press menu functionality

### **Documentation:**
- [ ] Update architecture documentation
- [ ] Document Smart Context Aggregator rules
- [ ] Create theme customization guide
- [ ] Document MVVM pattern usage

---

## 📋 **PRIORITY ORDER:**

### **HIGH PRIORITY:**
1. ✅ Complete Phase 3 verification (Immersive View, Date Scroller)
2. ⚠️ MVVM Refactor for HomeDashboardView
3. ⚠️ Phase 4: Theme Shop integration

### **MEDIUM PRIORITY:**
4. Location Bundle feature (add location field)
5. AI Break Down feature integration
6. Code quality improvements

### **LOW PRIORITY:**
7. Additional theme options
8. Advanced Smart Context rules
9. Performance optimizations

---

## 🎨 **THEME-SPECIFIC NOTES:**

### **Light Theme:**
- Should look like Stoic app (black borders, black text, white background)
- All elements use black/white/grey only
- High contrast for readability

### **Dark Theme:**
- Inverted Light theme (white text, black background)
- All elements use black/white/grey only
- Reduced eye strain for night use

### **Purple Theme:**
- Default colorful theme
- Full color spectrum available
- Vibrant gradients and glassmorphism

---

## 🚀 **RECOMMENDED NEXT ACTION:**

**Start with Phase 3 verification**, then move to **MVVM refactor** for HomeDashboardView. This will:
1. Ensure all features work correctly
2. Improve code maintainability
3. Make future changes easier
4. Follow best practices

After MVVM refactor, proceed with **Phase 4: Theme Shop** to complete the theme system.

