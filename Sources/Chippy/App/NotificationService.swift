import Foundation
import UserNotifications
import AppKit
import ChippyCore

/// Posts local macOS notifications when the agent requires attention, finishes a quest, or hits an error.
/// Automatically detects if running as a bundled .app (UNUserNotificationCenter) or raw binary via swift run.
@MainActor
public final class NotificationService {
    public static let shared = NotificationService()

    private var hasRequestedPermission = false

    private var isNotificationCenterAvailable: Bool {
        Bundle.main.bundleURL.pathExtension == "app" || Bundle.main.bundlePath.contains(".app/")
    }

    private init() {}

    /// Requests notification authorization from macOS when running in an app bundle.
    public func requestAuthorizationIfNeeded() {
        guard !hasRequestedPermission else { return }
        hasRequestedPermission = true

        guard isNotificationCenterAvailable else {
            // Running as raw terminal executable via `swift run`, UNUserNotificationCenter is not supported by macOS
            return
        }

        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            }
        }
    }

    /// Evaluates incoming AgentEvent and sends a notification if Chippy is not frontmost.
    public func handleEvent(_ event: AgentEvent, isAppActive: Bool) {
        guard UserDefaults.standard.bool(forKey: "enableNotifications") else { return }

        switch event {
        case .error(_, let message, let reason):
            if reason == .quotaExceeded {
                postNotification(
                    title: "Antigravity Quota Exceeded",
                    body: "The Sovereign has rested: \(message)",
                    category: "quota"
                )
            } else {
                postNotification(
                    title: "Council Obstacle",
                    body: message,
                    category: "error"
                )
            }

        case .toolCall(_, .ask, let summary):
            postNotification(
                title: "Council Needs Clarification",
                body: summary.isEmpty ? "Antigravity requires your input." : summary,
                category: "ask"
            )

        case .agentMessage(_, let text):
            // Only notify if app is in background and response arrived
            if !isAppActive {
                let firstLine = text.components(separatedBy: .newlines).first ?? "New answer available."
                postNotification(
                    title: "Council Dispatch Arrived",
                    body: firstLine,
                    category: "response"
                )
            }

        default:
            break
        }
    }

    private func postNotification(title: String, body: String, category: String) {
        if isNotificationCenterAvailable {
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            content.sound = .default

            let request = UNNotificationRequest(
                identifier: UUID().uuidString,
                content: content,
                trigger: nil // deliver immediately
            )

            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Failed to schedule notification: \(error.localizedDescription)")
                }
            }
        } else {
            // Safe fallback when running as raw binary via swift run
            NSApp.requestUserAttention(.informationalRequest)
        }
    }
}
