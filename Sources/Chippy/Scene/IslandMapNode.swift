import SpriteKit
import AppKit
import ChippyCore

/// Renders the floating isometric sanctuary island with a cozy, Stardew Valley-inspired aesthetic:
/// warm meadow grass, earthy cobblestone paths, cliff depth, decorative trees, and street lanterns.
public final class IslandMapNode: SKNode {
    public let grid: IsometricGrid
    private var workshopNodes: [String: WorkshopNode] = [:]

    public init(grid: IsometricGrid = IsometricGrid(tileWidth: 64.0, tileHeight: 32.0)) {
        self.grid = grid
        super.init()

        buildTerrain()
        placeSceneryDecorations()
        placeLandmarks()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func buildTerrain() {
        let radius = 4

        // 1. Draw floating island terrain tiles with Stardew-style earth colors
        for col in -radius...radius {
            for row in -radius...radius {
                let dist = abs(col) + abs(row)
                guard dist <= radius + 2 else { continue }

                let screenPt = grid.gridToScreen(col: col, row: row)
                let isPath = (col == 0 || row == 0 || dist <= 1)
                let tile = createIsometricTile(col: col, row: row, isPath: isPath)
                tile.position = CGPoint(x: screenPt.x, y: screenPt.y)
                tile.zPosition = grid.zPosition(col: col, row: row, layerOffset: -100)
                addChild(tile)

                // Cliff walls for south-facing perimeter tiles
                if row == -radius || col == -radius || (dist == radius + 2 && (row < 0 || col < 0)) {
                    let cliff = createCliffDrop(isPath: isPath)
                    cliff.position = CGPoint(x: screenPt.x, y: screenPt.y)
                    cliff.zPosition = grid.zPosition(col: col, row: row, layerOffset: -110)
                    addChild(cliff)
                }
            }
        }
    }

    private func createIsometricTile(col: Int, row: Int, isPath: Bool) -> SKShapeNode {
        let hw = grid.tileWidth / 2.0
        let hh = grid.tileHeight / 2.0

        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0, y: hh))
        path.addLine(to: CGPoint(x: hw, y: 0))
        path.addLine(to: CGPoint(x: 0, y: -hh))
        path.addLine(to: CGPoint(x: -hw, y: 0))
        path.closeSubpath()

        let tile = SKShapeNode(path: path)
        if isPath {
            // Earthy dirt & cobblestone path (Stardew farm trail)
            tile.fillColor = NSColor(red: 0.50, green: 0.42, blue: 0.33, alpha: 1.0)
            tile.strokeColor = NSColor(red: 0.38, green: 0.32, blue: 0.25, alpha: 1.0)
        } else {
            // Warm alternating lush meadow grass (Stardew checkerboard grass)
            let isAlternate = (col + row) % 2 == 0
            if isAlternate {
                tile.fillColor = NSColor(red: 0.31, green: 0.49, blue: 0.27, alpha: 1.0) // Lush green
                tile.strokeColor = NSColor(red: 0.24, green: 0.40, blue: 0.21, alpha: 1.0)
            } else {
                tile.fillColor = NSColor(red: 0.27, green: 0.44, blue: 0.24, alpha: 1.0) // Deep meadow
                tile.strokeColor = NSColor(red: 0.20, green: 0.35, blue: 0.18, alpha: 1.0)
            }
        }
        tile.lineWidth = 0.5
        return tile
    }

    private func createCliffDrop(isPath: Bool) -> SKShapeNode {
        let hw = grid.tileWidth / 2.0
        let hh = grid.tileHeight / 2.0
        let drop: CGFloat = 16.0

        let path = CGMutablePath()
        path.move(to: CGPoint(x: -hw, y: 0))
        path.addLine(to: CGPoint(x: 0, y: -hh))
        path.addLine(to: CGPoint(x: hw, y: 0))
        path.addLine(to: CGPoint(x: hw, y: -drop))
        path.addLine(to: CGPoint(x: 0, y: -hh - drop))
        path.addLine(to: CGPoint(x: -hw, y: -drop))
        path.closeSubpath()

        let cliff = SKShapeNode(path: path)
        cliff.fillColor = NSColor(red: 0.26, green: 0.20, blue: 0.16, alpha: 1.0) // Rich earthen bedrock
        cliff.strokeColor = NSColor(red: 0.18, green: 0.14, blue: 0.11, alpha: 1.0)
        cliff.lineWidth = 0.5
        return cliff
    }

    private func placeSceneryDecorations() {
        // Decorative pixel trees around farm perimeters
        let treeCoords = [
            GridPoint(col: 3, row: -1),
            GridPoint(col: -3, row: 2),
            GridPoint(col: 2, row: 3),
            GridPoint(col: -2, row: -2),
            GridPoint(col: 1, row: -3)
        ]

        for pt in treeCoords {
            let tree = createTree()
            let screenPt = grid.gridToScreen(col: pt.col, row: pt.row)
            tree.position = CGPoint(x: screenPt.x + 8, y: screenPt.y + 6)
            tree.zPosition = grid.zPosition(col: pt.col, row: pt.row, layerOffset: 5)
            addChild(tree)
        }

        // Lantern posts at road intersections
        let lanternCoords = [
            GridPoint(col: 1, row: 1),
            GridPoint(col: -1, row: -1)
        ]

        for pt in lanternCoords {
            let lantern = createLantern()
            let screenPt = grid.gridToScreen(col: pt.col, row: pt.row)
            lantern.position = CGPoint(x: screenPt.x - 10, y: screenPt.y + 4)
            lantern.zPosition = grid.zPosition(col: pt.col, row: pt.row, layerOffset: 8)
            addChild(lantern)
        }
    }

    private func createTree() -> SKNode {
        let tree = SKNode()

        // Trunk
        let trunk = SKShapeNode(rectOf: CGSize(width: 6, height: 12), cornerRadius: 1)
        trunk.fillColor = NSColor(red: 0.38, green: 0.25, blue: 0.15, alpha: 1.0)
        trunk.strokeColor = .clear
        trunk.position = CGPoint(x: 0, y: 6)
        tree.addChild(trunk)

        // Lower foliage
        let bottomLeaves = SKShapeNode(ellipseOf: CGSize(width: 24, height: 20))
        bottomLeaves.fillColor = NSColor(red: 0.22, green: 0.42, blue: 0.20, alpha: 1.0)
        bottomLeaves.strokeColor = NSColor(red: 0.16, green: 0.32, blue: 0.14, alpha: 1.0)
        bottomLeaves.lineWidth = 0.5
        bottomLeaves.position = CGPoint(x: 0, y: 18)
        tree.addChild(bottomLeaves)

        // Upper canopy
        let topLeaves = SKShapeNode(ellipseOf: CGSize(width: 18, height: 16))
        topLeaves.fillColor = NSColor(red: 0.30, green: 0.52, blue: 0.26, alpha: 1.0)
        topLeaves.strokeColor = .clear
        topLeaves.position = CGPoint(x: 0, y: 24)
        tree.addChild(topLeaves)

        return tree
    }

    private func createLantern() -> SKNode {
        let lantern = SKNode()

        // Wood post
        let post = SKShapeNode(rectOf: CGSize(width: 3, height: 16))
        post.fillColor = NSColor(red: 0.32, green: 0.24, blue: 0.18, alpha: 1.0)
        post.strokeColor = .clear
        post.position = CGPoint(x: 0, y: 8)
        lantern.addChild(post)

        // Amber glow lantern
        let lamp = SKShapeNode(circleOfRadius: 3.5)
        lamp.fillColor = NSColor(red: 0.95, green: 0.80, blue: 0.40, alpha: 1.0) // Warm amber light
        lamp.strokeColor = NSColor(red: 0.40, green: 0.30, blue: 0.20, alpha: 1.0)
        lamp.lineWidth = 0.5
        lamp.position = CGPoint(x: 0, y: 16)
        lantern.addChild(lamp)

        return lantern
    }

    private func placeLandmarks() {
        // Center Citadel
        addWorkshop(
            kind: .citadel,
            title: "Citadel",
            key: "citadel",
            gridPt: GridPoint(col: 0, row: 0)
        )

        // Harbor (South)
        addWorkshop(
            kind: .harbor,
            title: "Harbor",
            key: "harbor",
            gridPt: GridPoint(col: -3, row: -3)
        )

        // District Workshops
        addWorkshop(
            kind: .district(.highCouncil),
            title: "High Council",
            key: DistrictID.highCouncil.rawValue,
            gridPt: GridPoint(col: 3, row: 1)
        )

        addWorkshop(
            kind: .district(.ironBastion),
            title: "Iron Bastion",
            key: DistrictID.ironBastion.rawValue,
            gridPt: GridPoint(col: 1, row: 3)
        )

        addWorkshop(
            kind: .district(.grandAtelier),
            title: "Grand Atelier",
            key: DistrictID.grandAtelier.rawValue,
            gridPt: GridPoint(col: -2, row: 2)
        )

        addWorkshop(
            kind: .district(.engineCore),
            title: "Engine Core",
            key: DistrictID.engineCore.rawValue,
            gridPt: GridPoint(col: 2, row: -2)
        )

        addWorkshop(
            kind: .district(.scriptorium),
            title: "Scriptorium",
            key: DistrictID.scriptorium.rawValue,
            gridPt: GridPoint(col: -1, row: -2)
        )

        addWorkshop(
            kind: .district(.wanderersMarket),
            title: "Market",
            key: DistrictID.wanderersMarket.rawValue,
            gridPt: GridPoint(col: -3, row: 1)
        )
    }

    private func addWorkshop(kind: WorkshopNode.LandmarkKind, title: String, key: String, gridPt: GridPoint) {
        let node = WorkshopNode(kind: kind, title: title)
        let pt = grid.gridToScreen(col: gridPt.col, row: gridPt.row)
        node.position = CGPoint(x: pt.x, y: pt.y)
        node.zPosition = grid.zPosition(col: gridPt.col, row: gridPt.row, layerOffset: 0)
        addChild(node)
        workshopNodes[key] = node
    }

    /// Resolves the screen coordinate for a landmark key or district.
    public func positionFor(landmarkKey: String) -> CGPoint? {
        workshopNodes[landmarkKey]?.position
    }

    public func activateWorkshop(key: String) {
        workshopNodes[key]?.activateWorkshop()
    }
}
