import SpriteKit
import AppKit
import ChippyCore

/// The main SpriteKit 2.5D diorama scene rendering the island, creatures, and camera interactions.
public final class ParadiseScene: SKScene {
    public let grid = IsometricGrid(tileWidth: 64.0, tileHeight: 32.0)
    public private(set) var islandMap: IslandMapNode!
    public private(set) var cameraNode: SKCameraNode!

    private var creatures: [FamiliarKind: CreatureNode] = [:]

    public override init(size: CGSize) {
        super.init(size: size)
        self.scaleMode = .resizeFill
        self.backgroundColor = NSColor(red: 0.08, green: 0.09, blue: 0.11, alpha: 1.0) // Deep void backdrop

        setupCamera()
        setupIsland()
        setupInitialFamiliars()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupCamera() {
        let camera = SKCameraNode()
        camera.position = CGPoint(x: 0, y: 40)
        camera.setScale(1.0)
        self.cameraNode = camera
        addChild(camera)
        self.camera = camera
    }

    private func setupIsland() {
        let map = IslandMapNode(grid: grid)
        self.islandMap = map
        addChild(map)
    }

    private func setupInitialFamiliars() {
        // 1. Sovereign at Citadel
        spawnFamiliar(kind: .sovereign, at: GridPoint(col: 0, row: 0), landmark: "citadel")

        // 2. Scout near Harbor
        spawnFamiliar(kind: .scout, at: GridPoint(col: -2, row: -2), landmark: "harbor")

        // 3. Mason at Engine Core
        spawnFamiliar(kind: .mason, at: GridPoint(col: 1, row: -1), landmark: DistrictID.engineCore.rawValue)

        // 4. Weaver at Atelier
        spawnFamiliar(kind: .weaver, at: GridPoint(col: -1, row: 1), landmark: DistrictID.grandAtelier.rawValue)

        // 5. Sentinel at Bastion
        spawnFamiliar(kind: .sentinel, at: GridPoint(col: 0, row: 2), landmark: DistrictID.ironBastion.rawValue)

        // 6. Scribe at Scriptorium
        spawnFamiliar(kind: .scribe, at: GridPoint(col: -1, row: -1), landmark: DistrictID.scriptorium.rawValue)
    }

    @discardableResult
    public func spawnFamiliar(kind: FamiliarKind, at gridPt: GridPoint, landmark: String? = nil) -> CreatureNode {
        if let existing = creatures[kind] {
            return existing
        }

        let node = CreatureNode(kind: kind, initialGrid: gridPt)
        let screenPt = grid.gridToScreen(col: gridPt.col, row: gridPt.row)
        node.position = CGPoint(x: screenPt.x, y: screenPt.y)
        node.zPosition = grid.zPosition(col: gridPt.col, row: gridPt.row, layerOffset: 10)
        addChild(node)
        creatures[kind] = node
        return node
    }

    public func familiarNode(for kind: FamiliarKind) -> CreatureNode? {
        creatures[kind]
    }

    /// Animates a familiar walking to a specific destination workshop or landmark.
    public func moveFamiliar(
        _ kind: FamiliarKind,
        toLandmark key: String,
        targetGrid: GridPoint,
        completion: (@MainActor @Sendable () -> Void)? = nil
    ) {
        guard let creature = creatures[kind],
              let targetPos = islandMap.positionFor(landmarkKey: key) else {
            completion?()
            return
        }

        creature.walk(to: targetPos, newGrid: targetGrid, duration: 0.9) { [weak self] in
            guard let self else { return }
            creature.zPosition = self.grid.zPosition(col: targetGrid.col, row: targetGrid.row, layerOffset: 10)
            self.islandMap.activateWorkshop(key: key)
            completion?()
        }
    }

    public func setWorkshopWorking(key: String, isWorking: Bool, task: String? = nil) {
        islandMap.setWorkshopWorking(key: key, isWorking: isWorking, task: task)
    }

    public func setAllWorkshopsWorking(_ isWorking: Bool) {
        islandMap.setAllWorkshopsWorking(isWorking)
    }

    // MARK: - Camera Controls & Island Bounds Clamping

    public let cameraMinX: CGFloat = -260.0
    public let cameraMaxX: CGFloat = 260.0
    public let cameraMinY: CGFloat = -140.0
    public let cameraMaxY: CGFloat = 200.0

    public func zoomIn() {
        let newScale = max(0.6, cameraNode.xScale - 0.2)
        cameraNode.run(SKAction.scale(to: newScale, duration: 0.2))
    }

    public func zoomOut() {
        let newScale = min(1.6, cameraNode.xScale + 0.2)
        cameraNode.run(SKAction.scale(to: newScale, duration: 0.2))
    }

    public func zoomCamera(by delta: CGFloat) {
        let newScale = max(0.6, min(1.6, cameraNode.xScale - delta * 0.1))
        cameraNode.setScale(newScale)
    }

    public func panCamera(by delta: CGPoint) {
        let newX = cameraNode.position.x - delta.x
        let newY = cameraNode.position.y - delta.y
        cameraNode.position = CGPoint(
            x: max(cameraMinX, min(cameraMaxX, newX)),
            y: max(cameraMinY, min(cameraMaxY, newY))
        )
    }

    public func resetCamera() {
        let move = SKAction.move(to: CGPoint(x: 0, y: 40), duration: 0.35)
        move.timingMode = .easeInEaseOut
        let scale = SKAction.scale(to: 1.0, duration: 0.35)
        scale.timingMode = .easeInEaseOut
        cameraNode.run(SKAction.group([move, scale]))
    }

    public func focusLandmark(key: String) {
        guard let pos = islandMap.positionFor(landmarkKey: key) else { return }
        let targetX = max(cameraMinX, min(cameraMaxX, pos.x))
        let targetY = max(cameraMinY, min(cameraMaxY, pos.y + 20))
        let move = SKAction.move(to: CGPoint(x: targetX, y: targetY), duration: 0.4)
        move.timingMode = .easeInEaseOut
        cameraNode.run(move)
        islandMap.activateWorkshop(key: key)
    }

    public override func scrollWheel(with event: NSEvent) {
        if event.hasPreciseScrollingDeltas {
            // Trackpad two-finger smooth pan
            let dx = event.scrollingDeltaX * cameraNode.xScale * 0.75
            let dy = event.scrollingDeltaY * cameraNode.yScale * 0.75
            panCamera(by: CGPoint(x: dx, y: -dy))
        } else {
            // Discrete mouse wheel zoom
            let delta = event.deltaY
            if delta > 0 {
                zoomIn()
            } else if delta < 0 {
                zoomOut()
            }
        }
    }

    public override func magnify(with event: NSEvent) {
        let newScale = max(0.6, min(1.6, cameraNode.xScale * (1.0 - event.magnification)))
        cameraNode.setScale(newScale)
    }

    public override func mouseDown(with event: NSEvent) {
        if event.clickCount == 2 {
            resetCamera()
        }
    }

    public override func mouseDragged(with event: NSEvent) {
        let dx = event.deltaX * cameraNode.xScale
        let dy = event.deltaY * cameraNode.yScale
        panCamera(by: CGPoint(x: dx, y: -dy))
    }
}
