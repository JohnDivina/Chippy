import Foundation

/// Represents integer coordinate on the 2D isometric diorama grid.
public struct GridPoint: Sendable, Hashable, Equatable {
    public let col: Int
    public let row: Int

    public init(col: Int, row: Int) {
        self.col = col
        self.row = row
    }
}

/// Represents a 2D floating-point position in scene space.
public struct ScenePoint: Sendable, Equatable {
    public let x: Double
    public let y: Double

    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }
}

/// Handles geometric coordinate conversions between 2D tile grid coordinates
/// and 2.5D isometric projection space.
public struct IsometricGrid: Sendable {
    public let tileWidth: Double
    public let tileHeight: Double

    public init(tileWidth: Double = 64.0, tileHeight: Double = 32.0) {
        self.tileWidth = tileWidth
        self.tileHeight = tileHeight
    }

    /// Converts grid coordinates (col, row) to isometric screen coordinates (x, y).
    public func gridToScreen(col: Int, row: Int, elevation: Double = 0) -> ScenePoint {
        let x = Double(col - row) * (tileWidth / 2.0)
        let y = Double(col + row) * (tileHeight / 2.0) + elevation
        return ScenePoint(x: x, y: y)
    }

    /// Converts isometric screen coordinates back to nearest grid coordinates.
    public func screenToGrid(x: Double, y: Double, elevation: Double = 0) -> GridPoint {
        let adjustedY = y - elevation
        let colD = (x / (tileWidth / 2.0) + adjustedY / (tileHeight / 2.0)) / 2.0
        let rowD = (adjustedY / (tileHeight / 2.0) - x / (tileWidth / 2.0)) / 2.0
        return GridPoint(col: Int(round(colD)), row: Int(round(rowD)))
    }

    /// Calculates depth zPosition for isometric Y-sorting.
    /// In an isometric scene, lower Y screen positions appear in front of higher Y positions.
    public func zPosition(col: Int, row: Int, layerOffset: Double = 0) -> Double {
        // Base depth decreases as (col + row) increases
        let baseDepth = -Double(col + row) * 10.0
        return baseDepth + layerOffset
    }
}
