import Foundation

/// Redacts sensitive secrets, API keys, authorization tokens, and credentials
/// from telemetry streams before events are dispatched to the UI or diorama.
public struct Redactor: Sendable {
    private struct Pattern: Sendable {
        let regex: NSRegularExpression
        let replacement: String
    }

    private let patterns: [Pattern]

    public init() {
        var list: [Pattern] = []

        // Helper to compile regex
        func addPattern(_ pattern: String, replacement: String = "[REDACTED_SECRET]", options: NSRegularExpression.Options = []) {
            if let regex = try? NSRegularExpression(pattern: pattern, options: options) {
                list.append(Pattern(regex: regex, replacement: replacement))
            }
        }

        // Anthropic API keys: sk-ant-... (placed before general sk-)
        addPattern(#"sk-ant-[A-Za-z0-9_-]{20,}"#, replacement: "[REDACTED_ANTHROPIC_KEY]")

        // OpenAI API keys: sk-...
        addPattern(#"sk-[A-Za-z0-9_-]{20,}"#, replacement: "[REDACTED_OPENAI_KEY]")

        // AWS Access Keys: AKIA...
        addPattern(#"\bAKIA[0-9A-Z]{16}\b"#, replacement: "[REDACTED_AWS_KEY]")

        // JWT tokens: eyJ...
        addPattern(#"eyJ[A-Za-z0-9-_]{10,}\.eyJ[A-Za-z0-9-_]{10,}\.[A-Za-z0-9-_]{10,}"#, replacement: "[REDACTED_JWT]")

        // Google API keys: AIza...
        addPattern(#"AIza[0-9A-Za-z-_]{30,45}"#, replacement: "[REDACTED_GOOGLE_KEY]")

        // GitHub tokens: ghp_..., gho_..., ghs_..., ghr_...
        addPattern(#"gh[pousr]_[A-Za-z0-9_]{30,}"#, replacement: "[REDACTED_GITHUB_TOKEN]")

        // Slack tokens: xoxb-..., xoxp-..., xoxa-...
        addPattern(#"xox[baprs]-[0-9A-Za-z-]+"#, replacement: "[REDACTED_SLACK_TOKEN]")

        // Authorization headers
        addPattern(#"(?i)Authorization:\s*(Bearer|Basic)\s+[A-Za-z0-9._~+/-]+=*"#, replacement: "Authorization: [REDACTED_AUTH]")

        // PEM private keys
        addPattern(#"-----BEGIN [A-Z ]*PRIVATE KEY-----[a-zA-Z0-9+/=\s\n]+-----END [A-Z ]*PRIVATE KEY-----"#, replacement: "[REDACTED_PRIVATE_KEY]")

        // Key-value secrets like API_KEY=xyz, PASSWORD=xyz, SECRET_KEY=xyz, SUPABASE_SERVICE_ROLE_KEY=xyz
        addPattern(#"(?i)\b(API_KEY|SECRET|PASSWORD|AUTH_TOKEN|PRIVATE_KEY|ACCESS_TOKEN|SUPABASE_KEY|SUPABASE_SERVICE_ROLE_KEY)\s*=\s*['"]?[^\s'"\n]{8,}['"]?"#, replacement: "$1=[REDACTED]")

        self.patterns = list
    }

    /// Redacts known secrets from a string.
    public func redact(_ text: String) -> String {
        guard !text.isEmpty else { return text }
        var result = text
        for item in patterns {
            let range = NSRange(location: 0, length: (result as NSString).length)
            result = item.regex.stringByReplacingMatches(in: result, options: [], range: range, withTemplate: item.replacement)
        }
        return result
    }

    /// Redacts secrets inside an AgentEvent payload.
    public func redact(event: AgentEvent) -> AgentEvent {
        switch event {
        case .sessionStarted(let id, let model, let date):
            return .sessionStarted(sessionID: id, model: model.map { redact($0) }, startedAt: date)
        case .userPrompt(let text):
            return .userPrompt(text: redact(text))
        case .thinking(let agentID):
            return .thinking(agentID: agentID)
        case .toolCall(let agentID, let tool, let summary):
            return .toolCall(agentID: agentID, tool: tool, summary: redact(summary))
        case .skillLoaded(let agentID, let skillName):
            return .skillLoaded(agentID: agentID, skillName: redact(skillName))
        case .fileRead(let agentID, let path):
            return .fileRead(agentID: agentID, path: redact(path))
        case .fileEdited(let agentID, let path, let kind):
            return .fileEdited(agentID: agentID, path: redact(path), kind: kind)
        case .commandRun(let agentID, let command):
            return .commandRun(agentID: agentID, command: redact(command))
        case .commandFinished:
            return event
        case .subagentSpawned(let parentID, let childID, let task):
            return .subagentSpawned(parentID: parentID, childID: childID, task: redact(task))
        case .subagentFinished:
            return event
        case .agentMessage(let agentID, let text):
            return .agentMessage(agentID: agentID, text: redact(text))
        case .error(let agentID, let message, let reason):
            return .error(agentID: agentID, message: redact(message), reason: reason)
        case .sessionEnded:
            return event
        }
    }
}
