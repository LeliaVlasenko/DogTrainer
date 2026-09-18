import SwiftUI

// MARK: - Streak milestone card (показується в HomeView при досягненні порогу)

struct StreakMilestoneView: View {
    let streak: Int

    private var isMilestone: Bool {
        [3, 7, 14, 30].contains(streak)
    }

    private var milestoneEmoji: String {
        switch streak {
        case 3:  return "🔥"
        case 7:  return "🔥🔥"
        case 14: return "⚡️"
        case 30: return "🏆"
        default: return "🔥"
        }
    }

    private var milestoneColor: Color {
        switch streak {
        case 3:  return Color.appFlame
        case 7:  return Color.appFlame
        case 14: return Color.appRose
        case 30: return Color.appGold
        default: return Color.appFlame
        }
    }

    var body: some View {
        if isMilestone {
            HStack(spacing: 14) {
                Text(milestoneEmoji)
                    .font(.system(size: 32))

                VStack(alignment: .leading, spacing: 2) {
                    Text(String(localized: "streak.milestone.title \(streak)"))
                        .font(.system(size: 14, weight: .semibold))
                    Text(String(localized: "streak.milestone.subtitle"))
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "star.fill")
                    .foregroundStyle(milestoneColor)
                    .font(.system(size: 18))
            }
            .padding(14)
            .background(milestoneColor.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(milestoneColor.opacity(0.25), lineWidth: 1)
            )
        }
    }
}

// MARK: - Compact badges row (для HomeView / ProfileView)

struct RecentBadgesRow: View {
    let earned: [EarnedBadge]
    let onTapAll: () -> Void

    private var recentThree: [EarnedBadge] {
        Array(earned.sorted { $0.earnedAt > $1.earnedAt }.prefix(3))
    }

    var body: some View {
        if !earned.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(String(localized: "badges.recent.title"))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button(String(localized: "badges.recent.all \(earned.count)"), action: onTapAll)
                        .font(.system(size: 13))
                        .foregroundStyle(Color.accentColor)
                }

                HStack(spacing: 10) {
                    ForEach(recentThree, id: \.badgeId) { eb in
                        if let def = BadgeCatalog.definition(for: eb.badgeId) {
                            VStack(spacing: 4) {
                                ZStack {
                                    Circle()
                                        .fill(Color.accentColor.opacity(0.1))
                                        .frame(width: 48, height: 48)
                                    Text(def.emoji)
                                        .font(.system(size: 24))
                                }
                                Text(String(localized: def.titleKey))
                                    .font(.system(size: 10))
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                                    .frame(maxWidth: 64)
                            }
                        }
                    }

                    // Показуємо скільки ще
                    if earned.count > 3 {
                        VStack(spacing: 4) {
                            ZStack {
                                Circle()
                                    .fill(Color.secondary.opacity(0.1))
                                    .frame(width: 48, height: 48)
                                Text("+\(earned.count - 3)")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(.secondary)
                            }
                            Text(String(localized: "badges.more"))
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                        }
                        .onTapGesture { onTapAll() }
                    }
                    Spacer()
                }
            }
            .cardStyle(padding: 14)
        }
    }
}
