import Foundation
import ChippyCore

/// Bridges prompt dispatching from Chippy into active Antigravity IDE sessions.
/// Sends prompts seamlessly in the background via Antigravity's native `agentapi`
/// without switching windows, closing Chippy, or tampering with the clipboard.
public struct AntigravityBridge: Sendable {
    public static func forwardPromptToAntigravity(_ prompt: String) {
        DispatchQueue.global(qos: .userInitiated).async {
            // 1. Locate active Antigravity conversation ID
            guard let conversationID = SessionLocator().findLatestConversationID() else {
                print("ℹ️ AntigravityBridge: No active Antigravity session found in brain directory.")
                return
            }

            // 2. Locate agentapi executable
            let agentAPIPath = FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent(".gemini/antigravity-ide/bin/agentapi").path

            guard FileManager.default.isExecutableFile(atPath: agentAPIPath) else {
                print("⚠️ AntigravityBridge: agentapi binary not found at \(agentAPIPath)")
                return
            }

            let process = Process()
            process.executableURL = URL(fileURLWithPath: agentAPIPath)
            process.arguments = ["send-message", "--title=Chippy Quest", conversationID, prompt]

            do {
                try process.run()
                process.waitUntilExit()
                print("✅ AntigravityBridge: Prompt seamlessly delivered to conversation \(conversationID) (exit: \(process.terminationStatus))")
            } catch {
                print("⚠️ AntigravityBridge: Failed to execute agentapi: \(error)")
            }
        }
    }
}
