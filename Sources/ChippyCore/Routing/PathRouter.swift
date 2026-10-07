import Foundation

/// Destination route assigned to a file path.
public struct PathRoute: Sendable, Equatable {
    public let familiar: FamiliarKind
    public let district: DistrictID
    public let landmarkKey: String

    public init(familiar: FamiliarKind, district: DistrictID, landmarkKey: String) {
        self.familiar = familiar
        self.district = district
        self.landmarkKey = landmarkKey
    }
}

/// Dispatches file operations to the responsible Familiar and District based on path semantics.
public struct PathRouter: Sendable {
    public init() {}

    /// Static convenience router.
    public static func route(filePath: String) -> PathRoute {
        PathRouter().route(filePath: filePath)
    }

    /// Routes a file path to its responsible familiar and workshop landmark.
    public func route(filePath: String) -> PathRoute {
        let path = filePath.lowercased()
        let filename = URL(fileURLWithPath: filePath).lastPathComponent.lowercased()

        // 1. Tests -> Sentinel at Iron Bastion
        if path.contains("tests") || filename.contains(".test.") || filename.contains(".spec.") {
            return PathRoute(familiar: .sentinel, district: .ironBastion, landmarkKey: DistrictID.ironBastion.rawValue)
        }

        // 2. Documentation & Markdown -> Scribe at Scriptorium
        if filename.hasSuffix(".md") || filename.hasSuffix(".markdown") || filename.hasSuffix(".txt") {
            return PathRoute(familiar: .scribe, district: .scriptorium, landmarkKey: DistrictID.scriptorium.rawValue)
        }

        // 3. Frontend & UI styling -> Weaver at Grand Atelier
        let frontendExtensions = [".tsx", ".jsx", ".css", ".scss", ".html", ".vue", ".svelte"]
        let isFrontendExtension = frontendExtensions.contains { filename.hasSuffix($0) }
        let isSwiftUIView = filename.hasSuffix("view.swift")

        if isFrontendExtension || isSwiftUIView {
            return PathRoute(familiar: .weaver, district: .grandAtelier, landmarkKey: DistrictID.grandAtelier.rawValue)
        }

        // 4. Backend, systems, and core code -> Mason at Engine Core
        return PathRoute(familiar: .mason, district: .engineCore, landmarkKey: DistrictID.engineCore.rawValue)
    }
}
