//
//  ReflectionEntryView.swift
//  TimeFlow
//
//  Created by AI on 2025-10-30.
//

import SwiftUI
import SwiftData
import PhotosUI
import UIKit

struct ReflectionEntryView: View {
    let task: Task
    let goalID: String
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(ThemeManager.self) private var themeManager
    @State private var note: String = ""
    @State private var selectedPhoto: PhotosPickerItem? = nil
    @State private var selectedImageData: Data? = nil
    @State private var showingImagePicker = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Themed background
                LinearGradient(
                    colors: [Color.purple.opacity(0.8), Color.pink.opacity(0.7), Color.blue.opacity(0.6)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 12) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 50))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.purple, .pink, .blue],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: .purple.opacity(0.5), radius: 10)
                            
                            Text("Reflect on this task")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text(task.title)
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 20)
                        
                        // Reflection text editor
                        VStack(alignment: .leading, spacing: 12) {
                            Text("What did you learn? How did it go?")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            transparentTextEditor(
                                text: $note,
                                theme: themeManager.currentTheme,
                                placeholder: "What did you learn? How did it go?",
                                minHeight: 200
                            )
                        }
                        .padding(.horizontal, 20)
                        
                        // Image picker section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Add a photo (optional)")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            HStack(spacing: 16) {
                                Button(action: {
                                    // Request camera permission first
                                    let permissionManager = PermissionManager()
                                    permissionManager.requestCameraPermission { granted in
                                        if granted {
                                            showingImagePicker = true
                                        } else {
                                            // Show alert that permission is needed
                                        }
                                    }
                                }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: selectedImageData != nil ? "photo.fill" : "photo")
                                            .font(.title3)
                                        Text(selectedImageData != nil ? "Change Photo" : "Add Photo")
                                            .font(.subheadline)
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 12)
                                    .background(
                                        Capsule()
                                            .fill(
                                                LinearGradient(
                                                    colors: [.purple.opacity(0.8), .pink.opacity(0.8)],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                    )
                                }
                                
                                if selectedImageData != nil {
                                    Button(role: .destructive, action: {
                                        selectedImageData = nil
                                        selectedPhoto = nil
                                    }) {
                                        HStack(spacing: 8) {
                                            Image(systemName: "trash")
                                                .font(.caption)
                                            Text("Remove")
                                                .font(.subheadline)
                                        }
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                        .background(
                                            Capsule()
                                                .fill(Color.red.opacity(0.7))
                                        )
                                    }
                                }
                            }
                            
                            // Image preview
                            if let imageData = selectedImageData,
                               let uiImage = UIImage(data: imageData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(maxHeight: 300)
                                    .cornerRadius(16)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(
                                                LinearGradient(
                                                    colors: [.purple.opacity(0.6), .pink.opacity(0.6)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 2
                                            )
                                    )
                                    .shadow(color: .purple.opacity(0.3), radius: 10)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("Add Reflection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Skip") {
                        dismiss()
                    }
                    .foregroundColor(.white.opacity(0.8))
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        save()
                    }
                    .disabled(note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .foregroundColor(note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .white.opacity(0.5) : .white)
                }
            }
            .photosPicker(isPresented: $showingImagePicker, selection: $selectedPhoto, matching: .images)
            .onChange(of: selectedPhoto) { _, newItem in
                if let item = newItem {
                    loadPhoto(from: item)
                }
            }
        }
    }
    
    private func loadPhoto(from item: PhotosPickerItem) {
        item.loadTransferable(type: Data.self) { result in
            DispatchQueue.main.async {
                if case .success(let data) = result, let data = data {
                    // Compress image to reasonable size
                    if let uiImage = UIImage(data: data) {
                        selectedImageData = uiImage.jpegData(compressionQuality: 0.75)
                    }
                }
            }
        }
    }
    
    private func save() {
        let entry = JournalEntry(
            taskID: task.id,
            goalID: goalID,
            note: note.trimmingCharacters(in: .whitespacesAndNewlines),
            imageData: selectedImageData
        )
        modelContext.insert(entry)
        do {
            try modelContext.save()
        } catch {
            print("Failed saving reflection: \(error)")
        }
        dismiss()
    }
}

