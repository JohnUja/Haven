//
//  GoalsView.swift
//  Haven2.0
//
//  Refactored for SwiftData Relationships & Performance
//

import SwiftUI
import SwiftData
import UIKit
import AudioToolbox

struct GoalsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(ThemeManager.self) private var themeManager
    
    @Query private var goals: [Goal]
    @Query private var allTasks: [Task]
    
    @State private var showingAddGoal = false
    @State private var showingFloatingMenu: Goal? = nil
    @State private var showingEditGoal: Goal? = nil
    @State private var showingUpdateProgress: Goal? = nil
    @State private var showingAddTask: Goal? = nil
    @State private var showingDeleteConfirmation: Goal? = nil
    @State private var showingPauseConfirmation: Goal? = nil
    @State private var selectedGoal: Goal? = nil
    @State private var goalSortOrder: GoalSortOrder = .latest
    
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
        let goalID = goal.id
        
        // Find all tasks linked to this goal using ID check on the relationship
        // (Since the relationship is optional, we unwrap safely)
        let linkedTasks = allTasks.filter { $0.goal?.id == goalID }
        
        // Delete all linked tasks
        for task in linkedTasks {
            modelContext.delete(task)
        }
        
        // Delete the goal (Milestones will cascade delete automatically based on model rule)
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
            sortedActive = activeGoals.sorted { g1, g2 in
                if let d1 = g1.deadline, let d2 = g2.deadline {
                    return d1 < d2
                } else if g1.deadline != nil {
                    return true
                } else if g2.deadline != nil {
                    return false
                } else {
                    return g1.createdAt < g2.createdAt
                }
            }
        case .progression:
            // Higher progress (90%+) at top
            // 🛠️ FIX: Using the new parameter-less method on the Model
            sortedActive = activeGoals.sorted { g1, g2 in
                return g1.progressPercentage() > g2.progressPercentage()
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
                        // Goals Heading
                        Text("Goals")
                            .font(.system(size: 18, weight: .semibold, design: .default))
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
                                        .frame(height: 200)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedGoal = goal
                                }
                                .onLongPressGesture(minimumDuration: 0.3) {
                                            AudioServicesPlaySystemSound(1520)
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                                        showingFloatingMenu = goal
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
            .navigationBarTitleDisplayMode(.inline)
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
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                            .onTapGesture {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    showingFloatingMenu = nil
                                }
                            }
                        
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
    @Environment(ThemeManager.self) private var themeManager
    
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
                
                // 🛠️ FIX: Removed 'tasks' argument
                Circle()
                    .trim(from: 0, to: goal.progressPercentage())
                    .stroke(
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
                    // Animation value based on progress
                    .animation(.spring(response: 0.8, dampingFraction: 0.7), value: goal.progressPercentage())
                
                VStack {
                    // 🛠️ FIX: Removed 'tasks' argument
                    Text("\(Int(goal.progressPercentage() * 100))%")
                        .appTextStyle(.body, theme: themeManager.currentTheme)
                        .opacity(goal.status == .paused ? themeManager.currentTheme.textTertiaryOpacity : 1.0)
                    
                    // 🛠️ FIX: Removed 'tasks' argument
                    Text("\(goal.currentValue)/\(goal.effectiveTargetValue())")
                        .appTextStyle(.caption, theme: themeManager.currentTheme)
                        .opacity(themeManager.currentTheme.textSecondaryOpacity)
                }
            }
            .frame(maxWidth: .infinity)
            
            // Progress Description
            if progressDescription == "Add tasks to start tracking" {
                ZStack {
                    Text(progressDescription)
                        .font(.system(size: 9, weight: .light, design: .default))
                        .foregroundColor(themeManager.currentTheme.textPrimary.opacity(0.7))
                        .multilineTextAlignment(.center)
                    
                    GoalShimmerEffect()
                        .mask(
                            Text(progressDescription)
                                .font(.system(size: 9, weight: .light, design: .default))
                        )
                }
            } else {
                Text(progressDescription)
                    .font(.system(size: 11, weight: .regular, design: .default))
                    .foregroundColor(themeManager.currentTheme.textPrimary.opacity(themeManager.currentTheme.textSecondaryOpacity))
                    .multilineTextAlignment(.center)
            }

            // Status subtitle and due date
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
        .frame(height: 200)
    }
    
    private var goalWidgetBackgroundColor: Color {
        let theme = themeManager.currentTheme
        switch theme.id {
        case "light": return Color.white.opacity(0.9)
        case "dark": return Color.black.opacity(0.7)
        default: return theme.glassBackground
        }
    }
    
    private var borderColor: Color {
        if goal.status == .paused { return .gray }
        // 🛠️ FIX: GoalStatusManager likely needs tasks for calculation.
        // Assuming we pass tasks from relationship for accuracy or fetch
        // For card view without query, we rely on goal.tasks relationship
        let tasks = goal.tasks ?? []
        let insight = GoalStatusManager.evaluate(goal: goal, tasks: tasks)
        return GoalStatusManager.borderColor(for: insight.risk)
    }
    
    private var progressDescription: String {
        if goal.status == .completed {
            return "Goal completed! 🎉"
        } else {
            // 🛠️ FIX: Removed 'tasks' argument
            let effectiveTarget = goal.effectiveTargetValue()
            let remaining = max(effectiveTarget - goal.currentValue, 0)
            if effectiveTarget == 0 {
                return "Add tasks to start tracking"
            }
            return "\(remaining) more to go"
        }
    }

    private var statusSubtitle: String {
        if goal.status == .paused { return "Paused" }
        let tasks = goal.tasks ?? []
        let risk = GoalStatusManager.evaluate(goal: goal, tasks: tasks).risk
        switch risk {
        case .ahead: return "Ahead"
        case .onTrack: return "On Track"
        case .atRisk: return "At Risk"
        case .severe: return "Severe Risk"
        }
    }
    
    // Shimmer Effect
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
    // 🛠️ FIX: Draft struct needs to be visible or this needs to use it
    @State private var milestonesDraft: [GoalMilestoneDraft] = []
    @State private var showingMilestoneError = false
    
    private var currentUser: User? {
        users.first
    }
    
    var body: some View {
        let theme = themeManager.currentTheme
        
        return NavigationView {
            ZStack {
                theme.primaryGradient
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        sectionView(title: "GOAL DETAILS", theme: theme) {
                            VStack(spacing: 16) {
                                transparentTextField(placeholder: "Goal title", text: $title, theme: theme)
                                transparentTextEditor(text: $descriptionText, theme: theme, placeholder: "Description (optional)", minHeight: 80)
                    
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
                                            Circle().fill(p.color).frame(width: 12, height: 12)
                                Text(p.rawValue)
                            }.tag(p)
                }
                        }
                                .pickerStyle(.menu)
                                .tint(theme.accentColor)
                                .padding(.horizontal, theme.cardPadding)
                                .padding(.vertical, theme.cardVerticalPadding)
                                .background(transparentInputBackground(theme: theme))
                                .cornerRadius(theme.smallCornerRadius)
                            }
                            .padding(.horizontal, 20)
                            
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
                        Button("Cancel") { dismiss() }
                        }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Save") { saveGoal() }
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
            targetValue: 0,
            status: .active,
            createdAt: Date(),
            startDate: startDate,
            deadline: hasEndDate ? endDate : nil
        )
        
        // Add milestones (if any) to the goal before inserting
        // Note: With SwiftData, we insert the goal, then milestones, then link.
        // Or create object graph and insert parent.
        modelContext.insert(goal)
        
        if hasMilestones {
             let newMilestones = milestonesDraft.map { $0.toModel() }
             // Link them
             goal.milestones = newMilestones
             // They will be inserted automatically due to relationship
        }
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Error saving goal: \(error)")
        }
    }
}

// 🛠️ FIX: Make this public or internal so AddGoalView can see it
struct GoalMilestoneDraft: Identifiable {
    var id: String = UUID().uuidString
    var title: String = ""
    var hasDeadline: Bool = false
    var deadline: Date = Date()
    
    func toModel() -> GoalMilestone {
        GoalMilestone(title: title, targetValue: 0, isComplete: false, deadline: hasDeadline ? deadline : nil)
    }
}
