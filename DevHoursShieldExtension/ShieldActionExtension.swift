//
//  ShieldActionExtension.swift
//  DevHoursShieldExtension
//
//  Handles shield button actions (primary/secondary).
//

import Foundation
import ManagedSettings
import ManagedSettingsUI

class ShieldActionExtension: ShieldActionDelegate {

    // App Group for communication with main app
    private let appGroupID = "group.com.tobiasfu.DevHours"

    override func handle(action: ShieldAction, for application: ApplicationToken, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        handleAction(action, completionHandler: completionHandler)
    }

    override func handle(action: ShieldAction, for webDomain: WebDomainToken, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        handleAction(action, completionHandler: completionHandler)
    }

    override func handle(action: ShieldAction, for category: ActivityCategoryToken, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        handleAction(action, completionHandler: completionHandler)
    }

    private func handleAction(_ action: ShieldAction, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        switch action {
        case .primaryButtonPressed:
            // Close shield and go back
            completionHandler(.close)

        case .secondaryButtonPressed:
            // Record the override attempt and close
            // Note: True temporary unlock requires the main app to remove the shield
            recordOverride()
            completionHandler(.close)

        @unknown default:
            completionHandler(.close)
        }
    }

    private func recordOverride() {
        // Signal main app to end the focus session
        guard let defaults = UserDefaults(suiteName: appGroupID) else { return }

        // Set flag to end session
        defaults.set(true, forKey: "shouldEndFocusSession")
        defaults.set(Date().timeIntervalSince1970, forKey: "endSessionRequestTime")

        // Increment override count for stats
        let currentCount = defaults.integer(forKey: "pendingOverrideCount")
        defaults.set(currentCount + 1, forKey: "pendingOverrideCount")
    }
}
