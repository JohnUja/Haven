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
                let g1Tasks = allTasks.filter { $0.goalID == g1.id }
                let g2Tasks = allTasks.filter { $0.goalID == g2.id }
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
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(sortedGoals) { goal in
                        GoalCardView(goal: goal)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                // Always navigate on tap (long press is handled separately)
                                selectedGoal = goal
                            }
                            .onLongPressGesture(minimumDuration: 0.3) {
                                // Haptic feedback AFTER long press completes
                                AudioServicesPlaySystemSound(1520) // Haptic vibration
                                withAnimation {
                                    showingFloatingMenu = goal
                                    // Don't set selectedGoal - long press should not navigate
                                }
                            }
                    }
                }
                .padding()
            }
            .background(
                LinearGradient(
                    colors: [.purple.opacity(0.1), .blue.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .navigationTitle("Goals")
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
                message: Text("This will remove the goal but keep all linked tasks."),
                primaryButton: .destructive(Text("Delete")) {
                    modelContext.delete(goal)
                    try? modelContext.save()
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
                                withAnimation {
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
                                withAnimation {
                                    showingFloatingMenu = nil
                                }
                            }
                        )
                        .transition(.scale.combined(with: .opacity))
                    }
                }
            }
        )
    }
}

struct GoalCardView: View {
    let goal: Goal
    @Query private var allTasks: [Task]
    
    private var goalTasks: [Task] {
        allTasks.filter { $0.goalID == goal.id }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header - Only show icon
            HStack {
                Image(systemName: goal.category.icon)
                    .foregroundColor(goal.category.color())
                    .font(.title2)
                
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
            
            // Progress Ring
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 8)
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
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(goal.status == .paused ? .gray : .primary)
                    
                    Text("\(goal.currentValue)/\(goal.effectiveTargetValue(tasks: goalTasks))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            
            // Progress Description
            Text(progressDescription)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            // Status subtitle and due date on same line
            HStack {
                Text(statusSubtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if let deadline = goal.deadline {
                    Text(formatShortDate(deadline))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(borderColor, lineWidth: 2)
        )
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
    
    private func formatShortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

struct AddGoalView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
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
        NavigationView {
            Form {
                Section("Goal Details") {
                    TextField("Goal title", text: $title)
                    TextEditor(text: $descriptionText)
                        .frame(minHeight: 80)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.2))
                        )
                    
                    Picker("Category", selection: $category) {
                        ForEach(GoalCategory.allCases, id: \.self) { category in
                            HStack {
                                Image(systemName: category.icon)
                                    .foregroundColor(category.color())
                                Text(category.displayName)
                            }.tag(category)
                        }
                    }
                    
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
                }
                
                Section("Dates") {
                    DatePicker("Start Date", selection: $startDate, displayedComponents: [.date])
                    Toggle("Set End Date", isOn: $hasEndDate)
                    if hasEndDate {
                        DatePicker("End Date", selection: $endDate, displayedComponents: [.date])
                    }
                }
                
                // Milestone Toggle
                Section("Structure") {
                    Toggle("Use Milestones", isOn: $hasMilestones)
                        .onChange(of: hasMilestones) { _, newValue in
                            if newValue && milestonesDraft.isEmpty {
                                // Add first milestone when toggled on (only if no existing milestones)
                                milestonesDraft.append(GoalMilestoneDraft())
                            }
                            // Don't clear milestones when toggled off - preserve them for when user toggles back on
                        }
                }
                
                // Milestones Section (only if toggle is ON)
                if hasMilestones {
                    Section(header: Text("Milestones")) {
                        if milestonesDraft.isEmpty {
                            Text("Tap '+' to add first milestone").foregroundColor(.secondary)
                        }
                        ForEach($milestonesDraft) { $m in
                            milestoneEditor($m)
                        }
                        .onDelete { indexSet in
                            milestonesDraft.remove(atOffsets: indexSet)
                        }
                        Button(action: {
                            milestonesDraft.append(GoalMilestoneDraft())
                        }) {
                            Label("Add Milestone", systemImage: "plus.circle")
                        }
                    }
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
    
    @ViewBuilder
    private func milestoneEditor(_ milestone: Binding<GoalMilestoneDraft>) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("Milestone title *", text: milestone.title)
                .font(.headline)
            
            Text("Target tasks will be auto-calculated when tasks are added to this milestone")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Toggle("Set Deadline", isOn: milestone.hasDeadline)
            if milestone.wrappedValue.hasDeadline {
                DatePicker("Deadline", selection: milestone.deadline, displayedComponents: [.date])
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
struct GoalFloatingActionMenu: View {
    let goal: Goal
    let onEdit: () -> Void
    let onAddTask: () -> Void
    let onPause: () -> Void
    let onDelete: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Edit
            Button(action: onEdit) {
                VStack(spacing: 4) {
                    Image(systemName: "pencil")
                        .font(.title2)
                    Text("Edit")
                        .font(.caption)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.gray.opacity(0.8))
                .cornerRadius(10)
            }
            
            // Add Task
            Button(action: onAddTask) {
                VStack(spacing: 4) {
                    Image(systemName: "plus.circle")
                        .font(.title2)
                    Text("Add Task")
                        .font(.caption)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.gray.opacity(0.8))
                .cornerRadius(10)
            }
            
            // Pause/Resume
            Button(action: onPause) {
                VStack(spacing: 4) {
                    Image(systemName: goal.status == .paused ? "play.circle" : "pause.circle")
                        .font(.title2)
                    Text(goal.status == .paused ? "Resume" : "Pause")
                        .font(.caption)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.gray.opacity(0.8))
                .cornerRadius(10)
            }
            
            // Delete
            Button(role: .destructive, action: onDelete) {
                VStack(spacing: 4) {
                    Image(systemName: "trash")
                        .font(.title2)
                    Text("Delete")
                        .font(.caption)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.red.opacity(0.8))
                .cornerRadius(10)
            }
        }
        .padding()
        .background(Color.black.opacity(0.9))
        .cornerRadius(16)
        .shadow(radius: 20)
    }
}

// Deprecated - kept for reference
struct GoalLongPressMenuView: View {
    let goal: Goal
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var showingEditGoal = false
    @State private var showingUpdateProgress = false
    @State private var showingAddTask = false
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        NavigationView {
            List {
                Button(action: {
                    dismiss()
                    showingEditGoal = true
                }) {
                    HStack {
                        Image(systemName: "pencil")
                            .foregroundColor(.blue)
                        Text("Edit Goal")
                    }
                }
                
                Button(action: {
                    dismiss()
                    showingUpdateProgress = true
                }) {
                    HStack {
                        Image(systemName: "checkmark.circle")
                            .foregroundColor(.green)
                        Text("Update Progress")
                    }
                }
                
                Button(action: {
                    dismiss()
                    showingAddTask = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle")
                            .foregroundColor(.purple)
                        Text("Add Task to This Goal")
                    }
                }
                
                Button(action: {
                    if goal.status == .paused {
                        goal.status = .active
                    } else {
                        goal.status = .paused
                    }
                    try? modelContext.save()
                    dismiss()
                }) {
                    HStack {
                        Image(systemName: goal.status == .paused ? "play.circle" : "pause.circle")
                            .foregroundColor(.orange)
                        Text(goal.status == .paused ? "Resume Goal" : "Pause Goal")
                    }
                }
                
                Button(role: .destructive, action: {
                    dismiss()
                    showingDeleteConfirmation = true
                }) {
                    HStack {
                        Image(systemName: "trash")
                        Text("Delete Goal")
                    }
                }
            }
            .navigationTitle("Goal Actions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .sheet(isPresented: $showingEditGoal) {
            EditGoalInlineView(goal: goal)
        }
        .sheet(isPresented: $showingUpdateProgress) {
            UpdateProgressInlineView(goal: goal)
        }
        .sheet(isPresented: $showingAddTask) {
            AddTaskToGoalView(goal: goal)
        }
        .alert("Delete Goal?", isPresented: $showingDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                modelContext.delete(goal)
                try? modelContext.save()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will remove the goal but keep all linked tasks.")
        }
    }
}


struct AddTaskToGoalView: View {
    let goal: Goal
    var preselectedMilestoneID: String? = nil
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [User]
    @Query private var tasks: [Task]
    
    @State private var mode: TaskAddMode = .createNew
    @State private var selectedExistingTask: Task? = nil
    @State private var selectedMilestoneID: String? = nil
    @State private var searchText = ""
    
    init(goal: Goal, preselectedMilestoneID: String? = nil) {
        self.goal = goal
        self.preselectedMilestoneID = preselectedMilestoneID
        // Inherit goal category for new tasks
        _category = State(initialValue: goalToTaskCategory(goal.category))
        // Set default recurrence end date to goal deadline if available
        if let deadline = goal.deadline {
            _recurrenceEndDate = State(initialValue: deadline)
        }
    }
    
    private func goalToTaskCategory(_ goalCategory: GoalCategory) -> TaskCategory {
        // Map goal categories to task categories
        switch goalCategory {
        case .health, .fitness: return .selfCare
        case .work: return .work
        case .learning: return .growth
        case .personal: return .personal
        case .financial: return .personal // Or create financial task category
        case .creative: return .hobbies
        case .social: return .personal
        case .spiritual: return .selfCare
        case .productivity: return .work
        }
    }
    
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
    
    private var availableTasks: [Task] {
        let unlinked = tasks.filter { $0.goalID == nil }
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
                if selectedMilestoneID == nil && preselectedMilestoneID != nil {
                    selectedMilestoneID = preselectedMilestoneID
                }
            }
    }
    
    private var formContent: some View {
        NavigationView {
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
                        Picker("Milestone", selection: $selectedMilestoneID) {
                            Text("None").tag(nil as String?)
                            ForEach(availableMilestones, id: \.id) { milestone in
                                HStack {
                                    Image(systemName: milestone.isComplete ? "checkmark.circle.fill" : "circle")
                                    Text(milestone.title)
                                }
                                .tag(milestone.id as String?)
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
                    Section(header: Text("Task Details")) {
                        TextField("Task title", text: $title)
                        TextField("Description (optional)", text: $taskDescription, axis: .vertical)
                            .lineLimit(3...6)
                        
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
                } else {
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
        if let milestoneID = selectedMilestoneID, !goal.milestones.contains(where: { $0.id == milestoneID }) {
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
                    goalID: goal.id,
                    milestoneID: selectedMilestoneID
                )
                modelContext.insert(task)
            }
        } else {
            // Link existing task to goal
            if let task = selectedExistingTask {
                task.goalID = goal.id
                task.milestoneID = selectedMilestoneID
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
                    goalID: goal.id,
                    milestoneID: selectedMilestoneID,
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

// MARK: - Link Task to Goal View
struct LinkTaskToGoalView: View {
    let task: Task
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var goals: [Goal]
    
    @State private var selectedGoalID: String? = nil
    @State private var selectedMilestoneID: String? = nil
    
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
                                    selectedMilestoneID = nil
                                } else {
                                    selectedGoalID = goal.id
                                    selectedMilestoneID = nil
                                }
                            }) {
                                HStack {
                                    Image(systemName: goal.category.icon)
                                        .foregroundColor(goal.category.color())
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(goal.title)
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        Text(goal.category.displayName)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    if selectedGoalID == goal.id {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.blue)
                                    } else {
                                        Image(systemName: "circle")
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                        }
                    }
                }
                
                // Milestone Selection (if goal selected and has milestones)
                if let goal = selectedGoal, !availableMilestones.isEmpty {
                    Section(header: Text("Link to Milestone (Optional)")) {
                        Picker("Milestone", selection: $selectedMilestoneID) {
                            Text("None - Link directly to goal").tag(nil as String?)
                            ForEach(availableMilestones, id: \.id) { milestone in
                                HStack {
                                    Image(systemName: milestone.isComplete ? "checkmark.circle.fill" : "circle")
                                    Text(milestone.title)
                                }
                                .tag(milestone.id as String?)
                            }
                        }
                    }
                }
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
        
        // Validate milestone belongs to selected goal
        if let milestoneID = selectedMilestoneID,
           let goal = selectedGoal,
           !goal.milestones.contains(where: { $0.id == milestoneID }) {
            return // Invalid milestone
        }
        
        // Link task to goal
        task.goalID = goalID
        task.milestoneID = selectedMilestoneID
        
        // Sync target value for the goal
        if let goal = selectedGoal {
            GoalProgressUpdater.syncTargetValue(for: goal, context: modelContext)
        }
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Error linking task to goal: \(error)")
        }
    }
}

#Preview {
    GoalsView()
        .modelContainer(for: [Goal.self], inMemory: true)
}
