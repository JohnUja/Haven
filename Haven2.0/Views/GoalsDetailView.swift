//
//  GoalsDetailView.swift
//  Haven2.0
//  Created by John Uja
//  Refactored for SwiftData Relationships
//

import SwiftUI
import SwiftData

struct GoalsDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(ThemeManager.self) private var themeManager
    
    let goal: Goal
    
    @Query private var tasks: [Task]
    @Query private var journalEntries: [JournalEntry]
    @Query private var users: [User]
    
    @State private var showingEdit = false
    @State private var showingAddTask = false
    @State private var editingTask: Task? = nil
    @State private var addingTaskToMilestone: String? = nil // Milestone ID
    @State private var showingDeleteSeriesConfirmation: Task? = nil
    
    private var currentUser: User? {
        users.first
    }
    
    init(goal: Goal) {
        self.goal = goal
        let goalID = goal.id
        
        // 🛠️ FIX: Predicate safely checks the optional relationship
        _tasks = Query(filter: #Predicate<Task> { task in
            if let taskGoal = task.goal {
                return taskGoal.id == goalID
            } else {
                return false
            }
        })
        
        // Assuming JournalEntry still uses String ID for loose coupling, keeping as is.
        // If JournalEntry also changed to Relationship, update this similar to above.
        _journalEntries = Query(filter: #Predicate<JournalEntry> { entry in
            entry.goalID == goalID
        }, sort: \JournalEntry.timestamp, order: .reverse)
    }
    
    var body: some View {
        ZStack {
            // Background matching home screen style
            themeManager.currentTheme.primaryGradient
                .opacity(0.1)
                .ignoresSafeArea()
            
            List {
                headerSection
                descriptionSection
                milestonesSection
                linkedTasksSection
                missedTasksSection
                journalEntriesSection
            }
            .scrollContentBackground(.hidden)
            .listStyle(.insetGrouped)
        }
        .navigationTitle("Goal Detail")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button("Edit Goal") { showingEdit = true }
                    Button("Add Task") { showingAddTask = true }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingEdit) { EditGoalInlineView(goal: goal) }
        .sheet(isPresented: $showingAddTask) {
            AddTaskToGoalView(goal: goal)
        }
        .sheet(isPresented: Binding(
            get: { addingTaskToMilestone != nil },
            set: { if !$0 { addingTaskToMilestone = nil } }
        )) {
            if let milestoneID = addingTaskToMilestone,
               let milestone = (goal.milestones ?? []).first(where: { $0.id == milestoneID }) {
                AddTaskToGoalView(goal: goal, preselectedMilestone: milestone)
            }
        }
        .sheet(item: $editingTask) { task in
            EditTaskView(task: task, allTasks: tasks)
        }
        .alert("Delete Recurring Series", isPresented: Binding(
            get: { showingDeleteSeriesConfirmation != nil },
            set: { if !$0 { showingDeleteSeriesConfirmation = nil } }
        )) {
            Button("Delete This Task Only", role: .destructive) {
                if let taskToDelete = showingDeleteSeriesConfirmation {
                    deleteTask(taskToDelete)
                }
            }
            Button("Delete Entire Series", role: .destructive) {
                if let taskToDelete = showingDeleteSeriesConfirmation,
                   let seriesID = taskToDelete.recurrenceSeriesID {
                    let seriesTasks = tasks.filter { $0.recurrenceSeriesID == seriesID }
                    for task in seriesTasks {
                        modelContext.delete(task)
                    }
                    try? modelContext.save()
                }
            }
            Button("Cancel", role: .cancel) {
                showingDeleteSeriesConfirmation = nil
            }
        } message: {
            Text("This task is part of a recurring series. Do you want to delete only this task or the entire series?")
        }
    }
    
    private var headerSection: some View {
        Section {
            HStack(spacing: 16) {
                ZStack {
                    Circle().stroke(themeManager.currentTheme.glassBorder.opacity(0.3), lineWidth: 10).frame(width: 90, height: 90)
                    
                    // 🛠️ FIX: Removed 'tasks' argument from progressPercentage
                    Circle()
                        .trim(from: 0, to: CGFloat(goal.progressPercentage()))
                        .stroke(
                            goal.status == .paused
                            ? LinearGradient(
                                colors: [Color.gray.opacity(0.5), Color.gray.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            : LinearGradient(
                                // Assuming GoalStatusManager needs tasks array, passing local tasks is fine
                                colors: [
                                    GoalStatusManager.borderColor(for: GoalStatusManager.evaluate(goal: goal, tasks: tasks).risk),
                                    GoalStatusManager.borderColor(for: GoalStatusManager.evaluate(goal: goal, tasks: tasks).risk).opacity(0.6)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 10, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .frame(width: 90, height: 90)
                    
                    VStack(spacing: 2) {
                        // 🛠️ FIX: Removed 'tasks' argument
                        Text("\(Int(goal.progressPercentage() * 100))%")
                            .font(.headline)
                            .foregroundColor(goal.status == .paused ? themeManager.currentTheme.textSecondary : themeManager.currentTheme.textPrimary)
                        // 🛠️ FIX: Removed 'tasks' argument
                        Text("\(goal.currentValue)/\(goal.effectiveTargetValue())")
                            .font(.caption)
                            .foregroundColor(themeManager.currentTheme.textSecondary)
                    }
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 4) {
                        Image(systemName: goal.category.icon)
                            .foregroundColor(goal.category.color())
                            .font(.caption)
                        Text(goal.category.displayName)
                            .font(.system(size: 12, weight: .regular, design: .rounded))
                            .foregroundColor(themeManager.currentTheme.textSecondary)
                    }
                    .padding(.bottom, 2)
                    
                    HStack(spacing: 8) {
                        Image(systemName: goal.category.icon).foregroundColor(goal.category.color())
                        Text(goal.title).font(.system(size: 18, weight: .semibold, design: .rounded))
                    }
                    Text(statusSubtitle(for: goal)).font(.system(size: 12, weight: .regular, design: .rounded)).foregroundColor(themeManager.currentTheme.textSecondary)
                    HStack(spacing: 8) {
                        if let start = Optional(goal.startDate) { Text(start, style: .date).font(.system(size: 12, weight: .regular, design: .rounded)).foregroundColor(themeManager.currentTheme.textSecondary) }
                        if let end = goal.deadline { Text("→").font(.system(size: 12, weight: .regular, design: .rounded)).foregroundColor(themeManager.currentTheme.textSecondary); Text(end, style: .date).font(.system(size: 12, weight: .regular, design: .rounded)).foregroundColor(themeManager.currentTheme.textSecondary) }
                    }
                }
            }
        }
    }
    
    private var descriptionSection: some View {
        Section {
            if let desc = goal.goalDescription, !desc.isEmpty {
                Text(desc)
                    .font(.system(size: 16, weight: .regular, design: .rounded))
            } else {
                Text("No description")
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundColor(themeManager.currentTheme.textSecondary)
            }
        } header: {
            Text("About")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
        }
    }
    
    private var milestonesSection: some View {
        Section {
            // 🛠️ FIX: Safely unwrap milestones optional
            if (goal.milestones ?? []).isEmpty {
                Text("No milestones")
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundColor(themeManager.currentTheme.textSecondary)
            } else {
                ForEach(goal.milestones ?? [], id: \.id) { milestone in
                    milestoneCard(milestone)
                }
            }
        } header: {
            Text("Milestones")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
        }
    }
    
    @ViewBuilder
    private func milestoneCard(_ milestone: GoalMilestone) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(milestone.title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                Spacer()
                if let d = milestone.deadline {
                    Text(d, style: .date)
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.textSecondary)
                }
            }
            
            ProgressView(value: milestoneProgress(milestone), total: 1.0)
                .progressViewStyle(.linear)
            
            // 🛠️ FIX: Use relationship to get tasks instead of manual filtering if possible,
            // or stick to local array filtering if easier for now.
            // Using local filtering is safe here since we fetched tasks for the goal.
            let milestoneTasks = tasks.filter { $0.milestone?.id == milestone.id }
            
            if milestoneTasks.isEmpty {
                Button(action: {
                    addingTaskToMilestone = milestone.id
                }) {
                    HStack {
                        Image(systemName: "plus.circle")
                        Text("Add Task")
                    }
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundColor(themeManager.currentTheme.accentColor)
                }
            } else {
                List {
                    ForEach(milestoneTasks, id: \.id) { task in
                        taskRow(task)
                            .listRowInsets(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
                            .listRowSeparator(.hidden)
                    }
                    
                    Button(action: {
                        addingTaskToMilestone = milestone.id
                    }) {
                        HStack {
                            Image(systemName: "plus.circle")
                            Text("Add Task")
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                    .listRowInsets(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .frame(height: CGFloat(milestoneTasks.count * 60 + 40))
            }
        }
        .padding(.vertical, 8)
    }
    
    @ViewBuilder
    private func taskRow(_ task: Task) -> some View {
        HStack {
            Image(systemName: task.isComplete ? "checkmark.circle.fill" : "circle")
                .foregroundColor(task.isComplete ? .green : .gray)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .strikethrough(task.isComplete)
                    .foregroundColor(task.isComplete ? .secondary : .primary)
                
                HStack(spacing: 4) {
                    Text(task.startTime, style: .time)
                        .font(.system(size: 11, weight: .regular, design: .rounded))
                        .foregroundColor(.secondary)
                    
                    if !task.isComplete && task.endTime < Date() {
                        Text("Late")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundColor(.orange)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.2))
                            .cornerRadius(4)
                    }
                }
            }
            
            Spacer()
            
            Button(action: {
                editingTask = task
            }) {
                Image(systemName: "pencil")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            .buttonStyle(.plain)
        }
        .contentShape(Rectangle())
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive, action: {
                if let seriesID = task.recurrenceSeriesID {
                    let seriesTasks = tasks.filter { $0.recurrenceSeriesID == seriesID }
                    if seriesTasks.count > 1 {
                        showingDeleteSeriesConfirmation = task
                    } else {
                        deleteTask(task)
                    }
                } else {
                    deleteTask(task)
                }
            }) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
    
    private func deleteTask(_ task: Task) {
        // SwiftData handles cleanup based on delete rules
        modelContext.delete(task)
        try? modelContext.save()
    }
    
    @ViewBuilder
    private var linkedTasksSection: some View {
        // 🛠️ FIX: Safely unwrap milestones
        if (goal.milestones ?? []).isEmpty {
            Section("Tasks") {
                let goalTasks = tasks.filter { $0.milestone == nil }
                if goalTasks.isEmpty {
                    Button(action: {
                        showingAddTask = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle")
                            Text("Add Task")
                        }
                        .foregroundColor(.blue)
                    }
                } else {
                    ForEach(goalTasks, id: \.id) { task in
                        taskRow(task)
                    }
                    
                    Button(action: {
                        showingAddTask = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle")
                            Text("Add Task")
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                }
            }
        }
    }
    
    private var journalEntriesSection: some View {
        Section("Journal Entries") {
            if journalEntries.isEmpty {
                Text("No journal entries yet").foregroundColor(.secondary)
            } else {
                ForEach(journalEntries, id: \.id) { entry in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(entry.note)
                            .font(.body)
                        
                        if let imageData = entry.imageData,
                           let uiImage = UIImage(data: imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxHeight: 150)
                                .cornerRadius(8)
                        }
                        
                        Text(entry.timestamp, style: .relative)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }
    
    @ViewBuilder
    private var missedTasksSection: some View {
        let missed = getMissedTasks()
        if !missed.isEmpty {
            Section("Missed Tasks") {
                ForEach(missed, id: \.id) { task in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(task.title)
                                    .font(.subheadline)
                                if task.endTime < Date() {
                                    Text("Due: \(task.endTime, style: .relative)")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                }
                            }
                            Spacer()
                            Button("Catch Up") {
                                task.isComplete = true
                                // Note: GoalProgressUpdater should be updated to use Models, but keeping basic call here
                                // GoalProgressUpdater.handleTaskToggle(task, context: modelContext, goals: [])
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        } else {
            EmptyView()
        }
    }
    
    private func getMissedTasks() -> [Task] {
        let now = Date()
        return tasks.filter { task in
            !task.isComplete && task.endTime < now
        }
    }
    
    private func milestoneProgress(_ m: GoalMilestone) -> Double {
        // 🛠️ FIX: Use relationship tasks if possible, otherwise fallback to filtering main list
        let linked = tasks.filter { $0.milestone?.id == m.id }
        guard !linked.isEmpty else { return 0 }
        let done = linked.filter { $0.isComplete }.count
        return Double(done) / Double(linked.count)
    }
    
    private func statusSubtitle(for goal: Goal) -> String {
        if goal.status == .paused {
            return "Paused"
        }
        let risk = GoalStatusManager.evaluate(goal: goal, tasks: tasks).risk
        switch risk {
        case .ahead: return "Ahead"
        case .onTrack: return "On Track"
        case .atRisk: return "At Risk"
        case .severe: return "Severe Risk"
        }
    }
}

// MARK: - Milestone Draft Model
// Note: GoalMilestoneDraft is defined in GoalsView.swift to avoid duplication

// MARK: - Edit Goal Inline View
struct EditGoalInlineView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(ThemeManager.self) private var themeManager
    let goal: Goal
    @Query private var allTasks: [Task]
    
    @State private var title: String
    @State private var descriptionText: String
    @State private var category: GoalCategory
    @State private var priority: GoalPriority
    @State private var startDate: Date
    @State private var hasEndDate: Bool
    @State private var endDate: Date
    @State private var status: GoalStatus
    @State private var hasMilestones: Bool
    @State private var milestonesDraft: [GoalMilestoneDraft] = []
    @State private var showingMilestoneError = false
    @State private var showingAddTaskToMilestone: String? = nil
    
    private var goalTasks: [Task] {
        allTasks.filter { $0.goal?.id == goal.id }
    }
    
    init(goal: Goal) {
        self.goal = goal
        _title = State(initialValue: goal.title)
        _descriptionText = State(initialValue: goal.goalDescription ?? "")
        _category = State(initialValue: goal.category)
        _priority = State(initialValue: goal.effectivePriority)
        _startDate = State(initialValue: goal.startDate)
        _hasEndDate = State(initialValue: goal.deadline != nil)
        _endDate = State(initialValue: goal.deadline ?? Date())
        _status = State(initialValue: goal.status)
        // 🛠️ FIX: Safe unwrap
        _hasMilestones = State(initialValue: !(goal.milestones ?? []).isEmpty)
        
        // 🛠️ FIX: Safe unwrap for init
        _milestonesDraft = State(initialValue: (goal.milestones ?? []).map {
            GoalMilestoneDraft(
                id: $0.id,
                title: $0.title,
                hasDeadline: $0.deadline != nil,
                deadline: $0.deadline ?? Date()
            )
        })
        
        let goalID = goal.id
        // 🛠️ FIX: Predicate safely checks optional relationship
        _allTasks = Query(filter: #Predicate<Task> { task in
            if let g = task.goal {
                return g.id == goalID
            } else {
                return false
            }
        })
    }
    
    var body: some View {
        NavigationView {
            ZStack {
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
                    basicsSection
                    timingSection
                    statusSection
                    structureSection
                    
                    if hasMilestones {
                        milestonesListSection
                        linkedTasksSection
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Edit Goal")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { save() }
                        .disabled(title.isEmpty || (hasMilestones && milestonesDraft.contains(where: { $0.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty })))
                }
            }
            // AddTaskToGoalView is now implemented above in the main body
            .alert("Milestone Name Required", isPresented: $showingMilestoneError) {
                Button("OK") { showingMilestoneError = false }
            } message: {
                Text("All milestones must have a title.")
            }
        }
    }
    
    private var basicsSection: some View {
        Section("Basics") {
            transparentTextField(
                placeholder: "Title",
                text: $title,
                theme: themeManager.currentTheme
            )
            transparentTextEditor(
                text: $descriptionText,
                theme: themeManager.currentTheme,
                placeholder: "Description",
                minHeight: 80
            )
            Picker("Category", selection: $category) {
                ForEach(GoalCategory.allCases, id: \.self) { c in
                    HStack { Image(systemName: c.icon); Text(c.displayName) }.tag(c)
                }
            }
            Picker("Priority", selection: $priority) {
                ForEach(GoalPriority.allCases, id: \.self) { p in
                    HStack {
                        Circle().fill(p.color).frame(width: 12, height: 12)
                        Text(p.rawValue)
                    }.tag(p)
                }
            }
        }
    }
    
    private var timingSection: some View {
        Section("Timing") {
            DatePicker("Start Date", selection: $startDate, displayedComponents: [.date])
            Toggle("Set End Date", isOn: $hasEndDate)
            if hasEndDate { DatePicker("End Date", selection: $endDate, displayedComponents: [.date]) }
        }
    }
    
    private var statusSection: some View {
        Section("Status") {
            if goal.status == .paused {
                Button("Resume Goal") { status = .active }
            } else {
                Button("Pause Goal") { status = .paused }
            }
        }
    }
    
    private var structureSection: some View {
        Section("Structure") {
            Toggle("Use Milestones", isOn: $hasMilestones)
                .onChange(of: hasMilestones) { _, newValue in
                    if newValue {
                        // 🛠️ FIX: Unwrapping
                        if milestonesDraft.isEmpty && !(goal.milestones ?? []).isEmpty {
                            milestonesDraft = (goal.milestones ?? []).map {
                                GoalMilestoneDraft(id: $0.id, title: $0.title, hasDeadline: $0.deadline != nil, deadline: $0.deadline ?? Date())
                            }
                        } else if milestonesDraft.isEmpty {
                            milestonesDraft.append(GoalMilestoneDraft())
                        }
                    }
                }
        }
    }
    
    private var milestonesListSection: some View {
        Section(header: Text("Milestones")) {
            ForEach($milestonesDraft) { $milestone in
                milestoneEditor($milestone)
                    .swipeActions {
                        Button(role: .destructive) {
                            if let index = milestonesDraft.firstIndex(where: { $0.id == milestone.id }) {
                                milestonesDraft.remove(at: index)
                            }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
            }
            .onDelete { indexSet in
                milestonesDraft.remove(atOffsets: indexSet)
            }
            
            Button("Add Milestone") {
                milestonesDraft.append(GoalMilestoneDraft())
            }
        }
    }
    
    private var linkedTasksSection: some View {
        Section(header: Text("Linked Tasks")) {
            ForEach(milestonesDraft) { milestone in
                let milestoneTasks = goalTasks.filter { $0.milestone?.id == milestone.id }
                DisclosureGroup("\(milestone.title) (\(milestoneTasks.count) tasks)") {
                    if milestoneTasks.isEmpty {
                        Button("Link Task to \(milestone.title)") {
                            showingAddTaskToMilestone = milestone.id
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    } else {
                        ForEach(milestoneTasks, id: \.id) { task in
                            HStack {
                                Text(task.title).font(.caption)
                                Spacer()
                                if task.isComplete {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                        .font(.caption2)
                                }
                            }
                            .swipeActions {
                                Button(role: .destructive) {
                                    task.milestone = nil
                                    try? modelContext.save()
                                } label: {
                                    Label("Unlink", systemImage: "link.badge.minus")
                                }
                            }
                        }
                        Button("Link More Tasks") {
                            showingAddTaskToMilestone = milestone.id
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func milestoneEditor(_ milestone: Binding<GoalMilestoneDraft>) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            transparentTextField(
                placeholder: "Milestone title *",
                text: milestone.title,
                theme: themeManager.currentTheme
            )
            
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
    
    private func save() {
        if hasMilestones {
            let invalidMilestones = milestonesDraft.filter { $0.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            if !invalidMilestones.isEmpty {
                showingMilestoneError = true
                return
            }
        }
        
        goal.title = title
        goal.goalDescription = descriptionText.isEmpty ? nil : descriptionText
        goal.category = category
        goal.priority = priority
        goal.startDate = startDate
        goal.deadline = hasEndDate ? endDate : nil
        goal.status = status
        
        // 🛠️ FIX: Milestone Logic for Relationships
        let currentMilestones = goal.milestones ?? []
        let existingMilestoneIDs = Set(currentMilestones.map { $0.id })
        let draftMilestoneIDs = Set(milestonesDraft.map { $0.id })
        
        // Find IDs to delete
        let toDeleteIDs = existingMilestoneIDs.subtracting(draftMilestoneIDs)
        
        // Unlink tasks from deleted milestones before deletion to avoid cascade issues if needed
        // (Cascade delete rule usually handles deleting the milestone object, tasks become unlinked automatically if nullify)
        
        // Remove deleted milestones from the relationship
        if var mutableMilestones = goal.milestones {
             mutableMilestones.removeAll { toDeleteIDs.contains($0.id) }
             goal.milestones = mutableMilestones
        }
        
        // Update existing or Create new
        var updatedList = goal.milestones ?? []
        
        for draft in milestonesDraft {
            if let existing = updatedList.first(where: { $0.id == draft.id }) {
                existing.title = draft.title
                existing.deadline = draft.hasDeadline ? draft.deadline : nil
            } else {
                let newMilestone = GoalMilestone(
                    id: draft.id,
                    title: draft.title,
                    targetValue: 0,
                    isComplete: false,
                    deadline: draft.hasDeadline ? draft.deadline : nil
                )
                modelContext.insert(newMilestone)
                updatedList.append(newMilestone)
            }
        }
        goal.milestones = updatedList
        
        try? modelContext.save()
        dismiss()
    }
}

// MARK: - Update Progress Inline View
struct UpdateProgressInlineView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let goal: Goal
    @Query private var tasks: [Task]
    @State private var value: Double
    
    init(goal: Goal) {
        self.goal = goal
        _value = State(initialValue: Double(goal.currentValue))
        let goalID = goal.id
        
        // 🛠️ FIX: Predicate update
        _tasks = Query(filter: #Predicate<Task> { task in
            if let g = task.goal {
                return g.id == goalID
            } else {
                return false
            }
        })
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Progress") {
                    Slider(value: $value, in: 0...Double(max(goal.targetValue, 1)), step: 1)
                    Text("\(Int(value))/\(goal.targetValue)")
                }
                Section("Milestones") {
                    if (goal.milestones ?? []).isEmpty { Text("No milestones").foregroundColor(.secondary) }
                    ForEach(goal.milestones ?? [], id: \.id) { m in
                        HStack {
                            Text(m.title)
                            Spacer()
                            Text(String(format: "%.0f%%", milestoneProgress(m) * 100)).foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Update Progress")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .navigationBarTrailing) { Button("Save") { save() } }
            }
        }
    }
    
    private func milestoneProgress(_ m: GoalMilestone) -> Double {
        let linked = tasks.filter { $0.milestone?.id == m.id }
        guard !linked.isEmpty else { return 0 }
        let done = linked.filter { $0.isComplete }.count
        return Double(done) / Double(linked.count)
    }
    
    private func save() {
        goal.currentValue = min(max(Int(value), 0), goal.targetValue)
        goal.status = goal.currentValue == goal.targetValue ? .completed : .active
        try? modelContext.save()
        dismiss()
    }
}
