import SwiftUI
import AppKit
import ChippyCore

/// Interactive Codex sheet allowing the user to search, inspect directives, and locate
/// all 48 production skills organized by island district.
public struct SkillCodexView: View {
    public let skills: [SkillWorkshop]
    public var onSelectSkill: (SkillWorkshop) -> Void
    public var onClose: () -> Void

    @State private var searchText: String = ""
    @State private var selectedDistrict: DistrictID? = nil
    @State private var selectedSkillID: String? = nil

    public init(
        skills: [SkillWorkshop],
        onSelectSkill: @escaping (SkillWorkshop) -> Void,
        onClose: @escaping () -> Void
    ) {
        self.skills = skills
        self.onSelectSkill = onSelectSkill
        self.onClose = onClose
    }

    public var filteredSkills: [SkillWorkshop] {
        skills.filter { skill in
            let matchesDistrict = selectedDistrict == nil || skill.districtID == selectedDistrict
            let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let matchesSearch = query.isEmpty ||
                skill.name.lowercased().contains(query) ||
                skill.description.lowercased().contains(query)
            return matchesDistrict && matchesSearch
        }
    }

    private var activeSkill: SkillWorkshop? {
        if let id = selectedSkillID, let match = skills.first(where: { $0.id == id }) {
            return match
        }
        return filteredSkills.first ?? skills.first
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header Bar
            headerBarView
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
                .background(ChippyTheme.surfacePrimary)

            // Autonomous System Explanation Banner
            autonomousNoticeBanner
                .padding(.horizontal, 18)
                .padding(.bottom, 12)
                .background(ChippyTheme.surfacePrimary)

            Divider()
                .background(ChippyTheme.borderSubtle)

            // Two-Column Layout: Left List + Right Dossier
            HStack(spacing: 0) {
                // Left Column: Filter & List
                VStack(spacing: 10) {
                    searchAndFilterBar
                        .padding(.horizontal, 14)
                        .padding(.top, 12)

                    skillsListView
                }
                .frame(width: 330)
                .background(ChippyTheme.surfacePrimary)

                Divider()
                    .background(ChippyTheme.borderSubtle)

                // Right Column: Skill Directives Dossier
                if let skill = activeSkill {
                    skillDossierView(for: skill)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(ChippyTheme.surfaceBubble.opacity(0.35))
                } else {
                    VStack(spacing: 10) {
                        Text("No skill selected")
                            .font(.system(size: 13))
                            .foregroundColor(ChippyTheme.textMuted)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .frame(width: 780, height: 620)
        .background(ChippyTheme.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(ChippyTheme.borderSubtle, lineWidth: 1)
        )
        .onAppear {
            if selectedSkillID == nil {
                selectedSkillID = skills.first?.id
            }
        }
    }

    // MARK: - Subviews

    private var headerBarView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Text("🛠️")
                        .font(.system(size: 16))
                    Text("Production Skills Codex")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(ChippyTheme.textPrimary)

                    Text("(\(skills.count) Active)")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(ChippyTheme.textMuted)
                }
                Text("Autonomous agent toolkits and island district workshops.")
                    .font(.system(size: 11))
                    .foregroundColor(ChippyTheme.textMuted)
            }

            Spacer()

            Button(action: onClose) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(ChippyTheme.textMuted)
            }
            .buttonStyle(.plain)
        }
    }

    private var autonomousNoticeBanner: some View {
        HStack(alignment: .top, spacing: 8) {
            Circle()
                .fill(ChippyTheme.statusDot)
                .frame(width: 5, height: 5)
                .padding(.top, 4)

            VStack(alignment: .leading, spacing: 2) {
                Text("Autonomous Execution")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(ChippyTheme.textPrimary)
                Text("Production skills are automatically engaged by Antigravity in the background as tasks require. Use this codex to review directives or locate a skill's workshop on the island.")
                    .font(.system(size: 10))
                    .foregroundColor(ChippyTheme.textMuted)
                    .lineLimit(2)
            }
            Spacer()
        }
        .padding(10)
        .background(ChippyTheme.surfaceBubble)
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(ChippyTheme.borderSubtle, lineWidth: 1)
        )
    }

    private var searchAndFilterBar: some View {
        VStack(spacing: 8) {
            // Search field
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 11))
                    .foregroundColor(ChippyTheme.textMuted)

                TextField("Search 48 production skills…", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 11))

                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle")
                            .font(.system(size: 10))
                            .foregroundColor(ChippyTheme.textMuted)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 9)
            .padding(.vertical, 6)
            .background(ChippyTheme.surfaceBubble)
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(ChippyTheme.borderSubtle, lineWidth: 1)
            )

            // District Filter Chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 5) {
                    filterTab(label: "All (\(skills.count))", district: nil)
                    ForEach(District.allDistricts) { district in
                        let count = skills.filter { $0.districtID == district.id }.count
                        if count > 0 {
                            filterTab(label: "\(district.icon) \(district.displayName) (\(count))", district: district.id)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func filterTab(label: String, district: DistrictID?) -> some View {
        let isSelected = selectedDistrict == district
        Button(action: {
            selectedDistrict = district
            if let first = filteredSkills.first {
                selectedSkillID = first.id
            }
        }) {
            Text(label)
                .font(.system(size: 10, weight: isSelected ? .bold : .regular))
                .foregroundColor(isSelected ? ChippyTheme.accentSolid : ChippyTheme.textMuted)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(isSelected ? ChippyTheme.surfaceBubble : Color.clear)
                .cornerRadius(5)
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(isSelected ? ChippyTheme.textPrimary : ChippyTheme.borderSubtle, lineWidth: isSelected ? 1 : 0.5)
                )
        }
        .buttonStyle(.plain)
    }

    private var skillsListView: some View {
        ScrollView {
            LazyVStack(spacing: 6) {
                if filteredSkills.isEmpty {
                    VStack(spacing: 6) {
                        Text("No matching skills.")
                            .font(.system(size: 12))
                            .foregroundColor(ChippyTheme.textMuted)
                    }
                    .frame(maxWidth: .infinity, minHeight: 140)
                } else {
                    ForEach(filteredSkills) { skill in
                        skillListCard(for: skill)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 14)
        }
    }

    @ViewBuilder
    private func skillListCard(for skill: SkillWorkshop) -> some View {
        let isSelected = activeSkill?.id == skill.id
        let district = District.allDistricts.first { $0.id == skill.districtID }

        Button(action: { selectedSkillID = skill.id }) {
            HStack(spacing: 8) {
                Text(district?.icon ?? "⚙️")
                    .font(.system(size: 16))
                    .frame(width: 24, height: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(skill.name)
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .foregroundColor(isSelected ? ChippyTheme.accentSolid : ChippyTheme.textPrimary)
                        .lineLimit(1)

                    Text(district?.displayName ?? "Sanctuary")
                        .font(.system(size: 9))
                        .foregroundColor(ChippyTheme.textMuted)
                }

                Spacer()

                if isSelected {
                    Circle()
                        .fill(ChippyTheme.accentSolid)
                        .frame(width: 5, height: 5)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(isSelected ? ChippyTheme.surfaceBubble : ChippyTheme.surfacePrimary)
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isSelected ? ChippyTheme.accentSolid : ChippyTheme.borderSubtle, lineWidth: isSelected ? 1 : 0.5)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Right Column Dossier View

    @ViewBuilder
    private func skillDossierView(for skill: SkillWorkshop) -> some View {
        let district = District.allDistricts.first { $0.id == skill.districtID }
        let familiar = district?.residentFamiliars.first

        VStack(alignment: .leading, spacing: 14) {
            // Dossier Header
            HStack(alignment: .top, spacing: 12) {
                Text(district?.icon ?? "⚙️")
                    .font(.system(size: 28))
                    .padding(10)
                    .background(ChippyTheme.surfacePrimary)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(ChippyTheme.borderSubtle, lineWidth: 1)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(skill.name)
                        .font(.system(size: 15, weight: .bold, design: .monospaced))
                        .foregroundColor(ChippyTheme.textPrimary)

                    HStack(spacing: 8) {
                        Text(district?.displayName ?? "District")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(ChippyTheme.textMuted)

                        Text("•")
                            .foregroundColor(ChippyTheme.textMuted)

                        Text(district?.workshopName ?? "Workshop")
                            .font(.system(size: 10))
                            .foregroundColor(ChippyTheme.textMuted)
                    }
                }

                Spacer()
            }

            // Autonomous Status Chip
            HStack(spacing: 6) {
                Circle()
                    .fill(ChippyTheme.statusDot)
                    .frame(width: 5, height: 5)

                Text("STATUS: AUTONOMOUS AGENT TOOLKIT")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(ChippyTheme.textPrimary)

                Spacer()

                Text("Auto-Invoked in Live Runs")
                    .font(.system(size: 9))
                    .foregroundColor(ChippyTheme.textMuted)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(ChippyTheme.surfacePrimary)
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(ChippyTheme.borderSubtle, lineWidth: 1)
            )

            // Stationed Familiar
            if let fam = familiar {
                HStack(spacing: 8) {
                    Text("Stationed Familiar:")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(ChippyTheme.textMuted)

                    Text(fam.displayName)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(ChippyTheme.textPrimary)

                    Text("(\(fam.rawValue))")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(ChippyTheme.textMuted)
                }
            }

            // Description / Scope
            VStack(alignment: .leading, spacing: 4) {
                Text("PURPOSE & SCOPE")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(ChippyTheme.textMuted)

                Text(skill.description)
                    .font(.system(size: 11))
                    .foregroundColor(ChippyTheme.textPrimary)
                    .lineSpacing(2)
            }

            // When To Use Directives
            if let whenToUse = skill.whenToUse, !whenToUse.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("TRIGGER CRITERIA (WHEN TO USE)")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(ChippyTheme.textMuted)

                    Text(whenToUse)
                        .font(.system(size: 11))
                        .foregroundColor(ChippyTheme.textMuted)
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(ChippyTheme.surfacePrimary)
                        .cornerRadius(6)
                }
            }

            // Scrollable Directives Body Preview
            if let body = skill.directivesBody, !body.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("SYSTEM DIRECTIVES (SKILL.MD)")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(ChippyTheme.textMuted)

                    ScrollView {
                        Text(body)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(ChippyTheme.textMuted)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(8)
                    }
                    .frame(maxHeight: 140)
                    .background(ChippyTheme.surfacePrimary)
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(ChippyTheme.borderSubtle, lineWidth: 1)
                    )
                }
            }

            Spacer()

            // Action Buttons
            HStack(spacing: 10) {
                // Locate Workshop on Island Button
                Button(action: {
                    onSelectSkill(skill)
                    onClose()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "scope")
                            .font(.system(size: 11, weight: .bold))
                        Text("Locate Workshop on Island")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(ChippyTheme.accentSolid)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(ChippyTheme.surfacePrimary)
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(ChippyTheme.accentSolid, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)

                // Open in Finder
                Button(action: {
                    let fileURL = skill.directoryURL.appendingPathComponent("SKILL.md")
                    if FileManager.default.fileExists(atPath: fileURL.path) {
                        NSWorkspace.shared.activateFileViewerSelecting([fileURL])
                    } else {
                        NSWorkspace.shared.activateFileViewerSelecting([skill.directoryURL])
                    }
                }) {
                    HStack(spacing: 5) {
                        Image(systemName: "folder")
                            .font(.system(size: 11))
                        Text("Reveal SKILL.md")
                            .font(.system(size: 11))
                    }
                    .foregroundColor(ChippyTheme.textMuted)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(ChippyTheme.surfacePrimary)
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(ChippyTheme.borderSubtle, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(18)
    }
}
