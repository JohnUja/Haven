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
    @State private var isRecurring = false
    @State private var recurrenceType: RecurrenceType = .daily
    @State private var recurrenceEndDate = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
    @State private var isFlexibleTask = false
    
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
                    
                    // Priority dropdown
                    Picker("Priority", selection: $priority) {
                        ForEach(PriorityType.allCases, id: \.self) { priority in
                            Text(priority.rawValue.capitalized).tag(priority)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Section("Task Type") {
                    Toggle("Flexible task (no specific time)", isOn: $isFlexibleTask)
                        .onChange(of: isFlexibleTask) { _, newValue in
                            if newValue {
                                hasEndTime = false
                            }
                        }
                }
                
                Section("Time") {
                    if !isFlexibleTask {
                        NumericTimeInput(time: $startTime, title: "Start time")
                            .onChange(of: startTime) { _, newValue in
                                // Prevent past times for today
                                if Calendar.current.isDateInToday(newValue) && newValue < Date() {
                                    startTime = Date()
                                }
                            }
                        
                        Toggle("Has end time", isOn: $hasEndTime)
                        
                        if hasEndTime {
                            NumericTimeInput(time: $endTime, title: "End time")
                        }
                    } else {
                        Text("This task can be done anytime today")
                            .foregroundColor(.secondary)
                            .italic()
                    }
                }
                
                Section("Category") {
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
                }
                
                Section("Recurrence") {
                    Toggle("Make this a recurring task", isOn: $isRecurring)
                    
                    if isRecurring {
                        Picker("Repeat", selection: $recurrenceType) {
                            ForEach(RecurrenceType.allCases, id: \.self) { type in
                                Text(type.displayName).tag(type)
                            }
                        }
                        .pickerStyle(.segmented)
                        
                        DatePicker("End date", selection: $recurrenceEndDate, displayedComponents: [.date])
                            .datePickerStyle(.compact)
                    }
                }
                
                Section("Settings") {
                    Toggle("Lock task", isOn: $isLocked)
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
        
        if isRecurring {
            createRecurringTasks(user: user)
        } else {
            createSingleTask(user: user)
        }
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Error saving task: \(error)")
        }
    }
    
    private func createSingleTask(user: User) {
        let task = Task(
            userID: user.id,
            title: title,
            taskDescription: taskDescription.isEmpty ? nil : taskDescription,
            startTime: isFlexibleTask ? selectedDate : startTime,
            endTime: isFlexibleTask ? selectedDate : (hasEndTime ? endTime : startTime),
            priority: priority,
            category: category,
            taskBlockID: taskBlockID
        )
        
        task.isLocked = isLocked
        modelContext.insert(task)
    }
    
    private func createRecurringTasks(user: User) {
        let calendar = Calendar.current
        var currentDate = startTime
        let endDate = recurrenceEndDate
        
        while currentDate <= endDate {
            // Check if we should create a task for this date based on recurrence type
            if shouldCreateTaskForDate(currentDate) {
                let task = Task(
                    userID: user.id,
                    title: title,
                    taskDescription: taskDescription.isEmpty ? nil : taskDescription,
                    startTime: isFlexibleTask ? currentDate : currentDate,
                    endTime: isFlexibleTask ? currentDate : (hasEndTime ? calendar.date(byAdding: .hour, value: 1, to: currentDate) ?? currentDate : currentDate),
                    priority: priority,
                    category: category,
                    taskBlockID: taskBlockID
                )
                
                task.isLocked = isLocked
                modelContext.insert(task)
            }
            
            // Move to next occurrence
            switch recurrenceType {
            case .daily:
                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
            case .weekdays:
                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
                // Skip weekends
                while calendar.isDateInWeekend(currentDate) {
                    currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
                }
            case .weekly:
                currentDate = calendar.date(byAdding: .weekOfYear, value: 1, to: currentDate) ?? currentDate
            case .custom:
                // For custom, just do daily for now
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
            return true // For now, treat custom as daily
        }
    }
}

#Preview {
    AddTaskView(selectedDate: Date())
        .modelContainer(for: [User.self, Task.self], inMemory: true)
}
