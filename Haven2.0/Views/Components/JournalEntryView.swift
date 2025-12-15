//
//  JournalEntryView.swift
//  TimeFlow
//
//  Created by AI on 2025-10-30.
//

import SwiftUI
import SwiftData
import PhotosUI

struct JournalEntryView: View {
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
            formContent
        }
    }
    
    @ViewBuilder
    private var formContent: some View {
        Form {
            Section(header: Text("Reflect on this task")) {
                textEditorSection
                imagePickerSection
                imagePreview
            }
        }
        .navigationTitle("Add Journal Entry")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Skip") { dismiss() }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") { save() }
                    .disabled(note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .photosPicker(isPresented: $showingImagePicker, selection: $selectedPhoto, matching: .images)
        .onChange(of: selectedPhoto) { _, newItem in
            if let item = newItem {
                loadPhoto(from: item)
            }
        }
    }
    
    private var textEditorSection: some View {
        transparentTextEditor(
            text: $note,
            theme: themeManager.currentTheme,
            placeholder: "Reflect on this task...",
            minHeight: 120
        )
    }
    
    @ViewBuilder
    private var imagePickerSection: some View {
        HStack {
            Button(action: { showingImagePicker = true }) {
                HStack {
                    Image(systemName: selectedImageData != nil ? "photo.fill" : "photo")
                    Text(selectedImageData != nil ? "Change Photo" : "Add Photo")
                }
                .foregroundColor(.blue)
            }
            
            if selectedImageData != nil {
                Button(role: .destructive, action: {
                    selectedImageData = nil
                    selectedPhoto = nil
                }) {
                    Text("Remove")
                        .foregroundColor(.red)
                }
            }
        }
    }
    
    @ViewBuilder
    private var imagePreview: some View {
        if let imageData = selectedImageData,
           let uiImage = UIImage(data: imageData) {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxHeight: 200)
                .cornerRadius(8)
        }
    }
    
    private func loadPhoto(from item: PhotosPickerItem) {
        item.loadTransferable(type: Data.self) { result in
            _Concurrency.Task { @MainActor in
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
            print("Failed saving journal: \(error)")
        }
        dismiss()
    }
}

