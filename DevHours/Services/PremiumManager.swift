//
//  PremiumManager.swift
//  DevHours
//
//  Manages premium feature access with StoreKit 2 integration.
//

import Foundation
import Observation
import SwiftData
import StoreKit

@Observable
final class PremiumManager {

    // MARK: - Dependencies

    private(set) var storeKitManager: StoreKitManager
    private var focusBlockingService: FocusBlockingService?

    // MARK: - Debug Override

    /// Debug flag to force premium status (for testing)
    var debugOverridePremium: Bool {
        get { UserDefaults.standard.bool(forKey: "debugPremiumOverride") }
        set { UserDefaults.standard.set(newValue, forKey: "debugPremiumOverride") }
    }

    // MARK: - Premium Status

    /// Whether user has active premium access
    var isPremium: Bool {
        // Debug override takes precedence
        if debugOverridePremium { return true }

        // Check StoreKit entitlements
        return storeKitManager.hasLifetimePurchase
    }

    // MARK: - Free Tier Limits

    /// Maximum focus sessions per week for free users
    static let freeWeeklySessionLimit = 3

    /// Maximum custom profiles for free users (they get 1 default profile)
    static let freeProfileLimit = 1

    // MARK: - Initialization

    init() {
        self.storeKitManager = StoreKitManager()
    }

    func configure(with focusBlockingService: FocusBlockingService) {
        self.focusBlockingService = focusBlockingService
    }

    // MARK: - Feature Gating

    /// Check if user can start a focus session
    func canStartFocusSession() -> Bool {
        if isPremium { return true }

        guard let stats = focusBlockingService?.getStats() else {
            // No stats yet, allow first sessions
            return true
        }

        // Reset weekly count if needed
        stats.resetWeeklyCountIfNeeded()

        return stats.weeklySessionCount < Self.freeWeeklySessionLimit
    }

    /// Check if user can create a new profile
    func canCreateProfile() -> Bool {
        if isPremium { return true }

        guard let profiles = focusBlockingService?.fetchProfiles() else {
            return true
        }

        // Free users can only have default profiles (no custom ones)
        let customProfiles = profiles.filter { !$0.isDefault }
        return customProfiles.count < Self.freeProfileLimit
    }

    /// Check if user can access focus statistics
    func canAccessStats() -> Bool {
        isPremium
    }

    /// Check if user can use custom shield messages
    func canUseCustomMessages() -> Bool {
        isPremium
    }

    /// Check if user can select all strictness levels
    func canUseAllStrictnessLevels() -> Bool {
        isPremium
    }

    /// Check if user can see streaks
    func canSeeStreaks() -> Bool {
        isPremium
    }

    /// Get remaining free sessions this week
    func remainingFreeSessions() -> Int {
        guard let stats = focusBlockingService?.getStats() else {
            return Self.freeWeeklySessionLimit
        }
        stats.resetWeeklyCountIfNeeded()
        return max(0, Self.freeWeeklySessionLimit - stats.weeklySessionCount)
    }

    // MARK: - Premium Prompts

    /// Message to show when free session limit is hit
    var sessionLimitMessage: String {
        "You've used your \(Self.freeWeeklySessionLimit) free Focus sessions this week. " +
        "Upgrade to Premium for unlimited focus time."
    }

    /// Message to show when trying to create a profile
    var profileLimitMessage: String {
        "Create unlimited custom Focus profiles with Premium."
    }

    /// Message to show when trying to access stats
    var statsLockedMessage: String {
        "Track your streaks, achievements, and focus statistics with Premium."
    }

    // MARK: - Purchase Methods

    /// Purchase lifetime premium
    @MainActor
    func purchaseLifetime() async -> Bool {
        await storeKitManager.purchaseLifetime()
    }

    /// Restore previous purchases
    @MainActor
    func restorePurchases() async {
        await storeKitManager.restorePurchases()
    }

    /// Check purchase status on app launch
    @MainActor
    func checkSubscriptionStatus() async {
        await storeKitManager.checkEntitlements()
    }

    // MARK: - Convenience Accessors

    /// Whether products are still loading
    var isLoading: Bool {
        storeKitManager.isLoading
    }

    /// Any purchase error message
    var purchaseError: String? {
        storeKitManager.purchaseError
    }

    /// Price string for display
    var priceString: String {
        storeKitManager.priceString
    }
}

// MARK: - Premium Feature Enum

enum PremiumFeature: String, CaseIterable {
    case unlimitedSessions = "Unlimited Focus Sessions"
    case customProfiles = "Custom Focus Profiles"
    case focusStats = "Focus Statistics"
    case streaksAndAchievements = "Streaks & Achievements"
    case customMessages = "Custom Shield Messages"
    case allStrictnessLevels = "All Strictness Levels"
    case scheduledFocus = "Scheduled Focus Times"

    var description: String {
        switch self {
        case .unlimitedSessions:
            return "Focus as much as you want, no weekly limits"
        case .customProfiles:
            return "Create profiles for different work contexts"
        case .focusStats:
            return "See detailed focus time analytics"
        case .streaksAndAchievements:
            return "Track your consistency and unlock achievements"
        case .customMessages:
            return "Write your own shield screen messages"
        case .allStrictnessLevels:
            return "Choose how hard it is to unlock blocked apps"
        case .scheduledFocus:
            return "Automatically enable focus at scheduled times"
        }
    }

    var iconName: String {
        switch self {
        case .unlimitedSessions: return "infinity"
        case .customProfiles: return "person.2.fill"
        case .focusStats: return "chart.bar.fill"
        case .streaksAndAchievements: return "flame.fill"
        case .customMessages: return "text.bubble.fill"
        case .allStrictnessLevels: return "lock.shield.fill"
        case .scheduledFocus: return "calendar.badge.clock"
        }
    }
}
