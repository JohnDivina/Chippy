import SwiftUI
import AppKit

@main
struct ChippyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1080, height: 720)
    }
}
