//
//  TimelineSectionSettingsManager.swift
//  Haven2.0
//
//  Created to manage timeline section customization
//

import Foundation
import SwiftUI

class TimelineSectionSettingsManager: ObservableObject {
    @Published var leftSectionName: String = "Work"
    @Published var rightSectionName: String = "Personal"
    @Published var leftSectionCategories: Set<TaskCategory> = [.work, .fixed, .growth, .reading]
    @Published var rightSectionCategories: Set<TaskCategory> = [.personal, .flexible, .hobbies, .selfCare, .leisure, .skinCare]
    
    init() {
        loadSettings()
    }
    
    private func loadSettings() {
        if let leftName = UserDefaults.standard.string(forKey: "timelineLeftSectionName") {
            leftSectionName = leftName
        }
        if let rightName = UserDefaults.standard.string(forKey: "timelineRightSectionName") {
            rightSectionName = rightName
        }
        
        // Load categories
        if let leftCategoriesData = UserDefaults.standard.data(forKey: "timelineLeftSectionCategories"),
           let decoded = try? JSONDecoder().decode([String].self, from: leftCategoriesData) {
            leftSectionCategories = Set(decoded.compactMap { TaskCategory(rawValue: $0) })
        }
        
        if let rightCategoriesData = UserDefaults.standard.data(forKey: "timelineRightSectionCategories"),
           let decoded = try? JSONDecoder().decode([String].self, from: rightCategoriesData) {
            rightSectionCategories = Set(decoded.compactMap { TaskCategory(rawValue: $0) })
        }
    }
    
    func saveSettings() {
        UserDefaults.standard.set(leftSectionName, forKey: "timelineLeftSectionName")
        UserDefaults.standard.set(rightSectionName, forKey: "timelineRightSectionName")
        
        // Save categories
        let leftCategoriesArray = leftSectionCategories.map { $0.rawValue }
        if let encoded = try? JSONEncoder().encode(leftCategoriesArray) {
            UserDefaults.standard.set(encoded, forKey: "timelineLeftSectionCategories")
        }
        
        let rightCategoriesArray = rightSectionCategories.map { $0.rawValue }
        if let encoded = try? JSONEncoder().encode(rightCategoriesArray) {
            UserDefaults.standard.set(encoded, forKey: "timelineRightSectionCategories")
        }
    }
    
    func isCategoryInLeftSection(_ category: TaskCategory) -> Bool {
        return leftSectionCategories.contains(category)
    }
    
    func isCategoryInRightSection(_ category: TaskCategory) -> Bool {
        return rightSectionCategories.contains(category)
    }
    
    func moveCategoryToSection(_ category: TaskCategory, toLeft: Bool) {
        if toLeft {
            rightSectionCategories.remove(category)
            leftSectionCategories.insert(category)
        } else {
            leftSectionCategories.remove(category)
            rightSectionCategories.insert(category)
        }
        saveSettings()
    }
}

