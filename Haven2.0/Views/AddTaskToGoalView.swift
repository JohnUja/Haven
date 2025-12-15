//
//  AddTaskToGoalView.swift
//  Haven2.0
//
//  View for adding a new task to a goal
//

import SwiftUI
import SwiftData

struct AddTaskToGoalView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(ThemeManager.self) private var themeManager
    @Environment(FirebaseAuthService.self) private var authService
    
    let goal: Goal
    let preselectedMilestone: GoalMilestone?
    
    @Query private var users: [User]
    
    @State private var title: String = ""
    @State private var taskDescription: String = ""
    @State private var startTime: Date = Date()
    @State private var endTime: Date = Date().addingTimeInterval(3600)
    @State private var hasEndTime: Bool = true
    @State private var priority: PriorityType = .normal
    @State private var category: TaskCategory = .personal
    @State private var selectedMilestone: GoalMilestone?
    @State private var isRecurring: Bool = false
    @State private var recurrenceType: RecurrenceType = .daily
    @State private var recurrenceEndDate = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
    
    private var currentUser: User? {
        users.first
    }
    
    init(goal: Goal, preselectedMilestone: GoalMilestone? = nil) {
        self.goal = goal
        self.preselectedMilestone = preselectedMilestone
    }
    
    var body: some View {
        let theme = themeManager.currentTheme
        
        NavigationStack {
            ZStack {
                theme.primaryGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Title
                        sectionView(title: "TASK TITLE", theme: theme) {
                            ZStack(alignment: .leading) {
                                if title.isEmpty {
                                    Text("Task title")
                                        .foregroundColor(theme.textSecondary.opacity(0.6))
                                        .font(theme.bodyFont)
                                        .padding(.horizontal, theme.cardPadding)
                                        .padding(.vertical, theme.cardVerticalPadding)
                                }
                                TextField("", text: $title)
                                    .font(theme.bodyFont)
                                    .foregroundColor(theme.textPrimary)
                                    .accentColor(theme.accentColor)
                                    .padding(.horizontal, theme.cardPadding)
                                    .padding(.vertical, theme.cardVerticalPadding)
                            }
                            .background(transparentInputBackground(theme: theme))
                            .cornerRadius(theme.smallCornerRadius)
                        }
                        
                        // Description
                        sectionView(title: "DESCRIPTION", theme: theme) {
                            ZStack(alignment: .topLeading) {
                                if taskDescription.isEmpty {
                                    Text("Description (optional)")
                                        .foregroundColor(theme.textSecondary.opacity(0.6))
                                        .font(theme.bodyFont)
                                        .padding(.horizontal, theme.cardPadding)
                                        .padding(.vertical, theme.cardVerticalPadding)
                                }
                                TextEditor(text: $taskDescription)
                                    .font(theme.bodyFont)
                                    .foregroundColor(theme.textPrimary)
                                    .scrollContentBackground(.hidden)
                                    .frame(minHeight: 100)
                                    .padding(.horizontal, theme.cardPadding - 4)
                                    .padding(.vertical, theme.cardVerticalPadding - 4)
                            }
                            .background(transparentInputBackground(theme: theme))
                            .cornerRadius(theme.smallCornerRadius)
                        }
                        
                        // Milestone Selection
                        if let milestones = goal.milestones, !milestones.isEmpty {
                            sectionView(title: "MILESTONE", theme: theme) {
                                Menu {
                                    ForEach(milestones, id: \.id) { milestone in
                                        Button(action: {
                                            selectedMilestone = milestone
                                        }) {
                                            HStack {
                                                Text(milestone.title)
                                                if selectedMilestone?.id == milestone.id {
                                                    Image(systemName: "checkmark")
                                                }
                                            }
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Text(selectedMilestone?.title ?? preselectedMilestone?.title ?? "Select Milestone")
                                            .font(theme.bodyFont)
                                            .foregroundColor(theme.textPrimary)
                                        Spacer()
                                        Image(systemName: "chevron.down")
                                            .font(.system(size: 12))
                                            .foregroundColor(theme.textSecondary)
                                    }
                                    .padding(.horizontal, theme.cardPadding)
                                    .padding(.vertical, theme.cardVerticalPadding)
                                    .background(transparentInputBackground(theme: theme))
                                    .cornerRadius(theme.smallCornerRadius)
                                }
                            }
                        }
                        
                        // Priority
                        sectionView(title: "PRIORITY", theme: theme) {
                            Menu {
                                ForEach(PriorityType.allCases, id: \.self) { priorityOption in
                                    Button(action: {
                                        priority = priorityOption
                                    }) {
                                        HStack {
                                            Text(priorityOption.rawValue.capitalized)
                                            if priority == priorityOption {
                                                Image(systemName: "checkmark")
                                            }
                                        }
                                    }
                                }
                            } label: {
                                HStack {
                                    Text("Priority: \(priority.rawValue.capitalized)")
                                        .font(theme.bodyFont)
                                        .foregroundColor(theme.textPrimary)
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 12))
                                        .foregroundColor(theme.textSecondary)
                                }
                                .padding(.horizontal, theme.cardPadding)
                                .padding(.vertical, theme.cardVerticalPadding)
                                .background(transparentInputBackground(theme: theme))
                                .cornerRadius(theme.smallCornerRadius)
                            }
                        }
                        
                        // Time
                        sectionView(title: "TIME", theme: theme) {
                            VStack(spacing: 16) {
                                if hasEndTime {
                                    HStack(spacing: 12) {
                                        NumericTimeInput(time: $startTime, title: "Start time")
                                        NumericTimeInput(time: $endTime, title: "End time")
                                    }
                                } else {
                                    NumericTimeInput(time: $startTime, title: "Start time")
                                }
                                
                                Toggle("Has end time", isOn: $hasEndTime)
                                    .foregroundColor(theme.textPrimary)
                                    .tint(theme.accentColor)
                            }
                            .padding(.horizontal, theme.cardPadding)
                            .padding(.vertical, theme.cardVerticalPadding)
                            .background(transparentInputBackground(theme: theme))
                            .cornerRadius(theme.smallCornerRadius)
                        }
                        
                        // Recurrence
                        sectionView(title: "RECURRENCE", theme: theme) {
                            VStack(spacing: 16) {
                                Toggle("Recurring task", isOn: $isRecurring)
                                    .foregroundColor(theme.textPrimary)
                                    .tint(theme.accentColor)
                                
                                if isRecurring {
                                    Picker("Recurrence", selection: $recurrenceType) {
                                        ForEach(RecurrenceType.allCases, id: \.self) { type in
                                            Text(type.rawValue.capitalized).tag(type)
                                        }
                                    }
                                    .tint(theme.accentColor)
                                    
                                    DatePicker("End Date", selection: $recurrenceEndDate, displayedComponents: [.date])
                                        .tint(theme.accentColor)
                                }
                            }
                            .padding(.horizontal, theme.cardPadding)
                            .padding(.vertical, theme.cardVerticalPadding)
                            .background(transparentInputBackground(theme: theme))
                            .cornerRadius(theme.smallCornerRadius)
                        }
                        
                        // Save Button
                        Button(action: saveTask) {
                            Text("Add Task")
                                .font(theme.bodyFont)
                                .fontWeight(.semibold)
                                .foregroundColor(theme.textPrimary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: theme.cardCornerRadius)
                                        .fill(theme.accentColor)
                                )
                        }
                        .disabled(title.isEmpty)
                        .padding(.top, 20)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Add Task to Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(theme.textPrimary)
                    }
                }
            }
        }
        .onAppear {
            selectedMilestone = preselectedMilestone
        }
    }
    
    private func sectionView<Content: View>(title: String, theme: any AppTheme, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(theme.headerFont)
                .foregroundColor(theme.textPrimary.opacity(0.7))
            content()
        }
    }
    
    private func saveTask() {
        guard let user = currentUser else { return }
        
        let finalMilestone = selectedMilestone ?? preselectedMilestone
        
        if isRecurring {
            createRecurringTasks(user: user, milestone: finalMilestone)
        } else {
            createSingleTask(user: user, milestone: finalMilestone)
        }
        
        dismiss()
    }
    
    private func createSingleTask(user: User, milestone: GoalMilestone?) {
        let task = Task(
            userID: user.id,
            title: title,
            taskDescription: taskDescription.isEmpty ? nil : taskDescription,
            startTime: startTime,
            endTime: hasEndTime ? endTime : startTime,
            priority: priority,
            category: category,
            goal: goal,
            milestone: milestone
        )
        
        modelContext.insert(task)
        try? modelContext.save()
    }
    
    private func createRecurringTasks(user: User, milestone: GoalMilestone?) {
        let calendar = Calendar.current
        var currentDate = startTime
        let endDate = recurrenceEndDate
        let seriesID = UUID().uuidString
        
        while currentDate <= endDate {
            if shouldCreateTaskOnDate(currentDate) {
                let task = Task(
                    userID: user.id,
                    title: title,
                    taskDescription: taskDescription.isEmpty ? nil : taskDescription,
                    startTime: currentDate,
                    endTime: hasEndTime ? calendar.date(byAdding: .hour, value: 1, to: currentDate) ?? currentDate : currentDate,
                    priority: priority,
                    category: category,
                    goal: goal,
                    milestone: milestone,
                    recurrenceSeriesID: seriesID
                )
                
                modelContext.insert(task)
            }
            
            // Increment date based on recurrence type
            switch recurrenceType {
            case .daily:
                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? endDate
            case .weekdays:
                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? endDate
                // Skip weekends
                while calendar.isDateInWeekend(currentDate) {
                    currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? endDate
                }
            case .weekly:
                currentDate = calendar.date(byAdding: .weekOfYear, value: 1, to: currentDate) ?? endDate
            case .custom:
                // For custom, just do daily for now
                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? endDate
            }
        }
        
        try? modelContext.save()
    }
    
    private func shouldCreateTaskOnDate(_ date: Date) -> Bool {
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

