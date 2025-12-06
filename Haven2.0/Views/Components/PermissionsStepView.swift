//
//  PermissionsStepView.swift
//  Haven2.0
//
//  Created by AI on 2025-01-XX.
//  Permissions step for onboarding - Location and Calendar access
//

import SwiftUI
import CoreLocation
import EventKit

struct PermissionsStepView: View {
    @Environment(ThemeManager.self) private var themeManager
    @StateObject private var permissionManager = PermissionManager.shared
    @StateObject private var calendarManager = CalendarManager.shared
    
    let onComplete: () -> Void
    
    @State private var locationPermissionStatus: CLAuthorizationStatus = .notDetermined
    @State private var calendarPermissionStatus: EKAuthorizationStatus = .notDetermined
    
    var body: some View {
        let theme = themeManager.currentTheme
        
        VStack(spacing: 24) {
            // Icon
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 60, weight: .light))
                .foregroundColor(theme.accentColor)
                .padding(.top, 40)
            
            // Title
            Text("Enable Permissions")
                .font(theme.headerFont)
                .foregroundColor(theme.textPrimary)
                .padding(.horizontal, 20)
            
            // Description
            Text("Grant access to location and calendar for enhanced features")
                .font(theme.titleFont)
                .foregroundColor(theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            
            Spacer()
            
            // Permission Cards
            VStack(spacing: 16) {
                // Location Permission
                permissionCard(
                    icon: "location.fill",
                    title: "Location Access",
                    description: "Enable location-based task suggestions",
                    isGranted: locationPermissionStatus == .authorizedWhenInUse || locationPermissionStatus == .authorizedAlways,
                    action: {
                        permissionManager.requestLocationPermission { granted in
                            locationPermissionStatus = CLLocationManager().authorizationStatus
                        }
                    }
                )
                
                // Calendar Permission
                permissionCard(
                    icon: "calendar",
                    title: "Calendar Access",
                    description: "Sync tasks with your calendar",
                    isGranted: calendarPermissionStatus == .authorized,
                    action: {
                        calendarManager.requestAccess { granted in
                            calendarPermissionStatus = EKEventStore.authorizationStatus(for: .event)
                        }
                    }
                )
            }
            .padding(.horizontal, 20)
            
            Spacer()
            
            // Continue Button
            Button(action: {
                onComplete()
            }) {
                Text("Continue")
                    .font(theme.headerFont)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(theme.accentColor)
                    .cornerRadius(theme.smallCornerRadius)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .onAppear {
            locationPermissionStatus = CLLocationManager().authorizationStatus
            calendarPermissionStatus = EKEventStore.authorizationStatus(for: .event)
        }
        .onChange(of: calendarManager.isAuthorized) { _, authorized in
            if authorized {
                calendarPermissionStatus = .authorized
            }
        }
        .onChange(of: permissionManager.locationStatus) { _, status in
            if status == .granted {
                locationPermissionStatus = .authorizedWhenInUse
            } else if status == .denied {
                locationPermissionStatus = .denied
            }
        }
    }
    
    private func permissionCard(icon: String, title: String, description: String, isGranted: Bool, action: @escaping () -> Void) -> some View {
        let theme = themeManager.currentTheme
        
        return Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(isGranted ? .green : theme.accentColor)
                    .frame(width: 40, height: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(theme.titleFont)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.textPrimary)
                    
                    Text(description)
                        .font(theme.bodyFont)
                        .foregroundColor(theme.textSecondary)
                }
                
                Spacer()
                
                if isGranted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.system(size: 20))
                } else {
                    Image(systemName: "chevron.right")
                        .foregroundColor(theme.textSecondary)
                        .font(.system(size: 14))
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: theme.cardCornerRadius)
                    .fill(theme.glassBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: theme.cardCornerRadius)
                            .stroke(theme.glassBorder, lineWidth: theme.cardBorderWidth)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

