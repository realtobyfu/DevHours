//
//  ShieldConfigurationExtension.swift
//  DevHoursShieldExtension
//
//  Provides custom shield configuration for blocked apps.
//

import Foundation
import ManagedSettings
import ManagedSettingsUI
import UIKit

class ShieldConfigurationExtension: ShieldConfigurationDataSource {

    // App Group for reading session data from main app
    private let appGroupID = "group.com.tobiasfu.DevHours"

    override func configuration(shielding application: Application) -> ShieldConfiguration {
        makeConfiguration()
    }

    override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration {
        makeConfiguration()
    }

    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        makeConfiguration()
    }

    override func configuration(shielding webDomain: WebDomain, in category: ActivityCategory) -> ShieldConfiguration {
        makeConfiguration()
    }

    private func makeConfiguration() -> ShieldConfiguration {
        let sessionData = loadSessionData()

        // Build subtitle with session info
        let subtitle: String
        if let data = sessionData {
            let elapsed = Int(Date().timeIntervalSince(data.startTime))
            let minutes = elapsed / 60
            if let customMessage = data.customMessage, !customMessage.isEmpty {
                subtitle = customMessage
            } else if minutes > 0 {
                subtitle = "You're \(minutes) min into \(data.profileName). \(getRandomMessage())"
            } else {
                subtitle = getRandomMessage()
            }
        } else {
            subtitle = getRandomMessage()
        }

        // Load app icon from bundle
        let appIcon = UIImage(named: "AppIcon") ?? UIImage(systemName: "timer")

        return ShieldConfiguration(
            backgroundBlurStyle: .systemThickMaterial,
            backgroundColor: UIColor.systemBackground,
            icon: appIcon,
            title: ShieldConfiguration.Label(
                text: "Taking a Focus Break",
                color: UIColor.label
            ),
            subtitle: ShieldConfiguration.Label(
                text: subtitle,
                color: UIColor.secondaryLabel
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: "Back to Task",
                color: UIColor.white
            ),
            primaryButtonBackgroundColor: UIColor.systemBlue,
            secondaryButtonLabel: secondaryButtonLabel(for: sessionData)
        )
    }

    private func secondaryButtonLabel(for sessionData: FocusSessionSharedData?) -> ShieldConfiguration.Label? {
        guard let data = sessionData else {
            return ShieldConfiguration.Label(
                text: "End Focus Session",
                color: UIColor.systemRed
            )
        }

        // Check strictness level
        switch data.strictnessLevel {
        case "locked":
            // No option for locked sessions - stay focused!
            return nil
        case "firm":
            return ShieldConfiguration.Label(
                text: "End Session",
                color: UIColor.systemRed
            )
        default: // gentle
            return ShieldConfiguration.Label(
                text: "End Focus Session",
                color: UIColor.systemRed
            )
        }
    }

    private func loadSessionData() -> FocusSessionSharedData? {
        guard let defaults = UserDefaults(suiteName: appGroupID),
              let data = defaults.data(forKey: "currentFocusSession") else {
            return nil
        }
        return try? JSONDecoder().decode(FocusSessionSharedData.self, from: data)
    }

    private func getRandomMessage() -> String {
        let messages = [
            "Your future self will thank you.",
            "Deep work is a superpower.",
            "This urge will pass in 60 seconds.",
            "You chose focus. Honor that choice.",
            "Boredom sparks creativity.",
            "The scroll can wait.",
            "Small distractions, big costs.",
            "You're building something great.",
            "Stay present. Stay powerful.",
            "Your attention is valuable.",
        ]
        return messages.randomElement() ?? messages[0]
    }
}

// MARK: - Shared Data Model (must match main app)

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
