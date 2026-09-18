import SwiftUI

struct TodayPlanView: View {
    let commands: [Command]
    let trainedToday: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(String(localized: "home.today.title"))
                        .font(.system(size: 18, weight: .semibold))
                    Text(
                        trainedToday
                        ? String(localized: "home.today.done")
                        : String(localized: "home.today.subtitle")
                    )
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                }
                Spacer()
                // Completion badge
                if trainedToday {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(Color.appSage)
                }
            }

            if commands.isEmpty {
                EmptyCommandsView()
            } else {
                VStack(spacing: 8) {
                    ForEach(commands, id: \.id) { command in
                        CommandRowView(command: command, trainedToday: trainedToday)
                    }
                }
            }
        }
    }
}

// MARK: - Single command row

struct CommandRowView: View {
    let command: Command
    let trainedToday: Bool

    var body: some View {
        HStack(spacing: 14) {
            // Category icon circle
            ZStack {
                Circle()
                    .fill(categoryColor(command.category).opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: command.category.systemImage)
                    .font(.system(size: 18))
                    .foregroundStyle(categoryColor(command.category))
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(command.title)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.primary)
                    if command.isPremium {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(Color.appGold)
                    }
                }
                // Progress dots
                HStack(spacing: 4) {
                    ForEach(0..<5) { i in
                        Circle()
                            .fill(i < command.successCount
                                  ? categoryColor(command.category)
                                  : Color.secondary.opacity(0.2))
                            .frame(width: 6, height: 6)
                    }
                    Text(progressLabel(command))
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .padding(.leading, 2)
                }
            }

            Spacer()

            // Difficulty badge
            Text(command.difficulty.localizedTitle)
                .font(.system(size: 11, weight: .medium))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(difficultyBg(command.difficulty))
                .foregroundStyle(difficultyFg(command.difficulty))
                .clipShape(Capsule())
        }
        .cardStyle(padding: 14)
        .opacity(trainedToday ? 0.6 : 1.0)
        .overlay(
            trainedToday
            ? RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color.appSage.opacity(0.3), lineWidth: 1)
            : nil
        )
    }

    private func progressLabel(_ cmd: Command) -> String {
        if cmd.isMastered { return String(localized: "command.mastered") }
        return "\(cmd.successCount)/5"
    }

    private func categoryColor(_ cat: CommandCategory) -> Color {
        switch cat {
        case .obedience:  return Color.appSage
        case .social:     return Color.appRose
        case .tricks:     return Color.appFlame
        case .behavioral: return Color.appCoral
        }
    }

    private func difficultyBg(_ d: CommandDifficulty) -> Color {
        switch d {
        case .beginner:     return Color.appSage.opacity(0.12)
        case .intermediate: return Color.appFlame.opacity(0.12)
        case .advanced:     return Color.appCoral.opacity(0.12)
        }
    }

    private func difficultyFg(_ d: CommandDifficulty) -> Color {
        switch d {
        case .beginner:     return Color.appSage
        case .intermediate: return Color.appFlame
        case .advanced:     return Color.appCoral
        }
    }
}

// MARK: - Empty state

private struct EmptyCommandsView: View {
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "pawprint.circle")
                .font(.system(size: 36))
                .foregroundStyle(.secondary)
            Text(String(localized: "home.today.empty"))
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .cardStyle(padding: 32)
    }
}
