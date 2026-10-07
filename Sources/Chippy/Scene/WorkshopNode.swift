import SpriteKit
import AppKit
import ChippyCore

/// Represents a physical workshop cottage or landmark on the Stardew Valley-inspired island.
public final class WorkshopNode: SKNode {
    public let districtID: DistrictID?
    public let title: String
    public let landmarkKind: LandmarkKind

    public enum LandmarkKind: Sendable, Equatable {
        case citadel
        case harbor
        case district(DistrictID)
    }

    private let structureContainer = SKNode()
    private var buildingSprite: SKSpriteNode?

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

    /// Triggers an activation glow/bounce when a skill inside this workshop is used.
    public func activateWorkshop() {
        let pulseUp = SKAction.scale(to: 1.08, duration: 0.12)
        let pulseDown = SKAction.scale(to: 1.0, duration: 0.22)
        pulseUp.timingMode = .easeInEaseOut
        pulseDown.timingMode = .easeInEaseOut
        structureContainer.run(SKAction.sequence([pulseUp, pulseDown]))

        // Warm beacon aura on activation
        let glow = SKShapeNode(circleOfRadius: 28)
        glow.fillColor = NSColor(red: 0.98, green: 0.82, blue: 0.35, alpha: 0.35)
        glow.strokeColor = .clear
        glow.position = CGPoint(x: 0, y: 26)
        glow.zPosition = 5
        addChild(glow)
        glow.run(SKAction.sequence([
            SKAction.scale(to: 1.4, duration: 0.3),
            SKAction.fadeOut(withDuration: 0.2),
            SKAction.removeFromParent()
        ]))
    }
}
