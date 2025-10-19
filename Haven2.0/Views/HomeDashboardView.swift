//
//  HomeDashboardView.swift
//  TimeFlow
//
//  Created by John Uja on 2025-10-18.
//

import SwiftUI
import SwiftData

struct HomeDashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(ThemeManager.self) private var themeManager
    @Query private var users: [User]
    @Query private var tasks: [Task]
    @State private var selectedDate = Date()
    @State private var showingAddTask = false
    @State private var showingCalendar = false
    @State private var currentTime = Date()
    @State private var showingAddBlock = false
    @State private var taskSortOrder: TaskSortOrder = .priority
    
    private var currentUser: User? {
        users.first
    }
    
    private var selectedDateTasks: [Task] {
        let filteredTasks = tasks.filter { task in
            Calendar.current.isDate(task.startTime, inSameDayAs: selectedDate)
        }
        
        switch taskSortOrder {
        case .priority:
            return filteredTasks.sorted { task1, task2 in
                let priorityOrder: [PriorityType] = [.urgent, .high, .normal]
                let task1Index = priorityOrder.firstIndex(of: task1.priority) ?? 2
                let task2Index = priorityOrder.firstIndex(of: task2.priority) ?? 2
                return task1Index < task2Index
            }
        case .mostRecent:
            return filteredTasks.sorted { $0.startTime > $1.startTime }
        case .timeSensitive:
            return filteredTasks.sorted { task1, task2 in
                let now = Date()
                let task1TimeUntil = task1.startTime.timeIntervalSince(now)
                let task2TimeUntil = task2.startTime.timeIntervalSince(now)
                return abs(task1TimeUntil) < abs(task2TimeUntil)
            }
        }
    }
    
    enum TaskSortOrder: String, CaseIterable {
        case priority = "Priority"
        case mostRecent = "Most Recent"
        case timeSensitive = "Time Sensitive"
    }
    
    var body: some View {
        let theme = themeManager.currentTheme
        
        NavigationView {
            ZStack {
                // Dynamic background
                theme.backgroundGradient
                    .ignoresSafeArea()
                
                // Cosmic particles
                CosmicParticlesView(theme: theme)
                
                VStack(spacing: 0) {
                    // Top Navigation Bar
                    topNavigationView(theme: theme)
                        .padding(.top, 10)
                    
                    // Completed Tasks Count
                    completedTasksCountView(theme: theme)
                        .padding(.top, 16)
                    
                    // Central Time Display with Portal
                    centralTimeView(theme: theme)
                        .padding(.top, 20)
                    
                    // Day Navigation Circles
                    dayNavigationView(theme: theme)
                        .padding(.top, 30)
                    
                    // Current Activity
                    currentActivityView(theme: theme)
                        .padding(.top, 20)
                    
                    // Task Ordering
                    taskOrderingView(theme: theme)
                        .padding(.top, 16)
                    
                    // Tasks Section
                    tasksSectionView(theme: theme)
                        .padding(.top, 20)
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingAddTask) {
            AddTaskView(selectedDate: selectedDate)
        }
        .sheet(isPresented: $showingCalendar) {
            calendarModalView(theme: theme)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingAddBlock) {
            AddBlockView(selectedDate: selectedDate)
                .presentationDetents([.medium])
        }
        .onAppear {
            startTimeTimer()
        }
    }
    
    // MARK: - Top Navigation Bar
    private func topNavigationView(theme: any AppTheme) -> some View {
        HStack {
            // Calendar Dropdown (Top Left)
            Button(action: { showingCalendar = true }) {
                HStack(spacing: 4) {
                    Text(selectedDate, format: .dateTime.month(.abbreviated).day())
                        .font(theme.bodyFont)
                        .foregroundColor(theme.textPrimary)
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundColor(theme.textSecondary)
                }
            }
            
            Spacer()
            
            // Add Task/Block Buttons (Top Right)
            HStack(spacing: 12) {
                Button(action: { showingAddTask = true }) {
                    Image(systemName: "plus.square.fill")
                        .font(.title3)
                        .foregroundColor(theme.accentColor)
                }
                
                Button(action: { showingAddBlock = true }) {
                    Image(systemName: "square.stack.3d.up.fill")
                        .font(.title3)
                        .foregroundColor(theme.secondaryColor)
                }
                
                Button(action: {}) {
                    Image(systemName: "person.circle.fill")
                        .font(.title3)
                        .foregroundColor(theme.textSecondary)
                }
            }
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Completed Tasks Count
    private func completedTasksCountView(theme: any AppTheme) -> some View {
        let completedCount = selectedDateTasks.filter { $0.isComplete }.count
        let totalCount = selectedDateTasks.count
        
        return HStack {
            Text("\(completedCount)/\(totalCount) tasks completed")
                .font(theme.bodyFont)
                .foregroundColor(theme.textSecondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(theme.cardBackground.opacity(0.8))
                )
            
            Spacer()
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Central Time Display
    private func centralTimeView(theme: any AppTheme) -> some View {
        ZStack {
            // Magical portal/time ring background
            CosmicPortalView()
                .frame(width: 200, height: 200)
                .opacity(0.8)
            
            VStack(spacing: 12) {
                Text(currentTime, format: .dateTime.hour().minute())
                    .font(.custom("Georgia-Bold", size: 56))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 1, y: 1)
            }
        }
    }
    
    // MARK: - Day Navigation
    private func dayNavigationView(theme: any AppTheme) -> some View {
        HStack(spacing: 0) {
            ForEach(-2...2, id: \.self) { offset in
                let date = Calendar.current.date(byAdding: .day, value: offset, to: selectedDate) ?? Date()
                let dayNumber = Calendar.current.component(.day, from: date)
                let isSelected = Calendar.current.isDate(date, inSameDayAs: selectedDate)
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        selectedDate = date
                    }
                }) {
                    VStack(spacing: 4) {
                        Text(dayNumber, format: .number)
                            .font(.custom("Montserrat", size: 16).weight(.medium))
                            .foregroundColor(isSelected ? .white : theme.textPrimary)
                            .frame(width: 40, height: 40)
                            .background(
                                Circle()
                                    .fill(isSelected ? theme.primaryColor : theme.cardBackground)
                                    .shadow(color: theme.primaryColor.opacity(0.3), radius: isSelected ? 8 : 4)
                            )
                        
                        Text(date.formatted(.dateTime.weekday(.abbreviated)))
                            .font(.caption)
                            .foregroundColor(theme.textSecondary)
                    }
                }
                .frame(width: 50)
            }
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Current Activity
    private func currentActivityView(theme: any AppTheme) -> some View {
        Group {
            if let currentTask = getCurrentTask() {
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 8, height: 8)
                        .opacity(0.8)
                    
                    Text("Working on: \(currentTask.title)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(theme.textPrimary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(theme.cardBackground.opacity(0.8))
                )
            }
        }
    }
    
    // MARK: - Task Ordering
    private func taskOrderingView(theme: any AppTheme) -> some View {
        HStack {
            Text("Tasks")
                .font(theme.titleFont)
                .foregroundColor(theme.textPrimary)
            
            Spacer()
            
            Menu {
                ForEach(TaskSortOrder.allCases, id: \.self) { order in
                    Button(order.rawValue) {
                        taskSortOrder = order
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text("Order by: \(taskSortOrder.rawValue)")
                        .font(theme.bodyFont)
                        .foregroundColor(theme.textSecondary)
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundColor(theme.textSecondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(theme.cardBackground.opacity(0.8))
                )
            }
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Tasks Section
    private func tasksSectionView(theme: any AppTheme) -> some View {
        VStack(spacing: 0) {
            // Dividing line
            Rectangle()
                .fill(theme.textSecondary.opacity(0.3))
                .frame(height: 1)
                .padding(.horizontal, 20)
            
            if selectedDateTasks.isEmpty {
                emptyTasksView(theme: theme)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(selectedDateTasks, id: \.id) { task in
                            TaskCardView(task: task, theme: theme)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }
            }
        }
    }
    
    // MARK: - Empty Tasks View
    private func emptyTasksView(theme: any AppTheme) -> some View {
        VStack(spacing: 20) {
            VStack(spacing: 16) {
                Image(systemName: "star.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(theme.accentColor)
                
                Text("Ready to make today amazing?")
                    .font(theme.titleFont)
                    .foregroundColor(theme.textPrimary)
                
                Text("Add your first task to get started!")
                    .font(theme.bodyFont)
                    .foregroundColor(theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            .padding(.vertical, 40)
        }
    }
    
    // MARK: - Calendar Modal View
    private func calendarModalView(theme: any AppTheme) -> some View {
        NavigationView {
            MonthCalendarView(selectedDate: $selectedDate)
                .navigationTitle("Select Date")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            showingCalendar = false
                        }
                    }
                }
        }
    }
    
    // MARK: - Helper Functions
    private func getCurrentTask() -> Task? {
        let now = Date()
        return selectedDateTasks.first { task in
            now >= task.startTime && now <= task.endTime && !task.isComplete
        }
    }
    
    private func startTimeTimer() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            currentTime = Date()
        }
    }
}

// MARK: - Task Card View
struct TaskCardView: View {
    let task: Task
    let theme: any AppTheme
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        HStack(spacing: 12) {
            // Category icon
            Image(systemName: task.category.icon)
                .font(.title3)
                .foregroundColor(task.category.color())
                .frame(width: 24, height: 24)
            
            // Task content
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(theme.bodyFont)
                    .foregroundColor(theme.textPrimary)
                    .strikethrough(task.isComplete)
                    .opacity(task.isComplete ? 0.6 : 1.0)
                
                if let description = task.taskDescription {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(theme.textSecondary)
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            // Completion button
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    task.isComplete.toggle()
                    task.completionAnimation = true
                }
            }) {
                Image(systemName: task.isComplete ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(task.isComplete ? .green : theme.textSecondary)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: theme.cardCornerRadius)
                .fill(theme.cardBackground)
                .shadow(color: theme.primaryColor.opacity(0.1), radius: theme.shadowRadius)
        )
        .opacity(task.isComplete ? 0.7 : 1.0)
        .animation(.easeInOut(duration: 0.3), value: task.isComplete)
    }
}

// MARK: - Cosmic Particles View
struct CosmicParticlesView: View {
    let theme: any AppTheme
    @State private var animationOffset: CGFloat = 0
    
    var body: some View {
        ZStack {
            ForEach(0..<20, id: \.self) { index in
                Circle()
                    .fill(theme.particleColors[index % theme.particleColors.count])
                    .frame(width: CGFloat.random(in: 2...6))
                    .position(
                        x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                        y: CGFloat.random(in: 0...UIScreen.main.bounds.height) + animationOffset
                    )
                    .opacity(0.6)
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                animationOffset = -UIScreen.main.bounds.height
            }
        }
    }
}

#Preview {
    HomeDashboardView()
        .environment(ThemeManager())
        .modelContainer(for: [User.self, Task.self, TaskBlock.self, Goal.self, Theme.self])
}