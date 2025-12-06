//
//  PermissionManager.swift
//  TimeFlow
//
//  Created by AI on 2025-10-30.
//

import Foundation
import AVFoundation
@preconcurrency import CoreLocation
import UIKit
import Combine

enum PermissionStatus {
    case notDetermined
    case granted
    case denied
    case restricted
}

@MainActor
class PermissionManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = PermissionManager()
    
    @Published var cameraStatus: PermissionStatus = .notDetermined
    @Published var locationStatus: PermissionStatus = .notDetermined
    
    private var locationManagerInstance: CLLocationManager?
    
    override init() {
        super.init()
        checkPermissions()
    }
    
    func checkPermissions() {
        cameraStatus = checkCameraPermission()
        locationStatus = checkLocationPermission()
    }
    
    // MARK: - Camera Permission
    
    private func checkCameraPermission() -> PermissionStatus {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:
            return .notDetermined
        case .authorized:
            return .granted
        case .denied, .restricted:
            return .denied
        @unknown default:
            return .notDetermined
        }
    }
    
    func requestCameraPermission(completion: @escaping (Bool) -> Void) {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                self.cameraStatus = granted ? .granted : .denied
                completion(granted)
            }
        }
    }
    
    // MARK: - Location Permission
    
    private func checkLocationPermission() -> PermissionStatus {
        let tempManager = CLLocationManager()
        switch tempManager.authorizationStatus {
        case .notDetermined:
            return .notDetermined
        case .authorizedWhenInUse, .authorizedAlways:
            return .granted
        case .denied, .restricted:
            return .denied
        @unknown default:
            return .notDetermined
        }
    }
    
    private var locationCompletion: ((Bool) -> Void)?
    
    func requestLocationPermission(completion: @escaping (Bool) -> Void) {
        let manager = CLLocationManager()
        manager.delegate = self
        locationManagerInstance = manager
        locationCompletion = completion
        
        manager.requestWhenInUseAuthorization()
    }
    
    // MARK: - CLLocationManagerDelegate
    // This is correct: the delegate runs on a background thread
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        // 1. Read the value from the non-sendable 'manager' object
        //    in the non-isolated (background) context.
        let status = manager.authorizationStatus
        
        // 2. Hop back to the MainActor to safely update 'self'
        //    (which is now isolated to the MainActor).
        _Concurrency.Task { @MainActor in
            // This code now runs safely on the main thread
            let granted = status == .authorizedWhenInUse || status == .authorizedAlways
            self.locationStatus = granted ? .granted : .denied
            self.locationCompletion?(granted)
            self.locationCompletion = nil
        }
    }
    
    // MARK: - Open Settings
    
    func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

