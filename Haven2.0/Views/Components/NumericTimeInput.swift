//
//  NumericTimeInput.swift
//  TimeFlow
//
//  Created by John Uja on 2025-10-20.
//

import SwiftUI

struct NumericTimeInput: View {
    @Binding var time: Date
    let title: String
    let isEnabled: Bool
    
    @State private var hourText = ""
    @State private var minuteText = ""
    @State private var isAM = true
    @FocusState private var isFocused: Bool
    
    init(time: Binding<Date>, title: String, isEnabled: Bool = true) {
        self._time = time
        self.title = title
        self.isEnabled = isEnabled
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            HStack(spacing: 12) {
                // Time input field
                HStack(spacing: 4) {
                    TextField("12", text: $hourText)
                        .keyboardType(.numberPad)
                        .focused($isFocused)
                        .multilineTextAlignment(.center)
                        .frame(width: 40)
                        .onChange(of: hourText) { _, newValue in
                            updateTime()
                        }
                    
                    Text(":")
                        .font(.title2)
                        .fontWeight(.medium)
                    
                    TextField("00", text: $minuteText)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.center)
                        .frame(width: 40)
                        .onChange(of: minuteText) { _, newValue in
                            updateTime()
                        }
                }
                .font(.title3)
                .fontWeight(.medium)
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(isFocused ? Color.blue : Color.clear, lineWidth: 0.5)
                        )
                )
                .disabled(!isEnabled)
                
                // AM/PM toggle
                Picker("AM/PM", selection: $isAM) {
                    Text("AM").tag(true)
                    Text("PM").tag(false)
                }
                .pickerStyle(.segmented)
                .frame(width: 80)
                .padding(.vertical, 4)
                .onChange(of: isAM) { _, _ in
                    updateTime()
                }
                .disabled(!isEnabled)
            }
        }
        .onAppear {
            updateDisplayFromTime()
        }
        .onChange(of: time) { _, _ in
            updateDisplayFromTime()
        }
    }
    
    private func updateTime() {
        guard let hour = Int(hourText), let minute = Int(minuteText) else { return }
        
        // Validate hour (1-12)
        let validHour = max(1, min(12, hour))
        let validMinute = max(0, min(59, minute))
        
        // Convert to 24-hour format
        var hour24 = validHour
        if !isAM && validHour != 12 {
            hour24 = validHour + 12
        } else if isAM && validHour == 12 {
            hour24 = 0
        }
        
        // Create new date with the time
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: time)
        if let newDate = calendar.date(bySettingHour: hour24, minute: validMinute, second: 0, of: time) {
            time = newDate
        }
    }
    
    private func updateDisplayFromTime() {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: time)
        let minute = calendar.component(.minute, from: time)
        
        // Convert to 12-hour format
        var hour12 = hour
        if hour == 0 {
            hour12 = 12
        } else if hour > 12 {
            hour12 = hour - 12
        }
        
        hourText = String(hour12)
        minuteText = String(format: "%02d", minute)
        isAM = hour < 12
    }
}

#Preview {
    VStack {
        NumericTimeInput(time: .constant(Date()), title: "Start Time")
        NumericTimeInput(time: .constant(Date().addingTimeInterval(3600)), title: "End Time")
    }
    .padding()
}
