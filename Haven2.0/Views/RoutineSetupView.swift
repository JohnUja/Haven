//
//  RoutineSetupView.swift
//  Haven2.0
//
//  Created by AI on 2025-11-03.
//

import SwiftUI
import SwiftData

struct RoutineSetupView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authService: FirebaseAuthService
    @Query private var users: [User]
    
    @State private var routineTitle = "My Daily Essentials"
    @State private var selectedTemplates: Set<String> = [] // Default template IDs
    @State private var customTasks: [RoutineTaskTemplate] = []
    @State private var durationType: RoutineDurationType = .tillMonthEnd
    @State private var durationDays: Int = 30
    @State private var notificationEnabled = true
    @State private var showAddTask = false
    
    // Default templates
    let defaultTemplates: [RoutineTaskTemplate] = [
        RoutineTaskTemplate(
            id: "sleep",
            title: "Sleep",
            description: "Good night's rest",
            timeOfDay: "22:00",
            durationMinutes: 540, // 9 hours
            priority: .normal,
            category: .selfCare,
            hasDefaultNotifications: true
        ),
        RoutineTaskTemplate(
            id: "breakfast",
            title: "Eat Breakfast",
            description: "Morning meal",
            timeOfDay: "08:00",
            durationMinutes: 30,
            priority: .normal,
            category: .selfCare,
            hasDefaultNotifications: true
        ),
        RoutineTaskTemplate(
            id: "lunch",
            title: "Eat Lunch",
            description: "Midday meal",
            timeOfDay: "12:00",
            durationMinutes: 30,
            priority: .normal,
            category: .selfCare,
            hasDefaultNotifications: true
        ),
        RoutineTaskTemplate(
            id: "dinner",
            title: "Eat Dinner",
            description: "Evening meal",
            timeOfDay: "18:00",
            durationMinutes: 45,
            priority: .normal,
            category: .selfCare,
            hasDefaultNotifications: true
        )
    ]
    
    private var currentUser: User? {
        users.first
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Routine Name") {
                    TextField("Routine name", text: $routineTitle)
                }
                
                Section("Default Tasks") {
                    Text("These are daily tasks everyone needs. Toggle them on/off:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ForEach(defaultTemplates) { template in
                        Toggle(isOn: Binding(
                            get: { selectedTemplates.contains(template.id) },
                            set: { isSelected in
                                if isSelected {
                                    selectedTemplates.insert(template.id)
                                } else {
                                    selectedTemplates.remove(template.id)
                                }
                            }
                        )) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(template.title)
                                    .font(.headline)
                                Text(template.timeOfDay)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                Section("Custom Tasks") {
                    ForEach(customTasks) { task in
                        NavigationLink(destination: RoutineTaskEditorView(
                            task: Binding(
                                get: { task },
                                set: { newTask in
                                    if let index = customTasks.firstIndex(where: { $0.id == task.id }) {
                                        customTasks[index] = newTask
                                    }
                                }
                            )
                        )) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(task.title)
                                    .font(.headline)
                                Text("\(task.timeOfDay) • \(task.durationMinutes) min")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .onDelete { indexSet in
                        customTasks.remove(atOffsets: indexSet)
                    }
                    
                    Button(action: {
                        showAddTask = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Custom Task")
                        }
                    }
                }
                
                Section("Duration") {
                    Picker("Duration", selection: $durationType) {
                        Text("Till End of Month").tag(RoutineDurationType.tillMonthEnd)
                        Text("Custom Days").tag(RoutineDurationType.days)
                    }
                    
                    if durationType == .days {
                        Stepper("Days: \(durationDays)", value: $durationDays, in: 7...90)
                    } else {
                        Text("Tasks will be generated until the end of the current month. You'll be prompted to update on the first of next month.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("Notifications") {
                    Toggle("Enable notifications", isOn: $notificationEnabled)
                }
            }
            .navigationTitle("Setup Routine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveRoutine()
                    }
                    .disabled(routineTitle.isEmpty || (selectedTemplates.isEmpty && customTasks.isEmpty))
                }
            }
            .sheet(isPresented: $showAddTask) {
                RoutineTaskEditorView(
                    task: Binding(
                        get: { RoutineTaskTemplate(
                            title: "",
                            timeOfDay: "09:00",
                            durationMinutes: 30
                        ) },
                        set: { newTask in
                            customTasks.append(newTask)
                        }
                    ),
                    isNewTask: true
                )
            }
        }
    }
    
    private func saveRoutine() {
        guard let user = currentUser else { return }
        
        // Combine default templates (selected) and custom tasks
        var allTemplates: [RoutineTaskTemplate] = []
        
        // Add selected default templates
        for template in defaultTemplates where selectedTemplates.contains(template.id) {
            allTemplates.append(template)
        }
        
        // Add custom tasks
        allTemplates.append(contentsOf: customTasks)
        
        guard !allTemplates.isEmpty else { return }
        
        // Create routine
        let routine = DailyRoutine(
            userID: user.id,
            title: routineTitle,
            isActive: true,
            isDefault: false,
            durationType: durationType,
            durationDays: durationType == .days ? durationDays : nil,
            startDate: Date(),
            taskTemplates: allTemplates,
            notificationEnabled: notificationEnabled
        )
        
        modelContext.insert(routine)
        
        // Generate tasks from routine
        RoutineService.shared.generateTasksFromRoutine(routine, in: modelContext)
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Error saving routine: \(error)")
        }
    }
}

struct RoutineTaskEditorView: View {
    @Binding var task: RoutineTaskTemplate
    @Environment(\.dismiss) private var dismiss
    var isNewTask: Bool = false
    
    @State private var title: String = ""
    @State private var description: String = ""
    @State private var timeOfDay: Date = Date()
    @State private var durationMinutes: Int = 30
    @State private var priority: PriorityType = .normal
    @State private var category: TaskCategory = .personal
    
    var body: some View {
        NavigationView {
            Form {
                Section("Task Details") {
                    TextField("Task title", text: $title)
                    TextField("Description (optional)", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Time") {
                    NumericTimeInput(time: $timeOfDay, title: "Time of day")
                    
                    Stepper("Duration: \(durationMinutes) minutes", value: $durationMinutes, in: 5...480, step: 5)
                }
                
                Section("Priority") {
                    Picker("Priority", selection: $priority) {
                        ForEach(PriorityType.allCases, id: \.self) { p in
                            Text(p.rawValue.capitalized).tag(p)
                        }
                    }
                }
                
                Section("Category") {
                    Picker("Category", selection: $category) {
                        ForEach(TaskCategory.allCases, id: \.self) { c in
                            HStack {
                                Image(systemName: c.icon)
                                Text(c.displayName)
                            }.tag(c)
                        }
                    }
                }
            }
            .navigationTitle(isNewTask ? "New Task" : "Edit Task")
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
            .onAppear {
                if !isNewTask {
                    title = task.title
                    description = task.description ?? ""
                    
                    // Parse timeOfDay string to Date
                    let components = task.timeOfDay.split(separator: ":")
                    if components.count == 2,
                       let hour = Int(components[0]),
                       let minute = Int(components[1]) {
                        let calendar = Calendar.current
                        timeOfDay = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? Date()
                    }
                    
                    durationMinutes = task.durationMinutes
                    priority = task.priority
                    category = task.category
                }
            }
        }
    }
    
    private func saveTask() {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: timeOfDay)
        let minute = calendar.component(.minute, from: timeOfDay)
        let timeString = String(format: "%02d:%02d", hour, minute)
        
        task = RoutineTaskTemplate(
            id: task.id,
            title: title,
            description: description.isEmpty ? nil : description,
            timeOfDay: timeString,
            durationMinutes: durationMinutes,
            priority: priority,
            category: category,
            hasDefaultNotifications: false
        )
        
        dismiss()
    }
}

