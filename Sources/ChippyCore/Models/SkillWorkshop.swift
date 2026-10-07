import Foundation

/// Represents a skill directory manifested as a workshop in Chippy's world.
public struct SkillWorkshop: Sendable, Identifiable, Equatable {
    public let id: String
    public let name: String
    public let description: String
    public var districtID: DistrictID
    public let directoryURL: URL
    public let isRuined: Bool
    public let parseError: String?
    public let explicitDistrict: String?
    public let metadata: [String: String]

    public init(
        id: String,
        name: String,
        description: String,
        districtID: DistrictID,
        directoryURL: URL,
        isRuined: Bool = false,
        parseError: String? = nil,
        explicitDistrict: String? = nil,
        metadata: [String: String] = [:]
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.districtID = districtID
        self.directoryURL = directoryURL
        self.isRuined = isRuined
        self.parseError = parseError
        self.explicitDistrict = explicitDistrict
        self.metadata = metadata
    }
}
