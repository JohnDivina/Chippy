import SwiftUI
import AppKit
import ChippyCore

/// Inspector card displaying details about an inspected entity (Familiar, Workshop, or Harbor Crate).
public enum InspectedEntity: Equatable {
    case familiar(kind: FamiliarKind, currentTask: String?, recentActions: [String])
    case workshop(skill: SkillWorkshop)
    case crate(path: String, editCount: Int)
}

public struct InspectorView: View {
    public let entity: InspectedEntity
    public var onInspectDiff: ((String, Int) -> Void)?
    public var onFocusLandmark: ((String) -> Void)?
    public var onClose: () -> Void

    public init(
        entity: InspectedEntity,
        onInspectDiff: ((String, Int) -> Void)? = nil,
        onFocusLandmark: ((String) -> Void)? = nil,
        onClose: @escaping () -> Void
    ) {
        self.entity = entity
        self.onInspectDiff = onInspectDiff
        self.onFocusLandmark = onFocusLandmark
        self.onClose = onClose
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack {
                Text(headerTitle)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(ChippyTheme.textPrimary)
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(ChippyTheme.textMuted)
                        .padding(5)
                        .background(ChippyTheme.surfaceBubble)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }

            Divider().background(ChippyTheme.borderSubtle)

            // Content
            switch entity {
            case .familiar(let kind, let currentTask, let recentActions):
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text(kind.displayName)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(ChippyTheme.textPrimary)
                        Spacer()
                        Text(kind.district.displayName)
                            .font(.system(size: 11))
                            .foregroundColor(ChippyTheme.textMuted)
                    }

                    if let task = currentTask, !task.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Current Task")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(ChippyTheme.textMuted)
                            Text(task)
                                .font(.system(size: 11))
                                .foregroundColor(ChippyTheme.textPrimary)
                                .padding(8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(ChippyTheme.surfaceBubble)
                                .cornerRadius(6)
                        }
                    }

                    if !recentActions.isEmpty {
                        Text("Recent Actions")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(ChippyTheme.textMuted)
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(Array(recentActions.prefix(5).enumerated()), id: \.offset) { _, action in
                                Text("• \(action)")
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(ChippyTheme.textMuted)
                                    .lineLimit(1)
                            }
                        }
                    }

                    Button("Focus Camera") {
                        onFocusLandmark?(kind.district.rawValue)
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 11))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(ChippyTheme.surfaceBubble)
                    .cornerRadius(6)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(ChippyTheme.borderSubtle, lineWidth: 1))
                }

            case .workshop(let skill):
                VStack(alignment: .leading, spacing: 10) {
                    Text(skill.name)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(ChippyTheme.textPrimary)

                    Text(skill.description)
                        .font(.system(size: 11))
                        .foregroundColor(ChippyTheme.textMuted)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack {
                        Text("Stationed Familiar: \(skill.districtID.assignedFamiliar.displayName)")
                            .font(.system(size: 10))
                            .foregroundColor(ChippyTheme.textMuted)
                        Spacer()
                    }

                    Button("Focus Camera on District") {
                        onFocusLandmark?(skill.districtID.rawValue)
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 11))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(ChippyTheme.surfaceBubble)
                    .cornerRadius(6)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(ChippyTheme.borderSubtle, lineWidth: 1))
                }

            case .crate(let path, let editCount):
                VStack(alignment: .leading, spacing: 10) {
                    Text(URL(fileURLWithPath: path).lastPathComponent)
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                        .foregroundColor(ChippyTheme.textPrimary)

                    Text(path)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(ChippyTheme.textMuted)
                        .lineLimit(2)

                    Text("Modifications in this session: \(editCount)")
                        .font(.system(size: 11))
                        .foregroundColor(ChippyTheme.textMuted)

                    HStack(spacing: 8) {
                        Button("Inspect Diff") {
                            onInspectDiff?(path, editCount)
                        }
                        .buttonStyle(.plain)
                        .font(.system(size: 11, weight: .semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(ChippyTheme.accentSolid)
                        .foregroundColor(ChippyTheme.surfacePrimary)
                        .cornerRadius(6)

                        Button("Reveal in Finder") {
                            let url = URL(fileURLWithPath: path)
                            NSWorkspace.shared.activateFileViewerSelecting([url])
                        }
                        .buttonStyle(.plain)
                        .font(.system(size: 11))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(ChippyTheme.surfaceBubble)
                        .cornerRadius(6)
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(ChippyTheme.borderSubtle, lineWidth: 1))

                        Button("Open in Editor") {
                            let url = URL(fileURLWithPath: path)
                            NSWorkspace.shared.open(url)
                        }
                        .buttonStyle(.plain)
                        .font(.system(size: 11))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(ChippyTheme.surfaceBubble)
                        .cornerRadius(6)
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(ChippyTheme.borderSubtle, lineWidth: 1))
                    }
                }
            }
        }
        .padding(16)
        .frame(width: 320)
        .background(ChippyTheme.surfacePrimary)
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(ChippyTheme.borderSubtle, lineWidth: 1))
        .shadow(color: Color.black.opacity(0.3), radius: 12, x: 0, y: 6)
    }

    private var headerTitle: String {
        switch entity {
        case .familiar: return "Familiar Inspector"
        case .workshop: return "Workshop Details"
        case .crate: return "Touched Artifact"
        }
    }
}
