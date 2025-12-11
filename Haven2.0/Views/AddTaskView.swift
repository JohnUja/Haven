//
//  AddTaskView.swift
//  TimeFlow
//
//  Created by John Uja on 2025-10-18.
//

import SwiftUI
import SwiftData
import UIKit

struct AddTaskView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(ThemeManager.self) private var themeManager
    @Environment(FirebaseAuthService.self) private var authService
    @Query private var users: [User]
    @Query private var taskBlocks: [TaskBlock]
    
    let selectedDate: Date
    let taskBlock: TaskBlock?
    let prefillTaskName: String?
    
    @StateObject private var guestModeService = GuestModeService.shared
    @State private var showGuestLoginPrompt = false
    
    init(selectedDate: Date, taskBlock: TaskBlock? = nil, taskBlockID: String? = nil, prefillTaskName: String? = nil) {
        self.selectedDate = selectedDate
        self.taskBlock = taskBlock
        self.prefillTaskName = prefillTaskName
        // Note: taskBlockID parameter kept for backward compatibility but should use taskBlock instead
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
    @State private var showLockScopeDialog = false
    @State private var pendingLockValue = false
    @State private var applyLockToSeries: Bool? = nil
    
    private var currentUser: User? {
        users.first
    }
    
    var body: some View {
        let theme = themeManager.currentTheme
        
        return NavigationView {
            ZStack {
                // Background using theme gradient
                theme.primaryGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Task Details Section
                        sectionView(title: "TASK DETAILS", theme: theme) {
                            VStack(spacing: 16) {
                                // Task Title - Larger and Bold
                                TextField("Task title", text: $title)
                                    .font(.system(size: 20, weight: .bold, design: .default))
                                    .foregroundColor(theme.textPrimary)
                                    .accentColor(theme.accentColor)
                                    .padding(.horizontal, theme.cardPadding)
                                    .padding(.vertical, theme.cardVerticalPadding)
                                    .background(transparentInputBackground(theme: theme))
                                    .cornerRadius(theme.smallCornerRadius)
                                    .placeholder(when: title.isEmpty) {
                                        Text("Task title")
                                            .foregroundColor(theme.textSecondary.opacity(0.8))
                                            .font(.system(size: 20, weight: .bold, design: .default))
                                            .padding(.horizontal, theme.cardPadding)
                                            .padding(.vertical, theme.cardVerticalPadding)
                                    }
                                
                                // Description - TextEditor
                                ZStack(alignment: .topLeading) {
                                    if taskDescription.isEmpty {
                                        Text("Description (optional)")
                                            .foregroundColor(theme.textSecondary.opacity(0.6))
                                            .font(.system(size: 16, weight: .regular, design: .default))
                                            .padding(.horizontal, theme.cardPadding)
                                            .padding(.vertical, theme.cardVerticalPadding)
                                    }
                                    TextEditor(text: $taskDescription)
                                        .font(.system(size: 16, weight: .regular, design: .default))
                                        .foregroundColor(theme.textPrimary)
                                        .accentColor(theme.accentColor)
                                        .scrollContentBackground(.hidden)
                                        .frame(minHeight: 100)
                                        .padding(.horizontal, theme.cardPadding - 4)
                                        .padding(.vertical, theme.cardVerticalPadding - 4)
                                }
                                .background(transparentInputBackground(theme: theme))
                                .cornerRadius(theme.smallCornerRadius)
                                
                                // Priority Pill Selector
                                priorityMenuSelector(theme: theme)
                            }
                        }
                        
                        // Task Type Section
                        sectionView(title: "TASK TYPE", theme: theme) {
                            HStack {
                                Image(systemName: "arrow.up.left.and.arrow.down.right")
                                    .font(.system(size: 16))
                                    .foregroundColor(theme.accentColor)
                            Toggle("Flexible task (no specific time)", isOn: $isFlexibleTask)
                                .foregroundColor(theme.textPrimary)
                                .tint(theme.accentColor)
                            }
                                .padding(.horizontal, theme.cardPadding)
                                .padding(.vertical, theme.cardVerticalPadding)
                                .background(transparentInputBackground(theme: theme))
                                .cornerRadius(theme.smallCornerRadius)
                                .onChange(of: isFlexibleTask) { _, newValue in
                                    if newValue {
                                        hasEndTime = false
                                    }
                                }
                        }
                        
                        // Time Section
                        sectionView(title: "TIME", theme: theme) {
                            if !isFlexibleTask {
                                VStack(spacing: 16) {
                                    // Vertical layout - one above the other
                                    NumericTimeInput(time: $startTime, title: "Start time")
                                        .onChange(of: startTime) { _, newValue in
                                            // Prevent past times for today
                                            if Calendar.current.isDateInToday(newValue) && newValue < Date() {
                                                startTime = Date()
                                            }
                                        }
                                    
                                    if hasEndTime {
                                        NumericTimeInput(time: $endTime, title: "End time")
                                    }
                                    
                                    Toggle("Has end time", isOn: $hasEndTime)
                                        .foregroundColor(theme.textPrimary)
                                        .tint(theme.accentColor)
                                }
                                .padding(.horizontal, theme.cardPadding)
                                .padding(.vertical, theme.cardVerticalPadding)
                                .background(transparentInputBackground(theme: theme))
                                .cornerRadius(theme.smallCornerRadius)
                            } else {
                                Text("This task can be done anytime today")
                                    .font(.system(size: 14, weight: .regular, design: .default))
                                    .foregroundColor(theme.textSecondary)
                                    .italic()
                                    .padding(.horizontal, theme.cardPadding)
                                    .padding(.vertical, theme.cardVerticalPadding)
                                    .background(transparentInputBackground(theme: theme))
                                    .cornerRadius(theme.smallCornerRadius)
                            }
                        }
                        
                        // Category Section
                        sectionView(title: "CATEGORY", theme: theme) {
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                                ForEach(TaskCategory.allCases, id: \.self) { cat in
                                    Button(action: { category = cat }) {
                                        HStack(spacing: 8) {
                                            Image(systemName: cat.icon)
                                                .font(.title3)
                                                .foregroundColor(category == cat ? cat.color() : cat.color().opacity(0.7))
                                                .frame(width: 24, height: 24)
                                            
                                            Text(cat.displayName)
                                                .font(.system(size: 16, weight: category == cat ? .bold : .regular, design: .default))
                                                .foregroundColor(theme.textPrimary)
                                            
                                            Spacer()
                                            
                                            if category == cat {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .font(.caption)
                                                    .foregroundColor(theme.accentColor)
                                            }
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(
                                            RoundedRectangle(cornerRadius: theme.smallCornerRadius)
                                                .fill(theme.glassBackground.opacity(0.3))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: theme.smallCornerRadius)
                                                        .stroke(category == cat ? theme.accentColor : theme.glassBorder.opacity(0.5), lineWidth: category == cat ? 2 : 1)
                                                )
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal, theme.cardPadding)
                            .padding(.vertical, theme.cardVerticalPadding)
                            .background(transparentInputBackground(theme: theme))
                            .cornerRadius(theme.smallCornerRadius)
                        }
                        
                        // Recurrence Section
                        sectionView(title: "RECURRENCE", theme: theme) {
                            VStack(spacing: 16) {
                                Toggle("Make this a recurring task", isOn: $isRecurring)
                                    .foregroundColor(theme.textPrimary)
                                    .tint(theme.accentColor)
                                
                                if isRecurring {
                                    Picker("Repeat", selection: $recurrenceType) {
                                        ForEach(RecurrenceType.allCases, id: \.self) { type in
                                            Text(type.displayName).tag(type)
                                        }
                                    }
                                    .pickerStyle(.segmented)
                                    .tint(theme.accentColor)
                                    
                                    DatePicker("End date", selection: $recurrenceEndDate, displayedComponents: [.date])
                                        .datePickerStyle(.compact)
                                        .tint(theme.accentColor)
                                }
                            }
                            .padding(.horizontal, theme.cardPadding)
                            .padding(.vertical, theme.cardVerticalPadding)
                            .background(transparentInputBackground(theme: theme))
                            .cornerRadius(theme.smallCornerRadius)
                        }
                        
                        // Settings Section
                        sectionView(title: "SETTINGS", theme: theme) {
                            HStack {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(theme.accentColor)
                            Toggle("Lock task", isOn: Binding(
                                get: { isLocked },
                                set: { newValue in
                                    if isRecurring {
                                        pendingLockValue = newValue
                                        showLockScopeDialog = true
                                    } else {
                                        isLocked = newValue
                                    }
                                }
                            ))
                            .foregroundColor(theme.textPrimary)
                            .tint(theme.accentColor)
                            }
                            .padding(.horizontal, theme.cardPadding)
                            .padding(.vertical, theme.cardVerticalPadding)
                            .background(transparentInputBackground(theme: theme))
                            .cornerRadius(theme.smallCornerRadius)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("Add Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(theme.textPrimary)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveTask()
                    }
                    .disabled(title.isEmpty)
                    .foregroundColor(title.isEmpty ? theme.textSecondary : theme.accentColor)
                }
            }
            .toolbarBackground(theme.glassBackground.opacity(0.5), for: .navigationBar)
        }
        .onAppear {
            setupInitialTimes()
            if let prefill = prefillTaskName, title.isEmpty {
                title = prefill
            }
        }
        .fullScreenCover(isPresented: $showGuestLoginPrompt) {
            GuestLoginPromptView(isPresented: $showGuestLoginPrompt) {
                // On dismiss, user can continue but with limited access
            }
        }
        .confirmationDialog(
            isLocked ? "Unlock Scope" : "Lock Scope",
            isPresented: $showLockScopeDialog,
            titleVisibility: .visible
        ) {
            if pendingLockValue { // locking
                Button("Lock only this task") {
                    isLocked = true
                    applyLockToSeries = false
                }
                Button("Lock all in series") {
                    isLocked = true
                    applyLockToSeries = true
                }
            } else { // unlocking
                Button("Unlock only this task") {
                    isLocked = false
                    applyLockToSeries = false
                }
                Button("Unlock all in series") {
                    isLocked = false
                    applyLockToSeries = true
                }
            }
            Button("Cancel", role: .cancel) {
                // revert the toggle
                pendingLockValue = isLocked
            }
        }
    }
    
    // MARK: - Priority Menu Selector (REVERTED from pills to original Menu)
    @ViewBuilder
    private func priorityMenuSelector(theme: any AppTheme) -> some View {
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
    
    private func priorityColor(for priority: PriorityType) -> Color {
        switch priority {
        case .urgent: return .red
        case .high: return .orange
        case .normal: return .blue
        case .low: return .green
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
        
        // Check guest mode limits
        if authService.isGuest {
            if !guestModeService.canCreateTask() {
                // Show login prompt
                showGuestLoginPrompt = true
                return
            }
            
            // Increment task count for guest
            guestModeService.incrementTaskCount()
        }
        
        if isRecurring {
            createRecurringTasks(user: user)
        } else {
            createSingleTask(user: user)
        }
        
        do {
            try modelContext.save()
            
            // Remember the date if task was created on a future date
            let calendar = Calendar.current
            let taskDate = isFlexibleTask ? selectedDate : startTime
            let today = Date()
            
            if calendar.dateComponents([.day], from: today, to: taskDate).day ?? 0 > 0 {
                // Task created on a future date - remember it
                DatePersistenceService.shared.saveLastWorkedDate(taskDate)
                DatePersistenceService.shared.saveSelectedDate(taskDate)
            }
            
            // Post notification that task was created (for onboarding flow)
            NotificationCenter.default.post(name: NSNotification.Name("OnboardingTaskCreated"), object: nil)
            
            // Ensure dismiss happens on main thread
            DispatchQueue.main.async {
                dismiss()
            }
            
            // If guest just created their first task, show prompt after saving
            if authService.isGuest && guestModeService.taskCount == 1 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showGuestLoginPrompt = true
                }
            }
        } catch {
            print("Error saving task: \(error)")
            // Show error to user
            DispatchQueue.main.async {
                // TODO: Show error alert
            }
        }
    }
    
    private func createSingleTask(user: User) {
        // Resolve taskBlock from ID if needed (backward compatibility)
        let resolvedTaskBlock: TaskBlock? = {
            if let taskBlock = taskBlock {
                return taskBlock
            }
            // Legacy support: if taskBlockID was provided, find it
            return nil
        }()
        
        let task = Task(
            userID: user.id,
            title: title,
            taskDescription: taskDescription.isEmpty ? nil : taskDescription,
            startTime: isFlexibleTask ? selectedDate : startTime,
            endTime: isFlexibleTask ? selectedDate : (hasEndTime ? endTime : startTime),
            priority: priority,
            category: category,
            taskBlock: resolvedTaskBlock
        )
        
        task.isLocked = isLocked
        modelContext.insert(task)
    }
    
    private func createRecurringTasks(user: User) {
        let calendar = Calendar.current
        var currentDate = startTime
        let endDate = recurrenceEndDate
        let seriesID = UUID().uuidString
        
        // Resolve taskBlock from ID if needed (backward compatibility)
        let resolvedTaskBlock: TaskBlock? = {
            if let taskBlock = taskBlock {
                return taskBlock
            }
            return nil
        }()
        
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
                    taskBlock: resolvedTaskBlock,
                    recurrenceSeriesID: seriesID
                )
                
                if let applyToSeries = applyLockToSeries {
                    if applyToSeries {
                        task.isLocked = pendingLockValue
                    } else {
                        task.isLocked = (currentDate == startTime) ? pendingLockValue : false
                    }
                } else {
                    task.isLocked = isLocked
                }
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
    
    // MARK: - Helper Views
    private func sectionView<Content: View>(title: String, theme: any AppTheme, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 12, weight: .semibold, design: .default))
                .foregroundColor(theme.textPrimary.opacity(0.5)) // Lighter grey for better visibility
                // Removed .textCase(.uppercase)
            
            content()
        }
    }
    
}

#Preview {
    AddTaskView(selectedDate: Date())
        .modelContainer(for: [User.self, Task.self], inMemory: true)
}
