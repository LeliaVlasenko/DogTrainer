import SwiftUI

struct CommandsProgressView: View {
    let commands: [Command]

    @State private var selectedCategory: CommandCategory? = nil

    private var filtered: [Command] {
        let unlocked = commands.filter { $0.isUnlocked }
        guard let cat = selectedCategory else { return unlocked }
        return unlocked.filter { $0.category == cat }
    }

    private var masteredCount: Int { commands.filter { $0.isMastered }.count }
    private var totalUnlocked: Int { commands.filter { $0.isUnlocked }.count }
    private var overallProgress: Double {
        totalUnlocked > 0 ? Double(masteredCount) / Double(totalUnlocked) : 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header + overall ring
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(localized: "progress.commands.title"))
                        .font(.system(size: 15, weight: .semibold))
                    Text(String(localized: "progress.commands.mastered \(masteredCount) of \(totalUnlocked)"))
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                // Overall ring
                ZStack {
                    Circle()
                        .stroke(Color.accentColor.opacity(0.15), lineWidth: 6)
                        .frame(width: 48, height: 48)
                    Circle()
                        .trim(from: 0, to: overallProgress)
                        .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: 48, height: 48)
                        .animation(.spring(response: 0.6), value: overallProgress)
                    Text("\(Int(overallProgress * 100))%")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color.accentColor)
                }
            }

            // Category filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    CategoryChip(
                        label: String(localized: "progress.category.all"),
                        isSelected: selectedCategory == nil
                    ) { selectedCategory = nil }

                    ForEach(CommandCategory.allCases, id: \.rawValue) { cat in
                        CategoryChip(
                            label: cat.localizedTitle,
                            icon: cat.systemImage,
                            isSelected: selectedCategory == cat
                        ) { selectedCategory = cat }
                    }
                }
            }

            // Commands list
            if filtered.isEmpty {
                Text(String(localized: "progress.commands.empty"))
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                VStack(spacing: 8) {
                    ForEach(
                        filtered.sorted { $0.successCount > $1.successCount },
                        id: \.id
                    ) { command in
                        CommandProgressRow(command: command)
                    }
                }
            }
        }
        .cardStyle(radius: 18)
    }
}

// MARK: - Command progress row

private struct CommandProgressRow: View {
    let command: Command

    @State private var animatedProgress: Double = 0

    private var progressColor: Color {
        command.isMastered ? Color.appSage : .accentColor
    }

    var body: some View {
        HStack(spacing: 12) {
            // Category icon
            Image(systemName: command.category.systemImage)
                .font(.system(size: 14))
                .foregroundStyle(progressColor)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(command.title)
                        .font(.system(size: 14, weight: .medium))
                    if command.isMastered {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.appSage)
                    }
                    if command.isPremium {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(Color.appGold)
                    }
                    Spacer()
                    Text(command.isMastered
                         ? String(localized: "command.mastered")
                         : "\(command.successCount)/5")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }

                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.secondary.opacity(0.12))
                            .frame(height: 6)
                        Capsule()
                            .fill(progressColor)
                            .frame(width: geo.size.width * animatedProgress, height: 6)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: animatedProgress)
                    }
                }
                .frame(height: 6)
            }
        }
        .padding(12)
        .background(Color.appNestedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                animatedProgress = command.progress
            }
        }
        .onChange(of: command.successCount) {
            withAnimation { animatedProgress = command.progress }
        }
    }
}

// MARK: - Category chip

private struct CategoryChip: View {
    let label: String
    var icon: String? = nil
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 11))
                }
                Text(label)
                    .font(.system(size: 13, weight: isSelected ? .medium : .regular))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(isSelected ? Color.accentColor : Color.appNestedBackground)
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(Capsule())
            .animation(.easeInOut(duration: 0.15), value: isSelected)
        }
        .buttonStyle(.plain)
    }
}
