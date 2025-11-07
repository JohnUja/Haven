# Fixes Summary - January 13, 2025

## Issues Fixed

### 1. ✅ Guest Mode Persistence Issue
**Problem**: App was stuck in guest mode, couldn't access sign-on pages for testing.

**Solution**:
- Added **debug option** in `TimeFlowApp.swift` to automatically clear guest auth on app launch (DEBUG builds only)
- Added **"Sign Out" button** in ProfileView settings with confirmation dialog
- Sign out now clears guest task count and persisted dates

**Files Changed**:
- `Haven2.0/TimeFlowApp.swift` - Auto-clear guest auth on launch (DEBUG only)
- `Haven2.0/Views/ProfileView.swift` - Added sign out button and handler

---

### 2. ✅ Day Scroller Memory Issue
**Problem**: When user scrolls to a future day (e.g., 45 days ahead) and creates a task, returning to the app resets the scroller to today, losing their position.

**Solution**:
- Created `DatePersistenceService` to persist selected dates
- App now remembers:
  1. **Last worked date** (when task is created on a future date) - highest priority
  2. **Last selected date** (when user scrolls to a date) - second priority
  3. Falls back to today if neither exists
- When task is created on a future date, that date is saved as "last worked date"
- On app launch, the scroller restores to the last worked date or last selected date

**Files Changed**:
- `Haven2.0/Services/DatePersistenceService.swift` - **NEW FILE** - Date persistence service
- `Haven2.0/Views/HomeDashboardView.swift` - Restore selected date on launch
- `Haven2.0/Views/AddTaskView.swift` - Save date when task created on future date
- `Haven2.0/Views/Components/InfiniteDaySelector.swift` - Persist date on scroll

---

### 3. ✅ Calendar System Bugs
**Problem**: 
- Calendar height keeps shifting when scrolling
- Calendar appears within another background element
- Calendar not connected to day scroller

**Solution**:
- **Fixed height constraints** on all calendar sections:
  - Month/Year header: Fixed 60px height
  - Days of week header: Fixed 30px height
  - Calendar grid: Fixed 240px height (6 rows)
- **Removed background conflicts** - Added explicit `.background(Color(.systemBackground))` to calendar modal
- **Synchronized calendar with day scroller**:
  - Calendar month updates when `selectedDate` changes from day scroller
  - Calendar selection updates `selectedDate` and persists it
  - Both systems now work together seamlessly

**Files Changed**:
- `Haven2.0/Views/Components/MonthCalendarView.swift` - Fixed heights, added sync logic
- `Haven2.0/Views/HomeDashboardView.swift` - Calendar modal improvements, date persistence

---

## New Features

### Date Persistence Service
A new service that manages date persistence across app launches:

```swift
DatePersistenceService.shared.saveSelectedDate(date)      // Save when user scrolls
DatePersistenceService.shared.saveLastWorkedDate(date)     // Save when task created on future date
DatePersistenceService.shared.restoreSelectedDate()         // Restore last selected
DatePersistenceService.shared.restoreLastWorkedDate()       // Restore last worked
DatePersistenceService.shared.clearAllDates()               // Clear all (on sign out)
```

**Priority Order** (on app launch):
1. Last worked date (if task was created on future date)
2. Last selected date (if user scrolled to a date)
3. Today (default)

---

## Testing Instructions

### Test Guest Mode Clearing
1. Sign in as guest
2. Close and reopen app
3. **Expected**: Guest auth is cleared (DEBUG builds only), you see login screen

### Test Day Scroller Memory
1. Scroll to a future date (e.g., 45 days ahead)
2. Create a task on that date
3. Close and reopen app
4. **Expected**: Scroller restores to the date where you created the task

### Test Calendar Sync
1. Open calendar modal (tap "NOV 2025" button)
2. Select a date in the calendar
3. **Expected**: Day scroller updates to that date
4. Scroll day scroller to a different date
5. Open calendar modal again
6. **Expected**: Calendar shows the month of the selected date

### Test Sign Out
1. Go to Profile tab
2. Scroll to "Account" section
3. Tap "Sign Out"
4. Confirm sign out
5. **Expected**: Returns to login screen, guest task count cleared, dates cleared

---

## Notes

- **DEBUG Mode**: Guest auth auto-clearing only works in DEBUG builds. Remove the `#if DEBUG` block if you want this in production (not recommended).
- **Date Range**: Persisted dates are only restored if within 365 days (1 year) range to prevent invalid dates.
- **Calendar Heights**: Fixed heights prevent layout shifts but may need adjustment for different screen sizes.

---

## Files Created
- `Haven2.0/Services/DatePersistenceService.swift` - Date persistence service

## Files Modified
- `Haven2.0/TimeFlowApp.swift` - Guest auth clearing
- `Haven2.0/Views/ProfileView.swift` - Sign out button
- `Haven2.0/Views/HomeDashboardView.swift` - Date restoration, calendar sync
- `Haven2.0/Views/AddTaskView.swift` - Save date on task creation
- `Haven2.0/Views/Components/MonthCalendarView.swift` - Fixed heights, sync logic
- `Haven2.0/Views/Components/InfiniteDaySelector.swift` - Date persistence

