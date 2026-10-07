import SwiftUI
import ChippyCore

/// Interactive Codex sheet allowing the user to search, inspect, and interact with
/// all 48 production skills organized by island district.
public struct SkillCodexView: View {
    public let skills: [SkillWorkshop]
    public var onSelectSkill: (SkillWorkshop) -> Void
    public var onClose: () -> Void

    @State private var searchText: String = ""
    @State private var selectedDistrict: DistrictID? = nil

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

    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text("🛠️")
                            .font(.system(size: 16))
                        Text("Production Skills Codex")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(ChippyTheme.textPrimary)

                        Text("(\(skills.count) Active)")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(ChippyTheme.textMuted)
                    }
                    Text("Select any skill to inspect directives and assign familiars.")
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
            .padding(18)
            .background(ChippyTheme.surfacePrimary)

            Divider()
                .background(ChippyTheme.borderSubtle)

            // Search Bar & District Filter Tabs
            VStack(spacing: 10) {
                // Search field
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 12))
                        .foregroundColor(ChippyTheme.textMuted)

                    TextField("Search 48 production skills…", text: $searchText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 12))

                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle")
                                .font(.system(size: 11))
                                .foregroundColor(ChippyTheme.textMuted)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(ChippyTheme.surfaceBubble)
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(ChippyTheme.borderSubtle, lineWidth: 1)
                )

                // Filter Tabs
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
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
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(ChippyTheme.surfacePrimary)

            Divider()
                .background(ChippyTheme.borderSubtle)

            // Skills Grid / List
            ScrollView {
                LazyVStack(spacing: 10) {
                    if filteredSkills.isEmpty {
                        VStack(spacing: 8) {
                            Text("No skills match your search.")
                                .font(.system(size: 13))
                                .foregroundColor(ChippyTheme.textMuted)
                        }
                        .frame(maxWidth: .infinity, minHeight: 180)
                    } else {
                        ForEach(filteredSkills) { skill in
                            skillCard(for: skill)
                        }
                    }
                }
                .padding(18)
            }
        }
        .frame(width: 580, height: 600)
        .background(ChippyTheme.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(ChippyTheme.borderSubtle, lineWidth: 1)
        )
    }

    // MARK: - Subviews

    @ViewBuilder
    private func filterTab(label: String, district: DistrictID?) -> some View {
        let isSelected = selectedDistrict == district
        Button(action: { selectedDistrict = district }) {
            Text(label)
                .font(.system(size: 11, weight: isSelected ? .bold : .regular))
                .foregroundColor(isSelected ? ChippyTheme.accentSolid : ChippyTheme.textMuted)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(isSelected ? ChippyTheme.surfaceBubble : Color.clear)
                .cornerRadius(5)
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(isSelected ? ChippyTheme.textPrimary : ChippyTheme.borderSubtle, lineWidth: isSelected ? 1 : 0.5)
                )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func skillCard(for skill: SkillWorkshop) -> some View {
        let district = District.allDistricts.first { $0.id == skill.districtID }

        HStack(alignment: .top, spacing: 12) {
            Text(district?.icon ?? "⚙️")
                .font(.system(size: 20))
                .padding(8)
                .background(ChippyTheme.surfacePrimary)
                .cornerRadius(6)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(skill.name)
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                        .foregroundColor(ChippyTheme.textPrimary)

                    if let dist = district {
                        Text(dist.displayName)
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(ChippyTheme.textMuted)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(ChippyTheme.surfacePrimary)
                            .cornerRadius(4)
                    }
                }

                Text(skill.description)
                    .font(.system(size: 11))
                    .foregroundColor(ChippyTheme.textMuted)
                    .lineLimit(3)

                if let familiar = district?.residentFamiliars.first {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(ChippyTheme.statusDot)
                            .frame(width: 4, height: 4)
                        Text("Assigned: \(familiar.displayName)")
                            .font(.system(size: 10))
                            .foregroundColor(ChippyTheme.textMuted)
                    }
                    .padding(.top, 2)
                }
            }

            Spacer()

            Button(action: { onSelectSkill(skill) }) {
                Text("Inspect")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(ChippyTheme.textPrimary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(ChippyTheme.surfacePrimary)
                    .cornerRadius(5)
                    .overlay(
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(ChippyTheme.borderSubtle, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(ChippyTheme.surfaceBubble)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(ChippyTheme.borderSubtle, lineWidth: 1)
        )
    }
}
