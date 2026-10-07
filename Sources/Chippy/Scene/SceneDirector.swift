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
                scene.familiarNode(for: .sovereign)?.showThought(text: "Awakened: \(model)", duration: 4.0)
            }

        case .userPrompt(let text):
            scene.setWorkshopWorking(key: "citadel", isWorking: true, task: "New Quest")
            scene.familiarNode(for: .sovereign)?.showThought(text: "Quest: \(text)", duration: 5.0, isWorking: true)

        case .thinking:
            scene.setWorkshopWorking(key: DistrictID.highCouncil.rawValue, isWorking: true, task: "Reasoning")
            scene.familiarNode(for: .sovereign)?.showThought(text: "Reasoning strategy…", duration: 4.0, isWorking: true)

        case .skillLoaded(_, let skillName):
            let targetDistrict = DistrictID.scriptorium.rawValue
            scene.setWorkshopWorking(key: targetDistrict, isWorking: true, task: skillName)
            scene.moveFamiliar(.scribe, toLandmark: targetDistrict, targetGrid: GridPoint(col: -1, row: -2)) { [weak self] in
                self?.scene.familiarNode(for: .scribe)?.performWork(taskName: "Equipped: \(skillName)", duration: 2.2)
            }

        case .fileRead(_, let path):
            let filename = URL(fileURLWithPath: path).lastPathComponent
            scene.setWorkshopWorking(key: "harbor", isWorking: true, task: filename)
            scene.moveFamiliar(.scout, toLandmark: "harbor", targetGrid: GridPoint(col: -3, row: -2)) { [weak self] in
                self?.scene.familiarNode(for: .scout)?.performWork(taskName: "Inspecting \(filename)", duration: 2.0)
            }

        case .fileEdited(_, let path, let kind):
            let filename = URL(fileURLWithPath: path).lastPathComponent
            let isFrontend = path.hasSuffix(".tsx") || path.hasSuffix(".jsx") || path.hasSuffix(".css") || path.hasSuffix(".html") || path.hasSuffix("View.swift")
            let familiar: FamiliarKind = isFrontend ? .weaver : .mason
            let landmark = isFrontend ? DistrictID.grandAtelier.rawValue : DistrictID.ironBastion.rawValue
            let actionText = kind == .created ? "Created \(filename)" : "Crafted \(filename)"

            scene.setWorkshopWorking(key: landmark, isWorking: true, task: filename)
            let destGrid = isFrontend ? GridPoint(col: -2, row: 2) : GridPoint(col: 1, row: 3)
            scene.moveFamiliar(familiar, toLandmark: landmark, targetGrid: destGrid) { [weak self] in
                self?.scene.familiarNode(for: familiar)?.performWork(taskName: actionText, duration: 2.4)
            }

        case .commandRun(_, let command):
            let shortCmd = command.components(separatedBy: " ").first ?? "exec"
            scene.setWorkshopWorking(key: DistrictID.engineCore.rawValue, isWorking: true, task: shortCmd)
            scene.moveFamiliar(.mason, toLandmark: DistrictID.engineCore.rawValue, targetGrid: GridPoint(col: 2, row: -2)) { [weak self] in
                self?.scene.familiarNode(for: .mason)?.performWork(taskName: "$ \(command)", duration: 2.5)
            }

        case .toolCall(_, let tool, let summary):
            switch tool {
            case .search:
                scene.setWorkshopWorking(key: DistrictID.wanderersMarket.rawValue, isWorking: true, task: "Search")
                scene.familiarNode(for: .scout)?.performWork(taskName: "Searching codebase…", duration: 2.2)
            case .ask:
                scene.familiarNode(for: .sovereign)?.showThought(text: "Awaiting clarification…", duration: 4.0)
            case .test:
                scene.setWorkshopWorking(key: DistrictID.ironBastion.rawValue, isWorking: true, task: "Testing")
                scene.familiarNode(for: .sentinel)?.performWork(taskName: "Running test suite…", duration: 2.5)
            default:
                scene.familiarNode(for: .scout)?.showThought(text: summary, duration: 3.5, isWorking: true)
            }

        case .subagentSpawned(_, _, let task):
            scene.spawnFamiliar(kind: .sentinel, at: GridPoint(col: 0, row: 0), landmark: "citadel")
            scene.setWorkshopWorking(key: DistrictID.ironBastion.rawValue, isWorking: true, task: "Subagent")
            scene.moveFamiliar(.sentinel, toLandmark: DistrictID.ironBastion.rawValue, targetGrid: GridPoint(col: 1, row: 3)) { [weak self] in
                self?.scene.familiarNode(for: .sentinel)?.performWork(taskName: "Subagent: \(task)", duration: 3.0)
            }

        case .agentMessage(_, let text):
            let summary = text.components(separatedBy: "\n").first ?? text
            scene.familiarNode(for: .sovereign)?.showThought(text: summary, duration: 5.0)

            // Settle workshops back to peaceful state after message delivery
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
                self?.scene.setAllWorkshopsWorking(false)
            }

        case .error(_, let message):
            scene.familiarNode(for: .sovereign)?.showThought(text: "⚠️ \(message)", duration: 4.5)

        case .commandFinished, .subagentFinished, .sessionEnded:
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                self?.scene.setAllWorkshopsWorking(false)
            }
        }
    }
}
