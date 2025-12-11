//
//  RoutineSetupView.swift
//  Haven2.0
//
//  Created by AI on 2025-11-03.
//

import SwiftUI
import SwiftData

struct RoutineSetupView: View {
    @Environment(ThemeManager.self) private var themeManager
    private let routineToEdit: DailyRoutine?
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(FirebaseAuthService.self) private var authService
    @Query private var users: [User]
    
    @State private var routineTitle: String
    @State private var selectedTemplates: Set<String>
    @State private var customTasks: [RoutineTaskTemplate]
    @State private var durationType: RoutineDurationType
    @State private var durationDays: Int
    @State private var notificationEnabled: Bool
    @State private var showAddTask: Bool
    
    // Default templates
    private static let defaultTemplateCatalog: [RoutineTaskTemplate] = [
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
    
    private var defaultTemplates: [RoutineTaskTemplate] {
        Self.defaultTemplateCatalog
    }
    
    private var defaultTemplateLookup: [String: RoutineTaskTemplate] {
        Dictionary(uniqueKeysWithValues: defaultTemplates.map { ($0.id, $0) })
    }
    
    init(routineToEdit: DailyRoutine? = nil) {
        self.routineToEdit = routineToEdit
        let defaults = RoutineSetupView.defaultTemplateCatalog
        let defaultIDs = Set(defaults.map { $0.id })
        
        if let routine = routineToEdit {
            let defaultSelections = routine.taskTemplates.filter { defaultIDs.contains($0.id) }
            let customSelections = routine.taskTemplates.filter { !defaultIDs.contains($0.id) }
            
            _routineTitle = State(initialValue: routine.title)
            _selectedTemplates = State(initialValue: Set(defaultSelections.map { $0.id }))
            _customTasks = State(initialValue: customSelections)
            _durationType = State(initialValue: routine.durationType)
            _durationDays = State(initialValue: routine.durationDays ?? 30)
            _notificationEnabled = State(initialValue: routine.notificationEnabled)
        } else {
            _routineTitle = State(initialValue: "My Daily Essentials")
            _selectedTemplates = State(initialValue: [])
            _customTasks = State(initialValue: [])
            _durationType = State(initialValue: .tillMonthEnd)
            _durationDays = State(initialValue: 30)
            _notificationEnabled = State(initialValue: true)
        }
        _showAddTask = State(initialValue: false)
    }
    
    private var currentUser: User? {
        users.first
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Routine Name") {
                    transparentTextField(
                        placeholder: "Routine name",
                        text: $routineTitle,
                        theme: themeManager.currentTheme
                    )
                }
                
                Section("Default Tasks") {
                    Text("These are daily tasks everyone needs. Toggle them on/off:")
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundColor(themeManager.currentTheme.textSecondary)
                    
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
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                Text(template.timeOfDay)
                                    .font(.system(size: 12, weight: .regular, design: .rounded))
                                    .foregroundColor(themeManager.currentTheme.textSecondary)
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
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                Text("\(task.timeOfDay) • \(task.durationMinutes) min")
                                    .font(.system(size: 12, weight: .regular, design: .rounded))
                                    .foregroundColor(themeManager.currentTheme.textSecondary)
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
                            .font(.system(size: 12, weight: .regular, design: .rounded))
                            .foregroundColor(themeManager.currentTheme.textSecondary)
                    }
                }
                
                Section("Notifications") {
                    Toggle("Enable notifications", isOn: $notificationEnabled)
                }
            }
            .scrollContentBackground(.hidden)
            .listStyle(.insetGrouped)
            .navigationTitle(routineToEdit == nil ? "Setup Routine" : "Edit Routine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(routineToEdit == nil ? "Save" : "Update") {
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
        // Combine default templates (selected) and custom tasks
        var allTemplates: [RoutineTaskTemplate] = selectedTemplates.compactMap { defaultTemplateLookup[$0] }
        allTemplates.append(contentsOf: customTasks)
        allTemplates.sort { $0.timeOfDay < $1.timeOfDay }
        
        guard !allTemplates.isEmpty else { return }
        
        if let routine = routineToEdit {
            updateExistingRoutine(routine, with: allTemplates)
        } else {
            guard let user = currentUser else { return }
            createRoutine(for: user, templates: allTemplates)
        }
    }
    
    private func createRoutine(for user: User, templates: [RoutineTaskTemplate]) {
        let routine = DailyRoutine(
            userID: user.id,
            title: routineTitle,
            isActive: true,
            isDefault: false,
            durationType: durationType,
            durationDays: durationType == .days ? durationDays : nil,
            startDate: Date(),
            taskTemplates: templates,
            notificationEnabled: notificationEnabled
        )
        
        modelContext.insert(routine)
        RoutineService.shared.generateTasksFromRoutine(routine, in: modelContext)
        
        do {
            try modelContext.save()
            // Post notification for onboarding flow
            NotificationCenter.default.post(name: NSNotification.Name("RoutineCreated"), object: nil)
            dismiss()
        } catch {
            print("Error saving routine: \(error)")
        }
    }
    
    private func updateExistingRoutine(_ routine: DailyRoutine, with templates: [RoutineTaskTemplate]) {
        routine.title = routineTitle
        routine.taskTemplates = templates
        routine.notificationEnabled = notificationEnabled
        routine.durationType = durationType
        routine.durationDays = durationType == .days ? durationDays : nil
        routine.startDate = Date()
        routine.updatedAt = Date()
        routine.isActive = true
        
        let calendar = Calendar.current
        if routine.durationType == .tillMonthEnd {
            if let monthEnd = calendar.dateInterval(of: .month, for: routine.startDate)?.end {
                routine.endDate = calendar.date(byAdding: .day, value: -1, to: monthEnd)
            } else {
                routine.endDate = nil
            }
        } else if let days = routine.durationDays {
            routine.endDate = calendar.date(byAdding: .day, value: days, to: routine.startDate)
        } else {
            routine.endDate = nil
        }
        
        RoutineService.shared.removeTasks(for: routine, in: modelContext)
        RoutineService.shared.generateTasksFromRoutine(routine, in: modelContext)
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Error updating routine: \(error)")
        }
    }
}

struct RoutineTaskEditorView: View {
    @Binding var task: RoutineTaskTemplate
    @Environment(\.dismiss) private var dismiss
    @Environment(ThemeManager.self) private var themeManager
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
                    transparentTextField(
                        placeholder: "Task title",
                        text: $title,
                        theme: themeManager.currentTheme
                    )
                    transparentTextField(
                        placeholder: "Description (optional)",
                        text: $description,
                        theme: themeManager.currentTheme,
                        axis: .vertical,
                        lineLimit: 3...6
                    )
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

