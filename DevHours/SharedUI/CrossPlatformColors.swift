//
//  CrossPlatformColors.swift
//  DevHours
//
//  Cross-platform color definitions for iOS and macOS
//

import SwiftUI

#if os(macOS)
import AppKit
#else
import UIKit
#endif

extension Color {
    /// Secondary system background - adapts to platform
    static var secondarySystemBackground: Color {
        #if os(macOS)
        Color(nsColor: .windowBackgroundColor)
        #else
        Color(uiColor: .secondarySystemBackground)
        #endif
    }

    /// Primary system background
    static var systemBackground: Color {
        #if os(macOS)
        Color(nsColor: .textBackgroundColor)
        #else
        Color(uiColor: .systemBackground)
        #endif
    }

    /// Tertiary system background
    static var tertiarySystemBackground: Color {
        #if os(macOS)
        Color(nsColor: .controlBackgroundColor)
        #else
        Color(uiColor: .tertiarySystemBackground)
        #endif
    }

    /// System gray 6
    static var systemGray6: Color {
        #if os(macOS)
        Color(nsColor: .controlBackgroundColor)
        #else
        Color(uiColor: .systemGray6)
        #endif
    }

    /// Separator color
    static var separatorColor: Color {
        #if os(macOS)
        Color(nsColor: .separatorColor)
        #else
        Color(uiColor: .separator)
        #endif
    }
}
