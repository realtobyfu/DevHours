//
//  ShieldConfigurationExtension.swift
//  DevHoursShieldExtension
//
//  Provides profile-specific shield configuration.
//  Reads session data from shared UserDefaults to apply profile theming.
//

import ManagedSettings
import ManagedSettingsUI
import UIKit

// MARK: - Session Data (minimal struct for decoding shared session)

private struct SessionData: Decodable {
    let profileName: String
    let profileIconName: String
    let profileColorHex: String
    let customMessage: String?
}

// MARK: - Extension

nonisolated class ShieldConfigurationExtension: ShieldConfigurationDataSource {

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
        guard let defaults = UserDefaults(suiteName: appGroupID) else {
            return makeDefaultConfiguration()
        }

        // Try to read session data for profile-specific theming
        guard let sessionJSON = defaults.data(forKey: "currentFocusSession"),
              let session = try? JSONDecoder().decode(SessionData.self, from: sessionJSON) else {
            return makeDefaultConfiguration()
        }

        // Apply profile-specific theming
        let profileColor = colorFromHex(session.profileColorHex)
        let subtitle = session.customMessage ?? "Stay focused! You've got this."

        return ShieldConfiguration(
            backgroundBlurStyle: .systemUltraThinMaterialDark,
            backgroundColor: profileColor.withAlphaComponent(0.1),
            icon: UIImage(systemName: session.profileIconName),
            title: ShieldConfiguration.Label(
                text: session.profileName,
                color: profileColor
            ),
            subtitle: ShieldConfiguration.Label(
                text: subtitle,
                color: UIColor.label
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: "Go Back",
                color: UIColor.white
            ),
            primaryButtonBackgroundColor: profileColor
        )
    }

    private func makeDefaultConfiguration() -> ShieldConfiguration {
        return ShieldConfiguration(
            backgroundBlurStyle: .systemUltraThinMaterialDark,
            backgroundColor: UIColor.systemIndigo.withAlphaComponent(0.1),
            icon: UIImage(systemName: "sparkles"),
            title: ShieldConfiguration.Label(
                text: "Focus Mode",
                color: UIColor.systemIndigo
            ),
            subtitle: ShieldConfiguration.Label(
                text: "Stay focused! You've got this.",
                color: UIColor.label
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: "Go Back",
                color: UIColor.white
            ),
            primaryButtonBackgroundColor: UIColor.systemIndigo
        )
    }

    // MARK: - Hex Color Conversion

    private func colorFromHex(_ hex: String) -> UIColor {
        let cleanHex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: cleanHex).scanHexInt64(&int)

        let r, g, b: CGFloat
        switch cleanHex.count {
        case 6:
            r = CGFloat((int >> 16) & 0xFF) / 255.0
            g = CGFloat((int >> 8) & 0xFF) / 255.0
            b = CGFloat(int & 0xFF) / 255.0
        default:
            return .systemIndigo
        }
        return UIColor(red: r, green: g, blue: b, alpha: 1.0)
    }
}
