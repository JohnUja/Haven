# Pending Questions & Next Implementation Steps

## ✅ Fixed Issues
1. **Compilation Error** - Fixed Int to Double conversion in `ImmersiveWorkingOnView.swift`
2. **GoalsView Structure** - Fixed missing closing brace in ZStack
3. **ThemeManager** - Fixed @EnvironmentObject to @Environment usage

---

## ❓ Questions That Need Answers

### 1. **Goal Reflections Implementation** (High Priority)

**Current Status:** The current method for adding reflections to goal-linked tasks is broken and needs a new approach.

**Questions to Answer:**
1. **When should reflections be prompted?**
   - After completing a goal-linked task?
   - After completing a milestone?
   - After completing the entire goal?
   - All of the above?

2. **What should the reflection prompt ask?**
   - Open-ended journal entry?
   - Structured questions (e.g., "What went well?", "What could be improved?")?
   - Mood/emotion selection + text?
   - Photo upload option?

3. **UI/UX Approach:**
   - Should it be a modal sheet that appears automatically?
   - Should it be a button/option that appears after completion?
   - Should it be skippable or required?
   - Should it have a "Remind me later" option?

4. **Paywall Integration:**
   - Which paid plans get access? (Any paid plan, or only Pro?)
   - Should free users see a preview/teaser?
   - Should there be a limit on reflections per month for free users?

5. **Data Storage:**
   - Store as `JournalEntry` linked to task/goal?
   - Separate `GoalReflection` model?
   - Include in goal completion summary?

**Recommendation Needed:** We need to decide on the user flow and data model before implementing.

---

### 2. **Subscription Downgrade Logic** (High Priority)

**Current Status:** No logic exists for handling users switching from premium to free tier.

**Questions to Answer:**
1. **What happens to premium features when downgrading?**
   - **Tasks/Routines:** 
     - Keep all existing tasks/routines but prevent creating new ones beyond free limits?
     - Archive excess tasks/routines (keep but hide)?
     - Delete excess tasks/routines?
     - Warn user before downgrade about what will be affected?

   - **Themes:**
     - Keep unlocked themes but can't unlock new ones?
     - Lock premium themes but keep free/default?
     - Grandfather in themes purchased while premium?

   - **AI Insights:**
     - Keep existing insights but stop generating new ones?
     - Delete all AI insights?
     - Limit to 3/week going forward?

   - **Cloud Backups:**
     - Keep existing backups but stop new ones?
     - Delete all backups?
     - Allow export before deletion?

2. **Downgrade Warning Flow:**
   - Show warning before downgrade with list of what will be affected?
   - Give user options (e.g., "Archive excess tasks" vs "Delete excess tasks")?
   - Allow export of data before downgrade?

3. **Timing:**
   - Immediate downgrade when subscription ends?
   - Grace period (e.g., 7 days) before features are locked?
   - Soft limit (warn but allow) vs hard limit (block action)?

4. **Data Preservation:**
   - Should we create a "downgrade snapshot" that saves state?
   - Should users be able to restore if they upgrade again within X days?

**Recommendation Needed:** We need to define the exact behavior for each feature category.

---

### 3. **Feed Logic Definition** (Medium Priority)

**Current Status:** `FeedView` exists as a placeholder. Need to define what information should be displayed.

**Questions to Answer:**
1. **What content should appear in the feed?**
   - **Streaks:** Daily completion streaks, longest streak, current streak?
   - **Points/XP:** Level ups, milestone achievements (e.g., "Reached 1000 XP!")?
   - **Goals:** Goal completions, milestone completions, goal progress updates?
   - **Routines:** Routine completion streaks, routine milestones?
   - **Tasks:** Task completion milestones (e.g., "Completed 100 tasks!")?
   - **Social:** Leaderboard rankings, friend achievements (if social features added)?

2. **Feed Structure:**
   - Chronological timeline (newest first)?
   - Grouped by type (streaks, goals, points)?
   - Personalized (only user's achievements)?
   - Community feed (global achievements, anonymized)?

3. **Update Frequency:**
   - Real-time updates?
   - Batch updates (e.g., once per day)?
   - On-demand refresh?

4. **Visual Design:**
   - Card-based layout?
   - List view?
   - Timeline view?
   - Celebratory animations?

5. **Filtering/Sorting:**
   - Filter by type (streaks, goals, etc.)?
   - Sort by date, importance, type?
   - Search functionality?

**Recommendation Needed:** Define the feed's purpose and content structure.

---

### 4. **Theme System Definition** (Medium Priority)

**Current Status:** Basic theme system exists (`AppTheme` protocol, `ThemeManager`), but we need to define what components change based on theme.

**Questions to Answer:**
1. **What UI components should change with themes?**
   - **Colors:**
     - Primary/secondary/accent colors?
     - Task card colors?
     - Background gradients?
     - Text colors (primary/secondary)?
     - Button colors?
     - Timeline colors?

   - **Backgrounds:**
     - Screen backgrounds (gradient vs solid)?
     - Card backgrounds (glass effect vs solid)?
     - Timeline background?
     - Immersive mode background?

   - **Lighting/Contrast:**
     - Light mode vs dark mode variants?
     - Contrast ratios for accessibility?
     - Shadow styles?
     - Glow effects?

   - **Typography:**
     - Font weights?
     - Font sizes (should themes change sizes)?
     - Font families (if custom fonts added)?

   - **Shapes:**
     - Corner radius (rounded vs sharp)?
     - Card shapes (rounded rectangle vs pill)?
     - Button shapes?

   - **Animations:**
     - Animation speeds?
     - Animation styles (bounce, smooth, etc.)?
     - Particle effects?

2. **Theme Categories:**
   - **Mood-based themes:** One theme per mood (calm, energetic, focused, etc.)?
   - **Shop themes:** Premium unlockable themes?
   - **Time-based themes:** Themes that change based on time of day?
   - **Seasonal themes:** Themes that change based on season?

3. **Theme Application:**
   - Global theme (all screens)?
   - Per-screen themes (different theme per tab)?
   - Dynamic themes (auto-change based on mood/time)?

4. **Theme Preview:**
   - Preview before applying?
   - Live preview in settings?
   - Preview cards in theme shop?

**Recommendation Needed:** Define the complete list of components that will change, and create a design system document.

---

## 📋 Next Implementation Steps (In Order)

### Phase 1: Answer Questions & Design
1. ✅ Fix compilation errors (DONE)
2. **Decide on Goal Reflections approach** (User input needed)
3. **Decide on Subscription Downgrade logic** (User input needed)
4. **Define Feed content and structure** (User input needed)
5. **Define Theme system components** (User input needed)

### Phase 2: Implement Core Features
1. **Goal Reflections:**
   - Create new reflection view/screen
   - Implement paywall check
   - Add reflection prompts at appropriate times
   - Store reflections in data model

2. **Subscription Downgrade:**
   - Implement downgrade detection
   - Create downgrade warning flow
   - Handle feature locking/unlocking
   - Implement data archiving/deletion logic

3. **Feed Logic:**
   - Implement feed data collection
   - Create feed item models
   - Build feed UI components
   - Add filtering/sorting

4. **Theme System:**
   - Define theme component mapping
   - Update all views to use theme colors
   - Create theme preview system
   - Implement mood-based theme switching

### Phase 3: Polish & Testing
1. Test all new features
2. Fix any bugs
3. Performance optimization
4. UI/UX refinements

---

## 🎯 Immediate Next Steps

**Before implementing, we need your input on:**

1. **Goal Reflections:** How should the reflection flow work? When should it appear? What should it ask?

2. **Subscription Downgrade:** What should happen to premium features when a user downgrades? Should we archive, delete, or warn?

3. **Feed:** What should the feed show? Personal achievements only, or community activity too?

4. **Themes:** What specific UI components should change with themes? (We can start with a basic list and expand)

Once you answer these questions, I can start implementing the features in the order listed above.

