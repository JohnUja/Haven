//
//  FirebaseStorageService.swift
//  Haven2.0
//
//  Created by AI on 2025-11-03.
//

import Foundation
import SwiftUI
import FirebaseStorage
import FirebaseAuth

// MARK: - Firebase Storage Service
@MainActor
class FirebaseStorageService: ObservableObject {
    static let shared = FirebaseStorageService()
    
    private let storage = Storage.storage()
    
    private init() {}
    
    // MARK: - Upload Reflection Photo
    func uploadReflectionPhoto(imageData: Data, taskID: String) async throws -> String {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw StorageError.userNotAuthenticated
        }
        
        let storageRef = storage.reference()
        let photoRef = storageRef.child("user_files/\(uid)/reflections/\(taskID).jpg")
        
        // Set metadata
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        metadata.customMetadata = [
            "taskID": taskID,
            "uploadedAt": String(Date().timeIntervalSince1970)
        ]
        
        // Upload with progress tracking (optional)
        let _ = try await photoRef.putData(imageData, metadata: metadata)
        
        // Get download URL
        let downloadURL = try await photoRef.downloadURL()
        return downloadURL.absoluteString
    }
    
    // MARK: - Upload Task Attachment
    func uploadTaskAttachment(data: Data, fileName: String, taskID: String) async throws -> String {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw StorageError.userNotAuthenticated
        }
        
        let storageRef = storage.reference()
        let attachmentRef = storageRef.child("user_files/\(uid)/attachments/\(taskID)/\(fileName)")
        
        // Set metadata
        let metadata = StorageMetadata()
        metadata.contentType = getContentType(for: fileName)
        metadata.customMetadata = [
            "taskID": taskID,
            "fileName": fileName,
            "uploadedAt": String(Date().timeIntervalSince1970)
        ]
        
        // Upload
        let _ = try await attachmentRef.putData(data, metadata: metadata)
        
        // Get download URL
        let downloadURL = try await attachmentRef.downloadURL()
        return downloadURL.absoluteString
    }
    
    // MARK: - Delete Reflection Photo
    func deleteReflectionPhoto(taskID: String) async throws {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw StorageError.userNotAuthenticated
        }
        
        let storageRef = storage.reference()
        let photoRef = storageRef.child("user_files/\(uid)/reflections/\(taskID).jpg")
        
        try await photoRef.delete()
    }
    
    // MARK: - Delete Task Attachment
    func deleteTaskAttachment(fileName: String, taskID: String) async throws {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw StorageError.userNotAuthenticated
        }
        
        let storageRef = storage.reference()
        let attachmentRef = storageRef.child("user_files/\(uid)/attachments/\(taskID)/\(fileName)")
        
        try await attachmentRef.delete()
    }
    
    // MARK: - Download Image
    func downloadImage(urlString: String) async throws -> Data {
        guard let url = URL(string: urlString) else {
            throw StorageError.invalidURL
        }
        
        // If it's a Firebase Storage URL, use Storage reference
        if urlString.contains("firebasestorage.googleapis.com") {
            let storageRef = storage.reference(forURL: urlString)
            let maxSize: Int64 = 10 * 1024 * 1024 // 10 MB
            return try await storageRef.data(maxSize: maxSize)
        } else {
            // Regular HTTP URL
            let (data, _) = try await URLSession.shared.data(from: url)
            return data
        }
    }
    
    // MARK: - Helper: Get Content Type
    private func getContentType(for fileName: String) -> String {
        let ext = (fileName as NSString).pathExtension.lowercased()
        
        switch ext {
        case "jpg", "jpeg":
            return "image/jpeg"
        case "png":
            return "image/png"
        case "pdf":
            return "application/pdf"
        case "txt":
            return "text/plain"
        case "mp3", "m4a":
            return "audio/mpeg"
        default:
            return "application/octet-stream"
        }
    }
    
    // MARK: - Compress Image
    func compressImage(_ imageData: Data, maxSizeKB: Int = 500) -> Data? {
        guard let image = UIImage(data: imageData) else { return nil }
        
        var compression: CGFloat = 0.9
        var compressedData = image.jpegData(compressionQuality: compression)
        
        while let data = compressedData, data.count > maxSizeKB * 1024 && compression > 0.1 {
            compression -= 0.1
            compressedData = image.jpegData(compressionQuality: compression)
        }
        
        return compressedData ?? imageData
    }
}

// MARK: - Storage Error
enum StorageError: LocalizedError {
    case userNotAuthenticated
    case invalidURL
    case uploadFailed
    case downloadFailed
    case deleteFailed
    
    var errorDescription: String? {
        switch self {
        case .userNotAuthenticated:
            return "User not authenticated"
        case .invalidURL:
            return "Invalid URL"
        case .uploadFailed:
            return "Upload failed"
        case .downloadFailed:
            return "Download failed"
        case .deleteFailed:
            return "Delete failed"
        }
    }
}

