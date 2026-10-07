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

        // Discrete name tag above head
        let label = SKLabelNode(text: familiarKind.displayName.uppercased())
        label.fontName = NSFont.boldSystemFont(ofSize: 6.5).fontName
        label.fontSize = 6.5
        label.fontColor = NSColor(white: 0.92, alpha: 0.95)
        label.position = CGPoint(x: 0, y: 30)
        bodyContainer.addChild(label)
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

    public func performWork(taskName: String, duration: TimeInterval = 1.2, completion: (@MainActor @Sendable () -> Void)? = nil) {
        showThought(text: taskName)

        let jump = SKAction.moveBy(x: 0, y: 4, duration: 0.18)
        jump.timingMode = .easeOut
        let land = SKAction.moveBy(x: 0, y: -4, duration: 0.18)
        land.timingMode = .easeIn
        let workAction = SKAction.repeat(SKAction.sequence([jump, land]), count: Int(duration / 0.36))

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
        label.fontName = NSFont.monospacedSystemFont(ofSize: 8, weight: .semibold).fontName
        label.fontSize = 8
        label.fontColor = NSColor(white: 0.95, alpha: 1.0)
        label.verticalAlignmentMode = .center

        let bubbleWidth = CGFloat(max(displayText.count * 6 + 16, 40))
        let bg = SKShapeNode(rectOf: CGSize(width: bubbleWidth, height: 18), cornerRadius: 5)
        bg.fillColor = NSColor(red: 0.12, green: 0.14, blue: 0.16, alpha: 0.92)
        bg.strokeColor = NSColor(white: 0.35, alpha: 0.6)
        bg.lineWidth = 1.0

        bubble.addChild(bg)
        bubble.addChild(label)
        bubble.position = CGPoint(x: 0, y: 46)
        bubble.zPosition = 20
        bubble.setScale(0.1)

        bodyContainer.addChild(bubble)
        self.thoughtBubbleNode = bubble

        let popIn = SKAction.scale(to: 1.0, duration: 0.2)
        popIn.timingMode = .easeOut
        let wait = SKAction.wait(forDuration: 3.0)
        let fadeOut = SKAction.fadeOut(withDuration: 0.3)
        let remove = SKAction.removeFromParent()

        bubble.run(SKAction.sequence([popIn, wait, fadeOut, remove])) { [weak self] in
            if self?.thoughtBubbleNode === bubble {
                self?.thoughtBubbleNode = nil
            }
        }
    }
}
