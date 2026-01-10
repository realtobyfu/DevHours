//
//  FocusBlockingService.swift
//  DevHours
//
//  Manages app blocking using Screen Time API (FamilyControls/ManagedSettings).
//

import Foundation
import SwiftData
import Observation
import FamilyControls
import ManagedSettings

@Observable
final class FocusBlockingService {
    // MARK: - State

    private(set) var authorizationStatus: AuthorizationStatus = .notDetermined
    private(set) var isBlocking: Bool = false
    private(set) var currentSession: FocusSession?
    private(set) var activeProfile: FocusProfile?

    // MARK: - Private Properties

    private let store = ManagedSettingsStore()
    private let modelContext: ModelContext
    private let center = AuthorizationCenter.shared

    // App Group for sharing session state with Shield Extension
    private let appGroupID = "group.com.tobiasfu.DevHours"

    // MARK: - Initialization

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        checkAuthorizationStatus()
    }

    // MARK: - Authorization

    /// Check current authorization status
    func checkAuthorizationStatus() {
        switch center.authorizationStatus {
        case .notDetermined:
            authorizationStatus = .notDetermined
        case .approved:
            authorizationStatus = .approved
        case .denied:
            authorizationStatus = .denied
        @unknown default:
            authorizationStatus = .notDetermined
        }
    }

    /// Request Screen Time authorization from user
    @MainActor
    func requestAuthorization() async -> Bool {
        do {
            try await center.requestAuthorization(for: .individual)
            authorizationStatus = .approved
            return true
        } catch {
            print("FocusBlockingService: Authorization failed - \(error)")
            authorizationStatus = .denied
            return false
        }
    }

    /// Whether authorization has been granted
    var isAuthorized: Bool {
        authorizationStatus == .approved
    }

    // MARK: - Blocking Control

    /// Start blocking apps for a focus session
    func startBlocking(
        profile: FocusProfile,
        linkedTimeEntryId: UUID? = nil,
        plannedDuration: TimeInterval? = nil
    ) {
        guard isAuthorized else {
            print("FocusBlockingService: Not authorized to block apps")
            return
        }

        guard let selection = profile.blockedApps, profile.hasBlockedApps else {
            print("FocusBlockingService: Profile has no blocked apps")
            return
        }

        // Create session
        let session = FocusSession(
            profile: profile,
            plannedDuration: plannedDuration,
            linkedTimeEntryId: linkedTimeEntryId
        )
        modelContext.insert(session)
        try? modelContext.save()

        // Apply blocking using ManagedSettings
        store.shield.applications = selection.applicationTokens
        store.shield.applicationCategories = .specific(selection.categoryTokens)

        currentSession = session
        activeProfile = profile
        isBlocking = true

        // Share session state with Shield Extension
        updateSharedSessionState()

        print("FocusBlockingService: Started blocking for profile '\(profile.name)'")
    }

    /// Stop blocking and end the current session
    func stopBlocking(successful: Bool = true) {
        // Clear blocking
        store.shield.applications = nil
        store.shield.applicationCategories = nil

        // End session
        if var session = currentSession {
            session.end(successful: successful)
            try? modelContext.save()

            // Update stats if session qualifies
            if let stats = fetchOrCreateStats() {
                stats.recordSession(session)
                try? modelContext.save()
            }
        }

        currentSession = nil
        activeProfile = nil
        isBlocking = false

        // Clear shared session state
        clearSharedSessionState()

        print("FocusBlockingService: Stopped blocking")
    }

    /// Record that user unlocked a blocked app
    func recordOverride() {
        currentSession?.recordOverride()
        try? modelContext.save()
    }

    /// Check if shield extension requested to end session (call on app foreground)
    func checkForEndSessionRequest() {
        guard isBlocking else { return }

        guard let defaults = UserDefaults(suiteName: appGroupID) else { return }

        if defaults.bool(forKey: "shouldEndFocusSession") {
            // Clear the flag
            defaults.removeObject(forKey: "shouldEndFocusSession")
            defaults.removeObject(forKey: "endSessionRequestTime")

            // Process any pending overrides
            let overrideCount = defaults.integer(forKey: "pendingOverrideCount")
            if overrideCount > 0 {
                for _ in 0..<overrideCount {
                    currentSession?.recordOverride()
                }
                defaults.set(0, forKey: "pendingOverrideCount")
            }

            // End the session (not successful since user ended it early)
            stopBlocking(successful: false)

            print("FocusBlockingService: Session ended by user from shield")
        }
    }

    // MARK: - Session State Sharing (for Shield Extension)

    private func updateSharedSessionState() {
        guard let session = currentSession, let profile = activeProfile else { return }

        let sessionData = FocusSessionSharedData(
            sessionId: session.id,
            profileName: profile.name,
            profileIconName: profile.iconName,
            profileColorHex: profile.colorHex,
            startTime: session.startTime,
            plannedDuration: session.plannedDuration,
            customMessage: profile.customShieldMessage,
            strictnessLevel: profile.strictnessLevel.rawValue
        )

        if let defaults = UserDefaults(suiteName: appGroupID),
           let encoded = try? JSONEncoder().encode(sessionData) {
            defaults.set(encoded, forKey: "currentFocusSession")
        }
    }

    private func clearSharedSessionState() {
        if let defaults = UserDefaults(suiteName: appGroupID) {
            defaults.removeObject(forKey: "currentFocusSession")
        }
    }

    // MARK: - Stats

    private func fetchOrCreateStats() -> FocusStats? {
        let descriptor = FetchDescriptor<FocusStats>()
        if let existingStats = try? modelContext.fetch(descriptor).first {
            return existingStats
        }

        // Create new stats
        let stats = FocusStats()
        modelContext.insert(stats)
        return stats
    }

    /// Get current focus stats
    func getStats() -> FocusStats? {
        let descriptor = FetchDescriptor<FocusStats>()
        return try? modelContext.fetch(descriptor).first
    }

    // MARK: - Profile Management

    /// Fetch all focus profiles
    func fetchProfiles() -> [FocusProfile] {
        let descriptor = FetchDescriptor<FocusProfile>(
            sortBy: [SortDescriptor(\.sortOrder)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    /// Create default profiles if none exist
    func ensureDefaultProfiles() {
        let existingProfiles = fetchProfiles()
        guard existingProfiles.isEmpty else { return }

        let deepWork = FocusProfile.createDeepWorkProfile()
        let studyMode = FocusProfile.createStudyModeProfile()
        let windDown = FocusProfile.createWindDownProfile()

        modelContext.insert(deepWork)
        modelContext.insert(studyMode)
        modelContext.insert(windDown)

        try? modelContext.save()
        print("FocusBlockingService: Created default profiles")
    }
}

// MARK: - Authorization Status

enum AuthorizationStatus: String {
    case notDetermined
    case approved
    case denied
}

// MARK: - Shared Data for Shield Extension

struct FocusSessionSharedData: Codable {
    let sessionId: UUID
    let profileName: String
    let profileIconName: String
    let profileColorHex: String
    let startTime: Date
    let plannedDuration: TimeInterval?
    let customMessage: String?
    let strictnessLevel: String
}
