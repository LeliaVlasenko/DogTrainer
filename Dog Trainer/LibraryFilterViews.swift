import SwiftUI

// MARK: - Stats bar

struct LibraryStatsBar: View {
    let total: Int
    let mastered: Int
    let isPremium: Bool
    let onUnlock: () -> Void

    private var masteredPercent: Int {
        total > 0 ? Int(Double(mastered) / Double(total) * 100) : 0
    }

    var body: some View {
        HStack(spacing: 0) {
            StatPill(value: "\(total)", label: String(localized: "library.stat.total"))
            Divider().frame(height: 32)
            StatPill(value: "\(mastered)", label: String(localized: "library.stat.mastered"))
            Divider().frame(height: 32)

            if isPremium {
                StatPill(value: "\(masteredPercent)%", label: String(localized: "library.stat.progress"))
            } else {
                Button(action: onUnlock) {
                    HStack(spacing: 6) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.appGold)
                        Text(String(localized: "library.stat.unlock"))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color.accentColor)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 12)
        .background(Color.appCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

private struct StatPill: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.primary)
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Filter bar

struct FilterBarView: View {
    @Binding var selectedCategory: CommandCategory?
    @Binding var selectedDifficulty: CommandDifficulty?

    var body: some View {
        VStack(spacing: 8) {
            // Category chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterChip(
                        label: String(localized: "progress.category.all"),
                        icon: nil,
                        isSelected: selectedCategory == nil,
                        color: .blue
                    ) { selectedCategory = nil }

                    ForEach(CommandCategory.allCases, id: \.rawValue) { cat in
                        FilterChip(
                            label: cat.localizedTitle,
                            icon: cat.systemImage,
                            isSelected: selectedCategory == cat,
                            color: categoryColor(cat)
                        ) {
                            selectedCategory = selectedCategory == cat ? nil : cat
                        }
                    }
                }
                .padding(.horizontal, 1)
            }

            // Difficulty chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterChip(
                        label: String(localized: "library.filter.all_levels"),
                        icon: nil,
                        isSelected: selectedDifficulty == nil,
                        color: .gray
                    ) { selectedDifficulty = nil }

                    ForEach(CommandDifficulty.allCases, id: \.rawValue) { diff in
                        FilterChip(
                            label: diff.localizedTitle,
                            icon: nil,
                            isSelected: selectedDifficulty == diff,
                            color: difficultyColor(diff)
                        ) {
                            selectedDifficulty = selectedDifficulty == diff ? nil : diff
                        }
                    }
                }
                .padding(.horizontal, 1)
            }
        }
    }

    private func categoryColor(_ cat: CommandCategory) -> Color {
        switch cat {
        case .obedience:  return Color.appSage
        case .social:     return Color.appRose
        case .tricks:     return Color.appFlame
        case .behavioral: return Color.appCoral
        }
    }

    private func difficultyColor(_ d: CommandDifficulty) -> Color {
        switch d {
        case .beginner:     return Color.appSage
        case .intermediate: return Color.appFlame
        case .advanced:     return Color.appCoral
        }
    }
}

private struct FilterChip: View {
    let label: String
    let icon: String?
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 11))
                }
                Text(label)
                    .font(.system(size: 13, weight: isSelected ? .medium : .regular))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(isSelected ? color.opacity(0.12) : Color.appCardBackground)
            .foregroundStyle(isSelected ? color : Color.primary)
            .clipShape(Capsule())
            .overlay(
                Capsule().strokeBorder(
                    isSelected ? color.opacity(0.4) : Color.clear,
                    lineWidth: 1
                )
            )
            .animation(.easeInOut(duration: 0.15), value: isSelected)
        }
        .buttonStyle(.plain)
    }
}
