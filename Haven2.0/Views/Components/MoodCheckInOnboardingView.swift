//
//  MoodCheckInOnboardingView.swift
//  Haven2.0
//
//  Created by AI on 2025-01-XX.
//  Mood check-in views for onboarding with time pickers
//

import SwiftUI
import SwiftData

// MARK: - Wake Time Selection View
struct WakeTimeSelectionView: View {
    @Binding var wakeTime: Date
    @State private var selectedHour: Int = 9
    @State private var selectedMinute: Int = 0
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Alarm clock icon
            Image(systemName: "alarm.fill")
                .font(.system(size: 60))
                .foregroundColor(.red)
            
            Text("When do you usually wake up?")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Text("Let's set when your day starts")
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            // Time Picker
            HStack(spacing: 40) {
                // Hours
                Picker("Hour", selection: $selectedHour) {
                    ForEach(0..<24, id: \.self) { hour in
                        Text(String(format: "%02d", hour))
                            .tag(hour)
                    }
                }
                .pickerStyle(.wheel)
                .frame(width: 80)
                
                // Minutes
                Picker("Minute", selection: $selectedMinute) {
                    ForEach([0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55], id: \.self) { minute in
                        Text(String(format: "%02d", minute))
                            .tag(minute)
                    }
                }
                .pickerStyle(.wheel)
                .frame(width: 80)
            }
            .frame(height: 200)
            .onChange(of: selectedHour) { _, _ in updateWakeTime() }
            .onChange(of: selectedMinute) { _, _ in updateWakeTime() }
            .onAppear {
                let calendar = Calendar.current
                selectedHour = calendar.component(.hour, from: wakeTime)
                selectedMinute = calendar.component(.minute, from: wakeTime)
            }
            
            Spacer()
        }
        .padding()
    }
    
    private func updateWakeTime() {
        let calendar = Calendar.current
        wakeTime = calendar.date(bySettingHour: selectedHour, minute: selectedMinute, second: 0, of: Date()) ?? Date()
    }
}

// MARK: - Bed Time Selection View
struct BedTimeSelectionView: View {
    @Binding var bedTime: Date
    @State private var selectedHour: Int = 23
    @State private var selectedMinute: Int = 0
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Bed emoji/icon
            Text("🛏️")
                .font(.system(size: 60))
            
            Text("When do you usually go to bed?")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Text("Let's set the end time for your daily activities")
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            // Time Picker
            HStack(spacing: 40) {
                // Hours
                Picker("Hour", selection: $selectedHour) {
                    ForEach(0..<24, id: \.self) { hour in
                        Text(String(format: "%02d", hour))
                            .tag(hour)
                    }
                }
                .pickerStyle(.wheel)
                .frame(width: 80)
                
                // Minutes
                Picker("Minute", selection: $selectedMinute) {
                    ForEach([0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55], id: \.self) { minute in
                        Text(String(format: "%02d", minute))
                            .tag(minute)
                    }
                }
                .pickerStyle(.wheel)
                .frame(width: 80)
            }
            .frame(height: 200)
            .onChange(of: selectedHour) { _, _ in updateBedTime() }
            .onChange(of: selectedMinute) { _, _ in updateBedTime() }
            .onAppear {
                let calendar = Calendar.current
                selectedHour = calendar.component(.hour, from: bedTime)
                selectedMinute = calendar.component(.minute, from: bedTime)
            }
            
            Spacer()
        }
        .padding()
    }
    
    private func updateBedTime() {
        let calendar = Calendar.current
        bedTime = calendar.date(bySettingHour: selectedHour, minute: selectedMinute, second: 0, of: Date()) ?? Date()
    }
}

// MARK: - Dynamic Mood Scroller View
struct DynamicMoodScrollerView: View {
    @Binding var selectedMood: CoreMood?
    @State private var scrollOffset: CGFloat = 0
    
    let moods: [CoreMood] = CoreMood.allCases
    
    var body: some View {
        VStack(spacing: 24) {
            Text("How are you feeling?")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.black)
            
            Text("Swipe to select your mood")
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundColor(.gray)
            
            // Dynamic Scroller
            GeometryReader { geometry in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 20) {
                        ForEach(moods, id: \.self) { mood in
                            MoodCard(
                                mood: mood,
                                isSelected: selectedMood == mood,
                                onTap: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        selectedMood = mood
                                    }
                                }
                            )
                            .frame(width: geometry.size.width * 0.7)
                        }
                    }
                    .padding(.horizontal, geometry.size.width * 0.15)
                }
                .scrollTargetBehavior(.paging)
            }
            .frame(height: 300)
        }
        .padding()
    }
}

struct MoodCard: View {
    let mood: CoreMood
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 16) {
                Image(systemName: mood.icon)
                    .font(.system(size: 60))
                    .foregroundColor(isSelected ? mood.color : .gray)
                
                Text(mood.displayName)
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundColor(isSelected ? .black : .gray)
            }
            .frame(maxWidth: .infinity)
            .padding(30)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? mood.color.opacity(0.2) : Color.gray.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(isSelected ? mood.color : Color.clear, lineWidth: 3)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Theme Selection View (for onboarding)
struct ThemeSelectionOnboardingView: View {
    @Binding var selectedTheme: String
    @Environment(ThemeManager.self) private var themeManager
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Theme icon
            Image(systemName: "paintbrush.fill")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.purple, .pink],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Text("Which side are you on?")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Text("Choose a theme for your planner")
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            // Theme Cards
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(themeManager.getAllThemes(), id: \.id) { theme in
                        ThemeCard(
                            theme: theme,
                            isSelected: selectedTheme == theme.id,
                            onTap: {
                                selectedTheme = theme.id
                                themeManager.setTheme(to: theme.id)
                            }
                        )
                    }
                }
                .padding(.horizontal, 40)
            }
            
            Spacer()
        }
        .padding()
    }
}

struct ThemeCard: View {
    let theme: any AppTheme
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(theme.primaryGradient)
                    .frame(width: 120, height: 80)
                
                Text(theme.name)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.black)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? Color.purple : Color.clear, lineWidth: 3)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

