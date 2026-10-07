import SpriteKit
import AppKit
import ChippyCore

/// Represents a physical workshop building or landmark on the floating island diorama.
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
        switch landmarkKind {
        case .citadel:
            buildCitadel()
        case .harbor:
            buildHarbor()
        case .district(let id):
            buildDistrictWorkshop(for: id)
        }
    }

    private func buildCitadel() {
        // High stone platform
        let base = SKShapeNode(rectOf: CGSize(width: 72, height: 28), cornerRadius: 4)
        base.fillColor = NSColor(white: 0.22, alpha: 1.0)
        base.strokeColor = NSColor(white: 0.35, alpha: 1.0)
        base.lineWidth = 1.0
        base.position = CGPoint(x: 0, y: 14)
        structureContainer.addChild(base)

        // Spire tower
        let tower = SKShapeNode(rectOf: CGSize(width: 36, height: 48), cornerRadius: 3)
        tower.fillColor = NSColor(white: 0.18, alpha: 1.0)
        tower.strokeColor = NSColor(white: 0.30, alpha: 1.0)
        tower.lineWidth = 1.0
        tower.position = CGPoint(x: 0, y: 44)
        structureContainer.addChild(tower)

        // Crown emblem
        let emblem = SKLabelNode(text: "👑")
        emblem.fontSize = 18
        emblem.position = CGPoint(x: 0, y: 72)
        emblem.verticalAlignmentMode = .center
        structureContainer.addChild(emblem)

        // Name tag
        let label = SKLabelNode(text: "THE CITADEL")
        label.fontName = "SFPro-Bold"
        label.fontSize = 9
        label.fontColor = NSColor(white: 0.85, alpha: 1.0)
        label.position = CGPoint(x: 0, y: 38)
        structureContainer.addChild(label)
    }

    private func buildHarbor() {
        // Wooden dock piers
        let pier = SKShapeNode(rectOf: CGSize(width: 58, height: 20), cornerRadius: 3)
        pier.fillColor = NSColor(red: 0.35, green: 0.28, blue: 0.22, alpha: 1.0)
        pier.strokeColor = NSColor(white: 0.20, alpha: 0.6)
        pier.lineWidth = 1.0
        pier.position = CGPoint(x: 0, y: 10)
        structureContainer.addChild(pier)

        // Crate stack
        let crate = SKShapeNode(rectOf: CGSize(width: 14, height: 14), cornerRadius: 2)
        crate.fillColor = NSColor(red: 0.45, green: 0.35, blue: 0.25, alpha: 1.0)
        crate.strokeColor = NSColor(white: 0.20, alpha: 0.5)
        crate.position = CGPoint(x: -8, y: 22)
        structureContainer.addChild(crate)

        let emblem = SKLabelNode(text: "⚓")
        emblem.fontSize = 14
        emblem.position = CGPoint(x: 12, y: 22)
        emblem.verticalAlignmentMode = .center
        structureContainer.addChild(emblem)

        let label = SKLabelNode(text: "PROJECT HARBOR")
        label.fontName = "SFPro-Bold"
        label.fontSize = 8
        label.fontColor = NSColor(white: 0.85, alpha: 1.0)
        label.position = CGPoint(x: 0, y: 32)
        structureContainer.addChild(label)
    }

    private func buildDistrictWorkshop(for district: DistrictID) {
        let (color, icon) = districtAesthetics(for: district)

        // Workshop base masonry
        let base = SKShapeNode(rectOf: CGSize(width: 54, height: 32), cornerRadius: 4)
        base.fillColor = color
        base.strokeColor = NSColor(white: 0.2, alpha: 0.5)
        base.lineWidth = 1.0
        base.position = CGPoint(x: 0, y: 16)
        structureContainer.addChild(base)

        // Roof awning
        let roofPath = CGMutablePath()
        roofPath.move(to: CGPoint(x: -32, y: 32))
        roofPath.addLine(to: CGPoint(x: 0, y: 46))
        roofPath.addLine(to: CGPoint(x: 32, y: 32))
        roofPath.closeSubpath()

        let roof = SKShapeNode(path: roofPath)
        roof.fillColor = NSColor(white: 0.22, alpha: 1.0)
        roof.strokeColor = NSColor(white: 0.15, alpha: 0.5)
        roof.lineWidth = 1.0
        structureContainer.addChild(roof)

        // Emblem icon
        let emblem = SKLabelNode(text: icon)
        emblem.fontSize = 13
        emblem.position = CGPoint(x: 0, y: 22)
        emblem.verticalAlignmentMode = .center
        structureContainer.addChild(emblem)

        // Workshop banner
        let banner = SKLabelNode(text: title.uppercased())
        banner.fontName = "SFPro-Bold"
        banner.fontSize = 7.5
        banner.fontColor = NSColor(white: 0.90, alpha: 1.0)
        banner.position = CGPoint(x: 0, y: 50)
        structureContainer.addChild(banner)
    }

    private func districtAesthetics(for district: DistrictID) -> (color: NSColor, icon: String) {
        switch district {
        case .highCouncil:
            return (NSColor(white: 0.28, alpha: 1.0), "🏛️")
        case .ironBastion:
            return (NSColor(red: 0.28, green: 0.30, blue: 0.33, alpha: 1.0), "🛡️")
        case .grandAtelier:
            return (NSColor(red: 0.32, green: 0.28, blue: 0.32, alpha: 1.0), "🎨")
        case .engineCore:
            return (NSColor(red: 0.26, green: 0.28, blue: 0.30, alpha: 1.0), "⚙️")
        case .scriptorium:
            return (NSColor(red: 0.32, green: 0.30, blue: 0.26, alpha: 1.0), "📜")
        case .wanderersMarket:
            return (NSColor(red: 0.28, green: 0.32, blue: 0.28, alpha: 1.0), "🧭")
        }
    }

    /// Triggers an activation glow/bounce when a skill inside this workshop is used.
    public func activateWorkshop() {
        let pulseUp = SKAction.scale(to: 1.06, duration: 0.15)
        let pulseDown = SKAction.scale(to: 1.0, duration: 0.25)
        structureContainer.run(SKAction.sequence([pulseUp, pulseDown]))
    }
}
