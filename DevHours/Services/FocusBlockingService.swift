//
//  FocusBlockingService.swift
//  DevHours
//
//  Manages app blocking using Screen Time API (FamilyControls/ManagedSettings).
//

import Foundation
import SwiftData
import Observation
#if !os(macOS)
import FamilyControls
import ManagedSettings
#endif

#if !os(macOS)
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
        restoreBlockingStateIfNeeded()
    }

    // MARK: - Authorization

    // UserDefaults key for caching authorization status
    private static let authStatusKey = "focusAuthorizationStatus"

    /// Check current authorization status
    func checkAuthorizationStatus() {
        let systemStatus = center.authorizationStatus

        switch systemStatus {
        case .notDetermined:
            authorizationStatus = .notDetermined
        case .approved:
            authorizationStatus = .approved
            // Cache the approved status
            UserDefaults.standard.set(AuthorizationStatus.approved.rawValue, forKey: Self.authStatusKey)
        case .denied:
            authorizationStatus = .denied
            UserDefaults.standard.set(AuthorizationStatus.denied.rawValue, forKey: Self.authStatusKey)
        @unknown default:
            // Fall back to cached status if available
            if let cached = UserDefaults.standard.string(forKey: Self.authStatusKey),
               let cachedStatus = AuthorizationStatus(rawValue: cached) {
                authorizationStatus = cachedStatus
            } else {
                authorizationStatus = .notDetermined
            }
        }

        // If system says notDetermined but we have a cached approved status,
        // the system might not be ready yet - use cached value
        if systemStatus == .notDetermined,
           let cached = UserDefaults.standard.string(forKey: Self.authStatusKey),
           cached == AuthorizationStatus.approved.rawValue {
            authorizationStatus = .approved
        }
    }

    /// Request Screen Time authorization from user
    func requestAuthorization() async -> Bool {
        do {
            try await center.requestAuthorization(for: .individual)
            authorizationStatus = .approved
            // Cache the approved status
            UserDefaults.standard.set(AuthorizationStatus.approved.rawValue, forKey: Self.authStatusKey)
            return true
        } catch {
            print("FocusBlockingService: Authorization failed - \(error)")
            authorizationStatus = .denied
            UserDefaults.standard.set(AuthorizationStatus.denied.rawValue, forKey: Self.authStatusKey)
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
    /// Simplified: just check for the end session flag and end immediately
    func checkForEndSessionRequest() {
        guard isBlocking else { return }

        guard let defaults = UserDefaults(suiteName: appGroupID) else { return }

        // Check for end session request from shield
        if defaults.bool(forKey: "shouldEndFocusSession") {
            // Clear the flag
            defaults.removeObject(forKey: "shouldEndFocusSession")

            // End the session (not successful since user ended it early)
            stopBlocking(successful: false)

            print("FocusBlockingService: Session ended by user from shield")
        }
    }

    /// Re-apply blocking to ensure apps remain blocked
    func reapplyBlocking() {
        guard isBlocking, let profile = activeProfile else { return }
        guard let selection = profile.blockedApps else { return }

        // Re-apply the blocking to ensure it's still in effect
        store.shield.applications = selection.applicationTokens
        store.shield.applicationCategories = .specific(selection.categoryTokens)

        print("FocusBlockingService: Re-applied blocking")
    }

    // MARK: - Pause / Resume Blocking

    /// Temporarily remove shields (e.g. when user pauses timer)
    func pauseBlocking() {
        guard isBlocking else { return }
        store.shield.applications = nil
        store.shield.applicationCategories = nil
    }

    /// Re-apply shields (e.g. when user resumes timer)
    func resumeBlocking() {
        guard isBlocking else { return }
        reapplyBlocking()
    }

    // MARK: - Session State Sharing (for Shield Extension)

    private func updateSharedSessionState() {
        guard let session = currentSession, let profile = activeProfile else { return }

        // Get stats for enhanced shield messaging
        let stats = getStats()

        let sessionData = FocusSessionSharedData(
            sessionId: session.id,
            profileName: profile.name,
            profileIconName: profile.iconName,
            profileColorHex: profile.colorHex,
            startTime: session.startTime,
            plannedDuration: session.plannedDuration,
            customMessage: profile.customShieldMessage,
            strictnessLevel: profile.strictnessLevel.rawValue,
            // Extended properties for enhanced shield messaging
            linkedTaskTitle: nil, // Could be populated from linked TimeEntry
            currentStreak: stats?.currentStreak,
            weeklyFocusMinutes: stats?.totalFocusMinutes,
            consecutiveSuccesses: nil // Could track zero-override sessions
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

    // MARK: - Crash Recovery

    /// Restore in-memory blocking state from any persisted active FocusSession.
    /// Handles crash/force-quit recovery: ManagedSettingsStore shields persist across
    /// app restarts, but our in-memory state resets. This ensures the next
    /// stopBlocking() call will properly clear the shields.
    private func restoreBlockingStateIfNeeded() {
        var descriptor = FetchDescriptor<FocusSession>(
            predicate: #Predicate<FocusSession> { $0.endTime == nil },
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )
        descriptor.fetchLimit = 1

        guard let activeSession = try? modelContext.fetch(descriptor).first else { return }

        currentSession = activeSession
        activeProfile = activeSession.profile
        isBlocking = true

        print("FocusBlockingService: Restored active session from persistence (crash recovery)")
    }

    /// Unconditionally clear all ManagedSettingsStore shields and reset state.
    /// Use as a nuclear recovery option when blocking is stuck.
    func forceCleanup() {
        store.shield.applications = nil
        store.shield.applicationCategories = nil

        // End any active persisted sessions
        let descriptor = FetchDescriptor<FocusSession>(
            predicate: #Predicate<FocusSession> { $0.endTime == nil }
        )
        if let activeSessions = try? modelContext.fetch(descriptor) {
            for session in activeSessions {
                session.end(successful: false)
            }
            try? modelContext.save()
        }

        currentSession = nil
        activeProfile = nil
        isBlocking = false

        clearSharedSessionState()

        print("FocusBlockingService: Force cleanup completed — all shields cleared")
    }
}
#else
@Observable
final class FocusBlockingService {
    // MARK: - State

    private(set) var authorizationStatus: AuthorizationStatus = .notDetermined
    private(set) var isBlocking: Bool = false
    private(set) var currentSession: FocusSession?
    private(set) var activeProfile: FocusProfile?

    // MARK: - Initialization

    init(modelContext: ModelContext) {
        _ = modelContext
    }

    // MARK: - Authorization

    func checkAuthorizationStatus() {}

    func requestAuthorization() async -> Bool {
        false
    }

    var isAuthorized: Bool {
        false
    }

    // MARK: - Blocking Control

    func startBlocking(
        profile: FocusProfile,
        linkedTimeEntryId: UUID? = nil,
        plannedDuration: TimeInterval? = nil
    ) {
        _ = profile
        _ = linkedTimeEntryId
        _ = plannedDuration
    }

    func stopBlocking(successful: Bool = true) {
        _ = successful
    }

    func recordOverride() {}

    func checkForEndSessionRequest() {}

    func reapplyBlocking() {}

    func pauseBlocking() {}

    func resumeBlocking() {}

    func forceCleanup() {}

    // MARK: - Stats

    func getStats() -> FocusStats? {
        nil
    }

    // MARK: - Profile Management

    func fetchProfiles() -> [FocusProfile] {
        []
    }

    func ensureDefaultProfiles() {}

}
#endif

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

    // Extended properties for enhanced shield messaging
    let linkedTaskTitle: String?
    let currentStreak: Int?
    let weeklyFocusMinutes: Int?
    let consecutiveSuccesses: Int?

    // Memberwise initializer with defaults for new properties
    init(
        sessionId: UUID,
        profileName: String,
        profileIconName: String,
        profileColorHex: String,
        startTime: Date,
        plannedDuration: TimeInterval?,
        customMessage: String?,
        strictnessLevel: String,
        linkedTaskTitle: String? = nil,
        currentStreak: Int? = nil,
        weeklyFocusMinutes: Int? = nil,
        consecutiveSuccesses: Int? = nil
    ) {
        self.sessionId = sessionId
        self.profileName = profileName
        self.profileIconName = profileIconName
        self.profileColorHex = profileColorHex
        self.startTime = startTime
        self.plannedDuration = plannedDuration
        self.customMessage = customMessage
        self.strictnessLevel = strictnessLevel
        self.linkedTaskTitle = linkedTaskTitle
        self.currentStreak = currentStreak
        self.weeklyFocusMinutes = weeklyFocusMinutes
        self.consecutiveSuccesses = consecutiveSuccesses
    }
}
