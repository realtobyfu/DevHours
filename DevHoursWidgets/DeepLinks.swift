//
//  DeepLinks.swift
//  DevHoursWidgets
//
//  Deep link URLs for widget/Live Activity actions.
//

import Foundation

enum DeepLink {
    static let stopTimer = URL(string: "devhours://stop-timer")!
    static let pauseTimer = URL(string: "devhours://pause-timer")!
    static let resumeTimer = URL(string: "devhours://resume-timer")!
}
