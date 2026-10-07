import AppKit
import Foundation
import ChippyCore

/// Bridges prompt dispatching from Chippy into active Antigravity IDE sessions.
/// Dispatches the prompt directly into Antigravity's Agent Chat panel via Cmd+L focus,
/// while keeping Chippy pinned as a Floating HUD so Chippy never closes or vanishes.
public struct AntigravityBridge: Sendable {
    public static func forwardPromptToAntigravity(_ prompt: String) {
        // 1. Deliver to Antigravity via Agent Chat keystroke bridge
        DispatchQueue.main.async {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(prompt, forType: .string)

            let scriptSource = """
            tell application "System Events"
                set procList to every process whose name is "Electron"
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
            if let appleScript = NSAppleScript(source: scriptSource) {
                appleScript.executeAndReturnError(&error)
                if let error = error {
                    print("⚠️ AntigravityBridge AppleScript error: \(error)")
                } else {
                    print("✅ AntigravityBridge: Prompt dispatched to Antigravity Chat successfully.")
                }
            }

            NSApp.activate(ignoringOtherApps: true)
        }
    }
}
