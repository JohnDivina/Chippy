import SpriteKit
import AppKit
import ChippyCore

/// Generates and caches authentic 16-bit / 32-bit pixel-art textures inspired by Stardew Valley.
/// Uses nearest-neighbor sampling (`.nearest`) for crisp, razor-sharp retro visuals.
public final class PixelArtAtlas: @unchecked Sendable {
    public static let shared = PixelArtAtlas()

    private let cache = NSCache<NSString, SKTexture>()

    private init() {}

    // MARK: - Pixel Canvas Helper

    public final class Canvas {
        public let width: Int
        public let height: Int
        private var pixels: [UInt8] // Explicit RGBA bytes

        public init(width: Int, height: Int) {
            self.width = width
            self.height = height
            self.pixels = Array(repeating: 0, count: width * height * 4)
        }

        @inline(__always)
        public func setPixel(_ x: Int, _ y: Int, _ color: UInt32) {
            guard x >= 0, x < width, y >= 0, y < height else { return }
            let idx = (y * width + x) * 4
            let r = UInt8((color >> 24) & 0xFF)
            let g = UInt8((color >> 16) & 0xFF)
            let b = UInt8((color >> 8) & 0xFF)
            let a = UInt8(color & 0xFF)
            pixels[idx]     = r
            pixels[idx + 1] = g
            pixels[idx + 2] = b
            pixels[idx + 3] = a
        }

        @inline(__always)
        public func setPixel(_ x: Int, y: Int, _ color: UInt32) {
            setPixel(x, y, color)
        }

        public func fillRect(x: Int, y: Int, w: Int, h: Int, color: UInt32) {
            for dy in 0..<h {
                for dx in 0..<w {
                    setPixel(x + dx, y + dy, color)
                }
            }
        }

        public func fillIsoDiamond(tileW: Int, tileH: Int, topY: Int, baseColor: UInt32) {
            let cx = tileW / 2
            let cy = topY + tileH / 2
            let hw = tileW / 2
            let hh = tileH / 2

            for y in 0..<tileH {
                let actualY = topY + y
                let dy = abs(actualY - cy)
                let rowHalfWidth = Int(Double(hw) * (1.0 - Double(dy) / Double(hh)))
                for x in (cx - rowHalfWidth)...(cx + rowHalfWidth) {
                    setPixel(x, actualY, baseColor)
                }
            }
        }

        public func makeTexture() -> SKTexture {
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let bitmapInfo = CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue
            let data = pixels.withUnsafeBufferPointer { Data(buffer: $0) }
            guard let provider = CGDataProvider(data: data as CFData),
                  let cgImage = CGImage(
                    width: width,
                    height: height,
                    bitsPerComponent: 8,
                    bitsPerPixel: 32,
                    bytesPerRow: width * 4,
                    space: colorSpace,
                    bitmapInfo: CGBitmapInfo(rawValue: bitmapInfo),
                    provider: provider,
                    decode: nil,
                    shouldInterpolate: false,
                    intent: .defaultIntent
                  ) else {
                return SKTexture()
            }
            let texture = SKTexture(cgImage: cgImage)
            texture.filteringMode = .nearest
            return texture
        }
    }

    // MARK: - Terrain Tiles (64 × 32 Isometric Diamond)

    public func grassTile(variant: Int = 0) -> SKTexture {
        let key = "grass_\(variant)" as NSString
        if let cached = cache.object(forKey: key) { return cached }

        let c = Canvas(width: 64, height: 32)
        // Stardew Valley meadow palette
        let cBase: UInt32     = 0x4B7D38FF // Lush warm green
        let cDark: UInt32     = 0x3E6B2CFF // Shadow blade
        let cHighlight: UInt32 = 0x5C9646FF // Blade highlight
        let cFlower: UInt32    = 0xF8F9FAFF // Wild daisy petal
        let cCenter: UInt32    = 0xFDCB58FF // Flower center

        c.fillIsoDiamond(tileW: 64, tileH: 32, topY: 0, baseColor: cBase)

        // Dithered grass tufts
        for y in 4..<28 {
            for x in 10..<54 {
                let d = abs(x - 32) + 2 * abs(y - 16)
                guard d < 28 else { continue }
                if (x + y * 3) % 7 == 0 {
                    c.setPixel(x, y, cHighlight)
                    c.setPixel(x, y - 1, cHighlight)
                } else if (x * 2 + y) % 11 == 0 {
                    c.setPixel(x, y, cDark)
                }
            }
        }

        // Flower variants
        if variant == 1 {
            // White daisy patch
            let flowers = [(24, 14), (38, 18), (30, 22)]
            for (fx, fy) in flowers {
                c.setPixel(fx, fy, cCenter)
                c.setPixel(fx - 1, fy, cFlower)
                c.setPixel(fx + 1, fy, cFlower)
                c.setPixel(fx, fy - 1, cFlower)
                c.setPixel(fx, fy + 1, cFlower)
            }
        } else if variant == 2 {
            // Red berry/clover dots
            let clovers = [(20, 18), (42, 12), (34, 10)]
            for (cx, cy) in clovers {
                c.setPixel(cx, cy, 0xE63946FF)
                c.setPixel(cx + 1, cy, 0xE63946FF)
                c.setPixel(cx, cy + 1, 0x2A9D8FFF)
            }
        }

        let tex = c.makeTexture()
        cache.setObject(tex, forKey: key)
        return tex
    }

    public func pathTile() -> SKTexture {
        let key = "path_cobblestone" as NSString
        if let cached = cache.object(forKey: key) { return cached }

        let c = Canvas(width: 64, height: 32)
        let cSand: UInt32     = 0x8A6335FF // Sandy dirt outline
        let cBase: UInt32     = 0xBA8C52FF // Warm earthen dirt
        let cStone: UInt32    = 0x8D9096FF // River cobblestone
        let cStoneHi: UInt32  = 0xB5B8BDFF // Stone highlight
        let cStoneSh: UInt32  = 0x5C5E63FF // Stone shadow mortar

        c.fillIsoDiamond(tileW: 64, tileH: 32, topY: 0, baseColor: cBase)

        // Cobblestone paving patterns inside path
        let stones = [
            (24, 10, 6, 4), (34, 8, 8, 4), (18, 16, 7, 4),
            (28, 15, 8, 5), (39, 14, 7, 4), (22, 22, 8, 4),
            (32, 21, 7, 4), (43, 20, 6, 3)
        ]

        for (sx, sy, sw, sh) in stones {
            c.fillRect(x: sx, y: sy, w: sw, h: sh, color: cStone)
            // Top highlight
            c.fillRect(x: sx, y: sy, w: sw, h: 1, color: cStoneHi)
            c.fillRect(x: sx, y: sy, w: 1, h: sh, color: cStoneHi)
            // Bottom shadow
            c.fillRect(x: sx, y: sy + sh - 1, w: sw, h: 1, color: cStoneSh)
            c.fillRect(x: sx + sw - 1, y: sy, w: 1, h: sh, color: cStoneSh)
        }

        // Earth border grains
        for y in 0..<32 {
            for x in 0..<64 {
                let d = abs(x - 32) + 2 * abs(y - 16)
                if d >= 26 && d <= 30 {
                    c.setPixel(x, y, cSand)
                }
            }
        }

        let tex = c.makeTexture()
        cache.setObject(tex, forKey: key)
        return tex
    }

    public func gardenPatchTile() -> SKTexture {
        let key = "garden_patch" as NSString
        if let cached = cache.object(forKey: key) { return cached }

        let c = Canvas(width: 64, height: 32)
        let cSoilBase: UInt32   = 0x5A381EFF // Rich tilled soil
        let cSoilRidge: UInt32  = 0x3E2411FF // Furrow trench
        let cVine: UInt32       = 0x388E3CFF // Green crop vine
        let cPumpkin: UInt32    = 0xF3722CFF // Orange pumpkin body
        let cPumpkinHi: UInt32  = 0xF8961EFF // Pumpkin highlight
        let cStem: UInt32       = 0x2D6A4FFF // Pumpkin stem

        c.fillIsoDiamond(tileW: 64, tileH: 32, topY: 0, baseColor: cSoilBase)

        // Tilled furrow lines
        for y in 4..<28 {
            for x in 10..<54 {
                let d = abs(x - 32) + 2 * abs(y - 16)
                guard d < 28 else { continue }
                if y % 5 == 0 {
                    c.setPixel(x, y, cSoilRidge)
                }
            }
        }

        // Placed pumpkins with leaves
        let pumpkins = [(22, 12), (38, 11), (28, 19), (44, 18)]
        for (px, py) in pumpkins {
            // Leaf vine
            c.fillRect(x: px - 2, y: py + 2, w: 7, h: 2, color: cVine)
            // Pumpkin body
            c.fillRect(x: px - 1, y: py - 2, w: 5, h: 4, color: cPumpkin)
            c.fillRect(x: px, y: py - 3, w: 3, h: 6, color: cPumpkin)
            c.setPixel(px, py - 2, cPumpkinHi)
            // Stem
            c.setPixel(px + 1, py - 4, cStem)
        }

        let tex = c.makeTexture()
        cache.setObject(tex, forKey: key)
        return tex
    }

    public func waterPondTile() -> SKTexture {
        let key = "water_pond" as NSString
        if let cached = cache.object(forKey: key) { return cached }

        let c = Canvas(width: 64, height: 32)
        let cDeepWater: UInt32  = 0x245C8AFF
        let cMidWater: UInt32   = 0x357DA8FF
        let cRipple: UInt32     = 0x72B5E8FF
        let cLilypad: UInt32    = 0x2D7A3EFF
        let cFlower: UInt32     = 0xF72585FF

        c.fillIsoDiamond(tileW: 64, tileH: 32, topY: 0, baseColor: cMidWater)

        // Center deep water
        for y in 6..<26 {
            for x in 16..<48 {
                let d = abs(x - 32) + 2 * abs(y - 16)
                if d < 18 { c.setPixel(x, y, cDeepWater) }
            }
        }

        // Animated surface ripples
        let ripples = [(22, 11), (36, 9), (28, 18), (42, 20)]
        for (rx, ry) in ripples {
            c.fillRect(x: rx, y: ry, w: 5, h: 1, color: cRipple)
        }

        // Lily pads with lotus flower
        let lilypads = [(24, 15), (40, 16)]
        for (lx, ly) in lilypads {
            c.fillRect(x: lx - 2, y: ly - 1, w: 5, h: 3, color: cLilypad)
            c.setPixel(lx + 1, ly, cDeepWater) // Lily pad slit
            c.setPixel(lx, ly - 1, cFlower)    // Lotus blossom
        }

        let tex = c.makeTexture()
        cache.setObject(tex, forKey: key)
        return tex
    }

    public func cliffWall() -> SKTexture {
        let key = "cliff_wall" as NSString
        if let cached = cache.object(forKey: key) { return cached }

        let c = Canvas(width: 64, height: 28)
        let cBedrock1: UInt32 = 0x483222FF
        let cBedrock2: UInt32 = 0x352317FF
        let cBedrock3: UInt32 = 0x24160DFF
        let cStrata: UInt32   = 0x5C412CFF

        c.fillRect(x: 0, y: 0, w: 64, h: 28, color: cBedrock2)

        // Layered geological strata
        for y in 0..<28 {
            for x in 0..<64 {
                if y % 6 == 0 {
                    c.setPixel(x, y, cStrata)
                } else if y > 18 {
                    c.setPixel(x, y, cBedrock3)
                } else if (x + y * 2) % 9 == 0 {
                    c.setPixel(x, y, cBedrock1)
                }
            }
        }

        let tex = c.makeTexture()
        cache.setObject(tex, forKey: key)
        return tex
    }

    // MARK: - Foliage & Scenery Props

    public func appleTree() -> SKTexture {
        let key = "scenery_apple_tree" as NSString
        if let cached = cache.object(forKey: key) { return cached }

        let c = Canvas(width: 48, height: 60)

        // Wood trunk palette
        let cTrunk: UInt32   = 0x543A21FF
        let cTrunkSh: UInt32 = 0x3B2613FF
        let cTrunkHi: UInt32 = 0x755230FF

        // Foliage canopy palette (Stardew multi-tier green)
        let cLeafDark: UInt32 = 0x1E4F22FF
        let cLeafMid: UInt32  = 0x2D7332FF
        let cLeafHi: UInt32   = 0x479E4EFF

        // Red apple palette
        let cApple: UInt32   = 0xD90429FF
        let cAppleHi: UInt32 = 0xFF758FFF

        // 1. Draw trunk with roots
        c.fillRect(x: 21, y: 34, w: 6, h: 22, color: cTrunk)
        c.fillRect(x: 21, y: 34, w: 2, h: 22, color: cTrunkHi)
        c.fillRect(x: 25, y: 34, w: 2, h: 22, color: cTrunkSh)
        // Root flare at ground
        c.fillRect(x: 18, y: 52, w: 5, h: 5, color: cTrunkSh)
        c.fillRect(x: 25, y: 52, w: 5, h: 5, color: cTrunkSh)

        // 2. Draw spherical leafy canopy (layers of circles)
        let cx = 24
        let cy = 24
        let radius = 18

        for y in 0..<44 {
            for x in 0..<48 {
                let dx = x - cx
                let dy = y - cy
                let distSq = dx * dx + dy * dy
                if distSq <= radius * radius {
                    // Shading by vertical position and cluster
                    if dy > 5 {
                        c.setPixel(x, y, cLeafDark)
                    } else if dy < -4 || (dx < 0 && dy < 2) {
                        c.setPixel(x, y, cLeafHi)
                    } else {
                        c.setPixel(x, y, cLeafMid)
                    }
                }
            }
        }

        // 3. Apples with gleam
        let apples = [
            (15, 18), (28, 14), (20, 26), (33, 22), (24, 30), (16, 28)
        ]
        for (ax, ay) in apples {
            c.fillRect(x: ax - 1, y: ay - 1, w: 3, h: 3, color: cApple)
            c.setPixel(ax, ay - 1, cAppleHi) // Gleam dot
        }

        let tex = c.makeTexture()
        cache.setObject(tex, forKey: key)
        return tex
    }

    public func woodenFence() -> SKTexture {
        let key = "scenery_wooden_fence" as NSString
        if let cached = cache.object(forKey: key) { return cached }

        let c = Canvas(width: 32, height: 24)
        let cPost: UInt32    = 0x8C5E35FF
        let cPostSh: UInt32  = 0x5E3D1EFF
        let cPostHi: UInt32  = 0xB57E48FF
        let cNail: UInt32    = 0x333333FF

        // Two vertical fence posts
        let posts = [4, 24]
        for px in posts {
            c.fillRect(x: px, y: 4, w: 4, h: 18, color: cPost)
            c.fillRect(x: px, y: 4, w: 1, h: 18, color: cPostHi)
            c.fillRect(x: px + 3, y: 4, w: 1, h: 18, color: cPostSh)
            // Post cap bevel
            c.setPixel(px, y: 3, cPostHi)
            c.setPixel(px + 1, y: 2, cPostHi)
            c.setPixel(px + 2, y: 2, cPost)
            c.setPixel(px + 3, y: 3, cPostSh)
        }

        // Two horizontal rails
        let railsY = [8, 14]
        for ry in railsY {
            c.fillRect(x: 2, y: ry, w: 28, h: 3, color: cPost)
            c.fillRect(x: 2, y: ry, w: 28, h: 1, color: cPostHi)
            c.fillRect(x: 2, y: ry + 2, w: 28, h: 1, color: cPostSh)
            // Nail iron heads
            c.setPixel(5, ry + 1, cNail)
            c.setPixel(25, ry + 1, cNail)
        }

        let tex = c.makeTexture()
        cache.setObject(tex, forKey: key)
        return tex
    }

    public func streetLantern() -> SKTexture {
        let key = "scenery_street_lantern" as NSString
        if let cached = cache.object(forKey: key) { return cached }

        let c = Canvas(width: 20, height: 32)
        let cIron: UInt32   = 0x3F4245FF
        let cGlow: UInt32   = 0xFEE440FF // Warm amber lantern light
        let cGlowHi: UInt32 = 0xFFFFFFFF // Hot flame center
        let cWood: UInt32   = 0x6E4A2EFF

        // Timber post
        c.fillRect(x: 9, y: 12, w: 3, h: 19, color: cWood)

        // Iron bracket
        c.fillRect(x: 9, y: 6, w: 7, h: 2, color: cIron)
        c.fillRect(x: 14, y: 8, w: 2, h: 3, color: cIron)

        // Glass lantern cage
        c.fillRect(x: 12, y: 10, w: 6, h: 7, color: cIron)
        c.fillRect(x: 13, y: 11, w: 4, h: 5, color: cGlow)
        c.setPixel(14, y: 13, cGlowHi)

        let tex = c.makeTexture()
        cache.setObject(tex, forKey: key)
        return tex
    }

    // MARK: - Stardew Valley Cottages & District Workshops (64 × 60)

    public func citadelCottage() -> SKTexture {
        let key = "cottage_citadel" as NSString
        if let cached = cache.object(forKey: key) { return cached }

        let c = Canvas(width: 64, height: 60)
        let cWall: UInt32       = 0xD8C29DFF // Plaster & stone timber
        let cBeam: UInt32       = 0x654321FF // Dark oak support beams
        let cRoofGreen: UInt32  = 0x245C3BFF // Stardew emerald shingles
        let cRoofHi: UInt32     = 0x3A8557FF // Shingle highlight ridge
        let cRoofSh: UInt32     = 0x163D26FF // Shingle shadow
        let cDoor: UInt32       = 0x82491EFF // Oak arched door
        let cWindowGlow: UInt32 = 0xFEE440FF // Amber room glow
        let cChimney: UInt32    = 0x6E7075FF // Riverstone chimney
        let cCrown: UInt32      = 0xF9C74FFF // Sovereign golden crest

        // 1. Riverstone Chimney on left with smoke
        c.fillRect(x: 8, y: 4, w: 8, h: 32, color: cChimney)
        c.fillRect(x: 7, y: 3, w: 10, h: 3, color: 0x495057FF) // Chimney cap
        // Smoke puff
        c.fillRect(x: 9, y: 0, w: 4, h: 3, color: 0xE9ECEFFF)

        // 2. Main Wall Body
        c.fillRect(x: 12, y: 26, w: 40, h: 30, color: cWall)
        // Timber framing beams
        c.fillRect(x: 12, y: 26, w: 3, h: 30, color: cBeam)
        c.fillRect(x: 49, y: 26, w: 3, h: 30, color: cBeam)
        c.fillRect(x: 12, y: 53, w: 40, h: 3, color: cBeam) // Foundation beam

        // 3. Peaked Shingle Roof
        for row in 0..<16 {
            let y = 11 + row
            let roofW = 40 + (row * 2)
            c.fillRect(x: 12 - (row), y: y, w: roofW, h: 1, color: (row % 3 == 0) ? cRoofHi : cRoofGreen)
            c.setPixel(12 - row, y, cRoofSh)
            c.setPixel(12 - row + roofW - 1, y, cRoofSh)
        }

        // 4. Arched Oak Doorway
        c.fillRect(x: 27, y: 38, w: 10, h: 16, color: cDoor)
        c.fillRect(x: 29, y: 36, w: 6, h: 2, color: cDoor) // Arch top
        c.fillRect(x: 35, y: 46, w: 2, h: 2, color: 0xD4AF37FF) // Brass knob

        // 5. Lit Windows with Panes
        let windows = [(17, 34), (41, 34)]
        for (wx, wy) in windows {
            c.fillRect(x: wx, y: wy, w: 7, h: 8, color: cWindowGlow)
            // Window frame & mullion
            c.fillRect(x: wx, y: wy, w: 7, h: 1, color: cBeam)
            c.fillRect(x: wx, y: wy + 7, w: 7, h: 1, color: cBeam)
            c.fillRect(x: wx, y: wy, w: 1, h: 8, color: cBeam)
            c.fillRect(x: wx + 6, y: wy, w: 1, h: 8, color: cBeam)
            c.fillRect(x: wx + 3, y: wy, w: 1, h: 8, color: cBeam)
            c.fillRect(x: wx, y: wy + 4, w: 7, h: 1, color: cBeam)
        }

        // 6. Sovereign Golden Crest over doorway
        c.fillRect(x: 30, y: 30, w: 4, h: 3, color: cCrown)
        c.setPixel(30, y: 29, cCrown)
        c.setPixel(32, y: 29, cCrown)
        c.setPixel(34, y: 29, cCrown)

        let tex = c.makeTexture()
        cache.setObject(tex, forKey: key)
        return tex
    }

    public func ironBastionForge() -> SKTexture {
        let key = "cottage_iron_bastion" as NSString
        if let cached = cache.object(forKey: key) { return cached }

        let c = Canvas(width: 64, height: 60)
        let cStone: UInt32    = 0x5A5E66FF // Heavy granite masonry
        let cStoneSh: UInt32  = 0x3A3C42FF
        let cSlateRoof: UInt32 = 0x2E3033FF // Charcoal black forge slate
        let cRoofHi: UInt32   = 0x484B52FF
        let cAnvil: UInt32    = 0x1F2022FF // Heavy iron anvil
        let cForgeFire: UInt32 = 0xF3722CFF // Blazing forge window
        let cWoodPost: UInt32 = 0x543A21FF

        // Heavy Stone Walls
        c.fillRect(x: 14, y: 24, w: 38, h: 32, color: cStone)
        for y in stride(from: 26, to: 54, by: 4) {
            for x in stride(from: 14, to: 50, by: 8) {
                c.fillRect(x: x, y: y, w: 7, h: 1, color: cStoneSh)
            }
        }

        // Broad Slate Roof
        for row in 0..<14 {
            let y = 12 + row
            let w = 42 + (row * 2)
            c.fillRect(x: 12 - row, y: y, w: w, h: 1, color: (row % 2 == 0) ? cRoofHi : cSlateRoof)
        }

        // Glowing Forge Furnace Window
        c.fillRect(x: 20, y: 32, w: 10, h: 10, color: cForgeFire)
        c.fillRect(x: 22, y: 34, w: 6, h: 6, color: 0xF9C74FFF) // Yellow heart flame

        // Heavy Reinforced Iron Door
        c.fillRect(x: 35, y: 36, w: 11, h: 18, color: 0x343A40FF)
        c.fillRect(x: 35, y: 40, w: 11, h: 2, color: 0x1A1D20FF)
        c.fillRect(x: 35, y: 48, w: 11, h: 2, color: 0x1A1D20FF)

        // Front Porch with Anvil
        c.fillRect(x: 10, y: 48, w: 10, h: 8, color: cWoodPost) // Log porch stump
        // Iron Anvil on log
        c.fillRect(x: 11, y: 45, w: 8, h: 3, color: cAnvil)
        c.fillRect(x: 9, y: 44, w: 12, h: 2, color: cAnvil) // Horn & heel

        let tex = c.makeTexture()
        cache.setObject(tex, forKey: key)
        return tex
    }

    public func grandAtelierCottage() -> SKTexture {
        let key = "cottage_grand_atelier" as NSString
        if let cached = cache.object(forKey: key) { return cached }

        let c = Canvas(width: 64, height: 60)
        let cWall: UInt32      = 0xE9D8A6FF // Warm cedar stucco
        let cShingle: UInt32   = 0xAE2012FF // Terracotta artisan tiles
        let cShingleHi: UInt32 = 0xCA6702FF
        let cGlass: UInt32     = 0x94D2BDFF // Artisan glass
        let cFlowerRed: UInt32 = 0xE63946FF
        let cFlowerYel: UInt32 = 0xFFB703FF
        let cLeaf: UInt32      = 0x2D6A4FFF

        // Walls
        c.fillRect(x: 14, y: 24, w: 38, h: 32, color: cWall)

        // Curved Artisan Roof
        for row in 0..<14 {
            let y = 12 + row
            let w = 42 + (row * 2)
            c.fillRect(x: 12 - row, y: y, w: w, h: 1, color: (row % 2 == 0) ? cShingleHi : cShingle)
        }

        // Bay Window with Flower Box
        c.fillRect(x: 18, y: 32, w: 14, h: 12, color: cGlass)
        // Window mullions
        c.fillRect(x: 24, y: 32, w: 2, h: 12, color: 0x6E4A2EFF)
        c.fillRect(x: 18, y: 37, w: 14, h: 2, color: 0x6E4A2EFF)
        // Flower Box under window
        c.fillRect(x: 17, y: 44, w: 16, h: 4, color: 0x5C3A1EFF)
        // Blooming Flowers
        c.fillRect(x: 18, y: 42, w: 14, h: 2, color: cLeaf)
        c.setPixel(19, y: 41, cFlowerRed)
        c.setPixel(22, y: 41, cFlowerYel)
        c.setPixel(25, y: 41, cFlowerRed)
        c.setPixel(28, y: 41, cFlowerYel)

        // Cozy Wooden Door
        c.fillRect(x: 37, y: 34, w: 10, h: 20, color: 0x774936FF)
        c.fillRect(x: 39, y: 36, w: 6, h: 6, color: cGlass) // Door window

        let tex = c.makeTexture()
        cache.setObject(tex, forKey: key)
        return tex
    }

    public func engineCoreMill() -> SKTexture {
        let key = "cottage_engine_core" as NSString
        if let cached = cache.object(forKey: key) { return cached }

        let c = Canvas(width: 64, height: 60)
        let cBrick: UInt32     = 0x8D5B4CFF // Industrial brickwork
        let cRoof: UInt32      = 0x495057FF // Slate roof
        let cWheel: UInt32     = 0x5E3023FF // Waterwheel timber
        let cGearCopper: UInt32 = 0xCA6702FF // Copper clockwork cog

        // Brick Millhouse
        c.fillRect(x: 16, y: 22, w: 36, h: 34, color: cBrick)

        // Slate Roof
        for row in 0..<13 {
            let y = 11 + row
            let w = 40 + (row * 2)
            c.fillRect(x: 14 - row, y: y, w: w, h: 1, color: cRoof)
        }

        // Wooden Waterwheel on Left Side
        let wx = 8
        let wy = 42
        c.fillRect(x: wx - 4, y: wy - 8, w: 8, h: 16, color: cWheel)
        c.fillRect(x: wx - 8, y: wy - 4, w: 16, h: 8, color: cWheel)
        c.fillRect(x: wx - 2, y: wy - 2, w: 4, h: 4, color: cGearCopper) // Hub

        // Industrial Arched Door & Pipe
        c.fillRect(x: 28, y: 34, w: 12, h: 20, color: 0x343A40FF)
        // Copper Steam Pipe on right roof
        c.fillRect(x: 44, y: 4, w: 4, h: 18, color: cGearCopper)
        c.fillRect(x: 42, y: 4, w: 8, h: 2, color: cGearCopper)

        let tex = c.makeTexture()
        cache.setObject(tex, forKey: key)
        return tex
    }

    public func scriptoriumArchive() -> SKTexture {
        let key = "cottage_scriptorium" as NSString
        if let cached = cache.object(forKey: key) { return cached }

        let c = Canvas(width: 64, height: 60)
        let cStone: UInt32    = 0x4A4E69FF // Navy stone masonry
        let cRoofBlue: UInt32 = 0x22223BFF // Deep scholar midnight blue
        let cParchment: UInt32 = 0xF2E9E4FF // Parchment scroll banner
        let cRoseWindow: UInt32 = 0x9A8C98FF // Stained glass

        // Stone Walls
        c.fillRect(x: 14, y: 22, w: 38, h: 34, color: cStone)

        // Steep Scholar Gabled Roof
        for row in 0..<15 {
            let y = 9 + row
            let w = 38 + (row * 2)
            c.fillRect(x: 14 - row, y: y, w: w, h: 1, color: cRoofBlue)
        }

        // Circular Rose Window
        let rx = 33
        let ry = 28
        c.fillRect(x: rx - 4, y: ry - 4, w: 8, h: 8, color: cRoseWindow)
        c.fillRect(x: rx - 2, y: ry - 2, w: 4, h: 4, color: 0xFEE440FF) // Golden glow center

        // Arched Archive Entrance
        c.fillRect(x: 28, y: 38, w: 10, h: 16, color: 0x4A3B32FF)

        // Rolled Parchment Scroll Signboard
        c.fillRect(x: 18, y: 38, w: 7, h: 5, color: cParchment)
        c.setPixel(19, y: 40, 0x222222FF) // Text ink

        let tex = c.makeTexture()
        cache.setObject(tex, forKey: key)
        return tex
    }

    public func wanderersMarketStalls() -> SKTexture {
        let key = "cottage_wanderers_market" as NSString
        if let cached = cache.object(forKey: key) { return cached }

        let c = Canvas(width: 64, height: 60)
        let cAwningRed: UInt32 = 0xE63946FF // Striped market canvas
        let cAwningWht: UInt32 = 0xF1FAEEFF
        let cWoodPost: UInt32  = 0x7F4F24FF
        let cCrate: UInt32     = 0x936639FF
        let cApple: UInt32     = 0xD90429FF
        let cPumpkin: UInt32   = 0xF3722CFF

        // Four Timber Posts
        c.fillRect(x: 12, y: 18, w: 3, h: 36, color: cWoodPost)
        c.fillRect(x: 49, y: 18, w: 3, h: 36, color: cWoodPost)

        // Striped Canvas Awning Canopy
        for x in 8..<56 {
            let color = ((x / 6) % 2 == 0) ? cAwningRed : cAwningWht
            c.fillRect(x: x, y: 12, w: 1, h: 12, color: color)
            // Scalloped awning edge
            if x % 4 != 0 {
                c.setPixel(x, 24, color)
            }
        }

        // Wooden Display Counter
        c.fillRect(x: 15, y: 36, w: 34, h: 16, color: cWoodPost)

        // Produce Crates on counter
        c.fillRect(x: 18, y: 34, w: 12, h: 6, color: cCrate)
        // Apples inside crate
        c.fillRect(x: 19, y: 33, w: 10, h: 2, color: cApple)

        c.fillRect(x: 34, y: 34, w: 12, h: 6, color: cCrate)
        // Pumpkins inside crate
        c.fillRect(x: 35, y: 33, w: 10, h: 2, color: cPumpkin)

        let tex = c.makeTexture()
        cache.setObject(tex, forKey: key)
        return tex
    }

    // MARK: - Animated Pixel Familiars (20 × 28)

    public func familiarSprite(kind: FamiliarKind, frame: Int = 0) -> SKTexture {
        let key = "familiar_\(kind.rawValue)_\(frame)" as NSString
        if let cached = cache.object(forKey: key) { return cached }

        let c = Canvas(width: 24, height: 32)
        let cSkin: UInt32   = 0xFFDBACFF // Warm character skin tone
        let cEyes: UInt32   = 0x1A1A1AFF
        let cShoes: UInt32  = 0x3E2723FF

        // Bobbing vertical offset for walk animation
        let bob = (frame == 1) ? -1 : 0

        // Class-specific outfit colors
        let (cOutfit, cHat, cAccessory): (UInt32, UInt32, UInt32) = {
            switch kind {
            case .sovereign:
                return (0x1D3557FF, 0xF9C74FFF, 0xE63946FF) // Royal navy, golden crown, cape
            case .scout:
                return (0x2D6A4FFF, 0x588157FF, 0xD4A373FF) // Explorer green, feather cap, satchel
            case .mason:
                return (0x3A5A40FF, 0x415A77FF, 0x9B2226FF) // Denim overalls, red flannel
            case .weaver:
                return (0x6D597AFF, 0xB56576FF, 0xE56B6FFF) // Plum apron, artist beret
            case .sentinel:
                return (0x6C757DFF, 0xADB5BDFF, 0x212529FF) // Knight armor, visor helm, shield
            case .scribe:
                return (0x3D405BFF, 0x81B29AFF, 0xF4F1DEFF) // Navy robes, scroll
            case .arbiter:
                return (0x2B2D42FF, 0x8D99AEFF, 0xEDF2F4FF) // Formal inspector suit
            }
        }()

        // 1. Head & Hair/Hat
        c.fillRect(x: 8, y: 8 + bob, w: 8, h: 8, color: cSkin)
        // Eyes
        c.fillRect(x: 9, y: 11 + bob, w: 2, h: 2, color: cEyes)
        c.fillRect(x: 13, y: 11 + bob, w: 2, h: 2, color: cEyes)

        // Headwear
        if kind == .sovereign {
            // Golden Crown
            c.fillRect(x: 8, y: 5 + bob, w: 8, h: 3, color: cHat)
            c.setPixel(8, y: 4 + bob, cHat)
            c.setPixel(11, y: 4 + bob, cHat)
            c.setPixel(15, y: 4 + bob, cHat)
        } else {
            // Farmer / Cap Hat
            c.fillRect(x: 6, y: 6 + bob, w: 12, h: 3, color: cHat)
            c.fillRect(x: 8, y: 4 + bob, w: 8, h: 3, color: cHat)
        }

        // 2. Torso / Clothes
        c.fillRect(x: 7, y: 16 + bob, w: 10, h: 8, color: cOutfit)

        // 3. Accessory (Cape, Satchel, or Shield)
        if kind == .sovereign {
            // Flowing royal cape on back
            c.fillRect(x: 5, y: 16 + bob, w: 2, h: 9, color: cAccessory)
            c.fillRect(x: 17, y: 16 + bob, w: 2, h: 9, color: cAccessory)
        } else if kind == .sentinel {
            // Knight Shield on side
            c.fillRect(x: 4, y: 17 + bob, w: 3, h: 7, color: 0xCED4DAFF)
        } else if kind == .scribe {
            // White rolled scroll in hand
            c.fillRect(x: 17, y: 18 + bob, w: 3, h: 5, color: cAccessory)
        }

        // 4. Legs & Shoes (walking stride animation)
        if frame == 0 {
            // Idle feet
            c.fillRect(x: 8, y: 24, w: 3, h: 5, color: cShoes)
            c.fillRect(x: 13, y: 24, w: 3, h: 5, color: cShoes)
        } else {
            // Walking split feet
            c.fillRect(x: 7, y: 23, w: 3, h: 6, color: cShoes)
            c.fillRect(x: 14, y: 25, w: 3, h: 4, color: cShoes)
        }

        let tex = c.makeTexture()
        cache.setObject(tex, forKey: key)
        return tex
    }

    // MARK: - Pets & Wildlife (Dog, Cat, Birds)

    public func petDog(frame: Int = 0) -> SKTexture {
        let key = "pet_dog_\(frame)" as NSString
        if let cached = cache.object(forKey: key) { return cached }

        let c = Canvas(width: 24, height: 18)
        let cFur: UInt32     = 0xD4A373FF // Golden retriever coat
        let cFurDark: UInt32 = 0x99582AFF // Dark ear & tail shadow
        let cFurLight: UInt32 = 0xFAEDCDFF // Muzzle highlight
        let cCollar: UInt32  = 0xE63946FF // Red collar
        let cEyesNose: UInt32 = 0x1A1A1AFF

        // Body
        c.fillRect(x: 5, y: 7, w: 12, h: 6, color: cFur)

        // Head
        c.fillRect(x: 13, y: 3, w: 7, h: 6, color: cFur)
        // Muzzle
        c.fillRect(x: 17, y: 5, w: 4, h: 4, color: cFurLight)
        c.setPixel(20, y: 5, cEyesNose) // Nose
        c.setPixel(16, y: 4, cEyesNose) // Eye

        // Floppy Ear
        c.fillRect(x: 13, y: 4, w: 3, h: 5, color: cFurDark)

        // Red collar
        c.fillRect(x: 13, y: 8, w: 2, h: 3, color: cCollar)

        // Tail (wags)
        if frame == 0 {
            c.fillRect(x: 2, y: 4, w: 4, h: 3, color: cFurDark) // Tail up
            c.setPixel(1, y: 3, cFurDark)
        } else {
            c.fillRect(x: 1, y: 7, w: 4, h: 3, color: cFurDark) // Tail out
        }

        // 4 Paws / Legs (walking cycle)
        if frame == 0 {
            c.fillRect(x: 6, y: 13, w: 2, h: 4, color: cFur)
            c.fillRect(x: 9, y: 13, w: 2, h: 4, color: cFurDark)
            c.fillRect(x: 14, y: 13, w: 2, h: 4, color: cFur)
            c.fillRect(x: 17, y: 13, w: 2, h: 4, color: cFurDark)
        } else {
            c.fillRect(x: 5, y: 12, w: 2, h: 5, color: cFur)
            c.fillRect(x: 10, y: 13, w: 2, h: 4, color: cFurDark)
            c.fillRect(x: 13, y: 13, w: 2, h: 4, color: cFur)
            c.fillRect(x: 18, y: 12, w: 2, h: 5, color: cFurDark)
        }

        let tex = c.makeTexture()
        cache.setObject(tex, forKey: key)
        return tex
    }

    public func petCat(frame: Int = 0) -> SKTexture {
        let key = "pet_cat_\(frame)" as NSString
        if let cached = cache.object(forKey: key) { return cached }

        let c = Canvas(width: 20, height: 16)
        let cCoat: UInt32   = 0xE76F51FF // Ginger tabby orange
        let cStripe: UInt32 = 0xBC6C25FF // Dark tabby stripe
        let cWhite: UInt32  = 0xF8F9FAFF // White paws & muzzle
        let cEyeGreen: UInt32 = 0x2A9D8FFF // Cat emerald eyes

        // Body
        c.fillRect(x: 4, y: 6, w: 10, h: 5, color: cCoat)
        c.fillRect(x: 7, y: 6, w: 1, h: 5, color: cStripe)
        c.fillRect(x: 10, y: 6, w: 1, h: 5, color: cStripe)

        // Head
        c.fillRect(x: 11, y: 3, w: 6, h: 5, color: cCoat)
        // Pointed ears
        c.setPixel(12, y: 1, cCoat)
        c.setPixel(15, y: 1, cCoat)
        c.setPixel(12, y: 2, 0xFFA5ABFF) // Pink inner ear
        c.setPixel(15, y: 2, 0xFFA5ABFF)

        // Face
        c.setPixel(14, y: 4, cEyeGreen) // Green eye
        c.fillRect(x: 15, y: 5, w: 2, h: 2, color: cWhite) // White muzzle

        // Curled Tail
        if frame == 0 {
            c.fillRect(x: 1, y: 4, w: 3, h: 4, color: cStripe)
            c.setPixel(2, y: 3, cStripe)
        } else {
            c.fillRect(x: 1, y: 6, w: 3, h: 2, color: cStripe)
            c.setPixel(0, y: 5, cStripe)
        }

        // Legs & White Paws
        if frame == 0 {
            c.fillRect(x: 5, y: 11, w: 2, h: 3, color: cCoat)
            c.fillRect(x: 5, y: 14, w: 2, h: 1, color: cWhite)
            c.fillRect(x: 12, y: 11, w: 2, h: 3, color: cCoat)
            c.fillRect(x: 12, y: 14, w: 2, h: 1, color: cWhite)
        } else {
            c.fillRect(x: 4, y: 11, w: 2, h: 3, color: cCoat)
            c.fillRect(x: 4, y: 14, w: 2, h: 1, color: cWhite)
            c.fillRect(x: 13, y: 11, w: 2, h: 3, color: cCoat)
            c.fillRect(x: 13, y: 14, w: 2, h: 1, color: cWhite)
        }

        let tex = c.makeTexture()
        cache.setObject(tex, forKey: key)
        return tex
    }

    public func flyingBird(frame: Int = 0) -> SKTexture {
        let key = "flying_bird_\(frame)" as NSString
        if let cached = cache.object(forKey: key) { return cached }

        let c = Canvas(width: 14, height: 14)
        let cBody: UInt32 = 0x6F4E37FF // Warm brown sparrow
        let cChest: UInt32 = 0xD2B48CFF // Buff chest
        let cBeak: UInt32 = 0xF4A261FF

        // Head & Body
        c.fillRect(x: 4, y: 5, w: 5, h: 4, color: cBody)
        c.fillRect(x: 7, y: 6, w: 2, h: 3, color: cChest)
        c.setPixel(9, y: 6, cBeak) // Yellow beak
        c.setPixel(7, y: 5, 0x1A1A1AFF) // Eye

        // Tail feathers
        c.fillRect(x: 1, y: 7, w: 3, h: 2, color: 0x4A3322FF)

        if frame == 0 {
            // Perched: wings folded
            c.fillRect(x: 3, y: 5, w: 3, h: 3, color: 0x4A3322FF)
            // Tiny feet
            c.setPixel(5, y: 9, 0xE76F51FF)
            c.setPixel(7, y: 9, 0xE76F51FF)
        } else {
            // In flight: wings spread wide
            c.fillRect(x: 4, y: 1, w: 4, h: 3, color: 0x4A3322FF) // Wing up
            c.fillRect(x: 2, y: 2, w: 2, h: 2, color: 0x4A3322FF)
            c.fillRect(x: 4, y: 9, w: 3, h: 2, color: 0x4A3322FF) // Wing down
        }

        let tex = c.makeTexture()
        cache.setObject(tex, forKey: key)
        return tex
    }
}
