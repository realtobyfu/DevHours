//
//  FocusProfile.swift
//  DevHours
//
//  Focus profiles for blocking distracting apps during timer sessions.
//

import Foundation
import SwiftData
import FamilyControls

/// Strictness level determines how hard it is to unlock blocked apps
enum StrictnessLevel: String, Codable, CaseIterable {
    case gentle   // Single tap unlock
    case firm     // 3-second hold to unlock
    case locked   // No override until session ends

    var displayName: String {
        switch self {
        case .gentle: return "Gentle"
        case .firm: return "Firm"
        case .locked: return "Locked"
        }
    }

    var description: String {
        switch self {
        case .gentle: return "Single tap to unlock"
        case .firm: return "Hold 3 seconds to unlock"
        case .locked: return "No unlock until session ends"
        }
    }
}

@Model
final class FocusProfile {
    var id: UUID
    var name: String
    var iconName: String  // SF Symbol name
    var colorHex: String
    var strictnessLevel: StrictnessLevel
    var customShieldMessage: String?
    var isDefault: Bool  // Pre-built profiles
    var sortOrder: Int
    var createdAt: Date

    // Store FamilyActivitySelection as encoded Data
    // This allows SwiftData to persist the selection
    var blockedAppsData: Data?

    // Relationship to sessions
    @Relationship(deleteRule: .nullify)
    var sessions: [FocusSession] = []

    init(
        name: String,
        iconName: String,
        colorHex: String,
        strictnessLevel: StrictnessLevel = .firm,
        customShieldMessage: String? = nil,
        isDefault: Bool = false,
        sortOrder: Int = 0
    ) {
        self.id = UUID()
        self.name = name
        self.iconName = iconName
        self.colorHex = colorHex
        self.strictnessLevel = strictnessLevel
        self.customShieldMessage = customShieldMessage
        self.isDefault = isDefault
        self.sortOrder = sortOrder
        self.createdAt = Date()
    }

    // MARK: - FamilyActivitySelection Encoding/Decoding

    var blockedApps: FamilyActivitySelection? {
        get {
            guard let data = blockedAppsData else { return nil }
            do {
                return try PropertyListDecoder().decode(FamilyActivitySelection.self, from: data)
            } catch {
                print("Failed to decode FamilyActivitySelection: \(error)")
                return nil
            }
        }
        set {
            guard let selection = newValue else {
                blockedAppsData = nil
                return
            }
            do {
                blockedAppsData = try PropertyListEncoder().encode(selection)
            } catch {
                print("Failed to encode FamilyActivitySelection: \(error)")
                blockedAppsData = nil
            }
        }
    }

    /// Check if this profile has any apps or categories selected
    var hasBlockedApps: Bool {
        guard let selection = blockedApps else { return false }
        return !selection.applicationTokens.isEmpty || !selection.categoryTokens.isEmpty
    }
}

// MARK: - Default Profiles

extension FocusProfile {

    /// Create the default "Deep Work" profile
    static func createDeepWorkProfile() -> FocusProfile {
        FocusProfile(
            name: "Deep Work",
            iconName: "brain.head.profile",
            colorHex: "#5E35B1",  // Indigo
            strictnessLevel: .firm,
            customShieldMessage: "You're in deep work mode. Your best ideas come when you're fully present.",
            isDefault: true,
            sortOrder: 0
        )
    }

    /// Create the default "Study Mode" profile
    static func createStudyModeProfile() -> FocusProfile {
        FocusProfile(
            name: "Study Mode",
            iconName: "book.fill",
            colorHex: "#00897B",  // Teal
            strictnessLevel: .firm,
            customShieldMessage: "Study time! Knowledge compounds. Every minute focused pays dividends.",
            isDefault: true,
            sortOrder: 1
        )
    }

    /// Create the default "Wind Down" profile
    static func createWindDownProfile() -> FocusProfile {
        FocusProfile(
            name: "Wind Down",
            iconName: "moon.fill",
            colorHex: "#8E24AA",  // Purple
            strictnessLevel: .gentle,
            customShieldMessage: "Time to disconnect. Your mind needs rest to perform tomorrow.",
            isDefault: true,
            sortOrder: 2
        )
    }
}
