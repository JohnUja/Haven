//
//  LocalUserProvisioningService.swift
//  Haven2.0
//

import Foundation
import SwiftData
import FirebaseAuth

@MainActor
enum LocalUserProvisioningService {
    static let defaultThemeIDs = ["purple", "light", "dark"]

    nonisolated static func currentAuthenticatedUserID() -> String? {
        Auth.auth().currentUser?.uid
    }

    static func resolveCurrentUser(from users: [User]) -> User? {
        guard let authUser = Auth.auth().currentUser else {
            return users.first
        }

        if let exactMatch = users.first(where: { $0.id == authUser.uid }) {
            return exactMatch
        }

        if let email = authUser.email, !email.isEmpty,
           let emailMatch = users.first(where: { $0.email == email }) {
            return emailMatch
        }

        return users.first
    }

    static func ensureLocalUserExists(in modelContext: ModelContext) async throws -> User? {
        guard let authUser = Auth.auth().currentUser else {
            return nil
        }

        try ensureDefaultThemesExist(in: modelContext)

        let users = try modelContext.fetch(FetchDescriptor<User>())
        let user = try upsertLocalUser(for: authUser, existingUsers: users, in: modelContext)

        ensureDefaultThemeAccess(for: user)
        ensureDefaultRoutines(for: user, in: modelContext)

        try modelContext.save()

        do {
            try await syncRemoteUserState(for: user, authUser: authUser)
            try modelContext.save()
        } catch {
            print("LocalUserProvisioningService: Remote sync failed - \(error)")
        }

        return user
    }

    private static func upsertLocalUser(
        for authUser: FirebaseAuth.User,
        existingUsers: [User],
        in modelContext: ModelContext
    ) throws -> User {
        if let existingUser = existingUsers.first(where: { $0.id == authUser.uid }) {
            update(existingUser, from: authUser)
            return existingUser
        }

        if let legacyUser = legacyUserCandidate(from: existingUsers) {
            let previousID = legacyUser.id
            if previousID != authUser.uid {
                migrateOwnedRecords(from: previousID, to: authUser.uid, in: modelContext)
            }
            legacyUser.id = authUser.uid
            update(legacyUser, from: authUser)
            return legacyUser
        }

        let newUser = User(
            id: authUser.uid,
            email: authUser.email ?? "",
            name: displayName(for: authUser),
            gamificationCurrency: authUser.isAnonymous ? 0 : 100,
            ownedThemeIDs: defaultThemeIDs,
            activeThemeID: "purple",
            subscriptionTierRaw: SubscriptionTier.free.rawValue
        )
        modelContext.insert(newUser)
        return newUser
    }

    private static func legacyUserCandidate(from users: [User]) -> User? {
        if let syntheticUser = users.first(where: { $0.email == "user@timeflow.app" }) {
            return syntheticUser
        }

        if users.count == 1 {
            return users.first
        }

        return nil
    }

    private static func update(_ user: User, from authUser: FirebaseAuth.User) {
        if let email = authUser.email {
            user.email = email
        }

        let resolvedName = displayName(for: authUser)
        if !resolvedName.isEmpty {
            user.name = resolvedName
        }

        if user.subscriptionTierRaw.isEmpty {
            user.subscriptionTierRaw = SubscriptionTier.free.rawValue
        }
    }

    private static func displayName(for authUser: FirebaseAuth.User) -> String {
        if let displayName = authUser.displayName, !displayName.isEmpty {
            return displayName
        }

        if authUser.isAnonymous {
            return "Guest"
        }

        if let email = authUser.email, !email.isEmpty {
            return email.components(separatedBy: "@").first ?? "User"
        }

        return "User"
    }

    private static func ensureDefaultThemeAccess(for user: User) {
        for themeID in defaultThemeIDs where !user.ownedThemeIDs.contains(themeID) {
            user.ownedThemeIDs.append(themeID)
        }

        if user.activeThemeID == "default" || user.activeThemeID.isEmpty {
            user.activeThemeID = "purple"
        }
    }

    private static func ensureDefaultThemesExist(in modelContext: ModelContext) throws {
        let existingThemes = try modelContext.fetch(FetchDescriptor<Theme>())
        let existingIDs = Set(existingThemes.map(\.id))

        let defaultThemes: [Theme] = [
            Theme(
                id: "purple",
                name: "Purple",
                themeDescription: "Default purple gradient theme",
                unlockMethod: .defaultTheme,
                unlockRequirement: "Free",
                currencyPrice: 0,
                isDefault: true
            ),
            Theme(
                id: "light",
                name: "Light",
                themeDescription: "Clean white theme with black accents",
                unlockMethod: .defaultTheme,
                unlockRequirement: "Free",
                currencyPrice: 0,
                isDefault: true
            ),
            Theme(
                id: "dark",
                name: "Dark",
                themeDescription: "Dark theme with white accents",
                unlockMethod: .defaultTheme,
                unlockRequirement: "Free",
                currencyPrice: 0,
                isDefault: true
            ),
            Theme(
                id: "energetic",
                name: "Energetic",
                themeDescription: "Vibrant and motivating",
                unlockMethod: .level,
                unlockRequirement: "Reach Level 5",
                currencyPrice: 0,
                isDefault: false,
                unlockLevel: 5
            ),
            Theme(
                id: "calm",
                name: "Calm",
                themeDescription: "Peaceful and soothing",
                unlockMethod: .level,
                unlockRequirement: "Reach Level 10",
                currencyPrice: 0,
                isDefault: false,
                unlockLevel: 10
            ),
            Theme(
                id: "sunset",
                name: "Sunset",
                themeDescription: "Warm orange and red gradient",
                unlockMethod: .currency,
                unlockRequirement: "Purchase with crystals",
                currencyPrice: 500,
                isDefault: false
            ),
            Theme(
                id: "vintage",
                name: "Vintage",
                themeDescription: "Classic and timeless brown tones",
                unlockMethod: .currency,
                unlockRequirement: "Purchase with crystals",
                currencyPrice: 500,
                isDefault: false
            ),
            Theme(
                id: "neon",
                name: "Neon",
                themeDescription: "Bright cyan and pink neon colors",
                unlockMethod: .currency,
                unlockRequirement: "Purchase with crystals",
                currencyPrice: 750,
                isDefault: false
            ),
            Theme(
                id: "balanced",
                name: "Balanced",
                themeDescription: "Achieve balanced moods",
                unlockMethod: .currency,
                unlockRequirement: "Purchase with crystals",
                currencyPrice: 400,
                isDefault: false,
                moodRequirement: MoodRequirement(
                    requiredMoods: [.happy, .calm],
                    requiredCount: 7,
                    pattern: "balanced"
                )
            ),
            Theme(
                id: "consistency",
                name: "Consistency",
                themeDescription: "Perfect week achievement",
                unlockMethod: .currency,
                unlockRequirement: "Purchase with crystals",
                currencyPrice: 600,
                isDefault: false,
                moodRequirement: MoodRequirement(
                    requiredMoods: [],
                    requiredCount: 0,
                    pattern: "perfect_week"
                )
            )
        ]

        for theme in defaultThemes where !existingIDs.contains(theme.id) {
            modelContext.insert(theme)
        }
    }

    private static func ensureDefaultRoutines(for user: User, in modelContext: ModelContext) {
        let userID = user.id
        let routinesFetch = FetchDescriptor<DailyRoutine>(
            predicate: #Predicate<DailyRoutine> { routine in
                routine.userID == userID
            }
        )

        let hasExistingRoutines = ((try? modelContext.fetch(routinesFetch))?.isEmpty == false)
        if !hasExistingRoutines {
            _ = RoutineService.shared.createDefaultRoutines(userID: userID, in: modelContext)
        }
    }

    private static func migrateOwnedRecords(from oldUserID: String, to newUserID: String, in modelContext: ModelContext) {
        guard oldUserID != newUserID else { return }

        migrateTasks(from: oldUserID, to: newUserID, in: modelContext)
        migrateTaskBlocks(from: oldUserID, to: newUserID, in: modelContext)
        migrateGoals(from: oldUserID, to: newUserID, in: modelContext)
        migrateRoutines(from: oldUserID, to: newUserID, in: modelContext)
        migrateMoodEntries(from: oldUserID, to: newUserID, in: modelContext)
        migrateGoalReflections(from: oldUserID, to: newUserID, in: modelContext)
    }

    private static func migrateTasks(from oldUserID: String, to newUserID: String, in modelContext: ModelContext) {
        let descriptor = FetchDescriptor<Task>(
            predicate: #Predicate<Task> { task in
                task.userID == oldUserID
            }
        )
        (try? modelContext.fetch(descriptor))?.forEach { $0.userID = newUserID }
    }

    private static func migrateTaskBlocks(from oldUserID: String, to newUserID: String, in modelContext: ModelContext) {
        let descriptor = FetchDescriptor<TaskBlock>(
            predicate: #Predicate<TaskBlock> { block in
                block.userID == oldUserID
            }
        )
        (try? modelContext.fetch(descriptor))?.forEach { $0.userID = newUserID }
    }

    private static func migrateGoals(from oldUserID: String, to newUserID: String, in modelContext: ModelContext) {
        let descriptor = FetchDescriptor<Goal>(
            predicate: #Predicate<Goal> { goal in
                goal.userID == oldUserID
            }
        )
        (try? modelContext.fetch(descriptor))?.forEach { $0.userID = newUserID }
    }

    private static func migrateRoutines(from oldUserID: String, to newUserID: String, in modelContext: ModelContext) {
        let descriptor = FetchDescriptor<DailyRoutine>(
            predicate: #Predicate<DailyRoutine> { routine in
                routine.userID == oldUserID
            }
        )
        (try? modelContext.fetch(descriptor))?.forEach { $0.userID = newUserID }
    }

    private static func migrateMoodEntries(from oldUserID: String, to newUserID: String, in modelContext: ModelContext) {
        let descriptor = FetchDescriptor<MoodEntry>(
            predicate: #Predicate<MoodEntry> { moodEntry in
                moodEntry.userID == oldUserID
            }
        )
        (try? modelContext.fetch(descriptor))?.forEach { $0.userID = newUserID }
    }

    private static func migrateGoalReflections(from oldUserID: String, to newUserID: String, in modelContext: ModelContext) {
        let descriptor = FetchDescriptor<GoalReflection>(
            predicate: #Predicate<GoalReflection> { reflection in
                reflection.userID == oldUserID
            }
        )
        (try? modelContext.fetch(descriptor))?.forEach { $0.userID = newUserID }
    }

    private static func syncRemoteUserState(for user: User, authUser: FirebaseAuth.User) async throws {
        let firestore = FirestoreService.shared
        try await firestore.createOrUpdateUser(
            uid: authUser.uid,
            email: authUser.email ?? user.email,
            displayName: displayName(for: authUser)
        )

        if let remoteData = try await firestore.getUserData(uid: authUser.uid) {
            if let subscriptionStatus = remoteData["subscriptionStatus"] as? String,
               !subscriptionStatus.isEmpty {
                user.subscriptionTierRaw = subscriptionStatus
            }

            if let activeThemeID = remoteData["activeThemeID"] as? String, !activeThemeID.isEmpty {
                user.activeThemeID = normalizeRemoteThemeID(activeThemeID)
            }

            if let ownedThemes = remoteData["ownedThemeIDs"] as? [String: Any] {
                let normalizedIDs = ownedThemes.keys.map(normalizeRemoteThemeID(_:))
                for themeID in normalizedIDs where !user.ownedThemeIDs.contains(themeID) {
                    user.ownedThemeIDs.append(themeID)
                }
            }
        }
    }

    private static func normalizeRemoteThemeID(_ rawThemeID: String) -> String {
        rawThemeID == "default" ? "purple" : rawThemeID
    }
}
