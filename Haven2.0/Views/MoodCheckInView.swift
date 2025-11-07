//
//  MoodCheckInView.swift
//  TimeFlow
//
//  Created by AI on 2025-10-30.
//

import SwiftUI

struct MoodCheckInView: View {
    let onMoodSelected: (MoodType) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var selectedMood: MoodType? = nil
    @State private var notes: String = ""
    @State private var currentPeriod: CheckInTime? = MoodJarService.currentCheckInPeriod()
    
    private var canCheckIn: Bool {
        MoodJarService.canCheckIn().allowed || currentPeriod != nil
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Current Period Indicator
                Section {
                    if let period = currentPeriod {
                        HStack {
                            Image(systemName: "clock.fill")
                                .foregroundColor(.blue)
                            Text("\(period.displayName) Check-in")
                                .font(.headline)
                            Spacer()
                        }
                    } else {
                        HStack {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundColor(.orange)
                            Text("Outside Check-in Window")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        
                        Text("You can still check in (minimum 1 per day)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Mood Selection
                Section("How are you feeling?") {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        ForEach(MoodType.allCases, id: \.self) { mood in
                            Button(action: {
                                selectedMood = mood
                            }) {
                                VStack(spacing: 12) {
                                    Text(mood.emoji)
                                        .font(.system(size: 50))
                                    
                                    Text(mood.displayName)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.primary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 20)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(
                                            selectedMood == mood
                                            ? mood.isPositive ? Color.green.opacity(0.2) : Color.blue.opacity(0.2)
                                            : Color.gray.opacity(0.1)
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(
                                                    selectedMood == mood
                                                    ? (mood.isPositive ? Color.green : Color.blue)
                                                    : Color.clear,
                                                    lineWidth: 2
                                                )
                                        )
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                // Optional Notes
                Section("Notes (Optional)") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.2))
                        )
                }
            }
            .navigationTitle("Mood Check-in")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        if let mood = selectedMood {
                            onMoodSelected(mood)
                            dismiss()
                        }
                    }
                    .disabled(selectedMood == nil)
                }
            }
        }
    }
}

#Preview {
    MoodCheckInView(onMoodSelected: { _ in })
}

