//
//  QuickAddView.swift
//  Haven2.0
//
//  Created by AI on 2025-01-XX.
//  Quick add section for fast task creation
//

import SwiftUI

struct QuickAddView: View {
    @State private var showingAddTask = false
    @State private var showingVoiceNote = false
    @State private var showingSnapTask = false
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Quick Add")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                // Voice Note
                Button(action: {
                    showingVoiceNote = true
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "mic.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(
                                Circle()
                                    .fill(Color.blue.opacity(0.6))
                            )
                        
                        Text("Voice Note")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.white)
                        
                        Spacer()
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.1))
                    )
                }
                
                // Snap Task
                Button(action: {
                    showingSnapTask = true
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(
                                Circle()
                                    .fill(Color.purple.opacity(0.6))
                            )
                        
                        Text("Snap Task")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.white)
                        
                        Spacer()
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.1))
                    )
                }
                
                // New Task
                Button(action: {
                    showingAddTask = true
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(
                                Circle()
                                    .fill(Color.green.opacity(0.6))
                            )
                        
                        Text("New Task")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.white)
                        
                        Spacer()
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.1))
                    )
                }
            }
        }
        .padding(20)
        .frame(width: 180)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
        .sheet(isPresented: $showingAddTask) {
            AddTaskView(selectedDate: Date())
        }
        .sheet(isPresented: $showingVoiceNote) {
            // TODO: Voice note view
            Text("Voice Note - Coming Soon")
                .padding()
        }
        .sheet(isPresented: $showingSnapTask) {
            // TODO: Snap task view
            Text("Snap Task - Coming Soon")
                .padding()
        }
    }
}

