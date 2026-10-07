import Foundation
import SpriteKit
import ChippyCore

/// `@MainActor` director translating normalized `AgentEvent` streams into
/// choreographies of walking, working, and speech bubbles in `ParadiseScene`.
@MainActor
public final class SceneDirector {
    public let scene: ParadiseScene
    public private(set) var activeModelName: String = "Observing Model..."

    public init(scene: ParadiseScene) {
        self.scene = scene
    }

    /// Processes an incoming AgentEvent and directs the scene entities accordingly.
    public func handleEvent(_ event: AgentEvent) {
        switch event {
        case .sessionStarted(_, let model, _):
            if let model, !model.isEmpty {
                self.activeModelName = model
                scene.familiarNode(for: .sovereign)?.showThought(text: "Awakened: \(model)")
            }

        case .userPrompt(let text):
            scene.familiarNode(for: .sovereign)?.showThought(text: text)

        case .thinking:
            scene.familiarNode(for: .sovereign)?.showThought(text: "Reasoning strategy…")

        case .skillLoaded(_, let skillName):
            // Scribe visits matching district workshop
            let targetDistrict = DistrictID.highCouncil.rawValue
            scene.moveFamiliar(.scribe, toLandmark: targetDistrict, targetGrid: GridPoint(col: 2, row: 1)) { [weak self] in
                self?.scene.familiarNode(for: .scribe)?.performWork(taskName: "Equipped: \(skillName)")
            }

        case .fileRead(_, let path):
            let filename = URL(fileURLWithPath: path).lastPathComponent
            scene.moveFamiliar(.scout, toLandmark: "harbor", targetGrid: GridPoint(col: -3, row: -2)) { [weak self] in
                self?.scene.familiarNode(for: .scout)?.performWork(taskName: "Read \(filename)")
            }

        case .fileEdited(_, let path, let kind):
            let filename = URL(fileURLWithPath: path).lastPathComponent
            let isFrontend = path.hasSuffix(".tsx") || path.hasSuffix(".jsx") || path.hasSuffix(".css") || path.hasSuffix(".html") || path.hasSuffix("View.swift")
            let familiar: FamiliarKind = isFrontend ? .weaver : .mason
            let actionText = kind == .created ? "Created \(filename)" : "Updated \(filename)"

            scene.moveFamiliar(familiar, toLandmark: "harbor", targetGrid: GridPoint(col: -2, row: -3)) { [weak self] in
                self?.scene.familiarNode(for: familiar)?.performWork(taskName: actionText)
            }

        case .commandRun(_, let command):
            let shortCmd = command.components(separatedBy: " ").first ?? "exec"
            scene.moveFamiliar(.mason, toLandmark: DistrictID.engineCore.rawValue, targetGrid: GridPoint(col: 2, row: -2)) { [weak self] in
                self?.scene.familiarNode(for: .mason)?.performWork(taskName: "$ \(shortCmd)")
            }

        case .toolCall(_, let tool, let summary):
            switch tool {
            case .search:
                scene.familiarNode(for: .scout)?.performWork(taskName: "Searching codebase…")
            case .ask:
                scene.familiarNode(for: .sovereign)?.showThought(text: "Awaiting clarification…")
            case .test:
                scene.familiarNode(for: .sentinel)?.performWork(taskName: "Running test suite…")
            default:
                scene.familiarNode(for: .scout)?.showThought(text: summary)
            }

        case .subagentSpawned(_, _, let task):
            scene.spawnFamiliar(kind: .sentinel, at: GridPoint(col: 0, row: 0), landmark: "citadel")
            scene.moveFamiliar(.sentinel, toLandmark: DistrictID.ironBastion.rawValue, targetGrid: GridPoint(col: 1, row: 3)) { [weak self] in
                self?.scene.familiarNode(for: .sentinel)?.showThought(text: "Assigned: \(task)")
            }

        case .agentMessage(_, let text):
            let summary = text.components(separatedBy: "\n").first ?? text
            scene.familiarNode(for: .sovereign)?.showThought(text: summary)

        case .error(_, let message):
            scene.familiarNode(for: .sovereign)?.showThought(text: "⚠️ \(message)")

        case .commandFinished, .subagentFinished, .sessionEnded:
            break
        }
    }
}
