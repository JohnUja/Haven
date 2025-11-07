# Goals System - Architecture Decisions

## 1. Target Value Clarification ✅

**Question:** What does "Target" represent when creating a goal, especially when incrementing?

**Answer:** 
- **Target = Count of Tasks to Complete**
- When you set `targetValue: 5`, it means: "5 tasks must be completed to achieve this goal"
- Each time a linked task is marked complete → `currentValue` increments by 1
- When `currentValue >= targetValue` → Goal is marked complete

**UI Update:** Added helper text: "How many tasks must be completed to achieve this goal?"

---

## 2. Task-to-Goal Linking Architecture

### Current Implementation:
- Tasks can be linked to goals via `goalID` and optional `milestoneID`
- Tasks are linked **after creation** (existing tasks or new ones)
- Linking doesn't transform the task - it just adds metadata

### Your Questions:

**Q: Should we prevent unauthorized tasks (tasks with no relation to goal)?**
**A: NO** - We should allow any task to be linked to any goal. The user decides what's relevant.

**Q: Should we scrap adding tasks to goals completely?**
**A: NO** - The linking approach is flexible and user-friendly.

**Q: Should we transform tasks "in-flight" when adding?**
**A: PARTIALLY** - When creating a NEW task specifically for a goal (via "Add Task to Goal"), we set the `goalID` immediately. For existing tasks, we just link them.

**Q: How are goal tasks actually created?**
**A:** Two ways:
1. **Create new task** → Via "Add Task to This Goal" → Creates task with `goalID` set
2. **Link existing task** → Via "Add Task to This Goal" → Updates existing task's `goalID`

---

## 3. Recurring Goal Tasks

**Question:** Should goal tasks be recurring (every day, every other day, user-selected days)?

**Answer:** **NO for MVP** - Goal tasks are regular tasks with a link. They follow normal task rules:
- Can be one-time or recurring (via existing recurrence system)
- Recurrence is set at task creation, not goal creation
- Goal tracks completion count, not frequency

**Future Enhancement:** Could add "template tasks" that auto-create recurring instances when linked to goals.

---

## 4. Milestone Tasks

**Question:** Should different milestones have different tasks?

**Answer:** **YES** - Already implemented!
- Tasks can have `milestoneID` (optional)
- If `milestoneID` is set, task belongs to that milestone
- If `milestoneID` is nil but `goalID` is set, task belongs to goal (not milestone)
- Each milestone tracks progress separately

**How it works:**
- When adding task to goal → User can optionally select a milestone
- Milestone progress = completed tasks in that milestone / total tasks in that milestone
- Goal progress = completed goal tasks / target tasks

---

## 5. Add Task to Goal - Detailed Flow

### Current Flow (Good ✅):
1. Long-press goal → "Add Task to This Goal"
2. User chooses:
   - **Create New Task**: Enter details → Task created with `goalID` (and optional `milestoneID`)
   - **Link Existing Task**: Browse unlinked tasks → Select → Task's `goalID` updated

### Enhancements Needed:
- ✅ Search/filter for existing tasks (DONE)
- ✅ Show task details in selection list
- ⚠️ Add "Remove from Goal" button (currently only swipe in detail view)

---

## 6. Data Points for Widgets & AI

### For Widgets (Home Screen, Lock Screen):
1. **Goal Progress** - Current vs Target count, percentage
2. **Active Goals** - Count of active goals
3. **Upcoming Deadlines** - Goals with deadlines approaching
4. **Today's Goal Tasks** - Count of goal tasks scheduled today
5. **Milestone Progress** - If milestones exist, show next milestone

### For AI Learning:
1. **Goal Completion Patterns** - Which categories succeed, failure rates
2. **Task-to-Goal Linking Patterns** - Which task types link to which goals
3. **Journal Insights** - Sentiment, common themes in reflections
4. **Timing Patterns** - When users complete goal tasks (time of day, day of week)
5. **Milestone Effectiveness** - Do milestones improve completion rates?

### For Database Storage (when deleted):
1. **Archive goals** - Keep for analytics, soft delete
2. **Keep journal entries** - For AI insights, anonymized
3. **Task history** - Link preserved for audit trail

---

## 7. Implementation Status

### ✅ Completed:
- Goal model with milestones, priority, status
- Task linking (`goalID`, `milestoneID`)
- Progress tracking (auto-increment on task completion)
- Goal detail view
- Add Task to Goal with search
- Journaling system with images
- Priority sorting

### 🔄 In Progress:
- Floating menu for goals (replacing sheet)
- Milestone progress visualization (bars)

### 📋 Pending:
- Widget data points
- AI analytics structure
- Archive/soft delete system

---

## Next Steps

1. **Implement floating menu for goals** (black background, like tasks)
2. **Clarify target value in UI** (done)
3. **Keep current linking architecture** (flexible, user-friendly)
4. **No recurring goal tasks** (use existing recurrence for tasks)
5. **Milestones can have different tasks** (already works)

