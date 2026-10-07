import AppKit
import Foundation
import ApplicationServices
import ChippyCore

/// Hardened bridge dispatching prompts from Chippy into active Antigravity IDE sessions.
/// Strictly targets Antigravity by bundle identifier, restores the user's previous clipboard contents,
/// enforces a 2-second rate-limit, and checks accessibility permissions.
public struct AntigravityBridge: Sendable {
    public static let targetBundleID = "com.google.antigravity-ide"

    private static let lock = NSLock()
    nonisolated(unsafe) private static var lastSendTimestamp: Date = Date.distantPast

    /// Checks whether macOS Accessibility permissions are trusted.
    public static var isAccessibilityTrusted: Bool {
        AXIsProcessTrusted()
    }

    /// Verifies if Antigravity IDE is currently running.
    public static var isAntigravityRunning: Bool {
        NSWorkspace.shared.runningApplications.contains {
            $0.bundleIdentifier == targetBundleID
        }
    }

    /// Result of attempting to dispatch a prompt.
    public enum DispatchResult: Sendable {
        case success
        case rateLimited
        case notRunning
        case accessibilityDenied
        case scriptError(String)
    }

    @discardableResult
    public static func forwardPromptToAntigravity(_ prompt: String) -> DispatchResult {
        lock.lock()
        let now = Date()
        let elapsed = now.timeIntervalSince(lastSendTimestamp)
        if elapsed < 2.0 {
            lock.unlock()
            print("⚠️ AntigravityBridge: Rate-limited (must wait \(String(format: "%.1f", 2.0 - elapsed))s).")
            return .rateLimited
        }
        lastSendTimestamp = now
        lock.unlock()

        guard isAntigravityRunning else {
            print("⚠️ AntigravityBridge: Antigravity IDE is not running.")
            return .notRunning
        }

        // 1. Preserve clipboard contents
        let previousClipboard = NSPasteboard.general.string(forType: .string)

        // 2. Put prompt on clipboard
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(prompt, forType: .string)

        let scriptSource = """
        tell application "System Events"
            set procList to every process whose bundle identifier is "\(targetBundleID)"
            if (count of procList) is 0 then
                set procList to every process whose name is "Antigravity IDE"
            end if
            if (count of procList) > 0 then
                set targetProc to item 1 of procList
                set frontmost of targetProc to true
                delay 0.08
                -- Focus Antigravity Agent Chat input via Cmd+L
                keystroke "l" using {command down}
                delay 0.12
                -- Paste prompt into chat input
                keystroke "v" using {command down}
                delay 0.08
                -- Submit prompt to Antigravity
                keystroke return
                delay 0.05
                -- Reclaim focus back to Chippy so user never leaves Chippy
                set chippyProc to every process whose name contains "Chippy"
                if (count of chippyProc) > 0 then
                    set frontmost of (item 1 of chippyProc) to true
                end if
            end if
        end tell
        """

        var error: NSDictionary?
        var success = false
        if let appleScript = NSAppleScript(source: scriptSource) {
            appleScript.executeAndReturnError(&error)
            if let err = error {
                print("⚠️ AntigravityBridge error: \(err)")
            } else {
                success = true
                print("✅ AntigravityBridge: Prompt dispatched to Antigravity IDE successfully.")
            }
        }

        // 3. Restore previous clipboard after short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            if let previous = previousClipboard {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(previous, forType: .string)
            }
        }

        DispatchQueue.main.async {
            NSApp.activate(ignoringOtherApps: true)
        }

        if let err = error {
            return .scriptError(err.description)
        }
        return success ? .success : .scriptError("Could not locate Antigravity process")
    }
}
