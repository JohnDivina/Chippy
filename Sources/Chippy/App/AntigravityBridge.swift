import AppKit
import Foundation

/// Bridges prompt dispatching from Chippy into active Antigravity IDE sessions using macOS system automation.
public struct AntigravityBridge: Sendable {
    public static func forwardPromptToAntigravity(_ prompt: String) {
        let escaped = prompt
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")

        DispatchQueue.main.async {
            let scriptSource = """
            tell application "System Events"
                set procList to every process whose name is "Electron"
                if (count of procList) > 0 then
                    set targetProc to item 1 of procList
                    set frontmost of targetProc to true
                    delay 0.12
                    set the clipboard to "\(escaped)"
                    keystroke "v" using {command down}
                    delay 0.08
                    keystroke return
                end if
            end tell
            """

            var error: NSDictionary?
            if let appleScript = NSAppleScript(source: scriptSource) {
                appleScript.executeAndReturnError(&error)
            }
        }
    }
}
