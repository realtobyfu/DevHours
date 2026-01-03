//
//  ColorHelpers.swift
//  DevHours
//
//  Utilities for tag colors including preset palette and hex conversion.
//

import SwiftUI

// MARK: - Preset Color Palette

struct TagColor: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let hex: String

    var color: Color {
        Color.fromHex(hex)
    }
}

enum TagColors {
    static let presets: [TagColor] = [
        TagColor(name: "Red", hex: "#E53935"),
        TagColor(name: "Orange", hex: "#FB8C00"),
        TagColor(name: "Yellow", hex: "#FDD835"),
        TagColor(name: "Green", hex: "#43A047"),
        TagColor(name: "Teal", hex: "#00897B"),
        TagColor(name: "Blue", hex: "#1E88E5"),
        TagColor(name: "Indigo", hex: "#5E35B1"),
        TagColor(name: "Purple", hex: "#8E24AA"),
        TagColor(name: "Pink", hex: "#D81B60"),
        TagColor(name: "Gray", hex: "#757575")
    ]

    static var defaultHex: String {
        presets.first?.hex ?? "#1E88E5"
    }
}

// MARK: - Color Extensions

extension Color {
    /// Creates a Color from a hex string (e.g., "#E53935" or "E53935")
    static func fromHex(_ hex: String) -> Color {
        let cleanHex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: cleanHex).scanHexInt64(&int)

        let r, g, b: Double
        switch cleanHex.count {
        case 6: // RGB (24-bit)
            r = Double((int >> 16) & 0xFF) / 255.0
            g = Double((int >> 8) & 0xFF) / 255.0
            b = Double(int & 0xFF) / 255.0
        case 8: // ARGB (32-bit)
            r = Double((int >> 16) & 0xFF) / 255.0
            g = Double((int >> 8) & 0xFF) / 255.0
            b = Double(int & 0xFF) / 255.0
        default:
            r = 0; g = 0; b = 0
        }

        return Color(red: r, green: g, blue: b)
    }

    /// Converts a Color to a hex string
    func toHex() -> String {
        #if os(iOS)
        let uiColor = UIColor(self)
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        #else
        let nsColor = NSColor(self).usingColorSpace(.deviceRGB) ?? NSColor.gray
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        nsColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        #endif

        return String(
            format: "#%02X%02X%02X",
            Int(r * 255),
            Int(g * 255),
            Int(b * 255)
        )
    }
}
