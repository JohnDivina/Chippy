import SpriteKit
import AppKit
import ChippyCore

/// Renders the floating isometric sanctuary island, including terrain tiles,
/// cobblestone pathways, and placed workshop structures.
public final class IslandMapNode: SKNode {
    public let grid: IsometricGrid
    private var workshopNodes: [String: WorkshopNode] = [:]

    public init(grid: IsometricGrid = IsometricGrid(tileWidth: 64.0, tileHeight: 32.0)) {
        self.grid = grid
        super.init()

        buildTerrain()
        placeLandmarks()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func buildTerrain() {
        let radius = 4

        // 1. Draw floating island terrain tiles
        for col in -radius...radius {
            for row in -radius...radius {
                let dist = abs(col) + abs(row)
                guard dist <= radius + 2 else { continue }

                let screenPt = grid.gridToScreen(col: col, row: row)
                let tile = createIsometricTile(isPath: (col == 0 || row == 0 || dist <= 1))
                tile.position = CGPoint(x: screenPt.x, y: screenPt.y)
                tile.zPosition = grid.zPosition(col: col, row: row, layerOffset: -100)
                addChild(tile)
            }
        }
    }

    private func createIsometricTile(isPath: Bool) -> SKShapeNode {
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
            tile.fillColor = NSColor(white: 0.35, alpha: 1.0) // Cobblestone path
            tile.strokeColor = NSColor(white: 0.28, alpha: 1.0)
        } else {
            tile.fillColor = NSColor(red: 0.24, green: 0.32, blue: 0.24, alpha: 1.0) // Island grass
            tile.strokeColor = NSColor(red: 0.18, green: 0.24, blue: 0.18, alpha: 1.0)
        }
        tile.lineWidth = 0.5
        return tile
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
