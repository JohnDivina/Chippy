import SpriteKit
import AppKit
import ChippyCore

/// Represents ambient farm critters inspired by Stardew Valley:
/// a roaming farm dog, a wandering farm cat, and fluttering sparrows.
public final class CritterNode: SKNode {
    public enum CritterType {
        case dog
        case cat
        case bird
    }

    public let critterType: CritterType
    public let grid: IsometricGrid
    public var currentGrid: GridPoint

    private let spriteNode: SKSpriteNode
    private var isBusy: Bool = false

    public init(type: CritterType, startGrid: GridPoint, grid: IsometricGrid) {
        self.critterType = type
        self.grid = grid
        self.currentGrid = startGrid

        let initialTex: SKTexture = {
            switch type {
            case .dog: return PixelArtAtlas.shared.petDog(frame: 0)
            case .cat: return PixelArtAtlas.shared.petCat(frame: 0)
            case .bird: return PixelArtAtlas.shared.flyingBird(frame: 0)
            }
        }()

        let sprite = SKSpriteNode(texture: initialTex)
        sprite.anchorPoint = CGPoint(x: 0.5, y: 0.15)
        self.spriteNode = sprite

        super.init()

        // Subtle drop shadow for pets
        if type != .bird {
            let shadow = SKShapeNode(ellipseOf: CGSize(width: 14, height: 6))
            shadow.fillColor = NSColor.black.withAlphaComponent(0.2)
            shadow.strokeColor = .clear
            shadow.position = CGPoint(x: 0, y: 2)
            shadow.zPosition = -1
            addChild(shadow)
        }

        addChild(sprite)

        let pt = grid.gridToScreen(col: startGrid.col, row: startGrid.row)
        self.position = CGPoint(x: pt.x, y: pt.y)
        self.zPosition = grid.zPosition(col: startGrid.col, row: startGrid.row, layerOffset: 6)

        startAmbientBehavior()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Ambient Autonomous Roaming

    public func startAmbientBehavior() {
        switch critterType {
        case .dog:
            scheduleNextDogAction()
        case .cat:
            scheduleNextCatAction()
        case .bird:
            scheduleNextBirdAction()
        }
    }

    private func scheduleNextDogAction() {
        let waitTime = Double.random(in: 2.5...5.0)
        let wait = SKAction.wait(forDuration: waitTime)
        let roam = SKAction.run { [weak self] in
            self?.roamToAdjacentTile(speed: 1.2) {
                self?.scheduleNextDogAction()
            }
        }
        run(SKAction.sequence([wait, roam]), withKey: "petRoutine")
    }

    private func scheduleNextCatAction() {
        let waitTime = Double.random(in: 3.5...7.0)
        let wait = SKAction.wait(forDuration: waitTime)
        let roam = SKAction.run { [weak self] in
            // Cat sometimes naps/sits instead of walking
            if Bool.random() {
                self?.catSitAndPurr {
                    self?.scheduleNextCatAction()
                }
            } else {
                self?.roamToAdjacentTile(speed: 1.6) {
                    self?.scheduleNextCatAction()
                }
            }
        }
        run(SKAction.sequence([wait, roam]), withKey: "petRoutine")
    }

    private func scheduleNextBirdAction() {
        let waitTime = Double.random(in: 2.0...4.5)
        let wait = SKAction.wait(forDuration: waitTime)
        let birdAction = SKAction.run { [weak self] in
            if Bool.random() {
                self?.birdPeckSeed {
                    self?.scheduleNextBirdAction()
                }
            } else {
                self?.birdFlyToNewSpot {
                    self?.scheduleNextBirdAction()
                }
            }
        }
        run(SKAction.sequence([wait, birdAction]), withKey: "birdRoutine")
    }

    // MARK: - Actions

    private func roamToAdjacentTile(speed: TimeInterval, completion: @escaping () -> Void) {
        guard !isBusy else { completion(); return }
        isBusy = true

        let dCol = Int.random(in: -1...1)
        let dRow = Int.random(in: -1...1)
        guard dCol != 0 || dRow != 0 else {
            isBusy = false
            completion()
            return
        }

        let newCol = max(-4, min(4, currentGrid.col + dCol))
        let newRow = max(-4, min(4, currentGrid.row + dRow))
        let targetGrid = GridPoint(col: newCol, row: newRow)
        let targetPt = grid.gridToScreen(col: targetGrid.col, row: targetGrid.row)

        // Face travel direction
        spriteNode.xScale = (targetPt.x < position.x) ? -1.0 : 1.0

        // 2-frame walking cycle
        let f0 = (critterType == .dog) ? PixelArtAtlas.shared.petDog(frame: 0) : PixelArtAtlas.shared.petCat(frame: 0)
        let f1 = (critterType == .dog) ? PixelArtAtlas.shared.petDog(frame: 1) : PixelArtAtlas.shared.petCat(frame: 1)
        let stepAnim = SKAction.repeatForever(SKAction.animate(with: [f0, f1], timePerFrame: 0.16))
        spriteNode.run(stepAnim, withKey: "walkStep")

        let move = SKAction.move(to: CGPoint(x: targetPt.x, y: targetPt.y), duration: speed)
        move.timingMode = .easeInEaseOut

        run(move) { [weak self] in
            guard let self else { return }
            self.currentGrid = targetGrid
            self.zPosition = self.grid.zPosition(col: targetGrid.col, row: targetGrid.row, layerOffset: 6)
            self.spriteNode.removeAction(forKey: "walkStep")
            self.spriteNode.texture = f0
            self.isBusy = false
            completion()
        }
    }

    private func catSitAndPurr(completion: @escaping () -> Void) {
        isBusy = true
        let sit = PixelArtAtlas.shared.petCat(frame: 0)
        spriteNode.texture = sit
        // Gentle tail curl twitch
        let twitch0 = SKAction.run { [weak self] in
            self?.spriteNode.texture = PixelArtAtlas.shared.petCat(frame: 1)
        }
        let twitch1 = SKAction.run { [weak self] in
            self?.spriteNode.texture = sit
        }
        let sequence = SKAction.sequence([
            SKAction.wait(forDuration: 1.0),
            twitch0,
            SKAction.wait(forDuration: 0.3),
            twitch1,
            SKAction.wait(forDuration: 1.5)
        ])
        run(sequence) { [weak self] in
            self?.isBusy = false
            completion()
        }
    }

    private func birdPeckSeed(completion: @escaping () -> Void) {
        isBusy = true
        let peckDown = SKAction.moveBy(x: 0, y: -1.5, duration: 0.12)
        let peckUp = SKAction.moveBy(x: 0, y: 1.5, duration: 0.12)
        let peckAnim = SKAction.repeat(SKAction.sequence([peckDown, peckUp, SKAction.wait(forDuration: 0.2)]), count: 3)
        run(peckAnim) { [weak self] in
            self?.isBusy = false
            completion()
        }
    }

    private func birdFlyToNewSpot(completion: @escaping () -> Void) {
        isBusy = true
        let dCol = Int.random(in: -3...3)
        let dRow = Int.random(in: -3...3)
        let targetGrid = GridPoint(col: max(-4, min(4, currentGrid.col + dCol)), row: max(-4, min(4, currentGrid.row + dRow)))
        let targetPt = grid.gridToScreen(col: targetGrid.col, row: targetGrid.row)

        let f0 = PixelArtAtlas.shared.flyingBird(frame: 0)
        let f1 = PixelArtAtlas.shared.flyingBird(frame: 1)
        let flapAnim = SKAction.repeatForever(SKAction.animate(with: [f0, f1], timePerFrame: 0.12))
        spriteNode.run(flapAnim, withKey: "flapAnim")

        // Smooth flight arc
        let midX = (position.x + targetPt.x) / 2.0
        let midY = max(position.y, targetPt.y) + 30.0
        let path = CGMutablePath()
        path.move(to: position)
        path.addQuadCurve(to: CGPoint(x: targetPt.x, y: targetPt.y), control: CGPoint(x: midX, y: midY))

        let flyAction = SKAction.follow(path, asOffset: false, orientToPath: false, duration: 1.4)
        flyAction.timingMode = .easeInEaseOut

        run(flyAction) { [weak self] in
            guard let self else { return }
            self.currentGrid = targetGrid
            self.zPosition = self.grid.zPosition(col: targetGrid.col, row: targetGrid.row, layerOffset: 6)
            self.spriteNode.removeAction(forKey: "flapAnim")
            self.spriteNode.texture = f0
            self.isBusy = false
            completion()
        }
    }
}
