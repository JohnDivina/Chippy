import Foundation

/// Result of parsing YAML frontmatter from a markdown file.
public struct ParsedFrontmatter: Sendable, Equatable {
    public let name: String?
    public let description: String?
    public let district: String?
    public let metadata: [String: String]
    public let body: String
    public let isValid: Bool
    public let parseError: String?

    public init(
        name: String? = nil,
        description: String? = nil,
        district: String? = nil,
        metadata: [String: String] = [:],
        body: String = "",
        isValid: Bool = true,
        parseError: String? = nil
    ) {
        self.name = name
        self.description = description
        self.district = district
        self.metadata = metadata
        self.body = body
        self.isValid = isValid
        self.parseError = parseError
    }
}

/// A tolerant YAML frontmatter parser tailored for SKILL.md documents.
/// Never throws; returns structured failure reasons for the "Ruins" diorama state.
public struct FrontmatterParser: Sendable {
    public init() {}

    public func parse(markdown: String) -> ParsedFrontmatter {
        let trimmed = markdown.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.hasPrefix("---") else {
            return ParsedFrontmatter(
                body: markdown,
                isValid: false,
                parseError: "Missing leading frontmatter delimiter (---)"
            )
        }

        // Search for closing delimiter after first line
        let lines = markdown.components(separatedBy: "\n")
        guard let firstLine = lines.first, firstLine.trimmingCharacters(in: .whitespaces) == "---" else {
            return ParsedFrontmatter(
                body: markdown,
                isValid: false,
                parseError: "Invalid frontmatter start"
            )
        }

        var closingIndex: Int?
        for i in 1..<lines.count {
            if lines[i].trimmingCharacters(in: .whitespaces) == "---" {
                closingIndex = i
                break
            }
        }

        guard let closeIdx = closingIndex else {
            return ParsedFrontmatter(
                body: markdown,
                isValid: false,
                parseError: "Unclosed frontmatter block (missing ending ---)"
            )
        }

        let frontmatterLines = lines[1..<closeIdx]
        let bodyLines = lines[(closeIdx + 1)...]
        let body = bodyLines.joined(separator: "\n")

        var metadata: [String: String] = [:]
        var currentKey: String?
        var currentValue = ""

        for line in frontmatterLines {
            let lineTrimmed = line.trimmingCharacters(in: .whitespaces)
            if lineTrimmed.isEmpty || lineTrimmed.hasPrefix("#") {
                continue
            }

            // Check if this line starts a new key: value
            if let colonIdx = line.firstIndex(of: ":"), !line.hasPrefix(" ") && !line.hasPrefix("\t") {
                // Flush previous key if any
                if let k = currentKey {
                    metadata[k] = cleanValue(currentValue)
                }
                let key = String(line[..<colonIdx]).trimmingCharacters(in: .whitespaces)
                let valuePart = String(line[line.index(after: colonIdx)...]).trimmingCharacters(in: .whitespaces)
                currentKey = key
                currentValue = valuePart
            } else if currentKey != nil {
                // Continuation line (multiline description / string)
                if currentValue.isEmpty {
                    currentValue = lineTrimmed
                } else {
                    currentValue += " " + lineTrimmed
                }
            }
        }

        if let k = currentKey {
            metadata[k] = cleanValue(currentValue)
        }

        let name = metadata["name"]
        let description = metadata["description"]
        let district = metadata["district"]

        let isValid = (name != nil && !name!.isEmpty) || (description != nil && !description!.isEmpty)
        let parseError = isValid ? nil : "Frontmatter missing required 'name' or 'description' fields"

        return ParsedFrontmatter(
            name: name,
            description: description,
            district: district,
            metadata: metadata,
            body: body,
            isValid: isValid,
            parseError: parseError
        )
    }

    private func cleanValue(_ raw: String) -> String {
        var str = raw.trimmingCharacters(in: .whitespaces)
        // Strip outer quotes if present
        if (str.hasPrefix("\"") && str.hasSuffix("\"") && str.count >= 2) ||
           (str.hasPrefix("'") && str.hasSuffix("'") && str.count >= 2) {
            str.removeFirst()
            str.removeLast()
        }
        return str.trimmingCharacters(in: .whitespaces)
    }
}
