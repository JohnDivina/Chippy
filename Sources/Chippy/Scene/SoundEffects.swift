import AppKit

/// Manages native macOS acoustic feedback for Chippy interactions and milestones.
/// Uses built-in system sounds without external dependencies or bundled audio files.
@MainActor
public final class SoundEffects {
    public static let shared = SoundEffects()

    private init() {
        if UserDefaults.standard.object(forKey: "soundEffectsEnabled") == nil {
            UserDefaults.standard.set(true, forKey: "soundEffectsEnabled")
        }
    }

    public var isEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "soundEffectsEnabled") }
        set { UserDefaults.standard.set(newValue, forKey: "soundEffectsEnabled") }
    }

    /// Plays a clear bell chime when a decision is requested at the podium.
    public func playDecisionAlert() {
        guard isEnabled else { return }
        NSSound(named: "Glass")?.play()
    }

    /// Plays a triumphant chime when a quest or task is completed.
    public func playQuestCompleted() {
        guard isEnabled else { return }
        NSSound(named: "Hero")?.play()
    }

    /// Plays a soft pop when a prompt is dispatched.
    public func playPromptSent() {
        guard isEnabled else { return }
        NSSound(named: "Pop")?.play()
    }

    /// Plays a crisp wooden tap when a crate is delivered to Harbor.
    public func playCrateCrafted() {
        guard isEnabled else { return }
        NSSound(named: "Tink")?.play()
    }
}
