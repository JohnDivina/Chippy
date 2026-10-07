import SpriteKit
import AppKit
import ChippyCore

/// Visual SpriteKit node representing an animated creature (Sovereign or Familiar)
/// in the 2.5D diorama.
public final class CreatureNode: SKNode {
    public let familiarKind: FamiliarKind
    public var gridPosition: GridPoint

    private let bodyContainer = SKNode()
    private let shadowNode: SKShapeNode
    private var thoughtBubbleNode: SKNode?

    public init(kind: FamiliarKind, initialGrid: GridPoint = GridPoint(col: 0, row: 0)) {
        self.familiarKind = kind
        self.gridPosition = initialGrid

        // 1. Soft oval shadow
        let shadow = SKShapeNode(ellipseOf: CGSize(width: 22, height: 10))
        shadow.fillColor = NSColor.black.withAlphaComponent(0.2)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: 0, y: -2)
        self.shadowNode = shadow

        super.init()

        addChild(shadow)
        addChild(bodyContainer)

        buildProceduralVisuals()
        startIdleAnimation()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Procedural Visuals

    private func buildProceduralVisuals() {
        let (bodyColor, accentColor, accessorySymbol) = colorScheme(for: familiarKind)

        // Main torso/body
        let body = SKShapeNode(rectOf: CGSize(width: 18, height: 22), cornerRadius: 6)
        body.fillColor = bodyColor
        body.strokeColor = NSColor(white: 0.1, alpha: 0.4)
        body.lineWidth = 1.0
        body.position = CGPoint(x: 0, y: 12)
        bodyContainer.addChild(body)

        // Head/Crest
        let head = SKShapeNode(circleOfRadius: 8)
        head.fillColor = accentColor
        head.strokeColor = NSColor(white: 0.1, alpha: 0.4)
        head.lineWidth = 1.0
        head.position = CGPoint(x: 0, y: 26)
        bodyContainer.addChild(head)

        // Face eyes (crisp discrete dots)
        let leftEye = SKShapeNode(circleOfRadius: 1.2)
        leftEye.fillColor = NSColor(white: 0.1, alpha: 0.9)
        leftEye.strokeColor = .clear
        leftEye.position = CGPoint(x: -2.5, y: 26)
        bodyContainer.addChild(leftEye)

        let rightEye = SKShapeNode(circleOfRadius: 1.2)
        rightEye.fillColor = NSColor(white: 0.1, alpha: 0.9)
        rightEye.strokeColor = .clear
        rightEye.position = CGPoint(x: 2.5, y: 26)
        bodyContainer.addChild(rightEye)

        // Class accessory badge
        let badge = SKLabelNode(text: accessorySymbol)
        badge.fontSize = 9
        badge.position = CGPoint(x: 0, y: 8)
        badge.verticalAlignmentMode = .center
        bodyContainer.addChild(badge)
    }

    private func colorScheme(for kind: FamiliarKind) -> (body: NSColor, accent: NSColor, symbol: String) {
        switch kind {
        case .sovereign:
            return (NSColor(white: 0.20, alpha: 1.0), NSColor(white: 0.85, alpha: 1.0), "👑")
        case .scout:
            return (NSColor(red: 0.35, green: 0.40, blue: 0.35, alpha: 1.0), NSColor(white: 0.75, alpha: 1.0), "🏹")
        case .scribe:
            return (NSColor(red: 0.38, green: 0.34, blue: 0.28, alpha: 1.0), NSColor(white: 0.80, alpha: 1.0), "📜")
        case .mason:
            return (NSColor(red: 0.30, green: 0.32, blue: 0.36, alpha: 1.0), NSColor(white: 0.70, alpha: 1.0), "⚒️")
        case .weaver:
            return (NSColor(red: 0.40, green: 0.32, blue: 0.40, alpha: 1.0), NSColor(white: 0.82, alpha: 1.0), "🎨")
        case .sentinel:
            return (NSColor(red: 0.25, green: 0.28, blue: 0.32, alpha: 1.0), NSColor(white: 0.90, alpha: 1.0), "🛡️")
        case .arbiter:
            return (NSColor(red: 0.28, green: 0.30, blue: 0.30, alpha: 1.0), NSColor(white: 0.75, alpha: 1.0), "⚖️")
        }
    }

    // MARK: - Animations

    public func startIdleAnimation() {
        bodyContainer.removeAction(forKey: "idle")
        let bobUp = SKAction.moveBy(x: 0, y: 2.5, duration: 1.0)
        bobUp.timingMode = .easeInEaseOut
        let bobDown = SKAction.moveBy(x: 0, y: -2.5, duration: 1.0)
        bobDown.timingMode = .easeInEaseOut
        let sequence = SKAction.sequence([bobUp, bobDown])
        bodyContainer.run(SKAction.repeatForever(sequence), withKey: "idle")
    }

    public func walk(to targetPosition: CGPoint, newGrid: GridPoint, duration: TimeInterval = 0.8, completion: (@MainActor @Sendable () -> Void)? = nil) {
        bodyContainer.removeAction(forKey: "idle")

        // Face travel direction
        let movingLeft = targetPosition.x < position.x
        bodyContainer.xScale = movingLeft ? -1.0 : 1.0

        // Walking bob
        let stepUp = SKAction.moveBy(x: 0, y: 4, duration: 0.15)
        let stepDown = SKAction.moveBy(x: 0, y: -4, duration: 0.15)
        let walkBob = SKAction.repeatForever(SKAction.sequence([stepUp, stepDown]))
        bodyContainer.run(walkBob, withKey: "walkBob")

        let moveAction = SKAction.move(to: targetPosition, duration: duration)
        moveAction.timingMode = .easeInEaseOut

        run(moveAction) { [weak self] in
            guard let self else { return }
            self.gridPosition = newGrid
            self.bodyContainer.removeAction(forKey: "walkBob")
            self.bodyContainer.position = .zero
            self.startIdleAnimation()
            completion?()
        }
    }

    public func performWork(taskName: String, duration: TimeInterval = 1.2, completion: (@MainActor @Sendable () -> Void)? = nil) {
        showThought(text: taskName)

        let jump = SKAction.moveBy(x: 0, y: 5, duration: 0.2)
        jump.timingMode = .easeOut
        let land = SKAction.moveBy(x: 0, y: -5, duration: 0.2)
        land.timingMode = .easeIn
        let workAction = SKAction.repeat(SKAction.sequence([jump, land]), count: Int(duration / 0.4))

        bodyContainer.run(workAction) { [weak self] in
            self?.startIdleAnimation()
            completion?()
        }
    }

    public func showThought(text: String) {
        thoughtBubbleNode?.removeFromParent()

        let bubble = SKNode()
        let maxLen = 28
        let displayText = text.count > maxLen ? String(text.prefix(maxLen)) + "…" : text

        let label = SKLabelNode(text: displayText)
        label.fontName = "SFPro-Regular"
        label.fontSize = 10
        label.fontColor = NSColor(white: 0.15, alpha: 1.0)
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.position = CGPoint(x: 0, y: 0)

        let textWidth = max(label.frame.width + 16, 44)
        let textHeight: CGFloat = 20

        // Solid grey bubble background (Anti-slop compliance)
        let bg = SKShapeNode(rectOf: CGSize(width: textWidth, height: textHeight), cornerRadius: 5)
        bg.fillColor = NSColor(white: 0.94, alpha: 1.0) // Solid grey bubble #F0F0F0
        bg.strokeColor = NSColor(white: 0.80, alpha: 1.0)
        bg.lineWidth = 1.0
        bg.position = CGPoint(x: 0, y: 0)

        bubble.addChild(bg)
        bubble.addChild(label)
        bubble.position = CGPoint(x: 0, y: 46)
        bubble.zPosition = 1000

        bubble.alpha = 0.0
        bubble.setScale(0.8)

        addChild(bubble)
        self.thoughtBubbleNode = bubble

        let popIn = SKAction.group([
            SKAction.fadeIn(withDuration: 0.2),
            SKAction.scale(to: 1.0, duration: 0.2)
        ])
        let wait = SKAction.wait(forDuration: 2.5)
        let popOut = SKAction.group([
            SKAction.fadeOut(withDuration: 0.3),
            SKAction.scale(to: 0.8, duration: 0.3)
        ])
        let seq = SKAction.sequence([popIn, wait, popOut, SKAction.removeFromParent()])
        bubble.run(seq)
    }
}
