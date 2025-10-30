//
//  EditTaskView.swift
//  TimeFlow
//
//  Created by John Uja on 2025-10-18.
//

import SwiftUI
import SwiftData

struct EditTaskView: View {
    let task: Task
    let allTasks: [Task]? // Optional - all tasks to check for overlaps
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var timeSettings: TimeSettingsManager
    @Query private var allTasksQuery: [Task] // Query for all tasks if not provided
    
    @State private var title: String
    @State private var taskDescription: String
    @State private var priority: PriorityType
    @State private var category: TaskCategory
    @State private var isLocked: Bool
    @State private var startTime: Date
    @State private var endTime: Date
    @State private var showingDeleteAlert = false
    @State private var showingTimeOverlapAlert = false
    @State private var overlappingTasks: [Task] = []
    
    init(task: Task, allTasks: [Task]? = nil) {
        self.task = task
        self.allTasks = allTasks
        self._title = State(initialValue: task.title)
        self._taskDescription = State(initialValue: task.taskDescription ?? "")
        self._priority = State(initialValue: task.priority)
        self._category = State(initialValue: task.category)
        self._isLocked = State(initialValue: task.isLocked)
        self._startTime = State(initialValue: task.startTime)
        self._endTime = State(initialValue: task.endTime)
    }
    
    private var tasksToCheck: [Task] {
        allTasks ?? allTasksQuery
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Task Details") {
                    TextField("Task Title", text: $title)
                    
                    TextField("Description (Optional)", text: $taskDescription, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Time") {
                    DatePicker("Start Time", selection: $startTime, displayedComponents: [.hourAndMinute, .date])
                    DatePicker("End Time", selection: $endTime, displayedComponents: [.hourAndMinute, .date])
                }
                
                Section("Category & Priority") {
                    Picker("Category", selection: $category) {
                        ForEach(TaskCategory.allCases, id: \.self) { cat in
                            HStack {
                                Image(systemName: cat.icon)
                                    .foregroundColor(cat.color())
                                Text(cat.displayName)
                            }
                            .tag(cat)
                        }
                    }
                    
                    Picker("Priority", selection: $priority) {
                        ForEach(PriorityType.allCases, id: \.self) { priority in
                            Text(priority.rawValue.capitalized).tag(priority)
                        }
                    }
                }
                
                Section("Settings") {
                    Toggle("Lock task", isOn: $isLocked)
                }
                
                Section {
                    Button("Delete Task", role: .destructive) {
                        showingDeleteAlert = true
                    }
                }
            }
            .navigationTitle("Edit Task")
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
        }
        .alert("Delete Task", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                deleteTask()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete this task? This action cannot be undone.")
        }
        .alert("Time Overlap Detected", isPresented: $showingTimeOverlapAlert) {
            Button("Proceed", role: .destructive) {
                // Save changes despite overlap
                task.startTime = startTime
                task.endTime = endTime
                task.title = title
                task.taskDescription = taskDescription.isEmpty ? nil : taskDescription
                task.priority = priority
                task.category = category
                task.isLocked = isLocked
                do {
                    try modelContext.save()
                    dismiss()
                } catch {
                    print("Failed to save task: \(error.localizedDescription)")
                }
            }
            Button("Cancel", role: .cancel) {
                // Reset times to original values
                startTime = task.startTime
                endTime = task.endTime
            }
        } message: {
            if !overlappingTasks.isEmpty {
                let taskTitles = overlappingTasks.prefix(3).map { $0.title }.joined(separator: ", ")
                let moreText = overlappingTasks.count > 3 ? " and \(overlappingTasks.count - 3) more" : ""
                Text("The selected time overlaps with: \(taskTitles)\(moreText). Do you want to proceed?")
            } else {
                Text("The selected time overlaps with another task. Do you want to proceed?")
            }
        }
    }
    
    private func saveChanges() {
        // Validate end time is after start time
        guard endTime > startTime else {
            // TODO: Show error alert
            return
        }
        
        // Check for overlaps if time changed
        if startTime != task.startTime || endTime != task.endTime {
            let overlapping = findOverlappingTasks(newStartTime: startTime, newEndTime: endTime)
            if !overlapping.isEmpty {
                overlappingTasks = overlapping
                showingTimeOverlapAlert = true
                return // Don't save yet, wait for user confirmation
            }
        }
        
        // No overlaps or time didn't change - save normally
        task.title = title
        task.taskDescription = taskDescription.isEmpty ? nil : taskDescription
        task.priority = priority
        task.category = category
        task.isLocked = isLocked
        task.startTime = startTime
        task.endTime = endTime
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Failed to save task: \(error.localizedDescription)")
        }
    }
    
    private func findOverlappingTasks(newStartTime: Date, newEndTime: Date) -> [Task] {
        return tasksToCheck.filter { otherTask in
            // Don't check against ourselves
            if otherTask.id == task.id {
                return false
            }
            // Check if times overlap (within 5 minute tolerance)
            return newStartTime < otherTask.endTime && otherTask.startTime < newEndTime
        }
    }
    
    private func deleteTask() {
        modelContext.delete(task)
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Failed to delete task: \(error.localizedDescription)")
        }
    }
}

#Preview {
    EditTaskView(task: Task(
        userID: "test",
        title: "Sample Task",
        taskDescription: "Sample description",
        startTime: Date(),
        endTime: Date().addingTimeInterval(3600),
        priority: .high,
        category: .work
    ))
}
