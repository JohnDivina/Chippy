import Foundation
import SpriteKit
import ChippyCore

/// `@MainActor` director translating normalized `AgentEvent` streams into
/// truthful choreographies of walking, working, and speech bubbles in `ParadiseScene`.
/// Uses `ChoreographyQueue` for event pacing and `PathRouter` for semantically accurate district routing.
@MainActor
public final class SceneDirector {
    public let scene: ParadiseScene
    public let queue: ChoreographyQueue
    public let pathRouter: PathRouter

    public private(set) var activeModelName: String = "Observing Model..."
    public var knownSkills: [SkillWorkshop] = []

    public init(scene: ParadiseScene) {
        self.scene = scene
        self.queue = ChoreographyQueue(scene: scene)
        self.pathRouter = PathRouter()
    }

    /// Sets known skill workshops for truthful district matching.
    public func setKnownSkills(_ skills: [SkillWorkshop]) {
        self.knownSkills = skills
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
            queue.recordWorkshopActivity(landmarkKey: "citadel", taskName: "New Quest")
            let promptSummary = text.count > 45 ? String(text.prefix(42)) + "…" : text
            scene.familiarNode(for: .sovereign)?.showThought(text: "Quest: \(promptSummary)", duration: 5.0, isWorking: true)

        case .thinking:
            queue.recordWorkshopActivity(landmarkKey: DistrictID.highCouncil.rawValue, taskName: "Reasoning")
            scene.familiarNode(for: .sovereign)?.showThought(text: "Reasoning strategy…", duration: 4.0, isWorking: true)

        case .skillLoaded(_, let skillName):
            // Match skill's own designated district
            let matchedDistrict = knownSkills.first { $0.name.localizedCaseInsensitiveCompare(skillName) == .orderedSame }?.districtID
                ?? DistrictID.scriptorium
            let landmark = matchedDistrict.rawValue

            queue.recordWorkshopActivity(landmarkKey: landmark, taskName: skillName)
            queue.enqueue(ChoreographyAction(
                familiar: .scribe,
                taskName: "Equipped: \(skillName)",
                targetLandmark: landmark,
                targetGrid: GridPoint(col: -1, row: -2),
                duration: 2.2
            ))

        case .fileRead(_, let path):
            let filename = URL(fileURLWithPath: path).lastPathComponent
            queue.recordWorkshopActivity(landmarkKey: "harbor", taskName: filename)
            queue.enqueue(ChoreographyAction(
                familiar: .scout,
                taskName: "Inspecting \(filename)",
                targetLandmark: "harbor",
                targetGrid: GridPoint(col: -3, row: -2),
                duration: 2.0
            ))

        case .fileEdited(_, let path, let kind):
            let filename = URL(fileURLWithPath: path).lastPathComponent
            let route = pathRouter.route(filePath: path)
            let actionText = kind == .created ? "Created \(filename)" : "Crafted \(filename)"

            queue.recordWorkshopActivity(landmarkKey: route.landmarkKey, taskName: filename)

            let destGrid: GridPoint = {
                switch route.familiar {
                case .weaver: return GridPoint(col: -2, row: 2)
                case .sentinel: return GridPoint(col: 1, row: 3)
                case .scribe: return GridPoint(col: -1, row: -2)
                case .mason: return GridPoint(col: 2, row: -2)
                default: return GridPoint(col: 0, row: 0)
                }
            }()

            queue.enqueue(ChoreographyAction(
                familiar: route.familiar,
                taskName: actionText,
                targetLandmark: route.landmarkKey,
                targetGrid: destGrid,
                duration: 2.4
            ))

        case .commandRun(_, let command):
            let shortCmd = command.components(separatedBy: " ").first ?? "exec"
            queue.recordWorkshopActivity(landmarkKey: DistrictID.engineCore.rawValue, taskName: shortCmd)
            queue.enqueue(ChoreographyAction(
                familiar: .mason,
                taskName: "$ \(command)",
                targetLandmark: DistrictID.engineCore.rawValue,
                targetGrid: GridPoint(col: 2, row: -2),
                duration: 2.5
            ))

        case .toolCall(_, let tool, let summary):
            switch tool {
            case .search:
                queue.recordWorkshopActivity(landmarkKey: DistrictID.wanderersMarket.rawValue, taskName: "Search")
                queue.enqueue(ChoreographyAction(
                    familiar: .scout,
                    taskName: "Searching codebase…",
                    targetLandmark: DistrictID.wanderersMarket.rawValue,
                    targetGrid: GridPoint(col: 3, row: 1),
                    duration: 2.2
                ))
            case .ask:
                scene.familiarNode(for: .sovereign)?.showThought(text: "Awaiting clarification…", duration: 4.0)
            case .test:
                queue.recordWorkshopActivity(landmarkKey: DistrictID.ironBastion.rawValue, taskName: "Testing")
                queue.enqueue(ChoreographyAction(
                    familiar: .sentinel,
                    taskName: "Running test suite…",
                    targetLandmark: DistrictID.ironBastion.rawValue,
                    targetGrid: GridPoint(col: 1, row: 3),
                    duration: 2.5
                ))
            default:
                let shortSummary = summary.count > 45 ? String(summary.prefix(42)) + "…" : summary
                scene.familiarNode(for: .scout)?.showThought(text: shortSummary, duration: 3.5, isWorking: true)
            }

        case .subagentSpawned(_, _, let task):
            scene.spawnFamiliar(kind: .sentinel, at: GridPoint(col: 0, row: 0), landmark: "citadel")
            queue.recordWorkshopActivity(landmarkKey: DistrictID.ironBastion.rawValue, taskName: "Subagent")
            queue.enqueue(ChoreographyAction(
                familiar: .sentinel,
                taskName: "Subagent: \(task)",
                targetLandmark: DistrictID.ironBastion.rawValue,
                targetGrid: GridPoint(col: 1, row: 3),
                duration: 3.0
            ))

        case .agentMessage(_, let text):
            let firstLine = text.components(separatedBy: "\n").first ?? text
            let displaySummary = firstLine.count > 45 ? String(firstLine.prefix(42)) + "…" : firstLine
            scene.familiarNode(for: .sovereign)?.showThought(text: displaySummary, duration: 6.0)

        case .error(_, let message, let reason):
            if reason == .quotaExceeded || reason == .rateLimited {
                scene.familiarNode(for: .sovereign)?.showThought(text: "The Sovereign rests (Quota limit reached)", duration: 6.0)
            } else {
                let shortMsg = message.count > 45 ? String(message.prefix(42)) + "…" : message
                scene.familiarNode(for: .sovereign)?.showThought(text: "⚠️ \(shortMsg)", duration: 5.0)
            }

        case .commandFinished, .subagentFinished, .sessionEnded:
            break
        }
    }
}
