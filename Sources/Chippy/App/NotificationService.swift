import Foundation
import UserNotifications
import AppKit
import ChippyCore

/// Posts local macOS notifications when the agent requires attention, finishes a quest, or hits an error.
@MainActor
public final class NotificationService {
    public static let shared = NotificationService()

    private var hasRequestedPermission = false

    private init() {}

    /// Requests notification authorization from macOS.
    public func requestAuthorizationIfNeeded() {
        guard !hasRequestedPermission else { return }
        hasRequestedPermission = true

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
    }
}
