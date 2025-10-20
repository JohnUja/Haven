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
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var title: String
    @State private var taskDescription: String
    @State private var priority: PriorityType
    @State private var category: TaskCategory
    @State private var isLocked: Bool
    @State private var showingDeleteAlert = false
    
    init(task: Task) {
        self.task = task
        self._title = State(initialValue: task.title)
        self._taskDescription = State(initialValue: task.taskDescription ?? "")
        self._priority = State(initialValue: task.priority)
        self._category = State(initialValue: task.category)
        self._isLocked = State(initialValue: task.isLocked)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Task Details") {
                    TextField("Task Title", text: $title)
                    
                    TextField("Description (Optional)", text: $taskDescription, axis: .vertical)
                        .lineLimit(3...6)
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
    }
    
    private func saveChanges() {
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
