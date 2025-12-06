//
//  GoalsView.swift
//  TimeFlow
//
//  Created by John Uja on 2025-10-18.
//

import SwiftUI
import SwiftData
import UIKit
import AudioToolbox

struct GoalsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(ThemeManager.self) private var themeManager
    @Query private var goals: [Goal]
    @State private var showingAddGoal = false
    @State private var showingFloatingMenu: Goal? = nil
    @State private var showingEditGoal: Goal? = nil
    @State private var showingUpdateProgress: Goal? = nil
    @State private var showingAddTask: Goal? = nil
    @State private var showingDeleteConfirmation: Goal? = nil
    @State private var showingPauseConfirmation: Goal? = nil
    @State private var selectedGoal: Goal? = nil
    @State private var goalSortOrder: GoalSortOrder = .latest
    @Query private var allTasks: [Task]
    
    enum GoalSortOrder: String, CaseIterable {
        case latest = "Latest"
        case category = "Category"
        case dueDate = "Due Date"
        case progression = "Progression"
    }
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    // Delete goal and all linked tasks
    private func deleteGoalAndLinkedTasks(_ goal: Goal) {
        // Find all tasks linked to this goal
        let linkedTasks = allTasks.filter { $0.goal?.id == goal.id }
        
        // Delete all linked tasks
        for task in linkedTasks {
            modelContext.delete(task)
        }
        
        // Delete the goal
        modelContext.delete(goal)
        
        // Save changes
        try? modelContext.save()
    }
    
    private var sortedGoals: [Goal] {
        // Separate active and paused goals
        let activeGoals = goals.filter { $0.status != .paused }
        let pausedGoals = goals.filter { $0.status == .paused }
        
        // Sort active goals
        let sortedActive: [Goal]
        
        switch goalSortOrder {
        case .latest:
            // Last created at top
            sortedActive = activeGoals.sorted { $0.createdAt > $1.createdAt }
        case .category:
            sortedActive = activeGoals.sorted { g1, g2 in
                if g1.category.displayName != g2.category.displayName {
                    return g1.category.displayName < g2.category.displayName
                }
                return g1.title < g2.title
            }
        case .dueDate:
            // With due dates at top, without at bottom
            // If multiple without due, first created at lower position
            sortedActive = activeGoals.sorted { g1, g2 in
                if let d1 = g1.deadline, let d2 = g2.deadline {
                    return d1 < d2
                } else if g1.deadline != nil {
                    return true
                } else if g2.deadline != nil {
                    return false
                } else {
                    // Both have no due date - first created at lower position
                    return g1.createdAt < g2.createdAt
                }
            }
        case .progression:
            // Higher progress (90%+) at top, lower progress at bottom
            // Need tasks for accurate progress calculation
            let allTasks = (try? modelContext.fetch(FetchDescriptor<Task>())) ?? []
            sortedActive = activeGoals.sorted { g1, g2 in
                let g1Tasks = allTasks.filter { $0.goal?.id == g1.id }
                let g2Tasks = allTasks.filter { $0.goal?.id == g2.id }
                let p1 = g1.progressPercentage(tasks: g1Tasks)
                let p2 = g2.progressPercentage(tasks: g2Tasks)
                return p1 > p2
            }
        }
        
        // Sort paused goals by creation date (most recent first)
        let sortedPaused = pausedGoals.sorted { $0.createdAt > $1.createdAt }
        
        // Return active goals first, then paused goals at the bottom
        return sortedActive + sortedPaused
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background - purple gradient (matching home screen)
                themeManager.currentTheme.primaryGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Goals Heading (reduced size)
                        Text("Goals")
                            .font(.system(size: 18, weight: .semibold, design: .default)) // Reduced by 2
                            .foregroundColor(themeManager.currentTheme.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                            .padding(.top, 20)
                        
                        if sortedGoals.isEmpty {
                            emptyStateView
                        } else {
                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(sortedGoals) { goal in
                            GoalCardView(goal: goal)
                                .frame(height: 200) // Fixed height for consistency
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    // Always navigate on tap (long press is handled separately)
                                    selectedGoal = goal
                                }
                                .onLongPressGesture(minimumDuration: 0.3) {
                                    // Haptic feedback AFTER long press completes
                                    AudioServicesPlaySystemSound(1520) // Haptic vibration
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                                        showingFloatingMenu = goal
                                        // Don't set selectedGoal - long press should not navigate
                                    }
                                }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 20)
                }
            }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline) // Remove large heading
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Picker("Order by", selection: $goalSortOrder) {
                            ForEach(GoalSortOrder.allCases, id: \.self) { order in
                                Text(order.rawValue).tag(order)
                            }
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                            .font(.title3)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddGoal = true }) {
                        Image(systemName: "plus")
                            .font(.title3)
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddGoal) {
            AddGoalView()
        }
        .sheet(item: $showingEditGoal) { goal in
            EditGoalInlineView(goal: goal)
        }
        .sheet(item: $showingAddTask) { goal in
            AddTaskToGoalView(goal: goal)
        }
        .sheet(item: $selectedGoal) { goal in
            NavigationView {
                GoalsDetailView(goal: goal)
            }
        }
        .alert(item: $showingDeleteConfirmation) { goal in
            Alert(
                title: Text("Delete Goal?"),
                message: Text("This will permanently delete the goal and all linked tasks. This action cannot be undone."),
                primaryButton: .destructive(Text("Delete")) {
                    deleteGoalAndLinkedTasks(goal)
                },
                secondaryButton: .cancel()
            )
        }
        .alert(item: $showingPauseConfirmation) { goal in
            Alert(
                title: Text(goal.status == .paused ? "Resume Goal?" : "Pause Goal?"),
                message: Text(goal.status == .paused 
                    ? "This will add the goal and its tasks back to your workflow."
                    : "This will temporarily hide the goal and all its tasks from your workflow."),
                primaryButton: .default(Text(goal.status == .paused ? "Resume" : "Pause")) {
                    goal.status = goal.status == .paused ? .active : .paused
                    try? modelContext.save()
                },
                secondaryButton: .cancel()
            )
        }
        .overlay(
            Group {
                if let goal = showingFloatingMenu {
                    ZStack {
                        // Black background overlay
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                            .onTapGesture {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    showingFloatingMenu = nil
                                }
                            }
                        
                        // Floating menu
                        GoalFloatingActionMenu(
                            goal: goal,
                            onEdit: {
                                showingFloatingMenu = nil
                                showingEditGoal = goal
                            },
                            onAddTask: {
                                showingFloatingMenu = nil
                                showingAddTask = goal
                            },
                            onPause: {
                                showingFloatingMenu = nil
                                showingPauseConfirmation = goal
                            },
                            onDelete: {
                                showingFloatingMenu = nil
                                showingDeleteConfirmation = goal
                            },
                            onDismiss: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    showingFloatingMenu = nil
                                }
                            }
                        )
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.8).combined(with: .opacity).animation(.spring(response: 0.4, dampingFraction: 0.75)),
                            removal: .scale(scale: 0.8).combined(with: .opacity).animation(.spring(response: 0.3, dampingFraction: 0.8))
                        ))
                    }
                }
            }
        )
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "target")
                .font(.system(size: 64))
                .foregroundColor(.white.opacity(0.6))
            
            Text("Get Started")
                .appTextStyle(.sectionHeader, theme: themeManager.currentTheme)
            
            Text("Create a goal today and begin pursuing your goals or dreams")
                .font(AppStyleSheet.font(for: .body))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 80)
    }
}

struct GoalCardView: View {
    let goal: Goal
    @Query private var allTasks: [Task]
    @Environment(ThemeManager.self) private var themeManager
    
    private var goalTasks: [Task] {
        allTasks.filter { $0.goal?.id == goal.id }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header - Show goal name
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    // Goal name (Theme-Aware)
                    Text(goal.title)
                        .appTextStyle(.taskTitle, theme: themeManager.currentTheme)
                        .lineLimit(2)
                    
                    HStack(spacing: 4) {
                        Image(systemName: goal.category.icon)
                            .font(.system(size: 10, weight: .regular, design: .default))
                            .foregroundColor(goal.category.color())
                        
                        Text(goal.category.displayName)
                            .appTextStyle(.caption, theme: themeManager.currentTheme)
                            .opacity(themeManager.currentTheme.textSecondaryOpacity)
                    }
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    // Priority badge
                    Circle()
                        .fill(goal.effectivePriority.color)
                        .frame(width: 8.4, height: 8.4)
                    
                    if goal.status == .completed {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.green)
                    }
                }
            }
            
            // Progress Ring (Theme-Aware Background)
            ZStack {
                Circle()
                    .stroke(themeManager.currentTheme.textPrimary.opacity(0.2), lineWidth: 8)
                    .frame(width: 80, height: 80)
                
                Circle()
                    .trim(from: 0, to: goal.progressPercentage(tasks: goalTasks))
                    .stroke(
                        // Grey ring for paused goals, gradient for others
                        goal.status == .paused
                        ? LinearGradient(
                            colors: [Color.gray.opacity(0.5), Color.gray.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        : LinearGradient(
                            colors: [goal.category.color(), goal.category.color().opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.8, dampingFraction: 0.7), value: goal.progressPercentage(tasks: goalTasks))
                
                VStack {
                    Text("\(Int(goal.progressPercentage(tasks: goalTasks) * 100))%")
                        .appTextStyle(.body, theme: themeManager.currentTheme)
                        .opacity(goal.status == .paused ? themeManager.currentTheme.textTertiaryOpacity : 1.0)
                    
                    Text("\(goal.currentValue)/\(goal.effectiveTargetValue(tasks: goalTasks))")
                        .appTextStyle(.caption, theme: themeManager.currentTheme)
                        .opacity(themeManager.currentTheme.textSecondaryOpacity)
                }
            }
            .frame(maxWidth: .infinity)
            
            // Progress Description (Theme-Aware)
            // Special styling for "Add tasks to start tracking" with animation
            if progressDescription == "Add tasks to start tracking" {
                ZStack {
                    // Base text (smaller, light weight - reduced by 2-3 sizes)
                    Text(progressDescription)
                        .font(.system(size: 9, weight: .light, design: .default))
                        .foregroundColor(themeManager.currentTheme.textPrimary.opacity(0.7))
                        .multilineTextAlignment(.center)
                    
                    // Animated orange left-to-right swish/pulse
                    GoalShimmerEffect()
                        .mask(
                            Text(progressDescription)
                                .font(.system(size: 9, weight: .light, design: .default))
                        )
                }
            } else {
                Text(progressDescription)
                    .font(.system(size: 11, weight: .regular, design: .default)) // Reduced from body
                    .foregroundColor(themeManager.currentTheme.textPrimary.opacity(themeManager.currentTheme.textSecondaryOpacity))
                    .multilineTextAlignment(.center)
            }

            // Status subtitle and due date on same line (Theme-Aware)
            HStack {
                Text(statusSubtitle)
                    .appTextStyle(.caption, theme: themeManager.currentTheme)
                    .opacity(themeManager.currentTheme.textTertiaryOpacity)
                
                Spacer()
                
                if let deadline = goal.deadline {
                    Text(formatShortDate(deadline))
                        .appTextStyle(.caption, theme: themeManager.currentTheme)
                        .opacity(themeManager.currentTheme.textTertiaryOpacity)
                }
            }
        }
        .padding(themeManager.currentTheme.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: themeManager.currentTheme.cardCornerRadius)
                .fill(goalWidgetBackgroundColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: themeManager.currentTheme.cardCornerRadius)
                .stroke(borderColor, lineWidth: themeManager.currentTheme.cardBorderWidth)
        )
        .frame(height: 200) // Fixed height for all goal widgets
    }
    
    private var goalWidgetBackgroundColor: Color {
        // Black for dark theme, white for light theme, purple works (uses glassBackground)
        let theme = themeManager.currentTheme
        switch theme.id {
        case "light":
            return Color.white.opacity(0.9)
        case "dark":
            return Color.black.opacity(0.7)
        default:
            // Purple and other themes use glassBackground
            return theme.glassBackground
        }
    }
    
    private var borderColor: Color {
        // Grey border for paused goals
        if goal.status == .paused {
            return .gray
        }
        let insight = GoalStatusManager.evaluate(goal: goal, tasks: goalTasks)
        return GoalStatusManager.borderColor(for: insight.risk)
    }
    
    private var progressDescription: String {
        if goal.status == .completed {
            return "Goal completed! 🎉"
        } else {
            let effectiveTarget = goal.effectiveTargetValue(tasks: goalTasks)
            let remaining = max(effectiveTarget - goal.currentValue, 0)
            if effectiveTarget == 0 {
                return "Add tasks to start tracking"
            }
            return "\(remaining) more to go"
        }
    }

    private var statusSubtitle: String {
        // Show "Paused" for paused goals
        if goal.status == .paused {
            return "Paused"
        }
        let risk = GoalStatusManager.evaluate(goal: goal, tasks: goalTasks).risk
        switch risk {
        case .ahead: return "Ahead"
        case .onTrack: return "On Track"
        case .atRisk: return "At Risk"
        case .severe: return "Severe Risk"
        }
    }
    
    // MARK: - Shimmer Effect for Animated Text (Orange Swish/Pulse)
    struct GoalShimmerEffect: View {
        @State private var phase: CGFloat = 0
        
        var body: some View {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.orange.opacity(0),
                    Color.orange.opacity(0.8),
                    Color.orange.opacity(0)
                ]),
                startPoint: .leading,
                endPoint: .trailing
            )
            .offset(x: phase)
            .onAppear {
                withAnimation(Animation.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                    phase = 150
                }
            }
        }
    }
    
    private func formatShortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
    
}

struct AddGoalView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(ThemeManager.self) private var themeManager
    @Query private var users: [User]
    
    @State private var title = ""
    @State private var descriptionText = ""
    @State private var category = GoalCategory.personal
    @State private var priority = GoalPriority.normal
    @State private var startDate = Date()
    @State private var hasEndDate = false
    @State private var endDate: Date = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
    @State private var hasMilestones = false
    @State private var milestonesDraft: [GoalMilestoneDraft] = []
    @State private var showingMilestoneError = false
    
    private var currentUser: User? {
        users.first
    }
    
    var body: some View {
        let theme = themeManager.currentTheme
        
        return NavigationView {
            ZStack {
                // Background using theme gradient
                theme.primaryGradient
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Goal Details Section
                        sectionView(title: "GOAL DETAILS", theme: theme) {
                            VStack(spacing: 16) {
                                transparentTextField(placeholder: "Goal title", text: $title, theme: theme)
                                transparentTextEditor(text: $descriptionText, theme: theme, placeholder: "Description (optional)")
                    
                    Picker("Category", selection: $category) {
                                    ForEach(GoalCategory.allCases, id: \.self) { cat in
                            HStack {
                                            Image(systemName: cat.icon)
                                                .foregroundColor(cat.color())
                                            Text(cat.displayName)
                                        }.tag(cat)
                        }
                    }
                                .pickerStyle(.menu)
                                .tint(theme.accentColor)
                    
                    Picker("Priority", selection: $priority) {
                        ForEach(GoalPriority.allCases, id: \.self) { p in
                            HStack {
                                Circle()
                                    .fill(p.color)
                                    .frame(width: 12, height: 12)
                                Text(p.rawValue)
                            }.tag(p)
                }
                        }
                                .pickerStyle(.menu)
                                .tint(theme.accentColor)
                    }
                            .padding(.horizontal, theme.cardPadding)
                            .padding(.vertical, theme.cardVerticalPadding)
                            .background(transparentInputBackground(theme: theme))
                            .cornerRadius(theme.smallCornerRadius)
                }
                
                        // Dates Section
                        sectionView(title: "DATES", theme: theme) {
                            VStack(spacing: 16) {
                    DatePicker("Start Date", selection: $startDate, displayedComponents: [.date])
                                    .tint(theme.accentColor)
                                
                    Toggle("Set End Date", isOn: $hasEndDate)
                                    .tint(theme.accentColor)
                                
                    if hasEndDate {
                        DatePicker("End Date", selection: $endDate, displayedComponents: [.date])
                                        .tint(theme.accentColor)
            }
                    }
                            .padding(.horizontal, theme.cardPadding)
                            .padding(.vertical, theme.cardVerticalPadding)
                            .background(transparentInputBackground(theme: theme))
                            .cornerRadius(theme.smallCornerRadius)
                }
                
                        // Structure Section
                        sectionView(title: "STRUCTURE", theme: theme) {
                            VStack(spacing: 16) {
                    Toggle("Use Milestones", isOn: $hasMilestones)
                                    .tint(theme.accentColor)
                        .onChange(of: hasMilestones) { _, newValue in
                            if newValue && milestonesDraft.isEmpty {
                                milestonesDraft.append(GoalMilestoneDraft())
                            }
                                    }
                                
                                if hasMilestones {
                                    milestonesSection(theme: theme)
                                }
                            }
                            .padding(.horizontal, theme.cardPadding)
                            .padding(.vertical, theme.cardVerticalPadding)
                            .background(transparentInputBackground(theme: theme))
                            .cornerRadius(theme.smallCornerRadius)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("Add Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                        }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveGoal()
                    }
                    .disabled(title.isEmpty)
                }
            }
            .alert("Milestone Name Required", isPresented: $showingMilestoneError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Please provide a name for all milestones before saving.")
            }
        }
    }
    
    // MARK: - Helper Functions
    private func sectionView<Content: View>(title: String, theme: any AppTheme, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 12, weight: .semibold, design: .default))
                .foregroundColor(theme.textPrimary.opacity(0.5))
            
            content()
        }
    }
    
    private func milestonesSection(theme: any AppTheme) -> some View {
        VStack(spacing: 12) {
                        if milestonesDraft.isEmpty {
                Text("Tap '+' to add first milestone")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(theme.textSecondary)
                        }
            
                        ForEach($milestonesDraft) { $m in
                milestoneEditor($m, theme: theme)
                        }
            
                        Button(action: {
                            milestonesDraft.append(GoalMilestoneDraft())
                        }) {
                HStack {
                    Image(systemName: "plus.circle")
                    Text("Add Milestone")
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(theme.accentColor)
            }
        }
    }
    
    @ViewBuilder
    private func milestoneEditor(_ milestone: Binding<GoalMilestoneDraft>, theme: any AppTheme) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            transparentTextField(placeholder: "Milestone title *", text: milestone.title, theme: theme)
            
            Text("Target tasks will be auto-calculated when tasks are added to this milestone")
                .font(.caption)
                .foregroundColor(theme.textSecondary)
            
            Toggle("Set Deadline", isOn: milestone.hasDeadline)
                .tint(theme.accentColor)
            
            if milestone.wrappedValue.hasDeadline {
                DatePicker("Deadline", selection: milestone.deadline, displayedComponents: [.date])
                    .tint(theme.accentColor)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func saveGoal() {
        guard let user = currentUser else { return }
        
        // Validate milestone names (required if milestones exist)
        if hasMilestones {
            let invalidMilestones = milestonesDraft.filter { $0.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            if !invalidMilestones.isEmpty {
                showingMilestoneError = true
                return
            }
        }
        
        let goal = Goal(
            userID: user.id,
            title: title,
            goalDescription: descriptionText.isEmpty ? nil : descriptionText,
            category: category,
            priority: priority,
            targetValue: 0, // Will be auto-calculated from tasks
            status: .active,
            createdAt: Date(),
            startDate: startDate,
            deadline: hasEndDate ? endDate : nil,
            milestones: milestonesDraft.map { $0.toModel() }
        )
        
        modelContext.insert(goal)
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Error saving goal: \(error)")
        }
    }
}

private struct GoalMilestoneDraft: Identifiable {
    var id: String = UUID().uuidString
    var title: String = ""
    var hasDeadline: Bool = false
    var deadline: Date = Date()
    
    func toModel() -> GoalMilestone {
        // Target value will be auto-calculated from tasks, so use 0 initially
        GoalMilestone(title: title, targetValue: 0, isComplete: false, deadline: hasDeadline ? deadline : nil)
    }
}

// MARK: - Goal Floating Action Menu
// Moved to Views/Components/GoalFloatingActionMenu.swift

struct AddTaskToGoalView: View {
    let goal: Goal
    var preselectedMilestoneID: String? = nil
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [User]
    @Query private var tasks: [Task]
    
    @State private var mode: TaskAddMode = .createNew
    @State private var selectedExistingTask: Task? = nil
    @State private var selectedMilestone: GoalMilestone? = nil
    @State private var searchText = ""
    
    // New task fields
    @State private var title = ""
    @State private var taskDescription = ""
    @State private var startTime = Date()
    @State private var endTime = Date().addingTimeInterval(3600)
    @State private var priority = PriorityType.normal
    @State private var category: TaskCategory = .personal
    @State private var isRecurring = false
    @State private var recurrenceType = RecurrenceType.daily
    @State private var recurrenceEndDate: Date? = nil
    
    private var currentUser: User? {
        users.first
    }
    
    init(goal: Goal, preselectedMilestoneID: String? = nil) {
        self.goal = goal
        // Legacy support: convert milestone ID to object if provided
        if let milestoneID = preselectedMilestoneID {
            // Will be resolved in onAppear
        }
        // Inherit goal category for new tasks
        _category = State(initialValue: AddTaskToGoalView.goalToTaskCategory(goal.category))
        // Set default recurrence end date to goal deadline if available
        if let deadline = goal.deadline {
            _recurrenceEndDate = State(initialValue: deadline)
        }
    }
    
    // Static helper to avoid initialization issues
    private static func goalToTaskCategory(_ goalCategory: GoalCategory) -> TaskCategory {
        switch goalCategory {
        case .health, .fitness: return .selfCare
        case .work: return .work
        case .learning: return .growth
        case .personal: return .personal
        case .financial: return .personal
        case .creative: return .hobbies
        case .social: return .personal
        case .spiritual: return .selfCare
        case .productivity: return .work
        }
    }
    
    private var availableTasks: [Task] {
        let unlinked = tasks.filter { $0.goal == nil }
        if searchText.isEmpty {
            return unlinked
        }
        return unlinked.filter { task in
            task.title.localizedCaseInsensitiveContains(searchText) ||
            (task.taskDescription?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }
    
    private var availableMilestones: [GoalMilestone] {
        goal.milestones
    }
    
    var body: some View {
        formContent
            .onAppear {
                if selectedMilestone == nil && preselectedMilestoneID != nil {
                    // Convert milestone ID to object
                    selectedMilestone = goal.milestones.first(where: { $0.id == preselectedMilestoneID })
                }
            }
    }
    
    private var formContent: some View {
        NavigationView {
            ZStack {
                // Background matching home screen style
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
                
            Form {
                Section(header: Text("Goal")) {
                    HStack {
                        Image(systemName: goal.category.icon)
                            .foregroundColor(goal.category.color())
                        Text(goal.title)
                            .font(.headline)
                    }
                }
                
                // Milestone Selection (if any exist)
                if !availableMilestones.isEmpty {
                    Section(header: Text("Link to Milestone (Optional)")) {
                        Picker("Milestone", selection: $selectedMilestone) {
                            Text("None").tag(nil as GoalMilestone?)
                            ForEach(availableMilestones, id: \.id) { milestone in
                                HStack {
                                    Image(systemName: milestone.isComplete ? "checkmark.circle.fill" : "circle")
                                    Text(milestone.title)
                                }
                                .tag(milestone as GoalMilestone?)
                            }
                        }
                    }
                }
                
                // Mode Selection
                Section(header: Text("Action")) {
                    Picker("Mode", selection: $mode) {
                        Text("Create New Task").tag(TaskAddMode.createNew)
                        Text("Link Existing Task").tag(TaskAddMode.linkExisting)
                    }
                    .pickerStyle(.segmented)
                }
                
                if mode == .createNew {
                        createNewTaskSection
                    } else {
                        linkExistingTaskSection
                    }
                }
                .scrollContentBackground(.hidden)
                .listRowBackground(Color.clear)
            }
            .navigationTitle("Add Task to Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveTask()
                    }
                    .disabled(cannotSave)
                }
            }
        }
    }
    
    @Environment(ThemeManager.self) private var themeManager
    
    private var createNewTaskSection: some View {
        let theme = themeManager.currentTheme
        
        return Group {
                    Section(header: Text("Task Details")) {
                        transparentTextField(placeholder: "Task title", text: $title, theme: theme)
                        transparentTextField(placeholder: "Description (optional)", text: $taskDescription, theme: theme, axis: .vertical, lineLimit: 3...6)
                        
                        // Priority and Category pickers - keep existing style for now
                        
                        Picker("Priority", selection: $priority) {
                            ForEach(PriorityType.allCases, id: \.self) { p in
                                Text(p.rawValue.capitalized).tag(p)
                            }
                        }
                        
                        Picker("Category", selection: $category) {
                            ForEach(TaskCategory.allCases, id: \.self) { c in
                                HStack {
                                    Image(systemName: c.icon)
                                    Text(c.displayName)
                                }.tag(c)
                            }
                        }
                    }
                    
                    Section(header: Text("Time")) {
                        DatePicker("Start Time", selection: $startTime, displayedComponents: [.date, .hourAndMinute])
                        DatePicker("End Time", selection: $endTime, displayedComponents: [.date, .hourAndMinute])
                            .onChange(of: startTime) { _, newStart in
                                if endTime < newStart {
                                    endTime = newStart.addingTimeInterval(3600)
                                }
                            }
                    }
                    
                    Section(header: Text("Recurrence")) {
                        Toggle("Make Recurring", isOn: $isRecurring)
                        
                        if isRecurring {
                            Picker("Frequency", selection: $recurrenceType) {
                                ForEach(RecurrenceType.allCases, id: \.self) { type in
                                    Text(type.displayName).tag(type)
                                }
                            }
                            
                            Toggle("Until Goal End", isOn: Binding(
                                get: { recurrenceEndDate == nil },
                                set: { if $0 { recurrenceEndDate = nil } else { recurrenceEndDate = goal.deadline ?? Date().addingTimeInterval(86400 * 30) } }
                            ))
                            
                            if recurrenceEndDate != nil {
                                DatePicker("Recurrence End Date", selection: Binding(
                                    get: { recurrenceEndDate ?? Date() },
                                    set: { recurrenceEndDate = $0 }
                                ), displayedComponents: [.date])
                            } else if let deadline = goal.deadline {
                                Text("Recurring until goal deadline: \(deadline, style: .date)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
        }
    }
    
    private var linkExistingTaskSection: some View {
                    Section(header: Text("Select Task")) {
                        TextField("Search tasks...", text: $searchText)
                            .textFieldStyle(.roundedBorder)
                        
                        if availableTasks.isEmpty {
                            Text(searchText.isEmpty ? "No unlinked tasks available" : "No tasks match your search")
                                .foregroundColor(.secondary)
                                .italic()
                        } else {
                            ForEach(availableTasks, id: \.id) { task in
                                Button(action: {
                                    selectedExistingTask = task
                                }) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(task.title)
                                                .font(.headline)
                                                .foregroundColor(task.id == selectedExistingTask?.id ? .blue : .primary)
                                            if let desc = task.taskDescription {
                                                Text(desc)
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                                    .lineLimit(2)
                                            }
                                            HStack {
                                                Image(systemName: task.category.icon)
                                                    .font(.caption2)
                                                Text(task.category.displayName)
                                                    .font(.caption2)
                                                Spacer()
                                                Text(task.startTime, style: .date)
                                                    .font(.caption2)
                                            }
                                            .foregroundColor(.secondary)
                                        }
                                        Spacer()
                                        if selectedExistingTask?.id == task.id {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.blue)
                                        }
                                    }
                                }
                }
            }
        }
    }
    
    private var cannotSave: Bool {
        if mode == .createNew {
            return title.isEmpty || endTime < startTime
        } else {
            return selectedExistingTask == nil
        }
    }
    
    private func saveTask() {
        guard let user = currentUser else { return }
        
        // Validate milestone belongs to goal
        if let milestone = selectedMilestone, !goal.milestones.contains(where: { $0.id == milestone.id }) {
            return // Invalid milestone
        }
        
        if mode == .createNew {
            // Validate end >= start
            guard endTime >= startTime else { return }
            
            if isRecurring {
                // Create recurring tasks
                createRecurringTasks(user: user)
            } else {
                // Create single task
                let task = Task(
                    userID: user.id,
                    title: title,
                    taskDescription: taskDescription.isEmpty ? nil : taskDescription,
                    startTime: startTime,
                    endTime: endTime,
                    priority: priority,
                    category: category,
                    goal: goal,
                    milestone: selectedMilestone
                )
                modelContext.insert(task)
            }
        } else {
            // Link existing task to goal
            if let task = selectedExistingTask {
                task.goal = goal
                task.milestone = selectedMilestone
            }
        }
        
        do {
            try modelContext.save()
            // Sync target value after adding tasks
            GoalProgressUpdater.syncTargetValue(for: goal, context: modelContext)
            dismiss()
        } catch {
            print("Error saving task: \(error)")
        }
    }
    
    private func createRecurringTasks(user: User) {
        let calendar = Calendar.current
        var currentDate = startTime
        let endDate = recurrenceEndDate ?? goal.deadline ?? Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
        let seriesID = UUID().uuidString
        
        // Calculate end time duration
        let duration = endTime.timeIntervalSince(startTime)
        
        while currentDate <= endDate {
            if shouldCreateTaskForDate(currentDate) {
                let taskEnd = currentDate.addingTimeInterval(duration)
                let task = Task(
                    userID: user.id,
                    title: title,
                    taskDescription: taskDescription.isEmpty ? nil : taskDescription,
                    startTime: currentDate,
                    endTime: taskEnd,
                    priority: priority,
                    category: category,
                    goal: goal,
                    milestone: selectedMilestone,
                    recurrenceSeriesID: seriesID
                )
                modelContext.insert(task)
            }
            
            // Move to next occurrence
            switch recurrenceType {
            case .daily:
                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
            case .weekdays:
                var nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
                while calendar.isDateInWeekend(nextDate) {
                    nextDate = calendar.date(byAdding: .day, value: 1, to: nextDate) ?? nextDate
                }
                currentDate = nextDate
            case .weekly:
                currentDate = calendar.date(byAdding: .weekOfYear, value: 1, to: currentDate) ?? currentDate
            case .custom:
                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
            }
        }
    }
    
    private func shouldCreateTaskForDate(_ date: Date) -> Bool {
        let calendar = Calendar.current
        
        switch recurrenceType {
        case .daily:
            return true
        case .weekdays:
            return !calendar.isDateInWeekend(date)
        case .weekly:
            return calendar.component(.weekday, from: date) == calendar.component(.weekday, from: startTime)
        case .custom:
            return true
        }
    }
}

enum TaskAddMode {
    case createNew
    case linkExisting
}

struct LinkTaskToGoalView: View {
    let task: Task
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var goals: [Goal]
    
    @State private var selectedGoalID: String? = nil
    @State private var selectedMilestone: GoalMilestone? = nil
    
    private var activeGoals: [Goal] {
        goals.filter { $0.status != .paused }
    }
    
    private var selectedGoal: Goal? {
        guard let selectedGoalID = selectedGoalID else { return nil }
        return activeGoals.first(where: { $0.id == selectedGoalID })
    }
    
    private var availableMilestones: [GoalMilestone] {
        selectedGoal?.milestones ?? []
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background matching home screen style
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
                
            Form {
                Section(header: Text("Task")) {
                    HStack {
                        Image(systemName: task.category.icon)
                            .foregroundColor(task.category.color())
                        Text(task.title)
                            .font(.headline)
                    }
                }
                
                Section(header: Text("Select Goal")) {
                    if activeGoals.isEmpty {
                        Text("No active goals available")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(activeGoals, id: \.id) { goal in
                            Button(action: {
                                if selectedGoalID == goal.id {
                                    selectedGoalID = nil
                                    selectedMilestone = nil
                                } else {
                                    selectedGoalID = goal.id
                                    selectedMilestone = nil
                                }
                            }) {
                                HStack {
                                    Image(systemName: goal.category.icon)
                                        .foregroundColor(goal.category.color())
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(goal.title)
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                            if let deadline = goal.deadline {
                                                Text("Due: \(deadline, style: .date)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            }
                                    }
                                    Spacer()
                                    if selectedGoalID == goal.id {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                        }
                    }
                }
                
                // Milestone Selection (if goal selected and has milestones)
                if let _ = selectedGoal, !availableMilestones.isEmpty {
                    Section(header: Text("Link to Milestone (Optional)")) {
                        Picker("Milestone", selection: $selectedMilestone) {
                            Text("None - Link directly to goal").tag(nil as GoalMilestone?)
                            ForEach(availableMilestones, id: \.id) { milestone in
                                HStack {
                                    Image(systemName: milestone.isComplete ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(milestone.isComplete ? .green : .gray)
                                    Text(milestone.title)
                                }
                                .tag(milestone as GoalMilestone?)
                            }
                        }
                    }
                }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Add to Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        linkTaskToGoal()
                    }
                    .disabled(selectedGoalID == nil)
                }
            }
        }
    }
    
    private func linkTaskToGoal() {
        guard let goalID = selectedGoalID else { return }
        
        // Validate milestone belongs to goal
        if let milestone = selectedMilestone,
           let goal = selectedGoal,
           !goal.milestones.contains(where: { $0.id == milestone.id }) {
            return // Invalid milestone
        }
        
        // Link task to goal
        task.goal = selectedGoal
        task.milestone = selectedMilestone
        
        // Update goal target value if needed
        if let goal = selectedGoal {
            GoalProgressUpdater.syncTargetValue(for: goal, context: modelContext)
        }
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Failed to link task to goal: \(error)")
        }
    }
}

#Preview {
    GoalsView()
        .modelContainer(for: [Goal.self], inMemory: true)
}
