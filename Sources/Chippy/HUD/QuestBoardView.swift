import SwiftUI
import ChippyCore

/// Colony Quest Board displaying tasks across Planned, In Progress,
/// and Completed columns (Kanban Task Wall inspired by AgentCraft).
public struct QuestBoardView: View {
    public let tasks: [ColonyTask]
    public var onClose: () -> Void

    @State private var filterFamiliar: FamiliarKind? = nil

    public init(tasks: [ColonyTask], onClose: @escaping () -> Void) {
        self.tasks = tasks
        self.onClose = onClose
    }

    public var body: some View {
        VStack(spacing: 16) {
            // Header Bar
            HStack(spacing: 12) {
                Text("📋")
                    .font(.system(size: 16))

                VStack(alignment: .leading, spacing: 2) {
                    Text("COLONY QUEST BOARD")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(ChippyTheme.textMuted)

                    Text("Active Objectives & Engineering Quests")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(ChippyTheme.textPrimary)
                }

                Spacer()

                // Familiar Filter Pills
                familiarFilterBar

                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(ChippyTheme.textMuted)
                        .padding(6)
                        .background(ChippyTheme.surfaceBubble)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }

            Divider().background(ChippyTheme.borderSubtle)

            // 3-Column Kanban Board
            HStack(alignment: .top, spacing: 14) {
                kanbanColumn(
                    title: "PLANNED",
                    count: filteredTasks(for: .planned).count,
                    tasks: filteredTasks(for: .planned)
                )

                kanbanColumn(
                    title: "IN PROGRESS",
                    count: filteredTasks(for: .inProgress).count,
                    tasks: filteredTasks(for: .inProgress)
                )

                kanbanColumn(
                    title: "COMPLETED",
                    count: filteredTasks(for: .completed).count,
                    tasks: filteredTasks(for: .completed)
                )
            }
        }
        .padding(20)
        .frame(width: 820, height: 480)
        .background(ChippyTheme.surfacePrimary)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(ChippyTheme.borderSubtle, lineWidth: 1))
        .shadow(color: Color.black.opacity(0.4), radius: 20, x: 0, y: 10)
    }

    // MARK: - Subviews

    private var familiarFilterBar: some View {
        HStack(spacing: 6) {
            filterButton(title: "All", isSelected: filterFamiliar == nil) {
                filterFamiliar = nil
            }
            ForEach(FamiliarKind.allCases, id: \.self) { kind in
                filterButton(title: kind.displayName, isSelected: filterFamiliar == kind) {
                    filterFamiliar = kind
                }
            }
        }
    }

    private func filterButton(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 10, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? ChippyTheme.accentSolid : ChippyTheme.textMuted)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(isSelected ? ChippyTheme.surfaceBubble : Color.clear)
                .cornerRadius(4)
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(isSelected ? ChippyTheme.borderSubtle : Color.clear, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private func kanbanColumn(title: String, count: Int, tasks: [ColonyTask]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // Column Header
            HStack {
                Text(title)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(ChippyTheme.textMuted)
                Spacer()
                Text("\(count)")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(ChippyTheme.textMuted)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(ChippyTheme.surfaceBubble)
                    .cornerRadius(4)
            }

            // Scrollable Task Cards
            ScrollView {
                LazyVStack(spacing: 8) {
                    if tasks.isEmpty {
                        Text("No tasks in column")
                            .font(.system(size: 10))
                            .foregroundColor(ChippyTheme.textMuted.opacity(0.6))
                            .padding(.top, 24)
                    } else {
                        ForEach(tasks) { task in
                            taskCard(task: task)
                        }
                    }
                }
                .padding(.vertical, 2)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ChippyTheme.surfaceBubble.opacity(0.4))
        .cornerRadius(8)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(ChippyTheme.borderSubtle, lineWidth: 0.5))
    }

    private func taskCard(task: ColonyTask) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top) {
                // Category Tag
                Text(task.category.uppercased())
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(ChippyTheme.textMuted)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(ChippyTheme.surfacePrimary)
                    .cornerRadius(3)

                Spacer()

                // Discrete status dot
                Circle()
                    .fill(ChippyTheme.statusDot)
                    .frame(width: 5, height: 5)
                    .padding(.top, 2)
            }

            Text(task.title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(ChippyTheme.textPrimary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            HStack {
                Text("\(task.assignedFamiliar.displayName) • \(task.districtID.displayName)")
                    .font(.system(size: 9))
                    .foregroundColor(ChippyTheme.textMuted)
                Spacer()
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ChippyTheme.surfaceBubble)
        .cornerRadius(6)
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(ChippyTheme.borderSubtle, lineWidth: 0.5))
    }

    private func filteredTasks(for state: ColonyTaskState) -> [ColonyTask] {
        tasks.filter { task in
            guard task.state == state else { return false }
            if let fam = filterFamiliar {
                return task.assignedFamiliar == fam
            }
            return true
        }
    }
}
