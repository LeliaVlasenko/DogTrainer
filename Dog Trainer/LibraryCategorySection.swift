import SwiftUI

// MARK: - Category section

struct LibraryCategorySection: View {
    let category: CommandCategory
    let commands: [Command]
    let isPremium: Bool
    let onSelect: (Command) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Section header
            HStack(spacing: 8) {
                Image(systemName: category.systemImage)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(categoryColor)
                Text(category.localizedTitle)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.primary)
                Spacer()
                Text("\(commands.count)")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.appNestedBackground)
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 4)

            // Command rows
            VStack(spacing: 6) {
                ForEach(commands, id: \.id) { command in
                    LibraryCommandRow(
                        command: command,
                        isPremiumUser: isPremium,
                        onTap: { onSelect(command) }
                    )
                }
            }
        }
    }

    private var categoryColor: Color {
        switch category {
        case .obedience:  return Color.appSage
        case .social:     return Color.appRose
        case .tricks:     return Color.appFlame
        case .behavioral: return Color.appCoral
        }
    }
}

// MARK: - Command row

struct LibraryCommandRow: View {
    let command: Command
    let isPremiumUser: Bool
    let onTap: () -> Void

    private var isLocked: Bool { command.isPremium && !isPremiumUser }

    private var categoryColor: Color {
        switch command.category {
        case .obedience:  return Color.appSage
        case .social:     return Color.appRose
        case .tricks:     return Color.appFlame
        case .behavioral: return Color.appCoral
        }
    }

    private var difficultyColor: Color {
        switch command.difficulty {
        case .beginner:     return Color.appSage
        case .intermediate: return Color.appFlame
        case .advanced:     return Color.appCoral
        }
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Category icon
                ZStack {
                    Circle()
                        .fill(isLocked
                              ? Color.secondary.opacity(0.1)
                              : categoryColor.opacity(0.12))
                        .frame(width: 44, height: 44)
                    Image(systemName: isLocked ? "lock.fill" : command.category.systemImage)
                        .font(.system(size: 18))
                        .foregroundStyle(isLocked ? Color.secondary.opacity(0.5) : categoryColor)
                }

                // Title + meta
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(command.title)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(isLocked ? .secondary : .primary)

                        if command.isPremium {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(isPremiumUser ? Color.appGold : Color.secondary.opacity(0.5))
                        }
                        if command.isMastered {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(Color.appSage)
                        }
                    }

                    HStack(spacing: 8) {
                        // Steps count
                        if !command.steps.isEmpty {
                            Label("\(command.steps.count) \(String(localized: "library.steps"))", systemImage: "list.number")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }

                        // Progress dots
                        if !isLocked && command.successCount > 0 {
                            HStack(spacing: 3) {
                                ForEach(0..<5) { i in
                                    Circle()
                                        .fill(i < command.successCount
                                              ? categoryColor
                                              : Color.secondary.opacity(0.2))
                                        .frame(width: 5, height: 5)
                                }
                            }
                        }
                    }
                }

                Spacer()

                // Right side
                VStack(alignment: .trailing, spacing: 4) {
                    // Difficulty badge
                    Text(command.difficulty.localizedTitle)
                        .font(.system(size: 10, weight: .medium))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(isLocked
                                    ? Color.secondary.opacity(0.1)
                                    : difficultyColor.opacity(0.1))
                        .foregroundStyle(isLocked ? .secondary : difficultyColor)
                        .clipShape(Capsule())

                    if isLocked {
                        Text(String(localized: "library.premium"))
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.secondary.opacity(0.4))
            }
            .cardStyle(padding: 14)
            .opacity(isLocked ? 0.7 : 1.0)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Empty state

struct LibraryEmptyView: View {
    let hasFilters: Bool
    let onReset: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: hasFilters ? "magnifyingglass" : "books.vertical")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            Text(hasFilters
                 ? String(localized: "library.empty.search")
                 : String(localized: "library.empty.general"))
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            if hasFilters {
                Button(String(localized: "library.empty.reset"), action: onReset)
                    .font(.system(size: 14))
                    .foregroundStyle(Color.accentColor)
            }
        }
        .frame(maxWidth: .infinity)
        .cardStyle(padding: 40, radius: 16)
    }
}
