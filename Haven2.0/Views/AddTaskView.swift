//
//  AddTaskView.swift
//  TimeFlow
//
//  Created by John Uja on 2025-10-18.
//

import SwiftUI
import SwiftData

struct AddTaskView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var users: [User]
    
    let selectedDate: Date
    let taskBlockID: String?
    
    init(selectedDate: Date, taskBlockID: String? = nil) {
        self.selectedDate = selectedDate
        self.taskBlockID = taskBlockID
    }
    
    @State private var title = ""
    @State private var taskDescription = ""
    @State private var startTime = Date()
    @State private var endTime = Date().addingTimeInterval(3600) // 1 hour later
    @State private var priority = PriorityType.normal
    @State private var category = TaskCategory.personal
    @State private var hasEndTime = true
    @State private var isLocked = false
    
    private var currentUser: User? {
        users.first
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Task Details") {
                    TextField("Task title", text: $title)
                    
                    TextField("Description (optional)", text: $taskDescription, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Time") {
                    DatePicker("Start time", selection: $startTime, displayedComponents: [.date, .hourAndMinute])
                    
                    Toggle("Has end time", isOn: $hasEndTime)
                    
                    if hasEndTime {
                        DatePicker("End time", selection: $endTime, displayedComponents: [.date, .hourAndMinute])
                    }
                }
                
                Section("Category & Priority") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Category")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                            ForEach(TaskCategory.allCases, id: \.self) { cat in
                                Button(action: { category = cat }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: cat.icon)
                                            .font(.title3)
                                            .foregroundColor(cat.color())
                                            .frame(width: 24, height: 24)
                                        
                                        Text(cat.displayName)
                                            .font(.body)
                                            .foregroundColor(.primary)
                                        
                                        Spacer()
                                        
                                        if category == cat {
                                            Image(systemName: "checkmark")
                                                .font(.caption)
                                                .foregroundColor(.blue)
                                        }
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(category == cat ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                    
                    Picker("Priority", selection: $priority) {
                        ForEach(PriorityType.allCases, id: \.self) { priority in
                            Text(priority.rawValue.capitalized).tag(priority)
                        }
                    }
                }
                
                Section("Settings") {
                    Toggle("Lock task (prevents moving on timeline)", isOn: $isLocked)
                }
            }
            .navigationTitle("Add Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveTask()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
        .onAppear {
            setupInitialTimes()
        }
    }
    
    private func setupInitialTimes() {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: selectedDate)
        let minute = calendar.component(.minute, from: selectedDate)
        
        startTime = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: selectedDate) ?? selectedDate
        endTime = calendar.date(byAdding: .hour, value: 1, to: startTime) ?? startTime
    }
    
    private func saveTask() {
        guard let user = currentUser else { return }
        
        let task = Task(
            userID: user.id,
            title: title,
            taskDescription: taskDescription.isEmpty ? nil : taskDescription,
            startTime: startTime,
            endTime: hasEndTime ? endTime : startTime,
            priority: priority,
            category: category,
            taskBlockID: taskBlockID
        )
        
        // Set lock status
        task.isLocked = isLocked
        
        modelContext.insert(task)
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Error saving task: \(error)")
        }
    }
}

#Preview {
    AddTaskView(selectedDate: Date())
        .modelContainer(for: [User.self, Task.self], inMemory: true)
}
