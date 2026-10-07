import SpriteKit
import AppKit
import ChippyCore

/// Renders the expanded floating sanctuary island using authentic Stardew Valley-inspired pixel art:
/// lush dithered meadow grass with wildflowers, earthen cobblestone trails, expansive pumpkin garden plots,
/// a tranquil water pond with lily pads, rustic cedar fences, apple trees, street lanterns,
/// and roaming farm animals (1 dog, 1 cat, and fluttering sparrows).
public final class IslandMapNode: SKNode {
    public let grid: IsometricGrid
    private var workshopNodes: [String: WorkshopNode] = [:]
    private var critters: [CritterNode] = []

    public init(grid: IsometricGrid = IsometricGrid(tileWidth: 64.0, tileHeight: 32.0)) {
        self.grid = grid
        super.init()

        buildTerrain()
        placeSceneryDecorations()
        placeLandmarks()
        placePetsAndWildlife()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func buildTerrain() {
        let radius = 6 // Expanded landscape

        // 1. Draw floating island terrain tiles with authentic pixel textures
        for col in -radius...radius {
            for row in -radius...radius {
                let dist = abs(col) + abs(row)
                guard dist <= radius + 3 else { continue }

                let screenPt = grid.gridToScreen(col: col, row: row)
                let isPath = (col == 0 || row == 0 || dist <= 1 || (col == 2 && abs(row) <= 3) || (row == -2 && abs(col) <= 3))
                let isGarden = (col >= 3 && col <= 5 && row >= 1 && row <= 3) || (col <= -2 && col >= -4 && row >= 3 && row <= 5)
                let isPond = (col >= -4 && col <= -2 && row <= -1 && row >= -3)

                let tile = createPixelTile(col: col, row: row, isPath: isPath, isGarden: isGarden, isPond: isPond)
                tile.position = CGPoint(x: screenPt.x, y: screenPt.y)
                tile.zPosition = grid.zPosition(col: col, row: row, layerOffset: -100)
                addChild(tile)

                // Cliff walls for south-facing perimeter tiles
                if row == -radius || col == -radius || (dist == radius + 3 && (row < 0 || col < 0)) {
                    let cliff = SKSpriteNode(texture: PixelArtAtlas.shared.cliffWall())
                    cliff.anchorPoint = CGPoint(x: 0.5, y: 1.0)
                    cliff.position = CGPoint(x: screenPt.x, y: screenPt.y)
                    cliff.zPosition = grid.zPosition(col: col, row: row, layerOffset: -110)
                    addChild(cliff)
                }
            }
        }
    }

    private func createPixelTile(col: Int, row: Int, isPath: Bool, isGarden: Bool, isPond: Bool) -> SKNode {
        let texture: SKTexture = {
            if isPond {
                return PixelArtAtlas.shared.waterPondTile()
            } else if isGarden {
                return PixelArtAtlas.shared.gardenPatchTile()
            } else if isPath {
                return PixelArtAtlas.shared.pathTile()
            } else {
                let variant = abs(col * 3 + row * 7) % 3
                return PixelArtAtlas.shared.grassTile(variant: variant)
            }
        }()

        let sprite = SKSpriteNode(texture: texture)
        sprite.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        return sprite
    }

    private func placeSceneryDecorations() {
        // Apple trees around farm perimeters and orchards
        let treeCoords = [
            GridPoint(col: 5, row: -1),
            GridPoint(col: 4, row: -3),
            GridPoint(col: -5, row: 2),
            GridPoint(col: -4, row: 4),
            GridPoint(col: 2, row: 5),
            GridPoint(col: -2, row: -4),
            GridPoint(col: 1, row: -5),
            GridPoint(col: -1, row: 5)
        ]

        for pt in treeCoords {
            let tree = SKSpriteNode(texture: PixelArtAtlas.shared.appleTree())
            tree.anchorPoint = CGPoint(x: 0.5, y: 0.12)
            let screenPt = grid.gridToScreen(col: pt.col, row: pt.row)
            tree.position = CGPoint(x: screenPt.x + 4, y: screenPt.y + 4)
            tree.zPosition = grid.zPosition(col: pt.col, row: pt.row, layerOffset: 5)
            addChild(tree)
        }

        // Wooden farm fences flanking pathways and garden beds
        let fenceCoords = [
            GridPoint(col: 2, row: 4),
            GridPoint(col: 2, row: -1),
            GridPoint(col: -1, row: 3),
            GridPoint(col: 3, row: 0),
            GridPoint(col: -3, row: 1)
        ]

        for pt in fenceCoords {
            let fence = SKSpriteNode(texture: PixelArtAtlas.shared.woodenFence())
            fence.anchorPoint = CGPoint(x: 0.5, y: 0.2)
            let screenPt = grid.gridToScreen(col: pt.col, row: pt.row)
            fence.position = CGPoint(x: screenPt.x - 8, y: screenPt.y + 2)
            fence.zPosition = grid.zPosition(col: pt.col, row: pt.row, layerOffset: 4)
            addChild(fence)
        }

        // Street Lantern posts at crossroads
        let lanternCoords = [
            GridPoint(col: 1, row: 1),
            GridPoint(col: -1, row: -1),
            GridPoint(col: 2, row: -2),
            GridPoint(col: -2, row: 2)
        ]

        for pt in lanternCoords {
            let lantern = SKSpriteNode(texture: PixelArtAtlas.shared.streetLantern())
            lantern.anchorPoint = CGPoint(x: 0.5, y: 0.1)
            let screenPt = grid.gridToScreen(col: pt.col, row: pt.row)
            lantern.position = CGPoint(x: screenPt.x - 12, y: screenPt.y + 4)
            lantern.zPosition = grid.zPosition(col: pt.col, row: pt.row, layerOffset: 8)
            addChild(lantern)
        }
    }

    private func placeLandmarks() {
        // Center Citadel (High Manor)
        addWorkshop(
            kind: .citadel,
            title: "Citadel",
            key: "citadel",
            gridPt: GridPoint(col: 0, row: 0)
        )

        // Harbor (South Pier)
        addWorkshop(
            kind: .harbor,
            title: "Harbor",
            key: "harbor",
            gridPt: GridPoint(col: -4, row: -4)
        )

        // District Workshops (Stardew-style cottages)
        addWorkshop(
            kind: .district(.highCouncil),
            title: "High Council",
            key: DistrictID.highCouncil.rawValue,
            gridPt: GridPoint(col: 4, row: 2)
        )

        addWorkshop(
            kind: .district(.ironBastion),
            title: "Iron Bastion",
            key: DistrictID.ironBastion.rawValue,
            gridPt: GridPoint(col: 1, row: 4)
        )

        addWorkshop(
            kind: .district(.grandAtelier),
            title: "Grand Atelier",
            key: DistrictID.grandAtelier.rawValue,
            gridPt: GridPoint(col: -3, row: 3)
        )

        addWorkshop(
            kind: .district(.engineCore),
            title: "Engine Core",
            key: DistrictID.engineCore.rawValue,
            gridPt: GridPoint(col: 3, row: -3)
        )

        addWorkshop(
            kind: .district(.scriptorium),
            title: "Scriptorium",
            key: DistrictID.scriptorium.rawValue,
            gridPt: GridPoint(col: -1, row: -3)
        )

        addWorkshop(
            kind: .district(.wanderersMarket),
            title: "Market",
            key: DistrictID.wanderersMarket.rawValue,
            gridPt: GridPoint(col: -4, row: 1)
        )
    }

    private func placePetsAndWildlife() {
        // 1. Farm Dog (Golden Retriever roaming near Citadel & paths)
        let dog = CritterNode(type: .dog, startGrid: GridPoint(col: 1, row: -1), grid: grid)
        addChild(dog)
        critters.append(dog)

        // 2. Farm Cat (Ginger Tabby wandering near garden plots & pond)
        let cat = CritterNode(type: .cat, startGrid: GridPoint(col: -2, row: 2), grid: grid)
        addChild(cat)
        critters.append(cat)

        // 3. Ambient Birds (Sparrows & doves perching and fluttering)
        let bird1 = CritterNode(type: .bird, startGrid: GridPoint(col: 3, row: 1), grid: grid)
        addChild(bird1)
        critters.append(bird1)

        let bird2 = CritterNode(type: .bird, startGrid: GridPoint(col: -2, row: -2), grid: grid)
        addChild(bird2)
        critters.append(bird2)

        let bird3 = CritterNode(type: .bird, startGrid: GridPoint(col: 0, row: 3), grid: grid)
        addChild(bird3)
        critters.append(bird3)
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
