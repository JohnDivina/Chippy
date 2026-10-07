import SwiftUI
import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Promote process to a standard foreground GUI application
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)

        DispatchQueue.main.async {
            if let window = NSApp.windows.first {
                window.title = "Chippy — AI Paradise"
                window.level = .normal
                window.collectionBehavior = [.fullScreenAuxiliary]
                window.makeKeyAndOrderFront(nil)
                window.center()
            }
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false // Allow running via menu bar extra even if main window closes
    }
}

@main
struct ChippyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup("Chippy — AI Paradise") {
            ContentView(appState: appState)
        }
        .defaultSize(width: 1080, height: 720)

        // Menu Bar Mini Companion (Sprint D2)
        MenuBarExtra("Chippy", systemImage: "sparkles") {
            MenuBarView(appState: appState) {
                DispatchQueue.main.async {
                    if let window = NSApp.windows.first {
                        window.makeKeyAndOrderFront(nil)
                        NSApp.activate(ignoringOtherApps: true)
                    }
                }
            }
        }
        .menuBarExtraStyle(.window)
    }
}
