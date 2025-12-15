//
//  RoutineManagerView.swift
//  Haven2.0
//
//  Created by AI on 2025-11-10.
//

import SwiftUI
import SwiftData

struct RoutineManagerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(ThemeManager.self) private var themeManager
    @Query private var users: [User]
    
    @State private var showingAddRoutine = false
    @State private var editingRoutine: DailyRoutine?
    @State private var isPresentingEdit = false
    @State private var showingUpgradePrompt = false
    
    @Query private var routines: [DailyRoutine]
    private let userID: String
    
    private var currentUser: User? {
        users.first
    }
    
    private var subscriptionTier: SubscriptionTier {
        // TODO: Get from User model when subscription status is added
        SubscriptionService.shared.getSubscriptionTier(for: userID)
    }
    
    private var canCreateMoreRoutines: Bool {
        let activeCount = activeRoutines.count
        let maxAllowed = SubscriptionService.shared.maxActiveRoutines(tier: subscriptionTier)
        return activeCount < maxAllowed
    }
    
    init(userID: String) {
        self.userID = userID
        let descriptor = FetchDescriptor<DailyRoutine>(
            predicate: #Predicate<DailyRoutine> { routine in
                routine.userID == userID
            },
            sortBy: [
                SortDescriptor(\DailyRoutine.createdAt, order: .reverse)
            ]
        )
        _routines = Query(descriptor)
    }
    
    private var activeRoutines: [DailyRoutine] {
        routines.filter { $0.isActive }
    }
    
    private var archivedRoutines: [DailyRoutine] {
        routines.filter { !$0.isActive }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background using theme gradient
                themeManager.currentTheme.primaryGradient
                    .ignoresSafeArea()
                
                List {
                if activeRoutines.isEmpty {
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("No active routines yet")
                                .font(.headline)
                            Text("Create routine templates to automatically schedule your daily essentials.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 12)
                    }
                } else {
                    Section("Active") {
                        ForEach(activeRoutines) { routine in
                            routineRow(routine, isArchived: false)
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button("Archive") {
                                        archiveRoutine(routine)
                                    }
                                    .tint(.gray)
                                    
                                    Button(role: .destructive) {
                                        deleteRoutine(routine)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                }
                
                if !archivedRoutines.isEmpty {
                    Section("Archived") {
                        ForEach(archivedRoutines) { routine in
                            routineRow(routine, isArchived: true)
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button("Restore") {
                                        restoreRoutine(routine)
                                    }
                                    .tint(.green)
                                    
                                    Button(role: .destructive) {
                                        deleteRoutine(routine)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                }
                }
                .scrollContentBackground(.hidden)
                .listStyle(.insetGrouped)
            }
            .navigationTitle("Routines")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        if canCreateMoreRoutines {
                            showingAddRoutine = true
                        } else {
                            showingUpgradePrompt = true
                        }
                    } label: {
                        Label("New Routine", systemImage: "plus.circle.fill")
                    }
                }
            }
            .sheet(isPresented: $showingAddRoutine) {
                RoutineSetupView()
            }
            .sheet(isPresented: $isPresentingEdit, onDismiss: {
                editingRoutine = nil
            }) {
                if let routine = editingRoutine {
                    RoutineSetupView(routineToEdit: routine)
                }
            }
            .alert("Upgrade Required", isPresented: $showingUpgradePrompt) {
                Button("Maybe Later", role: .cancel) { }
                Button("View Plans") {
                    // TODO: Navigate to paywall/subscription view
                }
            } message: {
                let maxAllowed = SubscriptionService.shared.maxActiveRoutines(tier: subscriptionTier)
                Text("You've reached the limit of \(maxAllowed) active routine\(maxAllowed == 1 ? "" : "s") for free users. Upgrade to Haven+ to create up to 5 active routines.")
            }
        }
    }
    
    @ViewBuilder
    private func routineRow(_ routine: DailyRoutine, isArchived: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // Routine icon to differentiate from tasks
                Image(systemName: "repeat.circle.fill")
                    .font(.title3)
                    .foregroundColor(.blue)
                
                Text(routine.title)
                    .font(.headline)
                
                if routine.isDefault {
                    Label("Default", systemImage: "star.fill")
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.orange.opacity(0.15), in: Capsule())
                        .foregroundColor(.orange)
                }
                
                Spacer()
                
                if !isArchived {
                    Button {
                        editingRoutine = routine
                        isPresentingEdit = true
                    } label: {
                        Image(systemName: "square.and.pencil")
                    }
                    .buttonStyle(.borderless)
                }
            }
            
            // Show tasks within this routine (to differentiate from individual tasks)
            if !routine.taskTemplates.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Tasks in routine:")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                    
                    // Show first 3 tasks, then "and X more" if there are more
                    let displayTasks = Array(routine.taskTemplates.prefix(3))
                    let remainingCount = routine.taskTemplates.count - displayTasks.count
                    
                    ForEach(displayTasks) { template in
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color.blue.opacity(0.3))
                                .frame(width: 4, height: 4)
                            Text(template.title)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if remainingCount > 0 {
                        Text("and \(remainingCount) more")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .italic()
                    }
                }
                .padding(.leading, 24) // Indent to show hierarchy
            }
            
            Text(routineSummary(for: routine))
                .font(.caption)
                .foregroundColor(.secondary)
            
            Toggle("Active", isOn: Binding(
                get: { routine.isActive },
                set: { value in
                    routine.isActive = value
                    routine.updatedAt = Date()
                    if value {
                        // Routine activated - generate tasks
                        RoutineService.shared.generateTasksFromRoutine(routine, in: modelContext)
                    } else {
                        // Routine deactivated - remove tasks from workflow
                        RoutineService.shared.removeTasks(for: routine, in: modelContext)
                    }
                    try? modelContext.save()
                }
            ))
            .disabled(isArchived)
        }
        .padding(.vertical, 6)
    }
    
    private func routineSummary(for routine: DailyRoutine) -> String {
        let templateCount = routine.taskTemplates.count
        let templateText = templateCount == 1 ? "task" : "tasks"
        
        if let endDate = routine.endDate {
            return "\(templateCount) \(templateText) • Ends \(endDate.formatted(date: .abbreviated, time: .omitted))"
        } else {
            return "\(templateCount) \(templateText) • Continuous"
        }
    }
    
    private func archiveRoutine(_ routine: DailyRoutine) {
        routine.isActive = false
        routine.archivedAt = Date()
        routine.updatedAt = Date()
        RoutineService.shared.removeTasks(for: routine, in: modelContext)
        try? modelContext.save()
    }
    
    private func restoreRoutine(_ routine: DailyRoutine) {
        routine.isActive = true
        routine.archivedAt = nil
        routine.startDate = Date()
        routine.updatedAt = Date()
        
        let calendar = Calendar.current
        if routine.durationType == .tillMonthEnd {
            if let monthEnd = calendar.dateInterval(of: .month, for: routine.startDate)?.end {
                routine.endDate = calendar.date(byAdding: .day, value: -1, to: monthEnd)
            }
        } else if let days = routine.durationDays {
            routine.endDate = calendar.date(byAdding: .day, value: days, to: routine.startDate)
        }
        
        RoutineService.shared.generateTasksFromRoutine(routine, in: modelContext)
        try? modelContext.save()
    }
    
    private func deleteRoutine(_ routine: DailyRoutine) {
        RoutineService.shared.removeTasks(for: routine, in: modelContext)
        modelContext.delete(routine)
        try? modelContext.save()
    }
}


