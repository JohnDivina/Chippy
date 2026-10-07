import SwiftUI
import AppKit

/// Design tokens strictly conforming to the workspace anti-slop guidelines:
/// solid grey bubbles, high contrast, zero neon/glowing accents.
public enum ChippyTheme {
    // Surfaces
    public static let surfacePrimary = Color(nsColor: NSColor(name: nil) { appearance in
        appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            ? NSColor(red: 0.07, green: 0.07, blue: 0.07, alpha: 1.0) // #121212
            : NSColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)    // #FFFFFF
    })

    public static let surfaceBubble = Color(nsColor: NSColor(name: nil) { appearance in
        appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            ? NSColor(red: 0.094, green: 0.094, blue: 0.094, alpha: 1.0) // #181818
            : NSColor(red: 0.96, green: 0.96, blue: 0.96, alpha: 1.0)    // #F5F5F5
    })

    // Borders
    public static let borderSubtle = Color(nsColor: NSColor(name: nil) { appearance in
        appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            ? NSColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1.0) // #262626
            : NSColor(red: 0.90, green: 0.90, blue: 0.90, alpha: 1.0) // #E5E5E5
    })

    // Typography
    public static let textPrimary = Color(nsColor: NSColor(name: nil) { appearance in
        appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            ? NSColor(red: 0.90, green: 0.90, blue: 0.90, alpha: 1.0) // #E5E5E5
            : NSColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1.0) // #262626
    })

    public static let textMuted = Color(nsColor: NSColor(name: nil) { appearance in
        appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            ? NSColor(red: 0.60, green: 0.60, blue: 0.60, alpha: 1.0)
            : NSColor(red: 0.45, green: 0.45, blue: 0.45, alpha: 1.0)
    })

    // Accents & Indicators
    public static let accentSolid = Color(nsColor: NSColor(name: nil) { appearance in
        appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            ? NSColor.white
            : NSColor.black
    })

    public static let statusDot = Color(nsColor: NSColor(name: nil) { appearance in
        appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            ? NSColor.white
            : NSColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0)
    })
}
