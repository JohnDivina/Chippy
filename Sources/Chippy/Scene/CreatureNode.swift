import SpriteKit
import AppKit
import ChippyCore

/// Visual SpriteKit node representing an animated pixel creature (Sovereign or Familiar)
/// in the 2.5D diorama with Stardew Valley-style character sprites and walk cycles.
public final class CreatureNode: SKNode {
    public let familiarKind: FamiliarKind
    public var gridPosition: GridPoint

    private let bodyContainer = SKNode()
    private let shadowNode: SKShapeNode
    private var spriteNode: SKSpriteNode!
    private var thoughtBubbleNode: SKNode?

    public init(kind: FamiliarKind, initialGrid: GridPoint = GridPoint(col: 0, row: 0)) {
        self.familiarKind = kind
        self.gridPosition = initialGrid

        // 1. Soft oval shadow
        let shadow = SKShapeNode(ellipseOf: CGSize(width: 20, height: 8))
        shadow.fillColor = NSColor.black.withAlphaComponent(0.25)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: 0, y: 2)
        self.shadowNode = shadow

        super.init()

        addChild(shadow)
        addChild(bodyContainer)

        buildPixelVisuals()
        startIdleAnimation()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Pixel Visuals

    private func buildPixelVisuals() {
        let frame0 = PixelArtAtlas.shared.familiarSprite(kind: familiarKind, frame: 0)
        let sprite = SKSpriteNode(texture: frame0)
        sprite.anchorPoint = CGPoint(x: 0.5, y: 0.15)
        sprite.position = CGPoint(x: 0, y: 0)
        bodyContainer.addChild(sprite)
        self.spriteNode = sprite
    }

    // MARK: - Animations

    public func startIdleAnimation() {
        bodyContainer.removeAction(forKey: "idle")
        let bobUp = SKAction.moveBy(x: 0, y: 1.5, duration: 0.9)
        bobUp.timingMode = .easeInEaseOut
        let bobDown = SKAction.moveBy(x: 0, y: -1.5, duration: 0.9)
        bobDown.timingMode = .easeInEaseOut
        let sequence = SKAction.sequence([bobUp, bobDown])
        bodyContainer.run(SKAction.repeatForever(sequence), withKey: "idle")
    }

    public func walk(to targetPosition: CGPoint, newGrid: GridPoint, duration: TimeInterval = 0.8, completion: (@MainActor @Sendable () -> Void)? = nil) {
        bodyContainer.removeAction(forKey: "idle")

        // Face travel direction
        let movingLeft = targetPosition.x < position.x
        bodyContainer.xScale = movingLeft ? -1.0 : 1.0

        // 2-frame walking step animation
        let f0 = PixelArtAtlas.shared.familiarSprite(kind: familiarKind, frame: 0)
        let f1 = PixelArtAtlas.shared.familiarSprite(kind: familiarKind, frame: 1)
        let stepAnim = SKAction.repeatForever(SKAction.animate(with: [f0, f1], timePerFrame: 0.16))
        spriteNode.run(stepAnim, withKey: "walkStep")

        let stepUp = SKAction.moveBy(x: 0, y: 2, duration: 0.16)
        let stepDown = SKAction.moveBy(x: 0, y: -2, duration: 0.16)
        let walkBob = SKAction.repeatForever(SKAction.sequence([stepUp, stepDown]))
        bodyContainer.run(walkBob, withKey: "walkBob")

        let moveAction = SKAction.move(to: targetPosition, duration: duration)
        moveAction.timingMode = .easeInEaseOut

        run(moveAction) { [weak self] in
            guard let self else { return }
            self.gridPosition = newGrid
            self.spriteNode.removeAction(forKey: "walkStep")
            self.spriteNode.texture = f0
            self.bodyContainer.removeAction(forKey: "walkBob")
            self.bodyContainer.position = .zero
            self.startIdleAnimation()
            completion?()
        }
    }

    public func performWork(taskName: String, duration: TimeInterval = 1.8, completion: (@MainActor @Sendable () -> Void)? = nil) {
        showThought(text: taskName, duration: duration, isWorking: true)

        let jump = SKAction.moveBy(x: 0, y: 5, duration: 0.18)
        jump.timingMode = .easeOut
        let land = SKAction.moveBy(x: 0, y: -5, duration: 0.18)
        land.timingMode = .easeIn
        let workAction = SKAction.repeat(SKAction.sequence([jump, land]), count: max(1, Int(duration / 0.36)))

        bodyContainer.run(workAction) { [weak self] in
            self?.startIdleAnimation()
            completion?()
        }
    }

    /// Displays an individual Stardew Valley-inspired RPG speech/thought box above the character's head
    /// with role icons, clean typography, drop shadow, pointer tail, and active working indicators.
    public func showThought(text: String, duration: TimeInterval = 4.0, isWorking: Bool = false) {
        thoughtBubbleNode?.removeFromParent()

        let bubble = SKNode()
        let maxLen = 42
        let displayText = text.count > maxLen ? String(text.prefix(maxLen)) + "…" : text

        let roleTag: String = {
            switch familiarKind {
            case .sovereign: return "👑 Sovereign"
            case .scout: return "🔍 Scout"
            case .mason: return "⚒ Mason"
            case .weaver: return "✨ Weaver"
            case .sentinel: return "🛡 Sentinel"
            case .scribe: return "📜 Scribe"
            case .arbiter: return "⚖️ Arbiter"
            }
        }()

        let bubbleWidth = CGFloat(max(displayText.count * 6 + 24, 76))
        let bubbleHeight: CGFloat = 26

        // 1. Drop shadow behind speech box
        let shadow = SKShapeNode(rectOf: CGSize(width: bubbleWidth, height: bubbleHeight), cornerRadius: 4)
        shadow.fillColor = NSColor.black.withAlphaComponent(0.35)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: 0, y: -1)
        bubble.addChild(shadow)

        // 2. High-contrast solid dark slate bubble container (Anti-slop compliant)
        let bg = SKShapeNode(rectOf: CGSize(width: bubbleWidth, height: bubbleHeight), cornerRadius: 4)
        bg.fillColor = NSColor(red: 0.10, green: 0.12, blue: 0.14, alpha: 0.96)
        bg.strokeColor = isWorking ? NSColor(red: 0.65, green: 0.50, blue: 0.28, alpha: 0.9) : NSColor(white: 0.30, alpha: 0.8)
        bg.lineWidth = 1.0
        bubble.addChild(bg)

        // 3. Downward triangular pointer tail pointing to character's head
        let tailPath = CGMutablePath()
        tailPath.move(to: CGPoint(x: -4, y: -bubbleHeight / 2))
        tailPath.addLine(to: CGPoint(x: 4, y: -bubbleHeight / 2))
        tailPath.addLine(to: CGPoint(x: 0, y: -bubbleHeight / 2 - 4))
        tailPath.closeSubpath()

        let tail = SKShapeNode(path: tailPath)
        tail.fillColor = NSColor(red: 0.10, green: 0.12, blue: 0.14, alpha: 0.96)
        tail.strokeColor = .clear
        bubble.addChild(tail)

        // 4. Role tag on top line
        let roleLabel = SKLabelNode(text: roleTag)
        roleLabel.fontName = NSFont.monospacedSystemFont(ofSize: 6.5, weight: .bold).fontName
        roleLabel.fontSize = 6.5
        roleLabel.fontColor = isWorking ? NSColor(red: 0.98, green: 0.82, blue: 0.42, alpha: 1.0) : NSColor(white: 0.70, alpha: 1.0)
        roleLabel.verticalAlignmentMode = .center
        roleLabel.horizontalAlignmentMode = .center
        roleLabel.position = CGPoint(x: 0, y: 5)
        bubble.addChild(roleLabel)

        // 5. Main task/message line
        let textLabel = SKLabelNode(text: displayText)
        textLabel.fontName = NSFont.monospacedSystemFont(ofSize: 7.5, weight: .semibold).fontName
        textLabel.fontSize = 7.5
        textLabel.fontColor = NSColor(white: 0.96, alpha: 1.0)
        textLabel.verticalAlignmentMode = .center
        textLabel.horizontalAlignmentMode = .center
        textLabel.position = CGPoint(x: 0, y: -5)
        bubble.addChild(textLabel)

        bubble.position = CGPoint(x: 0, y: 48)
        bubble.zPosition = 25
        bubble.setScale(0.1)

        bodyContainer.addChild(bubble)
        self.thoughtBubbleNode = bubble

        // Pop in with gentle bounce, hover during task, and fade out
        let popIn = SKAction.scale(to: 1.05, duration: 0.14)
        let settle = SKAction.scale(to: 1.0, duration: 0.08)
        let hoverUp = SKAction.moveBy(x: 0, y: 1.5, duration: 0.8)
        let hoverDown = SKAction.moveBy(x: 0, y: -1.5, duration: 0.8)
        let hoverLoop = SKAction.repeat(SKAction.sequence([hoverUp, hoverDown]), count: max(1, Int(duration / 1.6)))
        let fadeOut = SKAction.fadeOut(withDuration: 0.3)
        let remove = SKAction.removeFromParent()

        let sequence = SKAction.sequence([popIn, settle, hoverLoop, fadeOut, remove])

        bubble.run(sequence) { [weak self] in
            if self?.thoughtBubbleNode === bubble {
                self?.thoughtBubbleNode = nil
            }
        }
    }
}
