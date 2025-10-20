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
    @State private var subtasks = ["Task 1", "Task 2", "Task 3"]
    
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
        
        // Create the task block
        let taskBlock = TaskBlock(
            userID: user.id,
            title: blockTitle,
            blockDescription: blockDescription.isEmpty ? nil : blockDescription,
            color: selectedColor
        )
        
        modelContext.insert(taskBlock)
        
        // Create the subtasks
        for (index, subtaskTitle) in subtasks.enumerated() {
            if !subtaskTitle.isEmpty {
                let task = Task(
                    userID: user.id,
                    title: subtaskTitle,
                    taskDescription: nil,
                    startTime: selectedDate,
                    endTime: selectedDate.addingTimeInterval(3600), // 1 hour later
                    priority: .normal,
                    category: .personal,
                    isComplete: false,
                    taskBlockID: taskBlock.id
                )
                modelContext.insert(task)
            }
        }
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Error saving block: \(error)")
        }
    }
}

#Preview {
    AddBlockView(selectedDate: Date())
}
