import SpriteKit
import AppKit
import ChippyCore

/// Represents a physical workshop cottage or landmark on the Stardew Valley-inspired island.
/// Features authentic wooden carved village signboards, warm window lantern glow, and active
/// chimney smoke / forge animations representing the world working when an AI prompt is active.
public final class WorkshopNode: SKNode {
    public let districtID: DistrictID?
    public let title: String
    public let landmarkKind: LandmarkKind

    public enum LandmarkKind: Sendable, Equatable {
        case citadel
        case harbor
        case podium
        case district(DistrictID)
    }

    private let structureContainer = SKNode()
    private var buildingSprite: SKSpriteNode?
    private var signBoardNode: SKNode?
    private var signLabel: SKLabelNode?
    private var signStatusDot: SKShapeNode?
    private var windowGlowNode: SKShapeNode?
    private var smokeEmitterTaskKey = "chimneySmoke"

    public private(set) var isWorking: Bool = false

    public init(kind: LandmarkKind, title: String) {
        self.landmarkKind = kind
        self.title = title
        if case .district(let id) = kind {
            self.districtID = id
        } else {
            self.districtID = nil
        }

        super.init()

        addChild(structureContainer)
        buildStructure()
        buildSignboard()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func buildStructure() {
        let texture: SKTexture = {
            switch landmarkKind {
            case .citadel:
                return PixelArtAtlas.shared.citadelCottage()
            case .harbor:
                return PixelArtAtlas.shared.woodenFence()
            case .podium:
                return PixelArtAtlas.shared.decisionPodium()
            case .district(let id):
                switch id {
                case .highCouncil:
                    return PixelArtAtlas.shared.citadelCottage()
                case .ironBastion:
                    return PixelArtAtlas.shared.ironBastionForge()
                case .grandAtelier:
                    return PixelArtAtlas.shared.grandAtelierCottage()
                case .engineCore:
                    return PixelArtAtlas.shared.engineCoreMill()
                case .scriptorium:
                    return PixelArtAtlas.shared.scriptoriumArchive()
                case .wanderersMarket:
                    return PixelArtAtlas.shared.wanderersMarketStalls()
                }
            }
        }()

        // Ground shadow
        let shadow = SKShapeNode(ellipseOf: CGSize(width: 54, height: 16))
        shadow.fillColor = NSColor.black.withAlphaComponent(0.22)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: 0, y: 4)
        shadow.zPosition = -1
        structureContainer.addChild(shadow)

        // Cottage Sprite with nearest-neighbor crispness
        let sprite = SKSpriteNode(texture: texture)
        sprite.anchorPoint = CGPoint(x: 0.5, y: 0.15) // Anchored on the ground tile
        sprite.position = CGPoint(x: 0, y: 0)
        structureContainer.addChild(sprite)
        self.buildingSprite = sprite
    }

    // MARK: - Stardew Valley Wooden Village Signboard

    private func buildSignboard() {
        let board = SKNode()

        let displayText = title
        let textWidth = CGFloat(max(displayText.count * 6 + 20, 52))
        let boardHeight: CGFloat = 16

        // Drop shadow for the wooden sign
        let boardShadow = SKShapeNode(rectOf: CGSize(width: textWidth, height: boardHeight), cornerRadius: 3)
        boardShadow.fillColor = NSColor.black.withAlphaComponent(0.3)
        boardShadow.strokeColor = .clear
        boardShadow.position = CGPoint(x: 0, y: -1)
        board.addChild(boardShadow)

        // Carved rustic oak wood backing
        let woodBacking = SKShapeNode(rectOf: CGSize(width: textWidth, height: boardHeight), cornerRadius: 3)
        woodBacking.fillColor = NSColor(red: 0.22, green: 0.14, blue: 0.08, alpha: 0.95)
        woodBacking.strokeColor = NSColor(red: 0.46, green: 0.32, blue: 0.18, alpha: 1.0)
        woodBacking.lineWidth = 1.0
        board.addChild(woodBacking)

        // Status indicator dot (active working beacon)
        let dot = SKShapeNode(circleOfRadius: 2.5)
        dot.fillColor = NSColor(white: 0.5, alpha: 0.4) // Dim when idle
        dot.strokeColor = .clear
        dot.position = CGPoint(x: -textWidth / 2 + 7, y: 0)
        board.addChild(dot)
        self.signStatusDot = dot

        // Clean cream/gold lettered sign text
        let label = SKLabelNode(text: displayText)
        label.fontName = NSFont.monospacedSystemFont(ofSize: 7.5, weight: .bold).fontName
        label.fontSize = 7.5
        label.fontColor = NSColor(red: 0.95, green: 0.92, blue: 0.82, alpha: 1.0)
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .left
        label.position = CGPoint(x: -textWidth / 2 + 14, y: 0)
        board.addChild(label)
        self.signLabel = label

        // Mount signboard near the facade roofline
        board.position = CGPoint(x: 0, y: landmarkKind == .podium ? 28 : 46)
        board.zPosition = 8
        structureContainer.addChild(board)
        self.signBoardNode = board
    }

    // MARK: - Active World Working State

    /// Activates or settles the workshop's working graphical state when an AI prompt is active.
    public func setActiveWorking(_ working: Bool, taskDescription: String? = nil) {
        self.isWorking = working

        if working {
            // 1. Solid active indicator (discrete solid dot, no glowing halo)
            signStatusDot?.fillColor = NSColor(white: 0.92, alpha: 1.0)

            if let task = taskDescription, !task.isEmpty {
                let maxLen = 14
                let shortTask = task.count > maxLen ? String(task.prefix(maxLen)) : task
                signLabel?.text = "\(title) • \(shortTask)"
            } else {
                signLabel?.text = "\(title) (Active)"
            }

            // 2. Start Chimney Smoke puffs (physical motion instead of glow)
            startChimneySmoke()

            // 3. Subtle bounce on start
            let bounceUp = SKAction.scale(to: 1.04, duration: 0.12)
            let bounceDown = SKAction.scale(to: 1.0, duration: 0.16)
            structureContainer.run(SKAction.sequence([bounceUp, bounceDown]))

        } else {
            // Settle down to peaceful village state
            signStatusDot?.fillColor = NSColor(white: 0.5, alpha: 0.4)
            signLabel?.text = title

            removeAction(forKey: smokeEmitterTaskKey)
        }
    }

    private func startChimneySmoke() {
        removeAction(forKey: smokeEmitterTaskKey)

        let chimneyPos = CGPoint(x: 12, y: 56)

        let spawnPuff = SKAction.run { [weak self] in
            guard let self else { return }
            let puff = SKShapeNode(circleOfRadius: CGFloat.random(in: 2.5...4.0))
            puff.fillColor = NSColor(white: 0.92, alpha: 0.5)
            puff.strokeColor = .clear
            puff.position = chimneyPos
            puff.zPosition = 6
            self.structureContainer.addChild(puff)

            let driftX = CGFloat.random(in: -6...8)
            let riseAction = SKAction.moveBy(x: driftX, y: 26, duration: 1.6)
            let growAction = SKAction.scale(by: 1.8, duration: 1.6)
            let fadeAction = SKAction.fadeOut(withDuration: 1.6)
            let group = SKAction.group([riseAction, growAction, fadeAction])

            puff.run(SKAction.sequence([group, SKAction.removeFromParent()]))
        }

        let loop = SKAction.repeatForever(SKAction.sequence([
            spawnPuff,
            SKAction.wait(forDuration: 0.55)
        ]))

        run(loop, withKey: smokeEmitterTaskKey)
    }

    /// Triggers an activation bounce when a skill inside this workshop is used.
    public func activateWorkshop() {
        let pulseUp = SKAction.scale(to: 1.06, duration: 0.12)
        let pulseDown = SKAction.scale(to: 1.0, duration: 0.20)
        pulseUp.timingMode = .easeInEaseOut
        pulseDown.timingMode = .easeInEaseOut
        structureContainer.run(SKAction.sequence([pulseUp, pulseDown]))
    }
}

