# Project Audit And Roadmap

Last updated: 2026-03-14

## Executive Summary

Haven has a strong core product surface:
- auth and onboarding
- home dashboard
- timeline and scheduling
- goals and milestones
- routines
- themes and gamification

The project is not cleanly finished. The biggest gaps are not cosmetic; they are architectural and product-completion gaps:
- Firebase auth and local SwiftData user state are not unified
- Feed and leaderboard were disabled, but the removal is incomplete
- subscription and paywall flows are mostly UI with placeholder logic
- debug instrumentation and investigation artifacts are mixed into the main codebase
- repository documentation is duplicated, stale, and contradictory
- test coverage is effectively absent

## What Is Actually Unfinished

### 1. Auth And User Provisioning

Status: critical

Evidence:
- `Haven2.0/Views/FirebaseAuthenticationView.swift` still uses placeholder `typealias User = String` and `typealias Theme = String`
- `createOrUpdateLocalUser()` is explicitly not implemented
- `setupDefaultThemes(for:)` is explicitly not implemented
- `Haven2.0/Views/MainTabView.swift` still seeds a synthetic local user if no `User` exists

Impact:
- Firebase auth state and local app data can drift apart
- guest, test, and authenticated flows do not share one clear source of truth
- features that assume `users.first` is the real current user are fragile

### 2. Social / Feed / Leaderboard Removal

Status: partially removed, not cleanly resolved

Evidence:
- active tracked files were deleted and preserved as untracked `*.swift.disabled`
- `Haven2.0/TimeFlowApp.swift` has feed models commented out of the SwiftData schema
- `Haven2.0/Views/ProfileView.swift` still says `Leaderboard coming soon`
- profile copy still tells users to "compete in leaderboards"

Impact:
- product messaging no longer matches the shipped feature set
- feature removal is easy to partially commit because backups are untracked
- schema rollback risk is mixed into production startup behavior

### 3. Subscription / Monetization

Status: mostly placeholder

Evidence:
- `Haven2.0/Services/SubscriptionService.swift` always returns `.free`
- `Haven2.0/Views/PaywallView.swift` still has TODO purchase handlers
- `Haven2.0/Views/RoutineManagerView.swift` shows an upgrade prompt, but `View Plans` is not wired
- `Haven2.0/Documentation/PENDING_QUESTIONS_AND_NEXT_STEPS.md` still leaves downgrade behavior undefined

Impact:
- paywall and gating behavior are not trustworthy
- plan limits are not backed by a real subscription source of truth
- premium UX exists before premium behavior exists

### 4. Goal / Task Consistency

Status: partially working, still fragile

Evidence:
- `Haven2.0/Views/GoalsDetailView.swift` "Catch Up" marks tasks complete but leaves goal progress update commented out
- goal reflections remain an open design and implementation topic in `Haven2.0/Documentation/PENDING_QUESTIONS_AND_NEXT_STEPS.md`

Impact:
- user-visible progress can become stale
- goal completion logic is likely inconsistent across views

### 5. Profile / Account Management

Status: incomplete

Evidence:
- `Haven2.0/Views/ProfileEditView.swift` still has TODOs for avatar upload, Firestore username sync, email change, and phone updates
- `Haven2.0/Services/FirestoreService.swift` deletes only the root user document, not visible subcollections

Impact:
- profile editing is only partially real
- account deletion may leave server-side orphaned data

### 6. Rewards / Polish Features

Status: placeholder or partial

Evidence:
- `Haven2.0/Services/DailyRewardService.swift` returns placeholder reward values
- `Haven2.0/Views/HomeDashboardView.swift` still has TODOs for reflection/journal and filter modal
- `Haven2.0/Views/Components/QuickAddView.swift` has "Coming Soon" surfaces

Impact:
- polish features create expectation gaps
- several surfaces are effectively prototypes

### 7. Testing

Status: missing

Evidence:
- `Haven2.0Tests/Haven2_0Tests.swift` is still the generated placeholder

Impact:
- no safety net for auth, goals, onboarding, routines, or freeze regressions

## Past Complaints That Still Look Unresolved

Transcript evidence is limited, but repo artifacts and current code strongly suggest these complaints are still not fully resolved:

1. Freeze and hang issues were mitigated, not cleanly closed.
   Current code still includes investigation-oriented debug logging in active files and many freeze docs remain unverified or contradictory.

2. Feed and leaderboard problems were solved by disabling the feature, not by finishing the feature.
   That is a scope reduction, not a complete fix.

3. Product status reporting became unreliable.
   Example: `PROJECT_STATUS.md` still claims storage is in-memory only, while `Haven2.0/TimeFlowApp.swift` uses persistent disk storage first.

4. Goal reflections still do not have a settled flow.
   The repo still contains an open design document instead of a finished implementation.

5. Subscription downgrade behavior still appears undefined.
   This remains an explicit open question in project documentation.

## Documentation Problems

Current state:
- too many top-level markdown files
- multiple overlapping audit/fix/status docs
- conflicting claims like "all fixed" vs "pending" vs "disabled for v1.0"
- several investigation notes are still sitting in the repo root as if they are current source-of-truth docs

Examples of stale or conflicting docs:
- `PROJECT_STATUS.md`
- `ALL_FIXES_COMPLETE.md`
- `MAIN_THREAD_BLOCKING_SUMMARY.md`
- `ALL_PHASES_IMPLEMENTATION_SUMMARY.md`
- `FEEDVIEW_FREEZE_FIX_PLAN.md`
- `FEED_LEADERBOARD_DISABLED_STATUS.md`
- `CLEANUP_SUMMARY.md`

Recommended documentation cleanup:
- keep one canonical current-state document
- move incident/debug notes into an archive folder
- keep superseded implementation plans, but mark them archived
- delete empty placeholders only after verifying they are not still useful scratchpads

## Immediate Cleanup Priorities

### P0: Stabilize The App

1. Unify local `User` creation with Firebase UID
2. remove fake default-user seeding from `MainTabView` after real provisioning exists
3. decide whether feed/leaderboard is removed or paused
4. stop destructive store reset behavior on migration failure, or at minimum gate and document it
5. remove or gate debug logging and hard-coded debug endpoints

### P1: Finish Product Chains

1. finish subscription source of truth
2. wire paywall actions to real purchase behavior
3. define downgrade behavior
4. complete profile editing and account deletion cleanup
5. fix goal/task progress synchronization

### P2: Clean The Repo

1. create `docs/archive/`
2. move freeze/debug/audit notes out of root
3. keep only 1 current roadmap doc and 1 current status doc
4. remove stale placeholder backups after deciding the fate of social features
5. make sure required helper files like `Haven2.0/Views/Components/LazyView.swift` are tracked intentionally

### P3: Add Tests

1. auth provisioning tests
2. onboarding state tests
3. goal progress update tests
4. routine limit / subscription gating tests
5. smoke tests for tab navigation and task completion

## Roadmap Going Forward

### Phase 1: Product Decision Freeze

Goal: stop ambiguity before more code churn

Decisions needed:
- Is feed/leaderboard coming back, or is it removed from the product?
- What is the real subscription model for launch?
- How should downgrade behavior work?
- What is the exact goal reflection experience?

Output:
- one `CURRENT_STATUS.md`
- one `RELEASE_SCOPE.md`
- one archived docs folder for superseded notes

### Phase 2: Core Architecture Repair

Goal: fix source-of-truth problems

Work:
- implement `createOrUpdateLocalUser()`
- bind local user identity to Firebase UID
- remove placeholder auth/model code
- eliminate legacy auth path if Firebase auth is the final approach
- replace `users.first` assumptions with explicit current-user lookup

### Phase 3: Feature Completion

Goal: finish the features already visible in the product

Work:
- finish subscription state and paywall flow
- finish profile/account management
- fix goal progress synchronization
- either fully remove or fully restore social references
- complete remaining placeholder services like daily rewards

### Phase 4: Cleanup And Performance Hardening

Goal: make the codebase maintainable

Work:
- move business logic out of large views
- centralize logging behind a debug-only utility
- remove hard-coded local network endpoints and absolute file paths
- archive stale docs
- delete dead placeholders once validated

### Phase 5: Test Coverage

Goal: prevent repeat regressions

Work:
- add focused unit tests for services and model flows
- add a few end-to-end smoke tests for main user journeys

## Recommended First Execution Sprint

If work starts immediately, this is the best first sprint:

1. implement real local-user provisioning from Firebase auth
2. remove default-user seeding
3. decide and cleanly finalize feed/leaderboard removal
4. remove debug-log plumbing from production files
5. create a docs archive and reduce root markdown clutter

## UX Priorities From User Feedback

These were called out explicitly and should drive the next design-focused sprint:

1. `ProfileView` needs a visual and structural revamp.
   The current profile tab, "Your Progress" section, and settings area feel inverted, over-colored, and inconsistent with the intended glass-first white / purple / light theme language.

2. `SettingsView` needs a design pass.
   The settings screen works, but the hierarchy and color treatment do not feel aligned with the intended app style.

3. The end-of-day summary surfaces need theme alignment.
   The current daily summary / reward surfaces lean too hard on black cards and isolated color accents instead of the shared glass system.

4. Mood tracking and reflection need product clarification.
   `MoodSliderCheckInView` is visually implemented, but still needs behavioral validation. `GoalReflectionView` exists, but the purpose, trigger points, and user value are still not settled enough.

5. Task creation needs a low-friction inline path.
   The current add-task flow technically works, but it asks users to click through too much UI. The desired direction is a more direct, editable object model in the plan/timeline experience where a user can create a default task quickly, then tap fields inline to adjust name, priority, time, and category without a full-screen edit flow every time.

6. Timeline weather is a parked feature.
   The requested weather-reactive timeline background should stay in the parking lot for now and should not compete with the current stabilization and UX consistency work.

## Suggested UX Sprint Order

1. Profile and settings redesign cleanup
2. Daily summary / reward visual alignment
3. Quick-add and inline task editing concept
4. Mood / reflection flow definition
5. Weather timeline exploration after the above is stable

## Cleanup Done In This Pass

Completed in the audit cleanup pass:
- added `.gitignore` to ignore `.cursor/debug.log`
- removed stale feed / leaderboard placeholder messaging from active Swift files
- removed untracked `*.swift.disabled` feed / leaderboard backups from the worktree
- replaced hard-coded freeze-debug logging plumbing in active files with no-op stubs
- aligned daily summary surfaces and profile info popups more closely with the glass theme system

Still intentionally deferred:
- large-scale profile/settings redesign
- auth architecture repair
- subscription implementation
- documentation archiving / deletion at scale
