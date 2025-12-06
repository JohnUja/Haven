//
//  InteractiveDateHeader.swift
//  Haven2.0
//
//  Created by AI on 2025-01-XX.
//  Clickable date header with day picker
//

import SwiftUI
import SwiftData

struct InteractiveDateHeader: View {
    @Binding var selectedDate: Date
    @State private var showingDayPicker = false
    let user: User?
    @Environment(ThemeManager.self) private var themeManager
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter
    }
    
    private var dayNameFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Day Scroller (shown above date container when clicked)
            if showingDayPicker {
                InfiniteDaySelector(
                    selectedDate: $selectedDate,
                    onDateChanged: { date in
                        selectedDate = date
                        DatePersistenceService.shared.saveSelectedDate(date)
                    },
                    hasEvents: { _ in false },
                    showMonthHeader: true
                )
                .frame(height: 120)
                .padding(.horizontal, 20)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
            
            // Date Container
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    showingDayPicker.toggle()
                }
            }) {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(dateFormatter.string(from: selectedDate))
                            .font(.system(size: 22, weight: .bold, design: .rounded)) // Smaller but bolder
                            .foregroundColor(.white)
                        
                        if Calendar.current.isDateInToday(selectedDate) {
                            Text("Today")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.8))
                        } else {
                            Text(dayNameFormatter.string(from: selectedDate))
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    
                    Spacer()
                    
                    // Momentum Ring & Level (replaces time crystals)
                    if let user = user {
                        HStack(spacing: 12) {
                            // Compact Momentum Ring
                            compactMomentumRing(user: user)
                            
                            // User Level
                            VStack(spacing: 2) {
                                Text("Level")
                                    .font(.system(size: 10, weight: .medium, design: .rounded))
                                    .foregroundColor(.white.opacity(0.7))
                                Text("\(user.level)")
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    // MARK: - Compact Momentum Ring
    private func compactMomentumRing(user: User) -> some View {
        let momentumProgress = Double(user.momentumDays % 7) / 7.0
        
        return ZStack {
            // Background ring
            Circle()
                .stroke(Color.white.opacity(0.2), lineWidth: 4)
                .frame(width: 50, height: 50)
            
            // Progress ring
            Circle()
                .trim(from: 0, to: momentumProgress)
                .stroke(
                    LinearGradient(
                        colors: [.orange, .red],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .frame(width: 50, height: 50)
                .rotationEffect(.degrees(-90))
            
            // Center content
            VStack(spacing: 0) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.orange)
                Text("\(user.momentumDays)")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
        }
        .frame(width: 50, height: 50)
    }
}

struct DayPickerSheet: View {
    @Binding var selectedDate: Date
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(
                    colors: [
                        Color.purple.opacity(0.8),
                        Color.blue.opacity(0.6),
                        Color.pink.opacity(0.4)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    InfiniteDaySelector(
                        selectedDate: $selectedDate,
                        onDateChanged: { date in
                            selectedDate = date
                            DatePersistenceService.shared.saveSelectedDate(date)
                            dismiss()
                        },
                        hasEvents: { _ in false },
                        showMonthHeader: true
                    )
                    .frame(height: 200)
                    
                    Button(action: {
                        selectedDate = Date()
                        DatePersistenceService.shared.saveSelectedDate(Date())
                        dismiss()
                    }) {
                        Text("Today")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(
                                Capsule()
                                    .fill(Color.white.opacity(0.2))
                            )
                    }
                }
                .padding()
            }
            .navigationTitle("Select Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
}

