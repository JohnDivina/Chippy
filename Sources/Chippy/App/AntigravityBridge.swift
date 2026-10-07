import AppKit
import Foundation

/// Bridges prompt dispatching from Chippy into active Antigravity IDE sessions.
/// Dispatches prompts directly via Antigravity's native CLI IPC, ensuring prompts
/// land directly in the AI Chat session rather than spilling into open terminal tabs.
public struct AntigravityBridge: Sendable {
    public static func forwardPromptToAntigravity(_ prompt: String) {
        DispatchQueue.global(qos: .userInitiated).async {
            // 1. Locate antigravity CLI binary
            let candidatePaths = [
                "/opt/homebrew/bin/antigravity",
                "/usr/local/bin/antigravity",
                "/usr/bin/antigravity",
                FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("bin/antigravity").path
            ]
            let cliPath = candidatePaths.first { FileManager.default.isExecutableFile(atPath: $0) }

            if let cliPath {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: cliPath)
                process.arguments = ["chat", "-r", prompt]

                do {
                    try process.run()
                    process.waitUntilExit()
                    print("✅ AntigravityBridge: Prompt forwarded directly to Chat via antigravity CLI (status: \(process.terminationStatus))")
                    bringAntigravityToFront()
                    return
                } catch {
                    print("⚠️ AntigravityBridge: CLI execution encountered error: \(error)")
                }
            }

            // 2. Fallback to AppleScript targeting Antigravity IDE
            forwardViaAppleScript(prompt)
        }
    }

    private static func bringAntigravityToFront() {
        DispatchQueue.main.async {
            for app in NSWorkspace.shared.runningApplications {
                let name = app.localizedName ?? ""
                let bundle = app.bundleIdentifier ?? ""
                if name == "Electron" || name.contains("Antigravity") || bundle.contains("antigravity") {
                    app.activate()
                    break
                }
            }
        }
    }

    private static func forwardViaAppleScript(_ prompt: String) {
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
                    delay 0.15
                    keystroke "p" using {command down, shift down}
                    delay 0.15
                    keystroke "Chat: Focus on Chat View"
                    delay 0.1
                    keystroke return
                    delay 0.15
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
                if let error = error {
                    print("⚠️ AntigravityBridge fallback AppleScript error: \(error)")
                } else {
                    print("✅ AntigravityBridge: Fallback AppleScript dispatched successfully.")
                }
            }
        }
    }
}
