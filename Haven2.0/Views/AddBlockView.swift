//
//  AddBlockView.swift
//  TimeFlow
//
//  Created by John Uja on 2025-10-19.
//

import SwiftUI
import SwiftData

struct AddBlockView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var users: [User]
    
    let selectedDate: Date
    
    @State private var blockTitle = ""
    @State private var blockDescription = ""
    @State private var selectedColor = "blue"
    @State private var selectedPriority: PriorityType = .normal
    @State private var isLocked = false
    @State private var isRecurring = false
    @State private var subtasks = ["Task 1", "Task 2", "Task 3"]
    @State private var startTime = Date()
    @State private var endTime = Date().addingTimeInterval(3600) // 1 hour later
    @State private var recurrenceType: RecurrenceType = .daily
    @State private var recurrenceEndDate = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
    @State private var showLockScopeDialog = false
    @State private var pendingLockValue = false
    @State private var applyLockToSeries: Bool? = nil
    
    private let availableColors = ["red", "orange", "yellow", "green", "blue", "purple", "pink", "mint", "cyan", "indigo", "brown"]
    
    private var currentUser: User? {
        users.first
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Block Details") {
                    TextField("Block name (e.g., Go to Work)", text: $blockTitle)
                    
                    TextField("Description (optional)", text: $blockDescription, axis: .vertical)
                        .lineLimit(2...4)
                }
                
                Section("Time") {
                    NumericTimeInput(time: $startTime, title: "Start time")
                    NumericTimeInput(time: $endTime, title: "End time")
                }
                
                Section("Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                        ForEach(availableColors, id: \.self) { color in
                            Button(action: { selectedColor = color }) {
                                Circle()
                                    .fill(colorFromString(color))
                                    .frame(width: 30, height: 30)
                                    .overlay(
                                        Circle()
                                            .stroke(selectedColor == color ? .white : .clear, lineWidth: 3)
                                    )
                                    .overlay(
                                        Circle()
                                            .stroke(.gray, lineWidth: 1)
                                    )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                
                Section("Priority & Settings") {
                    Picker("Priority", selection: $selectedPriority) {
                        ForEach(PriorityType.allCases, id: \.self) { p in
                            Text(p.rawValue.capitalized).tag(p)
                        }
                    }
                    Toggle("Lock block", isOn: Binding(
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
                }

                Section("Recurrence") {
                    Toggle("Make this a recurring block", isOn: $isRecurring)
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
                
                Section("Subtasks") {
                    ForEach(0..<subtasks.count, id: \.self) { index in
                        HStack {
                            TextField("Subtask \(index + 1)", text: $subtasks[index])
                            
                            Button(action: {
                                removeSubtask(at: index)
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .font(.title3)
                                    .foregroundColor(.red)
                            }
                            .disabled(subtasks.count <= 1)
                        }
                    }
                    
                    Button(action: {
                        addSubtask()
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                                .foregroundColor(.green)
                            Text("Add Subtask")
                                .foregroundColor(.green)
                        }
                    }
                }
            }
            .navigationTitle("Add Block")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveBlock()
                    }
                    .disabled(blockTitle.isEmpty)
                }
            }
        }
        .confirmationDialog(
            isLocked ? "Unlock Scope" : "Lock Scope",
            isPresented: $showLockScopeDialog,
            titleVisibility: .visible
        ) {
            if pendingLockValue { // locking
                Button("Lock only this block") {
                    isLocked = true
                    applyLockToSeries = false
                }
                Button("Lock all in series") {
                    isLocked = true
                    applyLockToSeries = true
                }
            } else { // unlocking
                Button("Unlock only this block") {
                    isLocked = false
                    applyLockToSeries = false
                }
                Button("Unlock all in series") {
                    isLocked = false
                    applyLockToSeries = true
                }
            }
            Button("Cancel", role: .cancel) {
                pendingLockValue = isLocked
            }
        }
    }
    
    private func addSubtask() {
        subtasks.append("New Task")
    }
    
    private func removeSubtask(at index: Int) {
        guard subtasks.count > 1 else { return }
        subtasks.remove(at: index)
    }
    
    private func colorFromString(_ colorString: String) -> Color {
        switch colorString {
        case "red": return .red
        case "orange": return .orange
        case "yellow": return .yellow
        case "green": return .green
        case "blue": return .blue
        case "purple": return .purple
        case "pink": return .pink
        case "mint": return .mint
        case "cyan": return .cyan
        case "indigo": return .indigo
        case "brown": return .brown
        default: return .blue
        }
    }
    
    private func saveBlock() {
        guard let user = currentUser else { return }
        if isRecurring {
            createRecurringBlocks(user: user)
        } else {
            createSingleBlock(user: user)
        }
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Error saving block: \(error)")
        }
    }

    private func createSingleBlock(user: User) {
        let taskBlock = TaskBlock(
            userID: user.id,
            title: blockTitle,
            blockDescription: blockDescription.isEmpty ? nil : blockDescription,
            color: selectedColor,
            priority: selectedPriority
        )
        taskBlock.isLocked = isLocked
        taskBlock.isRecurring = false
        modelContext.insert(taskBlock)
        createSubtasks(for: taskBlock, user: user, start: startTime, end: endTime)
    }

    private func createRecurringBlocks(user: User) {
        let seriesID = UUID().uuidString
        var occurrenceStart = startTime
        while occurrenceStart <= recurrenceEndDate {
            if shouldCreateBlockForDate(occurrenceStart) {
                let calendar = Calendar.current
                let endComponents = calendar.dateComponents([.hour, .minute], from: endTime)
                let occurrenceEnd = calendar.date(bySettingHour: endComponents.hour ?? 0, minute: endComponents.minute ?? 0, second: 0, of: occurrenceStart) ?? occurrenceStart.addingTimeInterval(3600)

                let block = TaskBlock(
                    userID: (currentUser?.id ?? ""),
                    title: blockTitle,
                    blockDescription: blockDescription.isEmpty ? nil : blockDescription,
                    color: selectedColor,
                    priority: selectedPriority
                )
                if let applyToSeries = applyLockToSeries {
                    block.isLocked = applyToSeries ? pendingLockValue : pendingLockValue // block itself reflects selection
                } else {
                    block.isLocked = isLocked
                }
                block.isRecurring = true
                block.recurrenceSeriesID = seriesID
                modelContext.insert(block)
                createSubtasks(for: block, user: user, start: occurrenceStart, end: occurrenceEnd)
            }

            switch recurrenceType {
            case .daily:
                occurrenceStart = Calendar.current.date(byAdding: .day, value: 1, to: occurrenceStart) ?? occurrenceStart
            case .weekdays:
                occurrenceStart = Calendar.current.date(byAdding: .day, value: 1, to: occurrenceStart) ?? occurrenceStart
                while Calendar.current.isDateInWeekend(occurrenceStart) {
                    occurrenceStart = Calendar.current.date(byAdding: .day, value: 1, to: occurrenceStart) ?? occurrenceStart
                }
            case .weekly:
                occurrenceStart = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: occurrenceStart) ?? occurrenceStart
            case .custom:
                occurrenceStart = Calendar.current.date(byAdding: .day, value: 1, to: occurrenceStart) ?? occurrenceStart
            }
        }
    }

    private func shouldCreateBlockForDate(_ date: Date) -> Bool {
        switch recurrenceType {
        case .daily: return true
        case .weekdays: return !Calendar.current.isDateInWeekend(date)
        case .weekly:
            return Calendar.current.component(.weekday, from: date) == Calendar.current.component(.weekday, from: startTime)
        case .custom: return true
        }
    }

    private func createSubtasks(for block: TaskBlock, user: User, start: Date, end: Date) {
        let count = max(subtasks.count, 1)
        let slice = end.timeIntervalSince(start) / Double(count)
        for (idx, title) in subtasks.enumerated() where !title.isEmpty {
            let s = start.addingTimeInterval(slice * Double(idx))
            let e = s.addingTimeInterval(slice)
            let t = Task(
                userID: user.id,
                title: title,
                taskDescription: nil,
                startTime: s,
                endTime: e,
                priority: selectedPriority,
                category: .personal,
                isComplete: false,
                taskBlockID: block.id,
                recurrenceSeriesID: block.recurrenceSeriesID
            )
            if let applyToSeries = applyLockToSeries {
                if applyToSeries {
                    t.isLocked = pendingLockValue
                } else {
                    // only first subtask (start of block) follows the user's toggle
                    t.isLocked = (idx == 0) ? pendingLockValue : false
                }
            } else {
                t.isLocked = isLocked
            }
            modelContext.insert(t)
        }
    }
}

#Preview {
    AddBlockView(selectedDate: Date())
}