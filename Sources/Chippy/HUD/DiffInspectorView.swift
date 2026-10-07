import SwiftUI
import AppKit
import ChippyCore

/// Harbor Crate Code & Diff Inspector displaying modified artifact contents,
/// line numbers, and quick editor opening actions.
public struct DiffInspectorView: View {
    public let filePath: String
    public let editCount: Int
    public var onClose: () -> Void

    @State private var fileLines: [String] = []
    @State private var isLoaded: Bool = false
    @State private var errorMessage: String? = nil

    public init(filePath: String, editCount: Int, onClose: @escaping () -> Void) {
        self.filePath = filePath
        self.editCount = editCount
        self.onClose = onClose
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack(spacing: 10) {
                Text("📦")
                    .font(.system(size: 16))

                VStack(alignment: .leading, spacing: 2) {
                    Text(URL(fileURLWithPath: filePath).lastPathComponent)
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundColor(ChippyTheme.textPrimary)

                    Text(filePath)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(ChippyTheme.textMuted)
                        .lineLimit(1)
                }

                Spacer()

                // Actions
                HStack(spacing: 8) {
                    Button(action: {
                        let url = URL(fileURLWithPath: filePath)
                        NSWorkspace.shared.open(url)
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up.forward.app")
                                .font(.system(size: 9))
                            Text("Editor")
                                .font(.system(size: 10, weight: .medium))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(ChippyTheme.surfaceBubble)
                        .cornerRadius(5)
                        .overlay(RoundedRectangle(cornerRadius: 5).stroke(ChippyTheme.borderSubtle, lineWidth: 1))
                    }
                    .buttonStyle(.plain)

                    Button(action: {
                        let url = URL(fileURLWithPath: filePath)
                        NSWorkspace.shared.activateFileViewerSelecting([url])
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "folder")
                                .font(.system(size: 9))
                            Text("Finder")
                                .font(.system(size: 10, weight: .medium))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(ChippyTheme.surfaceBubble)
                        .cornerRadius(5)
                        .overlay(RoundedRectangle(cornerRadius: 5).stroke(ChippyTheme.borderSubtle, lineWidth: 1))
                    }
                    .buttonStyle(.plain)

                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(ChippyTheme.textMuted)
                            .padding(5)
                            .background(ChippyTheme.surfaceBubble)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
            }

            Divider().background(ChippyTheme.borderSubtle)

            // Metadata banner
            HStack(spacing: 16) {
                Text("Edits in Session: \(editCount)")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(ChippyTheme.textMuted)

                Text("Lines: \(fileLines.count)")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(ChippyTheme.textMuted)

                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(ChippyTheme.surfaceBubble)
            .cornerRadius(6)

            // File Content Viewer / Diff Preview
            if let err = errorMessage {
                VStack(spacing: 8) {
                    Text("Could not preview file content")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(ChippyTheme.textPrimary)
                    Text(err)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(ChippyTheme.textMuted)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if isLoaded {
                ScrollView([.horizontal, .vertical]) {
                    LazyVStack(alignment: .leading, spacing: 2) {
                        ForEach(Array(fileLines.prefix(300).enumerated()), id: \.offset) { index, line in
                            HStack(alignment: .top, spacing: 10) {
                                Text("\(index + 1)")
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(ChippyTheme.textMuted.opacity(0.5))
                                    .frame(width: 32, alignment: .trailing)

                                Text(line.isEmpty ? " " : line)
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(ChippyTheme.textPrimary)
                                    .textSelection(.enabled)
                            }
                        }
                        if fileLines.count > 300 {
                            Text("... and \(fileLines.count - 300) more lines (truncated preview)")
                                .font(.system(size: 9, design: .monospaced))
                                .foregroundColor(ChippyTheme.textMuted)
                                .padding(.top, 4)
                        }
                    }
                    .padding(8)
                }
                .background(ChippyTheme.surfaceBubble)
                .cornerRadius(6)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(ChippyTheme.borderSubtle, lineWidth: 0.5))
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .padding(18)
        .frame(width: 580, height: 420)
        .background(ChippyTheme.surfacePrimary)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(ChippyTheme.borderSubtle, lineWidth: 1))
        .shadow(color: Color.black.opacity(0.4), radius: 20, x: 0, y: 10)
        .task {
            loadFilePreview()
        }
    }

    private func loadFilePreview() {
        let url = URL(fileURLWithPath: filePath)
        do {
            let data = try Data(contentsOf: url)
            if let string = String(data: data, encoding: .utf8) {
                self.fileLines = string.components(separatedBy: "\n")
                self.isLoaded = true
            } else {
                self.errorMessage = "Binary or unencoded file format"
                self.isLoaded = true
            }
        } catch {
            self.errorMessage = error.localizedDescription
            self.isLoaded = true
        }
    }
}
