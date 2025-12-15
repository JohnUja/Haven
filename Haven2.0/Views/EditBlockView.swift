//
//  EditBlockView.swift
//  Haven2.0
//
//  Created to edit task blocks
//

import SwiftUI
import SwiftData

struct EditBlockView: View {
    let taskBlock: TaskBlock
    let tasksInBlock: [Task]
    let allTasks: [Task] // All tasks to check for overlaps
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(ThemeManager.self) private var themeManager
    @EnvironmentObject private var timeSettings: TimeSettingsManager
    
    @State private var title: String
    @State private var blockDescription: String
    @State private var priority: PriorityType
    @State private var isLocked: Bool
    @State private var isRecurring: Bool
    @State private var recurrenceType: RecurrenceType = .daily
    @State private var recurrenceEndDate: Date = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
    @State private var newStartTime: Date
    @State private var showingDeleteAlert = false
    @State private var showingTimeOverlapAlert = false
    @State private var overlappingTasks: [Task] = []
    @State private var localTasksInBlock: [Task] = [] // Local copy for immediate UI updates
    @State private var showLockScopeDialog = false
    @State private var pendingLockValue: Bool = false
    
    init(taskBlock: TaskBlock, tasksInBlock: [Task], allTasks: [Task]) {
        self.taskBlock = taskBlock
        self.tasksInBlock = tasksInBlock
        self.allTasks = allTasks
        
        // Calculate current block start time (from earliest task)
        let earliestTask = tasksInBlock.sorted(by: { $0.startTime < $1.startTime }).first
        let currentStartTime = earliestTask?.startTime ?? Date()
        
        self._title = State(initialValue: taskBlock.title)
        self._blockDescription = State(initialValue: taskBlock.blockDescription ?? "")
        self._priority = State(initialValue: taskBlock.priority)
        self._isLocked = State(initialValue: taskBlock.isLocked)
        self._isRecurring = State(initialValue: taskBlock.isRecurring)
        self._newStartTime = State(initialValue: currentStartTime)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background using theme gradient
                themeManager.currentTheme.primaryGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Block Details Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("BLOCK DETAILS")
                                .font(.system(size: 12, weight: .semibold, design: .default))
                                .foregroundColor(themeManager.currentTheme.textPrimary.opacity(0.7))
                                .textCase(.uppercase)
                            
                            transparentTextField(
                                placeholder: "Block Title",
                                text: $title,
                                theme: themeManager.currentTheme
                            )
                            
                            transparentTextField(
                                placeholder: "Description (Optional)",
                                text: $blockDescription,
                                theme: themeManager.currentTheme,
                                axis: .vertical,
                                lineLimit: 3...6
                            )
                        }
                        .padding(.horizontal, 20)
                        
                        // Time Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("TIME")
                                .font(.system(size: 12, weight: .semibold, design: .default))
                                .foregroundColor(themeManager.currentTheme.textPrimary.opacity(0.7))
                                .textCase(.uppercase)
                            
                            DatePicker("Start Time", selection: $newStartTime, displayedComponents: [.hourAndMinute, .date])
                                .padding(.horizontal, themeManager.currentTheme.cardPadding)
                                .padding(.vertical, themeManager.currentTheme.cardVerticalPadding)
                                .background(transparentInputBackground(theme: themeManager.currentTheme))
                                .cornerRadius(themeManager.currentTheme.smallCornerRadius)
                            
                            Text("Moving the block start time will adjust all tasks within it by the same amount.")
                                .font(.caption)
                                .foregroundColor(themeManager.currentTheme.textSecondary)
                        }
                        .padding(.horizontal, 20)
                        
                        // Priority Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("PRIORITY")
                                .font(.system(size: 12, weight: .semibold, design: .default))
                                .foregroundColor(themeManager.currentTheme.textPrimary.opacity(0.7))
                                .textCase(.uppercase)
                            
                            Picker("Priority", selection: $priority) {
                                ForEach(PriorityType.allCases, id: \.self) { priority in
                                    Text(priority.rawValue.capitalized).tag(priority)
                                }
                            }
                            .padding(.horizontal, themeManager.currentTheme.cardPadding)
                            .padding(.vertical, themeManager.currentTheme.cardVerticalPadding)
                            .background(transparentInputBackground(theme: themeManager.currentTheme))
                            .cornerRadius(themeManager.currentTheme.smallCornerRadius)
                        }
                        .padding(.horizontal, 20)
                        
                        // Settings Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("SETTINGS")
                                .font(.system(size: 12, weight: .semibold, design: .default))
                                .foregroundColor(themeManager.currentTheme.textPrimary.opacity(0.7))
                                .textCase(.uppercase)
                            
                            Toggle("Lock block", isOn: Binding(
                                get: { isLocked },
                                set: { newValue in
                                    // If part of recurrence, show scope dialog; otherwise just toggle
                                    if taskBlock.recurrenceSeriesID != nil {
                                        pendingLockValue = newValue
                                        showLockScopeDialog = true
                                    } else {
                                        isLocked = newValue
                                    }
                                }
                            ))
                            .padding(.horizontal, themeManager.currentTheme.cardPadding)
                            .padding(.vertical, themeManager.currentTheme.cardVerticalPadding)
                            .background(transparentInputBackground(theme: themeManager.currentTheme))
                            .cornerRadius(themeManager.currentTheme.smallCornerRadius)
                            
                            Toggle("Make recurring", isOn: $isRecurring)
                                .padding(.horizontal, themeManager.currentTheme.cardPadding)
                                .padding(.vertical, themeManager.currentTheme.cardVerticalPadding)
                                .background(transparentInputBackground(theme: themeManager.currentTheme))
                                .cornerRadius(themeManager.currentTheme.smallCornerRadius)
                            
                            if isRecurring {
                                Picker("Repeat", selection: $recurrenceType) {
                                    ForEach(RecurrenceType.allCases, id: \.self) { type in
                                        Text(type.displayName).tag(type)
                                    }
                                }
                                .pickerStyle(.segmented)
                                .padding(.horizontal, themeManager.currentTheme.cardPadding)
                                .padding(.vertical, themeManager.currentTheme.cardVerticalPadding)
                                .background(transparentInputBackground(theme: themeManager.currentTheme))
                                .cornerRadius(themeManager.currentTheme.smallCornerRadius)
                                
                                DatePicker("End date", selection: $recurrenceEndDate, displayedComponents: [.date])
                                    .datePickerStyle(.compact)
                                    .padding(.horizontal, themeManager.currentTheme.cardPadding)
                                    .padding(.vertical, themeManager.currentTheme.cardVerticalPadding)
                                    .background(transparentInputBackground(theme: themeManager.currentTheme))
                                    .cornerRadius(themeManager.currentTheme.smallCornerRadius)
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Subtasks Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("SUBTASKS")
                                .font(.system(size: 12, weight: .semibold, design: .default))
                                .foregroundColor(themeManager.currentTheme.textPrimary.opacity(0.7))
                                .textCase(.uppercase)
                            
                            ForEach(localTasksInBlock, id: \.id) { task in
                                HStack {
                                    transparentTextField(
                                        placeholder: "Title",
                                        text: Binding(
                                            get: { task.title },
                                            set: { task.title = $0 }
                                        ),
                                        theme: themeManager.currentTheme
                                    )
                                    Spacer()
                                    Text("\(timeSettings.formatTime(task.startTime)) - \(timeSettings.formatTime(task.endTime))")
                                        .font(.caption)
                                        .foregroundColor(themeManager.currentTheme.textSecondary)
                                    Button(action: {
                                        // Remove from model and local list immediately
                                        task.taskBlock = nil
                                        localTasksInBlock.removeAll { $0.id == task.id }
                                        try? modelContext.save()
                                    }) {
                                        Image(systemName: "minus.circle.fill").foregroundColor(.red)
                                    }
                                }
                            }
                            
                            Button(action: { addSubtask() }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "plus.circle.fill").foregroundColor(.green)
                                    Text("Add Subtask").foregroundColor(.green)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Delete Button
                        Button("Delete Block", role: .destructive) {
                            showingDeleteAlert = true
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, themeManager.currentTheme.cardVerticalPadding)
                        .background(
                            RoundedRectangle(cornerRadius: themeManager.currentTheme.smallCornerRadius)
                                .fill(Color.red.opacity(0.2))
                                .overlay(
                                    RoundedRectangle(cornerRadius: themeManager.currentTheme.smallCornerRadius)
                                        .stroke(Color.red, lineWidth: themeManager.currentTheme.cardBorderWidth)
                                )
                        )
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("Edit Block")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(title.isEmpty)
                }
            }
            .onAppear {
                // Initialize local tasks for live UI updates
                localTasksInBlock = tasksInBlock
            }
        }
        .confirmationDialog(
            isLocked ? "Unlock Scope" : "Lock Scope",
            isPresented: $showLockScopeDialog,
            titleVisibility: .visible
        ) {
            if let seriesID = taskBlock.recurrenceSeriesID {
                if pendingLockValue {
                    Button("Lock only this block") {
                        isLocked = true
                        taskBlock.isLocked = true
                        try? modelContext.save()
                    }
                    Button("Lock all in series") {
                        isLocked = true
                        taskBlock.isLocked = true
                        lockSeriesBlocks(seriesID: seriesID, lock: true, modelContext: modelContext)
                        lockSeriesTasks(seriesID: seriesID, lock: true, modelContext: modelContext)
                    }
                } else {
                    Button("Unlock only this block") {
                        isLocked = false
                        taskBlock.isLocked = false
                        try? modelContext.save()
                    }
                    Button("Unlock all in series") {
                        isLocked = false
                        taskBlock.isLocked = false
                        lockSeriesBlocks(seriesID: seriesID, lock: false, modelContext: modelContext)
                        lockSeriesTasks(seriesID: seriesID, lock: false, modelContext: modelContext)
                    }
                }
                Button("Cancel", role: .cancel) {
                    // Revert toggle to current model value
                    isLocked = taskBlock.isLocked
                }
            }
        }
        .alert("Delete Block", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                deleteBlock()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete this block? All tasks within it will be deleted. This action cannot be undone.")
        }
        .alert("Time Overlap Detected", isPresented: $showingTimeOverlapAlert) {
            Button("Proceed", role: .destructive) {
                // Save changes despite overlap
                applyTimeChange()
                taskBlock.title = title
                taskBlock.blockDescription = blockDescription.isEmpty ? nil : blockDescription
                taskBlock.priority = priority
                taskBlock.isLocked = isLocked
                taskBlock.isRecurring = isRecurring
                do {
                    try modelContext.save()
                    dismiss()
                } catch {
                    print("Failed to save block: \(error.localizedDescription)")
                }
            }
            Button("Cancel", role: .cancel) {
                // Reset start time
                let earliestTask = tasksInBlock.sorted(by: { $0.startTime < $1.startTime }).first
                newStartTime = earliestTask?.startTime ?? Date()
            }
        } message: {
            if !overlappingTasks.isEmpty {
                let taskTitles = overlappingTasks.prefix(3).map { $0.title }.joined(separator: ", ")
                let moreText = overlappingTasks.count > 3 ? " and \(overlappingTasks.count - 3) more" : ""
                Text("Moving the block will cause overlaps with: \(taskTitles)\(moreText). Do you want to proceed?")
            } else {
                Text("Moving the block will cause overlaps with other tasks. Do you want to proceed?")
            }
        }
    }
    
    private func saveChanges() {
        // Calculate time difference if start time changed
        let earliestTask = tasksInBlock.sorted(by: { $0.startTime < $1.startTime }).first
        guard let earliestTask = earliestTask else { return }
        
        let currentStartTime = earliestTask.startTime
        let timeDifference = newStartTime.timeIntervalSince(currentStartTime)
        
        if abs(timeDifference) > 60 { // Only check if changed by more than 1 minute
            // Calculate new times for all tasks
            var newTaskTimes: [(Task, Date, Date)] = []
            for task in localTasksInBlock {
                let newStart = task.startTime.addingTimeInterval(timeDifference)
                let newEnd = task.endTime.addingTimeInterval(timeDifference)
                newTaskTimes.append((task, newStart, newEnd))
            }
            
            // Check for overlaps
            let overlapping = findOverlappingTasks(newTaskTimes: newTaskTimes)
            if !overlapping.isEmpty {
                overlappingTasks = overlapping
                showingTimeOverlapAlert = true
                return // Don't save yet, wait for user confirmation
            }
        }
        
        // No overlaps - save normally
        applyTimeChange()
        taskBlock.title = title
        taskBlock.blockDescription = blockDescription.isEmpty ? nil : blockDescription
        taskBlock.priority = priority
        taskBlock.isLocked = isLocked
        taskBlock.isRecurring = isRecurring
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Failed to save block: \(error.localizedDescription)")
        }
    }
    
    private func applyTimeChange() {
        let earliestTask = tasksInBlock.sorted(by: { $0.startTime < $1.startTime }).first
        guard let earliestTask = earliestTask else { return }
        
        let currentStartTime = earliestTask.startTime
        let timeDifference = newStartTime.timeIntervalSince(currentStartTime)
        
        // Apply time change to all tasks in the block
        for task in tasksInBlock {
            task.startTime = task.startTime.addingTimeInterval(timeDifference)
            task.endTime = task.endTime.addingTimeInterval(timeDifference)
        }
    }
    
    private func findOverlappingTasks(newTaskTimes: [(Task, Date, Date)]) -> [Task] {
        var overlapping: [Task] = []
        
        for (_, newStart, newEnd) in newTaskTimes {
            // Check against all tasks not in this block
            let conflicts = allTasks.filter { otherTask in
                // Don't check against tasks in this block
                if tasksInBlock.contains(where: { $0.id == otherTask.id }) {
                    return false
                }
                // Check if times overlap
                return newStart < otherTask.endTime && otherTask.startTime < newEnd
            }
            overlapping.append(contentsOf: conflicts)
        }
        
        // Remove duplicates
        return Array(Set(overlapping.map { $0.id })).compactMap { id in
            allTasks.first(where: { $0.id == id })
        }
    }
    
    private func deleteBlock() {
        // Delete all tasks in the block
        for task in tasksInBlock {
            modelContext.delete(task)
        }
        // Delete the block
        modelContext.delete(taskBlock)
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Failed to delete block: \(error.localizedDescription)")
        }
    }
}

extension EditBlockView {
    private func addSubtask() {
        let sortedTasks = localTasksInBlock.sorted(by: { $0.endTime < $1.endTime })
        guard let lastEnd = sortedTasks.last?.endTime ?? tasksInBlock.sorted(by: { $0.endTime < $1.endTime }).last?.endTime else { return }
        let newTask = Task(userID: taskBlock.userID,
                           title: "New Task",
                           startTime: lastEnd,
                           endTime: lastEnd.addingTimeInterval(15 * 60),
                           priority: priority,
                           category: .personal,
                           isComplete: false,
                           taskBlock: taskBlock)
        modelContext.insert(newTask)
        localTasksInBlock.append(newTask) // Immediate UI update
        try? modelContext.save()
    }
}

