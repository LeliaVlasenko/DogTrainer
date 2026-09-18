import SwiftUI

// MARK: - Upcoming badges row
//
// Показує 2-3 бейджі, які юзер найближче до того щоб отримати, з
// прогрес-баром "N / target". Візуалізує progression → мотивація тренуватись.

struct UpcomingBadgesRow: View {
    let dog: Dog?
    let totalSessions: Int
    let masteredCommands: Int
    let earnedBadges: [EarnedBadge]

    private var upcoming: [UpcomingBadge] {
        let earnedIds = Set(earnedBadges.map { $0.badgeId })
        let streak = dog?.currentStreak ?? 0

        var candidates: [UpcomingBadge] = []

        for (threshold, ids) in Self.streakThresholds where !earnedIds.contains(ids) {
            if let def = BadgeCatalog.definition(for: ids) {
                candidates.append(.init(definition: def, current: streak, target: threshold))
            }
        }
        for (threshold, ids) in Self.sessionThresholds where !earnedIds.contains(ids) {
            if let def = BadgeCatalog.definition(for: ids) {
                candidates.append(.init(definition: def, current: totalSessions, target: threshold))
            }
        }
        for (threshold, ids) in Self.masteryThresholds where !earnedIds.contains(ids) {
            if let def = BadgeCatalog.definition(for: ids) {
                candidates.append(.init(definition: def, current: masteredCommands, target: threshold))
            }
        }

        // Сортуємо: найменше залишилось першим; відкидаємо вже виконані
        // (їх би AchievementManager вже додав, але для безпеки).
        return candidates
            .filter { $0.current < $0.target }
            .sorted { $0.remaining < $1.remaining }
            .prefix(3)
            .map { $0 }
    }

    var body: some View {
        if !upcoming.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(String(localized: "badges.upcoming.title"))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.secondary)
                    Spacer()
                }

                VStack(spacing: 10) {
                    ForEach(upcoming) { badge in
                        UpcomingBadgeRow(badge: badge)
                    }
                }
            }
            .padding(14)
            .cardStyle(padding: 0, radius: 14)
            .padding(14)
        }
    }

    // MARK: - Thresholds

    private static let streakThresholds: [(Int, String)] = [
        (3, "streak_3"), (7, "streak_7"), (14, "streak_14"), (30, "streak_30")
    ]
    private static let sessionThresholds: [(Int, String)] = [
        (1, "sessions_1"), (5, "sessions_5"), (10, "sessions_10"),
        (25, "sessions_25"), (50, "sessions_50")
    ]
    private static let masteryThresholds: [(Int, String)] = [
        (1, "mastery_1"), (3, "mastery_3"), (5, "mastery_5")
    ]
}

// MARK: - Model

struct UpcomingBadge: Identifiable {
    let definition: BadgeDefinition
    let current: Int
    let target: Int

    var id: String { definition.id }
    var progress: Double { min(1.0, Double(current) / Double(target)) }
    var remaining: Int { max(0, target - current) }
}

// MARK: - Row

private struct UpcomingBadgeRow: View {
    let badge: UpcomingBadge

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.secondary.opacity(0.08))
                    .frame(width: 42, height: 42)
                Text(badge.definition.emoji)
                    .font(.system(size: 22))
                    .opacity(0.7)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(String(localized: badge.definition.titleKey))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.primary)
                    Spacer()
                    Text("\(badge.current) / \(badge.target)")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(.secondary)
                }

                ProgressBar(value: badge.progress)
            }
        }
    }
}

// MARK: - Progress bar

private struct ProgressBar: View {
    let value: Double

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.secondary.opacity(0.12))
                Capsule()
                    .fill(Color.appSage)
                    .frame(width: max(4, geo.size.width * value))
                    .animation(.easeInOut(duration: 0.4), value: value)
            }
        }
        .frame(height: 6)
    }
}

#Preview {
    let dog = Dog(name: "Rex", breed: "Boxer", level: .adult)
    return UpcomingBadgesRow(
        dog: dog,
        totalSessions: 3,
        masteredCommands: 0,
        earnedBadges: []
    )
    .padding()
    .background(Color.appBackground)
}
