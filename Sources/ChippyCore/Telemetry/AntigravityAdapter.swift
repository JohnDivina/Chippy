import Foundation

/// Internal JSON representation of a step in Antigravity's `transcript.jsonl`.
private struct AntigravityStep: Decodable {
    let step_index: Int?
    let source: String?
    let type: String?
    let status: String?
    let created_at: String?
    let thinking: String?
    let content: String?
    let tool_calls: [AntigravityToolCall]?
    let is_truncated: Bool?
}

private struct AntigravityToolCall: Decodable {
    let name: String
    let args: [String: AnyCodableValue]?
}

/// Flexible Codable container to handle arbitrary argument values (strings, numbers, dicts).
private enum AnyCodableValue: Decodable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case array([AnyCodableValue])
    case dictionary([String: AnyCodableValue])

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let s = try? container.decode(String.self) {
            // Unescape quotes if serialized as escaped string representation
            var cleaned = s
            if cleaned.hasPrefix("\"") && cleaned.hasSuffix("\"") && cleaned.count >= 2 {
                cleaned.removeFirst()
                cleaned.removeLast()
            }
            self = .string(cleaned)
        } else if let b = try? container.decode(Bool.self) {
            self = .bool(b)
        } else if let i = try? container.decode(Int.self) {
            self = .int(i)
        } else if let d = try? container.decode(Double.self) {
            self = .double(d)
        } else if let arr = try? container.decode([AnyCodableValue].self) {
            self = .array(arr)
        } else if let dict = try? container.decode([String: AnyCodableValue].self) {
            self = .dictionary(dict)
        } else {
            self = .string("")
        }
    }

    var stringValue: String? {
        switch self {
        case .string(let s): return s
        case .int(let i): return String(i)
        case .double(let d): return String(d)
        case .bool(let b): return String(b)
        default: return nil
        }
    }
}

/// Adapter transforming Antigravity's `transcript.jsonl` steps into normalized `AgentEvent` streams.
public final class AntigravityAdapter: TranscriptAdapter, Sendable {
    public static let id = "antigravity"

    private let jsonDecoder = JSONDecoder()

    public init() {}

    public func canHandle(fileAt url: URL) -> Bool {
        let filename = url.lastPathComponent
        return filename == "transcript.jsonl" || filename == "transcript_full.jsonl" || url.pathExtension == "jsonl"
    }

    public func events(fromLine line: Data) throws -> [AgentEvent] {
        guard !line.isEmpty else { return [] }

        guard let step = try? jsonDecoder.decode(AntigravityStep.self, from: line) else {
            // Fail soft on malformed JSON lines
            return []
        }

        var events: [AgentEvent] = []
        let agentID = "antigravity.lead"

        // 1. Check for error status
        if let status = step.status, status.uppercased() == "ERROR" {
            let errorMsg = step.content ?? "Step execution failed with ERROR status"
            events.append(.error(agentID: agentID, message: errorMsg))
            return events
        }

        // 2. Parse User Input & Model detection
        if step.type == "USER_INPUT" {
            if let content = step.content {
                // Check if user settings changed model
                if let modelMatch = extractModelSetting(from: content) {
                    events.append(.sessionStarted(sessionID: UUID().uuidString, model: modelMatch, startedAt: Date()))
                }
                // Strip metadata tags from user prompt for clean display
                let promptText = stripMetadataTags(from: content)
                if !promptText.isEmpty {
                    events.append(.userPrompt(text: promptText))
                }
            }
            return events
        }

        // 3. Parse Thinking
        if let thinking = step.thinking, !thinking.isEmpty {
            events.append(.thinking(agentID: agentID))
        }

        // 4. Parse Tool Calls
        if let toolCalls = step.tool_calls {
            for call in toolCalls {
                events.append(contentsOf: mapToolCall(call, agentID: agentID))
            }
        }

        // 5. Parse Agent Response Text
        if step.type == "PLANNER_RESPONSE" || step.type == "SUBAGENT_RESPONSE" {
            if let content = step.content, !content.isEmpty {
                events.append(.agentMessage(agentID: agentID, text: content))
            }
        }

        return events
    }

    private func mapToolCall(_ call: AntigravityToolCall, agentID: String) -> [AgentEvent] {
        let name = call.name
        let args = call.args ?? [:]

        switch name {
        case "view_file":
            let path = args["AbsolutePath"]?.stringValue ?? args["TargetFile"]?.stringValue ?? "file"
            if path.hasSuffix("SKILL.md") {
                let skillName = extractSkillName(from: path)
                return [.skillLoaded(agentID: agentID, skillName: skillName)]
            } else {
                return [.fileRead(agentID: agentID, path: path)]
            }

        case "list_dir":
            let dirPath = args["DirectoryPath"]?.stringValue ?? "directory"
            return [.fileRead(agentID: agentID, path: dirPath)]

        case "grep_search", "search_web", "read_url_content":
            let query = args["Query"]?.stringValue ?? args["query"]?.stringValue ?? args["Url"]?.stringValue ?? name
            return [.toolCall(agentID: agentID, tool: .search, summary: "\(name): \(query)")]

        case "write_to_file":
            let target = args["TargetFile"]?.stringValue ?? "file"
            return [.fileEdited(agentID: agentID, path: target, kind: .created)]

        case "replace_file_content", "multi_replace_file_content":
            let target = args["TargetFile"]?.stringValue ?? "file"
            return [.fileEdited(agentID: agentID, path: target, kind: .modified)]

        case "run_command":
            let cmd = args["CommandLine"]?.stringValue ?? ""
            return [.commandRun(agentID: agentID, command: cmd)]

        case "invoke_subagent", "browser_subagent":
            let task = args["Task"]?.stringValue ?? args["TaskName"]?.stringValue ?? "Subagent Task"
            let childID = UUID().uuidString
            return [.subagentSpawned(parentID: agentID, childID: childID, task: task)]

        case "ask_question":
            return [.toolCall(agentID: agentID, tool: .ask, summary: "Clarification requested from user")]

        default:
            let summary = args["toolSummary"]?.stringValue ?? args["toolAction"]?.stringValue ?? name
            return [.toolCall(agentID: agentID, tool: .custom(name), summary: summary)]
        }
    }

    private func extractSkillName(from path: String) -> String {
        let parts = path.components(separatedBy: "/")
        if parts.count >= 2 {
            return parts[parts.count - 2]
        }
        return "skill"
    }

    private func extractModelSetting(from text: String) -> String? {
        guard let rangeStart = text.range(of: "`Model Selection` from None to ") ?? text.range(of: "Model Selection to ") else {
            return nil
        }
        let remainder = text[rangeStart.upperBound...]
        let endCandidates = ["</USER_SETTINGS_CHANGE>", ".\n", "\n"]
        var bestEnd: Substring.Index? = nil
        for cand in endCandidates {
            if let idx = remainder.range(of: cand)?.lowerBound {
                if bestEnd == nil || idx < bestEnd! {
                    bestEnd = idx
                }
            }
        }
        if let end = bestEnd {
            var extracted = String(remainder[..<end]).trimmingCharacters(in: .whitespacesAndNewlines)
            if extracted.hasSuffix(".") { extracted.removeLast() }
            return extracted.trimmingCharacters(in: .whitespaces)
        }
        return nil
    }

    private func stripMetadataTags(from text: String) -> String {
        var clean = text
        // Remove <ADDITIONAL_METADATA>...</ADDITIONAL_METADATA>
        if let start = clean.range(of: "<ADDITIONAL_METADATA>"), let end = clean.range(of: "</ADDITIONAL_METADATA>") {
            clean.removeSubrange(start.lowerBound...end.upperBound)
        }
        // Remove <USER_SETTINGS_CHANGE>...</USER_SETTINGS_CHANGE>
        if let start = clean.range(of: "<USER_SETTINGS_CHANGE>"), let end = clean.range(of: "</USER_SETTINGS_CHANGE>") {
            clean.removeSubrange(start.lowerBound...end.upperBound)
        }
        // Extract <USER_REQUEST>...</USER_REQUEST> if present
        if let start = clean.range(of: "<USER_REQUEST>"), let end = clean.range(of: "</USER_REQUEST>") {
            let extracted = clean[start.upperBound..<end.lowerBound]
            return extracted.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return clean.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
